using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using System.Data;
using System.Net;
using System.Threading;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;

namespace SmartFoundation.Mvc.Controllers.Login
{
    public class LoginController : Controller
    {
        private readonly MastersServies _mastersServies;


        public LoginController(MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        private static readonly Dictionary<string, string> _dnsCache = new(StringComparer.OrdinalIgnoreCase);

        private static string ResolveClientHostName(HttpContext ctx)
        {
            string? forwardedFor = ctx.Request.Headers["X-Forwarded-For"].FirstOrDefault();
            IPAddress? remoteIp = null;
            if (!string.IsNullOrWhiteSpace(forwardedFor))
            {
                var firstIp = forwardedFor.Split(',').First().Trim();
                if (IPAddress.TryParse(firstIp, out var parsed))
                    remoteIp = parsed;
            }

            remoteIp ??= ctx.Connection.RemoteIpAddress;
            if (remoteIp == null)
                return "unknown";

            if (remoteIp.IsIPv4MappedToIPv6) remoteIp = remoteIp.MapToIPv4();

            if (IPAddress.IsLoopback(remoteIp))
                return remoteIp.ToString();

            var ipString = remoteIp.ToString();
            if (_dnsCache.TryGetValue(ipString, out var cached))
                return cached;

            var hostValue = ipString;
            try
            {
                var entry = Dns.GetHostEntry(remoteIp);
                if (!string.IsNullOrWhiteSpace(entry.HostName))
                    hostValue = entry.HostName.TrimEnd('.');
            }
            catch
            {
            }

            _dnsCache[ipString] = hostValue;
            return hostValue;
        }

        [HttpGet]
        [AllowAnonymous]
        [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
        public async Task<IActionResult> Index()
        {
            // Sign out (if using cookie auth) and clear all session
            HttpContext.Session.Clear();

            // If forced here by SessionGuard, show a message
            //if (Request.Query.ContainsKey("logout"))
            //{
            //    TempData["Error"] = "تم تسجيل خروجك من النظام لعدم وجود نشاط";
            //}

            if (Request.Query.ContainsKey("logout"))
            {
                var logoutValue = Request.Query["logout"].ToString();

                if (logoutValue == "1")
                {
                    TempData["Error"] = "تم تسجيل خروجك من النظام لعدم وجود نشاط";
                }
                else if (logoutValue == "2")
                {
                    TempData["Success"] = "تم تسجيل خروجك بنجاح";
                }
                else
                {
                    TempData["Error"] = "تم تسجيل الخروج";
                }
            }

            // Extra anti-cache headers (defense-in-depth)
            Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
            Response.Headers["Pragma"] = "no-cache";
            Response.Headers["Expires"] = "0";

            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CheckLogin(string username, string password, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                TempData["Error"] = "الرجاء اكمال الحقول المطلوبة";
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }

            DataSet ds;

            var spParameters = new object?[] { username.Trim(), password, Request.Host.Value };
            try
            {
                //ds = await _auth.GetLoginDataSetAsync(username.Trim(), password, Request.Host.Value);
                ds = await _mastersServies.GetLoginDataSetAsync(spParameters);
            }
            catch
            {
                TempData["Error"] = "خطأ في الاتصال بالخادم.";
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }

            var auth = _mastersServies.ExtractAuth(ds);

            if (auth.useractive == 0)
            {
                TempData["Error"] = string.IsNullOrWhiteSpace(auth.Message_)
                    ? "لايوجد حساب نشط لهذا المستخدم"
                    : auth.Message_;
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }

            string clientHostName = ResolveClientHostName(HttpContext);
            HttpContext.Session.SetString("userID", (auth.userId?.ToString() ?? username));
            HttpContext.Session.SetString("fullName", auth.fullName!);
            HttpContext.Session.SetString("IdaraID", auth.IdaraID!);
            HttpContext.Session.SetString("DepartmentName", auth.DepartmentName!);
            HttpContext.Session.SetString("ThameName", auth.ThameName!);
            HttpContext.Session.SetString("DeptCode", auth.DeptCode?.ToString() ?? "");
            HttpContext.Session.SetString("IDNumber", auth.IDNumber!);
            HttpContext.Session.SetString("HostName", clientHostName ?? "");
            HttpContext.Session.SetString("LastActivityUtc", DateTime.UtcNow.ToString("O"));
            HttpContext.Session.SetString("photoBase64", auth.PhotoBase64 ?? "");

            switch (auth.useractive)
            {
                case 1: TempData["Success"] = auth.Message_ ?? "تم تسجيل الدخول بنجاح."; break;
                case 2: TempData["Warning"] = auth.Message_ ?? "تم تسجيل الدخول مع تحذير."; break;
                case 3: TempData["Info"] = auth.Message_ ?? "معلومة: تم الدخول."; break;
                default: TempData["Success"] = auth.Message_ ?? "تم تسجيل الدخول."; break;
            }

            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Logout()
        {
            // حذف جميع السيشنات
            HttpContext.Session.Clear();

            // حذف الكوكيز إذا كنت تستخدم Cookie Authentication (اختياري)
            // await HttpContext.SignOutAsync();

            return RedirectToAction("Index", "Login", new { logout = 2 });
        }

    }
}
