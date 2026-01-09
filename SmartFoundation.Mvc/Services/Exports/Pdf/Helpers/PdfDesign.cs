using QuestPDF.Fluent;
using QuestPDF.Infrastructure;

namespace SmartFoundation.Mvc.Services.Exports.Pdf.Helpers
{
    public static class PdfDesign
    {
        // ===== Typography =====
        public const string Font = "Arial";
        public const float TitleSize = 18;
        public const float SubtitleSize = 11;
        public const float BodySize = 10;
        public const float SmallSize = 9;

        // ===== Colors (QuestPDF.Helpers.Colors => string) =====
        public static readonly string PageBg = QuestPDF.Helpers.Colors.White;
        public static readonly string Border = QuestPDF.Helpers.Colors.Grey.Lighten1;
        public static readonly string BorderDark = QuestPDF.Helpers.Colors.Grey.Medium;

        public static readonly string HeaderBand = QuestPDF.Helpers.Colors.Grey.Lighten4; // شريط العنوان
        public static readonly string HeaderText = QuestPDF.Helpers.Colors.Black;

        public static readonly string TableHeadBg = QuestPDF.Helpers.Colors.Grey.Darken2;  // هيدر الجدول 
        public static readonly string TableHeadFg = QuestPDF.Helpers.Colors.White;

        public static readonly string ZebraAlt = QuestPDF.Helpers.Colors.Grey.Lighten4;

        public static TextStyle BaseText() =>
            TextStyle.Default.FontFamily(Font).FontSize(BodySize).FontColor(QuestPDF.Helpers.Colors.Black);

        public static TextStyle SmallText() =>
            TextStyle.Default.FontFamily(Font).FontSize(SmallSize).FontColor(QuestPDF.Helpers.Colors.Grey.Darken2);

        public static TextStyle TitleText() =>
            TextStyle.Default.FontFamily(Font).FontSize(TitleSize).FontColor(HeaderText).SemiBold();

        public static TextStyle SubtitleText() =>
            TextStyle.Default.FontFamily(Font).FontSize(SubtitleSize).FontColor(QuestPDF.Helpers.Colors.Grey.Darken3);

        // ===== Page frame (إطار خفيف يعطي رسمية) =====
        public static void PageFrame(IContainer container)
        {
            container
                .Border(1).BorderColor(Border)
                .Padding(12);
        }

        // ===== Header (شريط علوي واضح) =====
        public static void BuildHeader(IContainer container, PdfTableRequest request)
        {
            container.Column(col =>
            {
                col.Spacing(8);

                // Title band
                col.Item()
                    .Background(HeaderBand)
                    .Border(1).BorderColor(Border)
                    .PaddingVertical(10).PaddingHorizontal(12)
                    .Row(row =>
                    {
                        row.RelativeItem().AlignCenter().Text(request.Title ?? "")
                            .Style(TitleText());

                        // لو تبغى لاحقًا تحط شعار، خله هنا
                        // row.ConstantItem(60).Height(30).AlignRight().Placeholder();
                    });

                // Subtitle
                if (!string.IsNullOrWhiteSpace(request.HeaderSubtitle))
                {
                    col.Item().AlignCenter()
                        .Text(request.HeaderSubtitle)
                        .Style(SubtitleText());
                }

                // Meta box
                col.Item()
                    .Border(1).BorderColor(Border)
                    .PaddingVertical(8).PaddingHorizontal(10)
                    .Row(row =>
                    {
                        if (request.ShowGeneratedAt)
                        {
                            row.RelativeItem().AlignRight()
                                .Text($"تاريخ التوليد: {request.GeneratedAt:yyyy-MM-dd HH:mm}")
                                .Style(SmallText());
                        }

                        if (!string.IsNullOrWhiteSpace(request.GeneratedBy))
                        {
                            row.RelativeItem().AlignLeft()
                                .Text($"المستخدم: {request.GeneratedBy}")
                                .Style(SmallText());
                        }
                    });
            });
        }

        // ===== Table =====
        public static void HeaderCell(IContainer cell, string text)
        {
            cell
                .Background(TableHeadBg)
                .Border(1).BorderColor(BorderDark)
                .PaddingVertical(7).PaddingHorizontal(8)
                .AlignMiddle()
                .Text(text ?? "")
                    .Style(BaseText())
                    .FontColor(TableHeadFg)
                    .Bold()
                    .FontSize(BodySize)
                    //.AlignRight();
                    .AlignCenter();

        }


        public static void InFrame(IContainer container, Action<IContainer> content)
        {
            var framed = container
                .Border(1).BorderColor(Border)
                .Padding(12);

            content(framed);
        }

        public static void BodyCell(IContainer cell, string text, string bgColor)
        {
            cell
                .Background(bgColor)
                .Border(1).BorderColor(Border)
                .PaddingVertical(7).PaddingHorizontal(8)
                .AlignMiddle()
                .Text(text ?? "")
                    .Style(BaseText())
                    .FontSize(SmallSize)
                    .AlignRight();
        }

        public static void BuildTable(IContainer container, PdfTableRequest request)
        {
            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    foreach (var _ in request.Columns)
                        columns.RelativeColumn();
                });

                // Header row
                foreach (var c in request.Columns)
                    table.Cell().Element(cell => HeaderCell(cell, c.Label));

                // Body rows
                var rowIndex = 0;
                foreach (var dataRow in request.Rows)
                {
                    string bg = (rowIndex % 2 == 0)
                        ? QuestPDF.Helpers.Colors.White
                        : ZebraAlt;

                    foreach (var c in request.Columns)
                    {
                        var value = dataRow.ContainsKey(c.Field)
                            ? dataRow[c.Field]?.ToString() ?? ""
                            : "";

                        table.Cell().Element(cell => BodyCell(cell, value, bg));
                    }

                    rowIndex++;
                }
            });
        }

        // ===== Footer =====
        public static void BuildFooter(IContainer container)
        {
            container
                .PaddingTop(8)
                //.BorderTop(1).BorderColor(Border)
                .PaddingTop(6)
                .Row(row =>
                {
                    //row.RelativeItem().AlignLeft()
                    //    .Text(t =>
                    //    {
                    //        t.Span("SmartFoundation").Style(SmallText());
                    //    });

                    row.RelativeItem().AlignRight()
                        .Text(t =>
                        {
                            t.Span("صفحة ").Style(SmallText());
                            t.CurrentPageNumber();
                            t.Span(" من ").Style(SmallText());
                            t.TotalPages();
                        });
                });
        }
    }
}
