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
                Table = new TableConfig
                {
                    // API Configuration
                    Endpoint = "/smart/execute",
                    StoredProcedureName = "dbo.sp_SmartFormDemo",
                    Operation = "select_employees",
                    
                    // Pagination
                    PageSize = 10,
                    PageSizes = new List<int> { 2, 10, 25, 50, 100 },
                    MaxPageSize = 1000,
                    
                    // Search & Filtering
                    Searchable = true,
                    SearchPlaceholder = "ابحث بالاسم/الجوال/البريد/المدينة...",
                    QuickSearchFields = new List<string> { "FullName", "Email", "City", "PhoneNumber" },
                    DebounceSearch = true,
                    SearchDebounceDelay = 500,
                    
                    // Export & Print
                    AllowExport = false,
                    
                    // UI Settings
                    ShowHeader = true,
                    ShowFooter = true,
                    AutoRefreshOnSubmit = true,
                    ClientSideMode = false, // Set to true for client-side processing
                    ResponsiveMode = true,
                    ShowRowNumbers = true,
                    HoverHighlight = true,
                    StripedRows = false,
                    Density = "normal", // compact | normal | comfortable
                    
                    // Advanced Features
                    Selectable = true,
                    RowIdField = "EmployeeId",
                    StorageKey = "EmployeesTablePrefs",
                    InlineEditing = false,
                    EnableKeyboardNavigation = true,
                    EnableContextMenu = true,
                    
                    // Performance
                    LazyLoading = false,
                    CacheTimeout = 300,
                    VirtualScrolling = false,
                    
                    // Accessibility
                    EnableScreenReader = true,
                    AriaLabel = "جدول الموظفين",
                    HighContrast = false,

                    // الأعمدة مع التحسينات
                    Columns = new List<TableColumn>
                    {
                        new TableColumn 
                        { 
                            Field = "EmployeeId", 
                            Label = "ID", 
                            Width = "80px", 
                            MinWidth = "60px",
                            Align = "center", 
                            Sortable = true, 
                            Visible = true,
                            Type = "number",
                            Frozen = true,
                            FrozenSide = "left",
                            ShowInExport = true,
                            Filter = new TableColumnFilter
                            {
                                Type = "number",
                                Enabled = true,
                                Placeholder = "رقم الموظف"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "FullName", 
                            Label = "الاسم الكامل", 
                            Sortable = true, 
                            Resizable = true,
                            Type = "text",
                            MinWidth = "150px",
                            Filter = new TableColumnFilter
                            {
                                Type = "text",
                                Enabled = true,
                                Placeholder = "اسم الموظف"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "Email", 
                            Label = "البريد الإلكتروني", 
                            Sortable = true,
                            Type = "link",
                            LinkTemplate = "mailto:{Email}",
                            MinWidth = "200px",
                            Filter = new TableColumnFilter
                            {
                                Type = "text",
                                Enabled = true,
                                Placeholder = "البريد الإلكتروني"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "PhoneNumber", 
                            Label = "الجوال", 
                            Width = "120px", 
                            Sortable = true,
                            Type = "text",
                            Filter = new TableColumnFilter
                            {
                                Type = "text",
                                Enabled = true,
                                Placeholder = "رقم الجوال"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "City", 
                            Label = "المدينة", 
                            Sortable = true,
                            Filter = new TableColumnFilter
                            {
                                Type = "select",
                                Enabled = true,
                                Options = new List<OptionItem>
                                {
                                    new OptionItem { Value = "", Text = "جميع المدن" },
                                    new OptionItem { Value = "الرياض", Text = "الرياض" },
                                    new OptionItem { Value = "جدة", Text = "جدة" },
                                    new OptionItem { Value = "الدمام", Text = "الدمام" },
                                    new OptionItem { Value = "مكة المكرمة", Text = "مكة المكرمة" },
                                    new OptionItem { Value = "المدينة المنورة", Text = "المدينة المنورة" },
                                    new OptionItem { Value = "أبها", Text = "أبها" },
                                    new OptionItem { Value = "خميس مشيط", Text = "خميس مشيط" }
                                }
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "IBAN", 
                            Label = "IBAN", 
                            Sortable = true,
                            Type = "text",
                            MinWidth = "180px",
                            FormatterJs = "row => row.IBAN ? row.IBAN.replace(/(.{4})/g, '$1 ').trim() : ''",
                            Filter = new TableColumnFilter
                            {
                                Type = "text",
                                Enabled = true,
                                Placeholder = "IBAN"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "BirthDate", 
                            Label = "تاريخ الميلاد", 
                            Type = "date", 
                            FormatString = "{0:yyyy-MM-dd}", 
                            Sortable = true,
                            Width = "120px",
                            Filter = new TableColumnFilter
                            {
                                Type = "date",
                                Enabled = true,
                                Placeholder = "تاريخ الميلاد"
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "AgreeTerms", 
                            Label = "موافق؟", 
                            Type = "bool", 
                            Align = "center",
                            Width = "80px",
                            Filter = new TableColumnFilter
                            {
                                Type = "select",
                                Enabled = true,
                                Options = new List<OptionItem>
                                {
                                    new OptionItem { Value = "", Text = "الكل" },
                                    new OptionItem { Value = "true", Text = "موافق" },
                                    new OptionItem { Value = "false", Text = "غير موافق" }
                                }
                            }
                        },
                        new TableColumn 
                        { 
                            Field = "CreatedAt", 
                            Label = "تاريخ الإنشاء", 
                            Type = "datetime", 
                            FormatString = "{0:yyyy-MM-dd HH:mm}", 
                            Sortable = true,
                            Width = "150px",
                            Visible = false
                        },
                        new TableColumn 
                        { 
                            Field = "UpdatedAt", 
                            Label = "آخر تحديث", 
                            Type = "datetime", 
                            FormatString = "{0:yyyy-MM-dd HH:mm}", 
                            Sortable = true,
                            Width = "150px",
                            Visible = false
                        }
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

            // نضع الجدول داخل FormConfig
            var form = new FormConfig
            {
                Title = "قائمة الموظفين",
                SubmitText = null,
                ShowReset = false,
                Fields = new List<FieldConfig> { tableField }
            };

            // ViewModel للصفحة
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
