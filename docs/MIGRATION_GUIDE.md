# Migration Guide: Creating Application Layer Services

This guide explains how to migrate controllers to use the new Clean Architecture pattern with Application Layer services.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step-by-Step Migration Process](#step-by-step-migration-process)
- [Complete Example: DepartmentService](#complete-example-departmentservice)
- [Testing Your Service](#testing-your-service)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

The SmartFoundation project follows Clean Architecture principles with an intelligent routing system:

```
Controller → SmartComponentController → [Route Found?]
                                         ├─ Yes → Application Layer Service
                                         └─ No → Legacy DataEngine (Fallback)
```

**Benefits:**

- ✅ Separation of concerns (business logic isolated from controllers)
- ✅ Testability (services can be unit tested independently)
- ✅ Reusability (services can be used by multiple controllers)
- ✅ Backward compatibility (unmigrated SPs automatically use DataEngine)
- ✅ Type safety and IntelliSense support

---

## Prerequisites

Before migrating a controller, ensure you have:

1. **Identified the stored procedures** used by the controller
2. **Determined the operations** (select, insert, update, delete, etc.)
3. **Reviewed the EmployeeService** implementation as a reference
4. **Understanding of the BaseService pattern**

**Required files to modify:**

- `SmartFoundation.Application/Services/{YourService}.cs` (create new)
- `SmartFoundation.Application/Mapping/ProcedureMapper.cs` (update mappings)
- `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs` (register service)
- `SmartFoundation.Application.Tests/Services/{YourService}Tests.cs` (create tests)

---

## Step-by-Step Migration Process

### Step 1: Create Your Service Class

Create a new service class in `SmartFoundation.Application/Services/` that inherits from `BaseService`.

**Template:**

```csharp
using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing {entity}-related operations.
/// Handles CRUD operations and {entity} data retrieval.
/// MANDATORY: Inherits from BaseService
/// </summary>
public class {Entity}Service : BaseService
{
    /// <summary>
    /// Constructor for {Entity}Service.
    /// </summary>
    /// <param name="dataEngine">DataEngine service injected via DI</param>
    /// <param name="logger">Logger instance specific to {Entity}Service</param>
    public {Entity}Service(
        ISmartComponentService dataEngine,
        ILogger<{Entity}Service> logger)
        : base(dataEngine, logger)
    {
    }

    // Add your service methods here...
}
```

**Example: DepartmentService.cs**

```csharp
using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing department-related operations.
/// Handles CRUD operations and department data retrieval.
/// </summary>
public class DepartmentService : BaseService
{
    public DepartmentService(
        ISmartComponentService dataEngine,
        ILogger<DepartmentService> logger)
        : base(dataEngine, logger)
    {
    }
}
```

---

### Step 2: Implement Service Methods

Add methods for each operation. Each method should:

- Accept `Dictionary<string, object?>` as parameter
- Return `Task<string>` (JSON string)
- Call `ExecuteOperation()` from BaseService
- Include comprehensive XML documentation

**Method Template:**

```csharp
/// <summary>
/// {Brief description of what this method does}.
/// </summary>
/// <param name="parameters">
/// Dictionary containing request parameters:
/// - {paramName} ({type}, required): {description}
/// - {paramName} ({type}, optional): {description}
/// </param>
/// <returns>
/// JSON string containing:
/// - success (bool): Whether the operation succeeded
/// - data (object/array): Result data or null
/// - message (string): Success or error message
/// </returns>
/// <example>
/// <code>
/// var parameters = new Dictionary&lt;string, object?&gt;
/// {
///     { "paramName", value }
/// };
/// var result = await _service.MethodName(parameters);
/// </code>
/// </example>
public async Task<string> MethodName(Dictionary<string, object?> parameters)
{
    return await ExecuteOperation("{module}", "{operation}", parameters);
}
```

**Example: DepartmentService methods**

```csharp
/// <summary>
/// Retrieves a paginated list of departments.
/// </summary>
/// <param name="parameters">
/// Dictionary containing request parameters:
/// - pageNumber (int, required): Page number to retrieve (1-based)
/// - pageSize (int, required): Number of records per page
/// - searchTerm (string, optional): Text to search in department name
/// </param>
/// <returns>
/// JSON string containing:
/// - success (bool): Whether the operation succeeded
/// - data (array): List of department objects
/// - message (string): Success or error message
/// </returns>
public async Task<string> GetDepartmentList(Dictionary<string, object?> parameters)
{
    return await ExecuteOperation("department", "list", parameters);
}

/// <summary>
/// Creates a new department record.
/// </summary>
/// <param name="parameters">
/// Dictionary containing:
/// - departmentName (string, required): Name of the department
/// - managerId (int, optional): ID of the department manager
/// </param>
/// <returns>JSON string with creation result</returns>
public async Task<string> CreateDepartment(Dictionary<string, object?> parameters)
{
    return await ExecuteOperation("department", "insert", parameters);
}

/// <summary>
/// Updates an existing department record.
/// </summary>
/// <param name="parameters">
/// Dictionary containing:
/// - departmentId (int, required): Department identifier
/// - departmentName (string, required): Updated department name
/// - managerId (int, optional): Updated manager ID
/// </param>
/// <returns>JSON string with update result</returns>
public async Task<string> UpdateDepartment(Dictionary<string, object?> parameters)
{
    return await ExecuteOperation("department", "update", parameters);
}

/// <summary>
/// Deletes a department record.
/// </summary>
/// <param name="parameters">
/// Dictionary containing:
/// - departmentId (int, required): Department identifier to delete
/// </param>
/// <returns>JSON string with deletion result</returns>
public async Task<string> DeleteDepartment(Dictionary<string, object?> parameters)
{
    return await ExecuteOperation("department", "delete", parameters);
}
```

---

### Step 3: Register in ProcedureMapper

Update `SmartFoundation.Application/Mapping/ProcedureMapper.cs` to map your stored procedures to the service.

**Add to `_serviceRegistry` dictionary:**

```csharp
private static readonly Dictionary<string, ServiceRoute> _serviceRegistry = new(StringComparer.OrdinalIgnoreCase)
{
    // Existing mappings...
    { "dbo.sp_SmartFormDemo", new ServiceRoute("employee", typeof(Services.EmployeeService), null!, "dbo.sp_SmartFormDemo") },
    
    // Add your new mapping
    { "dbo.sp_DepartmentOperations", new ServiceRoute("department", typeof(Services.DepartmentService), null!, "dbo.sp_DepartmentOperations") }
};
```

**Add operation mappings to `_operationMethodMap` dictionary (if needed):**

```csharp
private static readonly Dictionary<string, string> _operationMethodMap = new(StringComparer.OrdinalIgnoreCase)
{
    // Standard CRUD operations
    { "select", "GetEmployeeList" },
    { "insert", "CreateEmployee" },
    { "update", "UpdateEmployee" },
    { "delete", "DeleteEmployee" },
    
    // Add custom operation mappings if needed
    { "list", "GetDepartmentList" },    // Maps "list" operation to GetDepartmentList method
    { "create", "CreateDepartment" },   // Alternative name for insert
    { "getById", "GetDepartmentById" }
};
```

**⚠️ Important Notes:**

- The `_serviceRegistry` key is the **stored procedure name** (case-insensitive)
- The `ServiceRoute` contains: module name, service type, null for method name, SP name
- The `_operationMethodMap` maps **front-end operation names** to **service method names**
- Use consistent naming conventions for modules (e.g., "employee", "department")

---

### Step 4: Register Service in Dependency Injection

Update `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs`:

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Existing services
        services.AddScoped<EmployeeService>();
        services.AddScoped<MenuService>();
        services.AddScoped<DashboardService>();
        
        // Add your new service
        services.AddScoped<DepartmentService>();
        
        return services;
    }
}
```

**Service Lifetime Guidelines:**

- ✅ **Use `AddScoped`** (recommended): One instance per HTTP request
- ❌ Avoid `AddTransient`: Creates new instance every time (performance impact)
- ❌ Avoid `AddSingleton`: One instance for application lifetime (not suitable for services with state)

---

### Step 5: Update Controller (Optional)

Your controller doesn't need to change! The `SmartComponentController` automatically routes requests based on the stored procedure name.

However, if you want to inject your service directly into a controller:

```csharp
public class DepartmentsController : Controller
{
    private readonly DepartmentService _departmentService;
    private readonly ILogger<DepartmentsController> _logger;

    public DepartmentsController(
        DepartmentService departmentService,
        ILogger<DepartmentsController> logger)
    {
        _departmentService = departmentService;
        _logger = logger;
    }

    public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10)
    {
        try
        {
            // Validate input
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 10;

            var parameters = new Dictionary<string, object?>
            {
                { "pageNumber", pageNumber },
                { "pageSize", pageSize }
            };

            var jsonResult = await _departmentService.GetDepartmentList(parameters);
            
            ViewBag.DepartmentData = jsonResult;
            return View();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading departments");
            return View("Error");
        }
    }
}
```

---

## Complete Example: DepartmentService

Here's a complete, working example you can copy and adapt:

### File: `SmartFoundation.Application/Services/DepartmentService.cs`

```csharp
using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing department-related operations.
/// Handles CRUD operations, reporting, and department data retrieval.
/// </summary>
public class DepartmentService : BaseService
{
    /// <summary>
    /// Constructor for DepartmentService.
    /// </summary>
    /// <param name="dataEngine">DataEngine service injected via DI</param>
    /// <param name="logger">Logger instance specific to DepartmentService</param>
    public DepartmentService(
        ISmartComponentService dataEngine,
        ILogger<DepartmentService> logger)
        : base(dataEngine, logger)
    {
    }

    /// <summary>
    /// Retrieves a paginated list of departments with optional search filtering.
    /// </summary>
    /// <param name="parameters">
    /// Dictionary containing request parameters:
    /// - pageNumber (int, required): Page number to retrieve (1-based)
    /// - pageSize (int, required): Number of records per page (1-100)
    /// - searchTerm (string, optional): Text to search in department name or code
    /// </param>
    /// <returns>
    /// JSON string containing:
    /// - success (bool): Whether the operation succeeded
    /// - data (array): List of department objects with id, name, managerName, employeeCount
    /// - message (string): Success or error message
    /// </returns>
    /// <example>
    /// <code>
    /// var parameters = new Dictionary&lt;string, object?&gt;
    /// {
    ///     { "pageNumber", 1 },
    ///     { "pageSize", 10 },
    ///     { "searchTerm", "sales" }
    /// };
    /// var result = await departmentService.GetDepartmentList(parameters);
    /// </code>
    /// </example>
    public async Task<string> GetDepartmentList(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("department", "list", parameters);
    }

    /// <summary>
    /// Retrieves a single department record by its unique identifier.
    /// </summary>
    /// <param name="parameters">
    /// Dictionary containing:
    /// - departmentId (int, required): Unique identifier of the department to retrieve
    /// </param>
    /// <returns>
    /// JSON string containing:
    /// - success (bool): Whether the operation succeeded
    /// - data (object): Department object with full details, or null if not found
    /// - message (string): Success or error message
    /// </returns>
    public async Task<string> GetDepartmentById(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("department", "getById", parameters);
    }

    /// <summary>
    /// Creates a new department record.
    /// </summary>
    /// <param name="parameters">
    /// Dictionary containing:
    /// - departmentName (string, required): Name of the department (max 100 chars)
    /// - departmentCode (string, required): Unique code for the department (max 20 chars)
    /// - managerId (int, optional): ID of the department manager
    /// - description (string, optional): Department description
    /// </param>
    /// <returns>
    /// JSON string containing:
    /// - success (bool): Whether the operation succeeded
    /// - data (object): Created department object with generated ID
    /// - message (string): Success or error message
    /// </returns>
    public async Task<string> CreateDepartment(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("department", "insert", parameters);
    }

    /// <summary>
    /// Updates an existing department record.
    /// </summary>
    /// <param name="parameters">
    /// Dictionary containing:
    /// - departmentId (int, required): Department identifier
    /// - departmentName (string, required): Updated department name
    /// - departmentCode (string, required): Updated department code
    /// - managerId (int, optional): Updated manager ID
    /// - description (string, optional): Updated description
    /// </param>
    /// <returns>
    /// JSON string containing:
    /// - success (bool): Whether the operation succeeded
    /// - data (object): Updated department object
    /// - message (string): Success or error message
    /// </returns>
    public async Task<string> UpdateDepartment(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("department", "update", parameters);
    }

    /// <summary>
    /// Deletes a department record.
    /// </summary>
    /// <param name="parameters">
    /// Dictionary containing:
    /// - departmentId (int, required): Department identifier to delete
    /// </param>
    /// <returns>
    /// JSON string containing:
    /// - success (bool): Whether the operation succeeded
    /// - data (null): No data returned for delete operations
    /// - message (string): Success or error message
    /// </returns>
    public async Task<string> DeleteDepartment(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("department", "delete", parameters);
    }
}
```

### Updates to ProcedureMapper.cs

```csharp
// In _serviceRegistry dictionary:
{ "dbo.sp_DepartmentOperations", new ServiceRoute("department", typeof(Services.DepartmentService), null!, "dbo.sp_DepartmentOperations") }

// In _operationMethodMap dictionary (if using custom operations):
{ "list", "GetDepartmentList" },
{ "getById", "GetDepartmentById" }
```

### Updates to ServiceCollectionExtensions.cs

```csharp
public static IServiceCollection AddApplicationServices(this IServiceCollection services)
{
    services.AddScoped<EmployeeService>();
    services.AddScoped<MenuService>();
    services.AddScoped<DashboardService>();
    services.AddScoped<DepartmentService>();  // Add this line
    
    return services;
}
```

---

## Testing Your Service

### Step 1: Create Unit Tests

Create `SmartFoundation.Application.Tests/Services/DepartmentServiceTests.cs`:

```csharp
using Microsoft.Extensions.Logging;
using Moq;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using System.Text.Json;
using Xunit;

namespace SmartFoundation.Application.Tests.Services;

/// <summary>
/// Unit tests for DepartmentService to verify correct interaction with DataEngine.
/// </summary>
public class DepartmentServiceTests
{
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<ILogger<DepartmentService>> _mockLogger;
    private readonly DepartmentService _service;

    public DepartmentServiceTests()
    {
        _mockDataEngine = new Mock<ISmartComponentService>();
        _mockLogger = new Mock<ILogger<DepartmentService>>();
        _service = new DepartmentService(_mockDataEngine.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetDepartmentList_WithValidParams_ReturnsSuccess()
    {
        // Arrange
        var parameters = new Dictionary<string, object?>
        {
            { "pageNumber", 1 },
            { "pageSize", 10 }
        };

        var mockResponse = new SmartResponse
        {
            Success = true,
            Data = new List<Dictionary<string, object?>>
            {
                new() { { "id", 1 }, { "name", "Sales" } }
            }
        };

        _mockDataEngine
            .Setup(de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        // Act
        var result = await _service.GetDepartmentList(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
        
        _mockDataEngine.Verify(
            de => de.ExecuteAsync(
                It.Is<SmartRequest>(r => r.SpName == "dbo.sp_DepartmentOperations" && r.Operation == "sp"),
                It.IsAny<CancellationToken>()
            ),
            Times.Once
        );
    }

    [Fact]
    public async Task CreateDepartment_WithValidData_ReturnsSuccess()
    {
        // Arrange
        var parameters = new Dictionary<string, object?>
        {
            { "departmentName", "IT" },
            { "departmentCode", "IT001" }
        };

        var mockResponse = new SmartResponse
        {
            Success = true,
            Data = new List<Dictionary<string, object?>>
            {
                new() { { "id", 42 }, { "name", "IT" } }
            }
        };

        _mockDataEngine
            .Setup(de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        // Act
        var result = await _service.CreateDepartment(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    }
}
```

### Step 2: Run Tests

```powershell
dotnet test --filter "FullyQualifiedName~DepartmentServiceTests"
```

### Step 3: Verify Integration

1. **Build the solution:**

   ```powershell
   dotnet build
   ```

2. **Run the application:**

   ```powershell
   cd SmartFoundation.Mvc
   dotnet run
   ```

3. **Check logs** to see routing messages:
   - ✅ "Routing request to Application Layer: SP=dbo.sp_DepartmentOperations..."
   - ❌ "No service route found for SP=..." (means mapping is missing)

---

## Troubleshooting

### Issue: "No stored procedure mapping found"

**Symptom:** Exception thrown when calling service method

**Solution:** Add mapping to `ProcedureMapper._mappings`:

```csharp
{ "department:list", "dbo.sp_DepartmentOperations" }
```

### Issue: "Service not registered"

**Symptom:** `InvalidOperationException` when controller tries to use service

**Solution:** Add service to DI in `ServiceCollectionExtensions.cs`:

```csharp
services.AddScoped<DepartmentService>();
```

### Issue: "Method not found on service"

**Symptom:** Reflection error in SmartComponentController

**Solution:** Verify method name in `_operationMethodMap` matches actual method name:

```csharp
{ "list", "GetDepartmentList" }  // Must match exactly (case-sensitive)
```

### Issue: "No service route found" in logs

**Symptom:** Request falls back to DataEngine instead of using service

**Solution:** Add stored procedure to `_serviceRegistry`:

```csharp
{ "dbo.sp_DepartmentOperations", new ServiceRoute("department", typeof(Services.DepartmentService), null!, "dbo.sp_DepartmentOperations") }
```

### Issue: Tests fail with "Unsupported expression"

**Symptom:** Moq error when trying to mock service methods

**Solution:** Service methods are not virtual. Use real service instance with mocked dependencies:

```csharp
var mockDataEngine = new Mock<ISmartComponentService>();
var mockLogger = new Mock<ILogger<DepartmentService>>();
var realService = new DepartmentService(mockDataEngine.Object, mockLogger.Object);
```

---

## Best Practices

### ✅ DO

1. **Inherit from BaseService** - All services MUST inherit from BaseService (mandatory)
2. **Use ExecuteOperation** - Never call DataEngine directly
3. **Add XML documentation** - Document all public methods with /// comments
4. **Write unit tests** - Test each service method
5. **Use descriptive module names** - Lowercase, singular (e.g., "employee", "department")
6. **Return Task<string>** - All service methods return JSON strings
7. **Accept Dictionary<string, object?>** - For flexible parameter passing
8. **Log operations** - BaseService handles logging automatically
9. **Handle errors gracefully** - BaseService catches exceptions and returns error JSON
10. **Use consistent naming** - Follow {Entity}Service and {Action}{Entity} patterns

### ❌ DON'T

1. **Don't hard-code SP names** - Always use ProcedureMapper
2. **Don't call DataEngine directly** - Use BaseService.ExecuteOperation
3. **Don't make methods virtual** - Keep methods non-virtual (simpler testing)
4. **Don't put business logic in controllers** - Move to services
5. **Don't use .Result or .Wait()** - Always use async/await
6. **Don't mix naming conventions** - Be consistent across services
7. **Don't register services as Singleton** - Use Scoped lifetime
8. **Don't forget to add tests** - Every service needs unit tests
9. **Don't skip XML documentation** - Required for all public APIs
10. **Don't modify BaseService** - Extend through inheritance only

### Code Quality Checklist

Before submitting your migration:

- [ ] Service class inherits from BaseService
- [ ] All methods have XML documentation with examples
- [ ] ProcedureMapper has all required mappings
- [ ] Service registered in ServiceCollectionExtensions
- [ ] Unit tests created and passing
- [ ] Solution builds without errors
- [ ] Integration tested (manual or automated)
- [ ] Follows naming conventions
- [ ] No hard-coded stored procedure names
- [ ] Error handling delegated to BaseService

---

## Additional Resources

- [GitHub Copilot Instructions](../.github/copilot-instructions.md) - Complete architecture guide
- [Usage Examples](../.github/docs/usage.md) - More code examples
- [BaseService Implementation](../SmartFoundation.Application/Services/BaseService.cs) - Reference implementation
- [EmployeeService Example](../SmartFoundation.Application/Services/EmployeeService.cs) - Complete working example

---

## Need Help?

1. **Review EmployeeService** - It's the reference implementation
2. **Check logs** - Look for routing messages in application output
3. **Run unit tests** - Verify your service works in isolation
4. **Ask your team** - Share knowledge and learn together

---

**Last Updated:** November 6, 2025  
**Version:** 1.0  
**Author:** SmartFoundation Development Team
