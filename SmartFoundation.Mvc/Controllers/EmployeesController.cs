using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Net;
using System.Net.Sockets;


namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        
        private readonly MastersServies _mastersServies;

       

        public EmployeesController( MastersServies mastersServies)
        {
            
            _mastersServies = mastersServies;
           
        }



        [HttpGet]
        public IActionResult ShowCityToast(string? cityId, string? cityName)
        {
            // Normalize
            cityId = (cityId ?? "").Trim();
            cityName = (string.IsNullOrWhiteSpace(cityName) ? null : cityName.Trim());

            // Build message (fallbacks if missing)
            var msg = (string.IsNullOrWhiteSpace(cityId) && string.IsNullOrWhiteSpace(cityName))
                ? "No city selected"
                : $"City: {cityName ?? "(unknown)"} ({cityId})";

            TempData["Info"] = msg;

            // Redirect back to the page (Sami) so Toastr in the layout/view can display the message
            return RedirectToAction(nameof(Sami));
        }


        public async Task<IActionResult> Sami()
        {

            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("userID")))
                return RedirectToAction("Index", "Login", new { logout = 1 });



            int userID = Convert.ToInt32(HttpContext.Session.GetString("userID"));
            string fullName = HttpContext.Session.GetString("fullName");
            int IdaraID = Convert.ToInt32(HttpContext.Session.GetString("IdaraID"));
            string DepartmentName = HttpContext.Session.GetString("DepartmentName");
            string ThameName = HttpContext.Session.GetString("ThameName");
            string DeptCode = HttpContext.Session.GetString("DeptCode");
            string IDNumber = HttpContext.Session.GetString("IDNumber");
            string HostName = HttpContext.Session.GetString("HostName");

            
            var spParameters = new object?[]{"BuildingType", IdaraID, userID, HostName };

            DataSet ds;
          
            
            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();


            ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

            DataTable? permissionTable = (ds?.Tables?.Count ?? 0) > 0 ? ds.Tables[0] : null;
            DataTable? dt1 = (ds?.Tables?.Count ?? 0) > 1 ? ds.Tables[1] : null;
            DataTable? dt2 = (ds?.Tables?.Count ?? 0) > 2 ? ds.Tables[2] : null;
            DataTable? dt3 = (ds?.Tables?.Count ?? 0) > 3 ? ds.Tables[3] : null;
            DataTable? dt4 = (ds?.Tables?.Count ?? 0) > 4 ? ds.Tables[4] : null;
            DataTable? dt5 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[5] : null;
            DataTable? dt6 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[6] : null;
            DataTable? dt7 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[7] : null;
            DataTable? dt8 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[8] : null;
            DataTable? dt9 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[9] : null;

            if(permissionTable is null || permissionTable.Rows.Count == 0)
            {

                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }

            string rowIdField ="";
            bool canInsert = false;
            bool canUpdate = false;
            bool canUpdateGN = false;
            bool canDelete = false;

            List<OptionItem> cityOptions = new();
            FormConfig form = new();
            try
            {


                //To make city options list for dropdownlist later

                if (ds != null && ds.Tables.Count > 1 && ds.Tables[1].Rows.Count > 0)
                    {
                        var cityTable = ds.Tables[2];

                        foreach (DataRow row in cityTable.Rows)
                        {
                            string value = row["cityID"]?.ToString()?.Trim() ?? "";
                            string text = row["cityName_A"]?.ToString()?.Trim() ?? "";

                            if (!string.IsNullOrEmpty(value))
                                cityOptions.Add(new OptionItem { Value = value, Text = text });
                        }
                    }






                 form = new FormConfig
                {
                    FormId = "dynamicForm",
                    Title = "نموذج الإدخال",
                    Method = "POST",
                    ActionUrl = "/AllComponentsDemo/ExecuteDemo",
                    SubmitText = "حفظ",
                    ResetText = "تفريغ",
                    ShowPanel = true,
                    ShowReset = true,
                    StoredProcedureName = "sp_SaveDemoForm",
                    Operation = "insert",
                    StoredSuccessMessageField = "Message",
                    StoredErrorMessageField = "Error",

                    Fields = new List<FieldConfig>
                {
                    // ========= البيانات الشخصية =========
                    new FieldConfig
                    {

                        SectionTitle="البيانات",
                        Name="FullName",
                        Label="إدخال نص",
                        Type="text",
                        Required=true,
                        Placeholder="حقل عربي فقط",
                        Icon="fa-solid fa-user",
                        ColCss="col-span-12 md:col-span-3",
                        MaxLength=50,
                        TextMode="arsentence",
                    },
                     new FieldConfig { Name = "City", Label = "المدينة", Type = "select",
                            Options = cityOptions, ColCss = "6", Placeholder = "اختر المدينة", Icon = "fa fa-city" },
                },

                    Buttons = new List<FormButtonConfig>
                {
                    new FormButtonConfig
                    {
                        Text="طباعة",
                        Icon="fa-solid fa-print",
                        Type="button",
                        Color="danger",
                        OnClickJs="window.print();"
                    },


                    new FormButtonConfig
                    {
                        Text="رجوع",
                        Icon="fa-solid fa-arrow-left",
                        Type="button",
                        Color="info",
                        OnClickJs="history.back();"
                    },
                    new FormButtonConfig
                {
                    Text="تجربة",
                    Icon="fa-solid fa-bullhorn",
                    Type="button",
                    Color="info",
                    // Replace the OnClickJs of the "تجربة" button with this:
                    OnClickJs = "(function(){"
          + "var hidden=document.querySelector('input[name=City]');"
          + "if(!hidden){toastr.error('لا يوجد حقل مدينة');return;}"
          + "var v=hidden.value||'';"
          + "var anchor=hidden.parentElement.querySelector('.sf-select');"
          + "var t=anchor && anchor.querySelector('.truncate') ? anchor.querySelector('.truncate').textContent.trim() : '';"
          + "var u='/Employees/ShowCityToast?cityId='+encodeURIComponent(v)+'&cityName='+encodeURIComponent(t);"
          + "window.location.href=u;"
          + "})();"
                },

                }
                };

                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    // اقرأ الجدول الأول
                    

                    // نبحث عن صلاحيات محددة داخل الجدول
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "INSERT")
                            canInsert = true;

                        if (permissionName == "UPDATE")
                            canUpdate = true;

                        if (permissionName == "UPDATEGN" || permissionName == "UPDATEGN")
                            canUpdateGN = true;

                        if (permissionName == "DELETE")
                            canDelete = true;
                    }


                    if (ds != null && ds.Tables.Count > 0)
                    {
                       
                        // Resolve a correct row id field (case sensitive match to actual DataTable column)
                        rowIdField = "BuildingTypeID";
                        var possibleIdNames = new[] { "buildingTypeID", "BuildingTypeID", "Id", "ID" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n)) 
                                     ?? dt1.Columns[0].ColumnName;

                        //For change table name to arabic 
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["buildingTypeID"] = "المعرف",
                            ["buildingTypeCode"] = "رمز المبنى",
                            ["buildingTypeName_A"] = "اسم المبنى بالعربي",
                            ["buildingTypeName_E"] = "اسم المبنى بالانجليزي",
                            ["buildingTypeDescription"] = "ملاحظات"
                        };


                        // build columns from DataTable schema
                        foreach (DataColumn c in dt1.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                                bool isbuildingTypeCode = c.ColumnName.Equals("buildingTypeCode", StringComparison.OrdinalIgnoreCase);

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                //if u want to hide any column 
                                //,Visible = !(isbuildingTypeCode)
                            });
                        }


                       
                        // build rows (plain dictionaries) so JSON serialization is clean
                        foreach (DataRow r in dt1.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt1.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                           // Ensure the row id key actually exists with correct casing
                           if (!dict.ContainsKey(rowIdField))
                           {
                               // Try to copy from a differently cased variant
                               if (rowIdField.Equals("buildingTypeID", StringComparison.OrdinalIgnoreCase) &&
                                   dict.TryGetValue("BuildingTypeID", out var alt))
                                   dict["buildingTypeID"] = alt;
                               else if (rowIdField.Equals("BuildingTypeID", StringComparison.OrdinalIgnoreCase) &&
                                        dict.TryGetValue("buildingTypeID", out var alt2))
                                   dict["BuildingTypeID"] = alt2;
                           }

                            // Prefill pXX fields on the row so Edit form (which uses pXX names) loads the selected row values
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("buildingTypeID") ?? Get("BuildingTypeID") ?? Get("Id") ?? Get("ID");
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
                ViewBag.EmployeeDataSetError = ex.Message;

                ViewBag.EmployeeTableCount = 0;
            }


            // Local helper: map TableColumn -> FieldConfig
          

            // Local helper: build Edit1 fields (prefer dataset column for general number or fallback)
           
            // build dynamic field lists
            // REPLACE Add form fields: hide dataset textboxes and use your own custom inputs

            //ADD
            var addFields = new List<FieldConfig>
            {
                // keep id hidden first so row id can flow when needed
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // your custom textboxes
                new FieldConfig { Name = "p01", Label = "رمز المبنى", Type = "text", ColCss = "3", Required = true },
                new FieldConfig { Name = "p02", Label = "اسم المبنى بالعربي",Type = "text", Placeholder="حقل عربي فقط",TextMode="arsentence",ColCss="3"},
                new FieldConfig { Name = "p03", Label = "اسم المبنى بالانجليزي", Type = "text", ColCss = "3" , Required = true},
                new FieldConfig { Name = "p04", Label = "ملاحظات", Type = "text", ColCss = "3", Required = false }
            };

           

            // Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = Request.Host.Value });
            addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = "60014016" });
            addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = "1" });
            addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERT" }); // upper-case
            addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = "BuildingType" });

           

            // Optional: help the generic endpoint know where to go back
            addFields.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = nameof(Sami) });
            addFields.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = "Employees" });




            //UPDATE
            // Keep pXX as the visible inputs. They will now prefill automatically from the selected row
            // because we injected p01..p05 into each row above.
            // UPDATE fields: make pXX visible (so the binding engine can copy selected row[pXX] values).
            // Do NOT hide p01 if you need to see the selected id; keep it readonly instead of hidden.
            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = nameof(Sami) },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = "Employees" },
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = "BuildingType" },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "UPDATE" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = "1" },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = "60014016" },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "المعرف",             Type = "hidden", Readonly = true, ColCss = "3" },
                new FieldConfig { Name = "p02", Label = "رمز المبنى",         Type = "number", Required = true,  ColCss = "3" },
                new FieldConfig { Name = "p03", Label = "اسم المبنى بالعربي", Type = "text",   ColCss = "3", TextMode = "arabic" },
                new FieldConfig { Name = "p04", Label = "اسم المبنى بالانجليزي", Type = "text", Required = true, ColCss = "3" },
                new FieldConfig { Name = "p05", Label = "ملاحظات",            Type = "text",   ColCss = "6" }
            };


            // Delete fields: show confirmation as a label (not textbox) and show ID as label while still posting p01
            var deleteFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = nameof(Sami) },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = "Employees" },
                new FieldConfig { Name = "pageName_",          Type = "hidden", Value = "BuildingType" },
                new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETE" },
                new FieldConfig { Name = "idaraID",            Type = "hidden", Value = "1" },
                new FieldConfig { Name = "entrydata",          Type = "hidden", Value = "60014016" },
                new FieldConfig { Name = "hostname",           Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },

                // selection context
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // hidden p01 actually posted to SP
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "BuildingTypeID" }
            };



            // then create dsModel (snippet shows toolbar parts that use the dynamic lists)
            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                PageTitle = "جميع المكونات",
                PanelTitle = "عرض ",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = false,
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowEdit1 = canUpdateGN,
                    ShowDelete = canDelete,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة موظف",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إدخال بيانات الموظف الجديد",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeInsertForm",
                            Title = "بيانات الموظف الجديد",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            LabelText = "sami", // <-- show 'sami' at top of Add form
                            Fields = addFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success", /*Icon = "fa fa-save"*/ },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", /*Icon = "fa fa-times",*/ OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            }
                        }
                    },

                    // Edit: opens populated form for single selection and saves via SP
                    Edit = new TableAction
                    {
                        Label = "تعديل موظف",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل بيانات الموظف",
                        //ModalMessage = "بسم الله الرحمن الرحيم",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل بيانات الموظف",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            LabelText = "sami", // <-- show 'sami' at top of Edit form
                            Fields = updateFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1


                    },

                    Delete = new TableAction
                    {
                        Label = "حذف موظف",
                        Icon = "fa fa-trash",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        //ModalTitle = "رسالة تحذيرية",
                        ModalTitle = "<i class='fa fa-exclamation-triangle text-red-600 text-xl mr-2'></i> تحذير",
                        ModalMessage = "هل أنت متأكد من حذف هذا السجل؟",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeDeleteForm",
                            Title = "تأكيد حذف السجل",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            LabelText = "sami", // <-- show 'sami' at top of Delete form
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

            var vm = new SmartFoundation.UI.ViewModels.SmartPage.FormTableViewModel
            {
                Form = form,
                Table = dsModel,
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle
            };
            return View("Sami", vm);
        }



        public IActionResult Index()
        {
            return View();
        }


    }
}
