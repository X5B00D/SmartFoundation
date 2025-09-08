using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartCard;

namespace SmartFoundation.UI.ViewComponents.SmartCard;

public class SmartCardViewComponent : ViewComponent
{
    public IViewComponentResult Invoke(SmartCardModel model) => View(model);
}
