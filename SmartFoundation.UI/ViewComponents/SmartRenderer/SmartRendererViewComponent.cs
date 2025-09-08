using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartPage;

namespace SmartFoundation.UI.ViewComponents.SmartRenderer;

public class SmartRendererViewComponent : ViewComponent
{
    public IViewComponentResult Invoke(SmartPageViewModel model) => View(model);
}
