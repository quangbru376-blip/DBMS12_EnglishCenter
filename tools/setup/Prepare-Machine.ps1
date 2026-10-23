[CmdletBinding(SupportsShouldProcess)]
param(
 [Parameter(Mandatory)][ValidateSet('CreateRuntime','SaveCredential','WebCertificate','TrustWebCertificate','SqlCertificate')][string]$Phase,
 [string]$RuntimeUser='Dbms12Runtime',
 [string]$RuntimeFolder='C:\ProgramData\DBMS12-Team\Runtime',
 [string]$CredentialFolder=(Join-Path $env:LOCALAPPDATA 'DBMS12-Team/Operator'),
 [string]$SqlInstance='SQLEXPRESS',
 [string]$SqlCertificateFolder='C:\ProgramData\DBMS12-Team\SqlTls',
 [string]$Thumbprint
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TeamSetup.Common.ps1')
Assert-TeamWindows
$root=Get-TeamProjectRoot (Split-Path -Parent $PSScriptRoot)
Assert-TeamFreshWorkspace $root
Assert-TeamRuntimeName $RuntimeUser
foreach($path in @($RuntimeFolder,$CredentialFolder,$SqlCertificateFolder)){Assert-TeamPlainPath $path}
$identity=$env:COMPUTERNAME+'\'+$RuntimeUser
$publicPath=Join-Path $RuntimeFolder 'https.cer'
# WhatIf returns before password prompts or privileged operations.
if(-not $PSCmdlet.ShouldProcess($identity,"DBMS12 new-machine phase: $Phase")){return}
switch($Phase){
 'CreateRuntime' {
  Assert-TeamAdmin
  if(Get-LocalUser -Name $RuntimeUser -ErrorAction SilentlyContinue){throw 'Runtime account exists; no password reset or reuse is performed.'}
  if(Test-Path -LiteralPath $RuntimeFolder){throw 'Runtime folder exists; inspect instead of modifying it.'}
  $password=Read-Host 'New private Windows runtime password (never shared)' -AsSecureString
  try{$user=New-LocalUser -Name $RuntimeUser -Password $password -Description 'DBMS12 dedicated local runtime'}finally{$password.Dispose()}
  Add-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-545') -Member $user
  New-TeamPrivateFolder -Path $RuntimeFolder -RuntimeSid $user.SID
  & icacls.exe $root /grant:r "${identity}:(OI)(CI)RX" | Out-Null
  if($LASTEXITCODE -ne 0){throw 'Source RX grant failed; inspect the new account/folder; do not rerun blindly.'}
  Write-Output 'Created runtime and its folder; granted source RX. No SQL privileges or certificates created.'
 }
 'SaveCredential' {
  if([Security.Principal.WindowsIdentity]::GetCurrent().Name -ieq $identity){throw 'Run this phase as the owner who will launch the project, not runtime.'}
  $user=Get-LocalUser -Name $RuntimeUser
  $admins=@(Get-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-544'))
  if($admins.SID.Value -contains $user.SID.Value){throw 'Runtime must not be an administrator.'}
  if(Test-Path -LiteralPath $CredentialFolder){throw 'Credential folder exists; inspect it. No overwrite.'}
  $credential=Get-Credential -UserName $identity -Message 'Private runtime password; save only under the launcher owner'
  try{
   if($credential.UserName -cne $identity){throw 'Credential identity mismatch.'}
   New-TeamPrivateFolder -Path $CredentialFolder
   $credential | Export-Clixml -LiteralPath (Join-Path $CredentialFolder 'runtime.credential.clixml') -NoClobber
  }finally{if($credential){$credential.Password.Dispose()}}
  Write-Output 'Saved owner/machine-bound DPAPI credential. Never copy it to Git or another machine.'
 }
 'WebCertificate' {
  $current=[Security.Principal.WindowsIdentity]::GetCurrent()
  if($current.Name -ine $identity -or ([Security.Principal.WindowsPrincipal]::new($current)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run in a profile-loaded non-admin PowerShell of the runtime user.'}
  if(-not(Test-Path -LiteralPath $RuntimeFolder -PathType Container)){throw 'Create the runtime folder first.'}
  if(Test-Path -LiteralPath $publicPath){throw 'Public certificate exists; no certificate replacement performed.'}
  $cert=New-SelfSignedCertificate -DnsName 'localhost' -Type SSLServerAuthentication -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'DBMS12 team web localhost' -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(1)
  Export-Certificate -Cert $cert -FilePath $publicPath -NoClobber | Out-Null
  Write-Output ('Public web certificate created; thumbprint='+$cert.Thumbprint)
 }
 'TrustWebCertificate' {
  if($Thumbprint -cnotmatch '^[A-Fa-f0-9]{40}$'){throw 'Provide the exact thumbprint printed by the runtime WebCertificate phase.'}
  $cert=[Security.Cryptography.X509Certificates.X509Certificate2]::new($publicPath)
  try{
   if($cert.Thumbprint -ine $Thumbprint -or -not $cert.MatchesHostname('localhost',$false,$false) -or $cert.NotAfter.ToUniversalTime() -le [DateTime]::UtcNow -or $cert.HasPrivateKey){throw 'Public web certificate identity/validity mismatch.'}
   Import-Certificate -FilePath $publicPath -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null
  }finally{$cert.Dispose()}
  Write-Output 'Trusted the exact public web certificate for the current owner/browser; no private key exported.'
 }
 'SqlCertificate' {
  Assert-TeamAdmin
  if($SqlInstance -cnotmatch '^[A-Za-z0-9_]+$'){throw 'Named instance required.'}
  if(Test-Path -LiteralPath $SqlCertificateFolder){throw 'SQL certificate folder exists; inspect, no overwrite.'}
  $service=Get-CimInstance Win32_Service -Filter ("Name='MSSQL`$"+$SqlInstance+"'")
  if(-not $service){throw 'Install the named SQL Database Engine instance first.'}
  $serviceIdentity=switch($service.StartName){'LocalSystem' {'NT AUTHORITY\SYSTEM'};'NT AUTHORITY\NetworkService' {'NT AUTHORITY\NETWORK SERVICE'};'NT AUTHORITY\LocalService' {'NT AUTHORITY\LOCAL SERVICE'};default {$service.StartName}}
  $sqlSid=([Security.Principal.NTAccount]::new($serviceIdentity)).Translate([Security.Principal.SecurityIdentifier])
  New-TeamPrivateFolder -Path $SqlCertificateFolder
  $cert=New-SelfSignedCertificate -Type SSLServerAuthentication -DnsName @($env:COMPUTERNAME,'localhost') -CertStoreLocation 'Cert:\LocalMachine\My' -FriendlyName ('DBMS12 team SQL '+$SqlInstance) -KeySpec KeyExchange -Provider 'Microsoft RSA SChannel Cryptographic Provider' -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(1)
  $rsa=[Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
  try{
   if($rsa -isnot [Security.Cryptography.RSACryptoServiceProvider]){throw 'Expected SQL-compatible CAPI RSA private key.'}
   $keyPath=Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) ('Microsoft/Crypto/RSA/MachineKeys/'+$rsa.CspKeyContainerInfo.UniqueKeyContainerName)
   Assert-TeamPlainPath $keyPath
   $keyFile=Get-Item -LiteralPath $keyPath
   $acl=Get-Acl -LiteralPath $keyFile.FullName
   $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sqlSid,'Read','Allow'))
   Set-Acl -LiteralPath $keyFile.FullName -AclObject $acl
  }finally{$rsa.Dispose()}
  $sqlPublic=Join-Path $SqlCertificateFolder 'sql-localhost.cer'
  Export-Certificate -Cert $cert -FilePath $sqlPublic -NoClobber | Out-Null
  Import-Certificate -FilePath $sqlPublic -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
  Write-Output ('Created/trusted a new dev SQL certificate; thumbprint='+$cert.Thumbprint)
  Write-Output 'Bind this exact certificate to the intended instance in SQL Server Configuration Manager, then restart only that instance. This script did not change SQL binding or restart anything.'
 }
}
