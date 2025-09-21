using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        public IActionResult Index()
        {
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
                    ShowRefresh = true,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = true,
                    ShowAdd = true,
                    ShowEdit = true,
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
                                    ColCss = "3",
                                    Placeholder = "الاسم الرباعي",
                                    MaxLength = 100,
                                    Icon = "fa fa-user"
                                },
                                new FieldConfig {
                                    Name = "Email",
                                    Label = "البريد الإلكتروني",
                                    Type = "text",
                                    TextMode = "email",
                                    Required = true,
                                    ColCss = "3",
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
                                    ColCss = "3",
                                    Placeholder = "05xxxxxxxx",
                                    MaxLength = 10,
                                    InputLang = "number",
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
                                    ColCss = "3",
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
                                    ColCss = "6",
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
                    }

                }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "الموظفين",
                PanelTitle = "إدارة الموظفين",
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
    }
}
