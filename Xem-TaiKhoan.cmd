@echo off
setlocal
cd /d "%~dp0"
if not exist ".local\operator\tai-khoan.md" (
 echo Hay chay Chay-Project.cmd truoc.
 pause
 exit /b 1
)
start "" ".local\operator\tai-khoan.md"
endlocal
