using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartTable;

namespace SmartFoundation.UI.ViewComponents.SmartTableDS
{
    public class SmartTableDSViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(SmartTableDsModel model) => View("Default", model);
    }
}