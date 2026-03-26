@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "TARGET="
set "CHOICE_RAW=%OPENCLAW_SELECTOR_CHOICE%"

if not defined CHOICE_RAW (
    set "CHOICE_RAW=auto"
)

call :NormalizeChoice "%CHOICE_RAW%"
if errorlevel 1 (
    echo Unsupported choice: %CHOICE_RAW%
    call :MaybePause
    exit /b 1
)

if /I "%TARGET%"=="exit" (
    echo Exited.
    call :MaybePause
    exit /b 0
)

if /I "%TARGET%"=="auto" set "TARGET=windows"
echo Detected system: Windows
echo Selected target: %TARGET%

if /I "%TARGET%"=="windows" goto run_windows
if /I "%TARGET%"=="macos" goto print_macos
if /I "%TARGET%"=="linux" goto print_linux

echo Unsupported target: %TARGET%
call :MaybePause
exit /b 1

:run_windows
set "PS_SCRIPT=%SCRIPT_DIR%install-openclaw.ps1"

if exist "%PS_SCRIPT%" (
    echo Running installer: install-openclaw.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
    set "EXIT_CODE=!ERRORLEVEL!"
    call :MaybePause
    exit /b !EXIT_CODE!
)

echo Missing installer script: install-openclaw.ps1
call :MaybePause
exit /b 1

:print_macos
echo Target OS differs from current OS. Cannot run macOS installer on Windows.
echo Run these on macOS:
echo   chmod +x ./install-openclaw.sh
echo   ./install-openclaw.sh
call :MaybePause
exit /b 0

:print_linux
echo Target OS differs from current OS. Cannot run Linux installer on Windows.
echo Run these on Linux:
echo   chmod +x ./install-openclaw.sh
echo   ./install-openclaw.sh
call :MaybePause
exit /b 0

:NormalizeChoice
set "RAW=%~1"
if "%RAW%"=="" exit /b 1

if /I "%RAW%"=="1" set "TARGET=auto"& exit /b 0
if /I "%RAW%"=="2" set "TARGET=windows"& exit /b 0
if /I "%RAW%"=="3" set "TARGET=macos"& exit /b 0
if /I "%RAW%"=="4" set "TARGET=linux"& exit /b 0
if /I "%RAW%"=="5" set "TARGET=exit"& exit /b 0
if /I "%RAW%"=="auto" set "TARGET=auto"& exit /b 0
if /I "%RAW%"=="windows" set "TARGET=windows"& exit /b 0
if /I "%RAW%"=="win" set "TARGET=windows"& exit /b 0
if /I "%RAW%"=="mac" set "TARGET=macos"& exit /b 0
if /I "%RAW%"=="macos" set "TARGET=macos"& exit /b 0
if /I "%RAW%"=="darwin" set "TARGET=macos"& exit /b 0
if /I "%RAW%"=="linux" set "TARGET=linux"& exit /b 0
if /I "%RAW%"=="exit" set "TARGET=exit"& exit /b 0
if /I "%RAW%"=="quit" set "TARGET=exit"& exit /b 0
exit /b 1

:MaybePause
if /I "%OPENCLAW_NONINTERACTIVE%"=="1" exit /b 0
if /I "%OPENCLAW_TEST_MODE%"=="1" exit /b 0
pause
exit /b 0
