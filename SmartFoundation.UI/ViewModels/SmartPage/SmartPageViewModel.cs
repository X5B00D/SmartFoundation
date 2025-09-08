using SmartFoundation.UI.ViewModels.SmartCard;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPrint;

namespace SmartFoundation.UI.ViewModels.SmartPage;

public class SmartPageViewModel
{
    public string? PageTitle { get; set; } = "Smart Demo";
    public string? PanelTitle { get; set; } = "Smart Demo";

    public string SpName { get; set; } = "";
    public string Operation { get; set; } = "select";

    public List<SmartCardModel> Cards { get; set; } = new();
    public FormConfig? Form { get; set; }

    // ✨ هنا الخاصية الجديدة للطباعة
    public SmartPrintDocument? PrintDoc { get; set; }
}
