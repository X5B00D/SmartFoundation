using System.Collections.Generic;

namespace SmartFoundation.UI.ViewModels.SmartTable
{
    public class SmartTableDsModel
    {
        public List<TableColumn> Columns { get; set; } = new();
        public List<Dictionary<string, object?>> Rows { get; set; } = new();
        public string RowIdField { get; set; } = "Id";

        public int PageSize { get; set; } = 10;
        public List<int> PageSizes { get; set; } = new() { 10, 25, 50, 100 };

        public bool Searchable { get; set; } = true;
        public string? SearchPlaceholder { get; set; } = "بحث…";
        public List<string>? QuickSearchFields { get; set; } = new();

        public bool AllowExport { get; set; } = true;
        public bool ShowHeader { get; set; } = true;
        public bool ShowFooter { get; set; } = true;

        public TableToolbarConfig Toolbar { get; set; } = new();
    }
}