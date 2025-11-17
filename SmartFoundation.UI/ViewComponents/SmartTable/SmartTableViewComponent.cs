using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;


namespace SmartFoundation.UI.ViewComponents.SmartTable
{
    
    public class SmartTableViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(TableConfig model)
        {
            // لو ما فيه إعدادات، أنشئ افتراضي
            model ??= new TableConfig();
            model.Columns ??= new List<TableColumn>();
            model.RowActions ??= new List<TableAction>();
            model.PageSizes ??= new List<int> { 5,10, 25, 50, 100 };
            model.Toolbar ??= new TableToolbarConfig();

            return View("Default", model);
        }
    }
}
