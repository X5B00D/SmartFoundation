using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartPrint;

public class SmartPrintViewComponent : ViewComponent
{
    public IViewComponentResult Invoke(SmartPrintDocument model)
        => View("Default", model);
}
