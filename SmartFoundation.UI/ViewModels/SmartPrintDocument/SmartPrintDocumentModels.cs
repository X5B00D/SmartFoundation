using System;
using System.Collections.Generic;

namespace SmartFoundation.UI.ViewModels.SmartPrint
{
    // الجذر: يمثل مستند الطباعة الكامل
    public class SmartPrintDocument
    {
        public string Title { get; set; } = "تقرير";
        public string? SubTitle { get; set; }
        public PageOptions Page { get; set; } = new();
        public List<HeaderSlot> Headers { get; set; } = new();
        public List<FooterSlot> Footers { get; set; } = new();
        public Dictionary<string, List<Dictionary<string, object?>>> Datasets { get; set; } = new();
        public List<PrintBlock> Blocks { get; set; } = new();
    }

    // إعدادات الصفحة
    public class PageOptions
    {
        public string Size { get; set; } = "A4";              // A4 | Letter | Custom
        public string Orientation { get; set; } = "portrait"; // portrait | landscape
        public double MarginTopCm { get; set; } = 1.5;
        public double MarginRightCm { get; set; } = 1.5;
        public double MarginBottomCm { get; set; } = 1.5;
        public double MarginLeftCm { get; set; } = 1.5;
        public string Theme { get; set; } = "zebra";          // zebra|minimal|bordered
        public string Direction { get; set; } = "rtl";        // rtl | ltr
        public string Culture { get; set; } = "ar-SA";        // للتواريخ/الأرقام
        public string? WatermarkText { get; set; }
    }

    // الهيدر والفوتر
    public class HeaderSlot
    {
        public string Slot { get; set; } = "default"; // first|default|odd|even|last
        public double? HeightCm { get; set; }
        public List<PrintBlock> Blocks { get; set; } = new();
    }

    public class FooterSlot
    {
        public string Slot { get; set; } = "default";
        public double? HeightCm { get; set; }
        public List<PrintBlock> Blocks { get; set; } = new();
    }

    // الأساس لأي Block (جدول، نص، صورة.. إلخ)
    public abstract class PrintBlock
    {
        public string Type { get; set; } = "";
        public string? Title { get; set; }
        public string? Css { get; set; }
        public bool PageBreakBefore { get; set; }
        public bool PageBreakAfter { get; set; }
        public bool KeepTogether { get; set; }
    }

    // النصوص
    public class TextBlock : PrintBlock
    {
        public string Text { get; set; } = "";
        public bool IsHtml { get; set; } = false;
    }

    // جدول
    public class TableBlock : PrintBlock
    {
        public string Dataset { get; set; } = "main";
        public List<TableColumn> Columns { get; set; } = new();
        public List<string>? GroupBy { get; set; }
        public List<AggregateSpec>? Aggregates { get; set; }
        public bool Zebra { get; set; } = true;
        public string? RowClassExpr { get; set; } // تعبير لتلوين الصفوف
    }

    public class TableColumn
    {
        public string Field { get; set; } = "";
        public string Header { get; set; } = "";
        public string? Format { get; set; } // "n2", "c", "yyyy-MM-dd"
        public string Align { get; set; } = "start"; // start|center|end
        public string? Width { get; set; }
        public bool Sum { get; set; }
    }

    public class AggregateSpec
    {
        public string Field { get; set; } = "";
        public string Function { get; set; } = "sum"; // sum|avg|count|max|min
    }

    // Key/Value (معلومات العميل مثلاً)
    public class KeyValueBlock : PrintBlock
    {
        public List<KeyValueItem> Items { get; set; } = new();
        public int Columns { get; set; } = 2; // كم عمود يعرض kv
    }

    public class KeyValueItem
    {
        public string Label { get; set; }
        public string Value { get; set; } // يدعم Tokens {Field}
        public KeyValueItem(string label, string value)
        {
            Label = label; Value = value;
        }
    }

    // صورة
    public class ImageBlock : PrintBlock
    {
        public string Src { get; set; } = "";
        public string? Width { get; set; }
        public string? Height { get; set; }
    }

    // توقيع
    public class SignatureBlock : PrintBlock
    {
        public List<string> Placeholders { get; set; } = new();
    }

    // فاصل/مسافة
    public class DividerBlock : PrintBlock { }
    public class SpacerBlock : PrintBlock
    {
        public double HeightCm { get; set; } = 0.5;
    }

    // مستقبلًا: Charts / QR / Barcode
}
