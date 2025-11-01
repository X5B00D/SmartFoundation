using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for dashboard data aggregation and metrics.
/// Provides summary statistics and key performance indicators.
/// MANDATORY: Inherits from BaseService
/// </summary>
public class DashboardService : BaseService
{
  /// <summary>
  /// Constructor for DashboardService.
  /// </summary>
  /// <param name="dataEngine">DataEngine service injected via DI</param>
  /// <param name="logger">Logger instance specific to DashboardService</param>
  public DashboardService(
      ISmartComponentService dataEngine,
      ILogger<DashboardService> logger)
      : base(dataEngine, logger)
  {
  }

  /// <summary>
  /// Retrieves summary metrics for the dashboard.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing request parameters:
  /// - userId (int, optional): User ID for personalized dashboard
  /// - dateFrom (DateTime, optional): Start date for metrics
  /// - dateTo (DateTime, optional): End date for metrics
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (object): Dashboard metrics including employee count, revenue, active projects, etc.
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "userId", 123 },
  ///     { "dateFrom", new DateTime(2025, 1, 1) },
  ///     { "dateTo", new DateTime(2025, 12, 31) }
  /// };
  /// var result = await dashboardService.GetDashboardSummary(parameters);
  /// </example>
  public async Task<string> GetDashboardSummary(Dictionary<string, object?> parameters)
  {
    // Use base class method - no hard-coded SP names!
    return await ExecuteOperation("dashboard", "summary", parameters);
  }
}
