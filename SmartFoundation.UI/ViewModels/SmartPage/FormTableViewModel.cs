namespace SmartFoundation.UI.ViewModels.SmartPage
{
    public sealed class FormTableViewModel
    {
        public SmartFoundation.UI.ViewModels.SmartForm.FormConfig Form { get; set; } = new();
        public SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel Table { get; set; } = new();
        public string? PageTitle { get; set; }
        public string? PanelTitle { get; set; }
    }
}