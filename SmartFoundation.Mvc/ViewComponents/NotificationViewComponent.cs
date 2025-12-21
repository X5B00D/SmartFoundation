using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;

namespace SmartFoundation.Mvc.ViewComponents
{
    public class NotificationViewComponent : ViewComponent
    {
        private readonly MastersServies _mastersServies;

        public NotificationViewComponent(MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        public async Task<IViewComponentResult> InvokeAsync()
        {
            var userId = HttpContext.Session.GetString("usersID") ?? "";
            
            var count = await _mastersServies.GetUserNotificationCount(userId);
            var items = await _mastersServies.GetUserNotifications(userId);
            
            var model = new NotificationViewModel
            {
                Count = count,
                Items = items // ✅ Remove .Take(10) to show ALL notifications
            };
            
            return View("Default", model);
        }
    }
}
