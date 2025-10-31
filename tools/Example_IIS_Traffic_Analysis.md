# Example: IIS Traffic Analysis Output

## Sample Output - IIS_Traffic_Analysis.csv

```csv
ControllerName,RequestCount,TrafficPercent,AvgResponseTimeMs,PeakHour,Priority
Employees,15234,23.45,156.78,14,TBD
Dashboard,12890,19.83,245.12,9,TBD
Home,8765,13.48,89.34,10,TBD
Products,6543,10.06,312.45,11,TBD
Orders,5432,8.35,198.67,13,TBD
Customers,4321,6.65,145.23,14,TBD
Reports,3210,4.94,567.89,15,TBD
Settings,2109,3.24,78.45,16,TBD
UserProfile,1876,2.89,123.56,12,TBD
Notifications,1543,2.37,234.67,10,TBD
Invoices,1234,1.90,345.78,14,TBD
Payments,987,1.52,456.89,11,TBD
Analytics,654,1.01,678.90,17,TBD
ApiController,321,0.49,789.01,8,TBD
```

---

## Sample Output - Migration_Priority_Ranking.csv

```csv
ControllerName,PriorityLevel,PriorityScore,MigrationPhase,RequestCount,TrafficPercent,AvgResponseTimeMs,PeakHour,ComplexityScore,ComplexityTier,ReadinessScore,DependencyCount,UniqueSPs,HardCodedSPs,EstimatedHours,RiskLevel,BusinessImpact
Employees,CRITICAL,85,Phase 1 (Week 1-2),15234,23.45,156.78,14,72,Complex,35,8,12,5,96,High,High
Dashboard,CRITICAL,78,Phase 1 (Week 1-2),12890,19.83,245.12,9,65,Medium,42,6,10,3,80,Medium,High
Reports,HIGH,72,Phase 2 (Week 3-4),3210,4.94,567.89,15,78,Complex,28,9,15,6,120,High,Medium
Products,HIGH,68,Phase 2 (Week 3-4),6543,10.06,312.45,11,58,Medium,48,5,8,2,64,Medium,Medium
Orders,HIGH,65,Phase 2 (Week 3-4),5432,8.35,198.67,13,54,Medium,52,4,7,2,56,Medium,Medium
Customers,MEDIUM,48,Phase 3 (Week 5-6),4321,6.65,145.23,14,42,Medium,63,3,6,1,40,Low,Medium
Home,MEDIUM,45,Phase 3 (Week 5-6),8765,13.48,89.34,10,38,Simple,72,2,4,0,32,Low,Medium
Invoices,MEDIUM,42,Phase 3 (Week 5-6),1234,1.90,345.78,14,48,Medium,58,4,7,2,48,Medium,Low
Settings,LOW,35,Phase 4 (Week 7+),2109,3.24,78.45,16,28,Simple,80,2,3,0,24,Low,Low
UserProfile,LOW,32,Phase 4 (Week 7+),1876,2.89,123.56,12,32,Simple,76,2,4,1,28,Low,Low
Notifications,LOW,28,Phase 4 (Week 7+),1543,2.37,234.67,10,24,Simple,84,1,2,0,16,Low,Low
Payments,MEDIUM,38,Phase 3 (Week 5-6),987,1.52,456.89,11,44,Medium,61,3,5,1,36,Medium,Low
Analytics,LOW,25,Phase 4 (Week 7+),654,1.01,678.90,17,32,Simple,76,2,3,0,20,Low,Low
ApiController,LOW,22,Phase 4 (Week 7+),321,0.49,789.01,8,18,Simple,88,1,2,0,12,Low,Low
```

---

## Analysis Insights

### Traffic Distribution
- **Top 3 Controllers** account for 56.8% of total traffic
  - Employees: 23.45%
  - Dashboard: 19.83%
  - Home: 13.48%

- **High-traffic Controllers** (>5000 requests): 5 controllers
- **Medium-traffic Controllers** (1000-5000): 5 controllers
- **Low-traffic Controllers** (<1000): 4 controllers

---

### Performance Issues
Controllers with average response time >500ms:
1. **ApiController**: 789.01ms (lowest traffic, may need optimization)
2. **Analytics**: 678.90ms (low traffic, complex queries?)
3. **Reports**: 567.89ms (HIGH priority, needs immediate attention)
4. **Payments**: 456.89ms (financial transactions, critical path)

---

### Peak Usage Patterns
- **Morning Peak (9-10 AM)**: Dashboard, Home, Notifications
- **Midday Peak (11-14 PM)**: Products, Orders, Employees, Customers, Invoices
- **Afternoon Peak (15-17 PM)**: Reports, Settings, Analytics

**Recommendation:** Schedule migrations during off-peak hours (1-8 AM) to minimize user impact.

---

### Priority Distribution

| Priority | Controllers | Total Hours | Est. Duration (1 dev) | Est. Duration (2 devs) |
|----------|-------------|-------------|----------------------|------------------------|
| CRITICAL | 2           | 176         | 4.4 weeks            | 2.2 weeks              |
| HIGH     | 3           | 240         | 6.0 weeks            | 3.0 weeks              |
| MEDIUM   | 5           | 184         | 4.6 weeks            | 2.3 weeks              |
| LOW      | 4           | 72          | 1.8 weeks            | 0.9 weeks              |
| **TOTAL**| **14**      | **672**     | **16.8 weeks**       | **8.4 weeks**          |

---

### Critical Findings

#### 1. Employees Controller (CRITICAL - Priority Score: 85)
- **Traffic:** 15,234 requests (23.45% of total)
- **Complexity:** 72 (Complex tier)
- **Issues:**
  - 5 hard-coded stored procedures (needs ProcedureMapper)
  - 8 ISmartComponentService dependencies
  - 12 unique stored procedures
- **Recommendation:** **Top migration priority** - highest traffic + high complexity
- **Estimated Effort:** 96 hours (2.4 weeks for 1 developer)
- **Business Impact:** High

#### 2. Dashboard Controller (CRITICAL - Priority Score: 78)
- **Traffic:** 12,890 requests (19.83%)
- **Performance:** 245.12ms avg (acceptable but can improve)
- **Complexity:** 65 (Medium-high)
- **Issues:**
  - 3 hard-coded stored procedures
  - 6 dependencies
  - Peak usage at 9 AM (start of workday)
- **Recommendation:** **Second priority** - critical for user experience
- **Estimated Effort:** 80 hours (2 weeks)
- **Business Impact:** High

#### 3. Reports Controller (HIGH - Priority Score: 72)
- **Traffic:** 3,210 requests (4.94%)
- **Performance:** 567.89ms avg (**SLOW - needs optimization**)
- **Complexity:** 78 (Complex)
- **Issues:**
  - 6 hard-coded SPs
  - 9 dependencies
  - 15 unique stored procedures
- **Recommendation:** **Third priority** - performance issues + complexity
- **Estimated Effort:** 120 hours (3 weeks)
- **Risk:** High (complex logic + performance-sensitive)

---

### Quick Win Opportunities

Controllers with **high traffic** but **low complexity** (easy migrations with big impact):

1. **Home Controller**
   - Priority: MEDIUM (Score: 45)
   - Traffic: 8,765 requests (13.48%)
   - Complexity: 38 (Simple)
   - Effort: 32 hours (4 days)
   - **Benefit:** High traffic, simple migration, early win

2. **Customers Controller**
   - Priority: MEDIUM (Score: 48)
   - Traffic: 4,321 requests (6.65%)
   - Complexity: 42 (Medium)
   - Effort: 40 hours (5 days)
   - **Benefit:** Moderate traffic, straightforward CRUD

---

### Risk Assessment

#### High-Risk Controllers (need extra care)
1. **Reports Controller** - Complex logic + performance issues
2. **Employees Controller** - High traffic + multiple hard-coded SPs
3. **Payments Controller** - Financial transactions (data integrity critical)

#### Medium-Risk Controllers
1. **Dashboard Controller** - High traffic (staging testing crucial)
2. **Products Controller** - Business-critical data
3. **Orders Controller** - Transaction processing

#### Low-Risk Controllers
1. **Settings Controller** - Low complexity, low traffic
2. **Notifications Controller** - Non-critical feature
3. **ApiController** - Low usage, isolated

---

## Recommended Migration Order

### Phase 1 (Weeks 1-2) - Critical Impact
1. **Employees Controller** (96 hours)
   - Highest priority: traffic + complexity
   - Migrate during weekend or off-hours
   - Comprehensive testing required
   
2. **Dashboard Controller** (80 hours)
   - Second highest priority
   - Peak usage at 9 AM (test deployment 8 AM)
   - User-visible changes - monitor closely

**Phase 1 Total:** 176 hours (4.4 weeks for 1 dev, 2.2 weeks for 2 devs)

---

### Phase 2 (Weeks 3-4) - High Impact
3. **Reports Controller** (120 hours)
   - Performance optimization opportunity
   - Complex but important
   
4. **Products Controller** (64 hours)
   - Moderate traffic + complexity
   - Business-critical
   
5. **Orders Controller** (56 hours)
   - Transaction processing
   - Thorough testing needed

**Phase 2 Total:** 240 hours (6 weeks for 1 dev, 3 weeks for 2 devs)

---

### Phase 3 (Weeks 5-6) - Medium Impact
**Quick Win Strategy:** Start with Home Controller for early success

6. **Home Controller** (32 hours) - **Quick Win!**
7. **Customers Controller** (40 hours)
8. **Invoices Controller** (48 hours)
9. **Payments Controller** (36 hours)
10. *(Continue with other MEDIUM priority)*

**Phase 3 Total:** 184 hours (4.6 weeks for 1 dev, 2.3 weeks for 2 devs)

---

### Phase 4 (Weeks 7+) - Low Impact
11. **Settings Controller** (24 hours)
12. **UserProfile Controller** (28 hours)
13. **Notifications Controller** (16 hours)
14. **Analytics Controller** (20 hours)
15. **ApiController** (12 hours)

**Phase 4 Total:** 72 hours (1.8 weeks for 1 dev, 0.9 weeks for 2 devs)

---

## Using This Data for Migration

### 1. Review Priority Ranking
```powershell
Import-Csv ".\Migration_Priority_Ranking.csv" | Out-GridView
```

### 2. Select Next Controller
Start with **Employees Controller** (highest priority score: 85)

### 3. Prepare for Migration
- Review complexity report: Check specific dependencies and SPs
- Check traffic patterns: Plan deployment during low-traffic period
- Estimate effort: 96 hours (allocate 2-2.5 weeks)
- Assess risks: High - extensive testing required

### 4. Follow Checklist
Use `ControllerMigrationChecklist.md` for step-by-step process

### 5. Monitor Post-Migration
Re-run traffic analysis after 1 week to verify:
- No performance degradation
- Error rates unchanged
- Response times improved (if optimization was applied)

---

## Visualization Commands

### View Top 10 by Traffic
```powershell
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Sort-Object { [int]$_.RequestCount } -Descending | 
  Select-Object -First 10 ControllerName, RequestCount, AvgResponseTimeMs, PriorityLevel | 
  Format-Table -AutoSize
```

### View CRITICAL Priority Controllers
```powershell
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Where-Object PriorityLevel -eq "CRITICAL" | 
  Select-Object ControllerName, PriorityScore, RequestCount, ComplexityScore, EstimatedHours | 
  Format-Table -AutoSize
```

### Calculate Total Effort by Phase
```powershell
Import-Csv ".\Migration_Priority_Ranking.csv" | 
  Group-Object MigrationPhase | 
  ForEach-Object {
    [PSCustomObject]@{
      Phase = $_.Name
      Controllers = $_.Count
      TotalHours = ($_.Group | Measure-Object EstimatedHours -Sum).Sum
    }
  } | Format-Table -AutoSize
```

---

This example demonstrates how the IIS traffic analysis tools help prioritize controller migration based on real-world usage patterns, performance characteristics, and complexity metrics.
