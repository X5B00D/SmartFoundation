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
        public async Task<IActionResult> MaintenanceApproval()
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = "MaintenanceApproval";

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

            bool canApproveMAINTENANCEAPPROVAL = false;
            bool canRejectMAINTENANCEAPPROVAL = false;

            foreach (DataRow row in permissionTable.Rows)
            {
                var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();
                if (permissionName == "APPROVEMAINTENANCEAPPROVAL") canApproveMAINTENANCEAPPROVAL = true;
                if (permissionName == "REJECTMAINTENANCEAPPROVAL") canRejectMAINTENANCEAPPROVAL = true;
            }

            string rowIdField = "RequestID";

            if (dt1 != null)
            {
                rowIdField = dt1.Columns.Contains("RequestID")
                    ? "RequestID"
                    : dt1.Columns.Count > 0 ? dt1.Columns[0].ColumnName : "RequestID";

                var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["RequestID"] = "الرقم الداخلي",
                    ["RequestNo"] = "رقم الطلب",
                    ["RequestDate"] = "تاريخ الطلب",
                    ["BuildingID"] = "المبنى",
                    ["ResidentID"] = "المستفيد",
                    ["MaintenanceCategoryFullPath_A"] = "نوع الصيانة",
                    ["PriorityName_A"] = "الأولوية",
                    ["StatusName_A"] = "الحالة",
                    ["CurrentDSDID"] = "الجهة الحالية",
                    ["LastActionDate"] = "تاريخ آخر إجراء",
                    ["LastActionTypeName_A"] = "آخر إجراء",
                    ["LastActionNote"] = "ملاحظات آخر إجراء"
                };

                var hiddenColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "RequestID",
                    "BuildingID",
                    "ResidentID",
                    "MaintenanceCategoryID",
                    "CurrentDSDID"
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
                    dict["p01"] = Get("RequestID");
                    dict["p02"] = null;
                    dict["p03"] = Get("RequestNo");
                    dict["p04"] = Get("StatusName_A");

                    rowsList.Add(dict);
                }
            }

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

            var approveFields = BuildBaseFields("APPROVEMAINTENANCEAPPROVAL");
            approveFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p03", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p04", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "ملاحظة الموافقة", Type = "textarea", Required = false, ColCss = "12" }
            });

            var rejectFields = BuildBaseFields("REJECTMAINTENANCEAPPROVAL");
            rejectFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p03", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p04", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "سبب الرفض", Type = "textarea", Required = true, ColCss = "12" }
            });

            var dsModel = new SmartTableDsModel
            {
                PageTitle = "موافقات الصيانة",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = new List<string> { "RequestNo", "MaintenanceCategoryFullPath_A", "StatusName_A", "PriorityName_A" },
                Searchable = true,
                AllowExport = true,
                PanelTitle = "موافقات الصيانة",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = false,
                    ShowEdit = canApproveMAINTENANCEAPPROVAL,
                    ShowDelete = canRejectMAINTENANCEAPPROVAL,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,
                    Edit = new TableAction
                    {
                        Label = "موافقة",
                        Icon = "fa fa-check",
                        Color = "success",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "الموافقة على طلب الصيانة",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceApprovalApproveForm",
                            Title = "الموافقة على طلب الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            Fields = approveFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                    Delete = new TableAction
                    {
                        Label = "رفض",
                        Icon = "fa fa-xmark",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "رفض طلب الصيانة",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceApprovalRejectForm",
                            Title = "رفض طلب الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Fields = rejectFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    }
                }
            };

            var page = new SmartPageViewModel
            {
                PageTitle = "موافقات الصيانة",
                PanelTitle = "موافقات الصيانة",
                PanelIcon = "fa-check-double",
                TableDS = dsModel
            };

            return View("MaintenanceApproval", page);
        }
    }
}
