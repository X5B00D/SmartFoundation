using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using System.Text.Json;

namespace SmartFoundation.Application.Tests.Services;

public class DashboardServiceTests
{
  private readonly Mock<ISmartComponentService> _mockDataEngine;
  private readonly Mock<ILogger<DashboardService>> _mockLogger;
  private readonly DashboardService _service;

  public DashboardServiceTests()
  {
    _mockDataEngine = new Mock<ISmartComponentService>();
    _mockLogger = new Mock<ILogger<DashboardService>>();
    _service = new DashboardService(_mockDataEngine.Object, _mockLogger.Object);
  }

  [Fact]
  public async Task GetDashboardSummary_ReturnsMetrics()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
          Success = true,
          Data = new List<Dictionary<string, object?>>
            {
                    new()
                    {
                        { "TotalEmployees", 150 },
                        { "ActiveProjects", 12 },
                        { "Revenue", 500000.00m }
                    }
            }
        });

    var parameters = new Dictionary<string, object?>();

    // Act
    var result = await _service.GetDashboardSummary(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());

    var data = json.RootElement.GetProperty("data");
    Assert.True(data.GetArrayLength() > 0);
    Assert.Equal(150, data[0].GetProperty("TotalEmployees").GetInt32());
  }

  [Fact]
  public async Task GetDashboardSummary_WithDateRange_ReturnsFilteredMetrics()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
          Success = true,
          Data = new List<Dictionary<string, object?>>
            {
                    new()
                    {
                        { "Period", "Q1 2025" },
                        { "Revenue", 125000.00m },
                        { "NewCustomers", 45 }
                    }
            }
        });

    var parameters = new Dictionary<string, object?>
        {
            { "dateFrom", new DateTime(2025, 1, 1) },
            { "dateTo", new DateTime(2025, 3, 31) }
        };

    // Act
    var result = await _service.GetDashboardSummary(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());

    var data = json.RootElement.GetProperty("data");
    Assert.True(data.GetArrayLength() > 0);
  }

  [Fact]
  public async Task GetDashboardSummary_WithError_ReturnsErrorResponse()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ThrowsAsync(new Exception("Database timeout"));

    var parameters = new Dictionary<string, object?>();

    // Act
    var result = await _service.GetDashboardSummary(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.False(json.RootElement.GetProperty("success").GetBoolean());
    Assert.Contains("Database timeout",
        json.RootElement.GetProperty("message").GetString());
  }

  [Fact]
  public async Task GetDashboardSummary_WithUserId_ReturnsPersonalizedData()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
          Success = true,
          Data = new List<Dictionary<string, object?>>
            {
                    new()
                    {
                        { "UserId", 123 },
                        { "MyTasks", 8 },
                        { "MyProjects", 3 }
                    }
            }
        });

    var parameters = new Dictionary<string, object?>
        {
            { "userId", 123 }
        };

    // Act
    var result = await _service.GetDashboardSummary(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());
  }
}
