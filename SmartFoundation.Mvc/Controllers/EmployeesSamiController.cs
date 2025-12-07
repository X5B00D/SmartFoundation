using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;

namespace SmartFoundation.Mvc.Controllers
{
    
    public class EmployeesSamiController : Controller
    {
       
        private readonly MastersServies _mastersServies;

        public EmployeesSamiController(MastersServies mastersServies)
        {
           
            _mastersServies = mastersServies;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            bool canInsert = false, canUpdate = false, canUpdateGN = false;
            var cityOptions = new List<OptionItem>();
            DataSet? ds = null;

            // البارمترات
            var spParameters = new object?[] { "BuildingType", 1, 60014016, "hostname" };

            try
            {
                ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

                // صلاحيات من الجدول 0
                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    foreach (DataRow row in ds.Tables[0].Rows)
                    {
                        var p = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpperInvariant();
                        if (p == "INSERT") canInsert = true;
                        if (p == "UPDATE") canUpdate = true;
                        if (p == "UPDATEGN") canUpdateGN = true;
                    }
                }

                // المدن من الجدول 2
                if (ds != null && ds.Tables.Count > 2 && ds.Tables[2].Rows.Count > 0)
                {
                    foreach (DataRow row in ds.Tables[2].Rows)
                    {
                        var value = row["cityID"]?.ToString()?.Trim();
                        var text = row["cityName_A"]?.ToString()?.Trim();
                        if (!string.IsNullOrEmpty(value))
                            cityOptions.Add(new OptionItem { Value = value!, Text = string.IsNullOrEmpty(text) ? value! : text! });
                    }
                }

                ViewBag.EmployeeDataSet = ds;
                ViewBag.EmployeeTableCount = ds?.Tables?.Count ?? 0;
            }
            catch (Exception ex)
            {
                ViewBag.EmployeeDataSetError = ex.Message;
                ViewBag.EmployeeTableCount = 0;
            }

            var tableConfig = BuildTableConfig(canInsert, canUpdate, canUpdateGN, cityOptions);

            var vm = new SmartPageViewModel
            {
                PageTitle = "الموظفين",
                PanelTitle = "معلومات الموظفين",
                SpName = "dbo.sp_SmartFormDemo",
                Operation = "select_employees",
                Table = tableConfig
            };

            // استخدم نفس الفيو إن كانت مشتركة
            return View("Index", vm);
        }

        private static TableConfig BuildTableConfig(bool canInsert, bool canUpdate, bool canUpdateGN, List<OptionItem> cityOptions)
        {
            return new TableConfig
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
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowEdit1 = canUpdateGN,
                    ShowBulkDelete = false,

                    Add = BuildAddAction(canUpdate, cityOptions),
                    Edit = BuildEditAction(),
                    Edit1 = BuildEdit1Action()
                }
            };
        }

        private static TableAction BuildAddAction(bool canUpdate, List<OptionItem> cityOptions) =>
            new TableAction
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
                        new FieldConfig { Name = "FullName", Label = "الاسم الكامل", Type = "text",
                            Required = true, ColCss = "6", Placeholder = "الاسم الرباعي", MaxLength = 100,
                            Icon = "fa fa-user", Readonly = !canUpdate },
                        new FieldConfig { Name = "Email", Label = "البريد الإلكتروني", Type = "text",
                            TextMode = "email", Required = true, ColCss = "6", Placeholder = "example@email.com",
                            MaxLength = 150, Icon = "fa fa-envelope" },
                        new FieldConfig { Name = "NationalId", Label = "رقم الهوية", Type = "text",
                            Required = true, ColCss = "3", Placeholder = "1234567890", MaxLength = 10,
                            InputLang = "number", HelpText = "10 أرقام فقط", Icon = "fa fa-id-card" },
                        new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone",
                            Required = true, ColCss = "5", Placeholder = "05xxxxxxxx", MaxLength = 10,
                            InputLang = "numeric", Icon = "fa fa-phone" },
                        new FieldConfig { Name = "City", Label = "المدينة", Type = "select",
                            Options = cityOptions, ColCss = "6", Placeholder = "اختر المدينة", Icon = "fa fa-city" },
                        new FieldConfig { Name = "IBAN", Label = "الحساب البنكي (IBAN)", Type = "iban",
                            ColCss = "6", Placeholder = "SAxxxxxxxxxxxxxxxxxxxx", MaxLength = 24,
                            Icon = "fa fa-money-bill-transfer", HelpText = "يجب أن يبدأ بـ SA" },
                        new FieldConfig { Name = "BirthDate", Label = "تاريخ الميلاد", Type = "date",
                            ColCss = "6", HelpText = "اختر تاريخ ميلاد صحيح", Icon = "fa fa-calendar" },
                        new FieldConfig { Name = "Notes", Label = "ملاحظات", Type = "textarea",
                            ColCss = "4", MaxLength = 500, Placeholder = "اكتب ملاحظات إضافية هنا...",
                            Icon = "fa fa-note-sticky" },
                        new FieldConfig { Name = "AgreeTerms", Label = "أوافق على الشروط", Type = "checkbox",
                            Required = true, ColCss = "6", Icon = "fa fa-check-square" }
                    },
                    Buttons = new List<FormButtonConfig>
                    {
                        new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success", Icon = "fa fa-save" },
                        new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary",
                            Icon = "fa fa-times", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                    }
                },
                SaveSp = "dbo.sp_SmartFormDemo",
                SaveOp = "insert_employee"
            };

        private static TableAction BuildEditAction() =>
            new TableAction
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
                    Operation = "update_employee",
                    SubmitText = "حفظ التعديلات",
                    CancelText = "إلغاء",
                    Fields = new List<FieldConfig>
                    {
                        new FieldConfig { Name = "EmployeeId", Type = "hidden" },
                        new FieldConfig { Name = "FullName", Label = "الاسم الكامل", Type = "text", Required = true, ColCss="3" },
                        new FieldConfig { Name = "Email", Label = "البريد الإلكتروني", Type = "text", TextMode="email", Required = true, ColCss="3" },
                        new FieldConfig { Name = "NationalId", Label = "رقم الهوية", Type = "text", Required = true, ColCss="3" },
                        new FieldConfig { Name = "PhoneNumber", Label = "الجوال", Type = "phone", Required = true, ColCss="3" },
                        new FieldConfig {
                            Name = "City", Label = "المدينة", Type = "select",
                            Options = new List<OptionItem>{
                                new OptionItem{Value="RYD",Text="الرياض"},
                                new OptionItem{Value="JED",Text="جدة"},
                                new OptionItem{Value="DMM",Text="الدمام"}
                            }, ColCss="3"
                        },
                        new FieldConfig { Name = "IBAN", Label = "IBAN", Type = "iban", ColCss="6" },
                        new FieldConfig { Name = "BirthDate", Label = "تاريخ الميلاد", Type = "date", ColCss="6" },
                        new FieldConfig { Name = "Notes", Label = "ملاحظات", Type = "textarea", ColCss="6" },
                        new FieldConfig { Name = "AgreeTerms", Label = "أوافق على الشروط", Type = "checkbox", Required = true, ColCss="6" }
                    }
                },
                SaveSp = "dbo.sp_SmartFormDemo",
                SaveOp = "update_employee"
            };

        private static TableAction BuildEdit1Action() =>
            new TableAction
            {
                Label = "تعديل الرقم العام",
                Icon = "fa fa-pen-to-square",
                Color = "danger",
                IsEdit = true,
                OpenModal = true,
                ModalTitle = "تعديل الرقم العام",
                OpenForm = BuildEditAction().OpenForm,
                SaveSp = "dbo.sp_SmartFormDemo",
                SaveOp = "update_employee"
            };
    }
}
