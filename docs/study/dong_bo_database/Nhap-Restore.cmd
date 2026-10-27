@echo off
setlocal
cd /d "%~dp0"
echo ====================================================================
echo      NHAP PHUC HOI CSDL DBMS12 TU FILE .BAK (MAY B)
echo ====================================================================
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0Nhap-Restore.ps1"
if errorlevel 1 pause
endlocal
