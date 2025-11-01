namespace SmartFoundation.Application.Mapping;

/// <summary>
/// Centralized mapping of business operations to stored procedure names.
/// This eliminates hard-coded SP names throughout the application.
/// </summary>
public static class ProcedureMapper
{
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
        
        // Demo operations
        { "demo:getData", "dbo.sp_GetDemoData" },
        { "demo:saveForm", "dbo.sp_SaveDemoForm" },
        
        // Pakistani operations (from existing controller)
        { "pakistani:getData", "dbo.sp_SmartFormDemo" }
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
}
