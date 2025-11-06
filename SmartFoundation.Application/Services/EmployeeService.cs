using Microsoft.Extensions.Logging;
using SmartFoundation.DataEngine.Core.Interfaces;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Service for managing employee-related operations.
/// Handles CRUD operations and employee data retrieval.
/// MANDATORY: Inherits from BaseService
/// </summary>
public class EmployeeService : BaseService
{
  /// <summary>
  /// Constructor for EmployeeService.
  /// </summary>
  /// <param name="dataEngine">DataEngine service injected via DI</param>
  /// <param name="logger">Logger instance specific to EmployeeService</param>
  public EmployeeService(
      ISmartComponentService dataEngine,
      ILogger<EmployeeService> logger)
      : base(dataEngine, logger)
  {
  }

  /// <summary>
  /// Retrieves a paginated list of employees with optional search filtering.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing request parameters:
  /// - pageNumber (int, required): Page number to retrieve (1-based)
  /// - pageSize (int, required): Number of records per page
  /// - searchTerm (string, optional): Text to search in name, email, or phone
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (array): List of employee objects
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "pageNumber", 1 },
  ///     { "pageSize", 10 },
  ///     { "searchTerm", "john" }
  /// };
  /// var result = await employeeService.GetEmployeeList(parameters);
  /// </example>
  public async Task<string> GetEmployeeList(Dictionary<string, object?> parameters)
  {
    // Use base class method - no hard-coded SP names!
    return await ExecuteOperation("employee", "list", parameters);
  }

  /// <summary>
  /// Retrieves a single employee record by their unique identifier.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing:
  /// - employeeId (int, required): Unique identifier of the employee to retrieve
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (object): Employee object with all details, or null if not found
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "employeeId", 42 }
  /// };
  /// var result = await employeeService.GetEmployeeById(parameters);
  /// </example>
  public async Task<string> GetEmployeeById(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("employee", "getById", parameters);
  }

  /// <summary>
  /// Creates a new employee record in the database.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing employee data:
  /// - firstName (string, required): Employee's first name
  /// - lastName (string, required): Employee's last name
  /// - email (string, required): Employee's email address
  /// - phone (string, optional): Employee's phone number
  /// - departmentId (int, required): Department ID
  /// - salary (decimal, optional): Employee's salary
  /// - hireDate (DateTime, required): Date of hire
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether creation succeeded
  /// - data (object): Created employee object with ID
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "firstName", "John" },
  ///     { "lastName", "Doe" },
  ///     { "email", "john.doe@company.com" },
  ///     { "departmentId", 5 },
  ///     { "hireDate", DateTime.Now }
  /// };
  /// var result = await employeeService.CreateEmployee(parameters);
  /// </example>
  public async Task<string> CreateEmployee(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("employee", "insert", parameters);
  }

  /// <summary>
  /// Updates an existing employee record in the database.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing employee update data:
  /// - employeeId (int, required): ID of the employee to update
  /// - firstName (string, optional): Updated first name
  /// - lastName (string, optional): Updated last name
  /// - email (string, optional): Updated email address
  /// - phone (string, optional): Updated phone number
  /// - departmentId (int, optional): Updated department ID
  /// - salary (decimal, optional): Updated salary
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether update succeeded
  /// - data (object): Updated employee object
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "employeeId", 42 },
  ///     { "firstName", "Jane" },
  ///     { "email", "jane.doe@company.com" },
  ///     { "departmentId", 7 }
  /// };
  /// var result = await employeeService.UpdateEmployee(parameters);
  /// </example>
  public async Task<string> UpdateEmployee(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("employee", "update", parameters);
  }

  /// <summary>
  /// Deletes an employee record from the database.
  /// </summary>
  /// <param name="parameters">
  /// Dictionary containing:
  /// - employeeId (int, required): ID of the employee to delete
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether deletion succeeded
  /// - data (object): Empty result
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object?&gt;
  /// {
  ///     { "employeeId", 42 }
  /// };
  /// var result = await employeeService.DeleteEmployee(parameters);
  /// </example>
  public async Task<string> DeleteEmployee(Dictionary<string, object?> parameters)
  {
    return await ExecuteOperation("employee", "delete", parameters);
  }
}
