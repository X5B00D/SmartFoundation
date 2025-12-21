using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;

namespace SmartFoundation.Mvc.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly MastersServies _mastersServies;

        public NotificationsController(MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        [HttpPost("mark-clicked")]
        public async Task<IActionResult> MarkClicked([FromBody] MarkClickedRequest request)
        {
            if (request?.UserNotificationId == null)
            {
                return BadRequest(new { success = false, message = "Invalid request" });
            }

            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "User not authenticated" });
            }

            var result = await _mastersServies.MarkNotificationAsClicked(userId, request.UserNotificationId);
            
            return Ok(new { success = result });
        }

        [HttpPost("mark-all-read")]
        public async Task<IActionResult> MarkAllRead()
        {
            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "User not authenticated" });
            }

            var result = await _mastersServies.MarkAllNotificationsAsRead(userId);
            
            return Ok(new { success = result });
        }

        [HttpPost("mark-all-clicked")]
        public async Task<IActionResult> MarkAllClicked()
        {
            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "User not authenticated" });
            }

            var result = await _mastersServies.MarkAllNotificationsAsClicked(userId);
            
            return Ok(new { success = result });
        }

        // NEW: Mark single notification as read (on hover)
        [HttpPost("mark-read")]
        public async Task<IActionResult> MarkRead([FromBody] MarkReadRequest request)
        {
            if (request?.UserNotificationId == null)
            {
                return BadRequest(new { success = false, message = "Invalid request" });
            }

            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "User not authenticated" });
            }

            var result = await _mastersServies.MarkNotificationAsRead(userId, request.UserNotificationId);
            
            return Ok(new { success = result });
        }

        [HttpGet("get-latest")]
        public async Task<IActionResult> GetLatest()
        {
            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { success = false, message = "User not authenticated" });
            }

            try
            {
                var count = await _mastersServies.GetUserNotificationCount(userId);
                var items = await _mastersServies.GetUserNotifications(userId);
                
                return Ok(new
                {
                    success = true,
                    count = count,
                    notifications = items.Select(n => new
                    {
                        userNotificationId = n.UserNotificationId,
                        title = n.Title,
                        body = n.Body,
                        url_ = n.Url_,
                        timeAgo = n.TimeAgo,
                        isRead = n.IsRead,
                        isClicked = n.IsClicked
                    })
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Error fetching notifications" });
            }
        }
    }

    public class MarkClickedRequest
    {
        public long UserNotificationId { get; set; }
    }

    public class MarkReadRequest
    {
        public long UserNotificationId { get; set; }
    }
}
