@echo off
setlocal

if /I "%OPENCLAW_TEST_MODE%"=="1" goto run_installer

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:run_installer
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%install-openclaw.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo OpenClaw installation finished.
) else (
    echo OpenClaw installation failed. Exit code: %EXIT_CODE%
)

if /I not "%OPENCLAW_NONINTERACTIVE%"=="1" if /I not "%OPENCLAW_TEST_MODE%"=="1" pause
exit /b %EXIT_CODE%
