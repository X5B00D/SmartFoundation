using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using System.Text.Json;

namespace SmartFoundation.Application.Tests.Services;

public class MenuServiceTests
{
  private readonly Mock<ISmartComponentService> _mockDataEngine;
  private readonly Mock<ILogger<MastersServies>> _mockLogger;
  private readonly MastersServies _service;

  public MenuServiceTests()
  {
    _mockDataEngine = new Mock<ISmartComponentService>();
    _mockLogger = new Mock<ILogger<MastersServies>>();
    _service = new MastersServies(_mockDataEngine.Object, _mockLogger.Object);
  }

  [Fact]
  public async Task GetUserMenu_WithValidUserId_ReturnsSuccessJson()
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
                        { "MenuId", 1 },
                        { "Title", "Dashboard" },
                        { "Url", "/dashboard" },
                        { "ParentId", null }
                    },
                    new()
                    {
                        { "MenuId", 2 },
                        { "Title", "Employees" },
                        { "Url", "/employees" },
                        { "ParentId", null }
                    }
            }
        });

    var parameters = new Dictionary<string, object?>
        {
            { "userId", 123 }
        };

    // Act
    var result = await _service.GetUserMenu(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());

    var data = json.RootElement.GetProperty("data");
    Assert.True(data.GetArrayLength() == 2);
  }

  [Fact]
  public async Task GetUserMenu_WithInvalidUserId_ReturnsEmptyData()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
          Success = true,
          Data = new List<Dictionary<string, object?>>() // Empty list
        });

    var parameters = new Dictionary<string, object?>
        {
            { "userId", -1 }
        };

    // Act
    var result = await _service.GetUserMenu(parameters);    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());

    var data = json.RootElement.GetProperty("data");
    Assert.True(data.GetArrayLength() == 0);
  }

  [Fact]
  public async Task GetUserMenu_WithDatabaseError_ReturnsErrorJson()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ThrowsAsync(new Exception("Database connection failed"));

    var parameters = new Dictionary<string, object?>
        {
            { "userId", 123 }
        };

    // Act
    var result = await _service.GetUserMenu(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.False(json.RootElement.GetProperty("success").GetBoolean());
    Assert.Contains("Database connection failed",
        json.RootElement.GetProperty("message").GetString());
  }

  [Fact]
  public async Task GetAllMenus_ReturnsAllMenuItems()
  {
    // Arrange
    _mockDataEngine
        .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
        .ReturnsAsync(new SmartResponse
        {
          Success = true,
          Data = new List<Dictionary<string, object?>>
            {
                    new() { { "MenuId", 1 }, { "Title", "Menu1" } },
                    new() { { "MenuId", 2 }, { "Title", "Menu2" } },
                    new() { { "MenuId", 3 }, { "Title", "Menu3" } }
            }
        });

    var parameters = new Dictionary<string, object?>();    // Act
    var result = await _service.GetAllMenus(parameters);

    // Assert
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());
    Assert.Equal(3, json.RootElement.GetProperty("data").GetArrayLength());
  }

  [Fact]
  public async Task GetUserMenu_WithMultipleRoles_ReturnsFilteredMenu()
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
                        { "MenuId", 1 },
                        { "Title", "Admin Panel" },
                        { "RequiresRole", "Admin" },
                        { "Url", "/admin" }
                    }
            }
        });

    var parameters = new Dictionary<string, object?>
        {
            { "userId", 123 },
            { "roleId", 1 }
        };

    // Act
    var result = await _service.GetUserMenu(parameters);

    // Assert
    Assert.NotNull(result);
    var json = JsonDocument.Parse(result);
    Assert.True(json.RootElement.GetProperty("success").GetBoolean());

    var data = json.RootElement.GetProperty("data");
    Assert.True(data.GetArrayLength() > 0);

    // Verify the menu item has role requirement
    var firstItem = data[0];
    Assert.Equal("Admin Panel", firstItem.GetProperty("Title").GetString());
    Assert.Equal("Admin", firstItem.GetProperty("RequiresRole").GetString());
  }
}
