# ==============================================================================
# SCRIPT TỰ ĐỘNG XUẤT BACKUP CỦA MÁY A
# ==============================================================================
[CmdletBinding()]
param(
    [string]$BackupPath = 'C:\SQL_Backups\DBMS12_Team_Shared.bak',
    [string]$Instance = 'localhost\SQLEXPRESS'
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$profileFile = Join-Path $root '.local\config\profile.json'

if (-not (Test-Path $profileFile)) {
    throw "Khong tim thay file profile.json tai $profileFile. Hay chay Chay-Project.cmd it nhat 1 lan!"
}

$profile = Get-Content $profileFile -Raw | ConvertFrom-Json
$dbName = $profile.Database
Write-Host "--> Phat hien Database: $dbName" -ForegroundColor Cyan

$backupFolder = [IO.Path]::GetDirectoryName($BackupPath)
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "--> Da tao thu muc sao luu: $backupFolder" -ForegroundColor Yellow
}

$sql = @"
USE master;
BACKUP DATABASE [$dbName]
TO DISK = N'$BackupPath'
WITH FORMAT, INIT, NAME = N'DBMS12_Shared_AutoBackup', COMPRESSION, CHECKSUM, STATS = 20;
"@

Write-Host "--> Dang chay sao luu SQL Server..." -ForegroundColor Cyan
& sqlcmd -S $Instance -E -Q $sql
if ($LASTEXITCODE -ne 0) {
    throw "Sao luu SQL Server that bai! Hay kiem tra sqlcmd hoac quyen Administrator."
}

$fileItem = Get-Item $BackupPath
$sizeMb = [Math]::Round($fileItem.Length / 1MB, 2)

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "--> SAO LƯU THÀNH CÔNG!" -ForegroundColor Green
Write-Host "--> File backup: $BackupPath ($sizeMb MB)" -ForegroundColor Green
Write-Host "--> Hay gui file nay cho ban trong nhom (qua Zalo, Google Drive, USB...)." -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
