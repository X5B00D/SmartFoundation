using Microsoft.AspNetCore.Mvc;

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
    }
}