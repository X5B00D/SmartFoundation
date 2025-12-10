using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;


namespace SmartFoundation.Mvc.Controllers.Housing
{
    public partial class HousingController : Controller
    {
        public async Task<IActionResult> BuildingType()
        {
            //  قراءة السيشن والكونتكست
            if (!InitPageContext(out var redirect))
                return redirect!;

            var spParameters = new object?[] { PageName, IdaraID, userID, HostName };

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

            string rowIdField = "";
            bool canInsert = false;
            bool canUpdate = false;
            bool canDelete = false;

            try
            {
                if (ds != null && ds.Tables.Count > 0 && permissionTable!.Rows.Count > 0)
                {
                    // صلاحيات
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "INSERT") canInsert = true;
                        if (permissionName == "UPDATE") canUpdate = true;
                        if (permissionName == "DELETE") canDelete = true;
                    }

                    if (dt1 != null && dt1.Columns.Count > 0)
                    {
                        // RowId
                        rowIdField = "BuildingTypeID";
                        var possibleIdNames = new[] { "buildingTypeID", "BuildingTypeID", "Id", "ID" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        // عناوين الأعمدة بالعربي
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["buildingTypeID"] = "الرقم المرجعي",
                            ["buildingTypeCode"] = "رمز نوع المباني",
                            ["buildingTypeName_A"] = "اسم نوع المباني بالعربي",
                            ["buildingTypeName_E"] = "اسم نوع المباني بالانجليزي",
                            ["buildingTypeDescription"] = "ملاحظات"
                        };

                        // الأعمدة
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
                                Sortable = true
                            });
                        }

                        // الصفوف
                        foreach (DataRow r in dt1.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt1.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                            // p01..p05
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("buildingTypeID") ?? Get("BuildingTypeID");
                            dict["p02"] = Get("buildingTypeCode");
                            dict["p03"] = Get("buildingTypeName_A");
                            dict["p04"] = Get("buildingTypeName_E");
                            dict["p05"] = Get("buildingTypeDescription");

                            rowsList.Add(dict);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ViewBag.BuildingTypeDataSetError = ex.Message;
            }

            // ADD fields
            var addFields = new List<FieldConfig>
            {
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "رمز نوع المباني", Type = "text", ColCss = "3" },
                new FieldConfig { Name = "p02", Label = "اسم نوع المباني بالعربي", Type = "text", Required = true,
                    Placeholder = "حقل عربي فقط",
                    Icon = "fa-solid fa-user",
                    ColCss = "col-span-12 md:col-span-3",
                    MaxLength = 50,
                    TextMode = "arsentence",},
                new FieldConfig { Name = "p03", Label = "اسم نوع المباني بالانجليزي", Type = "text", ColCss = "3" , Required = true},
                new FieldConfig { Name = "p04", Label = "ملاحظات", Type = "text", ColCss = "3", Required = false }
            };

            // hidden fields
            addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = Request.Host.Value });
            addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = userID.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraID.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERT" });
            addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });
            addFields.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            addFields.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });

            // UPDATE fields
            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "UPDATE" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraID.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = userID.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "الرقم المرجعي",             Type = "hidden", Readonly = true, ColCss = "3" },
                new FieldConfig { Name = "p02", Label = "رمز نوع المباني",         Type = "number", Required = true,  ColCss = "3" },
                new FieldConfig { Name = "p03", Label = "اسم نوع المباني بالعربي", Type = "text",
                    ColCss = "3", Required = true, TextMode = "arsentence" },
                new FieldConfig { Name = "p04", Label = "اسم نوع المباني بالانجليزي", Type = "text", Required = true, ColCss = "3" },
                new FieldConfig { Name = "p05", Label = "ملاحظات",            Type = "text",   ColCss = "6" }
            };

            // DELETE fields
            var deleteFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_",          Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETE" },
                new FieldConfig { Name = "idaraID",            Type = "hidden", Value = IdaraID.ToString() },
                new FieldConfig { Name = "entrydata",          Type = "hidden", Value = userID.ToString() },
                new FieldConfig { Name = "hostname",           Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "BuildingTypeID" }
            };

            var dsModel = new SmartTableDsModel
            {
                PageTitle = "انواع المباني",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                PanelTitle = "عرض ",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = false,
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowDelete = canDelete,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة نوع مباني جديد",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إدخال بيانات نوع المباني الجديد",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeInsertForm",
                            Title = "بيانات نوع المباني الجديد",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            LabelText = "sami",
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
                        Label = "تعديل نوع المباني",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل بيانات نوع مباني",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeEditForm",
                            Title = "تعديل بيانات نوع مباني",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            LabelText = "sami",
                            Fields = updateFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },

                    Delete = new TableAction
                    {
                        Label = "حذف نوع مباني",
                        Icon = "fa fa-trash",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "<i class='fa fa-exclamation-triangle text-red-600 text-xl mr-2'></i> تحذير",
                        ModalMessage = "هل أنت متأكد من حذف هذا نوع المباني؟",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeDeleteForm",
                            Title = "تأكيد حذف نوع المباني",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            LabelText = "sami",
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حذف", Type = "submit", Color = "danger", Icon = "fa fa-save" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", Icon = "fa fa-times", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            },
                            Fields = deleteFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                }
            };

            return View("HousingDefinitions/BuildingType", dsModel);
        }
    }
}
