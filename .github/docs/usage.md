# SmartFoundation Usage Guide

This guide provides practical examples of how to use the SmartFoundation application layers following Clean Architecture principles.

---

## Table of Contents

- [Overview](#overview)
- [Application Layer Usage](#application-layer-usage)
- [Presentation Layer Usage](#presentation-layer-usage)
- [Creating New Features](#creating-new-features)
- [Common Scenarios](#common-scenarios)
- [Best Practices](#best-practices)

---

## Overview

SmartFoundation follows a layered architecture where:

- **Presentation Layer (MVC)** handles UI and user interactions
- **Application Layer** contains business logic and orchestration
- **Data Access Layer (DataEngine)** manages database operations

**Key Rule:** Controllers call Services, Services call DataEngine, DataEngine calls Database.

---

## Application Layer Usage

### Creating a New Service

#### **Step 1: Define the Service Class**

```csharp
// filepath: SmartFoundation.Application/Services/EmployeeService.cs
using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Interfaces;
using SmartFoundation.Application.Mapping;
using System.Text.Json;

namespace SmartFoundation.Application.Services
{
    /// <summary>
    /// Service for managing employee-related operations.
    /// Handles CRUD operations and employee data retrieval.
    /// </summary>
    public class EmployeeService : BaseService
    {
        public EmployeeService(
            ISmartComponentService dataEngine,
            ILogger<EmployeeService> logger)
            : base(dataEngine, logger)
        {
        }

        /// <summary>
        /// Retrieves a paginated list of employees.
        /// </summary>
        /// <param name="parameters">
        /// Required:
        /// - pageNumber (int): Page number to retrieve (1-based)
        /// - pageSize (int): Number of records per page
        /// Optional:
        /// - searchTerm (string): Search filter for name or email
        /// </param>
        /// <returns>JSON string containing employee list and pagination info</returns>
        public async Task<string> GetEmployeeList(Dictionary<string, object> parameters)
            => await ExecuteOperation("employee", "list", parameters);

        /// <summary>
        /// Creates a new employee record.
        /// </summary>
        /// <param name="parameters">
        /// Required:
        /// - fullName (string): Employee full name
        /// - email (string): Employee email address
        /// - departmentId (int): Department identifier
        /// </param>
        /// <returns>JSON string with created employee data</returns>
        public async Task<string> CreateEmployee(Dictionary<string, object> parameters)
            => await ExecuteOperation("employee", "insert", parameters);

        /// <summary>
        /// Updates an existing employee record.
        /// </summary>
        /// <param name="parameters">
        /// Required:
        /// - employeeId (int): Employee identifier
        /// - fullName (string): Updated full name
        /// - email (string): Updated email
        /// </param>
        /// <returns>JSON string with update result</returns>
        public async Task<string> UpdateEmployee(Dictionary<string, object> parameters)
            => await ExecuteOperation("employee", "update", parameters);

        /// <summary>
        /// Deletes an employee record.
        /// </summary>
        /// <param name="parameters">
        /// Required:
        /// - employeeId (int): Employee identifier to delete
        /// </param>
        /// <returns>JSON string with deletion result</returns>
        public async Task<string> DeleteEmployee(Dictionary<string, object> parameters)
            => await ExecuteOperation("employee", "delete", parameters);
    }
}
```

#### **Step 2: Add Stored Procedure Mappings**

```csharp
// filepath: SmartFoundation.Application/Mapping/ProcedureMapper.cs
public static class ProcedureMapper
{
    private static readonly Dictionary<string, string> _mappings = new()
    {
        // Employee operations
        { "employee:list", "dbo.sp_GetEmployees" },
        { "employee:insert", "dbo.sp_InsertEmployee" },
        { "employee:update", "dbo.sp_UpdateEmployee" },
        { "employee:delete", "dbo.sp_DeleteEmployee" },

        // Add more mappings as needed
    };

    /// <summary>
    /// Gets the stored procedure name for a given module and operation.
    /// </summary>
    /// <param name="module">Module name (e.g., "employee", "department")</param>
    /// <param name="operation">Operation name (e.g., "list", "insert")</param>
    /// <returns>Stored procedure name</returns>
    /// <exception cref="InvalidOperationException">
    /// Thrown when no mapping exists for the given module and operation
    /// </exception>
    public static string GetProcedureName(string module, string operation)
    {
        var key = $"{module}:{operation}";
        if (_mappings.TryGetValue(key, out var spName))
            return spName;

        throw new InvalidOperationException(
            $"No stored procedure mapping found for '{key}'. " +
            $"Available mappings: {string.Join(", ", _mappings.Keys)}");
    }
}
```

#### **Step 3: Register Service in Dependency Injection**

```csharp
// filepath: SmartFoundation.Mvc/Program.cs
// ...existing code...

// Register Application Layer services
builder.Services.AddScoped<EmployeeService>();
builder.Services.AddScoped<DepartmentService>();
builder.Services.AddScoped<MenuService>();

// Or use extension method
builder.Services.AddApplicationServices();

// ...existing code...
```

---

## Presentation Layer Usage

### Creating a Controller

```csharp
// filepath: SmartFoundation.Mvc/Controllers/EmployeesController.cs
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using System.Text.Json;

namespace SmartFoundation.Mvc.Controllers
{
    /// <summary>
    /// Controller for managing employee-related views and operations.
    /// </summary>
    public class EmployeesController : Controller
    {
        private readonly EmployeeService _employeeService;
        private readonly ILogger<EmployeesController> _logger;

        public EmployeesController(
            EmployeeService employeeService,
            ILogger<EmployeesController> logger)
        {
            _employeeService = employeeService;
            _logger = logger;
        }

        /// <summary>
        /// Displays the employee list page with pagination.
        /// </summary>
        /// <param name="pageNumber">Current page number (default: 1)</param>
        /// <param name="pageSize">Records per page (default: 10)</param>
        /// <param name="searchTerm">Optional search filter</param>
        /// <returns>Employee list view</returns>
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 10,
            string? searchTerm = null)
        {
            try
            {
                // Validate input
                if (pageNumber < 1) pageNumber = 1;
                if (pageSize < 1 || pageSize > 100) pageSize = 10;

                // Sanitize search term
                searchTerm = searchTerm?.Trim();
                if (searchTerm?.Length > 100)
                    searchTerm = searchTerm.Substring(0, 100);

                // Prepare parameters
                var parameters = new Dictionary<string, object>
                {
                    { "pageNumber", pageNumber },
                    { "pageSize", pageSize }
                };

                if (!string.IsNullOrEmpty(searchTerm))
                    parameters.Add("searchTerm", searchTerm);

                // Call service
                var jsonResult = await _employeeService.GetEmployeeList(parameters);

                // Pass to view
                ViewBag.EmployeeData = jsonResult;
                ViewBag.CurrentPage = pageNumber;
                ViewBag.PageSize = pageSize;
                ViewBag.SearchTerm = searchTerm;

                return View();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading employee list");
                TempData["Error"] = "Failed to load employee list. Please try again.";
                return View("Error");
            }
        }

        /// <summary>
        /// Displays the create employee form.
        /// </summary>
        /// <returns>Create employee view</returns>
        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }

        /// <summary>
        /// Handles employee creation form submission.
        /// </summary>
        /// <param name="fullName">Employee full name</param>
        /// <param name="email">Employee email</param>
        /// <param name="departmentId">Department ID</param>
        /// <returns>Redirect to Index on success, or back to form on error</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            string fullName,
            string email,
            int departmentId)
        {
            try
            {
                // Validate input
                if (string.IsNullOrWhiteSpace(fullName))
                {
                    ModelState.AddModelError("fullName", "Full name is required");
                    return View();
                }

                if (string.IsNullOrWhiteSpace(email))
                {
                    ModelState.AddModelError("email", "Email is required");
                    return View();
                }

                // Prepare parameters
                var parameters = new Dictionary<string, object>
                {
                    { "fullName", fullName.Trim() },
                    { "email", email.Trim() },
                    { "departmentId", departmentId }
                };

                // Call service
                var jsonResult = await _employeeService.CreateEmployee(parameters);

                // Parse result
                var result = JsonSerializer.Deserialize<JsonElement>(jsonResult);
                var success = result.GetProperty("success").GetBoolean();

                if (success)
                {
                    TempData["Success"] = "Employee created successfully";
                    return RedirectToAction(nameof(Index));
                }
                else
                {
                    var message = result.GetProperty("message").GetString();
                    ModelState.AddModelError("", message ?? "Failed to create employee");
                    return View();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating employee");
                ModelState.AddModelError("", "An error occurred while creating the employee");
                return View();
            }
        }

        /// <summary>
        /// Handles employee deletion.
        /// </summary>
        /// <param name="id">Employee ID to delete</param>
        /// <returns>JSON result indicating success or failure</returns>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var parameters = new Dictionary<string, object>
                {
                    { "employeeId", id }
                };

                var jsonResult = await _employeeService.DeleteEmployee(parameters);
                var result = JsonSerializer.Deserialize<JsonElement>(jsonResult);

                return Json(new
                {
                    success = result.GetProperty("success").GetBoolean(),
                    message = result.GetProperty("message").GetString()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting employee {EmployeeId}", id);
                return Json(new
                {
                    success = false,
                    message = "Failed to delete employee"
                });
            }
        }
    }
}
```

---

## Creating New Features

### Example: Adding Department Management

#### **Step 1: Add Stored Procedure Mappings**

```csharp
// filepath: SmartFoundation.Application/Mapping/ProcedureMapper.cs
private static readonly Dictionary<string, string> _mappings = new()
{
    // ...existing mappings...

    // Department operations
    { "department:list", "dbo.sp_GetDepartments" },
    { "department:insert", "dbo.sp_InsertDepartment" },
    { "department:update", "dbo.sp_UpdateDepartment" },
    { "department:delete", "dbo.sp_DeleteDepartment" },
    { "department:details", "dbo.sp_GetDepartmentDetails" }
};
```

#### **Step 2: Create DepartmentService**

```csharp
// filepath: SmartFoundation.Application/Services/DepartmentService.cs
namespace SmartFoundation.Application.Services
{
    /// <summary>
    /// Service for managing department operations.
    /// </summary>
    public class DepartmentService : BaseService
    {
        public DepartmentService(
            ISmartComponentService dataEngine,
            ILogger<DepartmentService> logger)
            : base(dataEngine, logger)
        {
        }

        /// <summary>
        /// Gets list of all departments.
        /// </summary>
        /// <param name="parameters">Optional search parameters</param>
        /// <returns>JSON string with department list</returns>
        public async Task<string> GetDepartmentList(Dictionary<string, object> parameters)
            => await ExecuteOperation("department", "list", parameters);

        /// <summary>
        /// Creates a new department.
        /// </summary>
        /// <param name="parameters">
        /// Required: departmentName (string), managerId (int)
        /// </param>
        /// <returns>JSON string with creation result</returns>
        public async Task<string> CreateDepartment(Dictionary<string, object> parameters)
            => await ExecuteOperation("department", "insert", parameters);
    }
}
```

#### **Step 3: Register Service**

```csharp
// filepath: SmartFoundation.Mvc/Program.cs
builder.Services.AddScoped<DepartmentService>();
```

#### **Step 4: Create Controller**

```csharp
// filepath: SmartFoundation.Mvc/Controllers/DepartmentsController.cs
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

    public async Task<IActionResult> Index()
    {
        try
        {
            var parameters = new Dictionary<string, object>();
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

## Common Scenarios

### Scenario 1: CRUD Operations with Validation

```csharp
// In Controller
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> Update(int id, string name, string email)
{
    // Step 1: Validate input
    if (id <= 0)
    {
        ModelState.AddModelError("id", "Invalid ID");
        return View();
    }

    if (string.IsNullOrWhiteSpace(name))
    {
        ModelState.AddModelError("name", "Name is required");
        return View();
    }

    if (string.IsNullOrWhiteSpace(email) || !IsValidEmail(email))
    {
        ModelState.AddModelError("email", "Valid email is required");
        return View();
    }

    // Step 2: Prepare parameters
    var parameters = new Dictionary<string, object>
    {
        { "id", id },
        { "name", name.Trim() },
        { "email", email.Trim().ToLower() }
    };

    // Step 3: Call service
    var result = await _service.UpdateRecord(parameters);

    // Step 4: Handle response
    var response = JsonSerializer.Deserialize<JsonElement>(result);
    if (response.GetProperty("success").GetBoolean())
    {
        TempData["Success"] = "Record updated successfully";
        return RedirectToAction(nameof(Index));
    }

    ModelState.AddModelError("", response.GetProperty("message").GetString());
    return View();
}

private bool IsValidEmail(string email)
{
    try
    {
        var addr = new System.Net.Mail.MailAddress(email);
        return addr.Address == email;
    }
    catch
    {
        return false;
    }
}
```

### Scenario 2: Working with Session Data

```csharp
// In Controller
public async Task<IActionResult> MyProfile()
{
    try
    {
        // Extract user ID from session
        var userIdString = HttpContext.Session.GetString("UserId");
        if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
        {
            return RedirectToAction("Login", "Account");
        }

        // Prepare parameters
        var parameters = new Dictionary<string, object>
        {
            { "userId", userId }
        };

        // Call service
        var jsonResult = await _userService.GetUserProfile(parameters);

        ViewBag.UserData = jsonResult;
        return View();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error loading user profile");
        return View("Error");
    }
}
```

### Scenario 3: Complex Data Aggregation

```csharp
// In Service
/// <summary>
/// Gets dashboard summary with multiple data sources.
/// Orchestrates multiple stored procedure calls.
/// </summary>
public async Task<string> GetDashboardSummary(Dictionary<string, object> parameters)
{
    _logger.LogInformation("GetDashboardSummary called");

    try
    {
        // Execute multiple operations in parallel
        var tasks = new[]
        {
            ExecuteOperation("dashboard", "employee-count", parameters),
            ExecuteOperation("dashboard", "department-count", parameters),
            ExecuteOperation("dashboard", "recent-activity", parameters)
        };

        var results = await Task.WhenAll(tasks);

        // Parse individual results
        var employeeCount = JsonSerializer.Deserialize<JsonElement>(results[0]);
        var departmentCount = JsonSerializer.Deserialize<JsonElement>(results[1]);
        var recentActivity = JsonSerializer.Deserialize<JsonElement>(results[2]);

        // Combine results
        var summary = new
        {
            success = true,
            data = new
            {
                employees = employeeCount.GetProperty("data"),
                departments = departmentCount.GetProperty("data"),
                activity = recentActivity.GetProperty("data")
            },
            message = "Dashboard loaded successfully"
        };

        return JsonSerializer.Serialize(summary);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in GetDashboardSummary");
        return JsonSerializer.Serialize(new
        {
            success = false,
            data = (object?)null,
            message = $"Error loading dashboard: {ex.Message}"
        });
    }
}
```

### Scenario 4: File Upload with Data

```csharp
// In Controller
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> UploadEmployeePhoto(int employeeId, IFormFile photo)
{
    try
    {
        // Validate file
        if (photo == null || photo.Length == 0)
        {
            ModelState.AddModelError("photo", "Please select a photo");
            return View();
        }

        // Validate file size (max 5MB)
        if (photo.Length > 5 * 1024 * 1024)
        {
            ModelState.AddModelError("photo", "File size must not exceed 5MB");
            return View();
        }

        // Validate file type
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
        var extension = Path.GetExtension(photo.FileName).ToLower();
        if (!allowedExtensions.Contains(extension))
        {
            ModelState.AddModelError("photo", "Only JPG and PNG files are allowed");
            return View();
        }

        // Read file to byte array
        byte[] photoData;
        using (var memoryStream = new MemoryStream())
        {
            await photo.CopyToAsync(memoryStream);
            photoData = memoryStream.ToArray();
        }

        // Prepare parameters
        var parameters = new Dictionary<string, object>
        {
            { "employeeId", employeeId },
            { "photoData", Convert.ToBase64String(photoData) },
            { "fileName", photo.FileName }
        };

        // Call service
        var result = await _employeeService.UpdateEmployeePhoto(parameters);

        var response = JsonSerializer.Deserialize<JsonElement>(result);
        if (response.GetProperty("success").GetBoolean())
        {
            TempData["Success"] = "Photo uploaded successfully";
            return RedirectToAction("Details", new { id = employeeId });
        }

        ModelState.AddModelError("", response.GetProperty("message").GetString());
        return View();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error uploading photo for employee {EmployeeId}", employeeId);
        ModelState.AddModelError("", "Failed to upload photo");
        return View();
    }
}
```

---

## Best Practices

### DO ✅

- **Always inject services in controllers**

  ```csharp
  public EmployeesController(EmployeeService employeeService)
  {
      _employeeService = employeeService;
  }
  ```

- **Validate input in controllers before calling services**

  ```csharp
  if (pageNumber < 1) pageNumber = 1;
  if (string.IsNullOrWhiteSpace(name))
  {
      ModelState.AddModelError("name", "Name is required");
      return View();
  }
  ```

- **Use ProcedureMapper for all stored procedure names**

  ```csharp
  var spName = ProcedureMapper.GetProcedureName("employee", "list");
  ```

- **Return structured JSON from services**

  ```csharp
  return JsonSerializer.Serialize(new
  {
      success = true,
      data = employeeData,
      message = "Success"
  });
  ```

- **Log operations and errors**

  ```csharp
  _logger.LogInformation("GetEmployeeList called with {Params}", parameters);
  _logger.LogError(ex, "Error in GetEmployeeList");
  ```

- **Use async/await for all I/O operations**

  ```csharp
  public async Task<IActionResult> Index()
  {
      var data = await _service.GetData(parameters);
      return View();
  }
  ```

### DON'T ❌

- **Don't hard-code stored procedure names**

  ```csharp
  // ❌ BAD
  var spName = "dbo.sp_GetEmployees";

  // ✅ GOOD
  var spName = ProcedureMapper.GetProcedureName("employee", "list");
  ```

- **Don't call DataEngine directly from controllers**

  ```csharp
  // ❌ BAD
  public EmployeesController(ISmartComponentService dataEngine)
  {
      _dataEngine = dataEngine;
  }

  // ✅ GOOD
  public EmployeesController(EmployeeService employeeService)
  {
      _employeeService = employeeService;
  }
  ```

- **Don't put business logic in controllers**

  ```csharp
  // ❌ BAD - Complex calculation in controller
  var salary = baseSalary + (baseSalary * bonusPercentage / 100);

  // ✅ GOOD - Move to service
  var result = await _employeeService.CalculateSalary(parameters);
  ```

- **Don't use .Result or .Wait() with async methods**

  ```csharp
  // ❌ BAD - Can cause deadlocks
  var result = _service.GetData(parameters).Result;

  // ✅ GOOD
  var result = await _service.GetData(parameters);
  ```

- **Don't ignore exceptions**

  ```csharp
  // ❌ BAD
  try
  {
      var data = await _service.GetData(parameters);
  }
  catch { } // Silent failure

  // ✅ GOOD
  try
  {
      var data = await _service.GetData(parameters);
  }
  catch (Exception ex)
  {
      _logger.LogError(ex, "Error getting data");
      return View("Error");
  }
  ```

---

## Additional Resources

- [Architecture Diagram](./architecture.md)
- [API Documentation](./api.md)
- [Testing Guide](./testing.md)
- [Deployment Guide](./deployment.md)

---

**Last Updated:** December 2024  
**Version:** 1.0
