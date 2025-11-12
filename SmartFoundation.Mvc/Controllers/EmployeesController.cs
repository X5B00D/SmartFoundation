using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Text.Json;
using System.Linq; 

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {

        private readonly MastersDataLoadService _mastersDataLoadService;

        bool canInsert = false;
        bool canUpdate = false;
        bool canUpdateGN = false;

        public EmployeesController(MastersDataLoadService mastersDataLoadService)
        {
            _mastersDataLoadService = mastersDataLoadService;
        }



        public IActionResult Index()
        {

            bool canInsert = false;
            bool canUpdate = false;
            bool canUpdateGN = false;
           



            //  الجدول الرئيسي
            var tableConfig = new TableConfig
            {
                Endpoint = "/smart/execute",
                StoredProcedureName = "dbo.sp_SmartFormDemo",
                Operation = "select_employees",
                PageSize = 10,
                PageSizes = new List<int> { 5, 10, 25, 50, 100 },
                MaxPageSize = 1000,
                Searchable = true,
                SearchPlaceholder = "ابحث بالاسم/الجوال/البريد/المدينة...",
                QuickSearchFields = new List<string> { "FullName", "Email", "City", "PhoneNumber" },
                AllowExport = true,
                ShowHeader = true,
                ShowFooter = true,
                AutoRefreshOnSubmit = true,
                Selectable = true,
                RowIdField = "EmployeeId",
                StorageKey = "EmployeesTablePrefs",

                Columns = new List<TableColumn>
                {
                    new TableColumn { Field="EmployeeId", Label="ID", Type="number", Width="80px", Align="center", Sortable=true },
                    new TableColumn { Field="FullName", Label="الاسم الكامل", Type="text", Sortable=true },
                    new TableColumn { Field="Email", Label="البريد الإلكتروني", Type="link", LinkTemplate="mailto:{Email}", Sortable=true },
                    new TableColumn { Field="PhoneNumber", Label="الجوال", Type="text", Sortable=true },
                    new TableColumn { Field="City", Label="المدينة", Sortable=true },
                    new TableColumn { Field="IBAN", Label="IBAN", Type="text", Sortable=true },
                    new TableColumn { Field="BirthDate", Label="تاريخ الميلاد", Type="date", FormatString="{0:yyyy-MM-dd}", Sortable=true },
                    new TableColumn { Field="AgreeTerms", Label="موافق؟", Type="bool", Align="center" }
                },

                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = true,
                    ShowAdd = false,
                    ShowEdit = false,
                    ShowEdit1 = false,
                    ShowBulkDelete = false,


                    Add = new TableAction
                    {
                        Label = "إضافة موظف",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة موظف",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeInsertForm",
                            Title = "بيانات الموظف الجديد",
                            ActionUrl = "/smart/execute",
                            StoredProcedureName = "dbo.sp_SmartFormDemo",
                            Operation = "insert_employee",
                            SubmitText = "حفظ",
                            CancelText = "إلغاء",

                            Fields = new List<FieldConfig>
                            {
                                new FieldConfig {
                                    Name = "FullName",
                                    Label = "الاسم الكامل",
                                    Type = "text",
                                    Required = true,
                                    ColCss = "6",
                                    Placeholder = "الاسم الرباعي",
                                    MaxLength = 100,
                                    Icon = "fa fa-user",
                                    Readonly = !canUpdate

                                },
                                new FieldConfig {
                                    Name = "Email",
                                    Label = "البريد الإلكتروني",
                                    Type = "text",
                                    TextMode = "email",
                                    Required = true,
                                    ColCss = "6",
                                    Placeholder = "example@email.com",
                                    MaxLength = 150,
                                    Icon = "fa fa-envelope"
                                },
                                new FieldConfig {
                                    Name = "NationalId",
                                    Label = "رقم الهوية",
                                    Type = "text",
                                    Required = true,
                                    ColCss = "3",
                                    Placeholder = "1234567890",
                                    MaxLength = 10,
                                    InputLang = "number",
                                    HelpText = "10 أرقام فقط",
                                    Icon = "fa fa-id-card"
                                },
                                new FieldConfig {
                                    Name = "PhoneNumber",
                                    Label = "الجوال",
                                    Type = "phone",
                                    Required = true,
                                    ColCss = "5",
                                    Placeholder = "05xxxxxxxx",
                                    MaxLength = 10,
                                    InputLang = "numeric",
                                    Icon = "fa fa-phone"
                                },
                                new FieldConfig {
                                    Name = "City",
                                    Label = "المدينة",
                                    Type = "select",
                                    Options = new List<OptionItem>{
                                        new OptionItem{Value="RYD",Text="الرياض"},
                                        new OptionItem{Value="JED",Text="جدة"},
                                        new OptionItem{Value="DMM",Text="الدمام"}
                                    },
                                    ColCss = "6",
                                    Placeholder = "اختر المدينة",
                                    Icon = "fa fa-city"
                                },
                                new FieldConfig {
                                    Name = "IBAN",
                                    Label = "الحساب البنكي (IBAN)",
                                    Type = "iban",
                                    ColCss = "6",
                                    Placeholder = "SAxxxxxxxxxxxxxxxxxxxx",
                                    MaxLength = 24,
                                    Icon = "fa fa-money-bill-transfer",
                                    HelpText = "يجب أن يبدأ بـ SA"
                                },
                                new FieldConfig {
                                    Name = "BirthDate",
                                    Label = "تاريخ الميلاد",
                                    Type = "date",
                                    ColCss = "6",
                                    HelpText = "اختر تاريخ ميلاد صحيح",
                                    Icon = "fa fa-calendar"
                                },
                                new FieldConfig {
                                    Name = "Notes",
                                    Label = "ملاحظات",
                                    Type = "textarea",
                                    ColCss = "4",
                                    MaxLength = 500,
                                    Placeholder = "اكتب ملاحظات إضافية هنا...",
                                    Icon = "fa fa-note-sticky"
                                },

                                new FieldConfig {
                                    Name = "AgreeTerms",
                                    Label = "أوافق على الشروط",
                                    Type = "checkbox",
                                    Required = true,
                                    ColCss = "6",
                                    Icon = "fa fa-check-square"
                                }
                            },

                            // الأزرار
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig {
                                    Text = "حفظ",
                                    Type = "submit",
                                    Color = "success",
                                    Icon = "fa fa-save"
                                },
                                new FormButtonConfig {
                                    Text = "إلغاء",
                                    Type = "button",
                                    Color = "secondary",
                                    Icon = "fa fa-times",
                                    OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();"
                                }
                            }
                        },
                        SaveSp = "dbo.sp_SmartFormDemo",
                        SaveOp = "insert_employee"
                    },

                    // زر التعديل (مثال)

                    Edit = new TableAction
                    {
                        Label = "تعديل موظف",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل موظف",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل بيانات الموظف",
                            ActionUrl = "/smart/execute",
                            StoredProcedureName = "dbo.sp_SmartFormDemo",
                            Operation = "update_employee",   //  عملية التعديل
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",

                            Fields = new List<FieldConfig>
        {
            new FieldConfig { Name = "EmployeeId", Type = "hidden" },
            new FieldConfig { Name = "FullName", Label = "الاسم الكامل", Type = "text", Required = true, ColCss="3" },
            new FieldConfig { Name = "Email", Label = "البريد الإلكتروني", Type = "text", TextMode="email", Required = true, ColCss="3" },
            new FieldConfig { Name = "NationalId", Label = "رقم الهوية", Type = "text", Required = true, ColCss="3" },
            new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone", Required = true, ColCss="3" },
            new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone", Required = true, ColCss="3" },
            new FieldConfig {
                Name = "City",
                Label = "المدينة",
                Type = "select",
                Options = new List<OptionItem>{
                    new OptionItem{Value="RYD",Text="الرياض"},
                    new OptionItem{Value="JED",Text="جدة"},
                    new OptionItem{Value="DMM",Text="الدمام"}
                },
                ColCss="3"
            },
            new FieldConfig { Name = "IBAN", Label = "IBAN", Type = "iban", ColCss="6" },
            new FieldConfig { Name = "BirthDate", Label = "تاريخ الميلاد", Type = "date", ColCss="6" },
            new FieldConfig { Name = "Notes", Label = "ملاحظات", Type = "textarea", ColCss="6" },
            new FieldConfig { Name = "AgreeTerms", Label = "أوافق على الشروط", Type = "checkbox", Required = true, ColCss="6" }
        }
                        },
                        SaveSp = "dbo.sp_SmartFormDemo",
                        SaveOp = "update_employee"
                    },


                    Edit1 = new TableAction
                    {
                        Label = "تعديل الرقم العام",
                        Icon = "fa fa-pen-to-square",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل الرقم العام",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل الرقم العام",
                            ActionUrl = "/smart/execute",
                            StoredProcedureName = "dbo.sp_SmartFormDemo",
                            Operation = "update_employee",   //  عملية التعديل
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",

                            Fields = new List<FieldConfig>
        {
            new FieldConfig { Name = "EmployeeId", Type = "hidden" },
            new FieldConfig { Name = "FullName", Label = "الاسم الكامل", Type = "text", Required = true, ColCss="3" },
            new FieldConfig { Name = "Email", Label = "البريد الإلكتروني", Type = "text", TextMode="email", Required = true, ColCss="3" },
            new FieldConfig { Name = "NationalId", Label = "رقم الهوية", Type = "text", Required = true, ColCss="3" },
            new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone", Required = true, ColCss="3" },
            new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone", Required = true, ColCss="3" },
            new FieldConfig {
                Name = "City",
                Label = "المدينة",
                Type = "select",
                Options = new List<OptionItem>{
                    new OptionItem{Value="RYD",Text="الرياض"},
                    new OptionItem{Value="JED",Text="جدة"},
                    new OptionItem{Value="DMM",Text="الدمام"}
                },
                ColCss="3"
            },
            new FieldConfig { Name = "IBAN", Label = "IBAN", Type = "iban", ColCss="6" },
            new FieldConfig { Name = "BirthDate", Label = "تاريخ الميلاد", Type = "date", ColCss="6" },
            new FieldConfig { Name = "Notes", Label = "ملاحظات", Type = "textarea", ColCss="6" },
            new FieldConfig { Name = "AgreeTerms", Label = "أوافق على الشروط", Type = "checkbox", Required = true, ColCss="6" }
        }
                        },
                        SaveSp = "dbo.sp_SmartFormDemo",
                        SaveOp = "update_employee"
                    }




                }

            };



            if (canInsert && tableConfig.Toolbar != null)
            {
                tableConfig.Toolbar.ShowAdd = true;

            }

            if (canUpdate && tableConfig.Toolbar != null)
            {
                tableConfig.Toolbar.ShowEdit = true;
            }

            if (canUpdateGN && tableConfig.Toolbar != null)
            {
                tableConfig.Toolbar.ShowEdit1 = true;
            }





            var vm = new SmartPageViewModel
            {
                PageTitle = "الموظفين",
                PanelTitle = "معلومات الموظفين",
                SpName = "dbo.sp_SmartFormDemo",
                Operation = "select_employees",
                Table = tableConfig
            };

            return View(vm);
        }


        public IActionResult EmployeeFields(int? id)
        {
            return Content("<div class='p-4 text-gray-700'>هنا يمكن وضع فورم التعديل لاحقاً</div>", "text/html");
        }


        public async Task<IActionResult> Sami()
        {
            
            var spParameters = new object?[]{"BuildingType",1,60014016,"hostname"};
            DataSet ds = await _mastersDataLoadService.GetDataLoadDataSetAsync(spParameters);
            List<OptionItem> cityOptions = new();


            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();
            string rowIdField = "Id";


            try
            {

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
               

                ViewBag.EmployeeDataSet = ds;

                // <-- new: pass table count to the view so client-side JS can show an alert
                ViewBag.EmployeeTableCount = ds?.Tables?.Count ?? 0;

                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    // اقرأ الجدول الأول
                    var permissionTable = ds.Tables[0];

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
                    }


                    if (ds != null && ds.Tables.Count > 0)
                    {
                        var dt = ds.Tables[1];

                        // pick a sensible row id field if present
                        var possibleIdNames = new[] { "EmployeeId", "Id", "ID", "employeeId", "id" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt.Columns.Contains(n)) ?? dt.Columns[0].ColumnName;


                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["EmployeeId"] = "المعرف",
                            ["FullName"] = "الاسم الكامل",
                            ["Department"] = "القسم",
                            ["JobTitle"] = "الوظيفة",
                            ["City"] = "المدينة",
                            ["IBAN"] = "IBAN رقم",
                            ["BirthDate"] = "تاريخ الميلاد",
                            ["Email"] = "الايميل",
                            ["PhoneNumber"] = "الجوال"
                        };


                        // build columns from DataTable schema
                        foreach (DataColumn c in dt.Columns)
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

                        // build rows (plain dictionaries) so JSON serialization is clean
                        foreach (DataRow r in dt.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }
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
            List<FieldConfig> BuildFieldsFromColumns(List<TableColumn> cols, string idField)
            {
                var list = new List<FieldConfig>();

                // ensure id hidden field is first
                list.Add(new FieldConfig { Name = idField, Type = "hidden" });

                foreach (var col in cols)
                {
                    if (string.Equals(col.Field, idField, StringComparison.OrdinalIgnoreCase))
                        continue;

                    var fc = new FieldConfig
                    {
                        Name = col.Field,
                        Label = string.IsNullOrWhiteSpace(col.Label) ? col.Field : col.Label,
                        ColCss = "3"
                    };

                    // map column type to field type with simple heuristics
                    switch ((col.Type ?? "text").ToLowerInvariant())
                    {
                        case "number":
                        case "int":
                        case "decimal":
                            fc.Type = "number";
                            fc.TextMode = "number";
                            break;
                        case "date":
                        case "datetime":
                            fc.Type = "date";
                            break;
                        case "bool":
                        case "boolean":
                            fc.Type = "checkbox";
                            break;
                        default:
                            fc.Type = "text";
                            break;
                    }

                    // name-based heuristics
                    var name = col.Field.ToLowerInvariant();
                    if (name.Contains("email"))
                    {
                        fc.TextMode = "email";
                    }
                    if (name.Contains("phone") || name.Contains("mobile"))
                    {
                        fc.Type = "phone";
                    }
                    if (name.Contains("iban"))
                    {
                        fc.Type = "iban";
                        fc.IsIban = true;
                    }
                    if (name == "city" || name.EndsWith("cityid"))
                    {
                        fc.Type = "select";
                        fc.Options = cityOptions; // reuse city options loaded from dataset
                    }

                    list.Add(fc);
                }

                return list;
            }

            // Local helper: build Edit1 fields (prefer dataset column for general number or fallback)
            List<FieldConfig> BuildEdit1Fields(List<TableColumn> cols, string idField)
            {
                var fields = new List<FieldConfig> { new FieldConfig { Name = idField, Type = "hidden" } };

                // try to find a "general number" column
                var gnCol = cols.FirstOrDefault(c => 
                   
                    c.Field.Equals("GeneralNo", StringComparison.OrdinalIgnoreCase)  ||
                    c.Field.IndexOf("general", StringComparison.OrdinalIgnoreCase) >= 0 && c.Field.IndexOf("num", StringComparison.OrdinalIgnoreCase) >= 0
                );

                if (gnCol != null)
                {
                    fields.AddRange(BuildFieldsFromColumns(new List<TableColumn> { gnCol }, idField).Skip(1)); // skip duplicate id
                }
                else
                {
                    // fallback field
                    fields.Add(new FieldConfig { Name = "GeneralNumber", Label = "الرقمb العام", Type = "text", ColCss = "3", Required = true });
                }

                // include Notes if present in dataset
                if (cols.Any(c => c.Field.Equals("Notes", StringComparison.OrdinalIgnoreCase)))
                {
                    fields.Add(new FieldConfig { Name = "Notes", Label = "ملاحظة", Type = "textarea", ColCss = "6" });
                }
                else
                {
                    fields.Add(new FieldConfig { Name = "Notes", Label = "ملاحظة", Type = "textarea", ColCss = "6" });
                }

                return fields;
            }

            // build dynamic field lists
            var addFields = BuildFieldsFromColumns(dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>(), rowIdField);
            var editFields = BuildFieldsFromColumns(dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>(), rowIdField);
            var edit1Fields = BuildEdit1Fields(dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>(), rowIdField);

            // then create dsModel (snippet shows toolbar parts that use the dynamic lists)
            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                Columns = dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>
                {
                    new TableColumn { Field="EmployeeId", Label="ID", Type="number", Width="80px", Align="center", Sortable=true },
                    new TableColumn { Field="FullName", Label="الاسم الكامل", Type="text", Sortable=true },
                    new TableColumn { Field="Email", Label="البريد الإلكتروني", Type="link", LinkTemplate="mailto:{Email}", Sortable=true },
                    new TableColumn { Field="PhoneNumber", Label="الجوال", Type="text", Sortable=true },
                    new TableColumn { Field="City", Label="المدينة", Sortable=true }
                },
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 5, 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = true,
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowEdit1 = canUpdateGN,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة موظف",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة موظف",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeInsertForm",
                            Title = "بيانات الموظف الجديد",
                            
                            SubmitText = "حفظ",
                            CancelText = "إلغاء",
                            Fields = addFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success", Icon = "fa fa-save" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", Icon = "fa fa-times", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
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
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل بيانات الموظف",
                            ActionUrl = "/smart/execute",
                            StoredProcedureName = "dbo.sp_SmartFormDemo",
                            Operation = "update_employee",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = editFields
                        },
                        SaveSp = "dbo.sp_SmartFormDemo",
                        SaveOp = "update_employee",
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },

                    // Edit1: alternate edit (e.g., update general number) — similar wiring
                    Edit1 = new TableAction
                    {
                        Label = "تعديل الرقم العام",
                        Icon = "fa fa-pen-to-square",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل الرقم العام",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditGNForm",
                            Title = "تعديل الرقم العام",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = edit1Fields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    }
                }
            };

            return View("Sami", dsModel);
        }
    }
}
