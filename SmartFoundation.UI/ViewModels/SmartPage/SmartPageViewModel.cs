using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartTable;

namespace SmartFoundation.UI.ViewModels.SmartPage
{
    public class SmartPageViewModel
    {
        public string? PageTitle { get; set; } = "Smart Demo";
        public string? PanelTitle { get; set; } = "Smart Demo";

        public string SpName { get; set; } = "";
        public string Operation { get; set; } = "select";

        public FormConfig? Form { get; set; }
        public TableConfig? Table { get; set; }  
                                                  

    }
}
