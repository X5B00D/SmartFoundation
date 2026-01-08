using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace SmartFoundation.Mvc.Controllers.ReportGen
{
    /// <summary>
    /// MVC controller responsible for the ReportGen page and form UI.
    /// </summary>
    public class ReportGenController : Controller
    {
        private readonly MastersServies _mastersServies;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportGenController"/> class.
        /// </summary>
        /// <param name="mastersServies">Masters service used by the page (existing pattern).</param>
        public ReportGenController(MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        /// <summary>
        /// Displays the ReportGen page.
        /// </summary>
        public async Task<IActionResult> Index()
        {
            // Session validation
            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("usersID")))
                return RedirectToAction("Index", "Login", new { logout = 1 });

            // Extract session data (following Housing pattern)
            string? usersId = HttpContext.Session.GetString("usersID");
            string? IdaraId = HttpContext.Session.GetString("IdaraID");
            string? HostName = HttpContext.Session.GetString("HostName");
            string PageName = "ReportGen";

            // Call stored procedure using Housing pattern
            var spParameters = new object?[]
            {
                PageName,
                IdaraId,
                usersId,
                HostName
            };

            DataSet? ds = null;
            try
            {
                ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);
            }
            catch (Exception ex)
            {
                // Keep page working even if init call fails
                Console.WriteLine($"Error loading data: {ex.Message}");
            }

            var form = new FormConfig
            {
                FormId = "reportGenForm",
                Title = "بطاقة الموظف",
                ShowPanel = false,
                ShowReset = false,
                Fields = new List<FieldConfig>
                {
                    new FieldConfig
                    {
                        Name = "GeneralNo",
                        Label = "الرقم العام",
                        Type = "number",
                        ColCss = "md:3",
                        Required = true,
                        Value = "60014016",
                        Placeholder = "أدخل الرقم العام",
                        Icon = "fa-solid fa-id-card",
                        InputLang = "number",
                        MaxLength = 10
                    }
                },
                Buttons = new List<FormButtonConfig>
                {
                    new FormButtonConfig
                    {
                        Text = "طباعة الكرت",
                        Icon = "fa-solid fa-print",
                        Type = "button",
                        Color = "primary",
                        OnClickJs = "printEmployeeCard();"
                    }
                }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "طباعة بطاقة الموظف",
                Form = form
            };

            return View(vm);
        }
    }

    /// <summary>
    /// API controller for printing reports.
    /// Loads a report template by id, then loads report data via a provided stored procedure + parameters.
    /// Returns a unified payload under the common { d: "...json..." } convention.
    /// </summary>
    [ApiController]
    [Route("ReportGen")]
    public class ReportGenApiController : ControllerBase
    {
        private readonly ISmartComponentService _dataEngine;
        private readonly ILogger<ReportGenApiController> _logger;

        /// <summary>
        /// Initializes a new instance of the <see cref="ReportGenApiController"/> class.
        /// </summary>
        /// <param name="dataEngine">Smart DataEngine service.</param>
        /// <param name="logger">Logger instance.</param>
        public ReportGenApiController(ISmartComponentService dataEngine, ILogger<ReportGenApiController> logger)
        {
            _dataEngine = dataEngine;
            _logger = logger;
        }

        /// <summary>
        /// Request payload for printing a report.
        /// </summary>
        public class PrintReportRequest
        {
            /// <summary>
            /// Gets or sets the report template identifier.
            /// </summary>
            public int reportID { get; set; }

            /// <summary>
            /// Gets or sets the stored procedure to load the report data.
            /// </summary>
            public string? dataSp { get; set; }

            /// <summary>
            /// Gets or sets the stored procedure parameters.
            /// </summary>
            public Dictionary<string, object?>? parameters { get; set; }
        }

        /// <summary>
        /// Loads report template + data and returns a unified payload.
        /// </summary>
        /// <param name="req">Print request.</param>
        /// <returns>JSON payload in { d: "..." } format containing { report, data }.</returns>
        [HttpPost("Print")]
        public async Task<IActionResult> Print([FromBody] PrintReportRequest req)
        {
            if (req == null)
                return Ok(new { d = JsonSerializer.Serialize(new { error = "Invalid request" }) });

            if (req.reportID <= 0)
                return Ok(new { d = JsonSerializer.Serialize(new { error = "reportID is required" }) });

            if (string.IsNullOrWhiteSpace(req.dataSp))
                return Ok(new { d = JsonSerializer.Serialize(new { error = "dataSp is required" }) });

            try
            {
                // 1) Load report template by id
                var reportTemplateRequest = new SmartRequest
                {
                    Operation = "sp",
                    SpName = "dbo.GetReportContentById",
                    Params = new Dictionary<string, object?>
                    {
                        // SP signature is @reportID BIGINT
                        { "reportID", req.reportID }
                    }
                };

                SmartResponse reportTemplateResponse = await _dataEngine.ExecuteAsync(reportTemplateRequest);

                if (!reportTemplateResponse.Success)
                {
                    _logger.LogWarning("GetReportContentById returned failed SmartResponse: {@Resp}", reportTemplateResponse);

                    var templateError = reportTemplateResponse.Error
                        ?? reportTemplateResponse.Message
                        ?? "Failed to load report template";

                    return Ok(new
                    {
                        d = JsonSerializer.Serialize(new
                        {
                            error = $"dbo.GetReportContentById failed: {templateError}"
                        })
                    });
                }

                // Parse report object from JsonResult (first row)
                object? reportObj = null;
                try
                {
                    var reportRow = reportTemplateResponse.Data?.FirstOrDefault();

                    string? jsonResult = null;
                    if (reportRow != null && reportRow.TryGetValue("JsonResult", out var jr) && jr != null)
                        jsonResult = jr.ToString();

                    if (!string.IsNullOrWhiteSpace(jsonResult))
                        reportObj = JsonSerializer.Deserialize<Dictionary<string, object?>>(jsonResult!);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to parse report JsonResult for reportID={reportID}", req.reportID);
                }

                // 2) Load report data using provided SP + parameters
                var spParams = new Dictionary<string, object?>();
                if (req.parameters != null)
                {
                    foreach (var kvp in req.parameters)
                    {
                        if (string.IsNullOrWhiteSpace(kvp.Key))
                            continue;

                        // Keep behavior safe: skip nulls rather than passing null object values.
                        if (kvp.Value != null)
                            spParams[kvp.Key] = kvp.Value;
                    }
                }

                var dataRequest = new SmartRequest
                {
                    Operation = "sp",
                    SpName = req.dataSp,
                    Params = spParams
                };

                SmartResponse dataResponse = await _dataEngine.ExecuteAsync(dataRequest);

                if (!dataResponse.Success)
                {
                    _logger.LogWarning("Data SP {Sp} returned failed SmartResponse: {@Resp}", req.dataSp, dataResponse);

                    var dataError = dataResponse.Error
                        ?? dataResponse.Message
                        ?? "Failed to load report data";

                    return Ok(new
                    {
                        d = JsonSerializer.Serialize(new
                        {
                            error = $"{req.dataSp} failed: {dataError}"
                        })
                    });
                }

                // First row only (no guessing / no report-specific logic)
                object? firstRow = null;
                try
                {
                    firstRow = dataResponse.Data?.FirstOrDefault() ?? new Dictionary<string, object?>();
                }
                catch
                {
                    firstRow = new Dictionary<string, object?>();
                }

                // 3) Return unified payload: { report, data }
                return Ok(new
                {
                    d = JsonSerializer.Serialize(new
                    {
                        report = reportObj,
                        data = firstRow
                    })
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error printing report. reportID={reportID}, dataSp={DataSp}", req.reportID, req.dataSp);
                return Ok(new { d = JsonSerializer.Serialize(new { error = ex.Message }) });
            }
        }

        /// <summary>
        /// Request payload for retrieving SP column metadata.
        /// </summary>
        public class GetSpColumnsRequest
        {
            /// <summary>
            /// Gets or sets the stored procedure name to inspect.
            /// </summary>
            public string? spName { get; set; }
        }

        /// <summary>
        /// Retrieves column names (metadata only) from a stored procedure for design-time assistance.
        /// This endpoint DOES NOT return actual data, DOES NOT modify data, and is safe for design use only.
        /// Uses sys.dm_exec_describe_first_result_set_for_object which inspects metadata WITHOUT executing the SP.
        /// </summary>
        /// <param name="req">Request containing the SP name.</param>
        /// <returns>JSON containing column names or error.</returns>
        [HttpPost("GetSpColumns")]
        public async Task<IActionResult> GetSpColumns([FromBody] GetSpColumnsRequest req)
        {
            _logger.LogInformation("GetSpColumns called with spName: {SpName}", req?.spName ?? "null");
            
            if (req == null || string.IsNullOrWhiteSpace(req.spName))
            {
                _logger.LogWarning("GetSpColumns called with null or empty spName");
                return Ok(new { success = false, error = "spName is required" });
            }

            // Security: Validate SP name format (prevent SQL injection)
            var spName = req.spName.Trim();
            if (!IsValidSpName(spName))
            {
                _logger.LogWarning("Invalid SP name format: {SpName}", spName);
                return Ok(new { success = false, error = "Invalid stored procedure name format" });
            }

            try
            {
                _logger.LogDebug("Calling GetSpColumnMetadata for SP: {SpName}", spName);
                
                // SAFE APPROACH: Use sys.dm_exec_describe_first_result_set_for_object
                // This DMF inspects the SP's metadata using its object_id WITHOUT EXECUTING IT
                // It works even for SPs that require parameters because it analyzes the schema, not the execution
                //
                // We use a wrapper SP that calls the DMF with OBJECT_ID() to get column names
                var metadataRequest = new SmartRequest
                {
                    Operation = "sp",
                    SpName = "dbo.GetSpColumnMetadata",
                    Params = new Dictionary<string, object?>
                    {
                        { "spName", spName }
                    }
                };

                SmartResponse metadataResponse = await _dataEngine.ExecuteAsync(metadataRequest);

                if (!metadataResponse.Success)
                {
                    _logger.LogWarning("GetSpColumnMetadata failed for SP {SpName}: Error={Error}, Message={Message}",
                        spName,
                        metadataResponse.Error ?? "N/A",
                        metadataResponse.Message ?? "N/A");
                    
                    // Check if it's because the wrapper SP doesn't exist
                    var errorMsg = metadataResponse.Error ?? metadataResponse.Message ?? "";
                    if (errorMsg.Contains("Could not find stored procedure 'dbo.GetSpColumnMetadata'", StringComparison.OrdinalIgnoreCase))
                    {
                        return Ok(new
                        {
                            success = false,
                            error = "GetSpColumnMetadata stored procedure not found. Please deploy GetSpColumnMetadata.sql script to your database."
                        });
                    }
                    
                    // Return user-friendly error
                    return Ok(new
                    {
                        success = false,
                        error = "Unable to determine output columns for this stored procedure. " +
                                $"The stored procedure '{spName}' may not exist or its result set cannot be determined.",
                        details = errorMsg
                    });
                }

                // Extract column names from the metadata result
                var columns = new List<string>();
                if (metadataResponse.Data != null)
                {
                    foreach (var row in metadataResponse.Data)
                    {
                        // The DMF returns 'name' column for each result column
                        if (row.TryGetValue("name", out var nameValue) && nameValue != null)
                        {
                            var columnName = nameValue.ToString();
                            if (!string.IsNullOrWhiteSpace(columnName))
                            {
                                columns.Add(columnName);
                            }
                        }
                    }
                }

                if (columns.Count == 0)
                {
                    return Ok(new
                    {
                        success = false,
                        error = "Unable to determine output columns for this stored procedure. " +
                                "The stored procedure may not return a result set or its schema cannot be inferred."
                    });
                }

                _logger.LogInformation("GetSpColumns for {SpName} returned {Count} columns", spName, columns.Count);

                return Ok(new
                {
                    success = true,
                    spName = spName,
                    columns = columns
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting SP columns for {SpName}", spName);
                return Ok(new
                {
                    success = false,
                    error = "Unable to determine output columns for this stored procedure."
                });
            }
        }

        /// <summary>
        /// Retrieves list of available report templates for the designer presets.
        /// Uses GetReportsList stored procedure to get the list of available reports.
        /// </summary>
        /// <returns>JSON containing list of available report templates.</returns>
        [HttpGet("GetReportTemplates")]
        public async Task<IActionResult> GetReportTemplates()
        {
            _logger.LogInformation("GetReportTemplates called");
            
            try
            {
                // Get list of reports from the database
                // This SP should return: reportID, reportNam_A, reportNam_B
                var listRequest = new SmartRequest
                {
                    Operation = "sp",
                    SpName = "dbo.GetReportsList",
                    Params = new Dictionary<string, object?>()
                };

                _logger.LogDebug("Executing GetReportsList stored procedure");
                SmartResponse listResponse = await _dataEngine.ExecuteAsync(listRequest);

                if (!listResponse.Success)
                {
                    _logger.LogWarning("GetReportsList SP failed: {Error} - {Message}",
                        listResponse.Error ?? "N/A",
                        listResponse.Message ?? "N/A");
                    
                    // Return empty list but indicate SP is not available
                    return Ok(new
                    {
                        success = false,
                        templates = new List<object>(),
                        error = "GetReportsList stored procedure not found or failed. Please deploy the SQL script.",
                        message = listResponse.Message ?? listResponse.Error
                    });
                }

                var templates = new List<object>();

                if (listResponse.Data != null && listResponse.Data.Count > 0)
                {
                    foreach (var row in listResponse.Data)
                    {
                        object? reportId = null;
                        string? reportNameA = null;
                        string? reportNameB = null;

                        if (row.TryGetValue("reportID", out var idVal))
                            reportId = idVal;
                        
                        // Try reportNam_A first (Arabic name)
                        if (row.TryGetValue("reportNam_A", out var nameAVal))
                            reportNameA = nameAVal?.ToString();
                        
                        // Try reportNam_B (English name) as fallback
                        if (row.TryGetValue("reportNam_B", out var nameBVal))
                            reportNameB = nameBVal?.ToString();
                        
                        // Fallback to reportName if the above don't exist
                        if (string.IsNullOrWhiteSpace(reportNameA) && row.TryGetValue("reportName", out var nameVal))
                            reportNameA = nameVal?.ToString();

                        // Use Arabic name, or English name, or generic label
                        var displayName = !string.IsNullOrWhiteSpace(reportNameA) ? reportNameA :
                                          !string.IsNullOrWhiteSpace(reportNameB) ? reportNameB :
                                          $"قالب #{reportId}";

                        if (reportId != null)
                        {
                            templates.Add(new
                            {
                                reportID = reportId,
                                reportName = displayName,
                                reportNam_A = reportNameA,
                                reportNam_B = reportNameB
                            });
                        }
                    }
                }
                else
                {
                    // Log but don't fail - return empty list
                    _logger.LogInformation("GetReportsList SP not available or returned no data: {Message}",
                        listResponse.Message ?? listResponse.Error ?? "No data");
                }

                _logger.LogInformation("GetReportTemplates returned {Count} templates", templates.Count);

                return Ok(new
                {
                    success = true,
                    templates = templates
                });
            }
            catch (Exception ex)
            {
                // Don't fail the entire request - just return empty list
                _logger.LogWarning(ex, "Error getting report templates, returning empty list");
                return Ok(new
                {
                    success = true,
                    templates = new List<object>()
                });
            }
        }

        /// <summary>
        /// Retrieves a specific report template content by ID for loading into the designer.
        /// Uses GetReportContentById stored procedure.
        /// Returns: reportID, reportNam_A, reportNam_B, reportDesign
        /// </summary>
        /// <param name="reportID">The report ID to load.</param>
        /// <returns>JSON containing the report design content.</returns>
        [HttpGet("GetReportTemplate/{reportID:int}")]
        public async Task<IActionResult> GetReportTemplate(int reportID)
        {
            if (reportID <= 0)
            {
                return Ok(new { success = false, error = "Invalid reportID" });
            }

            try
            {
                // Use the existing GetReportContentById stored procedure
                var templateRequest = new SmartRequest
                {
                    Operation = "sp",
                    SpName = "dbo.GetReportContentById",
                    Params = new Dictionary<string, object?>
                    {
                        { "reportID", reportID }
                    }
                };

                SmartResponse templateResponse = await _dataEngine.ExecuteAsync(templateRequest);

                if (!templateResponse.Success)
                {
                    _logger.LogWarning("GetReportContentById failed for reportID={ReportID}: {@Resp}", reportID, templateResponse);
                    return Ok(new
                    {
                        success = false,
                        error = templateResponse.Error ?? templateResponse.Message ?? "Failed to load template"
                    });
                }

                // Parse report object from the result
                string? reportDesign = null;
                string? reportNameA = null;
                string? reportNameB = null;

                try
                {
                    var reportRow = templateResponse.Data?.FirstOrDefault();

                    if (reportRow != null)
                    {
                        // Try to get JsonResult first (if SP returns JSON wrapper)
                        if (reportRow.TryGetValue("JsonResult", out var jr) && jr != null)
                        {
                            var jsonResult = jr.ToString();
                            if (!string.IsNullOrWhiteSpace(jsonResult))
                            {
                                var parsed = JsonSerializer.Deserialize<Dictionary<string, object?>>(jsonResult!);
                                if (parsed != null)
                                {
                                    if (parsed.TryGetValue("reportDesign", out var designVal))
                                        reportDesign = designVal?.ToString();
                                    if (parsed.TryGetValue("reportNam_A", out var nameAVal))
                                        reportNameA = nameAVal?.ToString();
                                    if (parsed.TryGetValue("reportNam_B", out var nameBVal))
                                        reportNameB = nameBVal?.ToString();
                                }
                            }
                        }
                        
                        // Fallback: try direct columns from the result set
                        if (string.IsNullOrWhiteSpace(reportDesign) && reportRow.TryGetValue("reportDesign", out var designDirect))
                            reportDesign = designDirect?.ToString();
                        if (string.IsNullOrWhiteSpace(reportNameA) && reportRow.TryGetValue("reportNam_A", out var nameADirect))
                            reportNameA = nameADirect?.ToString();
                        if (string.IsNullOrWhiteSpace(reportNameB) && reportRow.TryGetValue("reportNam_B", out var nameBDirect))
                            reportNameB = nameBDirect?.ToString();
                        
                        // Legacy fallback: try reportName
                        if (string.IsNullOrWhiteSpace(reportNameA) && reportRow.TryGetValue("reportName", out var nameFallback))
                            reportNameA = nameFallback?.ToString();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to parse report content for reportID={ReportID}", reportID);
                }

                if (string.IsNullOrWhiteSpace(reportDesign))
                {
                    return Ok(new
                    {
                        success = false,
                        error = "Report template has no design content"
                    });
                }

                // Display name: prefer Arabic, then English
                var displayName = !string.IsNullOrWhiteSpace(reportNameA) ? reportNameA :
                                  !string.IsNullOrWhiteSpace(reportNameB) ? reportNameB :
                                  $"قالب #{reportID}";

                _logger.LogInformation("GetReportTemplate loaded reportID={ReportID}, name={Name}", reportID, displayName);

                return Ok(new
                {
                    success = true,
                    reportID = reportID,
                    reportName = displayName,
                    reportNam_A = reportNameA,
                    reportNam_B = reportNameB,
                    reportDesign = reportDesign
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting report template for reportID={ReportID}", reportID);
                return Ok(new { success = false, error = $"Error: {ex.Message}" });
            }
        }

        /// <summary>
        /// Validates that an SP name is safe (prevents SQL injection).
        /// Allows schema-qualified names like dbo.SpName or [dbo].[SpName].
        /// </summary>
        private static bool IsValidSpName(string spName)
        {
            if (string.IsNullOrWhiteSpace(spName))
                return false;

            // Max reasonable length
            if (spName.Length > 256)
                return false;

            // Disallow dangerous characters/patterns
            var dangerous = new[] { ";", "--", "/*", "*/", "xp_", "sp_oa", "EXEC(", "EXECUTE(", "DROP ", "DELETE ", "INSERT ", "UPDATE ", "TRUNCATE " };
            foreach (var d in dangerous)
            {
                if (spName.Contains(d, StringComparison.OrdinalIgnoreCase))
                    return false;
            }

            // Allow: letters, numbers, underscore, dot, brackets
            // Pattern: optional [schema]. or schema. followed by sp name
            var pattern = @"^(\[?[A-Za-z_][A-Za-z0-9_]*\]?\.)?(\[?[A-Za-z_][A-Za-z0-9_]*\]?)$";
            return System.Text.RegularExpressions.Regex.IsMatch(spName, pattern);
        }
    }
}
