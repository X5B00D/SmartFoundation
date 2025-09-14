using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        public IActionResult Index()
        {
            // تعريف الجدول الرئيسي (DataTable) 
            var tableField = new FieldConfig
            {
                Name = "EmployeesTable",
                Type = "datatable",
                ColCss = "col-span-12 md:col-span-12", // الجدول ياخذ العرض كامل
                Table = new TableConfig
                {
                    // API
                    Endpoint = "/smart/execute",
                    StoredProcedureName = "dbo.sp_SmartFormDemo",
                    Operation = "select_employees",

                    // الصفحة
                    PageSize = 10,
                    PageSizes = new List<int> { 2, 10, 25, 50, 100 },
                    MaxPageSize = 1000,

                    // البحث
                    Searchable = true,
                    SearchPlaceholder = "ابحث بالاسم/الجوال/البريد/المدينة...",
                    QuickSearchFields = new List<string> { "FullName", "Email", "City", "PhoneNumber" },
                    DebounceSearch = true,
                    SearchDebounceDelay = 500,

                    // تصدير
                    AllowExport = true,

                    // واجهة
                    ShowHeader = true,
                    ShowFooter = true,
                    AutoRefreshOnSubmit = true,
                    ClientSideMode = false,
                    ResponsiveMode = true,
                    ShowRowNumbers = true,
                    HoverHighlight = true,
                    StripedRows = true,
                    Density = "normal",

                    // ميزات متقدمة
                    Selectable = true,
                    RowIdField = "EmployeeId",
                    StorageKey = "EmployeesTablePrefs",
                    InlineEditing = false,
                    EnableKeyboardNavigation = true,
                    EnableContextMenu = true,

                    // الأداء
                    LazyLoading = false,
                    CacheTimeout = 300,
                    VirtualScrolling = false,

                    // الوصول
                    EnableScreenReader = true,
                    AriaLabel = "جدول الموظفين",
                    HighContrast = false,

                    // الأعمدة
                    Columns = new List<TableColumn>
                    {
                        new TableColumn { Field="EmployeeId", Label="ID", Type="number", Width="80px", Align="center", Sortable=true, Frozen=true, FrozenSide="left" },
                        new TableColumn { Field="FullName", Label="الاسم الكامل", Type="text", MinWidth="150px", Sortable=true, Resizable=true },
                        new TableColumn { Field="Email", Label="البريد الإلكتروني", Type="link", LinkTemplate="mailto:{Email}", MinWidth="200px", Sortable=true },
                        new TableColumn { Field="PhoneNumber", Label="الجوال", Type="text", Width="120px", Sortable=true },
                        new TableColumn { Field="City", Label="المدينة", Sortable=true },
                        new TableColumn { Field="IBAN", Label="IBAN", Type="text", MinWidth="180px", Sortable=true, FormatterJs="row => row.IBAN ? row.IBAN.replace(/(.{4})/g, '$1 ').trim() : ''" },
                        new TableColumn { Field="BirthDate", Label="تاريخ الميلاد", Type="date", FormatString="{0:yyyy-MM-dd}", Width="120px", Sortable=true },
                        new TableColumn { Field="AgreeTerms", Label="موافق؟", Type="bool", Align="center", Width="80px" },
                        new TableColumn { Field="CreatedAt", Label="تاريخ الإنشاء", Type="datetime", FormatString="{0:yyyy-MM-dd HH:mm}", Width="150px", Visible=false },
                        new TableColumn { Field="UpdatedAt", Label="آخر تحديث", Type="datetime", FormatString="{0:yyyy-MM-dd HH:mm}", Width="150px", Visible=false }
                    },

                    // شريط الأدوات
                    Toolbar = new TableToolbarConfig
                    {
                        ShowRefresh = true,
                        ShowColumns = true,
                        ShowExportCsv = true,
                        ShowExportExcel = true,
                        ShowExportPdf = true,
                        ShowPrint = true,
                        ShowAdvancedFilter = true,
                        ShowAdd = true,
                        ShowEdit = true,
                        ShowBulkDelete = true,
                        ShowFullscreen = true,
                        ShowDensityToggle = true,
                        ShowThemeToggle = true,
                        ShowSearch = true,
                        SearchPosition = "left",

                        // زر إضافة
                        Add = new TableAction
                        {
                            Label = "إضافة موظف",
                            Icon = "fa fa-plus",
                            Color = "success",
                            OpenModal = true,
                            ModalTitle = "إضافة موظف",
                            OpenForm = new FormConfig
                            {
                                FormId = "employeeCreateForm",
                                Title = "إضافة موظف",
                                Method = "POST",
                                ActionUrl = "/smart/execute",
                                StoredProcedureName = "dbo.sp_SmartFormDemo",
                                Operation = "insert",
                                SubmitText = "حفظ",
                                Fields = new List<FieldConfig>
                                {
                                    new FieldConfig { Name="FullName", Label="الاسم", Type="text", Required=true, MaxLength=100, ColCss="6" },
                                    new FieldConfig { Name="Email", Label="البريد", Type="text", TextMode="email", Required=true, ColCss="6" },
                                    new FieldConfig { Name="NationalId", Label="الهوية", Type="text", Required=true, MaxLength=10, IsNumericOnly=true, ColCss="6" },
                                    new FieldConfig { Name="PhoneNumber", Label="الجوال", Type="phone", Required=true, MaxLength=10, ColCss="6" },
                                    new FieldConfig { Name="City", Label="المدينة", Type="text", ColCss="6" },
                                    new FieldConfig { Name="IBAN", Label="IBAN", Type="iban", IsIban=true, MaxLength=34, ColCss="6" },
                                    new FieldConfig { Name="BirthDate", Label="تاريخ الميلاد", Type="date", Calendar="both", ColCss="6" },
                                    new FieldConfig { Name="AgreeTerms", Label="موافق على الشروط", Type="checkbox", ColCss="12" }
                                }
                            }
                        },

                        // زر تعديل
                        Edit = new TableAction
                        {
                            Label = "تعديل موظف",
                            Icon = "fa fa-pen-to-square",
                            Color = "info",
                            IsEdit = true,
                            OpenModal = true,
                            SaveSp = "dbo.sp_SmartFormDemo",
                            SaveOp = "update",
                            ModalTitle = "تعديل موظف",
                            FormUrl = Url.Action("EmployeeForm", "Employees")
                        }
                    }
                }
            };

            // ضع الجدول داخل فورم
            var form = new FormConfig
            {
                Title = "قائمة الموظفين",
                SubmitText = null,
                ShowReset = false,
                Fields = new List<FieldConfig> { tableField }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "الموظفين",
                PanelTitle = "إدارة الموظفين",
                SpName = "dbo.sp_SmartFormDemo",
                Operation = "select_employees",
                Form = form
            };

            return View(vm);
        }

        // فورم تعديل/إضافة
        public IActionResult EmployeeForm(int? id)
        {
            var form = new FormConfig
            {
                FormId = "employeeForm",
                Title = id == null ? "إضافة موظف" : "تعديل موظف",
                Method = "POST",
                ActionUrl = "/smart/execute",
                StoredProcedureName = "dbo.sp_SmartFormDemo",
                Operation = id == null ? "insert" : "update",
                SubmitText = "حفظ",
                Fields = new List<FieldConfig>
                {
                    new FieldConfig { Name="EmployeeId", Type="hidden", IsHidden=true, Value = id?.ToString() },
                    new FieldConfig { Name="FullName", Label="الاسم", Type="text", Required=true, MaxLength=100, ColCss="6" },
                    new FieldConfig { Name="Email", Label="البريد", Type="text", TextMode="email", Required=true, ColCss="6" },
                    new FieldConfig { Name="NationalId", Label="رقم الهوية", Type="text", Required=true, MaxLength=10, ColCss="6" },
                    new FieldConfig { Name="PhoneNumber", Label="الجوال", Type="phone", Required=true, MaxLength=10, ColCss="6" },
                    new FieldConfig { Name="City", Label="المدينة", Type="text", ColCss="6" },
                    new FieldConfig { Name="IBAN", Label="IBAN", Type="iban", IsIban=true, MaxLength=34, ColCss="6" },
                    new FieldConfig { Name="BirthDate", Label="تاريخ الميلاد", Type="date", Calendar="both", ColCss="6" },
                    new FieldConfig { Name="AgreeTerms", Label="موافق على الشروط", Type="checkbox", ColCss="12" }
                }
            };

            return ViewComponent("SmartForm", form);
        }
    }
}
