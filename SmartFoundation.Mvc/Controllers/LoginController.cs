using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using System.Threading;
using System.Data;

namespace SmartFoundation.Mvc.Controllers
{
    public class LoginController : Controller
    {
        private readonly AuthDataLoadService _auth;

        public LoginController(AuthDataLoadService auth)
        {
            _auth = auth;
        }

        public IActionResult Index() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CheckLogin(string username, string password, CancellationToken ct)
        {
            // Basic required field
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                TempData["Error"] = "الرجاء اكمال الحقول المطلوبة";
                TempData["LastUser"] = username;
                // Redirect so URL returns to /Login/Index (not stuck on /CheckLogin)
                return RedirectToAction(nameof(Index));
            }

            DataSet ds;
            try
            {
                ds = await _auth.GetLoginDataSetAsync(username.Trim(), password, Request.Host.Value, ct);
            }
            catch
            {
                TempData["Error"] = "خطأ في الاتصال بالخادم.";
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }

            var auth = _auth.ExtractAuth(ds);

            if (auth.useractive == 0)
            {
                TempData["Error"] = string.IsNullOrWhiteSpace(auth.Message)
                    ? "لايوجد حساب نشط لهذا المستخدم"
                    : auth.Message;
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }

            // Success / warning / info
            HttpContext.Session.SetString("userID", (auth.userId?.ToString() ?? username));
            if (!string.IsNullOrWhiteSpace(auth.fullName))
                HttpContext.Session.SetString("fullName", auth.fullName!);

            switch (auth.useractive)
            {
                case 1: TempData["Success"] = auth.Message ?? "تم تسجيل الدخول بنجاح."; break;
                case 2: TempData["Warning"] = auth.Message ?? "تم تسجيل الدخول مع تحذير."; break;
                case 3: TempData["Info"]    = auth.Message ?? "معلومة: تم الدخول."; break;
                default: TempData["Success"] = auth.Message ?? "تم تسجيل الدخول."; break;
            }

            // Redirect to home (Toastr will show there if you include _Toastr partial in layout)
            return RedirectToAction("Index", "Home");
        }
    }
}
