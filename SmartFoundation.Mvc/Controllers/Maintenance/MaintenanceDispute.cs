using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;

namespace SmartFoundation.Mvc.Controllers.Maintenance
{
    public partial class MaintenanceController : Controller
    {
        public async Task<IActionResult> MaintenanceDispute()
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = "MaintenanceDispute";

            var spParameters = new object?[]
            {
                PageName,
                IdaraId,
                usersId,
                HostName
            };

            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();

            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);
            SplitDataSet(ds);

            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }

            bool canRaiseMAINTENANCEDISPUTE = false;
            bool canDecideMAINTENANCEDISPUTE = false;
            bool canCloseMAINTENANCEDISPUTE = false;

            foreach (DataRow row in permissionTable.Rows)
            {
                var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();
                if (permissionName == "RAISEMAINTENANCEDISPUTE") canRaiseMAINTENANCEDISPUTE = true;
                if (permissionName == "DECIDEMAINTENANCEDISPUTE") canDecideMAINTENANCEDISPUTE = true;
                if (permissionName == "CLOSEMAINTENANCEDISPUTE") canCloseMAINTENANCEDISPUTE = true;
            }

            string rowIdField = "DisputeID";

            if (dt1 != null)
            {
                rowIdField = dt1.Columns.Contains("DisputeID")
                    ? "DisputeID"
                    : dt1.Columns.Count > 0 ? dt1.Columns[0].ColumnName : "DisputeID";

                var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["DisputeID"] = "رقم النزاع",
                    ["RequestID"] = "رقم الطلب الداخلي",
                    ["RequestNo"] = "رقم الطلب",
                    ["RequestDate"] = "تاريخ الطلب",
                    ["MaintenanceCategoryFullPath_A"] = "نوع الصيانة",
                    ["StatusName_A"] = "حالة الطلب",
                    ["RaisedByDSDID"] = "الجهة الرافعة",
                    ["AgainstDSDID"] = "ضد الجهة",
                    ["Reason"] = "سبب النزاع",
                    ["DecisionNote"] = "قرار التحكيم",
                    ["DecisionDate"] = "تاريخ القرار"
                };

                var hiddenColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "DisputeID",
                    "RequestID",
                    "StatusCode",
                    "DisputeStatusID",
                    "IsActive"
                };

                foreach (DataColumn c in dt1.Columns)
                {
                    string colType = "text";
                    var t = c.DataType;
                    if (t == typeof(bool)) colType = "bool";
                    else if (t == typeof(DateTime)) colType = "date";
                    else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                             || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                        colType = "number";

                    dynamicColumns.Add(new TableColumn
                    {
                        Field = c.ColumnName,
                        Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                        Type = colType,
                        Sortable = true,
                        Visible = !hiddenColumns.Contains(c.ColumnName)
                    });
                }

                foreach (DataRow r in dt1.Rows)
                {
                    var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                    foreach (DataColumn c in dt1.Columns)
                    {
                        var val = r[c];
                        dict[c.ColumnName] = val == DBNull.Value ? null : val;
                    }

                    object? Get(string key) => dict.TryGetValue(key, out var value) ? value : null;
                    dict["p01"] = Get("DisputeID");
                    dict["p02"] = null;
                    dict["p03"] = Get("RequestNo");
                    dict["p04"] = Get("Reason");
                    dict["p05"] = Get("RequestNo");

                    rowsList.Add(dict);
                }
            }

            var requestOptions = BuildOptions(dt2, "RequestID", "RequestNo");
            var dsdOptions = BuildOptions(dt3, "DSDID", "DSDName_A");

            string antiForgeryToken = Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "";
            string currentHostName = HostName ?? Request.Host.Value;

            List<FieldConfig> BuildBaseFields(string actionType) => new()
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = actionType },
                new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId },
                new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId },
                new FieldConfig { Name = "hostname", Type = "hidden", Value = currentHostName },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken }
            };

            var raiseFields = BuildBaseFields("RAISEMAINTENANCEDISPUTE");
            raiseFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Label = "طلب الصيانة", Type = "select", Required = true, ColCss = "6", Options = requestOptions, Select2 = true },
                new FieldConfig { Name = "p02", Label = "ضد الجهة", Type = "select", Required = false, ColCss = "6", Options = dsdOptions, Select2 = true },
                new FieldConfig { Name = "p03", Label = "سبب النزاع", Type = "textarea", Required = true, ColCss = "12" }
            });

            var decideFields = BuildBaseFields("DECIDEMAINTENANCEDISPUTE");
            decideFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "DisputeID" },
                new FieldConfig { Name = "p05", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "جهة القرار", Type = "select", Required = true, ColCss = "6", Options = dsdOptions, Select2 = true },
                new FieldConfig { Name = "p04", Label = "سبب النزاع", Type = "textarea", Readonly = true, ColCss = "12" },
                new FieldConfig { Name = "p03", Label = "قرار التحكيم", Type = "textarea", Required = true, ColCss = "12" }
            });

            var closeFields = BuildBaseFields("CLOSEMAINTENANCEDISPUTE");
            closeFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "DisputeID" },
                new FieldConfig { Name = "p03", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" }
            });

            var dsModel = new SmartTableDsModel
            {
                PageTitle = "نزاعات الصيانة والتحكيم",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = new List<string> { "RequestNo", "Reason", "StatusName_A" },
                Searchable = true,
                AllowExport = true,
                PanelTitle = "نزاعات الصيانة والتحكيم",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canRaiseMAINTENANCEDISPUTE,
                    ShowEdit = canDecideMAINTENANCEDISPUTE,
                    ShowDelete = canCloseMAINTENANCEDISPUTE,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,
                    Add = new TableAction
                    {
                        Label = "تسجيل نزاع",
                        Icon = "fa fa-triangle-exclamation",
                        Color = "warning",
                        OpenModal = true,
                        ModalTitle = "تسجيل نزاع",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceDisputeRaiseForm",
                            Title = "بيانات النزاع",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = raiseFields
                        }
                    },
                    Edit = new TableAction
                    {
                        Label = "قرار تحكيم",
                        Icon = "fa fa-gavel",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "قرار تحكيم",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceDisputeDecisionForm",
                            Title = "قرار التحكيم",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            Fields = decideFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                    Delete = new TableAction
                    {
                        Label = "إغلاق نزاع",
                        Icon = "fa fa-lock",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "إغلاق نزاع",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceDisputeCloseForm",
                            Title = "إغلاق النزاع",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Fields = closeFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    }
                }
            };

            var page = new SmartPageViewModel
            {
                PageTitle = "نزاعات الصيانة والتحكيم",
                PanelTitle = "نزاعات الصيانة والتحكيم",
                PanelIcon = "fa-gavel",
                TableDS = dsModel
            };

            return View("MaintenanceDispute", page);
        }
    }
}
