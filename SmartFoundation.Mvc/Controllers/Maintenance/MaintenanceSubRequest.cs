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
        public async Task<IActionResult> MaintenanceSubRequest()
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = "MaintenanceSubRequest";

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

            bool canCreateMAINTENANCESUBREQUEST = false;
            bool canCompleteMAINTENANCESUBREQUEST = false;
            bool canCancelMAINTENANCESUBREQUEST = false;

            foreach (DataRow row in permissionTable.Rows)
            {
                var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();
                if (permissionName == "CREATEMAINTENANCESUBREQUEST") canCreateMAINTENANCESUBREQUEST = true;
                if (permissionName == "COMPLETEMAINTENANCESUBREQUEST" || permissionName == "RETURNTOPARENTREQUEST") canCompleteMAINTENANCESUBREQUEST = true;
                if (permissionName == "CANCELMAINTENANCESUBREQUEST") canCancelMAINTENANCESUBREQUEST = true;
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
                    ["RequestNo"] = "رقم الطلب الفرعي",
                    ["RequestDate"] = "تاريخ الطلب",
                    ["ParentRequestID"] = "الطلب الرئيسي",
                    ["MaintenanceCategoryFullPath_A"] = "نوع الصيانة",
                    ["CurrentDSDID"] = "الجهة الحالية",
                    ["StatusName_A"] = "الحالة",
                    ["PriorityName_A"] = "الأولوية",
                    ["LastActionDate"] = "تاريخ آخر إجراء",
                    ["LastActionDate"] = "ملاحظة آخر إجراء",
                    ["LastActionTypeName_A"] = "آخر إجراء"
                };

                var hiddenColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "RequestID",
                    "TransactionID_FK",
                    "ParentRequestID",
                    "RootRequestID",
                    "BuildingID",
                    "ResidentID",
                    "MaintenanceCategoryID",
                    "CurrentDSDID",
                    "StatusID",
                    "StatusCode",
                    "PriorityID",
                    "PriorityCode"
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

            var parentRequestOptions = BuildOptions(dt2, "RequestID", "RequestNo");
            var categoryOptions = BuildOptions(dt3, "MaintenanceCategoryID", "FullPath_A");
            var dsdOptions = BuildOptions(dt4, "DSDID", "DSDName_A");
            var priorityOptions = BuildOptions(dt5, "PriorityID", "PriorityName_A");

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

            var createFields = BuildBaseFields("CREATEMAINTENANCESUBREQUEST");
            createFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Label = "الطلب الرئيسي", Type = "select", Required = true, ColCss = "6", Options = parentRequestOptions, Select2 = true },
                new FieldConfig { Name = "p02", Label = "نوع الصيانة", Type = "select", Required = true, ColCss = "6", Options = categoryOptions, Select2 = true },
                new FieldConfig { Name = "p03", Label = "الجهة المسؤولة", Type = "select", Required = false, ColCss = "6", Options = dsdOptions, Select2 = true },
                new FieldConfig { Name = "p05", Label = "الأولوية", Type = "select", Required = false, ColCss = "6", Options = priorityOptions, Select2 = true },
                new FieldConfig { Name = "p04", Label = "وصف الطلب الفرعي", Type = "textarea", Required = true, ColCss = "12" }
            });

            var completeFields = BuildBaseFields("COMPLETEMAINTENANCESUBREQUEST");
            completeFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p03", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p04", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "ملاحظات الإنهاء", Type = "textarea", Required = false, ColCss = "12" }
            });

            var cancelFields = BuildBaseFields("CANCELMAINTENANCESUBREQUEST");
            cancelFields.AddRange(new[]
            {
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p03", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p04", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "سبب الإلغاء", Type = "textarea", Required = false, ColCss = "12" }
            });

            var dsModel = new SmartTableDsModel
            {
                PageTitle = "الطلبات الفرعية",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = new List<string> { "RequestNo", "MaintenanceCategoryFullPath_A", "StatusName_A", "PriorityName_A" },
                Searchable = true,
                AllowExport = true,
                PanelTitle = "الطلبات الفرعية",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canCreateMAINTENANCESUBREQUEST,
                    ShowEdit = canCompleteMAINTENANCESUBREQUEST,
                    ShowDelete = canCancelMAINTENANCESUBREQUEST,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,
                    Add = new TableAction
                    {
                        Label = "إنشاء طلب فرعي",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إنشاء طلب فرعي",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceSubRequestCreateForm",
                            Title = "بيانات الطلب الفرعي",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = createFields
                        }
                    },
                    Edit = new TableAction
                    {
                        Label = "إنهاء طلب فرعي",
                        Icon = "fa fa-check",
                        Color = "success",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "إنهاء طلب فرعي",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceSubRequestCompleteForm",
                            Title = "إنهاء الطلب الفرعي",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            Fields = completeFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                    Delete = new TableAction
                    {
                        Label = "إلغاء طلب فرعي",
                        Icon = "fa fa-ban",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "إلغاء طلب فرعي",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceSubRequestCancelForm",
                            Title = "إلغاء الطلب الفرعي",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Fields = cancelFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    }
                }
            };

            var page = new SmartPageViewModel
            {
                PageTitle = "الطلبات الفرعية",
                PanelTitle = "الطلبات الفرعية",
                PanelIcon = "fa-code-branch",
                TableDS = dsModel
            };

            return View("MaintenanceSubRequest", page);
        }
    }
}
