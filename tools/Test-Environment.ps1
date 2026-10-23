[CmdletBinding()]
param([ValidateSet('Build','Run')][string]$Mode='Build',[switch]$AsJson)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'setup/TeamSetup.Common.ps1')
$root=Get-TeamProjectRoot $PSScriptRoot
$checks=[Collections.Generic.List[object]]::new()
function Add-Check([string]$Name,[bool]$Pass,[string]$Hint){$checks.Add([pscustomobject]@{name=$Name;status=$(if($Pass){'PASS'}else{'MISSING'});hint=$Hint})}
function Add-Pending([string]$Name,[string]$Hint){$checks.Add([pscustomobject]@{name=$Name;status='PENDING';hint=$Hint})}
Add-Check 'Windows x64' ($IsWindows -and [Environment]::Is64BitProcess) 'Full runtime requires Windows x64.'
Add-Check 'PowerShell >=7.4' ($PSVersionTable.PSVersion -ge [version]'7.4') 'Use pwsh7.4+;7.6 tested. Windows PowerShell5.1 is insufficient.'
if(Get-Command git -ErrorAction SilentlyContinue){Add-Check 'git' $true 'Available for GitHub clone/push.'}else{Add-Pending 'git' 'Needed for GitHub; optional when building from a source ZIP.'}
foreach($name in @('dotnet','node','npm.cmd')){Add-Check $name ([bool](Get-Command $name -ErrorAction SilentlyContinue)) 'Install the toolchain in REQUIREMENTS.md; reopen the terminal after installation.'}
if(Get-Command dotnet -ErrorAction SilentlyContinue){
 $sdks=(& dotnet --list-sdks 2>$null) -join "`n"
 Add-Check '.NET10 SDK' ($LASTEXITCODE -eq 0 -and $sdks -match '(?m)^10\.0\.') 'Install SDK10; a runtime alone is not enough.'
 $runtimes=(& dotnet --list-runtimes 2>$null) -join "`n"
 Add-Check 'ASP.NET Core10' ($LASTEXITCODE -eq 0 -and $runtimes -match '(?m)^Microsoft\.AspNetCore\.App 10\.') 'SDK10 normally includes this runtime.'
}
if(Get-Command node -ErrorAction SilentlyContinue){$version=(& node --version 2>$null) -join '';Add-Check 'Node>=24' ($LASTEXITCODE -eq 0 -and $version -match '^v(\d+)\.' -and [int]$Matches[1] -ge 24) 'Use Node24.x for the team baseline.'}
if(Get-Command npm.cmd -ErrorAction SilentlyContinue){$version=(& npm.cmd --version 2>$null) -join '';Add-Check 'npm>=11' ($LASTEXITCODE -eq 0 -and $version -match '^(\d+)\.' -and [int]$Matches[1] -ge 11) 'Use npm ci; preserve package-lock.json.'}
if($Mode -ceq 'Run' -and $IsWindows){
 $machinePath=Join-Path $root 'config/machine.json'
 Add-Check 'machine.json' (Test-Path -LiteralPath $machinePath) 'On a fresh clone run tools/Initialize-MachineConfig.ps1; existing configs are never overwritten.'
 if(Test-Path -LiteralPath $machinePath){
  try{
   $m=Get-Content -LiteralPath $machinePath -Raw | ConvertFrom-Json
   Assert-TeamRuntimeName $m.runtimeUser
   if(-not [IO.Path]::IsPathFullyQualified($m.runtimeCredentialPath) -or -not [IO.Path]::IsPathFullyQualified($m.httpsCertificatePath)){throw 'Expected absolute machine paths.'}
   $valid=$m.sqlServer -match '^lpc:(?:\.|localhost)\\([A-Za-z0-9_]+)$' -and $m.sqlHostName -ceq 'localhost'
   Add-Check 'Local named SQL config' $valid 'Only lpc:.\NAMED_INSTANCE with SQL hostname localhost is supported.'
   if($valid){
    $instance=($m.sqlServer -split '\\')[-1]
    $service=Get-Service -Name ('MSSQL$'+$instance) -ErrorAction SilentlyContinue
    Add-Check 'SQL Database Engine service' ([bool]$service -and $service.Status -eq 'Running') 'Install/start the intended named Database Engine instance; SSMS alone is not the engine.'
   }
   $user=Get-LocalUser -Name $m.runtimeUser -ErrorAction SilentlyContinue
   Add-Check 'Local runtime account' ([bool]$user -and $user.Enabled) 'Prepare a dedicated enabled non-admin runtime account.'
   if($user){$admins=@(Get-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-544'));Add-Check 'Runtime not local admin' ($admins.SID.Value -notcontains $user.SID.Value) 'Never add runtime to Administrators.'}
   $exists=Test-Path -LiteralPath $m.runtimeCredentialPath
   Add-Check 'Owner DPAPI credential file' $exists 'SaveCredential must run as the launcher owner on this machine.'
   if($exists){
    $credential=$null
    try{$credential=Import-Clixml -LiteralPath $m.runtimeCredentialPath;Add-Check 'Credential identity' ($credential -is [Management.Automation.PSCredential] -and $credential.UserName -ceq ($env:COMPUTERNAME+'\'+$m.runtimeUser)) 'Credential must decrypt as this owner and match the exact runtime identity.'}catch{Add-Check 'Credential identity' $false 'Cannot read/decrypt credential; create it as the launcher owner, never copy DPAPI.'}finally{if($credential -is [Management.Automation.PSCredential]){$credential.Password.Dispose()}}
   }
   # The public certificate may intentionally be unreadable to owner; runtime checks its own store.
   Add-Pending 'Runtime HTTPS private key' 'Verified under runtime identity by the launcher/host, not by this owner-only preflight.'
   Add-Pending 'SQL TLS and native login rights' 'Bind/trust the correct SQL certificate and create the runtime Windows LOGIN; provision/host perform trusted TLS and SQL checks.'
  }catch{Add-Check 'Machine configuration validation' $false 'Invalid/inaccessible machine settings. Read SETUP_WINDOWS.md; do not print credentials or bypass guards.'}
 }
 try{
  $portUsed=[Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners().Port -contains 8446
  if($portUsed){Add-Pending 'Port8446' 'Occupied: launcher must verify its own receipt and ready endpoint; do not kill an arbitrary process.'}else{Add-Check 'Port8446' $true 'Free; the launcher is the authority for start/reuse.'}
 }catch{Add-Pending 'Port8446' 'Listener inspection unavailable in this context; verify with the launcher. No process was stopped.'}
 Add-Pending 'End-to-end readiness' 'After setup, launch Chay-Project.cmd and verify HTTPS /health/ready plus Test-Project.ps1 -CheckDatabase. This preflight makes no changes and is not a READY verdict.'
}
$missing=@($checks | Where-Object status -eq 'MISSING').Count
$report=[pscustomobject]@{mode=$Mode;checkedUtc=[DateTime]::UtcNow.ToString('O');missing=$missing;preflightPassed=($missing -eq 0);applicationReadyVerified=$false;checks=$checks.ToArray()}
if($AsJson){$report | ConvertTo-Json -Depth 5}else{$checks | Format-Table -AutoSize -Wrap;Write-Output ('Missing='+$missing+'. Preflight only; no accounts/certificates/ACL/SQL/data were changed.')}
if($missing){exit 1}
