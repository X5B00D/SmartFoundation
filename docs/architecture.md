# SmartFoundation Architecture

This document provides a comprehensive overview of the SmartFoundation architecture, design principles, and technical implementation.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Clean Architecture Principles](#clean-architecture-principles)
- [Layer Responsibilities](#layer-responsibilities)
- [Intelligent Routing System](#intelligent-routing-system)
- [Data Flow Diagrams](#data-flow-diagrams)
- [Key Components](#key-components)
- [Design Patterns](#design-patterns)
- [Technology Stack](#technology-stack)

---

## Architecture Overview

SmartFoundation follows **Clean Architecture** (also known as Onion Architecture or Hexagonal Architecture) principles, organizing code into distinct layers with clear separation of concerns.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────────┐  ┌──────────────────────────────┐    │
│  │   Controllers    │  │  SmartComponentController    │    │
│  │                  │  │   (Intelligent Routing)      │    │
│  └──────────────────┘  └──────────────────────────────┘    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ├─────────────────┐
                     │                 │
                     ▼                 ▼
     ┌───────────────────────┐  ┌──────────────────────┐
     │  Application Layer    │  │  DataEngine          │
     │  ┌─────────────────┐ │  │  (Legacy Fallback)   │
     │  │  Services       │ │  │                      │
     │  │  - Employee     │ │  │                      │
     │  │  - Department   │ │  │                      │
     │  │  - Menu         │ │  │                      │
     │  │  - Dashboard    │ │  │                      │
     │  └─────────────────┘ │  │                      │
     │  ┌─────────────────┐ │  │                      │
     │  │ ProcedureMapper │ │  │                      │
     │  │ (SP Routing)    │ │  │                      │
     │  └─────────────────┘ │  │                      │
     └──────────┬────────────┘  └──────────┬───────────┘
                │                          │
                └──────────┬───────────────┘
                           │
                           ▼
                 ┌──────────────────┐
                 │  DataEngine      │
                 │  Core Services   │
                 └─────────┬────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Database   │
                    │  (SQL Server)│
                    └─────────────┘
```

### Core Principles

1. **Dependency Inversion:** Outer layers depend on inner layers, never vice versa
2. **Separation of Concerns:** Each layer has a single, well-defined responsibility
3. **Testability:** Every layer can be tested independently
4. **Flexibility:** Easy to swap implementations without affecting other layers
5. **Backward Compatibility:** Legacy code works alongside new architecture

---

## Clean Architecture Principles

### The Dependency Rule

**Dependencies point inward:**

```
Presentation → Application → DataEngine → Database
```

- **Outer layers know about inner layers**
- **Inner layers know nothing about outer layers**
- Application Layer is independent of MVC framework
- DataEngine is independent of Application Layer services

### Benefits

✅ **Testability**

- Each layer tested in isolation
- Mock dependencies easily
- Fast unit tests without database

✅ **Maintainability**

- Changes isolated to specific layers
- Clear boundaries reduce coupling
- Easy to understand and modify

✅ **Flexibility**

- Swap implementations (e.g., different ORM)
- Support multiple UI frameworks
- Migrate incrementally

✅ **Team Independence**

- Teams work on different layers simultaneously
- Clear contracts between layers
- Reduced merge conflicts

---

## Layer Responsibilities

### 1. Presentation Layer (SmartFoundation.Mvc)

**Location:** `SmartFoundation.Mvc/`

**Purpose:** Handle user interactions and HTTP requests

**Responsibilities:**

- Render views and handle HTTP requests/responses
- Validate user input at the edge
- Extract session data and prepare parameters
- Route requests via SmartComponentController
- Pass data to views for rendering
- Handle authentication and authorization

**Key Components:**

- `Controllers/` - MVC controllers
- `Views/` - Razor views
- `ViewComponents/` - Reusable UI components
- `wwwroot/` - Static files (CSS, JS, images)

**Rules:**

- ❌ NO business logic
- ❌ NO direct DataEngine calls
- ❌ NO hard-coded stored procedure names
- ✅ Inject Application Layer services
- ✅ Validate input before calling services
- ✅ Use async/await for all service calls

---

### 2. Application Layer (SmartFoundation.Application)

**Location:** `SmartFoundation.Application/`

**Purpose:** Implement business logic and orchestration

**Responsibilities:**

- Implement business operations as service methods
- Use ProcedureMapper to translate operations to SP names
- Orchestrate multiple stored procedure calls when needed
- Handle errors gracefully with structured responses
- Serialize data to JSON for presentation layer
- Provide clear method signatures with documented parameters
- Log operations for debugging and auditing

**Key Components:**

- `Services/` - Business service classes
  - `BaseService.cs` - Abstract base class for all services
  - `EmployeeService.cs` - Employee CRUD operations
  - `MenuService.cs` - Menu/navigation services
  - `DashboardService.cs` - Dashboard aggregation
- `Mapping/ProcedureMapper.cs` - SP name and routing configuration
- `Extensions/ServiceCollectionExtensions.cs` - DI registration

**Rules:**

- ❌ NO hard-coded stored procedure names
- ❌ NO direct database access
- ❌ NO HttpContext or session access
- ✅ All service methods must be async
- ✅ Return JSON strings or serializable objects
- ✅ Handle errors with try-catch
- ✅ Document expected parameters with XML comments
- ✅ Inject ISmartComponentService for data access
- ✅ ALL services MUST inherit from BaseService

---

### 3. DataEngine Layer (SmartFoundation.DataEngine)

**Location:** `SmartFoundation.DataEngine/`

**Purpose:** Database interaction and stored procedure execution

**Responsibilities:**

- Execute stored procedures via SmartComponentService
- Manage database connections
- Handle SQL errors and return structured responses
- Use parameterized queries (prevent SQL injection)
- Return data as SmartResponse objects

**Key Components:**

- `Core/SmartComponentService.cs` - Main data access service
- `Core/Models/SmartRequest.cs` - Request model
- `Core/Models/SmartResponse.cs` - Response model
- `Core/Interfaces/ISmartComponentService.cs` - Service contract

**Rules:**

- ✅ Only Application Layer calls DataEngine
- ✅ Use SmartRequest and SmartResponse objects
- ✅ Handle database errors gracefully
- ❌ NO business logic here
- ❌ Controllers should NEVER call DataEngine directly

---

### 4. UI Components Layer (SmartFoundation.UI)

**Location:** `SmartFoundation.UI/`

**Purpose:** Reusable view components and view models

**Responsibilities:**

- Provide reusable UI components (SmartTable, SmartForm)
- Define view models for complex views
- Handle client-side rendering logic

**Key Components:**

- `ViewComponents/` - Reusable view components
- `ViewModels/` - View models and DTOs
- `Views/` - Shared partial views

---

## Intelligent Routing System

### Overview

SmartFoundation uses an intelligent routing system that automatically directs requests to either the Application Layer (new pattern) or DataEngine (legacy fallback).

### Request Flow

```
┌──────────────┐
│ Client       │
│ JavaScript   │
│ POST Request │
└──────┬───────┘
       │
       │ POST /smart/execute
       │ { spName: "dbo.sp_SmartFormDemo", operation: "select", params: {...} }
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  SmartComponentController.Execute()                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Log request                                   │  │
│  │ 2. Call ProcedureMapper.GetServiceRoute(spName) │  │
│  └──────────────────────┬───────────────────────────┘  │
│                         │                               │
│                         ├─────────────┐                 │
│                         │             │                 │
│              ┌──────────▼──────┐  ┌──▼───────────┐     │
│              │ Route Found?    │  │ null?        │     │
│              │ (ServiceRoute)  │  │              │     │
│              └──────┬──────────┘  └──┬───────────┘     │
│                     │                │                  │
│           ┌─────────▼──────┐    ┌───▼────────────┐    │
│           │ YES: Use       │    │ NO: Fallback to│    │
│           │ Application    │    │ DataEngine     │    │
│           │ Layer Service  │    │ (Legacy Path)  │    │
│           └────────┬───────┘    └───┬────────────┘    │
│                    │                 │                 │
│                    ▼                 ▼                 │
│  ┌────────────────────────────────────────────────┐   │
│  │ 3. Resolve service from DI container           │   │
│  │    - IServiceProvider.GetService(serviceType)  │   │
│  └────────────────┬───────────────────────────────┘   │
│                   │                                    │
│                   ▼                                    │
│  ┌────────────────────────────────────────────────┐   │
│  │ 4. Get method name from operation              │   │
│  │    - ProcedureMapper._operationMethodMap      │   │
│  │    - e.g., "select" → "GetEmployeeList"       │   │
│  └────────────────┬───────────────────────────────┘   │
│                   │                                    │
│                   ▼                                    │
│  ┌────────────────────────────────────────────────┐   │
│  │ 5. Invoke service method via reflection       │   │
│  │    - serviceType.GetMethod(methodName)        │   │
│  │    - method.Invoke(service, [parameters])     │   │
│  └────────────────┬───────────────────────────────┘   │
│                   │                                    │
│                   ▼                                    │
│  ┌────────────────────────────────────────────────┐   │
│  │ 6. Return JSON result to client                │   │
│  │    - JsonResult with success, data, message    │   │
│  └────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Routing Decision

**Application Layer Path (Preferred):**

- Stored procedure name found in `ProcedureMapper._serviceRegistry`
- Service registered in DI container
- Method name mapped from operation
- Logs: "Routing request to Application Layer: SP=..., Operation=..."

**Legacy DataEngine Path (Fallback):**

- Stored procedure name NOT found in registry
- Direct call to ISmartComponentService.ExecuteAsync()
- Logs: "No service route found for SP=..., falling back to DataEngine"

### Benefits of Intelligent Routing

✅ **Backward Compatibility:** Unmigrated stored procedures continue to work
✅ **Incremental Migration:** Migrate one service at a time
✅ **Zero Downtime:** No need to update all code simultaneously
✅ **Transparent:** Client code doesn't need changes
✅ **Testable:** Each path can be tested independently

---

## Data Flow Diagrams

### Complete Request-Response Flow

```
┌─────────────┐
│   Browser   │
│   (Client)  │
└──────┬──────┘
       │
       │ 1. User Action (Click, Submit Form)
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  Razor View (.cshtml)                               │
│  ┌───────────────────────────────────────────────┐ │
│  │ <form> with inputs                            │ │
│  │ JavaScript: smartComponent.execute({          │ │
│  │   spName: "dbo.sp_SmartFormDemo",            │ │
│  │   operation: "select",                        │ │
│  │   params: { pageNumber: 1 }                   │ │
│  │ })                                            │ │
│  └───────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────┘
                     │
                     │ 2. POST /smart/execute
                     │    (JSON payload)
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│  SmartComponentController (Presentation Layer)         │
│  ┌──────────────────────────────────────────────────┐ │
│  │ Execute(spName, operation, params)               │ │
│  │ - Validate input                                 │ │
│  │ - Get ServiceRoute from ProcedureMapper         │ │
│  │ - Route to Application Layer OR DataEngine      │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────┬──────────────────┬──────────────────┘
                   │                  │
       ┌───────────┴────────┐         └─────────────────┐
       │                    │                           │
       ▼                    ▼                           ▼
┌─────────────────┐  ┌─────────────────────┐  ┌────────────────┐
│ Application     │  │ ProcedureMapper     │  │ DataEngine     │
│ Layer Service   │  │ (Routing Config)    │  │ (Fallback)     │
│ (EmployeeService│  │ - _serviceRegistry  │  │                │
│  MenuService,   │  │ - _operationMap     │  │                │
│  etc.)          │  │                     │  │                │
└────────┬────────┘  └─────────────────────┘  └───────┬────────┘
         │                                             │
         │ 3. ExecuteOperation(module, operation, params)
         │                                             │
         └──────────────────┬──────────────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │  BaseService         │
                │  ┌────────────────┐  │
                │  │ try {          │  │
                │  │  - Map to SP   │  │
                │  │  - Create req  │  │
                │  │  - Call DataEng│  │
                │  │  - Return JSON │  │
                │  │ } catch {      │  │
                │  │  - Log error   │  │
                │  │  - Return err  │  │
                │  │ }              │  │
                │  └────────────────┘  │
                └──────────┬───────────┘
                           │
                           │ 4. ISmartComponentService.ExecuteAsync(request)
                           │
                           ▼
                ┌──────────────────────┐
                │  DataEngine          │
                │  ┌────────────────┐  │
                │  │ Open connection│  │
                │  │ Execute SP     │  │
                │  │ Map results    │  │
                │  │ Return response│  │
                │  └────────────────┘  │
                └──────────┬───────────┘
                           │
                           │ 5. SmartResponse { Success, Data, Message }
                           │
                           ▼
                ┌──────────────────────┐
                │  SQL Server Database │
                │  ┌────────────────┐  │
                │  │ Stored Proc    │  │
                │  │ - Validation   │  │
                │  │ - Business     │  │
                │  │ - Data query   │  │
                │  │ - Return rows  │  │
                │  └────────────────┘  │
                └──────────────────────┘
                           │
                           │ 6. Result set
                           │
                ┌──────────▼───────────┐
                │  JSON Response       │
                │  {                   │
                │    success: true,    │
                │    data: [...],      │
                │    message: "..."    │
                │  }                   │
                └──────────┬───────────┘
                           │
                           │ 7. Return to client
                           │
                           ▼
                ┌─────────────────────┐
                │  Browser            │
                │  - Parse JSON       │
                │  - Update UI        │
                │  - Show feedback    │
                └─────────────────────┘
```

### Service Execution Flow (Application Layer)

```
┌────────────────────────────────────────────────┐
│  EmployeeService.GetEmployeeList(parameters)   │
└─────────────────┬──────────────────────────────┘
                  │
                  │ Inherits from BaseService
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  BaseService.ExecuteOperation("employee", "list", ...)  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 1. _logger.LogInformation("employee:list called") │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 2. ProcedureMapper.GetProcedureName(              │  │
│  │      "employee", "list")                          │  │
│  │    → "dbo.sp_GetEmployees"                        │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 3. Create SmartRequest {                          │  │
│  │      Operation = "sp",                            │  │
│  │      SpName = "dbo.sp_GetEmployees",              │  │
│  │      Params = parameters                          │  │
│  │    }                                              │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 4. response = await _dataEngine.ExecuteAsync(req) │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ 5. return JsonSerializer.Serialize({              │  │
│  │      success: response.Success,                   │  │
│  │      data: response.Data,                         │  │
│  │      message: response.Message                    │  │
│  │    })                                             │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ catch (Exception ex) {                            │  │
│  │   _logger.LogError(ex);                           │  │
│  │   return error JSON                               │  │
│  │ }                                                 │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. SmartComponentController

**Purpose:** Intelligent routing hub for all data operations

**Location:** `SmartFoundation.Mvc/Controllers/SmartComponentController.cs`

**Key Features:**

- Receives all AJAX requests from client-side JavaScript
- Routes to Application Layer services when available
- Falls back to DataEngine for unmigrated stored procedures
- Uses reflection for dynamic method invocation
- Comprehensive logging and error handling

**Key Methods:**

```csharp
public async Task<IActionResult> Execute(string spName, string operation, Dictionary<string, object?> @params)
```

### 2. ProcedureMapper

**Purpose:** Central configuration for stored procedure routing

**Location:** `SmartFoundation.Application/Mapping/ProcedureMapper.cs`

**Key Features:**

- Maps stored procedure names to service types
- Maps operation names to method names
- Case-insensitive lookups
- Supports custom operation mappings

**Key Components:**

```csharp
private static readonly Dictionary<string, ServiceRoute> _serviceRegistry
private static readonly Dictionary<string, string> _operationMethodMap

public static ServiceRoute? GetServiceRoute(string spName, string? operation)
```

**ServiceRoute Record:**

```csharp
public record ServiceRoute(
    string Module,          // e.g., "employee", "department"
    Type ServiceType,       // e.g., typeof(EmployeeService)
    string? MethodName,     // Optional explicit method name
    string StoredProcedure  // e.g., "dbo.sp_SmartFormDemo"
);
```

### 3. BaseService

**Purpose:** Abstract base class providing common functionality for all services

**Location:** `SmartFoundation.Application/Services/BaseService.cs`

**Key Features:**

- Standardized error handling
- Consistent logging
- ExecuteOperation template method
- JSON serialization
- Exception wrapping

**Key Methods:**

```csharp
protected async Task<string> ExecuteOperation(string module, string operation, Dictionary<string, object?> parameters)
```

**Inheritance Requirement:** ⚠️ **ALL services MUST inherit from BaseService**

### 4. ISmartComponentService

**Purpose:** Data access interface for executing stored procedures

**Location:** `SmartFoundation.DataEngine/Core/Interfaces/ISmartComponentService.cs`

**Key Methods:**

```csharp
Task<SmartResponse> ExecuteAsync(SmartRequest request, CancellationToken cancellationToken = default);
```

---

## Design Patterns

### 1. Dependency Injection (DI)

**Pattern:** Constructor Injection

**Usage:** All services and controllers

**Example:**

```csharp
public class EmployeeService : BaseService
{
    public EmployeeService(
        ISmartComponentService dataEngine,
        ILogger<EmployeeService> logger)
        : base(dataEngine, logger)
    {
    }
}
```

**Benefits:**

- Loose coupling
- Easy testing with mocks
- Clear dependencies

### 2. Template Method

**Pattern:** BaseService.ExecuteOperation()

**Usage:** All Application Layer services

**Example:**

```csharp
protected async Task<string> ExecuteOperation(string module, string operation, Dictionary<string, object?> parameters)
{
    // Common logic:
    // 1. Map to SP name
    // 2. Create request
    // 3. Call DataEngine
    // 4. Handle errors
    // 5. Return JSON
}
```

**Benefits:**

- Eliminates code duplication
- Consistent error handling
- Centralized logging

### 3. Repository Pattern

**Pattern:** ISmartComponentService abstracts data access

**Usage:** DataEngine layer

**Benefits:**

- Database-agnostic services
- Easy to mock for testing
- Swap implementations without changing services

### 4. Service Layer Pattern

**Pattern:** Application Layer services encapsulate business logic

**Usage:** All domain services (EmployeeService, DepartmentService, etc.)

**Benefits:**

- Business logic separate from presentation
- Reusable across multiple controllers
- Testable in isolation

### 5. Strategy Pattern (Implicit)

**Pattern:** Routing strategy based on ProcedureMapper lookup

**Usage:** SmartComponentController.Execute()

**Strategies:**

1. Application Layer Service (when route found)
2. Legacy DataEngine (when route not found)

**Benefits:**

- Backward compatibility
- Incremental migration
- Transparent to clients

---

## Technology Stack

### Backend

- **Framework:** ASP.NET Core 8.0
- **Language:** C# 12
- **Database:** SQL Server
- **ORM/Data Access:** Custom DataEngine (ADO.NET-based)

### Testing

- **Unit Testing Framework:** xUnit
- **Mocking Framework:** Moq
- **Assertion Library:** xUnit.Assert

### Frontend

- **Framework:** Razor Views (MVC)
- **JavaScript:** Vanilla JS with SmartComponent library
- **CSS Framework:** Tailwind CSS
- **HTTP Client:** Fetch API

### DevOps & Tools

- **Version Control:** Git
- **Task Management:** Task Master AI (MCP)
- **Build Tool:** .NET CLI / MSBuild
- **Package Manager:** NuGet

### Development Environment

- **IDE:** Visual Studio Code / Visual Studio 2022
- **AI Assistant:** GitHub Copilot
- **CI/CD:** (To be configured)

---

## Summary

SmartFoundation's architecture provides:

✅ **Clean separation** between presentation, business logic, and data access  
✅ **Intelligent routing** that supports both new services and legacy code  
✅ **High testability** with comprehensive unit test coverage  
✅ **Incremental migration** path for modernizing legacy code  
✅ **Team scalability** through clear layer boundaries  
✅ **Maintainability** via consistent patterns and practices  

The architecture supports the project's goals of modernization while maintaining stability and backward compatibility.

---

## Related Documentation

- [Usage Guide](../.github/docs/usage.md) - Practical examples and code patterns
- [Migration Guide](./MIGRATION_GUIDE.md) - Step-by-step service migration
- [GitHub Copilot Instructions](../.github/copilot-instructions.md) - Complete coding standards

---

**Last Updated:** November 6, 2025  
**Version:** 1.0  
**Author:** SmartFoundation Development Team
