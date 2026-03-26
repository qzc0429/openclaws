$ErrorActionPreference = "Stop"

function Write-TextFileUtf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [switch]$UnixNewline
    )

    $normalized = $Content -replace "`r`n", "`n" -replace "`r", "`n"
    if (-not $UnixNewline) {
        $normalized = $normalized -replace "`n", "`r`n"
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptRoot "..")).Path
$distDir = Join-Path $repoRoot "dist"
$packageName = "openclaw-installer-universal"
$packageRoot = Join-Path $distDir $packageName
$zipPath = Join-Path $distDir "$packageName.zip"

$filesToCopy = @(
    "install-openclaw.ps1",
    "install-openclaw.sh",
    "openclaw-installer-selector.cmd",
    "openclaw-installer-selector.sh",
    "openclaw-installer-selector.command"
)

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $repoRoot $file
    if (-not (Test-Path $sourcePath)) {
        throw "Missing required file: $file"
    }
}

if (Test-Path $packageRoot) {
    Remove-Item -Path $packageRoot -Recurse -Force
}

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

foreach ($file in $filesToCopy) {
    Copy-Item -Path (Join-Path $repoRoot $file) -Destination (Join-Path $packageRoot $file) -Force
}

$startCmd = @'
@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%openclaw-installer-selector.cmd"
exit /b %ERRORLEVEL%
'@

$startSh = @'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/openclaw-installer-selector.sh"
'@

$startCommand = @'
#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +e
bash "${SCRIPT_DIR}/openclaw-installer-selector.command"
EXIT_CODE=$?
set -e

if [[ -t 0 && "${OPENCLAW_NONINTERACTIVE:-0}" != "1" && "${OPENCLAW_TEST_MODE:-0}" != "1" ]]; then
  read -r -p "Press Enter to continue..." _
fi

exit "$EXIT_CODE"
'@

$userReadme = @'
OpenClaw Universal Installer
============================

How to install:

1) Extract this zip.
2) Run the launcher that matches your system:
   - Windows: Start-Installer.cmd
   - macOS: start-installer.command
   - Linux:  start-installer.sh

The launcher auto-detects your OS and runs the correct installer.

If the shell scripts are not executable, run:
  chmod +x ./start-installer.sh ./start-installer.command ./install-openclaw.sh ./openclaw-installer-selector.sh ./openclaw-installer-selector.command
'@

Write-TextFileUtf8NoBom -Path (Join-Path $packageRoot "Start-Installer.cmd") -Content $startCmd
Write-TextFileUtf8NoBom -Path (Join-Path $packageRoot "start-installer.sh") -Content $startSh -UnixNewline
Write-TextFileUtf8NoBom -Path (Join-Path $packageRoot "start-installer.command") -Content $startCommand -UnixNewline
Write-TextFileUtf8NoBom -Path (Join-Path $packageRoot "README-USER.txt") -Content $userReadme

Compress-Archive -Path $packageRoot -DestinationPath $zipPath -Force

Write-Host "Package directory: $packageRoot" -ForegroundColor Green
Write-Host "Zip file: $zipPath" -ForegroundColor Green
