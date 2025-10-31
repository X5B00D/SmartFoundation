using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;

namespace SmartFoundation.Mvc.Controllers;

/// <summary>
/// Template for migrated controllers using Application Layer services.
/// 
/// MIGRATION INSTRUCTIONS:
/// 1. Copy this template as reference for your controller migration
/// 2. Replace [Entity] placeholders with your actual entity name
/// 3. Inject the appropriate Application Layer service
/// 4. Update action methods to use service instead of DataEngine
/// 5. Remove ISmartComponentService dependency completely
/// 6. Remove SmartRequest/SmartResponse usage
/// 7. Keep controller thin - delegate business logic to service
/// 8. Add input validation
/// 9. Test thoroughly
/// 
/// MIGRATION CHECKLIST (per controller):
/// [ ] Service created and registered in DI
/// [ ] Service injected in controller constructor
/// [ ] All action methods updated to use service
/// [ ] ISmartComponentService dependency removed
/// [ ] Hard-coded SP names removed
/// [ ] Input validation added
/// [ ] Unit tests updated
/// [ ] Integration tests passing
/// [ ] Code review completed
/// 
/// KEY PRINCIPLES:
/// - Controllers orchestrate, services implement
/// - Validate input in controller
/// - Delegate business logic to service
/// - Keep controllers thin (ideally <50 lines per action)
/// - Return appropriate HTTP status codes
/// - Handle errors gracefully
/// </summary>
public class MigratedControllerTemplate : Controller
{
  #region Dependencies

  private readonly NewApplicationServiceTemplate _yourService;
  private readonly ILogger<MigratedControllerTemplate> _logger;

  /// <summary>
  /// Initializes a new instance of the controller.
  /// </summary>
  /// <param name="yourService">Application Layer service for [entity] operations</param>
  /// <param name="logger">Logger instance</param>
  public MigratedControllerTemplate(
      NewApplicationServiceTemplate yourService,
      ILogger<MigratedControllerTemplate> logger)
  {
    _yourService = yourService ?? throw new ArgumentNullException(nameof(yourService));
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
  }

  #endregion

  #region Index/List Actions

  /// <summary>
  /// Displays a paginated list of [entities].
  /// </summary>
  /// <param name="pageNumber">Page number (default: 1)</param>
  /// <param name="pageSize">Records per page (default: 10)</param>
  /// <param name="searchTerm">Optional search term</param>
  /// <returns>View with entity list</returns>
  public async Task<IActionResult> Index(
      int pageNumber = 1,
      int pageSize = 10,
      string? searchTerm = null)
  {
    try
    {
      // Step 1: Validate input
      if (pageNumber < 1) pageNumber = 1;
      if (pageSize < 1 || pageSize > 100) pageSize = 10;

      // Sanitize search term
      searchTerm = searchTerm?.Trim();
      if (searchTerm?.Length > 100)
        searchTerm = searchTerm.Substring(0, 100);

      // Step 2: Prepare parameters
      var parameters = new Dictionary<string, object>
            {
                { "pageNumber", pageNumber },
                { "pageSize", pageSize }
            };

      if (!string.IsNullOrWhiteSpace(searchTerm))
      {
        parameters.Add("searchTerm", searchTerm);
      }

      // Step 3: Call service
      var data = await _yourService.GetList(parameters);

      // Step 4: Pass data to view
      ViewBag.EntityData = data;
      ViewBag.PageNumber = pageNumber;
      ViewBag.PageSize = pageSize;
      ViewBag.SearchTerm = searchTerm;

      return View();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error loading entity list");
      TempData["ErrorMessage"] = "Failed to load data. Please try again.";
      return View();
    }
  }

  #endregion

  #region Details Actions

  /// <summary>
  /// Displays details for a single [entity].
  /// </summary>
  /// <param name="id">Entity ID</param>
  /// <returns>View with entity details</returns>
  public async Task<IActionResult> Details(int id)
  {
    try
    {
      // Validate input
      if (id <= 0)
      {
        TempData["ErrorMessage"] = "Invalid ID";
        return RedirectToAction(nameof(Index));
      }

      // Prepare parameters
      var parameters = new Dictionary<string, object>
            {
                { "id", id }
            };

      // Call service
      var data = await _yourService.GetById(parameters);

      // Pass to view
      ViewBag.EntityData = data;

      return View();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error loading entity details for ID: {Id}", id);
      TempData["ErrorMessage"] = "Failed to load details. Please try again.";
      return RedirectToAction(nameof(Index));
    }
  }

  #endregion

  #region Create Actions

  /// <summary>
  /// Displays the create form.
  /// </summary>
  /// <returns>View with empty form</returns>
  [HttpGet]
  public IActionResult Create()
  {
    return View();
  }

  /// <summary>
  /// Handles form submission for creating a new [entity].
  /// </summary>
  /// <param name="formData">Form data from view</param>
  /// <returns>Redirect to Index on success, View with errors on failure</returns>
  [HttpPost]
  [ValidateAntiForgeryToken]
  public async Task<IActionResult> Create([FromForm] Dictionary<string, object> formData)
  {
    try
    {
      // Step 1: Validate input
      if (!ModelState.IsValid)
      {
        TempData["ErrorMessage"] = "Please correct the errors in the form.";
        return View();
      }

      // Additional validation
      if (!formData.ContainsKey("name") || string.IsNullOrWhiteSpace(formData["name"]?.ToString()))
      {
        ModelState.AddModelError("name", "Name is required");
        TempData["ErrorMessage"] = "Name is required.";
        return View();
      }

      // Step 2: Extract and prepare parameters
      var parameters = new Dictionary<string, object>
            {
                { "name", formData["name"].ToString()! },
                // Add more fields as needed
            };

      // Add optional fields if present
      if (formData.ContainsKey("description") && !string.IsNullOrWhiteSpace(formData["description"]?.ToString()))
      {
        parameters.Add("description", formData["description"].ToString()!);
      }

      // Step 3: Call service
      var result = await _yourService.Create(parameters);

      // Step 4: Handle response
      var jsonResult = System.Text.Json.JsonDocument.Parse(result);
      var success = jsonResult.RootElement.GetProperty("success").GetBoolean();

      if (success)
      {
        TempData["SuccessMessage"] = "Entity created successfully!";
        return RedirectToAction(nameof(Index));
      }
      else
      {
        var message = jsonResult.RootElement.GetProperty("message").GetString();
        TempData["ErrorMessage"] = $"Failed to create entity: {message}";
        return View();
      }
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error creating entity");
      TempData["ErrorMessage"] = "An error occurred while creating the entity. Please try again.";
      return View();
    }
  }

  #endregion

  #region Edit Actions

  /// <summary>
  /// Displays the edit form for an existing [entity].
  /// </summary>
  /// <param name="id">Entity ID</param>
  /// <returns>View with populated form</returns>
  [HttpGet]
  public async Task<IActionResult> Edit(int id)
  {
    try
    {
      // Validate input
      if (id <= 0)
      {
        TempData["ErrorMessage"] = "Invalid ID";
        return RedirectToAction(nameof(Index));
      }

      // Get entity data
      var parameters = new Dictionary<string, object>
            {
                { "id", id }
            };

      var data = await _yourService.GetById(parameters);

      // Check if entity exists
      var jsonData = System.Text.Json.JsonDocument.Parse(data);
      var success = jsonData.RootElement.GetProperty("success").GetBoolean();

      if (!success)
      {
        TempData["ErrorMessage"] = "Entity not found";
        return RedirectToAction(nameof(Index));
      }

      // Pass to view
      ViewBag.EntityData = data;
      ViewBag.EntityId = id;

      return View();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error loading entity for edit: {Id}", id);
      TempData["ErrorMessage"] = "Failed to load entity. Please try again.";
      return RedirectToAction(nameof(Index));
    }
  }

  /// <summary>
  /// Handles form submission for updating an existing [entity].
  /// </summary>
  /// <param name="id">Entity ID</param>
  /// <param name="formData">Form data from view</param>
  /// <returns>Redirect to Index on success, View with errors on failure</returns>
  [HttpPost]
  [ValidateAntiForgeryToken]
  public async Task<IActionResult> Edit(int id, [FromForm] Dictionary<string, object> formData)
  {
    try
    {
      // Validate input
      if (id <= 0)
      {
        TempData["ErrorMessage"] = "Invalid ID";
        return RedirectToAction(nameof(Index));
      }

      if (!ModelState.IsValid)
      {
        TempData["ErrorMessage"] = "Please correct the errors in the form.";
        return View();
      }

      // Prepare parameters (include ID)
      var parameters = new Dictionary<string, object>
            {
                { "id", id }
            };

      // Add form data
      foreach (var kvp in formData)
      {
        if (!string.IsNullOrWhiteSpace(kvp.Value?.ToString()))
        {
          parameters[kvp.Key] = kvp.Value;
        }
      }

      // Call service
      var result = await _yourService.Update(parameters);

      // Handle response
      var jsonResult = System.Text.Json.JsonDocument.Parse(result);
      var success = jsonResult.RootElement.GetProperty("success").GetBoolean();

      if (success)
      {
        TempData["SuccessMessage"] = "Entity updated successfully!";
        return RedirectToAction(nameof(Index));
      }
      else
      {
        var message = jsonResult.RootElement.GetProperty("message").GetString();
        TempData["ErrorMessage"] = $"Failed to update entity: {message}";
        return View();
      }
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error updating entity: {Id}", id);
      TempData["ErrorMessage"] = "An error occurred while updating the entity. Please try again.";
      return View();
    }
  }

  #endregion

  #region Delete Actions

  /// <summary>
  /// Displays confirmation page for deleting an [entity].
  /// </summary>
  /// <param name="id">Entity ID</param>
  /// <returns>View with entity details for confirmation</returns>
  [HttpGet]
  public async Task<IActionResult> Delete(int id)
  {
    try
    {
      // Validate input
      if (id <= 0)
      {
        TempData["ErrorMessage"] = "Invalid ID";
        return RedirectToAction(nameof(Index));
      }

      // Get entity data for confirmation
      var parameters = new Dictionary<string, object>
            {
                { "id", id }
            };

      var data = await _yourService.GetById(parameters);

      // Pass to view
      ViewBag.EntityData = data;
      ViewBag.EntityId = id;

      return View();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error loading entity for delete: {Id}", id);
      TempData["ErrorMessage"] = "Failed to load entity. Please try again.";
      return RedirectToAction(nameof(Index));
    }
  }

  /// <summary>
  /// Handles confirmation for deleting an [entity].
  /// </summary>
  /// <param name="id">Entity ID</param>
  /// <returns>Redirect to Index</returns>
  [HttpPost, ActionName("Delete")]
  [ValidateAntiForgeryToken]
  public async Task<IActionResult> DeleteConfirmed(int id)
  {
    try
    {
      // Validate input
      if (id <= 0)
      {
        TempData["ErrorMessage"] = "Invalid ID";
        return RedirectToAction(nameof(Index));
      }

      // Prepare parameters
      var parameters = new Dictionary<string, object>
            {
                { "id", id }
            };

      // Call service
      var result = await _yourService.Delete(parameters);

      // Handle response
      var jsonResult = System.Text.Json.JsonDocument.Parse(result);
      var success = jsonResult.RootElement.GetProperty("success").GetBoolean();

      if (success)
      {
        TempData["SuccessMessage"] = "Entity deleted successfully!";
      }
      else
      {
        var message = jsonResult.RootElement.GetProperty("message").GetString();
        TempData["ErrorMessage"] = $"Failed to delete entity: {message}";
      }

      return RedirectToAction(nameof(Index));
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error deleting entity: {Id}", id);
      TempData["ErrorMessage"] = "An error occurred while deleting the entity. Please try again.";
      return RedirectToAction(nameof(Index));
    }
  }

  #endregion

  #region API Actions (Optional)

  /// <summary>
  /// API endpoint for getting entity list (JSON response).
  /// Use this pattern for AJAX/API calls from JavaScript.
  /// </summary>
  /// <param name="pageNumber">Page number</param>
  /// <param name="pageSize">Records per page</param>
  /// <returns>JSON result</returns>
  [HttpGet]
  public async Task<IActionResult> GetListApi(int pageNumber = 1, int pageSize = 10)
  {
    try
    {
      // Validate input
      if (pageNumber < 1) pageNumber = 1;
      if (pageSize < 1 || pageSize > 100) pageSize = 10;

      // Prepare parameters
      var parameters = new Dictionary<string, object>
            {
                { "pageNumber", pageNumber },
                { "pageSize", pageSize }
            };

      // Call service
      var data = await _yourService.GetList(parameters);

      // Return JSON
      return Content(data, "application/json");
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error in GetListApi");
      return StatusCode(500, new
      {
        success = false,
        message = "Internal server error"
      });
    }
  }

  /// <summary>
  /// API endpoint for creating entity (JSON request/response).
  /// </summary>
  /// <param name="request">JSON request body</param>
  /// <returns>JSON result</returns>
  [HttpPost]
  public async Task<IActionResult> CreateApi([FromBody] Dictionary<string, object> request)
  {
    try
    {
      // Validate input
      if (request == null || !request.Any())
      {
        return BadRequest(new
        {
          success = false,
          message = "Invalid request"
        });
      }

      // Call service
      var result = await _yourService.Create(request);

      // Return JSON
      return Content(result, "application/json");
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error in CreateApi");
      return StatusCode(500, new
      {
        success = false,
        message = "Internal server error"
      });
    }
  }

  #endregion
}

#region Before/After Comparison

/*
 * BEFORE MIGRATION (Direct DataEngine Usage):
 * 
 * public class EmployeesController : Controller
 * {
 *     private readonly ISmartComponentService _dataEngine;  // ❌ Direct dependency
 * 
 *     public EmployeesController(ISmartComponentService dataEngine)
 *     {
 *         _dataEngine = dataEngine;
 *     }
 * 
 *     public async Task<IActionResult> Index(int pageNumber = 1)
 *     {
 *         var request = new SmartRequest
 *         {
 *             Operation = "sp",
 *             SpName = "dbo.sp_GetEmployees",  // ❌ Hard-coded SP name
 *             Params = new Dictionary<string, object>
 *             {
 *                 { "pageNumber", pageNumber }
 *             }
 *         };
 * 
 *         var response = await _dataEngine.ExecuteAsync(request);  // ❌ Direct call
 *         
 *         ViewBag.Data = response.Data;
 *         return View();
 *     }
 * }
 * 
 * AFTER MIGRATION (Application Layer):
 * 
 * public class EmployeesController : Controller
 * {
 *     private readonly EmployeeService _employeeService;  // ✅ Service dependency
 *     private readonly ILogger<EmployeesController> _logger;
 * 
 *     public EmployeesController(
 *         EmployeeService employeeService,
 *         ILogger<EmployeesController> logger)
 *     {
 *         _employeeService = employeeService;
 *         _logger = logger;
 *     }
 * 
 *     public async Task<IActionResult> Index(int pageNumber = 1, int pageSize = 10)
 *     {
 *         try
 *         {
 *             // ✅ Validate input
 *             if (pageNumber < 1) pageNumber = 1;
 *             if (pageSize < 1 || pageSize > 100) pageSize = 10;
 * 
 *             // ✅ Prepare parameters
 *             var parameters = new Dictionary<string, object>
 *             {
 *                 { "pageNumber", pageNumber },
 *                 { "pageSize", pageSize }
 *             };
 * 
 *             // ✅ Call service (no SP names, no SmartRequest)
 *             var data = await _employeeService.GetEmployeeList(parameters);
 * 
 *             // ✅ Pass to view
 *             ViewBag.EmployeeData = data;
 *             return View();
 *         }
 *         catch (Exception ex)
 *         {
 *             _logger.LogError(ex, "Error loading employees");
 *             TempData["ErrorMessage"] = "Failed to load employees";
 *             return View();
 *         }
 *     }
 * }
 * 
 * BENEFITS:
 * ✅ No direct DataEngine dependency
 * ✅ No hard-coded stored procedure names
 * ✅ No SmartRequest/SmartResponse in controller
 * ✅ Input validation added
 * ✅ Error handling improved
 * ✅ Logging added
 * ✅ Cleaner, more maintainable code
 * ✅ Easier to test (mock the service)
 * ✅ Better separation of concerns
 */

#endregion

#region Migration Checklist

/*
 * CONTROLLER MIGRATION CHECKLIST
 * 
 * BEFORE STARTING:
 * [ ] Review current controller code
 * [ ] Identify all ISmartComponentService usage
 * [ ] List all stored procedures used
 * [ ] Document current functionality
 * [ ] Create service class (if not exists)
 * [ ] Add SP mappings to ProcedureMapper
 * [ ] Register service in DI
 * 
 * DURING MIGRATION:
 * [ ] Replace ISmartComponentService injection with service injection
 * [ ] Update constructor to accept service
 * [ ] For each action method:
 *     [ ] Add input validation
 *     [ ] Replace SmartRequest with Dictionary<string, object>
 *     [ ] Replace _dataEngine.ExecuteAsync() with _service.Method()
 *     [ ] Remove SmartRequest/SmartResponse usage
 *     [ ] Add try-catch error handling
 *     [ ] Add logging
 *     [ ] Update view data passing
 * [ ] Remove all ISmartComponentService references
 * [ ] Remove all hard-coded SP names
 * [ ] Remove SmartRequest/SmartResponse usings
 * 
 * AFTER MIGRATION:
 * [ ] Build successfully
 * [ ] Update unit tests
 * [ ] Run all tests (pass)
 * [ ] Test manually in local environment
 * [ ] Code review
 * [ ] Deploy to staging
 * [ ] Smoke test in staging
 * [ ] UAT in staging
 * [ ] Deploy to production
 * [ ] Monitor for issues
 * [ ] Update documentation
 * 
 * VALIDATION:
 * [ ] No ISmartComponentService references in controller
 * [ ] No SmartRequest/SmartResponse in controller
 * [ ] No hard-coded SP names
 * [ ] All actions have error handling
 * [ ] All actions have logging
 * [ ] Input validation present
 * [ ] Code follows template patterns
 * [ ] Tests passing
 * [ ] No functionality regression
 */

#endregion
