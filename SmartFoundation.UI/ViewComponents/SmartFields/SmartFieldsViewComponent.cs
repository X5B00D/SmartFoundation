using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;

namespace SmartFoundation.UI.ViewComponents
{
    public class SmartFieldsViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(List<FieldConfig> model)
        {
            // لو ما فيه بيانات، أنشئ لستة فاضية
            model ??= new List<FieldConfig>();

            return View("Default", model);
        }
    }
}
