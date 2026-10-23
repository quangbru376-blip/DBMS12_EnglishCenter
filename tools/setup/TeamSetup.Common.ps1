# Shared guards only; dot-sourcing this file makes no machine changes.
Set-StrictMode -Version Latest
function Get-TeamProjectRoot {
 param([string]$ToolsRoot)
 $root=[IO.Path]::GetFullPath((Join-Path $ToolsRoot '..'))
 $marker=Get-Content -LiteralPath (Join-Path $root '.dbms12-project.json') -Raw | ConvertFrom-Json
 if($marker.projectId -cne 'cd991085-f47e-4f5e-915d-69c9a15156a8'){throw 'Wrong DBMS12 project marker.'}
 return $root
}
function Assert-TeamWindows {
 if(-not $IsWindows -or -not [Environment]::Is64BitProcess -or $PSVersionTable.PSVersion -lt [version]'7.4'){throw 'Use 64-bit PowerShell7.4 or newer on Windows.'}
}
function Assert-TeamFreshWorkspace {
 param([string]$Root)
 foreach($relative in @('.local/config/profile.json','.local/operator/ownership.json','.local/operator/creation.json')){
  if(Test-Path -LiteralPath (Join-Path $Root $relative)){throw 'Provisioned/partial workspace: setup refused. Keep existing state and inspect; use a fresh clone for a new machine.'}
 }
 # OwnerProvision also guards its receipts. Do not run setup over any provision attempt.
 if(Test-Path -LiteralPath (Join-Path $Root '.local/operator')){
  if(@(Get-ChildItem -LiteralPath (Join-Path $Root '.local/operator') -File -Force).Count){throw 'Existing operator state: setup refused.'}
 }
}
function Assert-TeamRuntimeName {
 param([string]$Name)
 if($Name -cnotmatch '^[A-Za-z][A-Za-z0-9_]{0,19}$'){throw 'Runtime name must start with a letter and contain at most20 ASCII letters/digits/underscores.'}
}
function Assert-TeamPlainPath {
 param([string]$Path)
 if(-not [IO.Path]::IsPathFullyQualified($Path) -or $Path.StartsWith('\\')){throw 'Use an absolute local path.'}
 $cursor=[IO.Path]::GetFullPath($Path)
 while($cursor){
  if(Test-Path -LiteralPath $cursor){if((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Reparse-point path refused.'}}
  $parent=[IO.Path]::GetDirectoryName($cursor)
  if($parent -eq $cursor){break};$cursor=$parent
 }
}
function Assert-TeamAdmin {
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'This phase needs an elevated PowerShell of the machine owner.'}
}
function New-TeamPrivateFolder {
 param([string]$Path,[Security.Principal.SecurityIdentifier]$RuntimeSid)
 Assert-TeamPlainPath $Path
 if(Test-Path -LiteralPath $Path){throw 'Folder already exists; inspect it, do not overwrite existing custody.'}
 [void][IO.Directory]::CreateDirectory($Path)
 $acl=[Security.AccessControl.DirectorySecurity]::new()
 $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User
 $acl.SetOwner($owner);$acl.SetAccessRuleProtection($true,$false)
 $inherit=[Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
 foreach($sid in @($owner,[Security.Principal.SecurityIdentifier]::new('S-1-5-18'))){
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl',$inherit,'None','Allow'))
 }
 if($RuntimeSid){$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($RuntimeSid,'Modify',$inherit,'None','Allow'))}
 [IO.FileSystemAclExtensions]::SetAccessControl([IO.DirectoryInfo]::new($Path),$acl)
}
