using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing menu-related operations.
/// Handles user-specific menu retrieval and menu data operations.
/// MANDATORY: Inherits from BaseService
/// </summary>
public class MenuService : BaseService
{
  /// <summary>
  /// Constructor for MenuService.
  /// </summary>
  /// <param name="dataEngine">DataEngine service injected via DI</param>
  /// <param name="logger">Logger instance specific to MenuService</param>
  public MenuService(
      ISmartComponentService dataEngine,
      ILogger<MenuService> logger)
      : base(dataEngine, logger)
  {
  }

  /// <summary>
  /// Retrieves menu items for a specific user.
  /// Returns hierarchical menu structure for navigation.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing request parameters:
  /// - userId (int, required): User ID to retrieve menu for
  /// - roleId (int, optional): Role ID for role-based filtering
  /// - includeHidden (bool, optional): Whether to include hidden menu items (default: false)
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (array): List of menu item objects with hierarchical structure
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt;
  /// {
  ///     { "userId", 123 },
  ///     { "roleId", 5 }
  /// };
  /// var result = await menuService.GetUserMenu(parameters);
  /// </example>
  public async Task<string> GetUserMenu(Dictionary<string, object?> parameters)
  {
    // Use base class method - no hard-coded SP names!
    return await ExecuteOperation("menu", "list", parameters);
  }

  /// <summary>
  /// Retrieves all available menu items (admin function).
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing request parameters:
  /// - includeInactive (bool, optional): Include inactive menu items (default: false)
  /// </param>
  /// <returns>JSON string with all menu items</returns>
  public async Task<string> GetAllMenus(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("menu", "listAll", parameters);
  }
}
