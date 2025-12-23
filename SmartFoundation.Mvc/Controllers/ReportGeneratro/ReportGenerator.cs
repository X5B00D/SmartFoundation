using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;

namespace SmartFoundation.Mvc.Controllers.ReportGeneratro
{
    public class ReportGenerator : Controller
    {
        public IActionResult Index()
        { 

            return View();
        }
    }
}