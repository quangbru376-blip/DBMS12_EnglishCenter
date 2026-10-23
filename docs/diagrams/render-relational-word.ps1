param([Parameter(Mandatory)][string]$ProjectRoot)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath($ProjectRoot)
$taskInput=Join-Path $taskRoot 'docs/diagrams/Luoc-do-quan-he-DBMS12.docx'
$taskOutput=Join-Path $taskRoot '.local/relational-word-qa'
[void][IO.Directory]::CreateDirectory($taskOutput)
$taskPdf=Join-Path $taskOutput 'Luoc-do-quan-he-DBMS12.pdf'
$taskWord=$null
$taskDocument=$null
$taskOwnEmptyInstance=$false
try {
    $taskWord=New-Object -ComObject Word.Application
    if ($taskWord.Documents.Count -ne 0) {throw 'Refusing to use a Word instance that already contains documents.'}
    $taskOwnEmptyInstance=$true
    $taskWord.Visible=$false
    $taskWord.DisplayAlerts=0
    $taskWord.AutomationSecurity=3
    $taskDocument=$taskWord.Documents.Open($taskInput,$false,$true,$false)
    $taskDocument.Repaginate()
    $taskPages=$taskDocument.ComputeStatistics(2)
    $taskDocument.ExportAsFixedFormat($taskPdf,17)
    @{renderer='Microsoft Word isolated empty instance';readOnly=$true;pages=$taskPages;pdf=$taskPdf} | ConvertTo-Json -Compress
}
finally {
    if ($null -ne $taskDocument) {
        $taskDocument.Close(0)
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskDocument)
    }
    if ($null -ne $taskWord -and $taskOwnEmptyInstance) {
        $taskWord.Quit(0)
        [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($taskWord)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
