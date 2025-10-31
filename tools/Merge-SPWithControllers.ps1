<#
.SYNOPSIS
    Merges stored procedure catalog with controller dependency scan results.

.DESCRIPTION
    Combines the output from Scan-ControllerDependencies.ps1 and Extract-StoredProcedures.ps1
    to create a comprehensive migration planning report.

.PARAMETER DependencyScanPath
    Path to the ISmartComponentService usage CSV from Scan-ControllerDependencies.ps1

.PARAMETER SPCatalogPath
    Path to the stored procedure catalog CSV from Extract-StoredProcedures.ps1

.PARAMETER OutputPath
    Path where the merged report CSV will be saved.

.EXAMPLE
    .\Merge-SPWithControllers.ps1 -DependencyScanPath ".\ISmartComponentService_Usage.csv" -SPCatalogPath ".\StoredProcedure_Catalog.csv"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$DependencyScanPath,
    
    [Parameter(Mandatory=$true)]
    [string]$SPCatalogPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\Migration_Analysis_Report.csv"
)

Write-Host "=== Migration Analysis Report Generator ===" -ForegroundColor Cyan
Write-Host ""

# Verify input files exist
if (-not (Test-Path $DependencyScanPath)) {
    Write-Error "Dependency scan file not found: $DependencyScanPath"
    exit 1
}

if (-not (Test-Path $SPCatalogPath)) {
    Write-Error "SP catalog file not found: $SPCatalogPath"
    exit 1
}

Write-Host "Loading data..." -ForegroundColor Yellow

# Load CSV files
$dependencies = Import-Csv $DependencyScanPath
$spCatalog = Import-Csv $SPCatalogPath

Write-Host "  ✓ Loaded $($dependencies.Count) dependency records" -ForegroundColor Gray
Write-Host "  ✓ Loaded $($spCatalog.Count) SP records" -ForegroundColor Gray
Write-Host ""

# Analyze by controller
Write-Host "Analyzing controllers..." -ForegroundColor Yellow

$controllerAnalysis = @{}

# Group dependencies by controller
$depsByController = $dependencies | Group-Object ControllerName

foreach ($group in $depsByController) {
    $controllerName = $group.Name
    
    # Count high severity dependencies
    $highSeverityCount = ($group.Group | Where-Object Severity -eq "High").Count
    
    # Get unique SPs for this controller
    $spsForController = $spCatalog | Where-Object ControllerName -eq $controllerName
    $uniqueSPs = ($spsForController | Select-Object -ExpandProperty SPName -Unique).Count
    
    # Check mapper usage
    $hardCodedSPs = ($spsForController | Where-Object UsesMapper -eq $false).Count
    $mapperSPs = ($spsForController | Where-Object UsesMapper -eq $true).Count
    
    # Categorize SPs
    $readOps = ($spsForController | Where-Object Category -eq "Read").Count
    $writeOps = ($spsForController | Where-Object { $_.Category -in @("Create", "Update", "Delete") }).Count
    
    $controllerAnalysis[$controllerName] = @{
        DependencyCount = $group.Count
        HighSeverityCount = $highSeverityCount
        UniqueSPs = $uniqueSPs
        HardCodedSPs = $hardCodedSPs
        MapperSPs = $mapperSPs
        ReadOps = $readOps
        WriteOps = $writeOps
    }
}

# Generate merged report
Write-Host "Generating report..." -ForegroundColor Yellow

$report = @()

foreach ($controller in $controllerAnalysis.Keys | Sort-Object) {
    $analysis = $controllerAnalysis[$controller]
    
    # Calculate complexity score (0-100)
    $complexityScore = 0
    $complexityScore += [Math]::Min($analysis.DependencyCount * 5, 30)  # Max 30 points
    $complexityScore += [Math]::Min($analysis.UniqueSPs * 3, 20)        # Max 20 points
    $complexityScore += [Math]::Min($analysis.WriteOps * 5, 25)         # Max 25 points
    $complexityScore += [Math]::Min($analysis.HardCodedSPs * 2, 15)     # Max 15 points
    $complexityScore += [Math]::Min($analysis.HighSeverityCount * 2, 10) # Max 10 points
    
    # Determine complexity tier
    $complexityTier = if ($complexityScore -ge 70) { "Complex" }
                     elseif ($complexityScore -ge 40) { "Medium" }
                     else { "Simple" }
    
    # Estimate effort (hours)
    $baseHours = 8
    $effortHours = $baseHours + ($analysis.DependencyCount * 2) + ($analysis.UniqueSPs * 4)
    
    # Determine risk level
    $riskLevel = if ($analysis.WriteOps -gt 5 -or $complexityScore -ge 70) { "High" }
                elseif ($analysis.WriteOps -gt 2 -or $complexityScore -ge 40) { "Medium" }
                else { "Low" }
    
    # Migration readiness score (0-100, higher is better/easier to migrate)
    $readinessScore = 100 - $complexityScore
    $readinessScore += ($analysis.MapperSPs * 2) - ($analysis.HardCodedSPs * 2)
    $readinessScore = [Math]::Max(0, [Math]::Min(100, $readinessScore))
    
    $report += [PSCustomObject]@{
        ControllerName = $controller
        ComplexityTier = $complexityTier
        ComplexityScore = $complexityScore
        ReadinessScore = $readinessScore
        DependencyCount = $analysis.DependencyCount
        HighSeverityDeps = $analysis.HighSeverityCount
        UniqueSPs = $analysis.UniqueSPs
        HardCodedSPs = $analysis.HardCodedSPs
        MapperSPs = $analysis.MapperSPs
        ReadOperations = $analysis.ReadOps
        WriteOperations = $analysis.WriteOps
        EstimatedHours = $effortHours
        RiskLevel = $riskLevel
        MigrationPriority = if ($complexityScore -ge 70) { "High" } 
                           elseif ($complexityScore -ge 40) { "Medium" } 
                           else { "Low" }
    }
}

# Export report
$report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host ""
Write-Host "=== Report Summary ===" -ForegroundColor Cyan
Write-Host "Total controllers analyzed: $($report.Count)" -ForegroundColor White
Write-Host ""

Write-Host "Complexity Distribution:" -ForegroundColor Cyan
$report | Group-Object ComplexityTier | Sort-Object Name | ForEach-Object {
    $color = switch ($_.Name) {
        "Complex" { "Red" }
        "Medium" { "Yellow" }
        "Simple" { "Green" }
    }
    Write-Host "  $($_.Name.PadRight(10)): $($_.Count)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Risk Distribution:" -ForegroundColor Cyan
$report | Group-Object RiskLevel | Sort-Object Name | ForEach-Object {
    $color = switch ($_.Name) {
        "High" { "Red" }
        "Medium" { "Yellow" }
        "Low" { "Green" }
    }
    Write-Host "  $($_.Name.PadRight(10)): $($_.Count)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Total Estimated Effort: $([Math]::Round(($report | Measure-Object EstimatedHours -Sum).Sum, 0)) hours" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== Top 10 Most Complex Controllers ===" -ForegroundColor Cyan
$report | Sort-Object ComplexityScore -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.ControllerName.PadRight(30)) Score: $($_.ComplexityScore.ToString().PadLeft(3))  [$($_.ComplexityTier)]  Risk: $($_.RiskLevel)" -ForegroundColor $(
        if ($_.ComplexityTier -eq "Complex") { "Red" }
        elseif ($_.ComplexityTier -eq "Medium") { "Yellow" }
        else { "White" }
    )
}

Write-Host ""
Write-Host "=== Top 10 Most Ready for Migration ===" -ForegroundColor Cyan
$report | Sort-Object ReadinessScore -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.ControllerName.PadRight(30)) Readiness: $($_.ReadinessScore.ToString().PadLeft(3))%  [$($_.ComplexityTier)]" -ForegroundColor Green
}

Write-Host ""
Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
Write-Host ""
