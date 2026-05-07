using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartTable;

namespace SmartFoundation.UI.ViewComponents.SmartTableDS
{
    public class SmartTableDSViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(SmartTableDsModel model)
        {
            model ??= new SmartTableDsModel();
            model.Columns ??= new List<TableColumn>();
            model.RowActions ??= new List<TableAction>();
            model.PageSizes ??= new List<int> { 10, 25, 50, 100 };
            model.Toolbar ??= new TableToolbarConfig();
            model.Rows ??= new List<Dictionary<string, object?>>();
            model.StyleRules ??= new List<TableStyleRule>();
            model.ProfileBadges ??= new List<ProfileBadge>();

            return View("Default", model);
        }
    }
}
