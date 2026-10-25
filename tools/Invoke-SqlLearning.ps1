[CmdletBinding()]
param([string]$FixtureProfile,[switch]$Prepare,[switch]$All,[string]$Case,[string]$Group,[switch]$CommitTransactions,[switch]$ForceRollback)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$practiceRoot=Join-Path $projectRoot 'database/practice'
$catalog=Get-Content (Join-Path $practiceRoot 'catalog.json') -Raw | ConvertFrom-Json
if(-not($Prepare -or $All -or $Case -or $Group)){Write-Output 'Dùng -Prepare, -Case functions/fn_GradeTotal.sql, -Group functions hoặc -All. Profile phải là fixture riêng.';return}
if(($CommitTransactions -or $ForceRollback) -and $Group -ne 'transactions'){throw 'Commit/forced rollback chỉ dùng với -Group transactions.'}
if(-not $FixtureProfile){$fixtureRoot=(Get-Content (Join-Path $projectRoot '.local/security-redesign/fixture-path.txt') -Raw).Trim();$FixtureProfile=Join-Path $fixtureRoot '.local/config/profile.json'}
$FixtureProfile=[IO.Path]::GetFullPath($FixtureProfile)
$p=Get-Content $FixtureProfile -Raw | ConvertFrom-Json
$fixturePrefix=Join-Path $projectRoot '.local/security-redesign/fixture-'
if($p.Workspace -notmatch ('^'+[Regex]::Escape($fixturePrefix)+'[0-9a-f]{32}$') -or $FixtureProfile -cne [IO.Path]::GetFullPath((Join-Path $p.Workspace '.local/config/profile.json'))){throw 'Learning lab chỉ nhận profile security fixture, không nhận PROJECT chính.'}
if($p.Database -notmatch '^EnglishCenter_DBMS12_PROJECT_[0-9a-f]{32}$' -or $p.DatabaseId -le 4){throw 'Database identity guard.'}
$databaseGuid=[Guid]::Parse($p.DatabaseGuid);$fileGuid=[Guid]::Parse($p.FileGuid)
if($p.ManifestSha256 -cne (Get-FileHash (Join-Path $projectRoot 'database/dbms12-compact/manifest.json') -Algorithm SHA256).Hash){throw 'Fixture source pin khác phiên bản hiện tại; không tự refresh hoặc reset.'}
$identity=@"
SET NOCOUNT ON;
IF DB_NAME()<>N'$($p.Database)' OR DB_ID()<>$($p.DatabaseId)
 OR NOT EXISTS(SELECT 1 FROM sys.database_recovery_status WHERE database_id=DB_ID() AND database_guid='$databaseGuid')
 OR NOT EXISTS(SELECT 1 FROM sys.database_files WHERE file_id=1 AND file_guid='$fileGuid')
 THROW 51990,N'Learning exact fixture identity mismatch.',1;
"@
$private=Join-Path $projectRoot '.local/operator/sql-learning'
[void][IO.Directory]::CreateDirectory($private)
function Invoke-LearningSql([string]$sql,[string]$stem){
 $inputPath=Join-Path $runFolder ($stem+'.sql');$logPath=Join-Path $runFolder ($stem+'.txt')
 [IO.File]::WriteAllText($inputPath,$sql)
 & sqlcmd -S $p.Machine.SqlServer -d $p.Database -E -Nm -F $p.Machine.SqlHostName -b -x -X1 -f 65001 -t 90 -i $inputPath -o $logPath
 if($LASTEXITCODE -ne 0){throw ('SQL lab failed: '+$stem+'. Log private: '+$logPath)}
 return [IO.File]::ReadAllText($logPath)
}
$runFolder=Join-Path $private ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')+'-'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runFolder)
if($Prepare){
 $mark=$identity+@"
IF USER_NAME()<>'dbo' THROW 51990,N'Owner required for fixture marker.',1;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'DBMS12_LearningFixture' AND CONVERT(nvarchar(36),value)<>N'$databaseGuid') THROW 51990,N'Existing marker mismatch.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'DBMS12_LearningFixture') EXEC sys.sp_addextendedproperty @name=N'DBMS12_LearningFixture',@value=N'$databaseGuid';
"@
 [void](Invoke-LearningSql $mark 'prepare')
}
$session=$identity+@"
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'DBMS12_LearningFixture' AND CONVERT(nvarchar(36),value)=N'$databaseGuid') THROW 51990,N'Chạy Invoke-SqlLearning.ps1 -Prepare trên fixture trước.',1;
DECLARE @LearningGuid uniqueidentifier='$databaseGuid';
EXEC sys.sp_set_session_context @key=N'ec12_learning_guid',@value=@LearningGuid,@read_only=1;
GO
"@
[IO.File]::WriteAllText((Join-Path $private 'SSMS_SESSION.sql'),"-- Chọn database $($p.Database) trên SSMS trước khi chạy. Không chứa SID/hash/password.`r`n"+$session)
if($Prepare -and -not($All -or $Case -or $Group)){Write-Output ('Learning fixture ready. SSMS session: '+(Join-Path $private 'SSMS_SESSION.sql'));return}
$selected=@($catalog.cases | Where-Object {if($Case){$_.file -ceq $Case}elseif($Group){$_.group -ceq $Group}else{$All}})
if($selected.Count -eq 0){throw 'Không có case phù hợp catalog.json.'}
$results=[Collections.Generic.List[object]]::new()
foreach($item in $selected){
 $casePath=[IO.Path]::GetFullPath((Join-Path $practiceRoot $item.file))
 if(-not $casePath.StartsWith($practiceRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Case path boundary.'}
 $script=[IO.File]::ReadAllText($casePath)
 if($item.group -eq 'transactions'){
  if($CommitTransactions){$script=$script.Replace('DECLARE @CommitLab bit=0','DECLARE @CommitLab bit=1')}
  if($ForceRollback){$script=$script.Replace('@ForceFailure bit=0','@ForceFailure bit=1')}
 }
 $raw=Invoke-LearningSql ($session+$script) ($item.group+'-'+$item.name)
 if(-not $raw.Contains('EC_LAB_PASS|'+$item.name)){throw ('Missing success marker: '+$item.file)}
 $row=[ordered]@{file=$item.file;pass=$true;expectedError=$item.expectedError}
 if($item.group -eq 'indexes'){
  $before=$raw.Split('EC_INDEX_BASELINE|'+$item.name)[1].Split('EC_INDEX_WITH|'+$item.name)[0]
  $after=$raw.Split('EC_INDEX_WITH|'+$item.name)[1].Split('EC_INDEX_END|'+$item.name)[0]
  $r0=@([Regex]::Matches($before,"(?m)^Table '#Lab[^\r\n]*?, logical reads (\d+)") | ForEach-Object {[int]$_.Groups[1].Value})
  $r1=@([Regex]::Matches($after,"(?m)^Table '#Lab[^\r\n]*?, logical reads (\d+)") | ForEach-Object {[int]$_.Groups[1].Value})
  if($r0.Count -ne 1 -or $r1.Count -ne 1 -or $r1[0] -ge $r0[0]){throw ('Chưa chứng minh giảm logical reads: '+$item.name+'; giữ log để điều tra.')}
  $row.baselineLogicalReads=$r0[0];$row.indexedLogicalReads=$r1[0]
 }
 $results.Add([pscustomobject]$row)
 Write-Output ('PASS '+$item.file)
 $results | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $runFolder 'results.json') -Encoding utf8NoBOM
}
$summary=[ordered]@{pass=$true;fixtureOnly=$true;database=$p.Database;id=$p.DatabaseId;guid=$databaseGuid;total=$results.Count;committedTransactions=[bool]$CommitTransactions;forcedRollback=[bool]$ForceRollback;results=$results}
$summary | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $runFolder 'summary.json') -Encoding utf8NoBOM
[IO.File]::WriteAllText((Join-Path $private 'last-run.txt'),$runFolder)
Write-Output ('SQL learning PASS '+$results.Count+'; summary private: '+(Join-Path $runFolder 'summary.json'))
