using System;
using System.Collections.Generic;
using SmartFoundation.Mvc.Models;

namespace SmartFoundation.Mvc.Helpers
{
    public static class MenuBreadcrumb
    {
        public class Crumb
        {
            public string Text { get; set; } = "";
            public string Url { get; set; } = "";
        }

        // يطلع المسار من شجرة المنيو حسب controller/action الحاليين
        public static List<Crumb> Get(List<MenuItem> tree, string controller, string action)
        {
            var path = new List<MenuItem>();
            if (!Find(tree, controller ?? "", action ?? "", path))
                return new List<Crumb>();

            var result = new List<Crumb>();
            foreach (var item in path)
            {
                result.Add(new Crumb
                {
                    Text = item.MenuName_A ?? "",
                    Url = BuildUrl(item)
                });
            }
            return result;
        }

        private static bool Find(List<MenuItem> nodes, string controller, string action, List<MenuItem> path)
        {
            foreach (var n in nodes)
            {
                path.Add(n);

                // ✅ نطابق صفحة المنيو النهائية: MPLink=Controller و MenuLink=Action
                if (!string.IsNullOrWhiteSpace(n.MenuLink) &&
                    string.Equals(n.MPLink ?? "", controller, StringComparison.OrdinalIgnoreCase) &&
                    string.Equals(n.MenuLink ?? "", action, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (n.Children != null && n.Children.Count > 0)
                {
                    if (Find(n.Children, controller, action, path))
                        return true;
                }

                path.RemoveAt(path.Count - 1);
            }
            return false;
        }

        private static string BuildUrl(MenuItem item)
        {
            // إذا هذا عنصر صفحة
            if (!string.IsNullOrWhiteSpace(item.MPLink) && !string.IsNullOrWhiteSpace(item.MenuLink))
                return "/" + item.MPLink.Trim('/') + "/" + item.MenuLink.Trim('/');

            // إذا هذا عنصر أب (يفتح قائمة فقط)
            return "";
        }
    }
}
