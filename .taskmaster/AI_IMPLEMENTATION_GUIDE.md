# AI Implementation Guide for SmartFoundation Application Layer

> **Important:** This guide is specifically written for AI agents implementing the tasks in this project.
> All tasks have been enhanced with exact code, commands, and patterns to follow.

## 🤖 Overview for AI Agents

This project will be **99% implemented by AI**. Each task includes:
- ✅ Exact file paths to create
- ✅ Complete code implementations
- ✅ PowerShell commands to run
- ✅ Unit tests with full code
- ✅ Verification steps

## 🎯 Critical Patterns You MUST Follow

### 1. **BaseService Pattern (MANDATORY)**

❌ **NEVER create a service like this:**
```csharp
public class EmployeeService
{
    private readonly ISmartComponentService _dataEngine;
    // This is WRONG - missing BaseService inheritance
}
```

✅ **ALWAYS create services like this:**
```csharp
public class EmployeeService : BaseService  // ← MUST inherit
{
    public EmployeeService(ISmartComponentService dataEngine, ILogger<EmployeeService> logger)
        : base(dataEngine, logger)  // ← MUST call base constructor
    {
    }

    public async Task<string> GetEmployees(Dictionary<string, object> parameters)
        => await ExecuteOperation("employee", "list", parameters);  // ← Use base method
}
```

### 2. **No Hard-Coded Stored Procedure Names**

❌ **NEVER do this:**
```csharp
var request = new SmartRequest
{
    SpName = "dbo.sp_SmartFormDemo"  // ❌ HARD-CODED SP NAME
};
```

✅ **ALWAYS use ProcedureMapper:**
```csharp
var spName = ProcedureMapper.GetProcedureName("employee", "list");  // ✅ Via mapper
```

✅ **OR use BaseService.ExecuteOperation():**
```csharp
return await ExecuteOperation("employee", "list", parameters);  // ✅ Best approach
```

### 3. **Standard JSON Response Format**

ALL service methods MUST return this JSON structure:
```json
{
  "success": true,
  "data": [ /* array of results */ ],
  "message": "Operation completed successfully"
}
```

Error response:
```json
{
  "success": false,
  "data": null,
  "message": "Error: Database connection failed"
}
```

### 4. **File Organization**

```
SmartFoundation.Application/
├── Services/
│   ├── BaseService.cs           ← Create this FIRST
│   ├── EmployeeService.cs       ← All inherit from BaseService
│   ├── MenuService.cs
│   └── DashboardService.cs
├── Mapping/
│   └── ProcedureMapper.cs       ← Centralized SP name mapping
├── Extensions/
│   └── ServiceCollectionExtensions.cs  ← DI registration
└── SmartFoundation.Application.csproj
```

## 📋 Implementation Checklist for Each Service

When creating a new service, follow this checklist:

- [ ] **Inherit from BaseService**
- [ ] **Constructor calls base(dataEngine, logger)**
- [ ] **All methods are async Task<string>**
- [ ] **Accept Dictionary<string, object> for parameters**
- [ ] **Use ExecuteOperation() from base class**
- [ ] **Add XML documentation with <summary>, <param>, <returns>**
- [ ] **Create unit tests with Moq**
- [ ] **Test both success and error scenarios**

## 🔧 Code Templates for AI

### Template: New Service Class

```csharp
using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for [DESCRIPTION].
/// </summary>
public class [ServiceName] : BaseService
{
    public [ServiceName](
        ISmartComponentService dataEngine, 
        ILogger<[ServiceName]> logger)
        : base(dataEngine, logger)
    {
    }

    /// <summary>
    /// [Method description]
    /// </summary>
    /// <param name="parameters">
    /// Required parameters:
    /// - [param1] ([type]): [description]
    /// Optional parameters:
    /// - [param2] ([type]): [description]
    /// </param>
    /// <returns>JSON string with success, data, and message</returns>
    public async Task<string> [MethodName](Dictionary<string, object> parameters)
        => await ExecuteOperation("[module]", "[operation]", parameters);
}
```

### Template: Unit Test Class

```csharp
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using System.Text.Json;

namespace SmartFoundation.Application.Tests.Services;

public class [ServiceName]Tests
{
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<ILogger<[ServiceName]>> _mockLogger;
    private readonly [ServiceName] _service;

    public [ServiceName]Tests()
    {
        _mockDataEngine = new Mock<ISmartComponentService>();
        _mockLogger = new Mock<ILogger<[ServiceName]>>();
        _service = new [ServiceName](_mockDataEngine.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task [Method]_WithValidParams_ReturnsSuccess()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>> { /* test data */ }
            });

        var parameters = new Dictionary<string, object> { /* params */ };

        // Act
        var result = await _service.[Method](parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    }

    [Fact]
    public async Task [Method]_WithError_ReturnsErrorJson()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ThrowsAsync(new Exception("Test error"));

        var parameters = new Dictionary<string, object> { /* params */ };

        // Act
        var result = await _service.[Method](parameters);

        // Assert
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("Test error", json.RootElement.GetProperty("message").GetString());
    }
}
```

### Template: Controller Refactoring

❌ **OLD (Direct DataEngine usage):**
```csharp
public class EmployeesController : Controller
{
    private readonly ISmartComponentService _dataEngine;  // ❌ Direct dependency

    public async Task<IActionResult> Index()
    {
        var request = new SmartRequest
        {
            SpName = "dbo.sp_SmartFormDemo"  // ❌ Hard-coded
        };
        var response = await _dataEngine.ExecuteAsync(request);
        // ...
    }
}
```

✅ **NEW (Application Layer):**
```csharp
public class EmployeesController : Controller
{
    private readonly EmployeeService _employeeService;  // ✅ Service dependency

    public EmployeesController(EmployeeService employeeService)
    {
        _employeeService = employeeService;
    }

    public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10)
    {
        // Validate input
        if (pageNumber < 1) pageNumber = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 10;

        // Prepare parameters
        var parameters = new Dictionary<string, object>
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

## 🚀 Common Commands for AI

### Create New Project
```powershell
cd "c:\Users\abdulaziz\Documents\GitHub\SmartFoundation"
dotnet new classlib -n SmartFoundation.Application -f net8.0
cd SmartFoundation.Application
mkdir Services; mkdir Mapping; mkdir Extensions
```

### Add Project Reference
```powershell
dotnet add SmartFoundation.Application reference SmartFoundation.DataEngine/SmartFoundation.DataEngine.csproj
```

### Add NuGet Packages
```powershell
cd SmartFoundation.Application
dotnet add package Microsoft.Extensions.DependencyInjection.Abstractions
dotnet add package Microsoft.Extensions.Logging.Abstractions
```

### Create Test Project
```powershell
dotnet new xunit -n SmartFoundation.Application.Tests
cd SmartFoundation.Application.Tests
dotnet add reference ../SmartFoundation.Application/SmartFoundation.Application.csproj
dotnet add package Moq
```

### Build and Test
```powershell
# Build
dotnet build SmartFoundation.sln

# Run tests
dotnet test SmartFoundation.Application.Tests

# Run specific test
dotnet test --filter "FullyQualifiedName~EmployeeServiceTests"
```

### Register Services in Program.cs
```csharp
// Add this to SmartFoundation.Mvc/Program.cs

// Register DataEngine services (if not already)
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();

// Register Application Layer services
builder.Services.AddScoped<EmployeeService>();
builder.Services.AddScoped<MenuService>();
builder.Services.AddScoped<DashboardService>();
```

## ⚠️ Common Mistakes to Avoid

### Mistake #1: Not Inheriting from BaseService
```csharp
// ❌ WRONG
public class EmployeeService
{
    // Missing inheritance
}

// ✅ CORRECT
public class EmployeeService : BaseService
{
    // Inherits from BaseService
}
```

### Mistake #2: Hard-Coding SP Names
```csharp
// ❌ WRONG
var request = new SmartRequest { SpName = "dbo.sp_SmartFormDemo" };

// ✅ CORRECT
await ExecuteOperation("employee", "list", parameters);
```

### Mistake #3: Incorrect Constructor
```csharp
// ❌ WRONG
public EmployeeService(ISmartComponentService dataEngine)
{
    _dataEngine = dataEngine;  // Not calling base
}

// ✅ CORRECT
public EmployeeService(ISmartComponentService dataEngine, ILogger<EmployeeService> logger)
    : base(dataEngine, logger)
{
}
```

### Mistake #4: Wrong Return Type
```csharp
// ❌ WRONG
public List<Employee> GetEmployees() { }

// ✅ CORRECT
public async Task<string> GetEmployees(Dictionary<string, object> parameters) { }
```

### Mistake #5: Not Using Async/Await
```csharp
// ❌ WRONG
public string GetEmployees(Dictionary<string, object> parameters)
{
    return ExecuteOperation("employee", "list", parameters).Result;
}

// ✅ CORRECT
public async Task<string> GetEmployees(Dictionary<string, object> parameters)
    => await ExecuteOperation("employee", "list", parameters);
```

## 📊 Progress Tracking

As an AI agent, after completing each subtask:

1. **Verify the implementation** matches the patterns above
2. **Run the build command** to ensure no compilation errors
3. **Run the tests** to verify functionality
4. **Update task status** in TaskMaster:
   ```bash
   taskmaster set-task-status [task-id] done
   ```

## 🎓 Learning from Examples

All enhanced subtasks include:
- **EXACT file paths** where code should be created
- **COMPLETE code implementations** (copy-paste ready)
- **FULL unit tests** with all scenarios
- **PowerShell commands** to execute
- **Verification steps** to confirm success

Look for these sections in each task:
- `EXACT FILE TO CREATE:`
- `FULL CODE IMPLEMENTATION:`
- `UNIT TEST TO CREATE:`
- `COMMANDS TO RUN:`
- `VERIFICATION:`

## 🔍 How to Read Task Files

Each task file (`.taskmaster/tasks/task_XXX.txt`) now contains:

```
# Task ID: X
# Title: [Task Title]
# Status: pending
# Dependencies: [List]

## Subtask X.Y: [Subtask Title]
### Details:
[Original description]

<info added on [timestamp]>
EXACT FILE TO CREATE: [path]

FULL CODE IMPLEMENTATION:
```[language]
[Complete code]
```

COMMANDS TO RUN:
```[shell]
[Commands]
```

VERIFICATION:
- [Check 1]
- [Check 2]
</info added>
```

## ✅ Final Checklist for AI

Before marking any task complete:

- [ ] All files created in correct locations
- [ ] All code follows the mandatory patterns
- [ ] BaseService inheritance used where required
- [ ] No hard-coded stored procedure names
- [ ] All methods have XML documentation
- [ ] Unit tests created and passing
- [ ] Solution builds without errors
- [ ] All verification steps completed

## 🆘 Getting Help

If you encounter issues:

1. **Check the pattern templates** in this document
2. **Review the enhanced task details** in `.taskmaster/tasks/`
3. **Look at the Implementation Guide** in `/docs/`
4. **Check the PRD** for business requirements
5. **Verify dependencies** are met before starting a task

## 📝 Summary

**For AI Agents:**
- ✅ Follow the exact code provided in each task
- ✅ Use the templates in this guide
- ✅ Avoid the common mistakes listed
- ✅ Verify each step before moving on
- ✅ Update task status after completion

**Remember:** 99% of this project will be implemented by AI. The tasks have been designed with complete, executable code examples to make your job easier!

---

**Last Updated:** October 30, 2025  
**Version:** 1.0 (AI-Enhanced)
