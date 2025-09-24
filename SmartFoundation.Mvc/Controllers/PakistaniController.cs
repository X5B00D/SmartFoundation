using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;

namespace SmartFoundation.Mvc.Controllers
{
    public class PakistaniController : Controller
    {
        public IActionResult Index()

        {
            var form = new FormConfig
            {
                FormId = "dynamicForm",
                Title = "نموذج الإدخال",
                Method = "POST",
                ActionUrl = "/AllComponentsDemo/ExecuteDemo",
                SubmitText = "حفظ1",
                //ResetText = "تفريغ",
                //ShowPanel = true,
                ////ShowReset = true,
                //StoredProcedureName = "sp_SaveDemoForm",
                //Operation = "insert",
                //StoredSuccessMessageField = "Message",
                //StoredErrorMessageField = "Error",

                Fields = new List<FieldConfig>
                {
                    // ========= البيانات الشخصية =========
                    new FieldConfig
                    {

                        SectionTitle = "البيانات",
                        Name = "FullName",
                        Label = "إدخال نص",
                        Type = "text",
                        Required = true,
                        Placeholder = "حقل عربي فقط",
                        Icon = "fa-solid fa-user",
                        ColCss = "col-span-12 md:col-span-3",
                        MaxLength = 50,
                        TextMode = "arsentence",
                    },

                }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "جميع المكونات",
                PanelTitle = "عرض ",
                SpName = "sp_SaveDemoForm",
                Operation = "insert",
                Form = form
            };

            return View(vm);
        }
    }
}