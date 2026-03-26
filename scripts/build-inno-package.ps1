$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
$issPath = Join-Path $repoRoot "inno\openclaw-windows-installer.iss"
$distDir = Join-Path $repoRoot "dist"
$outputFile = Join-Path $distDir "openclaw-installer-windows-setup.exe"

if (-not (Test-Path $issPath)) {
    throw "Inno Setup script not found: $issPath"
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null

$possibleIsccPaths = @()
$isccCommand = Get-Command iscc.exe -ErrorAction SilentlyContinue
if ($isccCommand) {
    $possibleIsccPaths += $isccCommand.Source
}

$possibleIsccPaths += @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:USERPROFILE\Inno Setup 6\ISCC.exe"
)

$isccPath = $possibleIsccPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $isccPath) {
    throw "ISCC.exe not found. Please install Inno Setup 6, then rerun this script."
}

$version = Get-Date -Format "yyyy.MM.dd.HHmm"

Write-Host "Using ISCC: $isccPath" -ForegroundColor Cyan
Write-Host "Building version: $version" -ForegroundColor Cyan

& $isccPath "/Qp" "/DMyAppVersion=$version" "$issPath"
if ($LASTEXITCODE -ne 0) {
    throw "ISCC failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path $outputFile)) {
    throw "Build succeeded but output file not found: $outputFile"
}

Write-Host "Inno package generated: $outputFile" -ForegroundColor Green
