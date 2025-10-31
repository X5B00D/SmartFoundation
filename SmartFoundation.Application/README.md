# SmartFoundation.Application

## Overview

The Application Layer provides business logic and orchestration between the Presentation Layer (MVC) and the Data Access Layer (DataEngine). This layer implements the Clean Architecture pattern, ensuring separation of concerns and maintainability.

## Architecture

```
SmartFoundation.Mvc (Presentation)
    ↓
SmartFoundation.Application (Business Logic) ← YOU ARE HERE
    ↓
SmartFoundation.DataEngine (Data Access)
    ↓
Database (SQL Server)
```

## Folder Structure

```
SmartFoundation.Application/
├── Services/               # Business service classes
│   ├── BaseService.cs     # MANDATORY base class for all services
│   ├── EmployeeService.cs
│   ├── MenuService.cs
│   └── DashboardService.cs
├── Mapping/
│   └── ProcedureMapper.cs # Centralized SP name mapping
├── Extensions/
│   └── ServiceCollectionExtensions.cs  # DI registration
└── SmartFoundation.Application.csproj
```

## Key Components

### 1. BaseService (MANDATORY Pattern)

**ALL service classes MUST inherit from `BaseService`**

```csharp
public class YourService : BaseService  // ← MANDATORY
{
    public YourService(ISmartComponentService dataEngine, ILogger<YourService> logger)
        : base(dataEngine, logger)  // ← Call base constructor
    {
    }

    public async Task<string> YourMethod(Dictionary<string, object?> parameters)
        => await ExecuteOperation("module", "operation", parameters);
}
```

**Why Mandatory?**

- ✅ Eliminates code duplication
- ✅ Ensures consistent error handling
- ✅ Standardizes JSON response format
- ✅ Centralizes logging
- ✅ Makes maintenance easier

### 2. ProcedureMapper

Centralized mapping of business operations to stored procedure names. **Never hard-code SP names!**

```csharp
// ❌ WRONG - Hard-coded SP name
var request = new SmartRequest { SpName = "dbo.sp_SmartFormDemo" };

// ✅ CORRECT - Use ProcedureMapper
var spName = ProcedureMapper.GetProcedureName("employee", "list");

// ✅ BEST - Use BaseService.ExecuteOperation()
return await ExecuteOperation("employee", "list", parameters);
```

**Adding New Mappings:**

1. Open `Mapping/ProcedureMapper.cs`
2. Add entry to the `_mappings` dictionary:

   ```csharp
   { "yourModule:operation", "dbo.sp_YourStoredProcedure" }
   ```

### 3. Service Methods Pattern

All service methods follow this pattern:

```csharp
/// <summary>
/// [Clear description of what this method does]
/// </summary>
/// <param name="parameters">
/// Required parameters:
/// - paramName (type): description
/// Optional parameters:
/// - paramName (type): description
/// </param>
/// <returns>JSON string with format: { success, data, message }</returns>
public async Task<string> MethodName(Dictionary<string, object?> parameters)
    => await ExecuteOperation("module", "operation", parameters);
```

**Standard JSON Response:**

```json
{
  "success": true,
  "data": [ /* array of results */ ],
  "message": "Operation completed successfully"
}
```

## Creating a New Service

### Step 1: Create Service Class

```csharp
using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing [entity] operations.
/// </summary>
public class YourService : BaseService
{
    public YourService(
        ISmartComponentService dataEngine,
        ILogger<YourService> logger)
        : base(dataEngine, logger)
    {
    }

    public async Task<string> GetList(Dictionary<string, object?> parameters)
        => await ExecuteOperation("yourModule", "list", parameters);
}
```

### Step 2: Add Stored Procedure Mapping

Edit `Mapping/ProcedureMapper.cs`:

```csharp
{ "yourModule:list", "dbo.sp_YourStoredProcedure" }
```

### Step 3: Register Service

Edit `Extensions/ServiceCollectionExtensions.cs`:

```csharp
services.AddScoped<YourService>();
```

### Step 4: Create Unit Tests

```csharp
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
            .ReturnsAsync(new SmartResponse { Success = true, Data = /* ... */ });

        // Act
        var result = await _service.GetList(new Dictionary<string, object?>());

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    }
}
```

## Usage in MVC Controllers

### Before (Direct DataEngine):

```csharp
public class EmployeesController : Controller
{
    private readonly ISmartComponentService _dataEngine;  // ❌ Direct dependency

    public async Task<IActionResult> Index()
    {
        var request = new SmartRequest { SpName = "dbo.sp_SmartFormDemo" };  // ❌ Hard-coded
        var response = await _dataEngine.ExecuteAsync(request);
        // ...
    }
}
```

### After (Application Layer):

```csharp
public class EmployeesController : Controller
{
    private readonly EmployeeService _employeeService;  // ✅ Service dependency

    public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10)
    {
        // Validate input
        if (pageNumber < 1) pageNumber = 1;

        // Prepare parameters
        var parameters = new Dictionary<string, object?>
        {
            { "pageNumber", pageNumber },
            { "pageSize", pageSize }
        };

        // Call service
        var data = await _employeeService.GetEmployeeList(parameters);

        // Pass to view
        ViewBag.EmployeeData = data;
        return View();
    }
}
```

## Testing

### Run All Tests

```powershell
dotnet test SmartFoundation.Application.Tests
```

### Run Specific Test

```powershell
dotnet test --filter "FullyQualifiedName~EmployeeServiceTests"
```

### Check Code Coverage

```powershell
dotnet test SmartFoundation.Application.Tests --collect:"XPlat Code Coverage"
```

#### **Target: ≥80% code coverage**

## Common Mistakes to Avoid

### ❌ Not Inheriting from BaseService

```csharp
// WRONG
public class MyService
{
    private readonly ISmartComponentService _dataEngine;
}
```

### ❌ Hard-Coding Stored Procedure Names

```csharp
// WRONG
var request = new SmartRequest { SpName = "dbo.sp_Something" };
```

### ❌ Wrong Constructor Pattern

```csharp
// WRONG
public MyService(ISmartComponentService dataEngine)
{
    _dataEngine = dataEngine;  // Not calling base
}
```

### ❌ Synchronous Methods

```csharp
// WRONG
public string GetData() { }

// CORRECT
public async Task<string> GetData(Dictionary<string, object?> parameters) { }
```

## Dependencies

- **SmartFoundation.DataEngine**: Data access operations
- **Microsoft.Extensions.DependencyInjection.Abstractions**: DI support
- **Microsoft.Extensions.Logging.Abstractions**: Logging support
- **System.Text.Json**: JSON serialization

## Additional Resources

- [Architecture Diagram](/docs/architecture.md)
- [Implementation Guide](/docs/ImplementationGuide.md)
- [PRD](/docs/PRD.md)
- [Copilot Instructions](/.github/copilot-instructions.md)

## Support

For questions or issues:

1. Check this README
2. Review existing service implementations
3. Consult the team lead

---

**Last Updated:** October 31, 2025  
**Version:** 1.0
