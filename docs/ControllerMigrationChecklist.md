# Controller Migration Checklist

## Document Overview

**Purpose:** Step-by-step guide for migrating controllers from direct DataEngine usage to Application Layer services

**Scope:** Individual controller migration

**Prerequisites:**
- Application Layer infrastructure exists (BaseService, ProcedureMapper)
- Understanding of Clean Architecture principles
- Familiarity with SmartFoundation project structure

**Last Updated:** October 30, 2025  
**Version:** 1.0

---

## Phase 1: Pre-Migration Analysis

### 1.1 Select Controller for Migration

**Reference:** See `Migration_Priority_Ranking.csv` from Task 8.3

- [ ] Review priority ranking
- [ ] Select next controller based on priority (CRITICAL → HIGH → MEDIUM → LOW)
- [ ] Document controller name: `______________________`
- [ ] Priority level: [ ] CRITICAL [ ] HIGH [ ] MEDIUM [ ] LOW
- [ ] Complexity score: `______`
- [ ] Estimated effort: `______ hours`

**Notes:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### 1.2 Analyze Current Controller

**Location:** `SmartFoundation.Mvc/Controllers/[ControllerName].cs`

- [ ] Read and understand current implementation
- [ ] Identify all action methods
- [ ] Count total actions: `______`

**Action Method Inventory:**

| Action Name | HTTP Method | Purpose | SP Used | Notes |
|-------------|------------|---------|---------|-------|
| | | | | |
| | | | | |
| | | | | |
| | | | | |

---

### 1.3 Identify Dependencies

**Run Dependency Scanner:**
```powershell
cd c:\Users\abdulaziz\Documents\GitHub\SmartFoundation\tools
.\Scan-ControllerDependencies.ps1 -ProjectPath "..\SmartFoundation.Mvc"
```

**Findings:**
- [ ] ISmartComponentService usage count: `______`
- [ ] Constructor injection present: [ ] Yes [ ] No
- [ ] Field declaration present: [ ] Yes [ ] No
- [ ] ExecuteAsync calls count: `______`
- [ ] SmartRequest usage count: `______`

**Document specific line numbers:**
```
Field declaration: Line _____
Constructor injection: Line _____
ExecuteAsync calls: Lines _____, _____, _____, _____
```

---

### 1.4 Catalog Stored Procedures

**Run SP Extraction:**
```powershell
.\Extract-StoredProcedures.ps1 -ProjectPath "..\SmartFoundation.Mvc"
```

**Stored Procedures Used:**

| SP Name | Category | Hard-Coded? | Line Number | Usage Count |
|---------|----------|-------------|-------------|-------------|
| | | [ ] Yes [ ] No | | |
| | | [ ] Yes [ ] No | | |
| | | [ ] Yes [ ] No | | |
| | | [ ] Yes [ ] No | | |

**Total SPs:** `______`  
**Hard-coded SPs:** `______`  
**Using ProcedureMapper:** `______`

---

### 1.5 Review Traffic Analysis

**Reference:** `IIS_Traffic_Analysis.csv`

- [ ] Request count per week: `______`
- [ ] Traffic tier: [ ] High (>5000) [ ] Medium (1000-5000) [ ] Low (<1000)
- [ ] Average response time: `______ ms`
- [ ] Peak usage hour: `______ :00`
- [ ] Business impact: [ ] High [ ] Medium [ ] Low

**Deployment Strategy:**
- [ ] Maintenance window required: [ ] Yes [ ] No
- [ ] Recommended deployment time: `________________`
- [ ] Rollback plan needed: [ ] Yes [ ] No

---

### 1.6 Assess Risks

**Technical Risk Factors:**

- [ ] Complex business logic (multi-step workflows)
- [ ] Performance-sensitive (>500ms avg response time)
- [ ] High user visibility (customer-facing)
- [ ] Data integrity critical (financial, orders)
- [ ] External dependencies (APIs, services)

**Risk Level:** [ ] High [ ] Medium [ ] Low

**Mitigation Plan:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### 1.7 Estimate Effort

**Formula:** `Base Effort = 8 + (Dependencies × 2) + (Unique SPs × 4)`

**Calculation:**
```
Base: 8 hours
Dependencies: _____ × 2 = _____ hours
Unique SPs: _____ × 4 = _____ hours
---
Subtotal: _____ hours

Adjustment factors:
[ ] Complex logic (×1.3)
[ ] Performance-sensitive (×1.2)
[ ] High traffic (×1.2)
[ ] Many hard-coded SPs (×1.15)
[ ] Data integrity critical (×1.25)
[ ] External dependencies (×1.15)
[ ] Low test coverage (×1.3)

Final estimate: _____ hours (_____ days / _____ weeks)
```

---

### 1.8 Get Approval

- [ ] Technical Lead approval: _________________ Date: _______
- [ ] Effort estimate approved: [ ] Yes [ ] No
- [ ] Schedule confirmed: Start: _______ End: _______
- [ ] Resources allocated: Developer(s): _________________
- [ ] Stakeholders notified: [ ] Yes [ ] No

---

## Phase 2: Service Creation

### 2.1 Create Service Class

**Template:** Use `NewApplicationServiceTemplate.cs`

**Location:** `SmartFoundation.Application/Services/[Entity]Service.cs`

- [ ] Copy template file
- [ ] Rename to `[Entity]Service.cs`
- [ ] Update class name
- [ ] Update constructor XML documentation
- [ ] Update namespace if needed

**Service name:** `______________________Service`

---

### 2.2 Implement Service Methods

For each action method in controller, create corresponding service method:

**Method Mapping:**

| Controller Action | Service Method | Module | Operation |
|-------------------|---------------|--------|-----------|
| Index | GetList | | list |
| Details | GetById | | getById |
| Create (GET) | - | | - |
| Create (POST) | Create | | insert |
| Edit (GET) | GetById | | getById |
| Edit (POST) | Update | | update |
| Delete | Delete | | delete |

**Implementation Checklist:**

For each service method:
- [ ] Method signature correct: `public async Task<string> MethodName(Dictionary<string, object> parameters)`
- [ ] XML documentation complete
- [ ] Uses `ExecuteOperation(module, operation, parameters)`
- [ ] No hard-coded SP names
- [ ] No direct DataEngine calls

**Example:**
```csharp
/// <summary>
/// Gets paginated list of [entities].
/// </summary>
/// <param name="parameters">
/// Required: pageNumber (int), pageSize (int)
/// Optional: searchTerm (string)
/// </param>
/// <returns>JSON with success, data, message</returns>
public async Task<string> GetList(Dictionary<string, object> parameters)
    => await ExecuteOperation("module", "list", parameters);
```

---

### 2.3 Add ProcedureMapper Entries

**File:** `SmartFoundation.Application/Mapping/ProcedureMapper.cs`

**Entries to Add:**

| Key | Stored Procedure Name |
|-----|----------------------|
| "module:list" | "dbo.sp_______" |
| "module:getById" | "dbo.sp_______" |
| "module:insert" | "dbo.sp_______" |
| "module:update" | "dbo.sp_______" |
| "module:delete" | "dbo.sp_______" |

**Code:**
```csharp
// Add to _mappings dictionary in ProcedureMapper.cs
{ "yourModule:list", "dbo.sp_YourProcedure" },
{ "yourModule:getById", "dbo.sp_YourProcedure" },
{ "yourModule:insert", "dbo.sp_YourProcedure" },
{ "yourModule:update", "dbo.sp_YourProcedure" },
{ "yourModule:delete", "dbo.sp_YourProcedure" },
```

**Verification:**
- [ ] All mappings added
- [ ] No typos in keys or SP names
- [ ] Module name consistent across all entries
- [ ] File builds without errors

---

### 2.4 Register Service in DI Container

**File:** `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs`

**Add Registration:**
```csharp
services.AddScoped<YourService>();
```

**Checklist:**
- [ ] Service registered with `AddScoped` (per-request lifetime)
- [ ] Correct service type name
- [ ] File builds without errors
- [ ] No duplicate registrations

---

### 2.5 Build and Verify Service

**Commands:**
```powershell
cd c:\Users\abdulaziz\Documents\GitHub\SmartFoundation
dotnet build SmartFoundation.Application/SmartFoundation.Application.csproj
```

**Verification:**
- [ ] Build succeeds (0 errors)
- [ ] No warnings (or only acceptable warnings)
- [ ] Service class compiles
- [ ] ProcedureMapper compiles
- [ ] DI extensions compile

**If build fails, fix errors before proceeding.**

---

## Phase 3: Unit Testing (Service)

### 3.1 Create Test Class

**Location:** `SmartFoundation.Application.Tests/Services/[Entity]ServiceTests.cs`

**Template:**
```csharp
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using System.Text.Json;

namespace SmartFoundation.Application.Tests.Services;

public class YourServiceTests
{
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<ILogger<YourService>> _mockLogger;
    private readonly YourService _service;

    public YourServiceTests()
    {
        _mockDataEngine = new Mock<ISmartComponentService>();
        _mockLogger = new Mock<ILogger<YourService>>();
        _service = new YourService(_mockDataEngine.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetList_WithValidParams_ReturnsSuccess()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>
                {
                    new() { { "Id", 1 }, { "Name", "Test" } }
                }
            });

        var parameters = new Dictionary<string, object>
        {
            { "pageNumber", 1 },
            { "pageSize", 10 }
        };

        // Act
        var result = await _service.GetList(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    }
}
```

---

### 3.2 Write Tests for Each Method

**Test Coverage Target:** ≥80%

**For each service method, write tests for:**

- [ ] **Happy path** (valid input, successful execution)
- [ ] **Error handling** (DataEngine throws exception)
- [ ] **Invalid parameters** (missing required parameters)
- [ ] **Edge cases** (empty results, null values)

**Test Inventory:**

| Method | Happy Path | Error Handling | Invalid Params | Edge Cases |
|--------|-----------|----------------|----------------|------------|
| GetList | [ ] | [ ] | [ ] | [ ] |
| GetById | [ ] | [ ] | [ ] | [ ] |
| Create | [ ] | [ ] | [ ] | [ ] |
| Update | [ ] | [ ] | [ ] | [ ] |
| Delete | [ ] | [ ] | [ ] | [ ] |

**Total Tests:** `______`

---

### 3.3 Run Tests

**Commands:**
```powershell
dotnet test SmartFoundation.Application.Tests --filter "FullyQualifiedName~YourServiceTests"
```

**Results:**
- [ ] All tests passing
- [ ] Pass rate: 100% (______ passed, ______ failed)
- [ ] Code coverage: ______ % (target: ≥80%)

**If tests fail:**
```
Test Name: _______________________
Error: _________________________________________________________________
Fix: ___________________________________________________________________
```

---

## Phase 4: Controller Migration

### 4.1 Update Controller Dependencies

**File:** `SmartFoundation.Mvc/Controllers/[Controller].cs`

**Before:**
```csharp
private readonly ISmartComponentService _dataEngine;

public YourController(ISmartComponentService dataEngine)
{
    _dataEngine = dataEngine;
}
```

**After:**
```csharp
private readonly YourService _yourService;
private readonly ILogger<YourController> _logger;

public YourController(
    YourService yourService,
    ILogger<YourController> logger)
{
    _yourService = yourService ?? throw new ArgumentNullException(nameof(yourService));
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
}
```

**Checklist:**
- [ ] ISmartComponentService reference removed
- [ ] Service injected in constructor
- [ ] ILogger injected in constructor
- [ ] Null checks added
- [ ] Field names updated (_yourService, _logger)

---

### 4.2 Migrate Action Methods

**Template Reference:** `MigratedControllerTemplate.cs`

**For each action method:**

#### Step 1: Add Input Validation
```csharp
// Validate input
if (pageNumber < 1) pageNumber = 1;
if (pageSize < 1 || pageSize > 100) pageSize = 10;

// Sanitize strings
searchTerm = searchTerm?.Trim();
if (searchTerm?.Length > 100)
    searchTerm = searchTerm.Substring(0, 100);
```

#### Step 2: Prepare Parameters
```csharp
var parameters = new Dictionary<string, object>
{
    { "pageNumber", pageNumber },
    { "pageSize", pageSize }
};

if (!string.IsNullOrWhiteSpace(searchTerm))
{
    parameters.Add("searchTerm", searchTerm);
}
```

#### Step 3: Replace DataEngine Call
```csharp
// BEFORE:
var request = new SmartRequest
{
    Operation = "sp",
    SpName = "dbo.sp_GetEmployees",  // Hard-coded
    Params = parameters
};
var response = await _dataEngine.ExecuteAsync(request);

// AFTER:
var data = await _yourService.GetList(parameters);
```

#### Step 4: Add Error Handling
```csharp
try
{
    // ... service call ...
}
catch (Exception ex)
{
    _logger.LogError(ex, "Error in action method");
    TempData["ErrorMessage"] = "An error occurred";
    return View();  // or RedirectToAction
}
```

---

### 4.3 Action Method Migration Checklist

**For EACH action method:**

- [ ] **Input validation added**
  - [ ] Numeric ranges checked
  - [ ] Strings sanitized
  - [ ] Required params validated
  
- [ ] **Parameters prepared**
  - [ ] Dictionary created
  - [ ] Required params added
  - [ ] Optional params conditionally added
  
- [ ] **Service call updated**
  - [ ] SmartRequest removed
  - [ ] Service method called
  - [ ] No hard-coded SP names
  - [ ] No direct DataEngine usage
  
- [ ] **Error handling added**
  - [ ] try-catch block present
  - [ ] Exception logged
  - [ ] User-friendly error message
  - [ ] Appropriate return action
  
- [ ] **View data passing updated**
  - [ ] ViewBag or model used
  - [ ] JSON parsing if needed
  - [ ] Success/error messages passed

**Action Methods Completed:** ______ / ______

---

### 4.4 Remove Old Code

**Cleanup Checklist:**

- [ ] All ISmartComponentService usages removed
- [ ] All SmartRequest references removed
- [ ] All SmartResponse references removed
- [ ] All hard-coded SP names removed
- [ ] Unused using statements removed:
  - [ ] `using SmartFoundation.DataEngine.Core.Models;` (if not needed)
  - [ ] `using SmartFoundation.DataEngine.Core.Interfaces;` (if not needed)

**Verification Command:**
```powershell
# Search for remnants
Select-String -Path "Controllers\YourController.cs" -Pattern "ISmartComponentService|SmartRequest|SmartResponse" -CaseSensitive
```

**Expected:** No matches found

---

### 4.5 Build Controller

**Commands:**
```powershell
dotnet build SmartFoundation.Mvc/SmartFoundation.Mvc.csproj
```

**Verification:**
- [ ] Build succeeds (0 errors)
- [ ] No errors related to removed dependencies
- [ ] Service injection resolves correctly
- [ ] No warnings (or only acceptable warnings)

---

## Phase 5: Controller Testing

### 5.1 Update Controller Unit Tests

**Location:** `SmartFoundation.Mvc.Tests/Controllers/[Controller]Tests.cs`

**Update test setup:**
```csharp
// BEFORE:
private readonly Mock<ISmartComponentService> _mockDataEngine;

// AFTER:
private readonly Mock<YourService> _mockService;
private readonly Mock<ILogger<YourController>> _mockLogger;
```

**Update test mocks:**
```csharp
// BEFORE:
_mockDataEngine
    .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
    .ReturnsAsync(new SmartResponse { Success = true, Data = ... });

// AFTER:
_mockService
    .Setup(x => x.GetList(It.IsAny<Dictionary<string, object>>()))
    .ReturnsAsync(JsonSerializer.Serialize(new { success = true, data = ... }));
```

**Tests to Update:**

| Test Name | Status | Notes |
|-----------|--------|-------|
| | [ ] Updated | |
| | [ ] Updated | |
| | [ ] Updated | |
| | [ ] Updated | |

---

### 5.2 Run Controller Tests

**Commands:**
```powershell
dotnet test SmartFoundation.Mvc.Tests --filter "FullyQualifiedName~YourControllerTests"
```

**Results:**
- [ ] All tests passing
- [ ] Pass rate: 100% (______ passed, ______ failed)

**If tests fail, debug and fix before proceeding.**

---

### 5.3 Manual Testing (Local)

**Setup:**
```powershell
cd SmartFoundation.Mvc
dotnet run
```

**Test Each Action:**

| Action | URL | Expected Result | Status |
|--------|-----|-----------------|--------|
| Index | /Controller/Index | List displayed | [ ] Pass [ ] Fail |
| Details | /Controller/Details/1 | Details shown | [ ] Pass [ ] Fail |
| Create (GET) | /Controller/Create | Form displayed | [ ] Pass [ ] Fail |
| Create (POST) | (Submit form) | Record created | [ ] Pass [ ] Fail |
| Edit (GET) | /Controller/Edit/1 | Form with data | [ ] Pass [ ] Fail |
| Edit (POST) | (Submit form) | Record updated | [ ] Pass [ ] Fail |
| Delete | /Controller/Delete/1 | Confirmation shown | [ ] Pass [ ] Fail |
| Delete (POST) | (Confirm) | Record deleted | [ ] Pass [ ] Fail |

**Error Handling Tests:**

- [ ] Invalid ID (0, negative, non-existent): Handled gracefully
- [ ] Missing required field: Validation error shown
- [ ] Database error: Error message displayed
- [ ] Concurrent edit: Handled appropriately

**Performance Test:**
- [ ] Response times acceptable (< baseline + 20%)
- [ ] No noticeable slowdown

---

## Phase 6: Code Review

### 6.1 Self-Review Checklist

**Code Quality:**
- [ ] Follows project coding standards
- [ ] Consistent naming conventions
- [ ] No code duplication
- [ ] No commented-out code (remove old code)
- [ ] Proper indentation and formatting

**Architecture Compliance:**
- [ ] Service inherits from BaseService
- [ ] Service uses ExecuteOperation pattern
- [ ] No hard-coded SP names anywhere
- [ ] Controller is thin (business logic in service)
- [ ] Proper separation of concerns

**Documentation:**
- [ ] All public methods have XML documentation
- [ ] Complex logic has comments
- [ ] README updated if needed
- [ ] Migration notes documented

**Testing:**
- [ ] Service unit tests ≥80% coverage
- [ ] Controller unit tests updated
- [ ] Manual testing completed
- [ ] All tests passing

---

### 6.2 Peer Review

**Reviewer:** _______________________  
**Date:** _______

**Review Focus Areas:**

- [ ] **Architecture:** Follows Clean Architecture principles
- [ ] **Patterns:** Uses BaseService correctly
- [ ] **Mapping:** ProcedureMapper entries correct
- [ ] **DI:** Service properly registered
- [ ] **Validation:** Input validation adequate
- [ ] **Error Handling:** Try-catch blocks appropriate
- [ ] **Logging:** Sufficient logging added
- [ ] **Testing:** Test coverage sufficient
- [ ] **Documentation:** XML comments complete
- [ ] **Performance:** No obvious performance issues

**Comments:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Approval:**
- [ ] Approved - Ready for staging deployment
- [ ] Changes requested (see comments)

---

## Phase 7: Staging Deployment

### 7.1 Pre-Deployment

**Staging Environment Checks:**
- [ ] Staging database accessible
- [ ] Staging IIS configured
- [ ] Application pool running
- [ ] Connection strings correct
- [ ] Previous deployment successful

**Backup:**
- [ ] Database backup created
- [ ] Current code backed up
- [ ] Rollback procedure tested

---

### 7.2 Deploy to Staging

**Deployment Steps:**

1. [ ] Build release configuration
   ```powershell
   dotnet build SmartFoundation.sln --configuration Release
   ```

2. [ ] Publish application
   ```powershell
   dotnet publish SmartFoundation.Mvc -c Release -o .\publish
   ```

3. [ ] Stop IIS application pool
4. [ ] Copy files to staging server
5. [ ] Start IIS application pool
6. [ ] Verify application starts

**Deployment Time:** ____________  
**Deployed By:** _______________________

---

### 7.3 Smoke Tests (Staging)

**Basic Functionality:**

- [ ] Application loads (home page)
- [ ] Migrated controller loads (index page)
- [ ] Create operation works
- [ ] Read operation works
- [ ] Update operation works
- [ ] Delete operation works

**Error Scenarios:**

- [ ] Invalid input handled gracefully
- [ ] Error messages display correctly
- [ ] No unhandled exceptions

**Performance:**

- [ ] Response times acceptable
- [ ] No obvious slowdowns
- [ ] Database queries efficient

---

### 7.4 User Acceptance Testing (Staging)

**UAT Participants:**
- Product Owner: _______________________
- QA Lead: _______________________
- Business User: _______________________

**Test Scenarios:**

| Scenario | Expected | Actual | Status | Notes |
|----------|----------|--------|--------|-------|
| | | | [ ] Pass [ ] Fail | |
| | | | [ ] Pass [ ] Fail | |
| | | | [ ] Pass [ ] Fail | |
| | | | [ ] Pass [ ] Fail | |

**UAT Approval:**
- [ ] Approved for production
- [ ] Issues found (must fix before production)

**Sign-off:** _______________________ Date: _______

---

## Phase 8: Production Deployment

### 8.1 Pre-Production Checklist

**Preparation:**
- [ ] Staging tests passed
- [ ] UAT approved
- [ ] Deployment window scheduled
- [ ] Stakeholders notified
- [ ] Team available for support
- [ ] Rollback plan ready

**Deployment Details:**
- Scheduled date/time: _______________________
- Deployment window: ______ hours
- Team on call: _______________________
- Rollback contact: _______________________

---

### 8.2 Production Deployment Steps

**Pre-Deployment:**

1. [ ] Announce deployment (email/Slack)
2. [ ] Create database backup
3. [ ] Backup current application files
4. [ ] Test rollback procedure

**Deployment:**

1. [ ] Put application in maintenance mode (if applicable)
2. [ ] Build release configuration
3. [ ] Stop IIS application pool
4. [ ] Deploy files to production
5. [ ] Update configuration (if needed)
6. [ ] Start IIS application pool
7. [ ] Verify application starts
8. [ ] Remove maintenance mode

**Deployment Time:** ____________  
**Deployed By:** _______________________

---

### 8.3 Post-Deployment Verification

**Immediate Checks (within 15 minutes):**

- [ ] Application loads successfully
- [ ] Migrated controller accessible
- [ ] Home page loads
- [ ] Login functionality works
- [ ] No critical errors in logs

**Smoke Tests (within 30 minutes):**

- [ ] Create operation works
- [ ] Read operation works
- [ ] Update operation works
- [ ] Delete operation works
- [ ] Search/filter works
- [ ] Pagination works

**Performance Checks:**

- [ ] Response times within baseline + 10%
- [ ] No timeout errors
- [ ] Database queries efficient

---

### 8.4 Monitoring (First 24 Hours)

**Hour 1: Intensive Monitoring**

Every 15 minutes, check:
- [ ] Error rate in logs
- [ ] Response times
- [ ] User reports/complaints
- [ ] Database connection pool

**Hour 1-4: Active Monitoring**

Every 30 minutes, check:
- [ ] Error rate trends
- [ ] Performance metrics
- [ ] User feedback

**Hour 4-24: Passive Monitoring**

Every 2-4 hours, check:
- [ ] Error logs
- [ ] Performance dashboards
- [ ] Support tickets

**Metrics to Track:**

| Metric | Baseline | Current | Status |
|--------|----------|---------|--------|
| Error Rate | ____% | ____% | [ ] Normal [ ] Elevated |
| Avg Response Time | ____ms | ____ms | [ ] Normal [ ] Slow |
| Requests/Hour | ____ | ____ | [ ] Normal [ ] Low |
| User Complaints | ____ | ____ | [ ] None [ ] Some |

---

### 8.5 Rollback Decision

**Rollback Criteria:**

Rollback IF any of these occur:
- [ ] Error rate >5% for 15+ minutes
- [ ] Critical functionality broken
- [ ] Data integrity issues
- [ ] Performance degradation >30%
- [ ] Multiple user complaints

**Rollback Procedure:**

1. [ ] Stop IIS application pool
2. [ ] Restore previous application files
3. [ ] Restore database (if needed)
4. [ ] Start IIS application pool
5. [ ] Verify rollback successful
6. [ ] Notify stakeholders

**Rollback Decision:**
- [ ] No rollback needed - deployment successful
- [ ] Rollback initiated (see notes)

**Notes:**
```
_________________________________________________________________
_________________________________________________________________
```

---

## Phase 9: Post-Migration

### 9.1 Documentation Updates

**Update Documentation:**

- [ ] Architecture diagrams updated
- [ ] API documentation updated (if applicable)
- [ ] Migration log updated
- [ ] Lessons learned documented

**Files to Update:**

- [ ] README.md (if controller added/changed)
- [ ] Implementation Guide (if patterns changed)
- [ ] Migration tracking sheet

---

### 9.2 Knowledge Sharing

**Team Communication:**

- [ ] Demo completed migration to team
- [ ] Share lessons learned
- [ ] Update wiki/confluence
- [ ] Present in team meeting (if significant)

**Topics to Cover:**
- Challenges encountered
- Solutions implemented
- Performance improvements (if any)
- Recommendations for future migrations

---

### 9.3 Performance Baseline Update

**Update Baseline Metrics:**

| Metric | Before Migration | After Migration | Change |
|--------|------------------|-----------------|--------|
| Avg Response Time | ____ms | ____ms | ____% |
| Error Rate | ____% | ____% | ____% |
| Requests/Hour | ____ | ____ | ____% |
| Code Coverage | ____% | ____% | ____% |

---

### 9.4 Lessons Learned

**What Went Well:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**What Could Be Improved:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Recommendations for Next Migration:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### 9.5 Mark Complete

**Migration Status:**
- [ ] ✅ Controller fully migrated
- [ ] ✅ All tests passing
- [ ] ✅ Deployed to production
- [ ] ✅ Monitoring stable
- [ ] ✅ Documentation updated
- [ ] ✅ Knowledge shared

**Final Sign-off:**

- Developer: _______________________ Date: _______
- Technical Lead: _______________________ Date: _______
- QA Lead: _______________________ Date: _______

---

## Appendix A: Quick Reference

### Common Commands

```powershell
# Build solution
dotnet build SmartFoundation.sln

# Run tests
dotnet test SmartFoundation.Application.Tests
dotnet test SmartFoundation.Mvc.Tests

# Run application
cd SmartFoundation.Mvc
dotnet run

# Publish
dotnet publish SmartFoundation.Mvc -c Release -o .\publish

# Search for code patterns
Select-String -Path "Controllers\*.cs" -Pattern "ISmartComponentService"
```

### File Locations

- Service: `SmartFoundation.Application/Services/[Entity]Service.cs`
- Service Tests: `SmartFoundation.Application.Tests/Services/[Entity]ServiceTests.cs`
- Controller: `SmartFoundation.Mvc/Controllers/[Entity]Controller.cs`
- Controller Tests: `SmartFoundation.Mvc.Tests/Controllers/[Entity]ControllerTests.cs`
- ProcedureMapper: `SmartFoundation.Application/Mapping/ProcedureMapper.cs`
- DI Registration: `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs`

### Templates

- Service: `/docs/templates/NewApplicationServiceTemplate.cs`
- Controller: `/docs/templates/MigratedControllerTemplate.cs`

### Analysis Tools

- Dependency Scanner: `tools/Scan-ControllerDependencies.ps1`
- SP Extraction: `tools/Extract-StoredProcedures.ps1`
- Complexity Analysis: `tools/Merge-SPWithControllers.ps1`
- Traffic Analysis: `tools/Analyze-IISTraffic.ps1`
- Priority Ranking: `tools/Rank-MigrationPriority.ps1`

---

## Appendix B: Troubleshooting

### Common Issues

**Issue: Service not resolving in controller**
- Check DI registration in ServiceCollectionExtensions
- Verify service is public
- Check constructor signature

**Issue: ProcedureMapper throws InvalidOperationException**
- Verify mapping exists in _mappings dictionary
- Check spelling of module:operation key
- Ensure ProcedureMapper is accessible

**Issue: Tests failing after migration**
- Update test mocks to use service instead of DataEngine
- Check parameter names match
- Verify JSON response format

**Issue: Performance slower after migration**
- Check for multiple database calls (N+1 problem)
- Review SP execution plans
- Consider caching

---

## Document Control

**Version History:**

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-30 | Initial release |

**Next Review Date:** 2025-11-30

---

**End of Checklist**

---

## Notes Section

Use this space for migration-specific notes:

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```
