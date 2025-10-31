using SmartFoundation.DataEngine.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace SmartFoundation.Application.Services;

/// <summary>
/// Template for creating new Application Layer services.
/// 
/// INSTRUCTIONS:
/// 1. Copy this template to create your new service
/// 2. Rename the class to match your entity (e.g., ProductService, OrderService)
/// 3. Update the XML documentation
/// 4. Implement your business methods using the ExecuteOperation pattern
/// 5. Add stored procedure mappings to ProcedureMapper
/// 6. Register service in ServiceCollectionExtensions
/// 7. Write unit tests
/// 
/// NAMING CONVENTIONS:
/// - Service class: {Entity}Service (e.g., EmployeeService, ProductService)
/// - Methods: Verb + Entity (e.g., GetEmployeeList, CreateEmployee)
/// - Parameters: Use descriptive names with XML documentation
/// 
/// MANDATORY REQUIREMENTS:
/// - MUST inherit from BaseService
/// - MUST use ExecuteOperation() for database calls
/// - MUST NOT hard-code stored procedure names
/// - MUST be async (return Task<string>)
/// - MUST have XML documentation for all public methods
/// - MUST accept Dictionary<string, object> for parameters
/// 
/// EXAMPLE USAGE:
/// See examples at bottom of file for common patterns.
/// </summary>
public class NewApplicationServiceTemplate : BaseService
{
  #region Constructor

  /// <summary>
  /// Initializes a new instance of the [YourService] service.
  /// </summary>
  /// <param name="dataEngine">DataEngine service for database operations</param>
  /// <param name="logger">Logger instance for this service</param>
  public NewApplicationServiceTemplate(
      ISmartComponentService dataEngine,
      ILogger<NewApplicationServiceTemplate> logger)
      : base(dataEngine, logger)
  {
    // No additional initialization needed - base class handles everything
    // Only add initialization here if you need service-specific setup
  }

  #endregion

  #region Read Operations (Queries)

  /// <summary>
  /// Gets a paginated list of [entities].
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - pageNumber (int): Page number to retrieve (1-based)
  /// - pageSize (int): Number of records per page (1-100)
  /// 
  /// Optional parameters:
  /// - searchTerm (string): Text to filter results
  /// - sortBy (string): Column name to sort by
  /// - sortDirection (string): 'asc' or 'desc'
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (array): List of entity objects
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt;
  /// {
  ///     { "pageNumber", 1 },
  ///     { "pageSize", 10 },
  ///     { "searchTerm", "john" }
  /// };
  /// var result = await service.GetList(parameters);
  /// </example>
  public async Task<string> GetList(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "list", parameters);

  /// <summary>
  /// Gets a single [entity] by ID.
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - id (int): The ID of the entity to retrieve
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the operation succeeded
  /// - data (object): The entity object if found, null otherwise
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt; { { "id", 123 } };
  /// var result = await service.GetById(parameters);
  /// </example>
  public async Task<string> GetById(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "getById", parameters);

  /// <summary>
  /// Searches for [entities] based on criteria.
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - searchTerm (string): Text to search for
  /// 
  /// Optional parameters:
  /// - searchFields (string): Comma-separated field names to search in
  /// - maxResults (int): Maximum number of results to return
  /// </param>
  /// <returns>
  /// JSON string containing search results
  /// </returns>
  public async Task<string> Search(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "search", parameters);

  #endregion

  #region Write Operations (Commands)

  /// <summary>
  /// Creates a new [entity].
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - name (string): Entity name
  /// - [otherFields]: Additional required fields
  /// 
  /// Optional parameters:
  /// - description (string): Entity description
  /// - [optionalFields]: Additional optional fields
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the creation succeeded
  /// - data (object): The newly created entity with its ID
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt;
  /// {
  ///     { "name", "New Entity" },
  ///     { "description", "Entity description" }
  /// };
  /// var result = await service.Create(parameters);
  /// </example>
  public async Task<string> Create(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "insert", parameters);

  /// <summary>
  /// Updates an existing [entity].
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - id (int): The ID of the entity to update
  /// - [fieldsToUpdate]: Fields to be updated
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the update succeeded
  /// - data (object): The updated entity
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt;
  /// {
  ///     { "id", 123 },
  ///     { "name", "Updated Name" }
  /// };
  /// var result = await service.Update(parameters);
  /// </example>
  public async Task<string> Update(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "update", parameters);

  /// <summary>
  /// Deletes an [entity] by ID.
  /// </summary>
  /// <param name="parameters">
  /// Required parameters:
  /// - id (int): The ID of the entity to delete
  /// </param>
  /// <returns>
  /// JSON string containing:
  /// - success (bool): Whether the deletion succeeded
  /// - data (null): Always null for delete operations
  /// - message (string): Success or error message
  /// </returns>
  /// <example>
  /// var parameters = new Dictionary&lt;string, object&gt; { { "id", 123 } };
  /// var result = await service.Delete(parameters);
  /// </example>
  public async Task<string> Delete(Dictionary<string, object> parameters)
      => await ExecuteOperation("yourModule", "delete", parameters);

  #endregion

  #region Business Logic Methods (Optional)

  /// <summary>
  /// Example of a method with custom business logic.
  /// Use this pattern when you need to orchestrate multiple database calls
  /// or apply business rules before/after database operations.
  /// </summary>
  /// <param name="parameters">Method-specific parameters</param>
  /// <returns>JSON string with operation results</returns>
  public async Task<string> CustomBusinessOperation(Dictionary<string, object> parameters)
  {
    _logger.LogInformation("CustomBusinessOperation called");

    try
    {
      // Example: Validate business rules before database call
      if (!parameters.ContainsKey("requiredField"))
      {
        return System.Text.Json.JsonSerializer.Serialize(new
        {
          success = false,
          data = (object?)null,
          message = "Required field 'requiredField' is missing"
        });
      }

      // Example: Call multiple stored procedures
      var result1 = await ExecuteOperation("yourModule", "operation1", parameters);

      // Parse result1 if needed to use in result2
      // var data1 = JsonDocument.Parse(result1);

      // var params2 = new Dictionary<string, object> { ... };
      // var result2 = await ExecuteOperation("yourModule", "operation2", params2);

      // Return final result
      return result1;
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error in CustomBusinessOperation");
      return System.Text.Json.JsonSerializer.Serialize(new
      {
        success = false,
        data = (object?)null,
        message = $"Business operation failed: {ex.Message}"
      });
    }
  }

  #endregion
}

#region Example Implementations

/*
 * EXAMPLE 1: Simple CRUD Service
 * 
 * public class ProductService : BaseService
 * {
 *     public ProductService(
 *         ISmartComponentService dataEngine,
 *         ILogger<ProductService> logger)
 *         : base(dataEngine, logger) { }
 * 
 *     public async Task<string> GetProductList(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("product", "list", parameters);
 * 
 *     public async Task<string> GetProductById(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("product", "getById", parameters);
 * 
 *     public async Task<string> CreateProduct(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("product", "insert", parameters);
 * 
 *     public async Task<string> UpdateProduct(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("product", "update", parameters);
 * 
 *     public async Task<string> DeleteProduct(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("product", "delete", parameters);
 * }
 * 
 * // ProcedureMapper entries:
 * { "product:list", "dbo.sp_GetProducts" },
 * { "product:getById", "dbo.sp_GetProductById" },
 * { "product:insert", "dbo.sp_InsertProduct" },
 * { "product:update", "dbo.sp_UpdateProduct" },
 * { "product:delete", "dbo.sp_DeleteProduct" }
 */

/*
 * EXAMPLE 2: Service with Business Logic
 * 
 * public class OrderService : BaseService
 * {
 *     public OrderService(
 *         ISmartComponentService dataEngine,
 *         ILogger<OrderService> logger)
 *         : base(dataEngine, logger) { }
 * 
 *     public async Task<string> CreateOrderWithItems(Dictionary<string, object> parameters)
 *     {
 *         _logger.LogInformation("Creating order with items");
 * 
 *         try
 *         {
 *             // Validate order data
 *             if (!parameters.ContainsKey("customerId"))
 *                 throw new ArgumentException("Customer ID is required");
 * 
 *             // Create the order header
 *             var orderParams = new Dictionary<string, object>
 *             {
 *                 { "customerId", parameters["customerId"] },
 *                 { "orderDate", DateTime.Now }
 *             };
 *             var orderResult = await ExecuteOperation("order", "insert", orderParams);
 * 
 *             // Parse order ID from result
 *             var orderData = JsonDocument.Parse(orderResult);
 *             var orderId = orderData.RootElement.GetProperty("data")
 *                 .GetProperty("orderId").GetInt32();
 * 
 *             // Add order items
 *             if (parameters.ContainsKey("items"))
 *             {
 *                 var itemParams = new Dictionary<string, object>
 *                 {
 *                     { "orderId", orderId },
 *                     { "items", parameters["items"] }
 *                 };
 *                 await ExecuteOperation("orderItem", "insertBulk", itemParams);
 *             }
 * 
 *             return JsonSerializer.Serialize(new
 *             {
 *                 success = true,
 *                 data = new { orderId },
 *                 message = "Order created successfully"
 *             });
 *         }
 *         catch (Exception ex)
 *         {
 *             _logger.LogError(ex, "Error creating order");
 *             return JsonSerializer.Serialize(new
 *             {
 *                 success = false,
 *                 data = (object?)null,
 *                 message = $"Failed to create order: {ex.Message}"
 *             });
 *         }
 *     }
 * }
 */

/*
 * EXAMPLE 3: Read-Only Service (Reports/Analytics)
 * 
 * public class ReportService : BaseService
 * {
 *     public ReportService(
 *         ISmartComponentService dataEngine,
 *         ILogger<ReportService> logger)
 *         : base(dataEngine, logger) { }
 * 
 *     public async Task<string> GetSalesSummary(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("report", "salesSummary", parameters);
 * 
 *     public async Task<string> GetTopProducts(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("report", "topProducts", parameters);
 * 
 *     public async Task<string> GetCustomerAnalytics(Dictionary<string, object> parameters)
 *         => await ExecuteOperation("report", "customerAnalytics", parameters);
 * }
 * 
 * // ProcedureMapper entries:
 * { "report:salesSummary", "dbo.sp_Report_SalesSummary" },
 * { "report:topProducts", "dbo.sp_Report_TopProducts" },
 * { "report:customerAnalytics", "dbo.sp_Report_CustomerAnalytics" }
 */

#endregion

#region Checklist for New Service

/*
 * CHECKLIST: Creating a New Service
 * 
 * [ ] 1. Copy this template file
 * [ ] 2. Rename to {Entity}Service.cs
 * [ ] 3. Update class name to match file name
 * [ ] 4. Update XML documentation (class and all methods)
 * [ ] 5. Remove template methods you don't need
 * [ ] 6. Add your specific methods
 * [ ] 7. Add stored procedure mappings to ProcedureMapper.cs
 * [ ] 8. Register service in ServiceCollectionExtensions.cs
 * [ ] 9. Write unit tests in SmartFoundation.Application.Tests
 * [ ] 10. Test locally before committing
 * [ ] 11. Update controller to inject and use new service
 * [ ] 12. Remove direct ISmartComponentService usage from controller
 * [ ] 13. Code review
 * [ ] 14. Deploy to staging
 * [ ] 15. Validate in staging
 * [ ] 16. Deploy to production
 * 
 * COMMON MISTAKES TO AVOID:
 * - ❌ Forgetting to inherit from BaseService
 * - ❌ Hard-coding stored procedure names
 * - ❌ Not calling base constructor
 * - ❌ Using synchronous methods
 * - ❌ Missing XML documentation
 * - ❌ Not registering in DI container
 * - ❌ Not writing unit tests
 */

#endregion
