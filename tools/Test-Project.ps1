[CmdletBinding()]
param([switch]$CheckDatabase)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location $projectRoot
try{
 & node tools/Verify-Source.cjs;if($LASTEXITCODE -ne 0){throw 'Source verification failed.'}
 & dotnet restore backend/EnglishCenter.Dbms12/EnglishCenter.Dbms12.csproj --locked-mode;if($LASTEXITCODE -ne 0){throw 'NuGet restore/audit failed.'}
 & dotnet build backend/EnglishCenter.Dbms12/EnglishCenter.Dbms12.csproj --no-restore;if($LASTEXITCODE -ne 0){throw 'Backend build failed.'}
 if(-not(Test-Path frontend/node_modules/.package-lock.json)){& npm.cmd --prefix frontend ci --no-audit --no-fund;if($LASTEXITCODE -ne 0){throw 'npm ci failed.'}}
 foreach($step in @('typecheck','lint','test','build')){& npm.cmd --prefix frontend run $step;if($LASTEXITCODE -ne 0){throw ('Frontend '+$step+' failed.')}}
 if($CheckDatabase){
  $profile=Join-Path $projectRoot '.local/config/profile.json'
  if(-not(Test-Path -LiteralPath $profile)){throw 'Start project once before -CheckDatabase; no automatic seed during tests.'}
  & dotnet backend/EnglishCenter.Dbms12/bin/Debug/net10.0/EnglishCenter.Dbms12.dll --check-profile $profile;if($LASTEXITCODE -ne 0){throw 'Database read-only verification failed.'}
 }
 Write-Output 'Project checks PASS. Browser mutation suites are separate, explicit and documented in memory/05_RUNBOOK.md.'
}finally{Pop-Location}
