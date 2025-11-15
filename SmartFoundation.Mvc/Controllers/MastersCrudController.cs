using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using System.Data;

namespace SmartFoundation.Mvc.Controllers
{
    [Route("crud")]
    public class MastersCrudController : Controller
    {
        private readonly MastersCrudServies _mastersCrudServies;

        public MastersCrudController(MastersCrudServies mastersCrudServies)
        {
            _mastersCrudServies = mastersCrudServies;
        }

        public IActionResult Index()
        {
            return View();
        }

        // POST /crud/insert
        [HttpPost("insert")]
        public async Task<IActionResult> Insert()
        {
            try
            {
                var f = Request.Form;

                // Required headers (with safe defaults)
                string pageName   = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv.ToString()) ? pv.ToString() : "BuildingType";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av.ToString()) ? av.ToString() : "INSERT";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 1;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 60014016;
                string hostName   = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv.ToString()) ? hv.ToString() : Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                // Map p01..p50 => parameter_01..parameter_50 (send DBNull for empty/missing)
                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    if (f.TryGetValue(key, out var val))
                    {
                        var s = val.ToString();
                        parameters[$"parameter_{idx:00}"] = string.IsNullOrWhiteSpace(s) ? DBNull.Value : s;
                    }
                    else
                    {
                        parameters[$"parameter_{idx:00}"] = DBNull.Value;
                    }
                }

                var ds = await _mastersCrudServies.GetCrudDataSetAsync(parameters);

                string? message = null;
                bool? isSuccess = null;

                foreach (DataTable t in ds.Tables)
                {
                    if (t.Rows.Count == 0) continue;
                    var row = t.Rows[0];

                    var msgCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "Message_", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Message", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "SuccessMessage", StringComparison.OrdinalIgnoreCase));

                    if (msgCol != null && row[msgCol] != DBNull.Value)
                        message = row[msgCol]?.ToString();

                    var succCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "IsSuccessful", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Success", StringComparison.OrdinalIgnoreCase));

                    if (succCol != null && row[succCol] != DBNull.Value)
                    {
                        var v = row[succCol];
                        if (v is bool b) isSuccess = b;
                        else if (v is int i) isSuccess = i != 0;
                        else if (v is string s) isSuccess = s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase) || s.Equals("Y", StringComparison.OrdinalIgnoreCase);
                    }

                    if (!string.IsNullOrWhiteSpace(message) || isSuccess.HasValue)
                        break;
                }

                if (isSuccess == true) TempData["InsertMessage"] = message ?? "Success";
                else if (isSuccess == false) TempData["CrudError"] = message ?? "Insert failed.";
                else TempData["InsertMessage"] = message ?? "تمت العملية.";

                // Optional redirect targets (post hidden fields)
                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                if (!string.IsNullOrWhiteSpace(redirectAction))
                    return RedirectToAction(redirectAction, redirectController);

                // Fallback: back to referrer or home
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);

                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                TempData["CrudError"] = "Insert failed: " + ex.Message;
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }

        // POST /crud/update
        [HttpPost("update")]
        public async Task<IActionResult> Update()
        {
            try
            {
                var f = Request.Form;

                // Required headers (with safe defaults)
                string pageName   = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv.ToString()) ? pv.ToString() : "error";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av.ToString()) ? av.ToString() : "error";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 0;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 0;
                string hostName   = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv.ToString()) ? hv.ToString() : Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                // Map p01..p50 => parameter_01..parameter_50 (send DBNull for empty/missing)
                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    if (f.TryGetValue(key, out var val))
                    {
                        var s = val.ToString();
                        parameters[$"parameter_{idx:00}"] = string.IsNullOrWhiteSpace(s) ? DBNull.Value : s;
                    }
                    else
                    {
                        parameters[$"parameter_{idx:00}"] = DBNull.Value;
                    }
                }

                var ds = await _mastersCrudServies.GetCrudDataSetAsync(parameters);

                string? message = null;
                bool? isSuccess = null;

                foreach (DataTable t in ds.Tables)
                {
                    if (t.Rows.Count == 0) continue;
                    var row = t.Rows[0];

                    var msgCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "Message_", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Message", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "SuccessMessage", StringComparison.OrdinalIgnoreCase));

                    if (msgCol != null && row[msgCol] != DBNull.Value)
                        message = row[msgCol]?.ToString();

                    var succCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "IsSuccessful", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Success", StringComparison.OrdinalIgnoreCase));

                    if (succCol != null && row[succCol] != DBNull.Value)
                    {
                        var v = row[succCol];
                        if (v is bool b) isSuccess = b;
                        else if (v is int i) isSuccess = i != 0;
                        else if (v is string s) isSuccess = s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase) || s.Equals("Y", StringComparison.OrdinalIgnoreCase);
                    }

                    if (!string.IsNullOrWhiteSpace(message) || isSuccess.HasValue)
                        break;
                }

                if (isSuccess == true) TempData["UpdateMessage"] = message ?? "Success";
                else if (isSuccess == false) TempData["CrudError"] = message ?? "Update failed.";
                else TempData["UpdateMessage"] = message ?? "تمت العملية.";

                // Optional redirect targets (post hidden fields)
                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                if (!string.IsNullOrWhiteSpace(redirectAction))
                    return RedirectToAction(redirectAction, redirectController);

                // Fallback: back to referrer or home
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);

                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                TempData["CrudError"] = "Update failed: " + ex.Message;
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }



        [HttpPost("Delete")]
        public async Task<IActionResult> Delete()
        {
            try
            {
                var f = Request.Form;

                // Required headers (with safe defaults)
                string pageName = f.TryGetValue("pageName_", out var pv) && !string.IsNullOrWhiteSpace(pv.ToString()) ? pv.ToString() : "error";
                string actionType = f.TryGetValue("ActionType", out var av) && !string.IsNullOrWhiteSpace(av.ToString()) ? av.ToString() : "error";
                int? idaraID = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 0;
                int? entryData = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 0;
                string hostName = f.TryGetValue("hostname", out var hv) && !string.IsNullOrWhiteSpace(hv.ToString()) ? hv.ToString() : Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,
                    ["ActionType"] = actionType.ToUpperInvariant(),
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName
                };

                // Map p01..p50 => parameter_01..parameter_50 (send DBNull for empty/missing)
                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    if (f.TryGetValue(key, out var val))
                    {
                        var s = val.ToString();
                        parameters[$"parameter_{idx:00}"] = string.IsNullOrWhiteSpace(s) ? DBNull.Value : s;
                    }
                    else
                    {
                        parameters[$"parameter_{idx:00}"] = DBNull.Value;
                    }
                }

                var ds = await _mastersCrudServies.GetCrudDataSetAsync(parameters);

                string? message = null;
                bool? isSuccess = null;

                foreach (DataTable t in ds.Tables)
                {
                    if (t.Rows.Count == 0) continue;
                    var row = t.Rows[0];

                    var msgCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "Message_", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Message", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "SuccessMessage", StringComparison.OrdinalIgnoreCase));

                    if (msgCol != null && row[msgCol] != DBNull.Value)
                        message = row[msgCol]?.ToString();

                    var succCol = t.Columns.Cast<DataColumn>().FirstOrDefault(c =>
                        string.Equals(c.ColumnName, "IsSuccessful", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.ColumnName, "Success", StringComparison.OrdinalIgnoreCase));

                    if (succCol != null && row[succCol] != DBNull.Value)
                    {
                        var v = row[succCol];
                        if (v is bool b) isSuccess = b;
                        else if (v is int i) isSuccess = i != 0;
                        else if (v is string s) isSuccess = s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase) || s.Equals("Y", StringComparison.OrdinalIgnoreCase);
                    }

                    if (!string.IsNullOrWhiteSpace(message) || isSuccess.HasValue)
                        break;
                }

                if (isSuccess == true) TempData["UpdateMessage"] = message ?? "Success";
                else if (isSuccess == false) TempData["CrudError"] = message ?? "Update failed.";
                else TempData["UpdateMessage"] = message ?? "تمت العملية.";

                // Optional redirect targets (post hidden fields)
                var redirectAction = f.TryGetValue("redirectAction", out var ra) ? ra.ToString() : null;
                var redirectController = f.TryGetValue("redirectController", out var rc) ? rc.ToString() : null;

                if (!string.IsNullOrWhiteSpace(redirectAction))
                    return RedirectToAction(redirectAction, redirectController);

                // Fallback: back to referrer or home
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);

                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                TempData["CrudError"] = "Update failed: " + ex.Message;
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrWhiteSpace(referer)) return Redirect(referer);
                return RedirectToAction("Index", "Home");
            }
        }
    }
}
