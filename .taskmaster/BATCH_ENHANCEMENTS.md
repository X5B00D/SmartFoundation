# Batch Task Enhancements for AI Implementation

> This document contains complete code, commands, and patterns for all remaining subtasks.
> Use this as a reference to update tasks systematically.

## Phase 2: Remaining Service Methods (2.4 - 2.10)

### 2.4: UpdateEmployee Method

**Add to EmployeeService.cs:**
```csharp
/// <summary>
/// Updates an existing employee's information.
/// </summary>
/// <param name="parameters">
/// - id (int, required): Employee ID to update
/// - firstName (string, optional): New first name
/// - lastName (string, optional): New last name
/// - email (string, optional): New email address
/// - phone (string, optional): New phone number
/// - departmentId (int, optional): New department ID
/// - salary (decimal, optional): New salary
/// </param>
/// <returns>JSON with success status and updated employee data</returns>
public async Task<string> UpdateEmployee(Dictionary<string, object> parameters)
{
    return await ExecuteOperation("employee", "update", parameters);
}
```

**Unit Tests:**
```csharp
[Fact]
public async Task UpdateEmployee_WithValidId_ReturnsSuccess()
{
    // Arrange
    _mockDataEngine.Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse {
            Success = true,
            Data = new List<Dictionary<string, object?>> { new() { { "Id", 1 }, { "Updated", true } } }
        });
    
    // Act
    var result = await _service.UpdateEmployee(new Dictionary<string, object> {
        { "id", 1 }, { "firstName", "Jane" }
    });
    
    // Assert
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());
}
```

---

### 2.5: DeleteEmployee Method

**Add to EmployeeService.cs:**
```csharp
/// <summary>
/// Deletes an employee record from the database.
/// </summary>
/// <param name="parameters">
/// - id (int, required): Employee ID to delete
/// </param>
/// <returns>JSON with success status</returns>
public async Task<string> DeleteEmployee(Dictionary<string, object> parameters)
{
    return await ExecuteOperation("employee", "delete", parameters);
}
```

**Unit Tests:**
```csharp
[Fact]
public async Task DeleteEmployee_WithValidId_ReturnsSuccess()
{
    _mockDataEngine.Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse { Success = true, Data = null });
    
    var result = await _service.DeleteEmployee(new Dictionary<string, object> { { "id", 1 } });
    
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());
}

[Fact]
public async Task DeleteEmployee_WithNonExistentId_ReturnsError()
{
    _mockDataEngine.Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ThrowsAsync(new Exception("Employee not found"));
    
    var result = await _service.DeleteEmployee(new Dictionary<string, object> { { "id", 999 } });
    
    var json = JsonDocument.Parse(result);
    Assert.False(json.RootElement.GetProperty("success").GetBoolean());
}
```

---

### 2.6: DashboardService Implementation

**File: SmartFoundation.Application/Services/DashboardService.cs**
```csharp
using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for dashboard data aggregation and metrics.
/// </summary>
public class DashboardService : BaseService
{
    public DashboardService(ISmartComponentService dataEngine, ILogger<DashboardService> logger)
        : base(dataEngine, logger)
    {
    }

    /// <summary>
    /// Retrieves summary metrics for the dashboard.
    /// </summary>
    /// <param name="parameters">
    /// - userId (int, optional): User ID for personalized dashboard
    /// - dateFrom (DateTime, optional): Start date for metrics
    /// - dateTo (DateTime, optional): End date for metrics
    /// </param>
    /// <returns>JSON with dashboard metrics</returns>
    public async Task<string> GetDashboardSummary(Dictionary<string, object> parameters)
    {
        return await ExecuteOperation("dashboard", "summary", parameters);
    }
}
```

**Update ProcedureMapper:**
```csharp
// Already exists: { "dashboard:summary", "dbo.sp_GetDashboardSummary" }
```

**Unit Tests: SmartFoundation.Application.Tests/Services/DashboardServiceTests.cs**
```csharp
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using System.Text.Json;

namespace SmartFoundation.Application.Tests.Services;

public class DashboardServiceTests
{
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<ILogger<DashboardService>> _mockLogger;
    private readonly DashboardService _service;

    public DashboardServiceTests()
    {
        _mockDataEngine = new Mock<ISmartComponentService>();
        _mockLogger = new Mock<ILogger<DashboardService>>();
        _service = new DashboardService(_mockDataEngine.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetDashboardSummary_ReturnsMetrics()
    {
        // Arrange
        _mockDataEngine.Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>
                {
                    new() {
                        { "TotalEmployees", 150 },
                        { "ActiveProjects", 12 },
                        { "Revenue", 500000.00m }
                    }
                }
            });

        // Act
        var result = await _service.GetDashboardSummary(new Dictionary<string, object>());

        // Assert
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
        var data = json.RootElement.GetProperty("data")[0];
        Assert.Equal(150, data.GetProperty("TotalEmployees").GetInt32());
    }
}
```

---

### 2.7-2.10: Unit Test Tasks

These are covered by the unit tests provided above. Each service method includes corresponding unit tests.

**Commands to Run All Tests:**
```powershell
cd "c:\Users\abdulaziz\Documents\GitHub\SmartFoundation"

# Run all Application Layer tests
dotnet test SmartFoundation.Application.Tests --verbosity normal

# Check code coverage
dotnet test SmartFoundation.Application.Tests --collect:"XPlat Code Coverage"

# Generate coverage report (requires ReportGenerator)
reportgenerator -reports:**/coverage.cobertura.xml -targetdir:./CoverageReport -reporttypes:Html

# Open coverage report
Start-Process ./CoverageReport/index.html
```

---

## Phase 3: MVC Migration (3.1-3.12)

### 3.1: Register Services in Program.cs

**File: SmartFoundation.Mvc/Program.cs**

**Find this section:**
```csharp
// Register DataEngine services
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();
```

**Add after it:**
```csharp
// Register Application Layer services
using SmartFoundation.Application.Extensions;
builder.Services.AddApplicationServices();
```

**Full registration block should look like:**
```csharp
// DataEngine services
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();

// Application Layer services
using SmartFoundation.Application.Extensions;
builder.Services.AddApplicationServices();
```

**Verification:**
```powershell
# Build MVC project
dotnet build SmartFoundation.Mvc/SmartFoundation.Mvc.csproj

# Run the application
dotnet run --project SmartFoundation.Mvc

# Check for DI errors in application startup
```

---

### 3.2: Refactor MenuItemsViewComponent

**File: SmartFoundation.Mvc/ViewComponents/MenuItemsViewComponent.cs**

**BEFORE:**
```csharp
public class MenuItemsViewComponent : ViewComponent
{
    private readonly ISmartComponentService _dataEngine;  // ❌ Direct dependency

    public MenuItemsViewComponent(ISmartComponentService dataEngine)
    {
        _dataEngine = dataEngine;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        var request = new SmartRequest
        {
            SpName = "dbo.ListOfMenuByUser_MVC",  // ❌ Hard-coded
            // ...
        };
        var response = await _dataEngine.ExecuteAsync(request);
        // ...
    }
}
```

**AFTER:**
```csharp
using SmartFoundation.Application.Services;
using System.Text.Json;

public class MenuItemsViewComponent : ViewComponent
{
    private readonly MenuService _menuService;  // ✅ Service dependency
    private readonly ILogger<MenuItemsViewComponent> _logger;

    public MenuItemsViewComponent(MenuService menuService, ILogger<MenuItemsViewComponent> logger)
    {
        _menuService = menuService;
        _logger = logger;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        try
        {
            // Get user ID from session/claims
            var userId = HttpContext.Session.GetInt32("UserId") ?? 0;
            
            if (userId == 0)
            {
                _logger.LogWarning("No user ID found in session");
                return View(new List<MenuItem>());
            }

            // Prepare parameters
            var parameters = new Dictionary<string, object>
            {
                { "userId", userId }
            };

            // Call service
            var jsonResult = await _menuService.GetUserMenu(parameters);
            
            // Deserialize response
            var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);
            
            if (!response.GetProperty("success").GetBoolean())
            {
                _logger.LogError("Failed to retrieve menu: {Message}", 
                    response.GetProperty("message").GetString());
                return View(new List<MenuItem>());
            }

            // Convert to MenuItem objects
            var menuData = response.GetProperty("data");
            var menuItems = JsonSerializer.Deserialize<List<MenuItem>>(menuData.GetRawText());

            return View(menuItems ?? new List<MenuItem>());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading menu items");
            return View(new List<MenuItem>());
        }
    }
}
```

---

### 3.3: Refactor EmployeesController Index Action

**File: SmartFoundation.Mvc/Controllers/EmployeesController.cs**

**BEFORE:**
```csharp
public class EmployeesController : Controller
{
    private readonly ISmartComponentService _dataEngine;

    public EmployeesController(ISmartComponentService dataEngine)
    {
        _dataEngine = dataEngine;
    }

    public async Task<IActionResult> Index()
    {
        var request = new SmartRequest
        {
            SpName = "dbo.sp_SmartFormDemo"  // ❌ Hard-coded
        };
        var response = await _dataEngine.ExecuteAsync(request);
        ViewBag.Data = response.Data;
        return View();
    }
}
```

**AFTER:**
```csharp
using SmartFoundation.Application.Services;
using System.Text.Json;

public class EmployeesController : Controller
{
    private readonly EmployeeService _employeeService;
    private readonly ILogger<EmployeesController> _logger;

    public EmployeesController(EmployeeService employeeService, ILogger<EmployeesController> logger)
    {
        _employeeService = employeeService;
        _logger = logger;
    }

    /// <summary>
    /// Displays paginated list of employees.
    /// </summary>
    public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10, string? search = null)
    {
        try
        {
            // Validate input
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 10;
            
            // Sanitize search term
            search = search?.Trim();
            if (search?.Length > 100) search = search.Substring(0, 100);

            // Prepare parameters
            var parameters = new Dictionary<string, object>
            {
                { "pageNumber", pageNumber },
                { "pageSize", pageSize }
            };

            if (!string.IsNullOrWhiteSpace(search))
            {
                parameters.Add("searchTerm", search);
            }

            // Call service
            var jsonResult = await _employeeService.GetEmployeeList(parameters);

            // Deserialize and pass to view
            var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);
            
            if (response.GetProperty("success").GetBoolean())
            {
                ViewBag.EmployeeData = response.GetProperty("data").GetRawText();
                ViewBag.PageNumber = pageNumber;
                ViewBag.PageSize = pageSize;
                ViewBag.SearchTerm = search;
            }
            else
            {
                ViewBag.ErrorMessage = response.GetProperty("message").GetString();
            }

            return View();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading employee list");
            ViewBag.ErrorMessage = "An error occurred while loading employees.";
            return View();
        }
    }
}
```

---

### 3.4: Refactor CRUD Actions

**Add these methods to EmployeesController:**

```csharp
/// <summary>
/// Displays employee creation form.
/// </summary>
[HttpGet]
public IActionResult Create()
{
    return View();
}

/// <summary>
/// Handles employee creation.
/// </summary>
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Create(EmployeeCreateModel model)
{
    if (!ModelState.IsValid)
    {
        return View(model);
    }

    try
    {
        var parameters = new Dictionary<string, object>
        {
            { "firstName", model.FirstName },
            { "lastName", model.LastName },
            { "email", model.Email },
            { "phone", model.Phone ?? "" },
            { "departmentId", model.DepartmentId },
            { "hireDate", model.HireDate }
        };

        var jsonResult = await _employeeService.CreateEmployee(parameters);
        var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);

        if (response.GetProperty("success").GetBoolean())
        {
            TempData["SuccessMessage"] = "Employee created successfully!";
            return RedirectToAction(nameof(Index));
        }
        else
        {
            ModelState.AddModelError("", response.GetProperty("message").GetString());
            return View(model);
        }
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error creating employee");
        ModelState.AddModelError("", "An error occurred while creating the employee.");
        return View(model);
    }
}

/// <summary>
/// Displays employee edit form.
/// </summary>
[HttpGet]
public async Task<IActionResult> Edit(int id)
{
    try
    {
        var parameters = new Dictionary<string, object> { { "id", id } };
        var jsonResult = await _employeeService.GetEmployeeById(parameters);
        var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);

        if (response.GetProperty("success").GetBoolean())
        {
            var employeeData = response.GetProperty("data")[0];
            var model = JsonSerializer.Deserialize<EmployeeEditModel>(employeeData.GetRawText());
            return View(model);
        }
        else
        {
            TempData["ErrorMessage"] = "Employee not found.";
            return RedirectToAction(nameof(Index));
        }
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error loading employee for edit");
        TempData["ErrorMessage"] = "An error occurred.";
        return RedirectToAction(nameof(Index));
    }
}

/// <summary>
/// Handles employee update.
/// </summary>
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Edit(int id, EmployeeEditModel model)
{
    if (!ModelState.IsValid)
    {
        return View(model);
    }

    try
    {
        var parameters = new Dictionary<string, object>
        {
            { "id", id },
            { "firstName", model.FirstName },
            { "lastName", model.LastName },
            { "email", model.Email },
            { "phone", model.Phone ?? "" },
            { "departmentId", model.DepartmentId }
        };

        var jsonResult = await _employeeService.UpdateEmployee(parameters);
        var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);

        if (response.GetProperty("success").GetBoolean())
        {
            TempData["SuccessMessage"] = "Employee updated successfully!";
            return RedirectToAction(nameof(Index));
        }
        else
        {
            ModelState.AddModelError("", response.GetProperty("message").GetString());
            return View(model);
        }
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error updating employee");
        ModelState.AddModelError("", "An error occurred while updating the employee.");
        return View(model);
    }
}

/// <summary>
/// Handles employee deletion.
/// </summary>
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Delete(int id)
{
    try
    {
        var parameters = new Dictionary<string, object> { { "id", id } };
        var jsonResult = await _employeeService.DeleteEmployee(parameters);
        var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);

        if (response.GetProperty("success").GetBoolean())
        {
            TempData["SuccessMessage"] = "Employee deleted successfully!";
        }
        else
        {
            TempData["ErrorMessage"] = response.GetProperty("message").GetString();
        }

        return RedirectToAction(nameof(Index));
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error deleting employee");
        TempData["ErrorMessage"] = "An error occurred while deleting the employee.";
        return RedirectToAction(nameof(Index));
    }
}
```

---

### 3.6: Audit for Hard-Coded SP Names

**PowerShell Script: audit-sp-names.ps1**
```powershell
# Audit script to find hard-coded stored procedure names

Write-Host "=== Auditing for Hard-Coded SP Names ===" -ForegroundColor Cyan

$patterns = @(
    "sp_",
    "usp_",
    "dbo\.",
    "SpName\s*=\s*`"",
    "SpName\s*=\s*@`""
)

$mvcPath = "SmartFoundation.Mvc"
$results = @()

foreach ($pattern in $patterns) {
    Write-Host "`nSearching for pattern: $pattern" -ForegroundColor Yellow
    
    $matches = Get-ChildItem -Path $mvcPath -Recurse -Include *.cs |
        Select-String -Pattern $pattern |
        Where-Object { $_.Line -notmatch "//.*$pattern" }  # Exclude comments
    
    foreach ($match in $matches) {
        $results += [PSCustomObject]@{
            File = $match.Path
            Line = $match.LineNumber
            Code = $match.Line.Trim()
        }
        
        Write-Host "  Found in: $($match.Path):$($match.LineNumber)" -ForegroundColor Red
        Write-Host "    $($match.Line.Trim())" -ForegroundColor Gray
    }
}

# Generate report
$reportPath = ".taskmaster/reports/sp-audit-report.csv"
$results | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "`n=== Audit Complete ===" -ForegroundColor Cyan
Write-Host "Total findings: $($results.Count)" -ForegroundColor $(if ($results.Count -eq 0) { "Green" } else { "Red" })
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host "✓ No hard-coded SP names found!" -ForegroundColor Green
} else {
    Write-Host "✗ Please refactor the files listed above" -ForegroundColor Red
}
```

**Run Audit:**
```powershell
.\audit-sp-names.ps1
```

---

### 3.7-3.9: Integration Testing

**Create: SmartFoundation.Mvc.Tests/Integration/EmployeesControllerIntegrationTests.cs**

```csharp
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;
using Xunit;

namespace SmartFoundation.Mvc.Tests.Integration;

public class EmployeesControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public EmployeesControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Get_EmployeesIndex_ReturnsSuccess()
    {
        // Act
        var response = await _client.GetAsync("/Employees");

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Employees", content);
    }

    [Fact]
    public async Task Get_EmployeesIndexWithPagination_ReturnsSuccess()
    {
        // Act
        var response = await _client.GetAsync("/Employees?pageNumber=2&pageSize=20");

        // Assert
        response.EnsureSuccessStatusCode();
    }

    [Theory]
    [InlineData("/Employees/Create")]
    [InlineData("/Employees/Edit/1")]
    public async Task Get_EmployeesCrudPages_ReturnsSuccess(string url)
    {
        // Act
        var response = await _client.GetAsync(url);

        // Assert
        Assert.True(
            response.StatusCode == HttpStatusCode.OK || 
            response.StatusCode == HttpStatusCode.Redirect  // May redirect if not authenticated
        );
    }
}
```

---

### 3.10: Performance Benchmarking

**Create: benchmark-performance.ps1**
```powershell
# Performance benchmarking script

Write-Host "=== Performance Benchmarking ===" -ForegroundColor Cyan

# Using Apache Bench (ab) or Artillery
# Install: npm install -g artillery

$endpoints = @(
    @{ Name = "Employees Index"; Url = "http://localhost:5000/Employees" },
    @{ Name = "Employees Page 2"; Url = "http://localhost:5000/Employees?pageNumber=2" },
    @{ Name = "Dashboard"; Url = "http://localhost:5000/Dashboard" }
)

foreach ($endpoint in $endpoints) {
    Write-Host "`nTesting: $($endpoint.Name)" -ForegroundColor Yellow
    
    # Run Artillery test
    $config = @"
config:
  target: '$($endpoint.Url)'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - flow:
      - get:
          url: '/'
"@
    
    $config | Out-File -FilePath "temp-artillery-config.yml"
    artillery run temp-artillery-config.yml
    Remove-Item "temp-artillery-config.yml"
}

Write-Host "`n=== Benchmarking Complete ===" -ForegroundColor Cyan
```

---

## Phase 4-7: Summary Commands

Due to space constraints, here are the key implementation patterns for remaining phases:

### Phase 4: Documentation & Deployment

**4.1: Architecture Documentation**
- Use Mermaid.js diagrams in Markdown
- Document data flow with sequence diagrams
- Include component interaction diagrams

**4.8: Deployment Runbook Template**
```markdown
# Deployment Runbook

## Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Code review approved
- [ ] Staging validation complete
- [ ] Backup database
- [ ] Notify stakeholders

## Deployment Steps
1. Stop application: `iisreset /stop`
2. Backup current version: `xcopy /E /I C:\inetpub\wwwroot\app C:\backups\app-backup-{date}`
3. Deploy new version: `dotnet publish -c Release`
4. Update appsettings.json
5. Run database migrations
6. Start application: `iisreset /start`
7. Smoke tests
8. Monitor logs

## Rollback Plan
1. Stop application
2. Restore backup: `xcopy /E /I C:\backups\app-backup-{date} C:\inetpub\wwwroot\app`
3. Revert database migrations
4. Start application
5. Verify rollback successful
```

### Phase 7: Error Handling & Middleware

**7.1: Standard Error Response Format**
```csharp
public class ErrorResponse
{
    public string ErrorCode { get; set; }
    public string Message { get; set; }
    public string Details { get; set; }
    public string TraceId { get; set; }
    public DateTime Timestamp { get; set; }
}
```

**7.6: Global Exception Middleware**
```csharp
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = exception switch
        {
            NotFoundException => StatusCodes.Status404NotFound,
            ValidationException => StatusCodes.Status400BadRequest,
            UnauthorizedException => StatusCodes.Status401Unauthorized,
            _ => StatusCodes.Status500InternalServerError
        };

        var response = new ErrorResponse
        {
            ErrorCode = $"ERR_{context.Response.StatusCode}",
            Message = exception.Message,
            TraceId = Activity.Current?.Id ?? context.TraceIdentifier,
            Timestamp = DateTime.UtcNow
        };

        return context.Response.WriteAsJsonAsync(response);
    }
}
```

**Register Middleware:**
```csharp
app.UseMiddleware<GlobalExceptionMiddleware>();
```

---

## Task 5: Audit & Inventory

**Create: audit-controllers.ps1**
```powershell
$controllers = Get-ChildItem -Path "SmartFoundation.Mvc/Controllers" -Filter "*.cs"

$inventory = foreach ($controller in $controllers) {
    $content = Get-Content $controller.FullName -Raw
    
    $hasISmartComponentService = $content -match "ISmartComponentService"
    $hasHardCodedSP = $content -match "SpName\s*=\s*`""
    $hasApplicationService = $content -match "Service\s+_\w+Service"
    
    [PSCustomObject]@{
        Controller = $controller.Name
        UsesDataEngine = $hasISmartComponentService
        HasHardCodedSP = $hasHardCodedSP
        UsesApplicationLayer = $hasApplicationService
        Priority = if ($hasHardCodedSP) { "HIGH" } elseif ($hasISmartComponentService) { "MEDIUM" } else { "LOW" }
        Status = if ($hasApplicationService) { "MIGRATED" } else { "PENDING" }
    }
}

$inventory | Export-Csv -Path ".taskmaster/reports/controller-inventory.csv" -NoTypeInformation
$inventory | Format-Table -AutoSize
```

---

## Quick Reference Commands

**Build Everything:**
```powershell
dotnet clean SmartFoundation.sln
dotnet restore SmartFoundation.sln
dotnet build SmartFoundation.sln --configuration Debug
```

**Run All Tests:**
```powershell
dotnet test SmartFoundation.Application.Tests --verbosity normal
dotnet test SmartFoundation.Mvc.Tests --verbosity normal
```

**Check Code Coverage:**
```powershell
dotnet test --collect:"XPlat Code Coverage"
reportgenerator -reports:**/coverage.cobertura.xml -targetdir:./CoverageReport
```

**Run Application:**
```powershell
dotnet run --project SmartFoundation.Mvc
```

---

## Completion Checklist

### Phase 1: Foundation ✅
- [x] Project structure
- [x] BaseService
- [x] ProcedureMapper
- [x] DI setup
- [x] Tests configured

### Phase 2: Services (In Progress)
- [x] EmployeeService
- [x] MenuService
- [ ] DashboardService methods
- [ ] Complete unit tests

### Phase 3: MVC Migration
- [ ] Service registration
- [ ] ViewComponent refactoring
- [ ] Controller refactoring
- [ ] Integration tests
- [ ] Performance validation

### Phase 4-7: Finalization
- [ ] Documentation
- [ ] Deployment runbook
- [ ] Error handling
- [ ] Monitoring setup

---

**Last Updated:** October 30, 2025
**Document Version:** 1.0
