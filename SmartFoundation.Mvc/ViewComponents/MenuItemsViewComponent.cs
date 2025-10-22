using Microsoft.AspNetCore.Mvc;
using SmartFoundation.DataEngine.Core.Interfaces;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.Mvc.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartFoundation.Mvc.ViewComponents
{
    public class MenuItemsViewComponent : ViewComponent
    {
        private readonly ISmartComponentService _smartComponentService;

        public MenuItemsViewComponent(ISmartComponentService smartComponentService)
        {
            _smartComponentService = smartComponentService;
        }

        public async Task<IViewComponentResult> InvokeAsync()
        {
            var generalNo = HttpContext.Session.GetString("generalNo") ?? "63100004"; // Default to current user if not set

            var request = new SmartRequest
            {
                Operation = "sp",
                SpName = "ListOfMenuByUser_MVC",
                Params = new Dictionary<string, object?>
                {
                    { "generalNo", generalNo }
                }
            };

            var response = await _smartComponentService.ExecuteAsync(request);

            var menuItems = response.Success
                ? response.Data.Select(MapToMenuItem).ToList()
                : new List<MenuItem>();

            var menuTree = BuildMenuHierarchy(menuItems);
            return View("~/Views/Shared/_SidebarNavbar.cshtml", menuTree);
        }

        private static List<MenuItem> BuildMenuHierarchy(IEnumerable<MenuItem> items)
        {
            // Since we're now using JavaScript to build the menu hierarchy on the client-side,
            // we no longer need to build the hierarchy on the server-side.
            // Just return all items as a flat list, and JavaScript will handle the parent-child relationships
            return items.OrderBy(x => x.MPSerial).ToList();
        }

        private static MenuItem MapToMenuItem(Dictionary<string, object?> row)
        {
            return new MenuItem
            {
                MPID = GetInt(row, "MPID"),
                MenuName_A = GetString(row, "menuName_A") ?? GetString(row, "menuname_a") ?? GetString(row, "MenuName_A"),
                MPSerial = GetInt(row, "MPSerial"),
                MPLink = GetString(row, "MPLink", "#") ?? GetString(row, "mplink"),
                ParentMenuID_FK = GetNullableInt(row, "parentMenuID_FK") ?? GetNullableInt(row, "parentmenuid_fk"),
                ProgramID = GetInt(row, "programID", GetInt(row, "programid")),
                Parents = GetNullableInt(row, "parents"),
                Levels = GetInt(row, "levels"),
                MPIcon = GetString(row, "MPIcon") ?? GetString(row, "mpicon")
            };
        }

        private static string GetString(Dictionary<string, object?> row, string key, string fallback = "")
        {
            var value = GetValue(row, key);
            return value?.ToString() ?? fallback;
        }

        private static int GetInt(Dictionary<string, object?> row, string key, int fallback = 0)
        {
            var value = GetValue(row, key);
            if (value is null) return fallback;

            if (value is int i) return i;
            if (value is long l) return (int)l;
            if (value is decimal d) return (int)d;
            if (value is double dbl) return (int)dbl;
            if (value is float f) return (int)f;

            return int.TryParse(value.ToString(), out var parsed) ? parsed : fallback;
        }

        private static int? GetNullableInt(Dictionary<string, object?> row, string key)
        {
            var value = GetValue(row, key);
            if (value is null) return null;

            if (value is int i) return i;
            if (value is long l) return (int)l;
            if (value is decimal d) return (int)d;
            if (value is double dbl) return (int)dbl;
            if (value is float f) return (int)f;

            return int.TryParse(value.ToString(), out var parsed) ? parsed : null;
        }

        private static object? GetValue(Dictionary<string, object?> row, string key)
        {
            if (row.TryGetValue(key, out var value))
            {
                return value;
            }

            var match = row.FirstOrDefault(kv => string.Equals(kv.Key, key, StringComparison.OrdinalIgnoreCase));
            return !string.IsNullOrEmpty(match.Key) ? match.Value : null;
        }
    }
}
