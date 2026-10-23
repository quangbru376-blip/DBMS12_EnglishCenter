[CmdletBinding(SupportsShouldProcess)]
param(
 [string]$RuntimeUser='Dbms12Runtime',
 [string]$SqlInstance='SQLEXPRESS',
 [string]$RuntimeCredentialPath=(Join-Path $env:LOCALAPPDATA 'DBMS12-Team/Operator/runtime.credential.clixml'),
 [string]$HttpsCertificatePath='C:\ProgramData\DBMS12-Team\Runtime\https.cer'
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'setup/TeamSetup.Common.ps1')
Assert-TeamWindows
$root=Get-TeamProjectRoot $PSScriptRoot
Assert-TeamFreshWorkspace $root
Assert-TeamRuntimeName $RuntimeUser
if($SqlInstance -cnotmatch '^[A-Za-z0-9_]+$'){throw 'Named local SQL instance required.'}
Assert-TeamPlainPath $RuntimeCredentialPath
Assert-TeamPlainPath $HttpsCertificatePath
$target=Join-Path $root 'config/machine.json'
if(Test-Path -LiteralPath $target){throw 'config/machine.json already exists; no overwrite performed.'}
$loginScript=Join-Path $root '.local/setup/runtime-login.sql'
if(Test-Path -LiteralPath $loginScript){throw 'Generated login script already exists; inspect it.'}
if($env:COMPUTERNAME -cnotmatch '^[A-Za-z0-9_-]+$'){throw 'Unexpected machine name.'}
if($PSCmdlet.ShouldProcess($root,'Create ignored machine.json and a local Windows-login SQL script')){
 $config=[ordered]@{sqlServer=('lpc:.\'+$SqlInstance);sqlHostName='localhost';runtimeUser=$RuntimeUser;runtimeCredentialPath=[IO.Path]::GetFullPath($RuntimeCredentialPath);httpsCertificatePath=[IO.Path]::GetFullPath($HttpsCertificatePath)}
 $json=$config | ConvertTo-Json
 [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
 $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$bytes=[Text.Encoding]::UTF8.GetBytes($json);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 [IO.Directory]::CreateDirectory((Split-Path -Parent $loginScript)) | Out-Null
 $identity=$env:COMPUTERNAME+'\'+$RuntimeUser
 @"
-- Run as SQL owner in the intended local instance: $SqlInstance.
-- Creates a Windows LOGIN only; provision creates the new DB and its users/roles.
USE [master];
IF SUSER_ID(N'$identity') IS NOT NULL THROW 51000,'Login exists; inspect identity and server roles instead of recreating.',1;
CREATE LOGIN [$identity] FROM WINDOWS;
SELECT name,type_desc,is_disabled FROM sys.server_principals WHERE name=N'$identity';
"@ | Out-File -LiteralPath $loginScript -Encoding utf8NoBOM -NoClobber
 Write-Output 'Created config/machine.json and .local/setup/runtime-login.sql. No SQL was executed.'
}
