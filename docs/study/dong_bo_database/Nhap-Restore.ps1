# ==============================================================================
# SCRIPT TỰ ĐỘNG PHỤC HỒI (RESTORE) CỦA MÁY B
# ==============================================================================
[CmdletBinding()]
param(
    [string]$BackupPath = 'C:\SQL_Backups\DBMS12_Team_Shared.bak',
    [string]$Instance = 'localhost\SQLEXPRESS'
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$profileFile = Join-Path $root '.local\config\profile.json'

if (-not (Test-Path $BackupPath)) {
    throw "Khong tim thay file backup tai: $BackupPath. Hay copy file .bak vao dung thu muc nay truoc!"
}

if (-not (Test-Path $profileFile)) {
    throw "Khong tim thay profile.json tai $profileFile. May B can clone du an va chay Chay-Project.cmd it nhat 1 lan truoc!"
}

$profile = Get-Content $profileFile -Raw | ConvertFrom-Json
$dbName = $profile.Database
$runtimeLogin = "$env:COMPUTERNAME\Dbms12Runtime"

Write-Host "--> Phat hien Database may B: $dbName" -ForegroundColor Cyan
Write-Host "--> Windows Runtime Login may B: $runtimeLogin" -ForegroundColor Cyan

$sql = @"
USE master;

PRINT N'--> Ngat ket noi active...';
ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

PRINT N'--> Dang RESTORE DATABASE...';
RESTORE DATABASE [$dbName]
FROM DISK = N'$BackupPath'
WITH REPLACE, RECOVERY, STATS = 20;

ALTER DATABASE [$dbName] SET MULTI_USER;

PRINT N'--> Dang sua loi Orphaned User va anh xa login may B...';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$runtimeLogin')
BEGIN
    CREATE LOGIN [$runtimeLogin] FROM WINDOWS;
END;

USE [$dbName];

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'Dbms12ProjectRuntime')
BEGIN
    ALTER USER [Dbms12ProjectRuntime] WITH LOGIN = [$runtimeLogin];
    PRINT N'    [PASS] Da anh xa user Dbms12ProjectRuntime sang $runtimeLogin';
END
ELSE
BEGIN
    CREATE USER [Dbms12ProjectRuntime] FOR LOGIN [$runtimeLogin];
    PRINT N'    [PASS] Da tao moi user Dbms12ProjectRuntime cho $runtimeLogin';
END;

ALTER ROLE [dbms12_runtime] ADD MEMBER [Dbms12ProjectRuntime];

PRINT N'--> Kiem tra DBCC CHECKDB...';
DBCC CHECKDB([$dbName]) WITH NO_INFOMSGS;
"@

Write-Host "--> Dang thuc hien phuc hoi tren SQL Server..." -ForegroundColor Cyan
& sqlcmd -S $Instance -E -Q $sql
if ($LASTEXITCODE -ne 0) {
    throw "Phuc hoi SQL Server that bai! Hay kiem tra sqlcmd hoac SSMS."
}

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "--> PHỤC HỒI THÀNH CÔNG!" -ForegroundColor Green
Write-Host "--> Database cua may B da duoc cap nhat day du du lieu giong May A." -ForegroundColor Green
Write-Host "--> Ban co the chay Chay-Project.cmd ngay bay gio de xem du lieu!" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
