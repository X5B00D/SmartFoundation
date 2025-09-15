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
                ColCss = "col-span-12 md:col-span-12",
                Table = new TableConfig
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
                        ShowBulkDelete = true,

                        // زر إضافة → يفتح EmployeeForm (مودال)
                        Add = new TableAction
                        {
                            Label = "إضافة موظف",
                            Icon = "fa fa-plus",
                            Color = "success",
                            OpenModal = true,
                            ModalTitle = "إضافة موظف",
                            FormUrl = Url.Action("EmployeeForm", "Employees") // ⬅️ يستدعي الأكشن EmployeeForm
                        },

                        // زر تعديل → يفتح نفس الفورم لكن مع Id
                        Edit = new TableAction
                        {
                            Label = "تعديل موظف",
                            Icon = "fa fa-pen-to-square",
                            Color = "info",
                            IsEdit = true,
                            OpenModal = true,
                            ModalTitle = "تعديل موظف",
                            FormUrl = Url.Action("EmployeeForm", "Employees") + "?id={EmployeeId}"
                        }
                    }
                }
            };

            var form = new FormConfig
            {
                Title = "قائمة الموظفين",
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

        // 🔹 المودال (إضافة / تعديل) - هنا تكتب الحقول بنفسك
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
                ResetText = "تفريغ",
                ShowReset = true,
                Fields = new List<FieldConfig>
                {
                    new FieldConfig { Name="EmployeeId", Type="hidden", IsHidden=true, Value = id?.ToString() },
                    new FieldConfig { Name="FullName", Label="الاسم", Type="text", Required=true, MaxLength=100, ColCss="6" },
                    new FieldConfig { Name="Email", Label="البريد", Type="text", TextMode="email", Required=true, ColCss="6" },
                    new FieldConfig { Name="NationalId", Label="رقم الهوية", Type="text", Required=true, MaxLength=10, IsNumericOnly=true, ColCss="6" },
                    new FieldConfig { Name="PhoneNumber", Label="الجوال", Type="phone", Required=true, MaxLength=10, ColCss="6" },
                    new FieldConfig { Name="City", Label="المدينة", Type="text", ColCss="6" },
                    new FieldConfig { Name="IBAN", Label="IBAN", Type="iban", MaxLength=34, ColCss="6" },
                    new FieldConfig { Name="BirthDate", Label="تاريخ الميلاد", Type="date", Calendar="both", ColCss="6" },
                    new FieldConfig { Name="AgreeTerms", Label="موافق على الشروط", Type="checkbox", ColCss="12" }
                }
            };

            return ViewComponent("SmartForm", form);
        }
    }
}
