<#
.SYNOPSIS
    Analyzes IIS access logs to determine controller usage patterns and performance metrics.

.DESCRIPTION
    This script parses IIS log files in W3C extended format to extract:
    - Request counts per controller
    - Average response times per controller
    - Peak usage hours
    - Traffic patterns over time
    
    Results are used to prioritize controller migration efforts, focusing on high-traffic
    and high-impact controllers first.

.PARAMETER LogPath
    Path to IIS log files directory (e.g., C:\inetpub\logs\LogFiles\W3SVC1).
    Defaults to C:\inetpub\logs\LogFiles\W3SVC1.

.PARAMETER OutputPath
    Path where the traffic analysis CSV will be saved.
    Defaults to .\IIS_Traffic_Analysis.csv.

.PARAMETER StartDate
    Optional start date for log analysis (format: yyyy-MM-dd).
    If not specified, all available logs are processed.

.PARAMETER EndDate
    Optional end date for log analysis (format: yyyy-MM-dd).
    If not specified, all available logs are processed.

.PARAMETER ControllerPath
    Base path to the Controllers directory for validation.
    Defaults to ..\SmartFoundation.Mvc\Controllers.

.EXAMPLE
    .\Analyze-IISTraffic.ps1 -LogPath "C:\inetpub\logs\LogFiles\W3SVC1"
    
.EXAMPLE
    .\Analyze-IISTraffic.ps1 -LogPath "C:\logs" -StartDate "2025-10-01" -EndDate "2025-10-30"

.EXAMPLE
    .\Analyze-IISTraffic.ps1 -LogPath "C:\logs" -OutputPath ".\traffic_oct2025.csv"

.NOTES
    Author: SmartFoundation Team
    Version: 1.0
    Requires: PowerShell 5.1 or higher
    IIS Log Format: W3C Extended (default IIS format)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\inetpub\logs\LogFiles\W3SVC1",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\IIS_Traffic_Analysis.csv",
    
    [Parameter(Mandatory=$false)]
    [datetime]$StartDate,
    
    [Parameter(Mandatory=$false)]
    [datetime]$EndDate,
    
    [Parameter(Mandatory=$false)]
    [string]$ControllerPath = "..\SmartFoundation.Mvc\Controllers"
)

# Error handling setup
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "=== IIS Traffic Analysis Tool ===" -ForegroundColor Cyan
Write-Host "Log Path: $LogPath" -ForegroundColor Gray
Write-Host "Output Path: $OutputPath" -ForegroundColor Gray
if ($StartDate) { Write-Host "Start Date: $($StartDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray }
if ($EndDate) { Write-Host "End Date: $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray }
Write-Host ""

# Validate log path
if (-not (Test-Path $LogPath)) {
    Write-Error "Log path not found: $LogPath"
    Write-Host "Please verify the IIS log directory path." -ForegroundColor Yellow
    Write-Host "Common locations:" -ForegroundColor Yellow
    Write-Host "  - C:\inetpub\logs\LogFiles\W3SVC1" -ForegroundColor Gray
    Write-Host "  - C:\Windows\System32\LogFiles\W3SVC1" -ForegroundColor Gray
    exit 1
}

# Get log files
Write-Host "Scanning for IIS log files..." -ForegroundColor Cyan
$logFiles = Get-ChildItem -Path $LogPath -Filter "u_ex*.log" -File | Sort-Object LastWriteTime

if ($logFiles.Count -eq 0) {
    Write-Error "No IIS log files found in: $LogPath"
    Write-Host "Expected file pattern: u_ex*.log" -ForegroundColor Yellow
    exit 1
}

# Filter by date range if specified
if ($StartDate -or $EndDate) {
    $logFiles = $logFiles | Where-Object {
        $fileDate = $null
        if ($_.Name -match "u_ex(\d{6})\.log") {
            try {
                $fileDate = [datetime]::ParseExact($Matches[1], "yyMMdd", $null)
            } catch {
                return $false
            }
        }
        
        $includeFile = $true
        if ($StartDate -and $fileDate -lt $StartDate) { $includeFile = $false }
        if ($EndDate -and $fileDate -gt $EndDate) { $includeFile = $false }
        
        return $includeFile
    }
}

Write-Host "Found $($logFiles.Count) log file(s) to process" -ForegroundColor Green
Write-Host ""

# Initialize data structures
$controllerStats = @{}
$totalRequests = 0
$processedFiles = 0
$skippedLines = 0

# Process each log file
foreach ($logFile in $logFiles) {
    $processedFiles++
    Write-Host "[$processedFiles/$($logFiles.Count)] Processing: $($logFile.Name)" -ForegroundColor Gray
    
    try {
        $lineCount = 0
        Get-Content $logFile.FullName | ForEach-Object {
            $line = $_
            $lineCount++
            
            # Skip comment lines (IIS log headers)
            if ($line -match "^#") {
                return
            }
            
            # Parse log line (W3C format: space-delimited)
            # Typical format: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) sc-status sc-substatus sc-win32-status time-taken
            $fields = $line -split '\s+'
            
            # Validate minimum field count
            if ($fields.Count -lt 10) {
                $skippedLines++
                return
            }
            
            # Extract relevant fields
            # Common W3C field positions (may vary by IIS config):
            # 0: date, 1: time, 2: s-ip, 3: cs-method, 4: cs-uri-stem, 5: cs-uri-query, 6: s-port,
            # 7: cs-username, 8: c-ip, 9: cs(User-Agent), 10: sc-status, 11: sc-substatus,
            # 12: sc-win32-status, 13: time-taken
            
            $uriStem = $fields[4]
            $statusCode = $fields[10]
            $timeTaken = $fields[13]
            
            # Skip non-successful requests (optional - comment out to include all)
            if ($statusCode -notmatch "^2\d{2}$") {
                return
            }
            
            # Extract controller name from URI (e.g., /Employees/Index -> Employees)
            if ($uriStem -match "^/([A-Za-z][A-Za-z0-9_]*)/") {
                $controllerName = $Matches[1]
                
                # Parse time-taken (milliseconds)
                $responseTime = 0
                if ([int]::TryParse($timeTaken, [ref]$responseTime)) {
                    # Time-taken is in milliseconds
                } else {
                    $responseTime = 0
                }
                
                # Extract hour for peak analysis
                $requestTime = "$($fields[0]) $($fields[1])"
                try {
                    $timestamp = [datetime]::Parse($requestTime)
                    $hour = $timestamp.Hour
                } catch {
                    $hour = 0
                }
                
                # Initialize controller stats if not exists
                if (-not $controllerStats.ContainsKey($controllerName)) {
                    $controllerStats[$controllerName] = @{
                        RequestCount = 0
                        TotalResponseTime = 0
                        HourlyRequests = @{}
                    }
                }
                
                # Update statistics
                $controllerStats[$controllerName].RequestCount++
                $controllerStats[$controllerName].TotalResponseTime += $responseTime
                
                if (-not $controllerStats[$controllerName].HourlyRequests.ContainsKey($hour)) {
                    $controllerStats[$controllerName].HourlyRequests[$hour] = 0
                }
                $controllerStats[$controllerName].HourlyRequests[$hour]++
                
                $totalRequests++
            }
        }
        
        Write-Host "  Processed $lineCount lines" -ForegroundColor DarkGray
        
    } catch {
        Write-Warning "Error processing file $($logFile.Name): $_"
        continue
    }
}

Write-Host ""
Write-Host "=== Processing Complete ===" -ForegroundColor Cyan
Write-Host "Total requests analyzed: $totalRequests" -ForegroundColor Green
Write-Host "Unique controllers found: $($controllerStats.Count)" -ForegroundColor Green
Write-Host "Skipped lines: $skippedLines" -ForegroundColor Gray
Write-Host ""

# Calculate metrics and generate results
Write-Host "Calculating metrics..." -ForegroundColor Cyan
$results = @()

foreach ($controller in $controllerStats.Keys) {
    $stats = $controllerStats[$controller]
    
    # Calculate average response time
    $avgResponseTime = if ($stats.RequestCount -gt 0) {
        [math]::Round($stats.TotalResponseTime / $stats.RequestCount, 2)
    } else {
        0
    }
    
    # Find peak hour (hour with most requests)
    $peakHour = if ($stats.HourlyRequests.Count -gt 0) {
        ($stats.HourlyRequests.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Name
    } else {
        "N/A"
    }
    
    # Calculate traffic percentage
    $trafficPercent = if ($totalRequests -gt 0) {
        [math]::Round(($stats.RequestCount / $totalRequests) * 100, 2)
    } else {
        0
    }
    
    $results += [PSCustomObject]@{
        ControllerName = $controller
        RequestCount = $stats.RequestCount
        TrafficPercent = $trafficPercent
        AvgResponseTimeMs = $avgResponseTime
        PeakHour = $peakHour
        Priority = "TBD" # Will be set by Rank-MigrationPriority.ps1
    }
}

# Sort by request count (descending)
$results = $results | Sort-Object RequestCount -Descending

# Export to CSV
$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Traffic analysis saved to: $OutputPath" -ForegroundColor Green
Write-Host ""

# Display summary
Write-Host "=== Top 10 Controllers by Traffic ===" -ForegroundColor Cyan
$results | Select-Object -First 10 | ForEach-Object {
    $color = if ($_.RequestCount -gt 10000) { "Red" }
             elseif ($_.RequestCount -gt 5000) { "Yellow" }
             elseif ($_.RequestCount -gt 1000) { "White" }
             else { "Gray" }
    
    Write-Host ("  {0,-30} {1,10:N0} requests ({2,6}%)  Avg: {3,6:N0}ms  Peak: {4}" -f `
        $_.ControllerName, `
        $_.RequestCount, `
        $_.TrafficPercent, `
        $_.AvgResponseTimeMs, `
        "$($_.PeakHour):00"
    ) -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Response Time Analysis ===" -ForegroundColor Cyan
$slowControllers = $results | Where-Object { $_.AvgResponseTimeMs -gt 1000 } | Select-Object -First 5
if ($slowControllers) {
    Write-Host "Controllers with avg response time > 1000ms:" -ForegroundColor Yellow
    $slowControllers | ForEach-Object {
        Write-Host "  $($_.ControllerName): $($_.AvgResponseTimeMs)ms" -ForegroundColor Yellow
    }
} else {
    Write-Host "All controllers have acceptable response times (<1000ms)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Run Rank-MigrationPriority.ps1 to combine with complexity analysis" -ForegroundColor White
Write-Host "  2. Review the final migration priority ranking" -ForegroundColor White
Write-Host "  3. Start migration with Critical priority controllers" -ForegroundColor White
Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host '  .\Rank-MigrationPriority.ps1 -TrafficCsvPath ".\IIS_Traffic_Analysis.csv" -ComplexityCsvPath ".\Migration_Analysis_Report.csv"' -ForegroundColor Gray
