# Shared source inventory for ZIP and Git export; never enumerates private/build directories.
function Get-Dbms12SourceFiles {
 param([string]$Root)
 $rootPath=[IO.Path]::GetFullPath($Root)
 $marker=Get-Content -LiteralPath (Join-Path $rootPath '.dbms12-project.json') -Raw | ConvertFrom-Json
 if($marker.projectId -cne 'cd991085-f47e-4f5e-915d-69c9a15156a8'){throw 'Wrong source project marker.'}
 $files=[Collections.Generic.List[object]]::new()
 $excluded=@('.local','.git','node_modules','bin','obj','dist','.vs','.idea','__pycache__')
 function Add-TeamSource([string]$Folder){
  foreach($entry in Get-ChildItem -LiteralPath $Folder -Force){
   if($entry.Name -eq '.git'){continue}
   if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Source reparse point refused.'}
   if($entry.PSIsContainer){if($entry.Name -notin $excluded){Add-TeamSource $entry.FullName};continue}
   $relative=$entry.FullName.Substring($rootPath.Length).TrimStart('\','/').Replace('\','/')
   if($relative -ceq 'config/machine.json' -or $entry.Name -like '.env*' -or $entry.Name -like 'tempCodeRunnerFile.*' -or $entry.Extension.ToLowerInvariant() -in @('.zip','.dpapi','.bak','.trn','.pfx','.p12','.key','.pem','.cer','.crt','.clixml','.mdf','.ldf','.user','.log','.pyc')){continue}
   if($relative.StartsWith('../') -or [IO.Path]::IsPathRooted($relative)){throw 'Source path escaped root.'}
   $files.Add([pscustomobject]@{path=$relative;fullName=$entry.FullName;bytes=$entry.Length})
  }
 }
 Add-TeamSource $rootPath
 return $files.ToArray() | Sort-Object path
}
function Test-Dbms12SourceContents {
 param([object[]]$Files)
 # Only flag high-confidence secret formats, and print filenames/reasons, never matching values.
 $patterns=@{
  privateKey=('-----'+'BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY'+'-----')
  githubToken=('gh[pousr]'+'_[A-Za-z0-9]{30,}|github_pat'+'_[A-Za-z0-9_]{50,}')
  jwt=('eyJ[A-Za-z0-9_-]{12,}'+'\.eyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{30,}')
  dpapiBlob=('01000000'+'d08c9ddf0115d1118c7a00c04fc297eb[0-9a-fA-F]{60,}')
  passwordHash=('AQAAAA[EI]'+'[A-Za-z0-9+/]{70,}={0,2}')
 }
 $findings=[Collections.Generic.List[string]]::new()
 foreach($file in $Files){
  if([IO.Path]::GetExtension($file.path).ToLowerInvariant() -in @('.png','.jpg','.jpeg','.woff2','.pdf','.docx','.ico')){continue}
  $content=[IO.File]::ReadAllText($file.fullName)
  foreach($name in $patterns.Keys){if($content -match $patterns[$name]){$findings.Add($file.path+': '+$name)}}
 }
 if($findings.Count){throw ('Possible secret format found; inspect locally, do not publish: '+($findings -join ', '))}
}
