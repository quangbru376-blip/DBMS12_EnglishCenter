@echo off
setlocal
cd /d "%~dp0"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Start-Project.ps1"
if errorlevel 1 pause
endlocal
