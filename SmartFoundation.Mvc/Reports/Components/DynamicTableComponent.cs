using QuestPDF.Fluent;
using QuestPDF.Infrastructure;

namespace SmartFoundation.MVC.Reports;

public static class DynamicTableComponent
{
    public static void Compose(IContainer container, ReportResult report)
    {
        container.Column(column =>
        {
            var rowIndex = 0;

            foreach (var reportRow in report.Rows)
            {
                var isEven = rowIndex % 2 == 0;
                var serialNumber = report.SerialStart + rowIndex;
                rowIndex++;

                // الصف كاملًا كوحدة واحدة
                column.Item().Element(c =>
                    ComposeDataRow(c, report, reportRow, isEven, serialNumber));
            }
        });
    }

    public static void ComposeHeader(IContainer container, ReportResult report)
    {
        container.Row(row =>
        {
            if (report.ShowSerial)
            {
                row.RelativeItem(1)
                    .Element(CellHeader)
                    .AlignMiddle()
                    .AlignCenter()
                    .Text(report.SerialLabel)
                    .FontSize(10)
                    .SemiBold()
                    .FontColor("#FFFFFF");
            }

            foreach (var column in report.Columns)
            {
                IContainer cell = column.Width.HasValue && column.Width.Value > 0
                    ? row.ConstantItem(column.Width.Value)
                    : row.RelativeItem(column.Weight <= 0 ? 1 : column.Weight);

                cell = cell.Element(CellHeader).AlignMiddle();

                cell = column.Align.ToLowerInvariant() switch
                {
                    "right" => cell.AlignRight(),
                    "center" => cell.AlignCenter(),
                    _ => cell.AlignLeft()
                };

                cell.Text(column.Title)
                    .FontSize(10)
                    .SemiBold()
                    .FontColor("#FFFFFF");
            }
        });
    }

    private static void ComposeDataRow(
    IContainer container,
    ReportResult report,
    Dictionary<string, object?> reportRow,
    bool isEven,
    int serialNumber)
    {
        container.PreventPageBreak().Row(row =>
        {
            if (report.ShowSerial)
            {
                row.RelativeItem(1)
                    .Element(c => CellBody(c, isEven))
                    .AlignMiddle()
                    .AlignCenter()
                    .Text(serialNumber.ToString())
                    .FontSize(report.TableFontSize ?? 9)
                    .FontColor("#333333");
            }

            foreach (var column in report.Columns)
            {
                IContainer cell = column.Width.HasValue && column.Width.Value > 0
                    ? row.ConstantItem(column.Width.Value)
                    : row.RelativeItem(column.Weight <= 0 ? 1 : column.Weight);

                cell = cell
                    .Element(c => CellBody(c, isEven))
                    .AlignMiddle();

                cell = column.Align.ToLowerInvariant() switch
                {
                    "right" => cell.AlignRight(),
                    "center" => cell.AlignCenter(),
                    _ => cell.AlignLeft()
                };

                var value = reportRow.TryGetValue(column.Key, out var item)
                    ? item
                    : null;

                cell.Text(FormatCell(value, column.Format))
                    .FontSize(column.FontSize ?? report.TableFontSize ?? 9)
                    .FontColor("#333333");
            }
        });
    }

    private static IContainer CellHeader(IContainer container) =>
        container.Background("#5A5A5A")
            .BorderBottom(2)
            .BorderColor("#9E9E9E")
            .Padding(5);

    private static IContainer CellBody(IContainer container, bool isEven) =>
        container.Background(isEven ? "#F5F5F5" : "#FFFFFF")
            .Border(0.5f)
            .BorderColor("#DDDDDD")
            .Padding(4);

    private static string FormatCell(object? value, string? format)
    {
        if (value == null || value == DBNull.Value)
            return "";

        if (value is DateTime date)
        {
            return format == "date"
                ? date.ToString("yyyy-MM-dd")
                : date.ToString("yyyy-MM-dd HH:mm:ss");
        }

        if (format == "number" && decimal.TryParse(value.ToString(), out var number))
            return number.ToString("0.##");

        return value.ToString() ?? "";
    }
}