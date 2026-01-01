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
                    Params = new Dictionary<string, object>
                    {
                        // SP signature is @reportID BIGINT
                        { "reportID", req.reportID }
                    }
                };

                SmartResponse reportTemplateResponse = await _dataEngine.ExecuteAsync(reportTemplateRequest);

                if (!reportTemplateResponse.Success)
                {
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
                var spParams = new Dictionary<string, object>();
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
    }
}
