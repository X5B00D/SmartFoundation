using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing user session-related operations.
/// Handles retrieval and management of user session data.
/// </summary>
public class SessionService : BaseService
{
  /// <summary>
  /// Constructor for SessionService.
  /// </summary>
  /// <param name="dataEngine">DataEngine service injected via DI</param>
  /// <param name="logger">Logger instance specific to SessionService</param>
  public SessionService(
      ISmartComponentService dataEngine,
      ILogger<SessionService> logger)
      : base(dataEngine, logger)
  {
  }

  /// <summary>
  /// Retrieves session information for a specific user.
  /// Gets user details including name, department, photo, theme preferences, etc.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing request parameters:
  /// - UserID (int, required): User identifier to retrieve session info for
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (object): User session object with fullName, userID, DepartmentName, Photo, ThemeName, DeptCode
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// <code>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "UserID", 60014019 }
  /// };
  /// var result = await sessionService.GetSessionInfo(parameters);
  /// </code>
  /// </example>
  public async Task<string> GetSessionInfo(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("session", "getInfo", parameters);
  }
}
