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

                // Treat DeliveredUtc as local time (since your DB stores local time)
                var deliveredLocal = DeliveredUtc.Value;
                var nowLocal = DateTime.Now;

                var diff = nowLocal - deliveredLocal;

                if (diff.TotalMinutes < 1) return "الآن";
                if (diff.TotalMinutes > 1 && diff.TotalMinutes < 3) return $"قبل دقيقتان";
                if (diff.TotalMinutes > 2 && diff.TotalMinutes < 11) return $"قبل {(int)diff.TotalMinutes} دقائق";
                if (diff.TotalMinutes > 10 && diff.TotalMinutes < 60) return $"قبل {(int)diff.TotalMinutes} دقيقة";
                if (diff.TotalMinutes > 60 && diff.TotalHours < 2) return $"قبل ساعة";
                if (diff.TotalHours > 1 && diff.TotalHours < 3) return $"قبل ساعتان";
                if (diff.TotalHours > 2 && diff.TotalHours < 11) return $"قبل {(int)diff.TotalHours} ساعات";
                if (diff.TotalHours > 10 && diff.TotalHours < 24) return $"قبل {(int)diff.TotalHours} ساعة";
                if (diff.TotalHours > 24 && diff.TotalDays < 2) return $"قبل يوم";
                if (diff.TotalDays > 1 && diff.TotalDays < 3) return $"قبل يومان";
                if (diff.TotalDays > 2 && diff.TotalDays < 7) return $"قبل {(int)diff.TotalDays} أيام";

                return deliveredLocal.ToString("yyyy-MM-dd");
            }
        }
    }
}