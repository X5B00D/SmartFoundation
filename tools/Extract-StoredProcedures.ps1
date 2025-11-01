<#
.SYNOPSIS
    Extracts all stored procedure names from controller C# files.

.DESCRIPTION
    Scans all controllers to identify stored procedure usage patterns including:
    - ExecuteAsync calls with SP names
    - SmartRequest object initialization
    - Direct SP name string literals
    - ProcedureMapper calls
    
    Outputs a comprehensive catalog with categorization and duplicate detection.

.PARAMETER ProjectPath
    Root path of the SmartFoundation.Mvc project.

.PARAMETER OutputPath
    Path where the SP catalog CSV will be saved.

.EXAMPLE
    .\Extract-StoredProcedures.ps1 -ProjectPath "C:\SmartFoundation\SmartFoundation.Mvc"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\StoredProcedure_Catalog.csv"
)

Write-Host "=== SmartFoundation Stored Procedure Extractor ===" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host ""

$controllersPath = Join-Path $ProjectPath "Controllers"

if (-not (Test-Path $controllersPath)) {
    Write-Error "Controllers directory not found: $controllersPath"
    exit 1
}

$results = @()
$totalFiles = 0
$filesWithSPs = 0
$uniqueSPs = @{}

# Define regex patterns for different SP usage styles
$patterns = @{
    "ExecuteAsync" = 'ExecuteAsync\([^)]*SpName\s*=\s*"([^"]+)"'
    "SmartRequest" = 'new\s+SmartRequest\s*\{[^}]*SpName\s*=\s*"([^"]+)"'
    "DirectSpName" = 'SpName\s*=\s*"([^"]+)"'
    "ProcedureMapper" = 'ProcedureMapper\.GetProcedureName\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)'
    "StringLiteral" = '"(dbo\.|sp_)[^"]*"'
}

function Get-SPCategory {
    param([string]$spName)
    
    if ($spName -match '^(dbo\.)?sp_Get') { return "Read" }
    if ($spName -match '^(dbo\.)?sp_Insert|sp_Create|sp_Add') { return "Create" }
    if ($spName -match '^(dbo\.)?sp_Update|sp_Modify') { return "Update" }
    if ($spName -match '^(dbo\.)?sp_Delete|sp_Remove') { return "Delete" }
    if ($spName -match '^(dbo\.)?sp_List|ListOf') { return "List" }
    if ($spName -match '^(dbo\.)?sp_Exec|sp_Execute') { return "Execute" }
    return "Other"
}

Write-Host "Scanning controllers..." -ForegroundColor Yellow

Get-ChildItem -Path $controllersPath -Filter "*.cs" -Recurse | ForEach-Object {
    $totalFiles++
    $filePath = $_.FullName
    $fileName = $_.Name
    $controllerName = $fileName -replace "\.cs$", ""
    
    Write-Host "  Processing: $fileName" -ForegroundColor Gray
    
    $content = Get-Content $filePath -Raw
    $lines = Get-Content $filePath
    $foundInFile = $false
    
    # Pattern 1: ExecuteAsync with SpName parameter
    $executeMatches = [regex]::Matches($content, $patterns["ExecuteAsync"])
    foreach ($match in $executeMatches) {
        $spName = $match.Groups[1].Value
        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
        
        $results += [PSCustomObject]@{
            ControllerName = $controllerName
            FileName = $fileName
            SPName = $spName
            LineNumber = $lineNumber
            Pattern = "ExecuteAsync"
            Category = Get-SPCategory $spName
            UsesMapper = $false
        }
        
        $uniqueSPs[$spName] = $true
        $foundInFile = $true
    }
    
    # Pattern 2: SmartRequest initialization
    $requestMatches = [regex]::Matches($content, $patterns["SmartRequest"])
    foreach ($match in $requestMatches) {
        $spName = $match.Groups[1].Value
        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
        
        $results += [PSCustomObject]@{
            ControllerName = $controllerName
            FileName = $fileName
            SPName = $spName
            LineNumber = $lineNumber
            Pattern = "SmartRequest"
            Category = Get-SPCategory $spName
            UsesMapper = $false
        }
        
        $uniqueSPs[$spName] = $true
        $foundInFile = $true
    }
    
    # Pattern 3: Direct SpName assignment
    $directMatches = [regex]::Matches($content, $patterns["DirectSpName"])
    foreach ($match in $directMatches) {
        $spName = $match.Groups[1].Value
        
        # Skip if it's a variable or contains @
        if ($spName -match '@' -or $spName -match '\$' -or $spName.Length -lt 5) {
            continue
        }
        
        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
        
        $results += [PSCustomObject]@{
            ControllerName = $controllerName
            FileName = $fileName
            SPName = $spName
            LineNumber = $lineNumber
            Pattern = "DirectAssignment"
            Category = Get-SPCategory $spName
            UsesMapper = $false
        }
        
        $uniqueSPs[$spName] = $true
        $foundInFile = $true
    }
    
    # Pattern 4: ProcedureMapper calls
    $mapperMatches = [regex]::Matches($content, $patterns["ProcedureMapper"])
    foreach ($match in $mapperMatches) {
        $module = $match.Groups[1].Value
        $operation = $match.Groups[2].Value
        $spName = "${module}:${operation}"
        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
        
        $results += [PSCustomObject]@{
            ControllerName = $controllerName
            FileName = $fileName
            SPName = $spName
            LineNumber = $lineNumber
            Pattern = "ProcedureMapper"
            Category = "Mapped"
            UsesMapper = $true
        }
        
        $uniqueSPs[$spName] = $true
        $foundInFile = $true
    }
    
    # Pattern 5: String literals with dbo. or sp_ prefix (potential SP names)
    $literalMatches = [regex]::Matches($content, $patterns["StringLiteral"])
    foreach ($match in $literalMatches) {
        $spName = $match.Groups[0].Value.Trim('"')
        
        # Skip if already found by other patterns
        $alreadyFound = $results | Where-Object { 
            $_.FileName -eq $fileName -and $_.SPName -eq $spName 
        }
        
        if ($alreadyFound -or $spName.Length -lt 8) {
            continue
        }
        
        $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
        
        $results += [PSCustomObject]@{
            ControllerName = $controllerName
            FileName = $fileName
            SPName = $spName
            LineNumber = $lineNumber
            Pattern = "StringLiteral"
            Category = Get-SPCategory $spName
            UsesMapper = $false
        }
        
        $uniqueSPs[$spName] = $true
        $foundInFile = $true
    }
    
    if ($foundInFile) {
        $filesWithSPs++
        Write-Host "    ✓ SPs found" -ForegroundColor Green
    }
}

# Export results
Write-Host ""
Write-Host "Exporting catalog..." -ForegroundColor Yellow
$results | Export-Csv -Path $OutputPath -NoTypeInformation

# Generate summary statistics
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total files scanned: $totalFiles" -ForegroundColor White
Write-Host "Files with SPs: $filesWithSPs" -ForegroundColor Green
Write-Host "Total SP references: $($results.Count)" -ForegroundColor Yellow
Write-Host "Unique SPs: $($uniqueSPs.Count)" -ForegroundColor Yellow
Write-Host ""

# Category breakdown
Write-Host "=== SPs by Category ===" -ForegroundColor Cyan
$results | Group-Object Category | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name.PadRight(15)): $($_.Count)" -ForegroundColor White
}

Write-Host ""

# Pattern breakdown
Write-Host "=== SPs by Pattern ===" -ForegroundColor Cyan
$results | Group-Object Pattern | Sort-Object Count -Descending | ForEach-Object {
    $color = if ($_.Name -eq "ProcedureMapper") { "Green" } else { "Yellow" }
    Write-Host "  $($_.Name.PadRight(20)): $($_.Count)" -ForegroundColor $color
}

Write-Host ""

# Identify hard-coded SPs (not using ProcedureMapper)
$hardCoded = ($results | Where-Object { $_.UsesMapper -eq $false }).Count
$mapperUsed = ($results | Where-Object { $_.UsesMapper -eq $true }).Count

Write-Host "=== Mapper Usage ===" -ForegroundColor Cyan
Write-Host "  Using ProcedureMapper: $mapperUsed" -ForegroundColor Green
Write-Host "  Hard-coded SP names: $hardCoded" -ForegroundColor $(if ($hardCoded -gt 0) { "Red" } else { "Green" })

if ($hardCoded -gt 0) {
    Write-Host ""
    Write-Host "  ⚠ Hard-coded SP names should be migrated to ProcedureMapper!" -ForegroundColor Yellow
}

Write-Host ""

# Find duplicate SP usage across controllers
Write-Host "=== Duplicate SP Usage Across Controllers ===" -ForegroundColor Cyan
$duplicates = $results | 
    Group-Object SPName | 
    Where-Object { $_.Count -gt 1 -and ($_.Group | Select-Object -ExpandProperty ControllerName -Unique).Count -gt 1 } |
    Sort-Object Count -Descending

if ($duplicates.Count -gt 0) {
    foreach ($dup in $duplicates | Select-Object -First 10) {
        $controllers = ($dup.Group | Select-Object -ExpandProperty ControllerName -Unique) -join ", "
        Write-Host "  $($dup.Name) - Used by: $controllers" -ForegroundColor Yellow
    }
    
    if ($duplicates.Count -gt 10) {
        Write-Host "  ... and $($duplicates.Count - 10) more" -ForegroundColor Gray
    }
} else {
    Write-Host "  No duplicate usage found." -ForegroundColor Green
}

Write-Host ""
Write-Host "Catalog saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
