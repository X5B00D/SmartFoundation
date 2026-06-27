using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;

namespace SmartFoundation.Mvc.Controllers.Maintenance
{
    public partial class MaintenanceController : Controller
    {
        public async Task<IActionResult> BuildingMaintenanceRequest()
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = string.IsNullOrWhiteSpace(PageName) ? "BuildingMaintenanceRequest" : PageName;

            var spParameters = new object?[]
            {
                PageName ?? "BuildingMaintenanceRequest",
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

            string rowIdField = "RequestID";
            bool canInsertBUILDINGMAINTENANCEREQUEST = false;
            bool canUpdateBUILDINGMAINTENANCEREQUEST = false;
            bool canCancelBUILDINGMAINTENANCEREQUEST = false;

            try
            {
                foreach (DataRow row in permissionTable.Rows)
                {
                    var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                    if (permissionName == "INSERTBUILDINGMAINTENANCEREQUEST") canInsertBUILDINGMAINTENANCEREQUEST = true;
                    if (permissionName == "UPDATEBUILDINGMAINTENANCEREQUEST") canUpdateBUILDINGMAINTENANCEREQUEST = true;
                    if (permissionName == "CANCELBUILDINGMAINTENANCEREQUEST") canCancelBUILDINGMAINTENANCEREQUEST = true;
                }

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
                        ["MaintenanceCategoryName_A"] = "نوع الصيانة",
                        ["MaintenanceCategoryFullPath_A"] = "مسار نوع الصيانة",
                        ["PriorityName_A"] = "الأولوية",
                        ["StatusName_A"] = "الحالة",
                        ["CurrentDSDID"] = "الجهة الحالية",
                        ["LastActionDate"] = "تاريخ آخر إجراء",
                        ["LastActionTypeName_A"] = "آخر إجراء",
                        ["LastActionNote"] = "ملاحظات آخر إجراء",
                        ["Description_A"] = "وصف المشكلة"
                    };

                    var hiddenColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                    {
                        "RequestID",
                        "TransactionID_FK",
                        "BuildingID",
                        "UnitID",
                        "ResidentID",
                        "MaintenanceCategoryID",
                        "StatusID",
                        "PriorityID",
                        "CurrentDSDID",
                        "OriginalDSDID",
                        "ParentRequestID",
                        "RootRequestID",
                        "RequestLevel",
                        "IsSubRequest",
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
                        dict["p01"] = Get("RequestID");
                        dict["p02"] = Get("BuildingID");
                        dict["p03"] = Get("ResidentID");
                        dict["p04"] = Get("MaintenanceCategoryID");
                        dict["p05"] = Get("PriorityID");
                        dict["p06"] = Get("Description_A");
                        dict["p07"] = Get("RequestNo");
                        dict["p08"] = Get("StatusName_A");
                        dict["p09"] = Get("MaintenanceCategoryFullPath_A");

                        rowsList.Add(dict);
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.BuildingMaintenanceRequestDataSetError = ex.Message;
            }

            var residentOptions = BuildOptions(dt2, "residentInfoID", "ResidentDisplayName");
            var buildingOptions = BuildOptions(dt3, "buildingDetailsID", "BuildingDisplayName");
            var categoryOptions = BuildOptions(dt4, "MaintenanceCategoryID", "FullPath_A");
            var priorityOptions = BuildOptions(dt5, "PriorityID", "PriorityName_A");

            var emptyBuildingOptions = new List<OptionItem>
            {
                new OptionItem { Value = "-1", Text = "اختر المستفيد أولاً" }
            };

            string dependsBuildingsByResidentUrl = "/crud/DDLFiltered?FK=residentInfoID&textcol=BuildingDisplayName&ValueCol=buildingDetailsID&PageName=BuildingMaintenanceRequest&TableIndex=3";
            string antiForgeryToken = Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "";
            string currentHostName = HostName ?? Request.Host.Value;

            var addFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERTBUILDINGMAINTENANCEREQUEST" },
                new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId },
                new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId },
                new FieldConfig { Name = "hostname", Type = "hidden", Value = currentHostName },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },

                new FieldConfig { Name = "p02", Label = "المستفيد", Type = "select", Required = true, ColCss = "6", Options = residentOptions, Select2 = true },
                new FieldConfig { Name = "p01", Label = "المبنى", Type = "select", Required = true, ColCss = "6", Options = emptyBuildingOptions, Select2 = true, DependsOn = "p02", DependsUrl = dependsBuildingsByResidentUrl },
                new FieldConfig { Name = "p03", Label = "نوع الصيانة", Type = "select", Required = true, ColCss = "6", Options = categoryOptions, Select2 = true },
                new FieldConfig { Name = "p04", Label = "الأولوية", Type = "select", Required = true, ColCss = "6", Options = priorityOptions, Select2 = true },
                new FieldConfig { Name = "p05", Label = "وصف المشكلة", Type = "textarea", Required = true, ColCss = "12" }
            };

            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "UPDATEBUILDINGMAINTENANCEREQUEST" },
                new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId },
                new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId },
                new FieldConfig { Name = "hostname", Type = "hidden", Value = currentHostName },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p03", Label = "المستفيد", Type = "hidden", Required = true, ColCss = "6", Options = residentOptions, Select2 = true },
                new FieldConfig { Name = "p02", Label = "المبنى", Type = "hidden", Required = true, ColCss = "6", Options = buildingOptions, Select2 = true, DependsOn = "p03", DependsUrl = dependsBuildingsByResidentUrl },
                new FieldConfig { Name = "p04", Label = "نوع الصيانة", Type = "select", Required = true, ColCss = "6", Options = categoryOptions, Select2 = true },
                new FieldConfig { Name = "p05", Label = "الأولوية", Type = "select", Required = true, ColCss = "6", Options = priorityOptions, Select2 = true },
                new FieldConfig { Name = "p06", Label = "وصف المشكلة", Type = "textarea", Required = true, ColCss = "12" }
            };

            var cancelFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "CANCELBUILDINGMAINTENANCEREQUEST" },
                new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId },
                new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId },
                new FieldConfig { Name = "hostname", Type = "hidden", Value = currentHostName },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "سبب الإلغاء", Type = "textarea", Required = false, ColCss = "12" }
            };

            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                PageTitle = "طلبات الصيانة",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = new List<string> { "RequestNo", "MaintenanceCategoryName_A", "PriorityName_A", "StatusName_A" },
                Searchable = true,
                AllowExport = true,
                PanelTitle = "طلبات الصيانة",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canInsertBUILDINGMAINTENANCEREQUEST,
                    ShowEdit = canUpdateBUILDINGMAINTENANCEREQUEST,
                    ShowDelete = canCancelBUILDINGMAINTENANCEREQUEST,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,

                    Add = new TableAction
                    {
                        Label = "إضافة طلب صيانة",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة طلب صيانة",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingMaintenanceRequestInsertForm",
                            Title = "بيانات طلب الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = addFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            }
                        }
                    },

                    Edit = new TableAction
                    {
                        Label = "تعديل طلب",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل طلب صيانة",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingMaintenanceRequestUpdateForm",
                            Title = "تعديل طلب الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = updateFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1,
                        Guards = new TableActionGuards
                        {
                            AppliesTo = "any",
                            DisableWhenAny = new List<TableActionRule>
                            {
                                new TableActionRule
                                {
                                    Field = "StatusCode",
                                    Op = "neq",
                                    Value = "NEW",
                                    Message = "لا يمكن تعديل الطلب إلا إذا كانت حالته جديد",
                                    Priority = 3
                                }
                            }
                        }
                    },

                    Delete = new TableAction
                    {
                        Label = "إلغاء الطلب",
                        Icon = "fa fa-ban",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "إلغاء طلب الصيانة",
                        ModalMessage = "هل أنت متأكد من إلغاء طلب الصيانة المحدد؟",
                        ModalMessageClass = "bg-red-50 border border-red-200 text-red-700",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingMaintenanceRequestCancelForm",
                            Title = "إلغاء طلب الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Fields = cancelFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "إلغاء الطلب", Type = "submit", Color = "danger" },
                                new FormButtonConfig { Text = "تراجع", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            }
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1,
                        Guards = new TableActionGuards
                        {
                            AppliesTo = "any",
                            DisableWhenAny = new List<TableActionRule>
                            {
                                new TableActionRule { Field = "StatusCode", Op = "eq", Value = "CLOSED", Message = "لا يمكن إلغاء طلب مغلق", Priority = 3 },
                                new TableActionRule { Field = "StatusCode", Op = "eq", Value = "COMPLETED", Message = "لا يمكن إلغاء طلب مكتمل", Priority = 3 },
                                new TableActionRule { Field = "StatusCode", Op = "eq", Value = "CANCELLED", Message = "الطلب ملغي مسبقاً", Priority = 3 }
                            }
                        }
                    }
                }
            };

            dsModel.StyleRules = new List<TableStyleRule>
            {
                new TableStyleRule
                {
                    Target = "row", Field = "StatusCode", Op = "eq", Value = "NEW", Priority = 1,
                    PillEnabled = true,
                    PillField = "StatusName_A",
                    PillTextField = "StatusName_A",
                    PillCssClass = "pill pill-green",
                    PillMode = "replace"
                },
                new TableStyleRule
                {
                    Target = "row", Field = "StatusCode", Op = "eq", Value = "CANCELLED", Priority = 1,
                    PillEnabled = true,
                    PillField = "StatusName_A",
                    PillTextField = "StatusName_A",
                    PillCssClass = "pill pill-red",
                    PillMode = "replace"
                }
            };

            var page = new SmartFoundation.UI.ViewModels.SmartPage.SmartPageViewModel
            {
                PageTitle = "طلبات الصيانة",
                PanelTitle = "طلبات الصيانة",
                PanelIcon = "fa-screwdriver-wrench",
                TableDS = dsModel
            };

            return View("BuildingMaintenanceRequest", page);
        }

        private static List<OptionItem> BuildOptions(DataTable? table, string valueColumn, string textColumn)
        {
            var options = new List<OptionItem>
            {
                new OptionItem { Value = "-1", Text = "الرجاء الاختيار" }
            };

            if (table == null || !table.Columns.Contains(valueColumn) || !table.Columns.Contains(textColumn))
                return options;

            foreach (DataRow row in table.Rows)
            {
                options.Add(new OptionItem
                {
                    Value = row[valueColumn] == DBNull.Value ? "" : row[valueColumn]?.ToString() ?? "",
                    Text = row[textColumn] == DBNull.Value ? "" : row[textColumn]?.ToString() ?? ""
                });
            }

            return options;
        }
    }
}
