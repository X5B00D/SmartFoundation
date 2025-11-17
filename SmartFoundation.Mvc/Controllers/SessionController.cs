using Microsoft.AspNetCore.Mvc;

namespace SmartFoundation.Mvc.Controllers
{
    [ApiController]
    [Route("session")]
    public class SessionController : ControllerBase
    {
        /// <summary>
        /// Lightweight keep-alive: touches session so its IdleTimeout resets.
        /// Only works if the session already contains userID.
        /// </summary>
        [HttpPost("keepalive")]
        public IActionResult KeepAlive()
        {
            var userId = HttpContext.Session.GetString("userID");
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Session expired" });

            // Touch a marker to ensure the session is 'accessed'
            HttpContext.Session.SetString("LastActivityUtc", DateTime.UtcNow.ToString("O"));
            return Ok(new { success = true });
        }

        /// <summary>
        /// Explicit logout endpoint (used by inactivity script).
        /// </summary>
        [HttpPost("logout")]
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return Ok(new { success = true });
        }
    }
}