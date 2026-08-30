param(
    [string]$InputDocx = 'Documentation/SmartFoundation_System_Documentation.docx',
    [string]$OutputDirectory = 'Documentation/.word_qa/render1'
)

$resolvedInput = (Resolve-Path -LiteralPath $InputDocx).Path
$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
$documentationRoot = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'Documentation'))
if (-not $resolvedOutput.StartsWith($documentationRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must remain inside Documentation.'
}
New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null
$pdfPath = Join-Path $resolvedOutput 'system-render-temp.pdf'

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.ScreenUpdating = $false
    $word.Options.UpdateLinksAtOpen = $false
    $document = $word.Documents.Open($resolvedInput, $false, $false, $false)
    foreach ($toc in $document.TablesOfContents) { $toc.Update() }
    foreach ($field in $document.Fields) { $field.Update() | Out-Null }
    foreach ($section in $document.Sections) {
        foreach ($header in $section.Headers) { foreach ($field in $header.Range.Fields) { $field.Update() | Out-Null } }
        foreach ($footer in $section.Footers) { foreach ($field in $footer.Range.Fields) { $field.Update() | Out-Null } }
    }
    $document.Repaginate()
    $document.Save()
    $document.ExportAsFixedFormat($pdfPath, 17)
}
finally {
    if ($document) { $document.Close($false) }
    if ($word) { $word.Quit() }
    if ($document) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null }
    if ($word) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null }
}

$pdftoppm = 'C:\Users\samia\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdftoppm.exe'
& $pdftoppm -png -r 150 $pdfPath (Join-Path $resolvedOutput 'page')
if ($LASTEXITCODE -ne 0) { throw "pdftoppm failed with exit code $LASTEXITCODE" }
Remove-Item -LiteralPath $pdfPath -Force
Write-Output $resolvedOutput
