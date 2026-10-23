[CmdletBinding()]
param([string]$Destination)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$marker=Get-Content -Raw -LiteralPath (Join-Path $projectRoot '.dbms12-project.json')|ConvertFrom-Json
if($marker.projectId -cne 'cd991085-f47e-4f5e-915d-69c9a15156a8'){throw 'Project marker guard.'}
if(-not $Destination){$Destination=Join-Path ([IO.Directory]::GetParent($projectRoot).FullName) 'DBMS12_EnglishCenter.zip'}
$destinationPath=[IO.Path]::GetFullPath($Destination)
if(Test-Path -LiteralPath $destinationPath){throw 'Destination exists. Choose a new name; no overwrite is performed.'}
. (Join-Path $PSScriptRoot 'SourcePackage.ps1')
$sourceFiles=@(Get-Dbms12SourceFiles -Root $projectRoot)
Test-Dbms12SourceContents -Files $sourceFiles
$stream=[IO.FileStream]::new($destinationPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{
 $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
 try{foreach($file in $sourceFiles){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.fullName,'DBMS12_EnglishCenter/'+$file.path,[IO.Compression.CompressionLevel]::Optimal)}}finally{$zip.Dispose()}
}finally{$stream.Dispose()}
[pscustomobject]@{path=$destinationPath;files=$sourceFiles.Count;bytes=(Get-Item -LiteralPath $destinationPath).Length;sha256=(Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash;privateStateExcluded=$true}|ConvertTo-Json
