using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using System.Data;
using System.Net;
using System.Threading;

namespace SmartFoundation.Mvc.Controllers
{
    public class LoginController : Controller
    {
        private readonly AuthDataLoadService _auth;

        public LoginController(AuthDataLoadService auth)
        {
            _auth = auth;
        }


        private static readonly Dictionary<string, string> _dnsCache = new(StringComparer.OrdinalIgnoreCase);

        private static string ResolveClientHostName(HttpContext ctx)
        {
            // Ensure forwarded headers middleware configured in Program.cs:
            // builder.Services.Configure<ForwardedHeadersOptions>(o => {
            //     o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedHost;
            // });
            // app.UseForwardedHeaders();  // BEFORE auth/other middlewares.

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

            // Local dev (loopback) cannot give client PC name; if you run browser on same machine you will always get loopback.
            if (IPAddress.IsLoopback(remoteIp))
                return remoteIp.ToString(); // keep IP to make it obvious it is loopback

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
                // ignore; keep IP
            }

            _dnsCache[ipString] = hostValue;
            return hostValue;
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
                TempData["Error"] = string.IsNullOrWhiteSpace(auth.Message_)
                    ? "لايوجد حساب نشط لهذا المستخدم"
                    : auth.Message_;
                TempData["LastUser"] = username;
                return RedirectToAction(nameof(Index));
            }


            string clientHostName = ResolveClientHostName(HttpContext);
            // Success / warning / info
            HttpContext.Session.SetString("userID", (auth.userId?.ToString() ?? username));
            HttpContext.Session.SetString("fullName", auth.fullName!);
            HttpContext.Session.SetString("IdaraID", auth.IdaraID!);
            HttpContext.Session.SetString("DepartmentName", auth.DepartmentName!);
            HttpContext.Session.SetString("ThameName", auth.ThameName!);
            HttpContext.Session.SetString("DeptCode", auth.DeptCode?.ToString() ?? "");
            HttpContext.Session.SetString("IDNumber", auth.IDNumber!);
            HttpContext.Session.SetString("HostName", clientHostName ?? "");
            HttpContext.Session.SetString("LastActivityUtc", DateTime.UtcNow.ToString("O"));



            switch (auth.useractive)
            {
                case 1: TempData["Success"] = auth.Message_ ?? "تم تسجيل الدخول بنجاح."; break;
                case 2: TempData["Warning"] = auth.Message_ ?? "تم تسجيل الدخول مع تحذير."; break;
                case 3: TempData["Info"]    = auth.Message_ ?? "معلومة: تم الدخول."; break;
                default: TempData["Success"] = auth.Message_ ?? "تم تسجيل الدخول."; break;
            }

            // Redirect to home (Toastr will show there if you include _Toastr partial in layout)
            return RedirectToAction("Index", "Home");
        }
    }
}
