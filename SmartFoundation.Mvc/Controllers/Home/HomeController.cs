using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Mvc.Models;
using System.Diagnostics;

namespace SmartFoundation.Mvc.Controllers.Home
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
        public IActionResult Index()
        {

            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("usersID")))
            {
                return  RedirectToAction("Index", "Login", new { logout = 1 });
            }
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
