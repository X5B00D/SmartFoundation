using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartCharts;

namespace SmartFoundation.UI.ViewComponents.SmartCharts
{
    public class SmartChartsViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(SmartChartsConfig model) => View("Default", model);
    }
}
