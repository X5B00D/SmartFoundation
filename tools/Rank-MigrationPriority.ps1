<#
.SYNOPSIS
    Combines IIS traffic analysis with controller complexity analysis to generate final migration priority rankings.

.DESCRIPTION
    This script merges traffic data from IIS log analysis with complexity metrics from controller scanning
    to produce a comprehensive migration priority matrix. Controllers are ranked based on:
    - Request volume (high-traffic controllers are higher priority)
    - Average response time (slow controllers are higher priority)
    - Complexity score (from complexity analysis)
    - Business impact (traffic percentage)
    
    Priority Levels:
    - CRITICAL: High traffic + High complexity (>70 complexity, >5000 requests OR >1000ms response time)
    - HIGH: High traffic OR High complexity (>70 complexity OR >5000 requests)
    - MEDIUM: Medium traffic + Medium complexity (40-69 complexity, 1000-5000 requests)
    - LOW: Low traffic + Low complexity (<40 complexity, <1000 requests)

.PARAMETER TrafficCsvPath
    Path to the IIS traffic analysis CSV file (output from Analyze-IISTraffic.ps1).

.PARAMETER ComplexityCsvPath
    Path to the controller complexity analysis CSV file (output from Merge-SPWithControllers.ps1).

.PARAMETER OutputPath
    Path where the final migration priority ranking CSV will be saved.
    Defaults to .\Migration_Priority_Ranking.csv.

.EXAMPLE
    .\Rank-MigrationPriority.ps1 -TrafficCsvPath ".\IIS_Traffic_Analysis.csv" -ComplexityCsvPath ".\Migration_Analysis_Report.csv"

.EXAMPLE
    .\Rank-MigrationPriority.ps1 -TrafficCsvPath ".\traffic.csv" -ComplexityCsvPath ".\complexity.csv" -OutputPath ".\final_priority.csv"

.NOTES
    Author: SmartFoundation Team
    Version: 1.0
    Requires: PowerShell 5.1 or higher
    Prerequisites: 
      - IIS_Traffic_Analysis.csv (from Analyze-IISTraffic.ps1)
      - Migration_Analysis_Report.csv (from Merge-SPWithControllers.ps1)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TrafficCsvPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ComplexityCsvPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\Migration_Priority_Ranking.csv"
)

# Error handling setup
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "=== Migration Priority Ranking Tool ===" -ForegroundColor Cyan
Write-Host "Traffic CSV: $TrafficCsvPath" -ForegroundColor Gray
Write-Host "Complexity CSV: $ComplexityCsvPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
Write-Host ""

# Validate input files
if (-not (Test-Path $TrafficCsvPath)) {
    Write-Error "Traffic CSV not found: $TrafficCsvPath"
    Write-Host "Please run Analyze-IISTraffic.ps1 first." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ComplexityCsvPath)) {
    Write-Error "Complexity CSV not found: $ComplexityCsvPath"
    Write-Host "Please run Merge-SPWithControllers.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Load data
Write-Host "Loading traffic data..." -ForegroundColor Cyan
try {
    $trafficData = Import-Csv $TrafficCsvPath
    Write-Host "  Loaded $($trafficData.Count) traffic records" -ForegroundColor Green
} catch {
    Write-Error "Failed to load traffic CSV: $_"
    exit 1
}

Write-Host "Loading complexity data..." -ForegroundColor Cyan
try {
    $complexityData = Import-Csv $ComplexityCsvPath
    Write-Host "  Loaded $($complexityData.Count) complexity records" -ForegroundColor Green
} catch {
    Write-Error "Failed to load complexity CSV: $_"
    exit 1
}

Write-Host ""

# Create lookup dictionaries for faster merging
$trafficLookup = @{}
foreach ($record in $trafficData) {
    $trafficLookup[$record.ControllerName] = $record
}

$complexityLookup = @{}
foreach ($record in $complexityData) {
    $complexityLookup[$record.ControllerName] = $record
}

# Merge data and calculate priority
Write-Host "Calculating migration priorities..." -ForegroundColor Cyan
$results = @()
$processedControllers = @{}

# Process controllers from complexity data (these need migration)
foreach ($complexityRecord in $complexityData) {
    $controllerName = $complexityRecord.ControllerName
    
    # Get traffic data (may not exist if controller has no recent traffic)
    $trafficRecord = $trafficLookup[$controllerName]
    
    $requestCount = if ($trafficRecord) { [int]$trafficRecord.RequestCount } else { 0 }
    $trafficPercent = if ($trafficRecord) { [double]$trafficRecord.TrafficPercent } else { 0.0 }
    $avgResponseTime = if ($trafficRecord) { [double]$trafficRecord.AvgResponseTimeMs } else { 0.0 }
    $peakHour = if ($trafficRecord) { $trafficRecord.PeakHour } else { "N/A" }
    
    $complexityScore = [int]$complexityRecord.ComplexityScore
    $complexityTier = $complexityRecord.ComplexityTier
    $readinessScore = [int]$complexityRecord.ReadinessScore
    $dependencyCount = [int]$complexityRecord.DependencyCount
    $uniqueSPs = [int]$complexityRecord.UniqueSPs
    $hardCodedSPs = [int]$complexityRecord.HardCodedSPs
    $estimatedHours = [int]$complexityRecord.EstimatedHours
    $riskLevel = $complexityRecord.RiskLevel
    
    # Calculate priority score (0-100, higher = more urgent)
    # Factors:
    # - Traffic volume (0-40 points): more traffic = higher priority
    # - Complexity (0-30 points): more complex = higher priority (counter-intuitive but important to tackle)
    # - Response time (0-20 points): slower = higher priority
    # - Hard-coded SPs (0-10 points): more hard-coded = higher priority
    
    $priorityScore = 0
    
    # Traffic volume (0-40 points)
    if ($requestCount -gt 10000) { $priorityScore += 40 }
    elseif ($requestCount -gt 5000) { $priorityScore += 30 }
    elseif ($requestCount -gt 1000) { $priorityScore += 20 }
    elseif ($requestCount -gt 100) { $priorityScore += 10 }
    
    # Complexity (0-30 points)
    if ($complexityScore -gt 80) { $priorityScore += 30 }
    elseif ($complexityScore -gt 70) { $priorityScore += 25 }
    elseif ($complexityScore -gt 50) { $priorityScore += 20 }
    elseif ($complexityScore -gt 30) { $priorityScore += 15 }
    else { $priorityScore += 10 }
    
    # Response time (0-20 points)
    if ($avgResponseTime -gt 2000) { $priorityScore += 20 }
    elseif ($avgResponseTime -gt 1000) { $priorityScore += 15 }
    elseif ($avgResponseTime -gt 500) { $priorityScore += 10 }
    elseif ($avgResponseTime -gt 100) { $priorityScore += 5 }
    
    # Hard-coded SPs penalty (0-10 points)
    if ($hardCodedSPs -gt 5) { $priorityScore += 10 }
    elseif ($hardCodedSPs -gt 2) { $priorityScore += 5 }
    
    # Determine priority level
    $priorityLevel = if ($priorityScore -gt 70) { "CRITICAL" }
                     elseif ($priorityScore -gt 50) { "HIGH" }
                     elseif ($priorityScore -gt 30) { "MEDIUM" }
                     else { "LOW" }
    
    # Determine recommended migration order rank
    $migrationPhase = if ($priorityLevel -eq "CRITICAL") { "Phase 1 (Week 1-2)" }
                      elseif ($priorityLevel -eq "HIGH") { "Phase 2 (Week 3-4)" }
                      elseif ($priorityLevel -eq "MEDIUM") { "Phase 3 (Week 5-6)" }
                      else { "Phase 4 (Week 7+)" }
    
    # Calculate business impact score (traffic + performance consideration)
    $businessImpact = if ($requestCount -gt 5000 -or $avgResponseTime -gt 1000) { "High" }
                      elseif ($requestCount -gt 1000 -or $avgResponseTime -gt 500) { "Medium" }
                      else { "Low" }
    
    $results += [PSCustomObject]@{
        ControllerName = $controllerName
        PriorityLevel = $priorityLevel
        PriorityScore = $priorityScore
        MigrationPhase = $migrationPhase
        RequestCount = $requestCount
        TrafficPercent = $trafficPercent
        AvgResponseTimeMs = $avgResponseTime
        PeakHour = $peakHour
        ComplexityScore = $complexityScore
        ComplexityTier = $complexityTier
        ReadinessScore = $readinessScore
        DependencyCount = $dependencyCount
        UniqueSPs = $uniqueSPs
        HardCodedSPs = $hardCodedSPs
        EstimatedHours = $estimatedHours
        RiskLevel = $riskLevel
        BusinessImpact = $businessImpact
    }
    
    $processedControllers[$controllerName] = $true
}

# Check for controllers in traffic data but not in complexity data (already migrated?)
$unmappedControllers = @()
foreach ($trafficRecord in $trafficData) {
    $controllerName = $trafficRecord.ControllerName
    if (-not $processedControllers.ContainsKey($controllerName)) {
        $unmappedControllers += $controllerName
    }
}

if ($unmappedControllers.Count -gt 0) {
    Write-Host ""
    Write-Host "Note: $($unmappedControllers.Count) controller(s) found in traffic data but not in complexity scan:" -ForegroundColor Yellow
    $unmappedControllers | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }
    if ($unmappedControllers.Count -gt 5) {
        Write-Host "  ... and $($unmappedControllers.Count - 5) more" -ForegroundColor Gray
    }
    Write-Host "These may already be migrated or not use ISmartComponentService." -ForegroundColor Yellow
}

# Sort by priority score (descending)
$results = $results | Sort-Object PriorityScore -Descending

# Export to CSV
$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host ""
Write-Host "Migration priority ranking saved to: $OutputPath" -ForegroundColor Green
Write-Host ""

# Display summary statistics
Write-Host "=== Priority Distribution ===" -ForegroundColor Cyan
$priorityGroups = $results | Group-Object PriorityLevel | Sort-Object Name
foreach ($group in $priorityGroups) {
    $color = switch ($group.Name) {
        "CRITICAL" { "Red" }
        "HIGH" { "Yellow" }
        "MEDIUM" { "White" }
        "LOW" { "Gray" }
        default { "White" }
    }
    
    $totalHours = ($group.Group | Measure-Object EstimatedHours -Sum).Sum
    Write-Host ("  {0,-10} {1,3} controllers  Est: {2,4} hours" -f $group.Name, $group.Count, $totalHours) -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Top 10 Priority Controllers ===" -ForegroundColor Cyan
$results | Select-Object -First 10 | ForEach-Object {
    $color = switch ($_.PriorityLevel) {
        "CRITICAL" { "Red" }
        "HIGH" { "Yellow" }
        "MEDIUM" { "White" }
        "LOW" { "Gray" }
        default { "White" }
    }
    
    Write-Host ("  [{0,8}] {1,-30} Score: {2,3}  Traffic: {3,7:N0}  Complexity: {4,2}  Hours: {5,3}" -f `
        $_.PriorityLevel, `
        $_.ControllerName, `
        $_.PriorityScore, `
        $_.RequestCount, `
        $_.ComplexityScore, `
        $_.EstimatedHours
    ) -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Migration Phase Summary ===" -ForegroundColor Cyan
$phaseGroups = $results | Group-Object MigrationPhase | Sort-Object Name
foreach ($phase in $phaseGroups) {
    $totalHours = ($phase.Group | Measure-Object EstimatedHours -Sum).Sum
    $totalControllers = $phase.Count
    Write-Host "  $($phase.Name):" -ForegroundColor White
    Write-Host "    Controllers: $totalControllers" -ForegroundColor Gray
    Write-Host "    Est. Hours: $totalHours (~$([math]::Ceiling($totalHours / 40)) weeks @ 40 hrs/week)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Total Migration Effort ===" -ForegroundColor Cyan
$totalEffort = ($results | Measure-Object EstimatedHours -Sum).Sum
$totalControllers = $results.Count
Write-Host "  Total Controllers: $totalControllers" -ForegroundColor White
Write-Host "  Total Hours: $totalEffort" -ForegroundColor White
Write-Host "  Est. Duration: ~$([math]::Ceiling($totalEffort / 160)) months (1 developer @ 40 hrs/week)" -ForegroundColor White
Write-Host "  Est. Duration: ~$([math]::Ceiling($totalEffort / 320)) months (2 developers @ 40 hrs/week)" -ForegroundColor White
Write-Host ""

Write-Host "=== High Impact Controllers (High Traffic + Complex) ===" -ForegroundColor Cyan
$highImpact = $results | Where-Object { $_.BusinessImpact -eq "High" -and $_.ComplexityScore -gt 60 } | Select-Object -First 5
if ($highImpact) {
    $highImpact | ForEach-Object {
        Write-Host ("  {0,-30} Requests: {1,7:N0}  Complexity: {2,2}  Response: {3,6:N0}ms" -f `
            $_.ControllerName, `
            $_.RequestCount, `
            $_.ComplexityScore, `
            $_.AvgResponseTimeMs
        ) -ForegroundColor Red
    }
} else {
    Write-Host "  No high-impact controllers identified." -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Quick Wins (Low Complexity + High Traffic) ===" -ForegroundColor Cyan
$quickWins = $results | Where-Object { $_.ComplexityScore -lt 40 -and $_.RequestCount -gt 1000 } | Select-Object -First 5
if ($quickWins) {
    $quickWins | ForEach-Object {
        Write-Host ("  {0,-30} Requests: {1,7:N0}  Complexity: {2,2}  Hours: {3,3}" -f `
            $_.ControllerName, `
            $_.RequestCount, `
            $_.ComplexityScore, `
            $_.EstimatedHours
        ) -ForegroundColor Green
    }
} else {
    Write-Host "  No quick win opportunities identified." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Review the priority ranking CSV: $OutputPath" -ForegroundColor White
Write-Host "  2. Start with CRITICAL priority controllers (Phase 1)" -ForegroundColor White
Write-Host "  3. Consider 'Quick Wins' for early momentum" -ForegroundColor White
Write-Host "  4. Use ControllerMigrationChecklist.md for each controller" -ForegroundColor White
Write-Host ""
Write-Host "Visualization:" -ForegroundColor Cyan
Write-Host '  Import-Csv ".\Migration_Priority_Ranking.csv" | Out-GridView' -ForegroundColor Gray
