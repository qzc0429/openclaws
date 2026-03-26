@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%openclaw-installer-selector.cmd"
exit /b %ERRORLEVEL%