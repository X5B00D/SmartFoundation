# Clean Architecture: Parameter Passing Guide

## The Problem

You encountered this error:

```
Procedure or function 'GetSessionInfoForMVC' expects parameter '@UserID', which was not supplied.
```

**Your concern was valid!** You correctly identified that simply adding parameters to `SmartPageViewModel` would break Clean Architecture principles.

---

## Why SmartPageViewModel Shouldn't Handle Business Parameters

### ❌ **What Would Break Clean Architecture:**

```csharp
// BAD: Adding business parameters to view model
public class SmartPageViewModel
{
    public Dictionary<string, object?> BusinessParameters { get; set; }  // ❌ WRONG!
}
```

**Problems with this approach:**

1. **Violates Separation of Concerns** - View models should only handle presentation data
2. **Tight Coupling** - View layer becomes aware of business logic parameters
3. **Testability Issues** - Harder to test controllers independently
4. **Breaks Dependency Rule** - Presentation layer shouldn't know about data access details

---

## ✅ The Clean Architecture Solution

### **Flow: Controller → Service → DataEngine → Database**

```
┌─────────────────────────────────────────────────────────────┐
│  Controller (Presentation Layer)                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 1. Extract UserID from Session/Request               │  │
│  │ 2. Validate input                                     │  │
│  │ 3. Prepare parameters Dictionary                     │  │
│  │ 4. Call SessionService.GetSessionInfo(parameters)    │  │
│  │ 5. Pass result to View via ViewBag                   │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  SessionService (Application Layer)                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 1. Receives parameters Dictionary                    │  │
│  │ 2. Calls BaseService.ExecuteOperation()              │  │
│  │ 3. Logs operation                                     │  │
│  │ 4. Returns JSON string                               │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  BaseService.ExecuteOperation() (Application Layer)         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 1. ProcedureMapper.GetProcedureName("session",       │  │
│  │    "getInfo") → "dbo.GetSessionInfoForMVC"           │  │
│  │ 2. Create SmartRequest with SP name & parameters     │  │
│  │ 3. Call DataEngine.ExecuteAsync(request)             │  │
│  │ 4. Handle errors gracefully                           │  │
│  │ 5. Return structured JSON                             │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  DataEngine (Data Access Layer)                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 1. Open SQL connection                                │  │
│  │ 2. Create SqlCommand with SP name                     │  │
│  │ 3. Add parameters (@UserID = 60014019)               │  │
│  │ 4. Execute stored procedure                           │  │
│  │ 5. Map results to SmartResponse                       │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
                 ┌─────────┐
                 │ Database│
                 └─────────┘
```

---

## Implementation Steps

### Step 1: Create SessionService (Application Layer)

**File:** `SmartFoundation.Application/Services/SessionService.cs`

```csharp
public class SessionService : BaseService
{
    public SessionService(
        ISmartComponentService dataEngine,
        ILogger<SessionService> logger)
        : base(dataEngine, logger)
    {
    }

    /// <summary>
    /// Retrieves session information for a specific user.
    /// </summary>
    public async Task<string> GetSessionInfo(Dictionary<string, object?> parameters)
    {
        return await ExecuteOperation("session", "getInfo", parameters);
    }
}
```

**Why This Is Correct:**

- ✅ Inherits from `BaseService` (MANDATORY)
- ✅ Uses `ExecuteOperation` pattern (no code duplication)
- ✅ Accepts `Dictionary<string, object?>` for flexible parameters
- ✅ Returns JSON string for presentation layer
- ✅ Testable independently with mocks

---

### Step 2: Register in ProcedureMapper

**File:** `SmartFoundation.Application/Mapping/ProcedureMapper.cs`

```csharp
// 1. Add SP name mapping
private static readonly Dictionary<string, string> _mappings = new()
{
    { "session:getInfo", "dbo.GetSessionInfoForMVC" }
};

// 2. Add service registry for intelligent routing
private static readonly Dictionary<string, ServiceRoute> _serviceRegistry = new(StringComparer.OrdinalIgnoreCase)
{
    { "dbo.GetSessionInfoForMVC", new ServiceRoute("session", typeof(Services.SessionService), null!, "dbo.GetSessionInfoForMVC") }
};

// 3. Add operation mapping
private static readonly Dictionary<string, string> _operationMethodMap = new(StringComparer.OrdinalIgnoreCase)
{
    { "getInfo", "GetSessionInfo" },
    { "sp", "GetSessionInfo" }  // For generic "sp" operation
};
```

**Why This Is Correct:**

- ✅ Centralizes SP name mapping (no hard-coding)
- ✅ Enables intelligent routing to Application Layer
- ✅ Maps operations to method names
- ✅ Supports backward compatibility (fallback to DataEngine)

---

### Step 3: Register in Dependency Injection

**File:** `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs`

```csharp
public static IServiceCollection AddApplicationServices(this IServiceCollection services)
{
    services.AddScoped<EmployeeService>();
    services.AddScoped<MenuService>();
    services.AddScoped<DashboardService>();
    services.AddScoped<SessionService>();  // ✅ Add this line
    
    return services;
}
```

**Why This Is Correct:**

- ✅ Uses `Scoped` lifetime (one instance per HTTP request)
- ✅ Registered in Application Layer extension method
- ✅ Available for controller injection

---

### Step 4: Update Controller (Presentation Layer)

**File:** `SmartFoundation.Mvc/Controllers/EmployeesController.cs`

```csharp
public class EmployeesController : Controller
{
    private readonly SessionService _sessionService;
    private readonly ILogger<EmployeesController> _logger;

    public EmployeesController(
        SessionService sessionService,
        ILogger<EmployeesController> logger)
    {
        _sessionService = sessionService;
        _logger = logger;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            // TODO: Replace with actual session value
            // var userId = HttpContext.Session.GetInt32("UserId") ?? 60014019;
            int testUserId = 60014019;

            // Prepare parameters for service call
            var parameters = new Dictionary<string, object?>
            {
                { "UserID", testUserId }
            };

            // Call Application Layer service (Clean Architecture ✅)
            var jsonResult = await _sessionService.GetSessionInfo(parameters);
            
            // Validate result
            var result = JsonSerializer.Deserialize<JsonElement>(jsonResult);
            var success = result.GetProperty("success").GetBoolean();

            if (!success)
            {
                var errorMessage = result.GetProperty("message").GetString();
                _logger.LogWarning("Failed to retrieve session info: {Message}", errorMessage);
                ViewBag.ErrorMessage = $"Error: {errorMessage}";
            }

            // Pass data to view
            ViewBag.SessionData = jsonResult;

            var vm = new SmartPageViewModel
            {
                PageTitle = "User Session Information",
                PanelTitle = $"Session Data for User {testUserId}",
                // ... table configuration
            };

            return View(vm);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading session information");
            ViewBag.ErrorMessage = "An error occurred while loading data";
            return View(new SmartPageViewModel());
        }
    }
}
```

**Why This Is Correct:**

- ✅ Injects `SessionService` (not `ISmartComponentService`)
- ✅ Prepares parameters in controller (validation layer)
- ✅ Calls service method with parameters
- ✅ Handles errors appropriately
- ✅ Passes data to view via `ViewBag`
- ✅ Uses async/await throughout
- ✅ Logs operations for debugging

---

## Key Architecture Principles Followed

### 1. **Dependency Rule ✅**

```
Presentation → Application → DataEngine → Database
```

Dependencies point **inward**, never outward.

### 2. **Single Responsibility ✅**

- **Controller**: Validate input, call service, render view
- **Service**: Business logic, orchestration
- **DataEngine**: Execute stored procedures
- **View**: Display data

### 3. **Separation of Concerns ✅**

- **Presentation Layer**: UI concerns only (page title, table configuration)
- **Application Layer**: Business operations (GetSessionInfo)
- **Data Access Layer**: Database operations only

### 4. **Testability ✅**

Each layer can be tested independently:

```csharp
// Test Controller
var mockService = new Mock<SessionService>();
var controller = new EmployeesController(mockService.Object, mockLogger.Object);

// Test Service
var mockDataEngine = new Mock<ISmartComponentService>();
var service = new SessionService(mockDataEngine.Object, mockLogger.Object);
```

### 5. **No Hard-Coded Values ✅**

- Stored procedure name: `ProcedureMapper.GetProcedureName("session", "getInfo")`
- Service routing: `ProcedureMapper.GetServiceRoute("dbo.GetSessionInfoForMVC", "sp")`
- Parameters: Passed dynamically via `Dictionary<string, object?>`

---

## Why Your Original Concern Was Valid

### ❌ **What Would Have Been Wrong:**

**Approach 1: Adding parameters to SmartPageViewModel**

```csharp
// BAD: Pollutes view model with business logic
public class SmartPageViewModel
{
    public Dictionary<string, object?> Parameters { get; set; }  // ❌ WRONG!
}

var vm = new SmartPageViewModel
{
    Parameters = new Dictionary<string, object?> { { "UserID", 60014019 } }
};
```

**Problems:**

- View model now knows about business parameters
- Presentation layer coupled to data access layer
- Can't validate parameters before passing to view
- Hard to test controllers

**Approach 2: Bypassing Application Layer**

```csharp
// BAD: Controller calls DataEngine directly
public class EmployeesController : Controller
{
    private readonly ISmartComponentService _dataEngine;  // ❌ WRONG!
    
    public async Task<IActionResult> Index()
    {
        var request = new SmartRequest
        {
            SpName = "dbo.GetSessionInfoForMVC",  // ❌ Hard-coded!
            Params = new Dictionary<string, object?> { { "UserID", 60014019 } }
        };
        
        var response = await _dataEngine.ExecuteAsync(request);  // ❌ Skips Application Layer!
    }
}
```

**Problems:**

- Bypasses Application Layer (breaks architecture)
- Hard-coded stored procedure names
- No business logic validation
- Duplicates code across controllers
- Can't use intelligent routing

---

## Comparison: Wrong vs. Right

| Aspect | ❌ Wrong Approach | ✅ Clean Architecture |
|--------|------------------|----------------------|
| **Parameter Passing** | Via SmartPageViewModel | Via Service method call |
| **Controller Dependencies** | ISmartComponentService | SessionService |
| **SP Name Location** | Hard-coded in controller | ProcedureMapper (centralized) |
| **Business Logic** | In controller | In Application Layer service |
| **Error Handling** | Controller only | Service + Controller (layered) |
| **Testability** | Hard to test (DB dependency) | Easy to test (mock services) |
| **Routing** | Manual (no intelligent routing) | Automatic via SmartComponentController |
| **Code Reusability** | Low (duplicated logic) | High (BaseService pattern) |

---

## Benefits of This Architecture

### 1. **Backward Compatibility**

- Unmigrated stored procedures still work (fallback to DataEngine)
- No need to update all code at once
- Incremental migration path

### 2. **Intelligent Routing**

- SmartComponentController automatically routes to correct service
- Front-end code doesn't need changes
- Transparent to existing views

### 3. **Flexibility**

- Easy to add new operations (just add method to service)
- Parameters validated in controller (before service call)
- Services remain agnostic to HTTP concerns

### 4. **Team Scalability**

- Different teams work on different layers
- Clear contracts between layers
- Reduced merge conflicts

### 5. **Maintainability**

- Change SP name in one place (ProcedureMapper)
- Update business logic in service (not controller)
- Easy to find and fix bugs

---

## Testing Strategy

### Unit Test: SessionService

```csharp
[Fact]
public async Task GetSessionInfo_WithValidUserId_ReturnsSuccess()
{
    // Arrange
    var mockDataEngine = new Mock<ISmartComponentService>();
    var mockLogger = new Mock<ILogger<SessionService>>();
    var service = new SessionService(mockDataEngine.Object, mockLogger.Object);
    
    var parameters = new Dictionary<string, object?>
    {
        { "UserID", 60014019 }
    };
    
    mockDataEngine
        .Setup(de => de.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
            Success = true,
            Data = new List<Dictionary<string, object?>>
            {
                new() { { "fullName", "Test User" }, { "userID", 60014019 } }
            }
        });
    
    // Act
    var result = await service.GetSessionInfo(parameters);
    
    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    
    mockDataEngine.Verify(
        de => de.ExecuteAsync(
            It.Is<SmartRequest>(r => 
                r.SpName == "dbo.GetSessionInfoForMVC" && 
                r.Params!["UserID"]!.Equals(60014019)
            ),
            default
        ),
        Times.Once
    );
}
```

### Integration Test: Controller

```csharp
[Fact]
public async Task Index_WithValidSession_ReturnsViewWithData()
{
    // Arrange
    var mockService = new Mock<SessionService>();
    var mockLogger = new Mock<ILogger<EmployeesController>>();
    var controller = new EmployeesController(mockService.Object, mockLogger.Object);
    
    mockService
        .Setup(s => s.GetSessionInfo(It.IsAny<Dictionary<string, object?>>()))
        .ReturnsAsync("{\"success\":true,\"data\":[{\"fullName\":\"Test\"}]}");
    
    // Act
    var result = await controller.Index() as ViewResult;
    
    // Assert
    Assert.NotNull(result);
    Assert.NotNull(result.Model);
    Assert.IsType<SmartPageViewModel>(result.Model);
}
```

---

## Summary: Clean Architecture Checklist

When implementing features with parameters:

- [x] **Create service in Application Layer** (inherits from BaseService)
- [x] **Register SP name in ProcedureMapper** (_mappings)
- [x] **Register service route in ProcedureMapper** (_serviceRegistry)
- [x] **Add operation mapping in ProcedureMapper** (_operationMethodMap)
- [x] **Register service in DI** (ServiceCollectionExtensions)
- [x] **Inject service in controller** (constructor injection)
- [x] **Prepare parameters in controller** (validate input)
- [x] **Call service method** (not DataEngine directly)
- [x] **Handle errors gracefully** (try-catch with logging)
- [x] **Pass data to view** (ViewBag, not in view model properties)
- [x] **Write unit tests** (service layer)
- [x] **Write integration tests** (controller layer)

---

## FAQ

### Q: Can I pass parameters through SmartPageViewModel?

**A:** ❌ No. View models should only contain presentation data (titles, labels, UI configuration). Business parameters should be handled in the controller and passed to services.

### Q: Why not call DataEngine directly from controller?

**A:** That would bypass the Application Layer, breaking Clean Architecture. You'd lose:

- Intelligent routing
- Business logic validation
- Code reusability (BaseService pattern)
- Testability (can't easily mock DataEngine)
- Centralized SP name mapping

### Q: What if I need to pass dynamic parameters from the view?

**A:** Use form submissions or AJAX requests that post data to controller actions. The controller validates input and passes it to the service:

```csharp
[HttpPost]
public async Task<IActionResult> GetSessionInfo(int userId)
{
    // Validate input
    if (userId <= 0)
        return BadRequest("Invalid user ID");
    
    // Prepare parameters
    var parameters = new Dictionary<string, object?> { { "UserID", userId } };
    
    // Call service
    var result = await _sessionService.GetSessionInfo(parameters);
    
    return Json(result);
}
```

### Q: How do I handle session values (like logged-in user ID)?

**A:** Extract session values in the controller, then pass them as parameters:

```csharp
public async Task<IActionResult> Index()
{
    // Extract from session
    var userId = HttpContext.Session.GetInt32("UserId") ?? throw new UnauthorizedException();
    
    // Prepare parameters
    var parameters = new Dictionary<string, object?> { { "UserID", userId } };
    
    // Call service
    var result = await _sessionService.GetSessionInfo(parameters);
    
    // ...
}
```

### Q: Does this work with SmartComponentController's intelligent routing?

**A:** ✅ Yes! When you configure `SmartPageViewModel` with the SP name, the SmartComponentController automatically:

1. Looks up the SP in `ProcedureMapper._serviceRegistry`
2. Resolves the service type (`SessionService`)
3. Gets the service instance from DI
4. Invokes the method (`GetSessionInfo`)
5. Passes parameters from the AJAX request

---

## Additional Resources

- [Architecture Guide](./architecture.md) - Complete system architecture
- [Migration Guide](./MIGRATION_GUIDE.md) - Step-by-step service migration
- [GitHub Copilot Instructions](../.github/copilot-instructions.md) - Coding standards

---

**Last Updated:** November 6, 2025  
**Version:** 1.0  
**Author:** SmartFoundation Development Team
