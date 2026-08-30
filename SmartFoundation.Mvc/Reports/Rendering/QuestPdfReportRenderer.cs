using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace SmartFoundation.MVC.Reports;

public static class QuestPdfReportRenderer
{
    public static byte[] Render(ReportResult report)
    {
        return Document.Create(container =>
        {
            var splitByGroup =
                report.Kind == ReportKind.Table &&
                report.StartEachGroupOnNewPage &&
                !string.IsNullOrWhiteSpace(report.GroupByKey);

            if (splitByGroup)
            {
                var groups = report.Rows
                    .GroupBy(row => row.TryGetValue(report.GroupByKey!, out var value)
                        ? value?.ToString() ?? "غير محدد"
                        : "غير محدد")
                    .ToList();

                foreach (var group in groups)
                {
                    var groupReport = CloneForGroup(report, group.ToList());

                    var groupCaption = string.IsNullOrWhiteSpace(report.GroupTitle)
                        ? group.Key
                        : $"{report.GroupTitle}: {group.Key}";

                    ComposePage(container, groupReport, groupCaption);
                }

                return;
            }

            ComposePage(container, report, null);
        }).GeneratePdf();
    }

    private static void ComposePage(
        IDocumentContainer container,
        ReportResult report,
        string? groupCaption)
    {
        var (orientation, fontSize) = DecideLayout(report);

        container.Page(page =>
        {
            page.Size(orientation == ReportOrientation.Landscape
                ? PageSizes.A4.Landscape()
                : PageSizes.A4);

            page.Margin(20);
            page.DefaultTextStyle(x => x.FontFamily("Tajawal").FontSize(fontSize));
            page.ContentFromRightToLeft();

            page.Header().Element(container =>
            {
                container.Column(column =>
                {
                    var officialHeader = column.Item();

                    if (report.HeaderRepeat == ReportHeaderRepeat.FirstPageOnly)
                        officialHeader = officialHeader.ShowOnce();

                    officialHeader.Element(c => HeaderFactory.Compose(c, report));

                    if (!string.IsNullOrWhiteSpace(groupCaption))
                    {
                        column.Item()
                            .PaddingTop(6)
                            .AlignRight()
                            .Text(groupCaption)
                            .Bold()
                            .FontSize(11);
                    }

                    if (report.Kind == ReportKind.Table &&
                        report.Columns.Count > 0)
                    {
                        column.Item()
                            .PaddingTop(6)
                            .Element(c => DynamicTableComponent.ComposeHeader(c, report));
                    }
                });
            });

            page.Content().Element(container =>
            {
                if (report.Kind == ReportKind.Letter)
                {
                    LetterBlocksComponent.Compose(container, report);
                    return;
                }

                DynamicTableComponent.Compose(container, report);
            });

            if (report.ShowFooter &&
                report.FooterFields != null &&
                report.FooterFields.Count > 0)
            {
                page.Footer().Element(c =>
                    StandardFooterComponent.Compose(c, report));
            }
        });
    }

    private static ReportResult CloneForGroup(
        ReportResult source,
        List<Dictionary<string, object?>> rows)
    {
        return new ReportResult
        {
            ReportId = source.ReportId,
            Title = source.Title,
            Kind = source.Kind,
            Orientation = source.Orientation,

            HeaderFields = source.HeaderFields,
            HeaderType = source.HeaderType,
            LogoPath = source.LogoPath,
            HeaderRepeat = source.HeaderRepeat,

            Columns = source.Columns,
            Rows = rows,
            TableFontSize = source.TableFontSize,

            ShowSerial = source.ShowSerial,
            SerialLabel = source.SerialLabel,
            SerialStart = source.SerialStart,

            GroupByKey = null,
            GroupTitle = null,
            StartEachGroupOnNewPage = false,

            LetterBlocks = source.LetterBlocks,
            LetterTitle = source.LetterTitle,
            LetterTitleFontSize = source.LetterTitleFontSize,

            FooterFields = source.FooterFields,
            ShowFooter = source.ShowFooter
        };
    }

    private static (ReportOrientation orientation, float fontSize)
        DecideLayout(ReportResult report)
    {
        if (report.Orientation != ReportOrientation.Auto)
            return (report.Orientation, 10);

        var serialWeight = report.ShowSerial ? 1 : 0;
        var colCount = report.Columns.Count + serialWeight;
        var weightSum = report.Columns.Sum(c => c.Weight) + serialWeight;

        if (colCount > 12 || weightSum > 22)
            return (ReportOrientation.Landscape, 9);

        if (colCount > 8 || weightSum > 16)
            return (ReportOrientation.Landscape, 10);

        return (ReportOrientation.Portrait, 11);
    }
}