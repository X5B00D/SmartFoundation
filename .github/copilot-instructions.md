# GitHub Copilot Instructions - SmartFoundation Project

## Project Overview

SmartFoundation is a multi-layered ASP.NET Core 8.0 application following Clean Architecture principles. The project isolates business logic from presentation and data access concerns, ensuring maintainability, testability, and team independence.

---

## MCP Tools Usage

### Context7 MCP - Documentation Lookup

**When to use:**

- ✅ **ALWAYS** use Context7 MCP (`mcp_context7_resolve-library-id` and `mcp_context7_get-library-docs`) when needing to look up documentation for any library, framework, or package
- Use for ASP.NET Core, Entity Framework, .NET libraries, npm packages, or any third-party dependencies
- Provides up-to-date, accurate documentation directly from official sources

**Fallback:**

- ❌ If Context7 MCP is not running or encounters errors, fall back to default documentation approaches
- Log the issue and continue with alternative methods

**Example usage:**

```
User asks: "How do I use dependency injection in ASP.NET Core?"
→ Use Context7 MCP to fetch latest ASP.NET Core DI documentation
```

### TaskMaster AI MCP - Task Management

**When to use:**

- ✅ **ALWAYS** use TaskMaster AI MCP tools when user asks about tasks, task status, or project planning
- Use `mcp_task-master-a_get_tasks` to retrieve task lists
- Use `mcp_task-master-a_get_task` for specific task details
- Use `mcp_task-master-a_set_task_status` to update task progress
- Use other TaskMaster tools for task creation, expansion, and management when applicable

**When NOT to use:**

- Simple TODO tracking within a conversation (use manage_todo_list instead)
- When TaskMaster is not initialized in the project

**Example usage:**

```
User asks: "What tasks are pending?"
→ Use mcp_task-master-a_get_tasks with status filter
```

---

## Architecture Layers

### 1. Presentation Layer (`SmartFoundation.Mvc`)

**Purpose:** User interface and request handling

**Responsibilities:**

- Render views and handle HTTP requests/responses
- Validate user input at the edge
- Extract session data and prepare parameters
- Call Application Layer services (never DataEngine directly)
- Pass data to views for rendering
- Handle authentication and authorization

**Rules:**

- ❌ NO hard-coded stored procedure names
- ❌ NO direct calls to `ISmartComponentService`
- ❌ NO business logic in controllers
- ✅ Inject Application Layer services only
- ✅ Keep controllers thin (orchestration only)
- ✅ Validate user input before passing to services
- ✅ Use `async/await` for all service calls

**Example:**

```csharp
public class EmployeesController : Controller
{
    private readonly EmployeeService _employeeService;

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

---

### 2. Application Layer (`SmartFoundation.Application`)

**Purpose:** Business logic and orchestration between presentation and data access

**Responsibilities:**

- Implement business operations as service methods
- Use `ProcedureMapper` to translate operations to stored procedure names
- Orchestrate multiple stored procedure calls when needed
- Handle errors gracefully and return structured responses
- Serialize data to JSON for presentation layer
- Provide clear method signatures with documented parameters
- Log operations for debugging and auditing

**Structure:**

```
SmartFoundation.Application/
├── Services/               # Business service classes
│   ├── EmployeeService.cs
│   ├── MenuService.cs
│   └── DashboardService.cs
├── Mapping/
│   └── ProcedureMapper.cs  # SP name mapping (centralized)
└── Extensions/
    └── ServiceCollectionExtensions.cs  # DI setup
```

**Rules:**

- ❌ NO hard-coded stored procedure names (use ProcedureMapper)
- ❌ NO direct database access (use DataEngine)
- ❌ NO HttpContext or session access (accept parameters)
- ✅ All service methods must be async
- ✅ Return JSON strings or serializable objects
- ✅ Handle errors with try-catch and return structured responses
- ✅ Document expected parameters with XML comments
- ✅ Inject `ISmartComponentService` for data access
- ✅ Inject `ILogger<TService>` for logging

**Service Method Pattern:**

```csharp
/// <summary>
/// Gets list of employees with pagination.
/// </summary>
/// <param name="parameters">
/// Required: pageNumber (int), pageSize (int)
/// Optional: searchTerm (string)
/// </param>
/// <returns>JSON string containing employee data</returns>
public async Task<string> GetEmployeeList(Dictionary<string, object> parameters)
{
    _logger.LogInformation("GetEmployeeList called with {Params}", parameters);

    try
    {
        // Get SP name from mapper
        var spName = ProcedureMapper.GetProcedureName("employee", "list");

        // Create request
        var request = new SmartRequest
        {
            Operation = "sp",
            SpName = spName,
            Params = parameters
        };

        // Call DataEngine
        var response = await _dataEngine.ExecuteAsync(request);

        // Return structured JSON
        return JsonSerializer.Serialize(new
        {
            success = response.Success,
            data = response.Data,
            message = response.Message ?? (response.Success ? "Success" : "Error")
        });
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in GetEmployeeList");
        return JsonSerializer.Serialize(new
        {
            success = false,
            data = (object?)null,
            message = $"Error: {ex.Message}"
        });
    }
}
```

**ProcedureMapper Pattern:**

```csharp
public static class ProcedureMapper
{
    private static readonly Dictionary<string, string> _mappings = new()
    {
        // Format: "module:operation" => "stored_procedure_name"
        { "employee:list", "dbo.sp_GetEmployees" },
        { "employee:insert", "dbo.sp_InsertEmployee" },
        { "employee:update", "dbo.sp_UpdateEmployee" },
        { "menu:list", "dbo.ListOfMenuByUser_MVC" },
        { "dashboard:summary", "dbo.sp_GetDashboardSummary" }
    };

    /// <summary>
    /// Gets the stored procedure name for a given module and operation.
    /// </summary>
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

**When to Create New Service:**

- Group related operations by domain/module (e.g., EmployeeService, OrderService)
- One service per major business entity
- Keep services focused and cohesive

**Orchestration Example (Multiple SPs):**

```csharp
public async Task<object> GetEmployeeDashboard(string employeeId)
{
    // Call multiple procedures and combine results
    var employeeInfo = await GetEmployeeDetails(employeeId);
    var employeeStats = await GetEmployeeStats(employeeId);
    var recentActivity = await GetRecentActivity(employeeId);

    // Combine and return
    return new
    {
        employee = employeeInfo,
        statistics = employeeStats,
        activity = recentActivity
    };
}
```

---

### 3. Data Access Layer (`SmartFoundation.DataEngine`)

**Purpose:** Database interaction and stored procedure execution

**Responsibilities:**

- Execute stored procedures via `SmartComponentService`
- Manage database connections
- Handle SQL errors and return structured responses
- Use parameterized queries (prevent SQL injection)
- Return data as `SmartResponse` objects

**Rules:**

- ✅ Only Application Layer calls DataEngine
- ✅ Use `SmartRequest` and `SmartResponse` objects
- ✅ Handle database errors gracefully
- ❌ NO business logic here (data access only)
- ❌ Controllers should NEVER call DataEngine directly

**Note:** This layer is stable and should not require changes for Application Layer implementation.

---

### 4. UI Components Layer (`SmartFoundation.UI`)

**Purpose:** Reusable view components and view models

**Responsibilities:**

- Provide reusable UI components (SmartTable, SmartForm)
- Define view models for complex views
- Handle client-side rendering logic

**Rules:**

- ✅ Keep components generic and reusable
- ✅ Accept configuration objects (TableConfig, FormConfig)
- ❌ NO business logic in view components
- ✅ Use ViewComponents for shared UI elements

---

## Clean Architecture Principles

### Dependency Rule

**Dependencies point inward:**

```
Presentation → Application → DataEngine → Database
```

- Outer layers depend on inner layers
- Inner layers know nothing about outer layers
- Application Layer is independent of MVC
- DataEngine is independent of Application Layer

### Separation of Concerns

- **Presentation:** UI and user interaction
- **Application:** Business logic and orchestration
- **Data Access:** Database operations only
- **Database:** Data storage

### Benefits

- ✅ Testability: Each layer can be tested independently
- ✅ Maintainability: Changes isolated to specific layers
- ✅ Flexibility: Easy to swap implementations
- ✅ Team Independence: Teams work on different layers simultaneously

---

## Code Style & Standards

### Naming Conventions

**Classes:**

- Services: `{Entity}Service` (e.g., `EmployeeService`)
- Controllers: `{Entity}Controller` (e.g., `EmployeesController`)
- ViewComponents: `{Name}ViewComponent` (e.g., `MenuItemsViewComponent`)

**Methods:**

- Use descriptive verb+noun: `GetEmployeeList`, `CreateEmployee`, `UpdateEmployeeStatus`
- Async methods: Suffix with `Async` if needed for clarity
- Return types: `Task<string>` for JSON, `Task<object>` for complex objects

**Parameters:**

- Use `Dictionary<string, object>` for dynamic parameters
- Validate in controllers, not services
- Document required vs optional parameters

**Variables:**

- camelCase for local variables: `employeeData`, `spName`
- PascalCase for properties: `Success`, `Data`
- Descriptive names: `pageNumber` not `pn`

### Error Handling

**In Controllers:**

```csharp
public async Task<IActionResult> Index()
{
    try
    {
        var data = await _service.GetData(params);
        return View();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error loading page");
        return View("Error");
    }
}
```

**In Services:**

```csharp
public async Task<string> GetData(Dictionary<string, object> parameters)
{
    try
    {
        // Business logic
        var response = await _dataEngine.ExecuteAsync(request);

        return JsonSerializer.Serialize(new
        {
            success = response.Success,
            data = response.Data,
            message = response.Message
        });
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in GetData");
        return JsonSerializer.Serialize(new
        {
            success = false,
            data = (object?)null,
            message = $"Error: {ex.Message}"
        });
    }
}
```

### Async/Await Best Practices

- ✅ Use `async/await` for all I/O operations
- ✅ Don't use `.Result` or `.Wait()` (causes deadlocks)
- ✅ Use `Task.WhenAll()` for parallel operations
- ✅ Use `CancellationToken` for long-running operations

### Logging

**Log Levels:**

- `LogInformation`: Normal operations
- `LogWarning`: Unexpected but handled situations
- `LogError`: Errors and exceptions
- `LogDebug`: Detailed debugging information

**Example:**

```csharp
_logger.LogInformation("Processing {Operation} for {Entity}", operation, entityId);
_logger.LogWarning("Invalid parameter: {ParamName}", paramName);
_logger.LogError(ex, "Failed to execute {Operation}", operation);
```

---

## Documentation Standards

### XML Documentation (REQUIRED)

**All public classes, methods, and properties must have XML comments.**

**Class Documentation:**

```csharp
/// <summary>
/// Service for managing employee-related operations.
/// Handles CRUD operations, reporting, and employee data retrieval.
/// </summary>
public class EmployeeService
{
    // Implementation
}
```

**Method Documentation:**

```csharp
/// <summary>
/// Retrieves a paginated list of employees with optional search filtering.
/// </summary>
/// <param name="parameters">
/// Dictionary containing request parameters:
/// - pageNumber (int, required): Page number to retrieve (1-based)
/// - pageSize (int, required): Number of records per page (1-100)
/// - searchTerm (string, optional): Text to search in name, email, or phone
/// </param>
/// <returns>
/// JSON string containing:
/// - success (bool): Whether the operation succeeded
/// - data (array): List of employee objects
/// - message (string): Success or error message
/// </returns>
/// <exception cref="InvalidOperationException">
/// Thrown when the stored procedure mapping is not found
/// </exception>
/// <example>
/// <code>
/// var parameters = new Dictionary&lt;string, object&gt;
/// {
///     { "pageNumber", 1 },
///     { "pageSize", 10 },
///     { "searchTerm", "john" }
/// };
/// var result = await _employeeService.GetEmployeeList(parameters);
/// </code>
/// </example>
public async Task<string> GetEmployeeList(Dictionary<string, object> parameters)
{
    // Implementation
}
```

**Property Documentation:**

```csharp
/// <summary>
/// Gets or sets the employee's full name.
/// Maximum length: 100 characters.
/// </summary>
public string FullName { get; set; }
```

### Code Comments

**When to comment:**

- Complex business logic
- Non-obvious algorithmic decisions
- Workarounds for known issues
- TODO items for future improvements

**When NOT to comment:**

- Self-explanatory code
- Restating what the code does

**Good Comment:**

```csharp
// Parse Hijri date mirror if calendar is set to 'both'
// This allows users to input Gregorian and see Hijri equivalent
if (calendar == "both" && !string.IsNullOrEmpty(mirrorName))
{
    // Parse logic
}
```

**Bad Comment:**

```csharp
// Increment i by 1
i++;
```

### README Files

**Each major component should have a README:**

```markdown
# SmartFoundation.Application

## Overview

Business logic layer providing services for data operations.

## Services

- **EmployeeService**: Employee CRUD operations
- **MenuService**: User menu retrieval
- **DashboardService**: Dashboard data aggregation

## Usage

See [Usage Examples](docs/usage.md)

## Architecture

See [Architecture Diagram](docs/architecture.md)
```

---

## Dependency Injection

### Registration Pattern

**In Program.cs:**

```csharp
// DataEngine services
builder.Services.AddScoped<ISmartComponentService, SmartComponentService>();

// Application Layer services
builder.Services.AddScoped<EmployeeService>();
builder.Services.AddScoped<MenuService>();
builder.Services.AddScoped<DashboardService>();

// Or use extension method
builder.Services.AddApplicationServices();
```

**Extension Method Pattern:**

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<EmployeeService>();
        services.AddScoped<MenuService>();
        services.AddScoped<DashboardService>();
        // Add more services here

        return services;
    }
}
```

### Service Lifetimes

- **Scoped** (recommended for Application Layer): One instance per HTTP request
- **Transient**: New instance every time (avoid for performance)
- **Singleton**: One instance for app lifetime (use for stateless services only)

---

## Testing Standards

### Unit Tests

**Test Structure:**

```csharp
public class EmployeeServiceTests
{
    [Fact]
    public async Task GetEmployeeList_WithValidParams_ReturnsSuccess()
    {
        // Arrange
        var mockDataEngine = new Mock<ISmartComponentService>();
        mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>()
            });

        var service = new EmployeeService(mockDataEngine.Object);
        var parameters = new Dictionary<string, object>
        {
            { "pageNumber", 1 },
            { "pageSize", 10 }
        };

        // Act
        var result = await service.GetEmployeeList(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonSerializer.Deserialize<JsonElement>(result);
        Assert.True(json.GetProperty("success").GetBoolean());
    }
}
```

**Test Coverage Target:** ≥80% for Application Layer

**What to Test:**

- ✅ Happy path scenarios
- ✅ Error handling
- ✅ Edge cases
- ✅ Parameter validation
- ✅ ProcedureMapper lookups

---

## Security Best Practices

### Input Validation

```csharp
// Validate in controllers
public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10, string? search = null)
{
    // Validate ranges
    if (pageNumber < 1) pageNumber = 1;
    if (pageSize < 1 || pageSize > 100) pageSize = 10;

    // Sanitize strings
    search = search?.Trim();
    if (search?.Length > 100) search = search.Substring(0, 100);

    // Then call service
}
```

### SQL Injection Prevention

- ✅ Always use parameterized queries (DataEngine handles this)
- ❌ Never concatenate user input into SQL strings
- ✅ Validate input types and ranges

### Logging Security

```csharp
// ✅ GOOD: Don't log sensitive data
_logger.LogInformation("User {UserId} logged in", userId);

// ❌ BAD: Don't log passwords, tokens, etc.
_logger.LogInformation("Password: {Password}", password);
```

---

## Performance Guidelines

### Async Operations

```csharp
// ✅ GOOD: Parallel execution when possible
var tasks = new[]
{
    _service.GetEmployeeData(id),
    _service.GetEmployeeStats(id),
    _service.GetRecentActivity(id)
};
var results = await Task.WhenAll(tasks);

// ❌ BAD: Sequential when not necessary
var data = await _service.GetEmployeeData(id);
var stats = await _service.GetEmployeeStats(id);
var activity = await _service.GetRecentActivity(id);
```

### Caching (Future Consideration)

- Consider caching frequently accessed data
- Use distributed cache for scalability
- Implement cache invalidation strategy

### JSON Serialization

```csharp
// Use System.Text.Json (fast)
return JsonSerializer.Serialize(data, new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
});
```

---

## Code Reusability

### DRY Principle (Don't Repeat Yourself)

**Extract common logic:**

```csharp
// ❌ BAD: Repeated code
public async Task<string> GetEmployees(Dictionary<string, object> parameters)
{
    var spName = ProcedureMapper.GetProcedureName("employee", "list");
    var request = new SmartRequest { Operation = "sp", SpName = spName, Params = parameters };
    var response = await _dataEngine.ExecuteAsync(request);
    return JsonSerializer.Serialize(new { success = response.Success, data = response.Data });
}

public async Task<string> GetDepartments(Dictionary<string, object> parameters)
{
    var spName = ProcedureMapper.GetProcedureName("department", "list");
    var request = new SmartRequest { Operation = "sp", SpName = spName, Params = parameters };
    var response = await _dataEngine.ExecuteAsync(request);
    return JsonSerializer.Serialize(new { success = response.Success, data = response.Data });
}

// ✅ GOOD: Extract to base method
protected async Task<string> ExecuteOperation(string module, string operation, Dictionary<string, object> parameters)
{
    try
    {
        var spName = ProcedureMapper.GetProcedureName(module, operation);
        var request = new SmartRequest
        {
            Operation = "sp",
            SpName = spName,
            Params = parameters
        };

        var response = await _dataEngine.ExecuteAsync(request);

        return JsonSerializer.Serialize(new
        {
            success = response.Success,
            data = response.Data,
            message = response.Message
        });
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in {Module}:{Operation}", module, operation);
        return JsonSerializer.Serialize(new
        {
            success = false,
            data = (object?)null,
            message = $"Error: {ex.Message}"
        });
    }
}

// Now services are simple
public async Task<string> GetEmployees(Dictionary<string, object> parameters)
    => await ExecuteOperation("employee", "list", parameters);

public async Task<string> GetDepartments(Dictionary<string, object> parameters)
    => await ExecuteOperation("department", "list", parameters);
```

### Extension Methods

```csharp
public static class DictionaryExtensions
{
    public static T GetValue<T>(this Dictionary<string, object> dict, string key, T defaultValue = default)
    {
        if (dict.TryGetValue(key, out var value) && value is T typedValue)
            return typedValue;
        return defaultValue;
    }
}

// Usage
var pageNumber = parameters.GetValue("pageNumber", 1);
var pageSize = parameters.GetValue("pageSize", 10);
```

### Service Base Class (MANDATORY)

⚠️ **ALL service classes MUST inherit from BaseService - this is not optional!**

**Why Mandatory:**

- Ensures consistent error handling across all services
- Eliminates code duplication (DRY principle)
- Standardizes logging for all operations
- Makes maintenance easier (update one place, affects all services)
- Enforces team coding standards

```csharp
/// <summary>
/// Base class for all Application Layer services.
/// ALL services MUST inherit from this class.
/// </summary>
public abstract class BaseService
{
    protected readonly ISmartComponentService _dataEngine;
    protected readonly ILogger _logger;

    protected BaseService(ISmartComponentService dataEngine, ILogger logger)
    {
        _dataEngine = dataEngine;
        _logger = logger;
    }

    /// <summary>
    /// Executes a stored procedure operation with standardized error handling.
    /// </summary>
    protected async Task<string> ExecuteOperation(
        string module,
        string operation,
        Dictionary<string, object> parameters)
    {
        _logger.LogInformation("{Module}:{Operation} called", module, operation);

        try
        {
            var spName = ProcedureMapper.GetProcedureName(module, operation);
            var request = new SmartRequest
            {
                Operation = "sp",
                SpName = spName,
                Params = parameters
            };

            var response = await _dataEngine.ExecuteAsync(request);

            return JsonSerializer.Serialize(new
            {
                success = response.Success,
                data = response.Data,
                message = response.Message ?? (response.Success ? "Success" : "Error")
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in {Module}:{Operation}", module, operation);
            return JsonSerializer.Serialize(new
            {
                success = false,
                data = (object?)null,
                message = $"Error: {ex.Message}"
            });
        }
    }
}

// ✅ CORRECT: All services must inherit from BaseService
public class EmployeeService : BaseService
{
    public EmployeeService(ISmartComponentService dataEngine, ILogger<EmployeeService> logger)
        : base(dataEngine, logger)
    {
    }

    // Use inherited ExecuteOperation method
    public async Task<string> GetEmployeeList(Dictionary<string, object> parameters)
        => await ExecuteOperation("employee", "list", parameters);
}
```

**Code Review Rule:** ❌ REJECT any service that doesn't inherit from BaseService

---

## Common Patterns & Examples

### Standard Service Method Template

```csharp
/// <summary>
/// [Description of what this method does]
/// </summary>
/// <param name="parameters">
/// Required: [list required params]
/// Optional: [list optional params]
/// </param>
/// <returns>JSON string with structured response</returns>
public async Task<string> MethodName(Dictionary<string, object> parameters)
{
    _logger.LogInformation("MethodName called with {Params}", parameters);

    try
    {
        var spName = ProcedureMapper.GetProcedureName("module", "operation");

        var request = new SmartRequest
        {
            Operation = "sp",
            SpName = spName,
            Params = parameters
        };

        var response = await _dataEngine.ExecuteAsync(request);

        return JsonSerializer.Serialize(new
        {
            success = response.Success,
            data = response.Data,
            message = response.Message ?? (response.Success ? "Success" : "Error")
        });
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in MethodName");
        return JsonSerializer.Serialize(new
        {
            success = false,
            data = (object?)null,
            message = $"Error: {ex.Message}"
        });
    }
}
```

### Standard Controller Method Template

```csharp
/// <summary>
/// [Description of controller action]
/// </summary>
public async Task<IActionResult> ActionName(/* parameters */)
{
    try
    {
        // 1. Validate input
        // 2. Extract session data if needed
        // 3. Prepare parameters
        var parameters = new Dictionary<string, object>
        {
            { "key", value }
        };

        // 4. Call service
        var data = await _service.MethodName(parameters);

        // 5. Pass to view
        ViewBag.Data = data;
        return View();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error in ActionName");
        return View("Error");
    }
}
```

---

## Migration Checklist (For Existing Controllers)

When migrating a controller to use Application Layer:

- [ ] Identify all stored procedure names in controller
- [ ] Add mappings to `ProcedureMapper` for each SP
- [ ] Create or update service in Application Layer
- [ ] Implement service methods for each operation
- [ ] Add XML documentation to service methods
- [ ] Write unit tests for service methods
- [ ] Update controller to inject service
- [ ] Replace direct DataEngine calls with service calls
- [ ] Remove hard-coded SP names from controller
- [ ] Test functionality end-to-end
- [ ] Remove old code (keep in comments initially)
- [ ] Update any related views if needed
- [ ] Code review
- [ ] Deploy and monitor

---

## Git Commit Messages

**Format:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(application): Add EmployeeService with CRUD operations

Implemented complete EmployeeService for managing employee data.
Includes GetEmployeeList, CreateEmployee, UpdateEmployee, DeleteEmployee methods.
All methods use ProcedureMapper for SP name resolution.

Closes #123
```

```
refactor(mvc): Migrate EmployeesController to use Application Layer

Removed direct DataEngine dependency from EmployeesController.
Now uses EmployeeService for all data operations.
Removed hard-coded stored procedure names.

Related to #124
```

---

## Quick Reference Commands

### Create New Service

```bash
# 1. Create service file
dotnet new class -n EmployeeService -o SmartFoundation.Application/Services

# 2. Add mappings to ProcedureMapper
# 3. Implement service methods
# 4. Register in Program.cs
# 5. Write tests
```

### Run Tests

```bash
dotnet test --filter "FullyQualifiedName~EmployeeServiceTests"
```

### Build Solution

```bash
dotnet build SmartFoundation.sln
```

### Run Application

```bash
cd SmartFoundation.Mvc
dotnet run
```

---

## Important Reminders

1. **Always use ProcedureMapper** - Never hard-code SP names
2. **Document everything** - XML comments are mandatory
3. **Log operations** - Use ILogger for debugging
4. **Handle errors gracefully** - Try-catch and return structured errors
5. **Test your code** - Write unit tests for all services
6. **Validate input** - Controllers validate, services trust
7. **Keep it simple** - Don't over-engineer
8. **Ask for help** - If stuck, consult the team
9. **Code review** - All changes reviewed before merge
10. **Follow standards** - Consistency is key

---

## Contact & Resources

**Team Leader:** [Name]  
**Technical Lead:** [Name]  
**Documentation:** See `/docs` folder  
**Architecture Diagram:** See `/docs/architecture.md`  
**PRD:** See `/docs/prd.md`

---

## GitHub Copilot Specific Instructions

When generating code for this project:

1. **Always follow the layer pattern** - Check which layer you're in
2. **Use existing patterns** - Look at similar code in the project
3. **Add XML documentation** - Every public member needs it
4. **Use ProcedureMapper** - Never hard-code SP names in Application Layer
5. **Inject services properly** - Use constructor injection
6. **Return JSON** - Application Layer methods return JSON strings
7. **Handle errors** - Wrap in try-catch with logging
8. **Use async/await** - All I/O operations must be async
9. **Validate input** - Controllers validate, not services
10. **Keep it DRY** - Extract common logic to base methods

**When suggesting refactoring:**

- Show the complete before/after
- Explain why the change improves the code
- Point out any potential breaking changes

**When generating tests:**

- Include Arrange, Act, Assert comments
- Cover happy path and error cases
- Use descriptive test method names

**When generating documentation:**

- Include summary, params, returns, exceptions
- Add code examples when helpful
- Keep it concise but complete

---

**Last Updated:** October 30, 2025  
**Version:** 1.0  
**Maintained By:** Development Team
