using System.Text.Json;
using Microsoft.Extensions.Logging;
using Moq;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using Xunit;

namespace SmartFoundation.Application.Tests.Services;

public class EmployeeServiceTests
{
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<ILogger<EmployeeService>> _mockLogger;
    private readonly EmployeeService _service;

    public EmployeeServiceTests()
    {
        _mockDataEngine = new Mock<ISmartComponentService>();
        _mockLogger = new Mock<ILogger<EmployeeService>>();
        _service = new EmployeeService(_mockDataEngine.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task GetEmployeeList_WithValidParams_ReturnsSuccessJson()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>
                {
                    new() { { "Id", 1 }, { "Name", "John Doe" }, { "Email", "john@test.com" } },
                    new() { { "Id", 2 }, { "Name", "Jane Smith" }, { "Email", "jane@test.com" } }
                }
            });

        var parameters = new Dictionary<string, object?>
        {
            { "pageNumber", 1 },
            { "pageSize", 10 }
        };

        // Act
        var result = await _service.GetEmployeeList(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());

        var data = json.RootElement.GetProperty("data");
        Assert.True(data.GetArrayLength() == 2);
    }

    [Fact]
    public async Task GetEmployeeList_WithError_ReturnsErrorJson()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ThrowsAsync(new Exception("Database connection failed"));

        var parameters = new Dictionary<string, object?>
        {
            { "pageNumber", 1 },
            { "pageSize", 10 }
        };

        // Act
        var result = await _service.GetEmployeeList(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("Database connection failed",
            json.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task GetEmployeeById_WithValidId_ReturnsSuccess()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.Is<SmartRequest>(req =>
                    req.Operation == "sp" &&
                    req.SpName == "dbo.sp_SmartFormDemo" &&
                    req.Params != null &&
                    req.Params.ContainsKey("employeeId")),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>
              {
              new()
              {
                  { "Id", 42 },
                  { "FirstName", "John" },
                  { "LastName", "Doe" },
                  { "Email", "john.doe@company.com" },
                  { "DepartmentId", 5 },
                  { "HireDate", DateTime.Parse("2020-01-15") }
              }
              },
                Message = "Employee retrieved successfully"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 42 }
    };

        // Act
        var result = await _service.GetEmployeeById(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Equal("Employee retrieved successfully",
            json.RootElement.GetProperty("message").GetString());

        var data = json.RootElement.GetProperty("data");
        Assert.True(data.GetArrayLength() == 1);
        Assert.Equal(42, data[0].GetProperty("Id").GetInt32());
        Assert.Equal("John", data[0].GetProperty("FirstName").GetString());

        _mockDataEngine.Verify(x => x.ExecuteAsync(
            It.Is<SmartRequest>(req =>
                req.SpName == "dbo.sp_SmartFormDemo" &&
                req.Params != null &&
                req.Params.ContainsKey("employeeId")),
            default), Times.Once);
    }

    [Fact]
    public async Task GetEmployeeById_WithInvalidId_ReturnsError()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.IsAny<SmartRequest>(),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = false,
                Data = new List<Dictionary<string, object?>>(),
                Message = "Employee not found"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 99999 }
    };

        // Act
        var result = await _service.GetEmployeeById(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("not found",
            json.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task CreateEmployee_WithValidData_ReturnsSuccess()
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
                        { "Id", 100 },
                        { "FirstName", "John" },
                        { "LastName", "Doe" },
                        { "Email", "john.doe@company.com" }
                    }
                }
            });

        var parameters = new Dictionary<string, object?>
        {
            { "firstName", "John" },
            { "lastName", "Doe" },
            { "email", "john.doe@company.com" },
            { "departmentId", 5 },
            { "hireDate", DateTime.Now }
        };

        // Act
        var result = await _service.CreateEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());

        var data = json.RootElement.GetProperty("data");
        Assert.True(data.GetArrayLength() > 0);
        Assert.Equal(100, data[0].GetProperty("Id").GetInt32());
    }

    [Fact]
    public async Task CreateEmployee_WithMissingRequiredFields_ReturnsError()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(It.IsAny<SmartRequest>(), default))
            .ThrowsAsync(new Exception("Required field missing: email"));

        var parameters = new Dictionary<string, object?>
        {
            { "firstName", "John" },
            { "lastName", "Doe" }
            // Missing email - should fail
        };

        // Act
        var result = await _service.CreateEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("Required field",
            json.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task UpdateEmployee_WithValidData_ReturnsSuccess()
    {
        // Arrange
        var updateData = new List<Dictionary<string, object?>>
    {
        new()
        {
            { "employeeId", 42 },
            { "firstName", "Jane" },
            { "lastName", "Smith" },
            { "email", "jane.smith@company.com" }
        }
    };

        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.Is<SmartRequest>(req =>
                    req.Operation == "sp" &&
                    req.SpName == "dbo.sp_SmartFormDemo" &&
                    req.Params != null &&
                    req.Params.ContainsKey("employeeId")),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = updateData,
                Message = "Employee updated successfully"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 42 },
        { "firstName", "Jane" },
        { "lastName", "Smith" },
        { "email", "jane.smith@company.com" }
    };

        // Act
        var result = await _service.UpdateEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Equal("Employee updated successfully",
            json.RootElement.GetProperty("message").GetString());

        _mockDataEngine.Verify(x => x.ExecuteAsync(
            It.Is<SmartRequest>(req =>
                req.SpName == "dbo.sp_SmartFormDemo" &&
                req.Params != null &&
                req.Params.ContainsKey("employeeId")),
            default), Times.Once);
    }

    [Fact]
    public async Task UpdateEmployee_WithInvalidId_ReturnsError()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.IsAny<SmartRequest>(),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = false,
                Data = new List<Dictionary<string, object?>>(),
                Message = "Employee not found"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 99999 },
        { "firstName", "John" }
    };

        // Act
        var result = await _service.UpdateEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("not found",
            json.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task DeleteEmployee_WithValidId_ReturnsSuccess()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.Is<SmartRequest>(req =>
                    req.Operation == "sp" &&
                    req.SpName == "dbo.sp_SmartFormDemo" &&
                    req.Params != null &&
                    req.Params.ContainsKey("employeeId")),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = true,
                Data = new List<Dictionary<string, object?>>(),
                Message = "Employee deleted successfully"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 42 }
    };

        // Act
        var result = await _service.DeleteEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.True(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Equal("Employee deleted successfully",
            json.RootElement.GetProperty("message").GetString());

        _mockDataEngine.Verify(x => x.ExecuteAsync(
            It.Is<SmartRequest>(req =>
                req.SpName == "dbo.sp_SmartFormDemo" &&
                req.Params != null &&
                req.Params.ContainsKey("employeeId")),
            default), Times.Once);
    }

    [Fact]
    public async Task DeleteEmployee_WithNonExistentId_ReturnsError()
    {
        // Arrange
        _mockDataEngine
            .Setup(x => x.ExecuteAsync(
                It.IsAny<SmartRequest>(),
                default))
            .ReturnsAsync(new SmartResponse
            {
                Success = false,
                Data = new List<Dictionary<string, object?>>(),
                Message = "Employee not found"
            });

        var parameters = new Dictionary<string, object?>
    {
        { "employeeId", 99999 }
    };

        // Act
        var result = await _service.DeleteEmployee(parameters);

        // Assert
        Assert.NotNull(result);
        var json = JsonDocument.Parse(result);
        Assert.False(json.RootElement.GetProperty("success").GetBoolean());
        Assert.Contains("not found",
            json.RootElement.GetProperty("message").GetString());
    }
}
