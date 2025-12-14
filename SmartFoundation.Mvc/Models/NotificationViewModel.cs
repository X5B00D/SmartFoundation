using SmartFoundation.Application.Services.Models;

namespace SmartFoundation.Mvc.Models
{
    public class NotificationViewModel
    {
        public int Count { get; set; }
        public List<NotificationItem> Items { get; set; } = new();
    }
}