using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace SmartFoundation.Mvc.ViewComponents
{
    public class MenuItemsViewComponent : ViewComponent
    {
        private readonly MenuService _menuService;

        public MenuItemsViewComponent(MenuService menuService)
        {
            _menuService = menuService;
        }

        public async Task<IViewComponentResult> InvokeAsync()
        {
            var generalNo = HttpContext.Session.GetString("generalNo") ?? "63100004";

            var parameters = new Dictionary<string, object?>
            {
                { "generalNo", generalNo }
            };

            var jsonResult = await _menuService.GetUserMenu(parameters);
            var response = JsonSerializer.Deserialize<JsonElement>(jsonResult);

            var menuItems = response.GetProperty("success").GetBoolean()
                ? response.GetProperty("data").EnumerateArray().Select(MapToMenuItem).ToList()
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

        private static MenuItem MapToMenuItem(JsonElement element)
        {
            return new MenuItem
            {
                MPID = GetInt(element, "MPID"),
                MenuName_A = GetString(element, "menuName_A") ?? GetString(element, "menuname_a") ?? GetString(element, "MenuName_A"),
                MPSerial = GetInt(element, "MPSerial"),
                MPLink = GetString(element, "MPLink", "#") ?? GetString(element, "mplink"),
                ParentMenuID_FK = GetNullableInt(element, "parentMenuID_FK") ?? GetNullableInt(element, "parentmenuid_fk"),
                ProgramID = GetInt(element, "programID", GetInt(element, "programid")),
                Parents = GetNullableInt(element, "parents"),
                Levels = GetInt(element, "levels"),
                MPIcon = GetString(element, "MPIcon") ?? GetString(element, "mpicon")
            };
        }

        private static string GetString(JsonElement element, string key, string fallback = "")
        {
            if (TryGetProperty(element, key, out var prop))
            {
                if (prop.ValueKind == JsonValueKind.String)
                    return prop.GetString() ?? fallback;
                if (prop.ValueKind != JsonValueKind.Null)
                    return prop.ToString();
            }
            return fallback;
        }

        private static int GetInt(JsonElement element, string key, int fallback = 0)
        {
            if (TryGetProperty(element, key, out var prop))
            {
                if (prop.ValueKind == JsonValueKind.Number)
                    return prop.GetInt32();
                if (prop.ValueKind == JsonValueKind.String && int.TryParse(prop.GetString(), out var parsed))
                    return parsed;
            }
            return fallback;
        }

        private static int? GetNullableInt(JsonElement element, string key)
        {
            if (TryGetProperty(element, key, out var prop))
            {
                if (prop.ValueKind == JsonValueKind.Number)
                    return prop.GetInt32();
                if (prop.ValueKind == JsonValueKind.String && int.TryParse(prop.GetString(), out var parsed))
                    return parsed;
            }
            return null;
        }

        private static bool TryGetProperty(JsonElement element, string key, out JsonElement property)
        {
            // Try exact match first
            if (element.TryGetProperty(key, out property))
                return true;

            // Try case-insensitive match
            foreach (var prop in element.EnumerateObject())
            {
                if (string.Equals(prop.Name, key, StringComparison.OrdinalIgnoreCase))
                {
                    property = prop.Value;
                    return true;
                }
            }

            property = default;
            return false;
        }
    }
}
