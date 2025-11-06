using SmartFoundation.Application.Mapping;
using SmartFoundation.Application.Services;
using Xunit;

namespace SmartFoundation.Application.Tests.Mapping;

/// <summary>
/// Unit tests for the ProcedureMapper service routing functionality.
/// Validates the GetServiceRoute method for various scenarios including:
/// - Valid route resolution
/// - Unmapped stored procedures (fallback scenarios)
/// - Case-insensitive lookups
/// - Null/empty input handling
/// - Partially mapped routes (SP found but operation not mapped)
/// </summary>
public class ProcedureMapperTests
{
  /// <summary>
  /// Test: GetServiceRoute returns correct ServiceRoute for a valid, registered SP and operation.
  /// Expected: Non-null ServiceRoute with all properties correctly populated.
  /// </summary>
  [Fact]
  public void GetServiceRoute_ValidSpNameAndOperation_ReturnsCorrectRoute()
  {
    // Arrange
    var spName = "dbo.sp_SmartFormDemo";
    var operation = "select";

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, operation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal("employee", route.ServiceName);
    Assert.Equal(typeof(EmployeeService), route.ServiceType);
    Assert.Equal("GetEmployeeList", route.MethodName);
    Assert.Equal(spName, route.SpName);
  }

  /// <summary>
  /// Test: GetServiceRoute returns null for an unregistered stored procedure name.
  /// Expected: Null return (enables fallback to DataEngine).
  /// </summary>
  [Fact]
  public void GetServiceRoute_UnregisteredSpName_ReturnsNull()
  {
    // Arrange
    var unregisteredSpName = "dbo.UnknownStoredProcedure";
    var operation = "select";

    // Act
    var route = ProcedureMapper.GetServiceRoute(unregisteredSpName, operation);

    // Assert
    Assert.Null(route);
  }

  /// <summary>
  /// Test: GetServiceRoute performs case-insensitive lookup for stored procedure name.
  /// Expected: Correct ServiceRoute returned regardless of casing.
  /// </summary>
  [Theory]
  [InlineData("dbo.sp_SmartFormDemo")]
  [InlineData("DBO.SP_SMARTFORMDEMO")]
  [InlineData("dBo.Sp_SmArTfOrMdEmO")]
  public void GetServiceRoute_CaseInsensitiveSpName_ReturnsCorrectRoute(string spName)
  {
    // Arrange
    var operation = "insert";

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, operation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal("employee", route.ServiceName);
    Assert.Equal(typeof(EmployeeService), route.ServiceType);
    Assert.Equal("CreateEmployee", route.MethodName);
  }

  /// <summary>
  /// Test: GetServiceRoute handles null stored procedure name input gracefully.
  /// Expected: Null return (no exception thrown).
  /// </summary>
  [Fact]
  public void GetServiceRoute_NullSpName_ReturnsNull()
  {
    // Arrange
    string? nullSpName = null;
    var operation = "select";

    // Act
    var route = ProcedureMapper.GetServiceRoute(nullSpName, operation);

    // Assert
    Assert.Null(route);
  }

  /// <summary>
  /// Test: GetServiceRoute handles empty stored procedure name input gracefully.
  /// Expected: Null return.
  /// </summary>
  [Theory]
  [InlineData("")]
  [InlineData("   ")]
  public void GetServiceRoute_EmptySpName_ReturnsNull(string emptySpName)
  {
    // Arrange
    var operation = "select";

    // Act
    var route = ProcedureMapper.GetServiceRoute(emptySpName, operation);

    // Assert
    Assert.Null(route);
  }

  /// <summary>
  /// Test: GetServiceRoute returns ServiceRoute with null MethodName for unmapped operation.
  /// Expected: ServiceRoute returned with correct service info but null MethodName.
  /// </summary>
  [Fact]
  public void GetServiceRoute_ValidSpNameButUnmappedOperation_ReturnsRouteWithNullMethodName()
  {
    // Arrange
    var spName = "dbo.sp_SmartFormDemo";
    var unmappedOperation = "unknownOperation";

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, unmappedOperation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal("employee", route.ServiceName);
    Assert.Equal(typeof(EmployeeService), route.ServiceType);
    Assert.Null(route.MethodName); // Operation not mapped
    Assert.Equal(spName, route.SpName);
  }

  /// <summary>
  /// Test: GetServiceRoute handles null operation input gracefully.
  /// Expected: ServiceRoute returned with null MethodName.
  /// </summary>
  [Fact]
  public void GetServiceRoute_NullOperation_ReturnsRouteWithNullMethodName()
  {
    // Arrange
    var spName = "dbo.sp_SmartFormDemo";
    string? nullOperation = null;

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, nullOperation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal("employee", route.ServiceName);
    Assert.Null(route.MethodName);
  }

  /// <summary>
  /// Test: GetServiceRoute performs case-insensitive lookup for operation.
  /// Expected: Correct method name resolved regardless of casing.
  /// </summary>
  [Theory]
  [InlineData("select", "GetEmployeeList")]
  [InlineData("SELECT", "GetEmployeeList")]
  [InlineData("SeLeCt", "GetEmployeeList")]
  [InlineData("insert", "CreateEmployee")]
  [InlineData("INSERT", "CreateEmployee")]
  [InlineData("update", "UpdateEmployee")]
  [InlineData("UPDATE", "UpdateEmployee")]
  [InlineData("delete", "DeleteEmployee")]
  [InlineData("DELETE", "DeleteEmployee")]
  public void GetServiceRoute_CaseInsensitiveOperation_ReturnsCorrectMethodName(string operation, string expectedMethodName)
  {
    // Arrange
    var spName = "dbo.sp_SmartFormDemo";

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, operation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal(expectedMethodName, route.MethodName);
  }

  /// <summary>
  /// Test: GetServiceRoute handles alternative operation names.
  /// Expected: Correct method name resolved for alternative operations like "list", "create".
  /// </summary>
  [Theory]
  [InlineData("list", "GetEmployeeList")]
  [InlineData("create", "CreateEmployee")]
  [InlineData("getById", "GetEmployeeById")]
  public void GetServiceRoute_AlternativeOperations_ReturnsCorrectMethodName(string operation, string expectedMethodName)
  {
    // Arrange
    var spName = "dbo.sp_SmartFormDemo";

    // Act
    var route = ProcedureMapper.GetServiceRoute(spName, operation);

    // Assert
    Assert.NotNull(route);
    Assert.Equal(expectedMethodName, route.MethodName);
  }
}
