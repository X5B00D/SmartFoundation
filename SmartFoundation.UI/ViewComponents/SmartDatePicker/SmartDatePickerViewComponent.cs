using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartDatePicker;

namespace SmartFoundation.UI.ViewComponents.SmartDatePicker
{
    public class SmartDatePickerViewComponent : ViewComponent
    {
        public IViewComponentResult Invoke(DatepickerViewModel model) => View("Default", model);
    }
}
