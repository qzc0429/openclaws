$ErrorActionPreference = "Stop"

function Get-FlagEnabled {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $false
    }

    return @("1", "true", "yes", "on") -contains $value.Trim().ToLowerInvariant()
}

$script:IsTestMode = Get-FlagEnabled -Name "OPENCLAW_TEST_MODE"
$script:IsNonInteractive = $script:IsTestMode -or (Get-FlagEnabled -Name "OPENCLAW_NONINTERACTIVE")
$script:SkipNodeInstall = $script:IsTestMode -or (Get-FlagEnabled -Name "OPENCLAW_SKIP_NODE_INSTALL")
$script:InstallUrl = if ([string]::IsNullOrWhiteSpace($env:OPENCLAW_INSTALL_URL)) {
    "https://openclaw.ai/install.ps1"
}
else {
    $env:OPENCLAW_INSTALL_URL
}

function Confirm-Yes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    if ($script:IsNonInteractive) {
        Write-Host "$Prompt (auto-approved: non-interactive mode)" -ForegroundColor DarkGray
        return
    }

    $answer = Read-Host "$Prompt`nType YES to continue"
    if ($answer -cne "YES") {
        throw "Cancelled by user."
    }
}

function Get-NodeMajorVersion {
    try {
        $nodeVersion = & node --version 2>$null
        if (-not $nodeVersion) {
            return 0
        }

        return [int](($nodeVersion -replace '^v', '').Split('.')[0])
    }
    catch {
        return 0
    }
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $combined = @($machinePath, $userPath) -join ";"

    foreach ($nodePath in @("C:\Program Files\nodejs", "C:\Program Files (x86)\nodejs")) {
        if ((Test-Path $nodePath) -and ($combined -notlike "*$nodePath*")) {
            $combined = "$nodePath;$combined"
        }
    }

    $env:Path = $combined
}

function Install-NodeJsIfNeeded {
    if ($script:SkipNodeInstall) {
        Write-Host "Skipping Node.js installation (test/skip mode enabled)." -ForegroundColor DarkGray
        return
    }

    $nodeMajorVersion = Get-NodeMajorVersion
    if ($nodeMajorVersion -ge 22) {
        Write-Host "Node.js v$nodeMajorVersion detected." -ForegroundColor Green
        return
    }

    Write-Host "Node.js v22+ is required. Installing from nodejs.org..." -ForegroundColor Yellow

    $nodeArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
        "arm64"
    }
    elseif ([Environment]::Is64BitOperatingSystem) {
        "x64"
    }
    else {
        "x86"
    }

    $nodeIndexUrl = "https://nodejs.org/dist/latest-v22.x/"
    $nodeIndex = Invoke-WebRequest -UseBasicParsing $nodeIndexUrl
    $msiPattern = "node-v22\.[0-9]+\.[0-9]+-$nodeArch\.msi"
    $msiMatch = [regex]::Match($nodeIndex.Content, $msiPattern)

    if (-not $msiMatch.Success) {
        throw "Could not find the latest Node.js 22 installer for architecture '$nodeArch'."
    }

    $nodeMsiName = $msiMatch.Value
    $nodeMsiUrl = "$nodeIndexUrl$nodeMsiName"
    $nodeMsiPath = Join-Path $env:TEMP $nodeMsiName

    Write-Host "Downloading $nodeMsiName..." -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing $nodeMsiUrl -OutFile $nodeMsiPath

    Confirm-Yes -Prompt "About to install Node.js ($nodeMsiName)."

    Write-Host "Installing Node.js..." -ForegroundColor Cyan
    $nodeInstall = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeMsiPath`" /qn /norestart" -Wait -PassThru

    if ($nodeInstall.ExitCode -ne 0) {
        throw "Node.js installer failed with exit code $($nodeInstall.ExitCode)."
    }

    Refresh-ProcessPath
    $updatedNodeMajorVersion = Get-NodeMajorVersion
    if ($updatedNodeMajorVersion -lt 22) {
        throw "Node.js installation completed, but Node 22+ is still not available in PATH."
    }

    Write-Host "Node.js v$updatedNodeMajorVersion installed successfully." -ForegroundColor Green
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host "OpenClaw installer will start now..." -ForegroundColor Cyan
    Write-Host "Source: $($script:InstallUrl)" -ForegroundColor DarkGray

    Install-NodeJsIfNeeded

    $tempInstaller = Join-Path $env:TEMP "openclaw-install.ps1"

    if ($script:IsTestMode) {
        Set-Content -Path $tempInstaller -Encoding UTF8 -Value "Write-Host 'OpenClaw test installer executed.'"
    }
    else {
        Invoke-WebRequest -UseBasicParsing $script:InstallUrl -OutFile $tempInstaller
    }

    if (-not (Test-Path $tempInstaller)) {
        throw "Failed to prepare the OpenClaw installer script."
    }

    Confirm-Yes -Prompt "About to execute the downloaded OpenClaw installer script."

    Unblock-File -Path $tempInstaller -ErrorAction SilentlyContinue
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tempInstaller
    $installerExitCode = $LASTEXITCODE

    if ($installerExitCode -ne 0) {
        throw "The official OpenClaw installer exited with code $installerExitCode."
    }

    Write-Host ""
    Write-Host "OpenClaw installation completed." -ForegroundColor Green
    Write-Host "If the 'openclaw' command is not available immediately, open a new terminal and try again." -ForegroundColor Yellow
}
catch {
    Write-Host ""
    Write-Host "OpenClaw installation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
