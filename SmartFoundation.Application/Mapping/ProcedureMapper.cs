namespace SmartFoundation.Application.Mapping;

using SmartFoundation.Application.Services;
/// <summary>
/// Data structure for holding service routing information.
/// Used by SmartComponentController to dynamically resolve and invoke service methods.
/// </summary>
/// <param name="ServiceName">The logical service name (e.g., "employee", "menu")</param>
/// <param name="ServiceType">The Type of the service class (e.g., typeof(EmployeeService))</param>
/// <param name="MethodName">The name of the method to invoke on the service</param>
/// <param name="SpName">The stored procedure name this route is associated with</param>
public record ServiceRoute(string ServiceName, Type ServiceType, string MethodName, string SpName);

/// <summary>
/// Centralized mapping of business operations to stored procedure names.
/// This eliminates hard-coded SP names throughout the application.
/// </summary>
public static class ProcedureMapper
{
  // Existing mappings: "module:operation" → "stored procedure name"
  private static readonly Dictionary<string, string> _mappings = new()
    {
        // Employee operations
        { "employee:list", "dbo.sp_SmartFormDemo" },
        { "employee:insert", "dbo.sp_SmartFormDemo" },
        { "employee:update", "dbo.sp_SmartFormDemo" },
        { "employee:delete", "dbo.sp_SmartFormDemo" },
        { "employee:getById", "dbo.sp_SmartFormDemo" },
        
        // Menu operations
        { "menu:list", "dbo.ListOfMenuByUser_MVC" },
        { "menu:listAll", "dbo.sp_GetAllMenuItems" },
        
        // Dashboard operations
        { "dashboard:summary", "dbo.sp_GetDashboardSummary" },
        
        // Session operations
        { "session:getInfo", "dbo.GetSessionInfoForMVC" },
        
        // Demo operations
        { "demo:getData", "dbo.sp_GetDemoData" },
        { "demo:saveForm", "dbo.sp_SaveDemoForm" },
        
        // Pakistani operations (from existing controller)
        { "pakistani:getData", "dbo.sp_SmartFormDemo" }
    };

  /// <summary>
  /// Service registry: Maps stored procedure names to service routing information.
  /// Used by SmartComponentController for intelligent routing to Application Layer services.
  /// Key: Stored procedure name (case-insensitive)
  /// Value: ServiceRoute with service type information (MethodName will be null until resolved)
  /// </summary>
  private static readonly Dictionary<string, ServiceRoute> _serviceRegistry = new(StringComparer.OrdinalIgnoreCase)
    {
        // Employee service mapping
        { "dbo.sp_SmartFormDemo", new ServiceRoute("employee", typeof(Services.EmployeeService), null!, "dbo.sp_SmartFormDemo") },
        
        // Session service mapping
        { "dbo.GetSessionInfoForMVC", new ServiceRoute("session", typeof(Services.SessionService), null!, "dbo.GetSessionInfoForMVC") }
        
        // Add more service mappings here as services are created
        // Example: { "dbo.sp_DepartmentOperations", new ServiceRoute("department", typeof(DepartmentService), null!, "dbo.sp_DepartmentOperations") }
    };

  /// <summary>
  /// Operation to method name mapping: Maps front-end operation names to service method names.
  /// Used to resolve which method to invoke on a service based on the operation requested.
  /// Key: Operation name from front-end (e.g., "select", "insert", "update", "delete") - case-insensitive
  /// Value: Method name on the service class
  /// </summary>
  private static readonly Dictionary<string, string> _operationMethodMap = new(StringComparer.OrdinalIgnoreCase)
    {
        // Standard CRUD operations mapping
        { "select", "GetEmployeeList" },
        { "insert", "CreateEmployee" },
        { "update", "UpdateEmployee" },
        { "delete", "DeleteEmployee" },
        
        // Alternative operation names (if needed)
        { "list", "GetEmployeeList" },
        { "create", "CreateEmployee" },
        { "getById", "GetEmployeeById" },
        
        // Session operations
        { "getInfo", "GetSessionInfo" },
        { "sp", "GetSessionInfo" }  // For generic "sp" operation
        
        // Add more operation mappings as needed
    };

  /// <summary>
  /// Gets the stored procedure name for a given module and operation.
  /// </summary>
  /// <param name="module">The module name (e.g., "employee", "menu")</param>
  /// <param name="operation">The operation name (e.g., "list", "insert")</param>
  /// <returns>The stored procedure name</returns>
  /// <exception cref="InvalidOperationException">Thrown when mapping not found</exception>
  public static string GetProcedureName(string module, string operation)
  {
    var key = $"{module}:{operation}";

    if (_mappings.TryGetValue(key, out var spName))
      return spName;

    throw new InvalidOperationException(
        $"No stored procedure mapping found for '{key}'. " +
        $"Available mappings: {string.Join(", ", _mappings.Keys)}");
  }

  /// <summary>
  /// Gets all available mappings (for debugging/documentation purposes)
  /// </summary>
  public static IReadOnlyDictionary<string, string> GetAllMappings()
      => _mappings;

  /// <summary>
  /// Gets the service route for a given stored procedure name and operation.
  /// This method enables intelligent routing to Application Layer services.
  /// </summary>
  /// <param name="spName">The stored procedure name (e.g., "dbo.sp_SmartFormDemo")</param>
  /// <param name="operation">The operation name from the front-end (e.g., "select", "insert", "update", "delete")</param>
  /// <returns>
  /// A ServiceRoute object with the resolved method name if the SP is registered, 
  /// or null if the SP is not found (enabling fallback to legacy DataEngine path).
  /// </returns>
  /// <remarks>
  /// The lookup process:
  /// 1. Checks if the spName exists in _serviceRegistry (case-insensitive)
  /// 2. If found, looks up the method name in _operationMethodMap using the operation (case-insensitive)
  /// 3. Returns a new ServiceRoute with the resolved method name
  /// 4. Returns null if spName not found (backward compatibility - allows fallback to DataEngine)
  /// 5. Returns ServiceRoute with null MethodName if operation not mapped (will cause invocation error)
  /// </remarks>
  /// <example>
  /// // Example 1: Valid route
  /// var route = GetServiceRoute("dbo.sp_SmartFormDemo", "select");
  /// // Returns: ServiceRoute("employee", typeof(EmployeeService), "GetEmployeeList", "dbo.sp_SmartFormDemo")
  /// 
  /// // Example 2: Unmapped SP (fallback scenario)
  /// var route = GetServiceRoute("dbo.UnknownProcedure", "select");
  /// // Returns: null (controller will use DataEngine fallback)
  /// 
  /// // Example 3: Mapped SP but unmapped operation
  /// var route = GetServiceRoute("dbo.sp_SmartFormDemo", "unknownOp");
  /// // Returns: ServiceRoute with MethodName = null (will fail during invocation)
  /// </example>
  public static ServiceRoute? GetServiceRoute(string? spName, string? operation)
  {
    // Handle null or empty inputs gracefully - return null for fallback
    if (string.IsNullOrWhiteSpace(spName))
      return null;

    // Look up the stored procedure in the service registry
    if (!_serviceRegistry.TryGetValue(spName, out var baseRoute))
    {
      // SP not registered - return null to enable fallback to DataEngine
      return null;
    }

    // Look up the method name for the given operation
    // If operation is null/empty or not found, methodName will be null
    string? methodName = null;
    if (!string.IsNullOrWhiteSpace(operation))
    {
      _operationMethodMap.TryGetValue(operation, out methodName);
    }

    // Return a new ServiceRoute with the resolved method name
    // Note: methodName might be null if operation wasn't mapped
    return new ServiceRoute(
        baseRoute.ServiceName,
        baseRoute.ServiceType,
        methodName!,
        baseRoute.SpName
    );
  }
}
