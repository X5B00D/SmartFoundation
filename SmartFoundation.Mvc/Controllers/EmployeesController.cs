using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        public IActionResult Index()
        {
            // تعريف الجدول الرئيسي
            var tableField = new FieldConfig
            {
                Name = "EmployeesTable",
                Type = "datatable",
                Table = new TableConfig
                {
                    Endpoint = "/smart/execute",
                    StoredProcedureName = "dbo.sp_SmartFormDemo",
                    Operation = "select_employees",
                    PageSize = 10,
                    PageSizes = new List<int> { 5, 10, 25, 50, 100 },
                    Searchable = true,
                    SearchPlaceholder = "ابحث بالاسم/الجوال/المدينة...",
                    QuickSearchFields = new List<string> { "FullName", "Email", "City", "PhoneNumber" },
                    AllowExport = true,
                    AutoRefreshOnSubmit = true,
                    ShowHeader = true,
                    ShowFooter = true,
                    Selectable = true,
                    RowIdField = "EmployeeId",
                    StorageKey = "EmployeesTablePrefs",

                    // الأعمدة
                    Columns = new List<TableColumn>
                    {
                        new TableColumn { Field="EmployeeId", Label="ID", Width="70px", Align="center", Sortable=true, Visible=true },
                        new TableColumn { Field="FullName", Label="الاسم الكامل", Sortable=true },
                        new TableColumn { Field="Email", Label="البريد الإلكتروني", Sortable=true },
                        new TableColumn { Field="PhoneNumber", Label="الجوال", Width="120px", Sortable=true },
                        new TableColumn { Field="City", Label="المدينة", Sortable=true },
                        new TableColumn { Field="IBAN", Label="IBAN", Sortable=true },
                        new TableColumn { Field="BirthDate", Label="تاريخ الميلاد", Type="date", FormatString="{0:yyyy-MM-dd}", Sortable=true },
                        new TableColumn { Field="AgreeTerms", Label="موافق؟", Type="bool", Align="center" },
                        new TableColumn { Field="CreatedAt", Label="تاريخ الإنشاء", Type="datetime", FormatString="{0:yyyy-MM-dd HH:mm}", Sortable=true },
                        new TableColumn { Field="UpdatedAt", Label="آخر تحديث", Type="datetime", FormatString="{0:yyyy-MM-dd HH:mm}", Sortable=true }
                    },

                    // الإجراءات على كل صف
                    RowActions = new List<TableAction>
                    {
                        new TableAction
                        {
                            Label="عرض",
                            Icon="fa fa-eye",
                            Color="secondary",
                            OpenModal=true,
                            ModalTitle="بيانات الموظف",
                            ModalSp="dbo.sp_SmartFormDemo",
                            ModalOp="detail",
                            ModalColumns=new List<TableColumn>
                            {
                                new TableColumn { Field="FullName", Label="الاسم" },
                                new TableColumn { Field="Email", Label="البريد" },
                                new TableColumn { Field="PhoneNumber", Label="الجوال" },
                                new TableColumn { Field="City", Label="المدينة" },
                                new TableColumn { Field="BirthDate", Label="الميلاد", Type="date" }
                            }
                        },
                        new TableAction
                        {
                            Label="حذف",
                            Icon="fa fa-trash",
                            Color="danger",
                            ConfirmText="هل أنت متأكد من الحذف؟",
                            Show=true,
                            SaveSp="dbo.sp_SmartFormDemo",
                            SaveOp="delete"
                        }
                    },

                    // شريط الأدوات
                    Toolbar = new TableToolbarConfig
                    {
                        ShowRefresh = true,
                        ShowColumns = true,
                        ShowExportCsv = true,
                        ShowExportExcel = true,
                        ShowAdvancedFilter = true,
                        ShowAdd = true,
                        ShowEdit = true,
                        ShowBulkDelete = true,

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
                                    new FieldConfig { Name="FullName",    Label="الاسم",         Type="text",  Required=true, MaxLength=100, ColCss="6" },
                                    new FieldConfig { Name="Email",       Label="البريد",        Type="text",  TextMode="email", Required=true, ColCss="6" },
                                    new FieldConfig { Name="NationalId",  Label="الهوية",        Type="text",  Required=true, MaxLength=10, IsNumericOnly=true, ColCss="6" },
                                    new FieldConfig { Name="PhoneNumber", Label="الجوال",        Type="phone", Required=true, MaxLength=10, ColCss="6" },
                                    new FieldConfig { Name="City",        Label="المدينة",       Type="text",  ColCss="6" },
                                    new FieldConfig { Name="IBAN",        Label="IBAN",          Type="iban",  IsIban=true, MaxLength=34, ColCss="6" },
                                    new FieldConfig { Name="BirthDate",   Label="تاريخ الميلاد", Type="date",  Calendar="both", ColCss="6" },
                                    new FieldConfig { Name="AgreeTerms",  Label="موافق على الشروط", Type="checkbox", ColCss="12" }
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

        // يعرض فورم التعديل (أو الإضافة عند id == null)
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
