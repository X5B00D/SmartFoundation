using Microsoft.AspNetCore.Mvc;
using System.Data;   // غيرها حسب اسم dbContext
using System.Linq;

namespace SmartFoundation.Mvc.Controllers
{
    [Route("session")]
    public class SessionController : Controller
    {
        [HttpPost("keepalive")]
        public IActionResult KeepAlive()
        {
            HttpContext.Session.SetString("LastActivityUtc", DateTime.UtcNow.ToString("O"));
            return Ok(new { success = true });
        }

        [HttpPost("logout")]
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return Ok(new { success = true });
        }


        [HttpGet]
        public IActionResult UserPhoto()
        {
            var base64 = HttpContext.Session.GetString("photoBase64");

            if (string.IsNullOrWhiteSpace(base64))
            {
                // رجّع صورة افتراضية (أيقونة المستخدم)
                var path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/img/user_.png");
                var bytes = System.IO.File.ReadAllBytes(path);
                return File(bytes, "image/png");
            }

            try
            {
                byte[] imageBytes = Convert.FromBase64String(base64);
                return File(imageBytes, "image/jpeg");
            }
            catch
            {
                // لو حصل خطأ في التحويل رجّع صورة افتراضية
                var path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/img/user_.png");
                var bytes = System.IO.File.ReadAllBytes(path);
                return File(bytes, "image/png");
            }
        }

    }
}