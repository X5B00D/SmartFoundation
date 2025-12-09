using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.UI.ViewModels.SmartForm;
using System.Data;
using System.Linq;

namespace SmartFoundation.Mvc.Controllers
{
    [Route("crud")]
    public class CrudController : Controller
    {
        private readonly MastersServies _mastersServies;

        public CrudController(MastersServies mastersCrudServies)
        {
            _mastersServies = mastersCrudServies;
        }

        // REMOVE any TempData like: CrudMessageType, CrudMessage, InsertMessage, UpdateMessage, DeleteMessage, CrudError.
        // KEEP ONLY Toastr buckets: Success, Warning, Error (optional: Info).

        // 0=error, 1=success, 2=warning — read from any table/row
        private static (int? code, string? message) ExtractResult(DataSet ds)
        {
            int? code = null;
            string? message = null;
            if (ds == null) return (code, message);

            foreach (DataTable t in ds.Tables)
            {
                if (t.Rows.Count == 0) continue;

                var msgCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                    c.ColumnName.Equals("Message_", StringComparison.OrdinalIgnoreCase) ||
                    c.ColumnName.Equals("Message", StringComparison.OrdinalIgnoreCase) ||
                    c.ColumnName.Equals("SuccessMessage", StringComparison.OrdinalIgnoreCase));

                var codeCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                    c.ColumnName.Equals("IsSuccessful", StringComparison.OrdinalIgnoreCase) ||
                    c.ColumnName.Equals("Success", StringComparison.OrdinalIgnoreCase));

                foreach (DataRow r in t.Rows)
                {
                    if (msgCol != null && r[msgCol] != DBNull.Value && string.IsNullOrWhiteSpace(message))
                        message = r[msgCol]?.ToString();

                    if (!code.HasValue && codeCol != null && r[codeCol] != DBNull.Value)
                    {
                        var v = r[codeCol];
                        if (v is int i) code = i;
                        else if (v is bool b) code = b ? 1 : 0;
                        else if (int.TryParse(v.ToString(), out var parsed)) code = parsed;
                    }

                    if (code.HasValue && !string.IsNullOrWhiteSpace(message)) break;
                }

                if (code.HasValue || !string.IsNullOrWhiteSpace(message)) break;
            }

            return (code, message);
        }

        // NEW: only set Toastr buckets
        // Map 0=Error, 1=Success, 2=Warning, 3=Info
        private void SetToastTempData(int? code, string? message)
        {
            string bucket = code switch
            {
                0 => "Error",
                1 => "Success",
                2 => "Warning",
                3 => "Info",
                _ => "Info"
            };

            if (string.IsNullOrWhiteSpace(message))
            {
                message = code switch
                {
                    0 => "حدث خطأ أثناء التنفيذ.",
                    1 => "تم تنفيذ العملية بنجاح.",
                    2 => "تم التنفيذ مع تحذير.",
                    3 => "معلومة.",
                    _ => "تمت المعالجة."
                };
            }

            // keep only Toastr buckets
            TempData.Remove("Success");
            TempData.Remove("Warning");
            TempData.Remove("Error");
            TempData.Remove("Info");

            TempData[bucket] = message;
        }

        [HttpPost("insert")]
        public async Task<IActionResult> Insert()
        {
            try
            {
                var f = Request.Form;

                string pageName   = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv) ? pv.ToString() : "";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av) ? av.ToString() : "";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 0;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 0;
                string hostName   = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv) ? hv.ToString() : "";

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    parameters[$"parameter_{idx:00}"] = f.TryGetValue(key, out var val) && !string.IsNullOrWhiteSpace(val)
                        ? val.ToString() : DBNull.Value;
                }

                var ds = await _mastersServies.GetCrudDataSetAsync(parameters);
                var (code, message) = ExtractResult(ds);
                SetToastTempData(code, message);

                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                if (!string.IsNullOrWhiteSpace(redirectAction))
                {
                    // 1) Base path using Url.Action (without query)
                    var baseUrl = Url.Action(redirectAction, redirectController) ?? "/";

                    // 2) Gather Q* keys and order them Q1, Q2, Q3...
                    var qPairs = new List<(int order, string key, string value)>();
                    foreach (var key in f.Keys)
                    {
                        if (string.IsNullOrWhiteSpace(key)) continue;
                        if (!key.StartsWith("Q", StringComparison.OrdinalIgnoreCase)) continue;

                        // Extract numeric suffix (default 0 if none)
                        int order = 0;
                        var suffix = key.Substring(1);
                        int.TryParse(suffix, out order);

                        var val = f[key].ToString();
                        if (!string.IsNullOrWhiteSpace(val))
                            qPairs.Add((order, key, val));
                    }

                    qPairs.Sort((a, b) => a.order.CompareTo(b.order)); // ensures Q1, Q2, Q3...

                    // 3) Build query string manually in desired order
                    var sb = new System.Text.StringBuilder();
                    for (int i = 0; i < qPairs.Count; i++)
                    {
                        var (order, key, value) = qPairs[i];
                        if (i > 0) sb.Append('&');
                        sb.Append(Uri.EscapeDataString(key));
                        sb.Append('=');
                        sb.Append(Uri.EscapeDataString(value));
                    }

                    var fullUrl = sb.Length > 0 ? $"{baseUrl}?{sb}" : baseUrl;
                    return Redirect(fullUrl);
                }

                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                SetToastTempData(0, "Insert failed: " + ex.Message);
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }

        [HttpPost("update")]
        public async Task<IActionResult> Update()
        {
            try
            {
                var f = Request.Form;

                string pageName   = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv) ? pv.ToString() : "";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av) ? av.ToString() : "UPDATE";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 1;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 60014016;
                string hostName   = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv) ? hv.ToString() : Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    parameters[$"parameter_{idx:00}"] = f.TryGetValue(key, out var val) && !string.IsNullOrWhiteSpace(val)
                        ? val.ToString() : DBNull.Value;
                }

                var ds = await _mastersServies.GetCrudDataSetAsync(parameters);
                var (code, message) = ExtractResult(ds);
                SetToastTempData(code, message);

                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                var routeValues = new Dictionary<string, object>();
                if (f.TryGetValue("Q1", out var q1) && !string.IsNullOrWhiteSpace(q1)) routeValues["Q1"] = q1.ToString();

                if (!string.IsNullOrWhiteSpace(redirectAction))
                {
                    return routeValues.Count > 0
                        ? RedirectToAction(redirectAction, redirectController, routeValues)
                        : RedirectToAction(redirectAction, redirectController);
                }

                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                SetToastTempData(0, "Update failed: " + ex.Message);
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }

        [HttpPost("delete")]
        public async Task<IActionResult> Delete()
        {
            try
            {
                var f = Request.Form;

                string pageName   = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv) ? pv.ToString() : "BuildingType";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av) ? av.ToString() : "DELETE";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 1;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 60014016;
                string hostName   = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv) ? hv.ToString() : Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    parameters[$"parameter_{idx:00}"] = f.TryGetValue(key, out var val) && !string.IsNullOrWhiteSpace(val)
                        ? val.ToString() : DBNull.Value;
                }

                var ds = await _mastersServies.GetCrudDataSetAsync(parameters);
                var (code, message) = ExtractResult(ds);
                SetToastTempData(code, message);

                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                var routeValues = new Dictionary<string, object>();
                if (f.TryGetValue("Q1", out var q1) && !string.IsNullOrWhiteSpace(q1)) routeValues["Q1"] = q1.ToString();

                if (!string.IsNullOrWhiteSpace(redirectAction))
                {
                    return routeValues.Count > 0
                        ? RedirectToAction(redirectAction, redirectController, routeValues)
                        : RedirectToAction(redirectAction, redirectController);
                }

                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                SetToastTempData(0, "Delete failed: " + ex.Message);
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }



        [HttpGet("DDLFiltered")]
        public async Task<IActionResult> DDLFiltered(
        string? DDlValues, string? FK, string? textcol, string? ValueCol, string? TableIndex,string? PageName)
        {

            int TableIndexInt = 0;
            if (!string.IsNullOrWhiteSpace(TableIndex))
                int.TryParse(TableIndex, out TableIndexInt);

            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("userID")))
                return Unauthorized();

            if (!int.TryParse(DDlValues, out int DDlValueID) || DDlValueID == -1)
                return Json(new List<object> { new { value = "-1", text = "الرجاء الاختيار" } });

            int userID = Convert.ToInt32(HttpContext.Session.GetString("userID"));
            int IdaraID = Convert.ToInt32(HttpContext.Session.GetString("IdaraID"));
            string HostName = HttpContext.Session.GetString("HostName");

            var ds = await _mastersServies.GetDataLoadDataSetAsync(PageName, IdaraID, userID, HostName);
            var table = (ds?.Tables?.Count ?? 0) > TableIndexInt ? ds.Tables[TableIndexInt] : null;

            var items = new List<object>();
            if (table is not null && table.Rows.Count > 0 && table.Columns.Contains(FK))
            {
                foreach (DataRow row in table.Rows)
                {
                    var fk = row[FK]?.ToString()?.Trim();
                    if (fk == DDlValueID.ToString())
                    {
                        var value = row[ValueCol]?.ToString()?.Trim() ?? "";
                        var text = row[textcol]?.ToString()?.Trim() ?? "";
                        if (!string.IsNullOrEmpty(value))
                            items.Add(new { value, text });
                    }
                }
            }

            if (!items.Any())
                items.Add(new { value = "-1", text = "لاتوجد خيارات" });

            return Json(items);
        }


        [HttpGet("GetDDLValues")]
        public async Task<IActionResult> GetDDLValues(string? textcol, string? ValueCol, string? TableIndex, string? PageName, int userID, int IdaraID, string? HostName)
        {
            int TableIndexInt = 0;
            if (!string.IsNullOrWhiteSpace(TableIndex))
                int.TryParse(TableIndex, out TableIndexInt);

            var ds = await _mastersServies.GetDataLoadDataSetAsync(PageName, IdaraID, userID, HostName);
            var table = (ds?.Tables?.Count ?? 0) > TableIndexInt ? ds.Tables[TableIndexInt] : null;

            var items = new List<object>();
            if (table is not null && table.Rows.Count > 0)
            {
                items.Add(new { Value = "-1", Text = "الرجاء الاختيار" });
                foreach (DataRow row in table.Rows)
                {
                    var value = row[ValueCol]?.ToString()?.Trim() ?? "";
                    var text = row[textcol]?.ToString()?.Trim() ?? "";

                    if (!string.IsNullOrEmpty(value))
                        // ✅ لاحظ الحروف الكبيرة
                        items.Add(new { Value = value, Text = text });
                }
            }

            if (!items.Any())
                items.Add(new { Value = "-1", Text = "لاتوجد خيارات" });

            return Json(items);
        }





    }
}
