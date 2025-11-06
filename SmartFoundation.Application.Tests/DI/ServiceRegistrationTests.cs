using Microsoft.Extensions.DependencyInjection;
using Moq;
using SmartFoundation.Application.Extensions;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using Xunit;

namespace SmartFoundation.Application.Tests.DI;

/// <summary>
/// Unit tests to verify that Application Layer services are correctly registered in the DI container.
/// This validates Task 1 implementation.
/// </summary>
public class ServiceRegistrationTests
{
  /// <summary>
  /// Verifies that EmployeeService is registered in the DI container.
  /// </summary>
  [Fact]
  public void AddApplicationServices_RegistersEmployeeService_Successfully()
  {
    // Arrange
    var services = new ServiceCollection();

    // Mock the ISmartComponentService dependency
    var mockDataEngine = new Mock<ISmartComponentService>();
    services.AddSingleton(mockDataEngine.Object);

    // Act - Call the extension method
    services.AddApplicationServices();

    // Assert - Verify EmployeeService is registered
    var employeeServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(EmployeeService));
    Assert.NotNull(employeeServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, employeeServiceDescriptor.Lifetime);
  }

  /// <summary>
  /// Verifies that MenuService is registered in the DI container.
  /// </summary>
  [Fact]
  public void AddApplicationServices_RegistersMenuService_Successfully()
  {
    // Arrange
    var services = new ServiceCollection();

    // Mock the ISmartComponentService dependency
    var mockDataEngine = new Mock<ISmartComponentService>();
    services.AddSingleton(mockDataEngine.Object);

    // Act
    services.AddApplicationServices();

    // Assert
    var menuServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(MenuService));
    Assert.NotNull(menuServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, menuServiceDescriptor.Lifetime);
  }

  /// <summary>
  /// Verifies that DashboardService is registered in the DI container.
  /// </summary>
  [Fact]
  public void AddApplicationServices_RegistersDashboardService_Successfully()
  {
    // Arrange
    var services = new ServiceCollection();

    // Mock the ISmartComponentService dependency
    var mockDataEngine = new Mock<ISmartComponentService>();
    services.AddSingleton(mockDataEngine.Object);

    // Act
    services.AddApplicationServices();

    // Assert
    var dashboardServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(DashboardService));
    Assert.NotNull(dashboardServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, dashboardServiceDescriptor.Lifetime);
  }

  /// <summary>
  /// Verifies that all services are registered with scoped lifetime.
  /// </summary>
  [Fact]
  public void AddApplicationServices_RegistersServicesWithScopedLifetime()
  {
    // Arrange
    var services = new ServiceCollection();

    // Mock the ISmartComponentService dependency
    var mockDataEngine = new Mock<ISmartComponentService>();
    services.AddSingleton(mockDataEngine.Object);

    // Act
    services.AddApplicationServices();

    // Assert
    var employeeServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(EmployeeService));
    Assert.NotNull(employeeServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, employeeServiceDescriptor.Lifetime);

    var menuServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(MenuService));
    Assert.NotNull(menuServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, menuServiceDescriptor.Lifetime);

    var dashboardServiceDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(DashboardService));
    Assert.NotNull(dashboardServiceDescriptor);
    Assert.Equal(ServiceLifetime.Scoped, dashboardServiceDescriptor.Lifetime);
  }
}
