using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;

namespace SmartFoundation.UI.ViewComponents.SmartForm
{
    public class SmartFormViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(FormConfig model) => View("Default", model);
    }
}
