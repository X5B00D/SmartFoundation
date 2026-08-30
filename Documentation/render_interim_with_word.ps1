param(
    [Parameter(Mandatory = $true)][string]$InputDocx,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$resolvedInput = (Resolve-Path -LiteralPath $InputDocx).Path
$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
if (-not $resolvedOutput.StartsWith([System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'Documentation')),
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must remain inside Documentation.'
}
New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null
$pdfPath = Join-Path $resolvedOutput 'interim-render-temp.pdf'

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.ScreenUpdating = $false
    $word.Options.UpdateLinksAtOpen = $false
    $word.Options.CheckGrammarAsYouType = $false
    $word.Options.CheckSpellingAsYouType = $false
    $document = $word.Documents.Open($resolvedInput, $false, $true, $false)
    $document.SaveAs2($pdfPath, 17)
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
