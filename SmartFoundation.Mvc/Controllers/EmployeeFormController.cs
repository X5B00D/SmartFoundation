//using Microsoft.AspNetCore.Mvc;
//using SmartFoundation.UI.ViewModels.SmartForm;
//using SmartFoundation.UI.ViewModels.SmartPage;


//namespace SmartFoundation.Mvc.Controllers
//{
//    public class EmployeeFormController : Controller
//    {
//        public IActionResult Create()
//        {
//            var form = new FormConfig
//            {
//                FormId = "employeeForm",
//                Title = "إضافة موظف",
//                Method = "POST",
//                ActionUrl = "/smart/execute",
//                StoredProcedureName = "sp_SmartFormDemo",
//                Operation = "insert",

//                Fields = new List<FieldConfig>
//                {
//                    new FieldConfig { Name="FullName", Label="الاسم الكامل", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3" },
//                    new FieldConfig { Name="Email", Label="البريد الإلكتروني", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3", TextMode="email" },
//                    new FieldConfig { Name="PasswordHash", Label="كلمة المرور", Type="password", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3" },
//                    new FieldConfig { Name="NationalId", Label="الهوية", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3", InputLang="number", MaxLength=10 },
//                    new FieldConfig { Name="PhoneNumber", Label="الجوال", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3", InputLang="number" },
//                    new FieldConfig { Name="IBAN", Label="الحساب البنكي (IBAN)", Type="text", Autocomplete="on", ColCss="col-span-12 md:col-span-3" },


//                    new FieldConfig
//                    {
//                        Name="CountryCode",
//                        Label="الدولة",
//                        Type="select",
//                        ColCss="col-span-12 md:col-span-3",
//                        Options = new List<OptionItem>
//                        {
//                            new OptionItem { Value="SA", Text="السعودية", Selected=true },
//                            new OptionItem { Value="EG", Text="مصر" },
//                            new OptionItem { Value="JO", Text="الأردن" }
//                        }
//                    },

//                    new FieldConfig { Name="City", Label="المدينة", Type="text", Autocomplete="on", ColCss="col-span-12 md:col-span-3" },
//                    new FieldConfig { Name="Address", Label="العنوان", Type="text", Autocomplete="on", ColCss="col-span-12 md:col-span-3" },


//                    new FieldConfig {
//                        Name="AgreeTerms",
//                        Label="الموافقة على الشروط",
//                        Type="checkbox",
//                        Required=true,
//                        ColCss="col-span-12 md:col-span-12",
//                        Value="1"
//                    }
//                }
//            };

//            var vm = new SmartPageViewModel
//            {
//                PageTitle = "إضافة موظف جديد",
//                PanelTitle = "نموذج إضافة موظف",
//                SpName = "sp_SmartFormDemo",
//                Operation = "insert",
//                Form = form
//            };

//            return View(vm);
//        }
//    }
//}
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using System.Collections.Generic;

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeeFormController : Controller
    {
        public IActionResult Create()
        {
            var form = new FormConfig
            {
                FormId = "employeeForm",
                Title = "إضافة موظف",
                Method = "POST",
                ActionUrl = "/smart/execute",      // نقطة التنفيذ الموحدة
                StoredProcedureName = "AddEmployee", // اسم الإجراء المخزن
                Operation = "insert",

                Fields = new List<FieldConfig>
                {
                    new FieldConfig { Name="Name", Label="الاسم", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3" },
                    new FieldConfig { Name="Department", Label="القسم", Type="text", Required=true, Autocomplete="on", ColCss="col-span-12 md:col-span-3" },
                    new FieldConfig { Name="Salary", Label="الراتب", Type="number", Required=true, InputLang="number", ColCss="col-span-12 md:col-span-3" },
                    new FieldConfig { Name="HireDate", Label="تاريخ التوظيف", Type="date", ColCss="col-span-12 md:col-span-3" }
                }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "إضافة موظف جديد",
                PanelTitle = "نموذج إدخال موظف",
                SpName = "AddEmployee",
                Operation = "insert",
                Form = form
            };

            return View(vm);
        }
    }
}
