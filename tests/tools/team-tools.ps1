[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixture=Join-Path $root ('.local/team-tools-tests/'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $fixture 'tools/setup')) | Out-Null
[IO.File]::Copy((Join-Path $root '.dbms12-project.json'),(Join-Path $fixture '.dbms12-project.json'))
foreach($relative in @('Initialize-MachineConfig.ps1','Test-Environment.ps1','SourcePackage.ps1','Export-TeamSource.ps1','setup/TeamSetup.Common.ps1','setup/Prepare-Machine.ps1')){
 [IO.File]::Copy((Join-Path $root ('tools/'+$relative)),(Join-Path $fixture ('tools/'+$relative)))
}
$checks=[Collections.Generic.List[string]]::new()
function Assert-TeamTest([bool]$Condition,[string]$Name){if(-not $Condition){throw ('Test failed: '+$Name)};$checks.Add($Name)}
function Invoke-Tool([string]$Name,[string[]]$ToolArgs){
 $output=& pwsh -NoProfile -File (Join-Path $fixture ('tools/'+$Name)) @ToolArgs 2>&1
 return [pscustomobject]@{code=$LASTEXITCODE;output=($output -join "`n")}
}
$scripts=@(Get-ChildItem -LiteralPath (Join-Path $root 'tools') -Filter '*.ps1' -Recurse)+@(Get-Item -LiteralPath $PSCommandPath)
foreach($script in $scripts){$tokens=$null;$problems=$null;[void][Management.Automation.Language.Parser]::ParseFile($script.FullName,[ref]$tokens,[ref]$problems);if($problems.Count){throw ('Parser failed: '+$script.Name)}}
Assert-TeamTest $true 'All tool scripts parse'
$configPath=Join-Path $fixture 'config/machine.json'
$result=Invoke-Tool 'Initialize-MachineConfig.ps1' @('-WhatIf')
Assert-TeamTest ($result.code -eq 0 -and -not(Test-Path -LiteralPath $configPath)) 'Config WhatIf writes nothing'
$result=Invoke-Tool 'Initialize-MachineConfig.ps1' @('-RuntimeUser','TeamRuntime','-SqlInstance','TEAMSQL','-RuntimeCredentialPath','C:\DBMS12-Test\runtime.clixml','-HttpsCertificatePath','C:\DBMS12-Test\https.cer')
Assert-TeamTest ($result.code -eq 0 -and (Test-Path -LiteralPath $configPath)) 'Fresh config generated'
$config=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert-TeamTest ($config.runtimeUser -ceq 'TeamRuntime' -and $config.sqlServer -ceq 'lpc:.\TEAMSQL' -and $config.runtimeCredentialPath -ceq 'C:\DBMS12-Test\runtime.clixml') 'Config uses recipient parameters'
$hash=(Get-FileHash -LiteralPath $configPath).Hash
$result=Invoke-Tool 'Initialize-MachineConfig.ps1' @()
Assert-TeamTest ($result.code -ne 0 -and (Get-FileHash -LiteralPath $configPath).Hash -ceq $hash) 'Existing config refused and unchanged'
$login=Get-Content -LiteralPath (Join-Path $fixture '.local/setup/runtime-login.sql') -Raw
Assert-TeamTest ($login.Contains('CREATE LOGIN ['+$env:COMPUTERNAME+'\TeamRuntime] FROM WINDOWS;') -and -not $login.Contains('sysadmin')) 'Login script uses local identity without privilege grant'
foreach($phase in @('CreateRuntime','SaveCredential','WebCertificate','TrustWebCertificate','SqlCertificate')){
 $result=Invoke-Tool 'setup/Prepare-Machine.ps1' @('-Phase',$phase,'-WhatIf')
 Assert-TeamTest ($result.code -eq 0) ($phase+' WhatIf avoids privileged operations/prompts')
}
$profile=Join-Path $fixture '.local/config/profile.json'
[IO.Directory]::CreateDirectory((Split-Path -Parent $profile)) | Out-Null
'{}' | Set-Content -LiteralPath $profile
$result=Invoke-Tool 'setup/Prepare-Machine.ps1' @('-Phase','CreateRuntime','-WhatIf')
Assert-TeamTest ($result.code -ne 0 -and $result.output.Contains('Provisioned/partial workspace')) 'Provisioned workspace refused even in WhatIf'
Remove-Item -LiteralPath $profile
$result=Invoke-Tool 'Initialize-MachineConfig.ps1' @('-RuntimeUser','bad;name')
Assert-TeamTest ($result.code -ne 0) 'Invalid runtime name refused'
$result=Invoke-Tool 'Initialize-MachineConfig.ps1' @('-SqlInstance','host\remote;')
Assert-TeamTest ($result.code -ne 0) 'Invalid SQL identifier refused'
# Worktree metadata, machine config and private formats must never enter source exports.
'.git points outside source' | Set-Content -LiteralPath (Join-Path $fixture '.git')
'not-a-real-private-key' | Set-Content -LiteralPath (Join-Path $fixture 'hidden.clixml')
'local-only' | Set-Content -LiteralPath (Join-Path $fixture '.env.local')
'sample' | Set-Content -LiteralPath (Join-Path $fixture 'public-source.txt')
. (Join-Path $root 'tools/SourcePackage.ps1')
$files=@(Get-Dbms12SourceFiles -Root $fixture)
Assert-TeamTest (-not @($files | Where-Object {$_.path -match '(^\.local/|^\.git$|^\.env|machine\.json$|\.clixml$)'}).Count) 'Private state and worktree metadata excluded'
$fakeToken=('gh'+'p_'+('X'*40))
$secretPath=Join-Path $fixture 'accidental.txt'
$fakeToken | Set-Content -LiteralPath $secretPath
$blocked=$false
try{Test-Dbms12SourceContents -Files @(Get-Dbms12SourceFiles -Root $fixture)}catch{$blocked=$_.Exception.Message.Contains('githubToken') -and -not $_.Exception.Message.Contains($fakeToken)}
Assert-TeamTest $blocked 'Secret format blocks publication without logging its value'
Remove-Item -LiteralPath $secretPath
$export=Join-Path $fixture 'export-outside-source'
# Export destination cannot be inside source, including a directory that would be copied recursively.
$sibling=Join-Path (Split-Path -Parent $fixture) ([IO.Path]::GetFileName($fixture)+'-export')
$result=Invoke-Tool 'Export-TeamSource.ps1' @('-Destination',$sibling)
Assert-TeamTest ($result.code -eq 0 -and (Test-Path -LiteralPath (Join-Path $sibling 'public-source.txt')) -and -not(Test-Path -LiteralPath (Join-Path $sibling '.local'))) 'Clean export copied only source'
$result=Invoke-Tool 'Export-TeamSource.ps1' @('-Destination',$sibling)
Assert-TeamTest ($result.code -ne 0) 'Existing export destination refused'
$result=Invoke-Tool 'Export-TeamSource.ps1' @('-Destination',$export)
Assert-TeamTest ($result.code -ne 0 -and -not(Test-Path -LiteralPath $export)) 'Export into visible source subtree refused'
# Doctor on a clone with no machine.json must report missing config, without creating it.
$doctorRoot=Join-Path $fixture 'doctor'
[IO.Directory]::CreateDirectory((Join-Path $doctorRoot 'tools/setup')) | Out-Null
foreach($relative in @('.dbms12-project.json','tools/Test-Environment.ps1','tools/setup/TeamSetup.Common.ps1')){[IO.File]::Copy((Join-Path $fixture $relative),(Join-Path $doctorRoot $relative))}
$raw=& pwsh -NoProfile -File (Join-Path $doctorRoot 'tools/Test-Environment.ps1') -Mode Run -AsJson
$exit=$LASTEXITCODE;$doctor=($raw -join "`n") | ConvertFrom-Json
Assert-TeamTest ($exit -eq 1 -and $doctor.missing -gt 0 -and -not $doctor.applicationReadyVerified -and -not(Test-Path -LiteralPath (Join-Path $doctorRoot 'config/machine.json'))) 'Missing-config doctor reports failure without writes or fake readiness'
[pscustomobject]@{pass=$true;checks=$checks.ToArray();count=$checks.Count;privilegedSetupExecuted=$false;fixtureRetained=$true} | ConvertTo-Json -Depth 4
exit 0
