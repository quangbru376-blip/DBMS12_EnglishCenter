@echo off
setlocal
cd /d "%~dp0"
echo ====================================================================
echo      XUAT SAO LUU CSDL DBMS12 RA FILE .BAK (MAY A)
echo ====================================================================
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0Xuat-Backup.ps1"
if errorlevel 1 pause
endlocal
