[CmdletBinding()]
param([switch]$NoBrowser,[switch]$CheckOnly)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if($PSVersionTable.PSVersion.Major -lt 7){throw 'Can PowerShell7.'}
$taskWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$marker=Get-Content -Raw -LiteralPath (Join-Path $taskWorkspace '.dbms12-project.json')|ConvertFrom-Json
if($marker.projectId -cne 'cd991085-f47e-4f5e-915d-69c9a15156a8'){throw 'Wrong project marker.'}
$machinePath=Join-Path $taskWorkspace 'config\machine.json'
if(-not(Test-Path -LiteralPath $machinePath)){Copy-Item -LiteralPath (Join-Path $taskWorkspace 'config\machine.example.json') -Destination $machinePath}
$machine=Get-Content -Raw -LiteralPath $machinePath|ConvertFrom-Json
if($machine.runtimeUser -notmatch '^[A-Za-z][A-Za-z0-9_]{0,19}$' -or -not [IO.Path]::IsPathFullyQualified($machine.runtimeCredentialPath) -or -not [IO.Path]::IsPathFullyQualified($machine.httpsCertificatePath)){throw 'Machine configuration guard.'}
if(-not(Test-Path -LiteralPath $machine.runtimeCredentialPath)){throw 'Prepared machine runtime credential missing; read memory/05_RUNBOOK.md.'}
# The host validates the certificate under its runtime identity; owner never bypasses its ACL.
$taskRoot=Join-Path $taskWorkspace '.local'
$taskProfile=Join-Path $taskRoot 'config\profile.json'
$taskDll=Join-Path $taskWorkspace 'backend\EnglishCenter.Dbms12\bin\Debug\net10.0\EnglishCenter.Dbms12.dll'
$taskOrigin='https://localhost:8446'
$taskClient=[Net.Http.HttpClient]::new();$taskClient.Timeout=[TimeSpan]::FromSeconds(3)
$taskProcess=$null;$taskOut=$null;$taskErr=$null
$taskMutex=[Threading.Mutex]::new($false,'Local\EnglishCenterDbms12ProjectLauncher')
$taskMutexOwned=$false
try{
 if((Test-Path -LiteralPath $taskProfile) -and (Test-Path -LiteralPath (Join-Path $taskRoot 'running.json'))){
  try{
   $record=Get-Content -Raw -LiteralPath (Join-Path $taskRoot 'running.json')|ConvertFrom-Json
   $process=Get-Process -Id $record.pid -ErrorAction Stop
   $native=Get-CimInstance Win32_Process -Filter ('ProcessId='+$record.pid)
   if($record.dll -cne $taskDll -or $record.profile -cne $taskProfile -or $record.url -cne ($taskOrigin+'/dbms12') -or $process.StartTime.ToUniversalTime() -ne ([DateTimeOffset]$record.startedUtc).UtcDateTime -or -not $native.CommandLine.Contains($taskDll) -or -not $native.CommandLine.Contains($taskProfile)){throw 'Reuse receipt mismatch.'}
   $r=$taskClient.GetAsync($taskOrigin+'/health/ready').GetAwaiter().GetResult();try{if([int]$r.StatusCode -eq 200 -and $r.Content.ReadAsStringAsync().GetAwaiter().GetResult() -ceq 'ready'){
    Write-Output ('DBMS12 dang chay: '+$taskOrigin+'/dbms12. Giu nguyen du lieu/phien.');if(-not $NoBrowser){Start-Process ($taskOrigin+'/dbms12')};return
  }}finally{$r.Dispose()}}catch{ }
 }
 $taskMutexOwned=$taskMutex.WaitOne(0)
 if(-not $taskMutexOwned){throw 'DBMS12 launcher is already active.'}
 if([Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners().Port -contains 8446){throw 'Port8446 is occupied; no process will be stopped automatically.'}
 $taskOwner=[Security.Principal.WindowsIdentity]::GetCurrent().User
 $taskRuntime=(Get-LocalUser -Name $machine.runtimeUser).SID
 function Set-Dbms12Folder([string]$path,[string]$runtimeRights){
  [void][IO.Directory]::CreateDirectory($path)
  $directory=[IO.DirectoryInfo]::new($path)
  $acl=[IO.FileSystemAclExtensions]::GetAccessControl($directory,[Security.AccessControl.AccessControlSections]'Access,Owner')
  if($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -cne $taskOwner.Value){throw 'Owned folder ACL guard.'}
  $acl.SetAccessRuleProtection($true,$false)
  foreach($rule in @($acl.GetAccessRules($true,$false,[Security.Principal.SecurityIdentifier]))){[void]$acl.RemoveAccessRuleSpecific($rule)}
  $inherit=[Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($taskOwner,[Security.AccessControl.FileSystemRights]::FullControl,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow))
  if($runtimeRights){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($taskRuntime,[Security.AccessControl.FileSystemRights]$runtimeRights,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow))}
  [IO.FileSystemAclExtensions]::SetAccessControl($directory,$acl)
 }
 Set-Dbms12Folder $taskRoot 'ReadAndExecute'
 Set-Dbms12Folder (Join-Path $taskRoot 'operator') ''
 Set-Dbms12Folder (Join-Path $taskRoot 'config') 'ReadAndExecute'
 Set-Dbms12Folder (Join-Path $taskRoot 'runtime') 'Modify'
 Set-Dbms12Folder (Join-Path $taskRoot 'web') 'ReadAndExecute'
 Set-Dbms12Folder (Join-Path $taskRoot 'logs') ''
 if($CheckOnly){Write-Output 'DBMS12 paths/identity/port preflight PASS; no build/provision/start.';return}
 Push-Location $taskWorkspace
 try{
  if(-not(Test-Path -LiteralPath (Join-Path $taskWorkspace 'frontend\node_modules\.package-lock.json'))){& npm.cmd --prefix frontend ci --no-audit --no-fund;if($LASTEXITCODE -ne 0){throw 'Frontend dependency restore failed.'}}
  & dotnet restore 'backend/EnglishCenter.Dbms12/EnglishCenter.Dbms12.csproj' --locked-mode;if($LASTEXITCODE -ne 0){throw 'Restore/audit failed.'}
  & dotnet build 'backend/EnglishCenter.Dbms12/EnglishCenter.Dbms12.csproj' --no-restore;if($LASTEXITCODE -ne 0){throw 'Backend build failed.'}
  & npm.cmd --prefix frontend run typecheck;if($LASTEXITCODE -ne 0){throw 'Frontend types failed.'}
  $taskWeb=[IO.Path]::GetFullPath((Join-Path $taskRoot 'web'))
  if($taskWeb -cne [IO.Path]::GetFullPath((Join-Path $taskWorkspace '.local\web'))){throw 'Web output guard.'}
  Push-Location (Join-Path $taskWorkspace 'frontend')
  try{& '.\node_modules\.bin\vite.cmd' build --outDir $taskWeb --emptyOutDir;if($LASTEXITCODE -ne 0){throw 'Frontend build failed.'}}finally{Pop-Location}
  # Provision only creates a fresh catalog when no DBMS12 profile exists. It never resets an existing profile/database.
  & dotnet $taskDll --provision $taskWorkspace;if($LASTEXITCODE -ne 0){throw 'DBMS12 provision refused. Existing demo is untouched.'}
 }finally{Pop-Location}
 $taskCredential=Import-Clixml -LiteralPath $machine.runtimeCredentialPath
 try{
  if($taskCredential.UserName -cne ($env:COMPUTERNAME+'\'+$machine.runtimeUser)){throw 'Runtime credential identity mismatch.'}
  $start=[Diagnostics.ProcessStartInfo]::new((Get-Command dotnet).Source)
  $start.ArgumentList.Add($taskDll);$start.ArgumentList.Add('--profile');$start.ArgumentList.Add($taskProfile);$start.ArgumentList.Add('--managed-stdin')
  $start.WorkingDirectory=$taskWorkspace;$start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
  $start.LoadUserProfile=$true;$start.Domain=$env:COMPUTERNAME;$start.UserName=$machine.runtimeUser;$start.Password=$taskCredential.Password
  $start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
  $taskProcess=[Diagnostics.Process]::Start($start)
 }finally{$taskCredential.Password.Dispose();$taskCredential=$null}
 $taskOut=$taskProcess.StandardOutput.ReadToEndAsync();$taskErr=$taskProcess.StandardError.ReadToEndAsync()
 $taskReceipt=@{pid=$taskProcess.Id;startedUtc=$taskProcess.StartTime.ToUniversalTime().ToString('O');dll=$taskDll;url=$taskOrigin+'/dbms12';profile=$taskProfile;runtimeIdentity=($env:COMPUTERNAME+'\'+$machine.runtimeUser)}
 $taskReceipt|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $taskRoot 'running.json') -Encoding utf8NoBOM
 $taskReady=$false;$taskUntil=[DateTime]::UtcNow.AddSeconds(45)
 while([DateTime]::UtcNow -lt $taskUntil -and -not $taskProcess.HasExited){
  try{$r=$taskClient.GetAsync($taskOrigin+'/health/ready').GetAwaiter().GetResult();try{$taskReady=[int]$r.StatusCode -eq 200 -and $r.Content.ReadAsStringAsync().GetAwaiter().GetResult() -ceq 'ready'}finally{$r.Dispose()}}catch{ }
  if($taskReady){break};Start-Sleep -Milliseconds 400
 }
 if(-not $taskReady){throw 'DBMS12 did not become ready. See .local/logs after controlled stop.'}
 Write-Output ('DBMS12 READY: '+$taskOrigin+'/dbms12')
 Write-Output 'Tai khoan rieng: .local/operator/tai-khoan.md. Enter de dung, khong xoa du lieu.'
 if(-not $NoBrowser){Start-Process ($taskOrigin+'/dbms12')}
 [void][Console]::ReadLine()
}finally{
 if($taskProcess){
  if(-not $taskProcess.HasExited){$taskProcess.StandardInput.WriteLine();$taskProcess.StandardInput.Flush();if(-not $taskProcess.WaitForExit(15000)){throw 'Controlled stop timeout; process retained, no force kill.'}}
  if($taskOut){[IO.File]::WriteAllText((Join-Path $taskRoot 'logs\host.out.txt'),$taskOut.GetAwaiter().GetResult())}
  if($taskErr){[IO.File]::WriteAllText((Join-Path $taskRoot 'logs\host.err.txt'),$taskErr.GetAwaiter().GetResult())}
  Write-Output ('DBMS12 STOP exit='+$taskProcess.ExitCode+'; du lieu duoc giu nguyen.')
  $taskProcess.Dispose()
 }
 if($taskMutexOwned){$taskMutex.ReleaseMutex()};$taskMutex.Dispose()
 $taskClient.Dispose()
}
