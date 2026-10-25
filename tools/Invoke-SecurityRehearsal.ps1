[CmdletBinding()]
param([string]$FixtureRoot,[switch]$SkipBrowser)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $FixtureRoot){$FixtureRoot=Join-Path $projectRoot ('.local/security-redesign/fixture-'+[Guid]::NewGuid().ToString('N'))}
$FixtureRoot=[IO.Path]::GetFullPath($FixtureRoot)
if(-not $FixtureRoot.StartsWith((Join-Path $projectRoot '.local/security-redesign/fixture-'),[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture path guard.'}
if([Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners().Port -contains 8446){throw 'Stop the existing PROJECT host normally first; no process will be killed.'}
$machine=Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'config/machine.json')|ConvertFrom-Json
$ownerSid=[Security.Principal.WindowsIdentity]::GetCurrent().User
$runtimeSid=(Get-LocalUser -Name $machine.runtimeUser).SID
function Initialize-FixtureFolder([string]$path,[string]$rights){
 [void][IO.Directory]::CreateDirectory($path)
 $directory=[IO.DirectoryInfo]::new($path)
 $acl=[IO.FileSystemAclExtensions]::GetAccessControl($directory,[Security.AccessControl.AccessControlSections]'Access,Owner')
 if($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -cne $ownerSid.Value){throw 'Fixture owner mismatch.'}
 $acl.SetAccessRuleProtection($true,$false)
 foreach($rule in @($acl.GetAccessRules($true,$false,[Security.Principal.SecurityIdentifier]))){[void]$acl.RemoveAccessRuleSpecific($rule)}
 $inherit=[Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
 $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($ownerSid,'FullControl',$inherit,'None','Allow'))
 if($rights){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($runtimeSid,$rights,$inherit,'None','Allow'))}
 [IO.FileSystemAclExtensions]::SetAccessControl($directory,$acl)
}
Initialize-FixtureFolder $FixtureRoot 'ReadAndExecute'
Initialize-FixtureFolder (Join-Path $FixtureRoot '.local') 'ReadAndExecute'
foreach($name in @('config','web')){Initialize-FixtureFolder (Join-Path $FixtureRoot ('.local/'+$name)) 'ReadAndExecute'}
Initialize-FixtureFolder (Join-Path $FixtureRoot '.local/runtime') 'Modify'
Initialize-FixtureFolder (Join-Path $FixtureRoot '.local/operator') ''
[void][IO.Directory]::CreateDirectory((Join-Path $FixtureRoot 'config'))
[void][IO.Directory]::CreateDirectory((Join-Path $FixtureRoot 'docs/evidence'))
Copy-Item -LiteralPath (Join-Path $projectRoot '.dbms12-project.json') -Destination $FixtureRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'config/machine.json') -Destination (Join-Path $FixtureRoot 'config/machine.json')
Copy-Item -Path (Join-Path $projectRoot 'frontend/dist/*') -Destination (Join-Path $FixtureRoot '.local/web') -Recurse -Force
$dll=Join-Path $projectRoot 'backend/EnglishCenter.Dbms12/bin/Debug/net10.0/EnglishCenter.Dbms12.dll'
$profile=Join-Path $FixtureRoot '.local/config/profile.json'
[IO.File]::WriteAllText((Join-Path $projectRoot '.local/security-redesign/fixture-path.txt'),$FixtureRoot)
& dotnet $dll --provision $FixtureRoot
if($LASTEXITCODE -ne 0){throw 'Fixture provision refused; retained for investigation.'}
& dotnet $dll --check-profile $profile
if($LASTEXITCODE -ne 0){throw 'Fixture schema check failed.'}
& dotnet $dll --verify-security $profile
if($LASTEXITCODE -ne 0){throw 'Native SQL security checks failed; fixture retained.'}
& dotnet $dll --verify-sql-transactions $profile
if($LASTEXITCODE -ne 0){throw 'SQL-owned transaction proofs failed; fixture retained.'}
if($SkipBrowser){return}
$process=$null;$stdout=$null;$stderr=$null;$client=[Net.Http.HttpClient]::new();$client.Timeout=[TimeSpan]::FromSeconds(3)
try{
 $credential=Import-Clixml -LiteralPath $machine.runtimeCredentialPath
 try{
  if($credential.UserName -cne ($env:COMPUTERNAME+'\'+$machine.runtimeUser)){throw 'Runtime identity guard.'}
  $start=[Diagnostics.ProcessStartInfo]::new((Get-Command dotnet).Source)
  foreach($arg in @($dll,'--profile',$profile,'--managed-stdin')){$start.ArgumentList.Add($arg)}
  $start.WorkingDirectory=$projectRoot;$start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.WindowStyle='Hidden'
  $start.LoadUserProfile=$true;$start.Domain=$env:COMPUTERNAME;$start.UserName=$machine.runtimeUser;$start.Password=$credential.Password
  $start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
  $process=[Diagnostics.Process]::Start($start)
 }finally{$credential.Password.Dispose()}
 $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 $ready=$false;$until=[DateTime]::UtcNow.AddSeconds(45)
 while([DateTime]::UtcNow -lt $until -and -not $process.HasExited){
  try{$r=$client.GetAsync('https://localhost:8446/health/ready').GetAwaiter().GetResult();try{$ready=[int]$r.StatusCode -eq 200 -and $r.Content.ReadAsStringAsync().GetAwaiter().GetResult() -ceq 'ready'}finally{$r.Dispose()}}catch{}
  if($ready){break};Start-Sleep -Milliseconds 400
 }
 if(-not $ready){throw 'Fixture host not ready.'}
 $previousRoot=$env:EC_DBMS12_TEST_ROOT;$env:EC_DBMS12_TEST_ROOT=$FixtureRoot
 try{
  foreach($test in @('browser-smoke','ui-teacher','http-journey','ui-journey','ui-weekly-move','audit-rollback','final-http')){
   & node (Join-Path $projectRoot ('tests/browser/'+$test+'.cjs'))
   if($LASTEXITCODE -ne 0){throw ('Browser check failed: '+$test)}
  }
 }finally{$env:EC_DBMS12_TEST_ROOT=$previousRoot}
 Write-Output ('SQL/HTTP/UI security rehearsal PASS; evidence: '+(Join-Path $FixtureRoot 'docs/evidence'))
}finally{
 if($process){
  if(-not $process.HasExited){$process.StandardInput.WriteLine();$process.StandardInput.Flush();if(-not $process.WaitForExit(15000)){throw 'Normal stop timeout; retained, no force kill.'}}
  if($stdout){[IO.File]::WriteAllText((Join-Path $FixtureRoot '.local/host.out.txt'),$stdout.GetAwaiter().GetResult())}
  if($stderr){[IO.File]::WriteAllText((Join-Path $FixtureRoot '.local/host.err.txt'),$stderr.GetAwaiter().GetResult())}
  Write-Output ('Fixture normal stop exit='+$process.ExitCode);$process.Dispose()
 }
 $client.Dispose()
}
