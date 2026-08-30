using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;

namespace SmartFoundation.Mvc.Controllers.Maintenance
{
    public partial class MaintenanceController : Controller
    {
        public async Task<IActionResult> BuildingMaintenanceRequestFollowUp(long? id = null)
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = string.IsNullOrWhiteSpace(PageName) ? "BuildingMaintenanceRequestFollowUp" : PageName;

            var spParameters = new object?[]
            {
                PageName ?? "BuildingMaintenanceRequestFollowUp",
                IdaraId,
                usersId,
                HostName,
                id
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
            bool canAssignMAINTENANCETECHNICIAN = false;
            bool canAddINSPECTIONREPORT = false;
            bool canStartMAINTENANCEWORK = false;
            bool canCompleteMAINTENANCEWORK = false;
            bool canCloseMAINTENANCEREQUEST = false;

            try
            {
                foreach (DataRow row in permissionTable.Rows)
                {
                    var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                    if (permissionName == "ASSIGNMAINTENANCETECHNICIAN") canAssignMAINTENANCETECHNICIAN = true;
                    if (permissionName == "ADDINSPECTIONREPORT") canAddINSPECTIONREPORT = true;
                    if (permissionName == "STARTMAINTENANCEWORK") canStartMAINTENANCEWORK = true;
                    if (permissionName == "COMPLETEMAINTENANCEWORK") canCompleteMAINTENANCEWORK = true;
                    if (permissionName == "CLOSEMAINTENANCEREQUEST") canCloseMAINTENANCEREQUEST = true;
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
                        ["MaintenanceCategoryName_A"] = "نوع الصيانة",
                        ["MaintenanceCategoryFullPath_A"] = "مسار نوع الصيانة",
                        ["StatusName_A"] = "الحالة",
                        ["StatusCode"] = "رمز الحالة",
                        ["PriorityName_A"] = "الأولوية",
                        ["LastActionDate"] = "تاريخ آخر إجراء",
                        ["LastActionTypeName_A"] = "آخر إجراء",
                        ["LastActionTypeCode"] = "رمز آخر إجراء",
                        ["LastActionNote"] = "ملاحظات آخر إجراء",
                        ["CanCloseMaintenanceRequest"] = "إمكانية الإغلاق",
                        ["Description_A"] = "وصف المشكلة"
                    };

                    var visibleColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                    {
                        "RequestNo",
                        "MaintenanceCategoryName_A",
                        "StatusName_A",
                        "PriorityName_A",
                        "LastActionTypeName_A",
                        "LastActionDate",
                        "RequestDate"
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
                            Visible = visibleColumns.Contains(c.ColumnName)
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
                        dict["p07"] = Get("RequestNo");
                        dict["p08"] = Get("StatusName_A");
                        dict["p09"] = Get("MaintenanceCategoryFullPath_A");

                        rowsList.Add(dict);
                    }
                }
            }
            catch (Exception)
            {
                ViewBag.BuildingMaintenanceRequestFollowUpDataSetError = "حدث خطأ أثناء تحميل البيانات. يرجى المحاولة مرة أخرى.";
            }

            var reasonOptions = BuildOptions(dt4, "ReasonID", "ReasonName_A");
            var technicianOptions = BuildOptions(dt5, "usersID", "UserDisplayName");

            string antiForgeryToken = Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "";
            string currentHostName = HostName ?? Request.Host.Value;

            var assignFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "ASSIGNMAINTENANCETECHNICIAN" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "الفني", Type = "select", Required = true, ColCss = "6", Options = technicianOptions, Select2 = true },
                new FieldConfig { Name = "p03", Label = "ملاحظات الإسناد", Type = "textarea", Required = false, ColCss = "6" }
            };

            var inspectionFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "ADDINSPECTIONREPORT" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "تقرير المعاينة", Type = "textarea", Required = true, ColCss = "12" },
                new FieldConfig { Name = "p03", Label = "السبب", Type = "select", Required = true, ColCss = "6", Options = reasonOptions, Select2 = true }
            };

            var startFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "STARTMAINTENANCEWORK" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "ملاحظات البدء", Type = "textarea", Required = false, ColCss = "12" }
            };

            var completeFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "COMPLETEMAINTENANCEWORK" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "ملاحظات الإنهاء", Type = "textarea", Required = false, ColCss = "12" }
            };

            var closeFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType", Type = "hidden", Value = "CLOSEMAINTENANCEREQUEST" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = antiForgeryToken },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "RequestID" },
                new FieldConfig { Name = "p07", Label = "رقم الطلب", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p08", Label = "الحالة", Type = "text", Readonly = true, ColCss = "6" },
                new FieldConfig { Name = "p02", Label = "ملاحظات الإغلاق", Type = "textarea", Required = false, ColCss = "12" }
            };

            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                PageTitle = "متابعة طلب الصيانة",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = new List<string> { "RequestNo", "MaintenanceCategoryName_A", "StatusName_A", "PriorityName_A" },
                Searchable = true,
                AllowExport = true,
                PanelTitle = "متابعة طلب الصيانة",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = false,
                    ShowEdit = false,
                    ShowEdit1 = canAssignMAINTENANCETECHNICIAN,
                    ShowEdit2 = canAddINSPECTIONREPORT,
                    ShowDelete = canStartMAINTENANCEWORK,
                    ShowDelete1 = canCompleteMAINTENANCEWORK,
                    ShowDelete2 = canCloseMAINTENANCEREQUEST,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,
                    Edit1 = new TableAction
                        {
                            Label = "إسناد فني",
                            Icon = "fa fa-user-gear",
                            Color = "success",
                            OpenModal = true,
                            ModalTitle = "إسناد فني",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceFollowUpAssignForm",
                                Title = "إسناد فني",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = assignFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "إسناد", Type = "submit", Color = "success" },
                                    new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                                    new TableActionRule { Field = "StatusCode", Op = "eq", Value = "CLOSED", Message = "لا يمكن إسناد فني لطلب مغلق", Priority = 3 },
                                    new TableActionRule { Field = "StatusCode", Op = "eq", Value = "CANCELLED", Message = "لا يمكن إسناد فني لطلب ملغي", Priority = 3 },
                                    new TableActionRule { Field = "StatusCode", Op = "eq", Value = "COMPLETED", Message = "لا يمكن إسناد فني لطلب مكتمل", Priority = 3 }
                                }
                            }
                        },
                    Edit2 = new TableAction
                        {
                            Label = "تسجيل تقرير معاينة",
                            Icon = "fa fa-clipboard-check",
                            Color = "info",
                            OpenModal = true,
                            ModalTitle = "تسجيل تقرير معاينة",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceFollowUpInspectionForm",
                                Title = "تسجيل تقرير معاينة",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = inspectionFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "حفظ التقرير", Type = "submit", Color = "info" },
                                    new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                                    new TableActionRule
                                    {
                                        Field = "StatusCode",
                                        Op = "neq",
                                        Value = "UNDER_INSPECTION",
                                        Message = "لا يمكن تسجيل تقرير المعاينة قبل إسناد فني للطلب",
                                        Priority = 3
                                    }
                                }
                            }
                        },
                    Delete = new TableAction
                        {
                            Label = "بدء التنفيذ",
                            Icon = "fa fa-play",
                            Color = "warning",
                            OpenModal = true,
                            ModalTitle = "بدء التنفيذ",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceFollowUpStartForm",
                                Title = "بدء التنفيذ",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = startFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "بدء التنفيذ", Type = "submit", Color = "warning" },
                                    new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                                    new TableActionRule
                                    {
                                        Field = "LastActionTypeCode",
                                        Op = "neq",
                                        Value = "INSPECTION_REPORT",
                                        Message = "لا يمكن بدء التنفيذ قبل تسجيل تقرير المعاينة",
                                        Priority = 3
                                    }
                                }
                            }
                        },
                    Delete1 = new TableAction
                        {
                            Label = "إنهاء التنفيذ",
                            Icon = "fa fa-check",
                            Color = "success",
                            OpenModal = true,
                            ModalTitle = "إنهاء التنفيذ",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceFollowUpCompleteForm",
                                Title = "إنهاء التنفيذ",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = completeFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "إنهاء التنفيذ", Type = "submit", Color = "success" },
                                    new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                                    new TableActionRule
                                    {
                                        Field = "StatusCode",
                                        Op = "neq",
                                        Value = "IN_PROGRESS",
                                        Message = "لا يمكن إنهاء التنفيذ قبل بدء العمل",
                                        Priority = 3
                                    }
                                }
                            }
                        },
                    Delete2 = new TableAction
                        {
                            Label = "إغلاق الطلب",
                            Icon = "fa fa-lock",
                            Color = "danger",
                            OpenModal = true,
                            ModalTitle = "إغلاق الطلب",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceFollowUpCloseForm",
                                Title = "إغلاق الطلب",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = closeFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "إغلاق", Type = "submit", Color = "danger" },
                                    new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                                    new TableActionRule
                                    {
                                        Field = "CanCloseMaintenanceRequest",
                                        Op = "neq",
                                        Value = "1",
                                        Message = "لا يمكن إغلاق الطلب قبل تسجيل تقرير المعاينة",
                                        Priority = 3
                                    }
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
                    Target = "row", Field = "StatusCode", Op = "eq", Value = "CLOSED", Priority = 1,
                    PillEnabled = true,
                    PillField = "StatusName_A",
                    PillTextField = "StatusName_A",
                    PillCssClass = "pill pill-red",
                    PillMode = "replace"
                }
            };

            var page = new SmartFoundation.UI.ViewModels.SmartPage.SmartPageViewModel
            {
                PageTitle = "متابعة طلب الصيانة",
                PanelTitle = "متابعة طلب الصيانة",
                PanelIcon = "fa-list-check",
                TableDS = dsModel
            };

            return View("BuildingMaintenanceRequestFollowUp", page);
        }

    }
}
