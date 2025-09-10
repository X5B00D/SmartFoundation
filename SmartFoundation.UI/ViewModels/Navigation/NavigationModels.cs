using System.Collections.Generic;
using System.Linq;

namespace SmartFoundation.UI.ViewModels.Navigation
{
    // عنصر قائمة موحَّد: ينفع للتوب بار/السايد بار/الفوتر
    public class NavItem
    {
        public int Id { get; set; }
        public string Text { get; set; } = "";
        public string? Url { get; set; }
        public string? Icon { get; set; }       // مثال: "fa-solid fa-house"
        public int? ParentId { get; set; }
        public int Level { get; set; }          // من الـSP (Levels) إن وُجد
        public int? Order { get; set; }         // من MPSerial
        public bool IsActive { get; set; }
        public List<NavItem> Children { get; set; } = new();
    }

    // فيو موديل بسيط يغطي الهيدر/السايد/الفوتر
    public class NavigationViewModel
    {
        public string? AppName { get; set; } = "KFMC";
        public string? UserName { get; set; }
        public string? CurrentUrl { get; set; }

        // تقدر تستخدم واحد منهم أو كلهم حسب التصميم
        public List<NavItem> Top { get; set; } = new();
        public List<NavItem> Side { get; set; } = new();
        public List<NavItem> Footer { get; set; } = new();
    }

    // صفّ قديم يطابق أعمدة الـSP (ListOfMenuByUser_MVC)
    public sealed class LegacyMenuRow
    {
        public int MPID { get; set; }
        public string? menuName_A { get; set; }
        public int? MPSerial { get; set; }
        public string? MPLink { get; set; }
        public int? parentMenuID_FK { get; set; }
        public int? programID { get; set; }
        public int? Levels { get; set; }
        public string? MPIcon { get; set; }
    }

    // محوّل: من صفوف مسطّحة => شجرة NavItem نظيفة
    public static class NavigationAdapter
    {
        public static List<NavItem> BuildTree(IEnumerable<LegacyMenuRow> rows)
        {
            // 1) خزّن كل عنصر بالقاموس
            var dict = rows.ToDictionary(
                r => r.MPID,
                r => new NavItem
                {
                    Id = r.MPID,
                    Text = r.menuName_A?.Trim() ?? "",
                    Url = NormalizeUrl(r.MPLink),
                    Icon = r.MPIcon,
                    ParentId = r.parentMenuID_FK,
                    Level = r.Levels ?? 1,
                    Order = r.MPSerial
                });

            // 2) اربط الأطفال بآبائهم
            foreach (var node in dict.Values)
            {
                if (node.ParentId.HasValue && dict.TryGetValue(node.ParentId.Value, out var parent))
                    parent.Children.Add(node);
            }

            // 3) رتّب حسب Order
            foreach (var n in dict.Values)
                n.Children = n.Children.OrderBy(c => c.Order ?? int.MaxValue).ToList();

            // 4) ارجع الجذور (اللي ما لها Parent)
            var roots = dict.Values
                            .Where(n => !n.ParentId.HasValue)
                            .OrderBy(n => n.Order ?? int.MaxValue)
                            .ToList();

            return roots;
        }

        // تنظيف روابط قديمة مثل ../Page.aspx => /Page
        private static string? NormalizeUrl(string? link)
        {
            if (string.IsNullOrWhiteSpace(link)) return null;
            var s = link.Replace("~/", "/")
                        .Replace("../", "/")
                        .Replace("./", "")
                        .Replace(".aspx", "");
            if (!s.StartsWith("/")) s = "/" + s;
            return s;
        }
    }
}
