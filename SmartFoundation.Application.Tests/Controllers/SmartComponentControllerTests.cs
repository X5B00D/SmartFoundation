using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.Mvc.Controllers;
using Xunit;

namespace SmartFoundation.Application.Tests.Controllers
{
  /// <summary>
  /// Unit tests for SmartComponentController to validate intelligent routing logic,
  /// Application Layer integration, and legacy DataEngine fallback behavior.
  /// </summary>
  public class SmartComponentControllerTests
  {
    private readonly Mock<ISmartComponentService> _mockDataEngine;
    private readonly Mock<IServiceProvider> _mockServiceProvider;
    private readonly Mock<ILogger<SmartComponentController>> _mockLogger;
    private readonly SmartComponentController _controller;

    /// <summary>
    /// Constructor to initialize mocks and System Under Test (SUT).
    /// </summary>
    public SmartComponentControllerTests()
    {
      // Initialize mocks for all dependencies
      _mockDataEngine = new Mock<ISmartComponentService>();
      _mockServiceProvider = new Mock<IServiceProvider>();
      _mockLogger = new Mock<ILogger<SmartComponentController>>();

      // Create the controller with mocked dependencies
      _controller = new SmartComponentController(
          _mockDataEngine.Object,
          _mockServiceProvider.Object,
          _mockLogger.Object
      );
    }

    /// <summary>
    /// Tests that when ProcedureMapper returns a valid route, the controller correctly
    /// resolves the service from DI, invokes the method via reflection, and returns
    /// an OkObjectResult containing a SmartResponse.
    /// </summary>
    [Fact]
    public async Task Execute_WithValidServiceRoute_InvokesApplicationService()
    {
      // Arrange
      // Use a real SP name and operation that are mapped in ProcedureMapper
      var request = new SmartRequest
      {
        SpName = "dbo.sp_SmartFormDemo",
        Operation = "select",
        Params = new Dictionary<string, object?>
                {
                    { "pageNumber", 1 },
                    { "pageSize", 10 }
                }
      };

      // Create a mock for the ISmartComponentService (used by EmployeeService internally)
      var mockEmployeeDataEngine = new Mock<ISmartComponentService>();
      var mockEmployeeLogger = new Mock<ILogger<EmployeeService>>();

      // Setup the data engine to return a successful SmartResponse
      var expectedDataEngineResponse = new SmartResponse
      {
        Success = true,
        Data = new List<Dictionary<string, object?>>
                {
                    new Dictionary<string, object?>
                    {
                        { "id", 1 },
                        { "name", "John Doe" }
                    }
                },
        Message = "Success"
      };

      mockEmployeeDataEngine
          .Setup(de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()))
          .ReturnsAsync(expectedDataEngineResponse);

      // Create a REAL EmployeeService with mocked dependencies
      var realEmployeeService = new EmployeeService(
          mockEmployeeDataEngine.Object,
          mockEmployeeLogger.Object
      );

      // Setup IServiceProvider to return our real EmployeeService
      _mockServiceProvider
          .Setup(sp => sp.GetService(typeof(EmployeeService)))
          .Returns(realEmployeeService);

      // Act
      var result = await _controller.Execute(request, CancellationToken.None);

      // Assert
      // 1. Verify result is OkObjectResult
      Assert.IsType<OkObjectResult>(result.Result);
      var okResult = result.Result as OkObjectResult;
      Assert.NotNull(okResult);

      // 2. Verify the value is a SmartResponse
      Assert.IsType<SmartResponse>(okResult!.Value);
      var response = okResult.Value as SmartResponse;
      Assert.NotNull(response);

      // 3. Verify the SmartResponse properties
      Assert.True(response!.Success);
      Assert.NotNull(response.Data);
      Assert.Equal("Success", response.Message);

      // 4. Verify the employee data engine was called (indirectly through EmployeeService)
      mockEmployeeDataEngine.Verify(
          de => de.ExecuteAsync(
              It.Is<SmartRequest>(r => r.SpName == "dbo.sp_SmartFormDemo" && r.Operation == "sp"),
              It.IsAny<CancellationToken>()
          ),
          Times.Once,
          "EmployeeService should have called the data engine with the correct stored procedure"
      );

      // 5. Verify the controller's DataEngine was NOT called (Application Layer path was used)
      _mockDataEngine.Verify(
          de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()),
          Times.Never,
          "Controller should use Application Layer service, not fallback to DataEngine"
      );
    }

    /// <summary>
    /// Tests that when ProcedureMapper does not find a route (returns null),
    /// the controller correctly falls back to the legacy DataEngine path.
    /// </summary>
    [Fact]
    public async Task Execute_WithNullServiceRoute_InvokesLegacyDataEngine()
    {
      // Arrange
      // Use an unmapped SP name that won't be found in ProcedureMapper
      var request = new SmartRequest
      {
        SpName = "dbo.UnmappedStoredProcedure",
        Operation = "select",
        Params = new Dictionary<string, object?>
                {
                    { "id", 123 }
                }
      };

      // Setup the DataEngine to return a successful SmartResponse
      var expectedResponse = new SmartResponse
      {
        Success = true,
        Data = new List<Dictionary<string, object?>>
                {
                    new Dictionary<string, object?>
                    {
                        { "id", 123 },
                        { "legacyData", "From DataEngine" }
                    }
                },
        Message = "Legacy DataEngine Success"
      };

      _mockDataEngine
          .Setup(de => de.ExecuteAsync(
              It.Is<SmartRequest>(r => r.SpName == "dbo.UnmappedStoredProcedure"),
              It.IsAny<CancellationToken>()
          ))
          .ReturnsAsync(expectedResponse);

      // Act
      var result = await _controller.Execute(request, CancellationToken.None);

      // Assert
      // 1. Verify result is OkObjectResult
      Assert.IsType<OkObjectResult>(result.Result);
      var okResult = result.Result as OkObjectResult;
      Assert.NotNull(okResult);

      // 2. Verify the value is a SmartResponse
      Assert.IsType<SmartResponse>(okResult!.Value);
      var response = okResult.Value as SmartResponse;
      Assert.NotNull(response);

      // 3. Verify the SmartResponse matches the DataEngine response exactly
      Assert.True(response!.Success);
      Assert.Equal("Legacy DataEngine Success", response.Message);
      Assert.NotNull(response.Data);
      Assert.Single(response.Data);
      Assert.Equal(123, response.Data[0]["id"]);
      Assert.Equal("From DataEngine", response.Data[0]["legacyData"]);

      // 4. Verify DataEngine.ExecuteAsync was called exactly once
      _mockDataEngine.Verify(
          de => de.ExecuteAsync(
              It.Is<SmartRequest>(r => r.SpName == "dbo.UnmappedStoredProcedure" && r.Operation == "select"),
              It.IsAny<CancellationToken>()
          ),
          Times.Once,
          "Controller should fallback to DataEngine for unmapped stored procedures"
      );

      // 5. Verify IServiceProvider was NOT used (no Application Layer service resolution)
      _mockServiceProvider.Verify(
          sp => sp.GetService(It.IsAny<Type>()),
          Times.Never,
          "Controller should not attempt service resolution for unmapped SPs"
      );
    }

    /// <summary>
    /// Tests that when ProcedureMapper returns a valid route but the IServiceProvider
    /// fails to resolve the service, the controller returns a 500 error response.
    /// </summary>
    [Fact]
    public async Task Execute_WhenServiceNotResolved_ReturnsErrorResponse()
    {
      // Arrange
      // Use a valid SP name that IS mapped in ProcedureMapper
      var request = new SmartRequest
      {
        SpName = "dbo.sp_SmartFormDemo",
        Operation = "select",
        Params = new Dictionary<string, object?>()
      };

      // Setup IServiceProvider to throw InvalidOperationException when GetRequiredService is called
      // This simulates the service not being registered in DI
      _mockServiceProvider
          .Setup(sp => sp.GetService(typeof(EmployeeService)))
          .Throws(new InvalidOperationException("Service not registered"));

      // Act
      var result = await _controller.Execute(request, CancellationToken.None);

      // Assert
      // 1. Verify result is ObjectResult with status code 500
      Assert.IsType<ObjectResult>(result.Result);
      var objectResult = result.Result as ObjectResult;
      Assert.NotNull(objectResult);
      Assert.Equal(500, objectResult!.StatusCode);

      // 2. Verify the value is a SmartResponse with error information
      Assert.IsType<SmartResponse>(objectResult.Value);
      var response = objectResult.Value as SmartResponse;
      Assert.NotNull(response);

      // 3. Verify the error response properties
      Assert.False(response!.Success);
      Assert.Contains("Service resolution failed", response.Message);
      Assert.Contains("Service not registered", response.Message);

      // 4. Verify DataEngine was NOT called (error occurred before fallback)
      _mockDataEngine.Verify(
          de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()),
          Times.Never,
          "DataEngine should not be called when service resolution fails"
      );
    }

    /// <summary>
    /// Tests that when a service method throws an exception during invocation,
    /// the BaseService catches it and returns a JSON error response, which the
    /// controller successfully deserializes and returns as an OkObjectResult
    /// with Success=false.
    /// </summary>
    [Fact]
    public async Task Execute_WhenServiceMethodThrowsException_ReturnsErrorResponse()
    {
      // Arrange
      // Use a valid SP name and operation that are mapped
      var request = new SmartRequest
      {
        SpName = "dbo.sp_SmartFormDemo",
        Operation = "select",
        Params = new Dictionary<string, object?>
                {
                    { "pageNumber", 1 },
                    { "pageSize", 10 }
                }
      };

      // Create a mock data engine that throws an exception
      var mockEmployeeDataEngine = new Mock<ISmartComponentService>();
      var mockEmployeeLogger = new Mock<ILogger<EmployeeService>>();

      // Setup the data engine to throw an exception when ExecuteAsync is called
      mockEmployeeDataEngine
          .Setup(de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()))
          .ThrowsAsync(new InvalidOperationException("Database connection failed"));

      // Create a real EmployeeService that will catch the exception and return error JSON
      var realEmployeeService = new EmployeeService(
          mockEmployeeDataEngine.Object,
          mockEmployeeLogger.Object
      );

      // Setup IServiceProvider to return the real EmployeeService
      _mockServiceProvider
          .Setup(sp => sp.GetService(typeof(EmployeeService)))
          .Returns(realEmployeeService);

      // Act
      var result = await _controller.Execute(request, CancellationToken.None);

      // Assert
      // 1. Verify result is OkObjectResult (BaseService handled the error gracefully)
      Assert.IsType<OkObjectResult>(result.Result);
      var okResult = result.Result as OkObjectResult;
      Assert.NotNull(okResult);

      // 2. Verify the value is a SmartResponse
      Assert.IsType<SmartResponse>(okResult!.Value);
      var response = okResult.Value as SmartResponse;
      Assert.NotNull(response);

      // 3. Verify the error response properties - Success should be false
      Assert.False(response!.Success);
      Assert.Contains("Error", response.Message);
      Assert.Contains("Database connection failed", response.Message);

      // 4. Verify the employee data engine WAS called (exception occurred during invocation)
      mockEmployeeDataEngine.Verify(
          de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()),
          Times.Once,
          "Service method should have been invoked, causing the data engine to be called"
      );

      // 5. Verify the controller's DataEngine was NOT called (Application Layer was used)
      _mockDataEngine.Verify(
          de => de.ExecuteAsync(It.IsAny<SmartRequest>(), It.IsAny<CancellationToken>()),
          Times.Never,
          "Controller should not fallback to DataEngine when service method throws"
      );
    }
  }
}
