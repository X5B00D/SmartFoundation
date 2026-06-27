using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;

namespace SmartFoundation.Mvc.Controllers.Maintenance
{
    public partial class MaintenanceController : Controller
    {
        public async Task<IActionResult> MaintenanceCategory()
        {
            //  تهيئة بيانات الصفحة (السيشن + ControllerName + PageName...)
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = string.IsNullOrWhiteSpace(PageName) ? "MaintenanceCategory" : PageName;

            var spParameters = new object?[]
            {
             PageName ?? "MaintenanceCategory",
             IdaraId,
             usersId,
             HostName
            };
            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();

            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

            //  تقسيم الداتا سيت للجدول الأول + جداول أخرى
            SplitDataSet(ds);

            //  التحقق من الصلاحيات
            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }

            string rowIdField = "MaintenanceCategoryID";
            bool canInsertMAINTENANCECATEGORY = false;
            bool canUpdateMAINTENANCECATEGORY = false;
            bool canDeleteMAINTENANCECATEGORY = false;
            bool canRouteMAINTENANCECATEGORY = false;

            try
            {
                if (ds != null && ds.Tables.Count > 0 && permissionTable!.Rows.Count > 0)
                {
                    // 🔐 قراءة الصلاحيات من الجدول الأول
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "INSERTMAINTENANCECATEGORY") canInsertMAINTENANCECATEGORY = true;
                        if (permissionName == "UPDATEMAINTENANCECATEGORY") canUpdateMAINTENANCECATEGORY = true;
                        if (permissionName == "DELETEMAINTENANCECATEGORY") canDeleteMAINTENANCECATEGORY = true;
                        if (permissionName == "ROUTEMAINTENANCECATEGORY") canRouteMAINTENANCECATEGORY = true;
                    }

                    if (dt1 != null && dt1.Rows.Count > 0)
                    {
                        // 🔑 تحديد حقل الـ Id
                        rowIdField = "MaintenanceCategoryID";
                        var possibleIdNames = new[] { "MaintenanceCategoryID", "maintenanceCategoryID" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        // 🏷️ عناوين الأعمدة بالعربي
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["MaintenanceCategoryID"] = "الرقم المرجعي",
                            ["CategoryName_A"] = "نوع الصيانة",
                            ["CategoryName_E"] = "الاسم بالإنجليزي",
                            ["Description_A"] = "الوصف",
                            ["DisplayOrder"] = "الترتيب",
                            ["LevelNo"] = "المستوى",
                            ["DSDName_A"] = "الجهة المسؤولة",
                            ["FullPath_A"] = "المسار الكامل",
                            ["HasChildren"] = "له أبناء"
                        };

                        // 🧱 الأعمدة
                        foreach (DataColumn c in dt1.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                            // إخفاء بعض الأعمدة
                            bool isMaintenanceCategoryID = c.ColumnName.Equals("MaintenanceCategoryID", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraId = c.ColumnName.Equals("IdaraId", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraId_FK = c.ColumnName.Equals("IdaraId_FK", StringComparison.OrdinalIgnoreCase);
                            bool isParentID = c.ColumnName.Equals("ParentID", StringComparison.OrdinalIgnoreCase);
                            bool isDisplayOrder = c.ColumnName.Equals("DisplayOrder", StringComparison.OrdinalIgnoreCase);
                            bool isIsActive = c.ColumnName.Equals("IsActive", StringComparison.OrdinalIgnoreCase);
                            bool islevelInt = c.ColumnName.Equals("levelInt", StringComparison.OrdinalIgnoreCase);
                            bool isResponsibleDSDIDt = c.ColumnName.Equals("ResponsibleDSDID", StringComparison.OrdinalIgnoreCase);
                            bool isHasChildren = c.ColumnName.Equals("HasChildren", StringComparison.OrdinalIgnoreCase);

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true,
                                Visible = !(isMaintenanceCategoryID || isIdaraId || isIdaraId_FK || isParentID || isDisplayOrder || isIsActive || islevelInt || isResponsibleDSDIDt || isHasChildren)
                            });
                        }

                        //  الصفوف
                        foreach (DataRow r in dt1.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt1.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                            // التأكد من وجود حقل الـ Id
                            if (!dict.ContainsKey(rowIdField))
                            {
                                if (rowIdField.Equals("MaintenanceCategoryID", StringComparison.OrdinalIgnoreCase) &&
                                    dict.TryGetValue("MaintenanceCategoryID", out var alt))
                                    dict["MaintenanceCategoryID"] = alt;
                                else if (rowIdField.Equals("maintenanceCategoryID", StringComparison.OrdinalIgnoreCase) &&
                                         dict.TryGetValue("maintenanceCategoryID", out var alt2))
                                    dict["maintenanceCategoryID"] = alt2;
                            }

                            // تعبئة p01..p07 لاستخدامها في الفورم
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("MaintenanceCategoryID");
                            dict["p02"] = Get("ParentID");
                            dict["p03"] = Get("CategoryName_A");
                            dict["p04"] = Get("CategoryName_E");
                            dict["p05"] = Get("Description_A");
                            dict["p06"] = Get("DisplayOrder");
                            dict["p07"] = Get("FullPath_A");

                            rowsList.Add(dict);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.MaintenanceCategoryDataSetError = ex.Message;
            }

            var parentOptions = new List<OptionItem>();
            if (dt2 != null)
            {
                foreach (DataRow r in dt2.Rows)
                {
                    parentOptions.Add(new OptionItem
                    {
                        Value = r["MaintenanceCategoryID"] == DBNull.Value ? "" : r["MaintenanceCategoryID"]?.ToString() ?? "",
                        Text = r["FullPath_A"] == DBNull.Value ? "" : r["FullPath_A"]?.ToString() ?? ""
                    });
                }
            }

            var dsdOptions = new List<OptionItem>();
            if (dt3 != null)
            {
                foreach (DataRow r in dt3.Rows)
                {
                    dsdOptions.Add(new OptionItem
                    {
                        Value = r["DSDID"] == DBNull.Value ? "" : r["DSDID"]?.ToString() ?? "",
                        Text = r["DSDName_A"] == DBNull.Value ? "" : r["DSDName_A"]?.ToString() ?? ""
                    });
                }
            }

            //  ADD fields
            var addFields = new List<FieldConfig>
            {
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", Value = "" },

                new FieldConfig
                {
                    Name = "p12",
                    Label = "اسم نوع الصيانة بالعربي",
                    Autocomplete = "off",
                    Type = "text",
                    ColCss = "6",
                    Required = true,
                    TextMode = "arabic",
                    HelpText = "اكتب أحرف عربية فقط",
                },
                new FieldConfig { Name = "p13", Label = "الاسم بالإنجليزي", Type = "text", ColCss = "6", Required = false, TextMode = "english" },
                new FieldConfig { Name = "p14", Label = "الوصف", Type = "textarea", ColCss = "6", Required = false },
                new FieldConfig { Name = "p15", Label = "الترتيب", Type = "hidden", ColCss = "3", Required = false }
            };

            // hidden fields المشتركة
            addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = Request.Host.Value });
            addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERTMAINTENANCECATEGORY" });
            addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });
            addFields.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            addFields.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });

            //  ADD CHILD fields
            var addChildFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "INSERTMAINTENANCECATEGORY" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "MaintenanceCategoryID" },
                new FieldConfig { Name = "p12", Label = "اسم نوع الصيانة بالعربي", Type = "text", Required = true, ColCss = "6", TextMode = "arabic" },
                new FieldConfig { Name = "p13", Label = "الاسم بالإنجليزي", Type = "text", Required = false, ColCss = "6", TextMode = "english" },
                new FieldConfig { Name = "p14", Label = "الوصف", Type = "textarea", Required = false, ColCss = "6" },
                new FieldConfig { Name = "p15", Label = "الترتيب", Type = "hidden", Required = false, ColCss = "3" }
            };

            // âœï¸ UPDATE fields
            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "UPDATEMAINTENANCECATEGORY" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "الرقم المرجعي", Type = "hidden", Readonly = true, ColCss = "3" },
                new FieldConfig { Name = "p02", Label = "التصنيف الأب", Type = "select", Required = false, ColCss = "4", Options = parentOptions, Select2 = true },
                new FieldConfig { Name = "p03", Label = "اسم نوع الصيانة بالعربي", Type = "text", Required = true, ColCss = "4", TextMode = "arabic" },
                new FieldConfig { Name = "p04", Label = "الاسم بالإنجليزي", Type = "text", Required = false, ColCss = "4", TextMode = "english" },
                new FieldConfig { Name = "p05", Label = "الوصف", Type = "textarea", Required = false, ColCss = "6" },
                new FieldConfig { Name = "p06", Label = "الترتيب", Type = "hidden", Required = false, ColCss = "3" }
            };

            // ðŸ—‘ï¸ DELETE fields
            var deleteFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_",          Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETEMAINTENANCECATEGORY" },
                new FieldConfig { Name = "idaraID",            Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",          Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",           Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "MaintenanceCategoryID" },
                new FieldConfig { Name = "p03", Label = "نوع الصيانة", Type = "text", Required = false, Readonly = true, ColCss = "6", TextMode = "arabic" },
                new FieldConfig { Name = "p07", Label = "المسار الكامل", Type = "text", Required = false, Readonly = true, ColCss = "6" },
            };

            // ROUTE fields
            var routeFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "ROUTEMAINTENANCECATEGORY" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "MaintenanceCategoryID" },
                new FieldConfig { Name = "p02", Label = "الجهة المسؤولة", Type = "select", Required = true, ColCss = "6", Options = dsdOptions, Select2 = true },
                new FieldConfig { Name = "p13", Label = "ملاحظات", Type = "textarea", Required = false, ColCss = "6" }
            };

            // UNROUTE fields
            var unrouteFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "ROUTEMAINTENANCECATEGORY" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "MaintenanceCategoryID" },
                new FieldConfig { Name = "p02", Type = "hidden", Value = "0" },
                new FieldConfig { Name = "p13", Label = "سبب إلغاء الربط", Type = "textarea", Required = false, ColCss = "12" }
            };

            //  SmartTable model
            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                PageTitle = "أنواع الصيانة",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                PanelTitle = "أنواع الصيانة",

                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canInsertMAINTENANCECATEGORY,
                    ShowEdit = canUpdateMAINTENANCECATEGORY,
                    ShowDelete = canDeleteMAINTENANCECATEGORY,
                    ShowBulkDelete = false,
                    ShowExportPdf = false,
                    ShowPrint = false,
                    ShowPrint1 = false,

                    Add = new TableAction
                    {
                        Label = "إضافة نوع رئيسي",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة نوع رئيسي",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceCategoryInsertForm",
                            Title = "بيانات نوع الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = addFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ",   Type = "submit", Color = "success" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            }
                        }
                    },

                    CustomActions = new List<TableAction>
                    {
                        new TableAction
                        {
                            Label = "إضافة نوع فرعي",
                            Icon = "fa fa-plus",
                            Color = "success",
                            OpenModal = true,
                            ModalTitle = "إضافة نوع فرعي",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceCategoryChildInsertForm",
                                Title = "بيانات نوع الصيانة الفرعي",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = addChildFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "حفظ",   Type = "submit", Color = "success" },
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
                                        Field = "ResponsibleDSDID",
                                        Op = "neq",
                                        Value = "0",
                                        Message = "لا يمكن إضافة نوع فرعي لتصنيف مرتبط بجهة مسؤولة، ألغِ الربط أولاً",
                                        Priority = 3
                                    }
                                }
                            }
                        },
                        new TableAction
                        {
                            Label = "ربط الجهة المسؤولة",
                            Icon = "fa fa-link",
                            Color = "info",
                            Show = canRouteMAINTENANCECATEGORY,
                            OpenModal = true,
                            ModalTitle = "ربط الجهة المسؤولة",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceCategoryRouteForm",
                                Title = "بيانات الجهة المسؤولة",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = routeFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "حفظ",   Type = "submit", Color = "success" },
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
                                        Field = "HasChildren",
                                        Op = "eq",
                                        Value = "1",
                                        Message = "لا يمكن ربط الجهة المسؤولة بتصنيف يحتوي على أبناء، اختر آخر مستوى",
                                        Priority = 3
                                    }
                                }
                            }
                        },
                        new TableAction
                        {
                            Label = "إلغاء ربط الجهة المسؤولة",
                            Icon = "fa fa-unlink",
                            Color = "warning",
                            Show = canRouteMAINTENANCECATEGORY,
                            OpenModal = true,
                            ModalTitle = "إلغاء ربط الجهة المسؤولة",
                            ModalMessage = "هل أنت متأكد من إلغاء ربط الجهة المسؤولة عن نوع الصيانة المحدد؟",
                            ModalMessageClass = "bg-yellow-50 border border-yellow-200 text-yellow-700",
                            OpenForm = new FormConfig
                            {
                                FormId = "MaintenanceCategoryUnrouteForm",
                                Title = "إلغاء ربط الجهة المسؤولة",
                                Method = "post",
                                ActionUrl = "/crud/insert",
                                Fields = unrouteFields,
                                Buttons = new List<FormButtonConfig>
                                {
                                    new FormButtonConfig { Text = "إلغاء الربط", Type = "submit", Color = "warning" },
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
                                        Field = "ResponsibleDSDID",
                                        Op = "eq",
                                        Value = "0",
                                        Message = "لا يوجد ربط جهة مسؤولة لإلغائه",
                                        Priority = 3
                                    }
                                }
                            }
                        }
                    },

                    Edit = new TableAction
                    {
                        Label = "تعديل نوع",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل نوع الصيانة",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceCategoryEditForm",
                            Title = "تعديل نوع الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = updateFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },

                    Delete = new TableAction
                    {
                        Label = "تعطيل نوع",
                        Icon = "fa fa-trash",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "<i class='fa fa-exclamation-triangle text-red-600 text-xl mr-2'></i> تحذير",
                        ModalMessage = "هل أنت متأكد من تعطيل نوع الصيانة؟",
                        ModalMessageClass = "bg-red-50 border border-red-200 text-red-700",
                        OpenForm = new FormConfig
                        {
                            FormId = "MaintenanceCategoryDeleteForm",
                            Title = "تأكيد تعطيل نوع الصيانة",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "تعطيل",   Type = "submit", Color = "danger",  },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            },
                            Fields = deleteFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                }
            };


            dsModel.StyleRules = new List<TableStyleRule>
                        {
                            new TableStyleRule
                            {
                                Target="row", Field="ResponsibleDSDID", Op="eq", Value="0", Priority=1,
                                PillEnabled=true,
                                PillField="DSDName_A",
                                PillTextField="DSDName_A",
                                PillCssClass="pill pill-red",
                                PillMode="replace"
                            },
                             new TableStyleRule
                            {
                                Target="row", Field="ResponsibleDSDID", Op="neq", Value="0", Priority=1,
                                PillEnabled=true,
                                PillField="DSDName_A",
                                PillTextField="DSDName_A",
                                PillCssClass="pill pill-green",
                                PillMode="replace"
                            },
                             new TableStyleRule
                            {
                                Target="row", Field="levelInt", Op="eq", Value="0", Priority=1,
                                PillEnabled=true,
                                PillField="LevelNo",
                                PillTextField="LevelNo",
                                PillCssClass="pill pill-green",
                                PillMode="replace"
                            },
                             new TableStyleRule
                            {
                                Target="row", Field="levelInt", Op="neq", Value="0", Priority=1,
                                PillEnabled=true,
                                PillField="LevelNo",
                                PillTextField="LevelNo",
                                PillCssClass="pill pill-yellow",
                                PillMode="replace"
                            }
                           
                        };


            var page = new SmartFoundation.UI.ViewModels.SmartPage.SmartPageViewModel
            {
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle,
                PanelIcon = "fa-screwdriver-wrench",
                TableDS = dsModel
            };

            return View("MaintenanceCategory", page);
        }
    }
}
