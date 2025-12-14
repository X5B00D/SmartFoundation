namespace SmartFoundation.Application.Services.Models
{
    public class NotificationItem
    {
        public long UserNotificationId { get; set; }
        public long NotificationId_FK { get; set; }
        public string? Title { get; set; }
        public string? Body { get; set; }
        public string? Url_ { get; set; }
        public DateTime? DeliveredUtc { get; set; }
        public bool IsClicked { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadUtc { get; set; }

        public DateTime? ClickUtc { get; set; }


        public string TimeAgo
        {
            get
            {
                if (!DeliveredUtc.HasValue) return "غير معروف";
                
                var diff = DateTime.UtcNow - DeliveredUtc.Value;
                
                if (diff.TotalMinutes < 1) return "الآن";
                if (diff.TotalMinutes < 60) return $"قبل {(int)diff.TotalMinutes} دقيقة";
                if (diff.TotalHours < 24) return $"قبل {(int)diff.TotalHours} ساعة";
                if (diff.TotalDays < 7) return $"قبل {(int)diff.TotalDays} يوم";
                
                return DeliveredUtc.Value.ToString("dd/MM/yyyy");
            }
        }
    }
}