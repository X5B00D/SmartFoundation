# IIS Traffic Analysis Tools

## Overview

This directory contains PowerShell scripts for analyzing IIS access logs to determine controller usage patterns, performance metrics, and migration priorities.

## Tools

### 1. Analyze-IISTraffic.ps1

**Purpose:** Parses IIS log files to extract traffic and performance metrics per controller.

**Output:**
- Request count per controller
- Average response time per controller
- Peak usage hours
- Traffic percentage distribution

**Usage:**
```powershell
# Basic usage (default IIS log location)
.\Analyze-IISTraffic.ps1

# Custom log path
.\Analyze-IISTraffic.ps1 -LogPath "C:\inetpub\logs\LogFiles\W3SVC1"

# Date range filtering
.\Analyze-IISTraffic.ps1 -StartDate "2025-10-01" -EndDate "2025-10-30"

# Custom output path
.\Analyze-IISTraffic.ps1 -OutputPath ".\traffic_analysis_oct.csv"
```

**Output Format (CSV):**
```csv
ControllerName,RequestCount,TrafficPercent,AvgResponseTimeMs,PeakHour,Priority
Employees,15234,23.45,156.78,14,TBD
Dashboard,12890,19.83,245.12,09,TBD
Home,8765,13.48,89.34,10,TBD
```

---

### 2. Rank-MigrationPriority.ps1

**Purpose:** Combines traffic analysis with complexity analysis to generate final migration priority rankings.

**Input:**
- `IIS_Traffic_Analysis.csv` (from Analyze-IISTraffic.ps1)
- `Migration_Analysis_Report.csv` (from Merge-SPWithControllers.ps1)

**Output:**
- Comprehensive migration priority ranking
- Priority levels: CRITICAL, HIGH, MEDIUM, LOW
- Migration phase recommendations (Phase 1-4)
- Effort estimation and business impact assessment

**Usage:**
```powershell
# Basic usage
.\Rank-MigrationPriority.ps1 `
  -TrafficCsvPath ".\IIS_Traffic_Analysis.csv" `
  -ComplexityCsvPath ".\Migration_Analysis_Report.csv"

# Custom output path
.\Rank-MigrationPriority.ps1 `
  -TrafficCsvPath ".\traffic.csv" `
  -ComplexityCsvPath ".\complexity.csv" `
  -OutputPath ".\final_priority.csv"
```

**Output Format (CSV):**
```csv
ControllerName,PriorityLevel,PriorityScore,MigrationPhase,RequestCount,TrafficPercent,AvgResponseTimeMs,PeakHour,ComplexityScore,ComplexityTier,ReadinessScore,DependencyCount,UniqueSPs,HardCodedSPs,EstimatedHours,RiskLevel,BusinessImpact
Employees,CRITICAL,85,Phase 1 (Week 1-2),15234,23.45,156.78,14,72,Complex,35,8,12,5,96,High,High
Dashboard,HIGH,65,Phase 2 (Week 3-4),12890,19.83,245.12,09,58,Medium,48,5,8,2,60,Medium,High
```

---

## Priority Scoring Algorithm

The Rank-MigrationPriority.ps1 script uses a weighted scoring system (0-100 points):

### Traffic Volume (0-40 points)
- >10,000 requests: 40 points
- >5,000 requests: 30 points
- >1,000 requests: 20 points
- >100 requests: 10 points

### Complexity (0-30 points)
- Complexity >80: 30 points
- Complexity >70: 25 points
- Complexity >50: 20 points
- Complexity >30: 15 points
- Complexity ≤30: 10 points

### Response Time (0-20 points)
- >2000ms: 20 points
- >1000ms: 15 points
- >500ms: 10 points
- >100ms: 5 points

### Hard-Coded SPs (0-10 points)
- >5 hard-coded SPs: 10 points
- >2 hard-coded SPs: 5 points

### Priority Levels
- **CRITICAL** (70-100): High traffic + High complexity OR severe performance issues
- **HIGH** (51-69): High traffic OR high complexity
- **MEDIUM** (31-50): Moderate traffic + moderate complexity
- **LOW** (0-30): Low traffic + low complexity

---

## Complete Workflow

### Step 1: Scan Controllers for Dependencies
```powershell
cd c:\Users\abdulaziz\Documents\GitHub\SmartFoundation\tools

# Scan for ISmartComponentService usage
.\Scan-ControllerDependencies.ps1 `
  -ProjectPath "c:\Users\abdulaziz\Documents\GitHub\SmartFoundation\SmartFoundation.Mvc"
```

**Output:** `ISmartComponentService_Usage.csv`

---

### Step 2: Extract Stored Procedures
```powershell
# Extract all stored procedure references
.\Extract-StoredProcedures.ps1 `
  -ProjectPath "c:\Users\abdulaziz\Documents\GitHub\SmartFoundation\SmartFoundation.Mvc"
```

**Output:** `StoredProcedure_Catalog.csv`

---

### Step 3: Merge Dependency and SP Data
```powershell
# Combine scans with complexity analysis
.\Merge-SPWithControllers.ps1 `
  -DependencyScanPath ".\ISmartComponentService_Usage.csv" `
  -SPCatalogPath ".\StoredProcedure_Catalog.csv"
```

**Output:** `Migration_Analysis_Report.csv`

---

### Step 4: Analyze IIS Traffic
```powershell
# Analyze IIS logs for traffic patterns
.\Analyze-IISTraffic.ps1 `
  -LogPath "C:\inetpub\logs\LogFiles\W3SVC1" `
  -StartDate "2025-10-01" `
  -EndDate "2025-10-30"
```

**Output:** `IIS_Traffic_Analysis.csv`

---

### Step 5: Generate Final Priority Ranking
```powershell
# Combine traffic + complexity for final priorities
.\Rank-MigrationPriority.ps1 `
  -TrafficCsvPath ".\IIS_Traffic_Analysis.csv" `
  -ComplexityCsvPath ".\Migration_Analysis_Report.csv"
```

**Output:** `Migration_Priority_Ranking.csv`

---

## Analyzing Results

### View in Excel/GridView
```powershell
# Open in Excel
Start-Process ".\Migration_Priority_Ranking.csv"

# Open in PowerShell GridView (interactive filtering)
Import-Csv ".\Migration_Priority_Ranking.csv" | Out-GridView
```

### Filter by Priority
```powershell
# Show only CRITICAL priority controllers
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Where-Object PriorityLevel -eq "CRITICAL" | 
  Format-Table ControllerName, RequestCount, ComplexityScore, EstimatedHours

# Show controllers in Phase 1 (Week 1-2)
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Where-Object MigrationPhase -eq "Phase 1 (Week 1-2)" | 
  Format-Table ControllerName, PriorityScore, BusinessImpact
```

### Sort by Different Criteria
```powershell
# Sort by traffic (most used first)
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Sort-Object { [int]$_.RequestCount } -Descending | 
  Select-Object -First 10 | 
  Format-Table ControllerName, RequestCount, TrafficPercent

# Sort by response time (slowest first)
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Sort-Object { [double]$_.AvgResponseTimeMs } -Descending | 
  Select-Object -First 10 | 
  Format-Table ControllerName, AvgResponseTimeMs, RequestCount
```

### Calculate Statistics
```powershell
$data = Import-Csv ".\Migration_Priority_Ranking.csv"

# Total effort by priority
$data | Group-Object PriorityLevel | ForEach-Object {
    $totalHours = ($_.Group | Measure-Object -Property EstimatedHours -Sum).Sum
    [PSCustomObject]@{
        Priority = $_.Name
        Controllers = $_.Count
        TotalHours = $totalHours
        Weeks = [math]::Ceiling($totalHours / 40)
    }
} | Format-Table

# Average response time by complexity tier
$data | Group-Object ComplexityTier | ForEach-Object {
    $avgResponseTime = ($_.Group | Measure-Object -Property AvgResponseTimeMs -Average).Average
    [PSCustomObject]@{
        ComplexityTier = $_.Name
        Controllers = $_.Count
        AvgResponseTimeMs = [math]::Round($avgResponseTime, 2)
    }
} | Format-Table
```

---

## Troubleshooting

### Issue: No log files found
**Solution:** Verify IIS log path. Common locations:
- `C:\inetpub\logs\LogFiles\W3SVC1`
- `C:\Windows\System32\LogFiles\W3SVC1`

Check IIS Manager → Site → Logging settings for actual path.

### Issue: Low request counts or missing controllers
**Possible Causes:**
- Date range too narrow (use wider range or omit dates)
- Log files not in W3C format (check IIS logging configuration)
- Controllers not receiving traffic (low usage or new features)

### Issue: Controllers in traffic but not in priority ranking
**Explanation:** These controllers may:
- Not use ISmartComponentService (already migrated or different architecture)
- Use different patterns not detected by scanner
- Be static controllers (no database operations)

**Action:** Review manually or update scanner patterns if needed.

---

## Best Practices

### 1. Regular Analysis
Run traffic analysis weekly or monthly to track trends and adjust priorities.

### 2. Baseline Before Migration
Capture current traffic and performance metrics before starting migration to measure improvement.

### 3. Phase Approach
Follow recommended migration phases:
- **Phase 1:** CRITICAL (high traffic + complex)
- **Phase 2:** HIGH (high traffic OR complex)
- **Phase 3:** MEDIUM (moderate)
- **Phase 4:** LOW (low traffic + simple)

### 4. Consider Quick Wins
Look for low-complexity + high-traffic controllers for early successes and team momentum.

### 5. Monitor Post-Migration
After migrating a controller, re-run traffic analysis to verify performance improvements.

---

## Integration with Migration Process

After generating priority rankings, proceed with:

1. **Select Controller:** Choose highest priority controller from ranking
2. **Review Details:** Check complexity report for specific issues (hard-coded SPs, dependencies)
3. **Plan Migration:** Use Migration_Effort_Risk_Assessment.md for guidance
4. **Follow Checklist:** Use ControllerMigrationChecklist.md for step-by-step process
5. **Use Templates:** Apply NewApplicationServiceTemplate.cs and MigratedControllerTemplate.cs
6. **Validate:** Re-scan after migration to verify dependency removal

---

## Support

For questions or issues with these tools, contact the SmartFoundation development team.

**Documentation:** See `/docs` folder for additional resources
**Architecture:** See `/docs/ImplementationGuide.md` for Clean Architecture principles
**PRD:** See `/docs/PRD.md` for project requirements
