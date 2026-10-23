[CmdletBinding()]
param([Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'SourcePackage.ps1')
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$target=[IO.Path]::GetFullPath($Destination)
if($target -eq $root -or ($target.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and -not $target.StartsWith((Join-Path $root '.local')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase))){throw 'Export inside source is refused; use a sibling folder or the ignored .local folder.'}
if(Test-Path -LiteralPath $target){throw 'Destination exists; source export never overwrites a checkout.'}
if(-not(Test-Path -LiteralPath (Split-Path -Parent $target) -PathType Container)){throw 'Destination parent must exist.'}
$files=@(Get-Dbms12SourceFiles -Root $root)
Test-Dbms12SourceContents -Files $files
[IO.Directory]::CreateDirectory($target) | Out-Null
foreach($file in $files){
 $path=Join-Path $target $file.path
 [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
 [IO.File]::Copy($file.fullName,$path,$false)
 if((Get-FileHash -LiteralPath $file.fullName -Algorithm SHA256).Hash -cne (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash){throw 'Source copy hash mismatch.'}
}
[pscustomobject]@{files=$files.Count;destination=$target;privateStateExcluded=$true;secretFormatScanPassed=$true;copyHashesMatch=$true} | ConvertTo-Json
