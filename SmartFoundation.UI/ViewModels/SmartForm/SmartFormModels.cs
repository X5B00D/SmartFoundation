using System.Text.RegularExpressions;

namespace SmartFoundation.UI.ViewModels.SmartForm
{
    public class OptionItem
    {
        public string Value { get; set; } = string.Empty;
        public string Text { get; set; } = string.Empty;
        public bool Selected { get; set; } = false;
        public bool Disabled { get; set; } = false;
        public string? TextEn { get; set; }
        public string? Icon { get; set; }
    }

    public class FieldConfig
    {
        // أساسية
        public string Name { get; set; } = string.Empty;

        public string Label { get; set; } = string.Empty;
        public string Type { get; set; } = "text";
        public string? Placeholder { get; set; }
        public string? HelpText { get; set; }
        public string? Value { get; set; }
        public bool Required { get; set; } = false;
        public bool Readonly { get; set; } = false;
        public bool Disabled { get; set; } = false;
        public bool Multiple { get; set; } = false;
        public bool IsHidden { get; set; } = false;

        // قيود عامة
        public int? Min { get; set; }

        public int? Max { get; set; }
        public int? MaxLength { get; set; }
        public string? Pattern { get; set; }
        public string? InputPattern { get; set; }
        public string? InputLang { get; set; }

        // تنسيق / واجهة
        public string? ColCss { get; set; }

        public string? ExtraCss { get; set; }
        public string? Icon { get; set; }
        public string? OnChangeJs { get; set; }
        public string? DependsOn { get; set; }
        public string? DependsUrl { get; set; }
        public string? SectionTitle { get; set; }
        public List<OptionItem> Options { get; set; } = new();

        // أنواع خاصة
        public bool IsNumericOnly { get; set; } = false;

        public bool IsIban { get; set; } = false;

        public string? TextMode { get; set; }
        /* القيم الممكنة:
           - arabic        => أحرف عربية فقط
           - english       => أحرف إنجليزية فقط
           - numeric       => أرقام فقط
           - alphanumeric  => إنجليزي + أرقام
           - arabicnum     => عربي + أرقام
           - engsentence   => إنجليزي (حروف + مسافات + علامات بسيطة)
           - arsentence    => عربي (حروف + مسافات + علامات بسيطة)
           - email         => بريد إلكتروني
           - url           => روابط
           - custom        => Regex مخصّص في Pattern
        */

        // خصائص المتصفح
        public string? Autocomplete { get; set; } = "off"; // off | on | name | email | username | new-password | current-password

        public bool? Spellcheck { get; set; }
        public string? Autocapitalize { get; set; }
        public string? Autocorrect { get; set; }

        // ===== التاريخ المتقدم =====
        public string? Calendar { get; set; } = "gregorian";   // gregorian | hijri | both

        public string? DateInputCalendar { get; set; } = "gregorian";
        public string? MirrorName { get; set; }
        public string? MirrorCalendar { get; set; } = "hijri";
        public string? DateDisplayLang { get; set; } = "ar";
        public string? DateNumerals { get; set; } = "latn";
        public bool ShowDayName { get; set; } = true;
        public bool DefaultToday { get; set; } = false;
        public string? MinDateStr { get; set; }
        public string? MaxDateStr { get; set; }
        public string? DisplayFormat { get; set; }

        public string? ColCssFrom { get; set; }       // حجم خانة "من"
        public string? ColCssTo { get; set; }       // حجم خانة "إلى"


        public TableConfig? Table { get; set; } // الحقول الخاصة بالجدول




        public string GetResolvedColCss()
        {
            var raw = (ColCss ?? "").Trim();
            if (string.IsNullOrWhiteSpace(raw))
                return "col-span-12 md:col-span-6"; // افتراضي: نصف الشاشة

            var tokens = Regex.Split(raw, @"\s+")
                              .Where(t => !string.IsNullOrWhiteSpace(t))
                              .ToList();

            var outTokens = new List<string>();
            var hasBase = false;

            foreach (var t in tokens)
            {
                // 1) sm|md|lg|xl|2xl:number  =>  sm|md|..:col-span-N
                var mBpNum = Regex.Match(t, @"^(sm|md|lg|xl|2xl):(\d{1,2})$");
                if (mBpNum.Success)
                {
                    var bp = mBpNum.Groups[1].Value;
                    var val = Clamp(int.Parse(mBpNum.Groups[2].Value), 1, 12);
                    outTokens.Add($"{bp}:col-span-{val}");
                    continue;
                }

                // 2) col-span-N (أساسي) – أبقيه وعدّ أنه موجود
                var mBase = Regex.Match(t, @"^col-span-(\d{1,2})$");
                if (mBase.Success)
                {
                    var val = Clamp(int.Parse(mBase.Groups[1].Value), 1, 12);
                    outTokens.Add($"col-span-{val}");
                    hasBase = true;
                    continue;
                }

                // 3) sm|md|..:col-span-N – أبقيه بعد ضبط N
                var mBpCol = Regex.Match(t, @"^(sm|md|lg|xl|2xl):col-span-(\d{1,2})$");
                if (mBpCol.Success)
                {
                    var bp = mBpCol.Groups[1].Value;
                    var val = Clamp(int.Parse(mBpCol.Groups[2].Value), 1, 12);
                    outTokens.Add($"{bp}:col-span-{val}");
                    continue;
                }

                // 4) مجرد رقم (1–12) → col-span-12 md:col-span-N
                var mNum = Regex.Match(t, @"^0*(\d{1,2})$");
                if (mNum.Success)
                {
                    var val = Clamp(int.Parse(mNum.Groups[1].Value), 1, 12);
                    outTokens.Add("col-span-12");
                    outTokens.Add($"md:col-span-{val}");
                    hasBase = true;
                    continue;
                }

                // 5) أي شيء آخر اتركه كما هو
                outTokens.Add(t);
            }

            // لو ما فيه أساس للموبايل، خليها فل عرض
            if (!hasBase)
                outTokens.Insert(0, "col-span-12");

            // إزالة التكرار وترتيب
            var result = string.Join(" ", outTokens.Distinct());
            return Regex.Replace(result, @"\s+", " ").Trim();
        }

        private static int Clamp(int v, int min, int max) => v < min ? min : (v > max ? max : v);
    }

    public class FormButtonConfig
    {
        public string? Text { get; set; }
        public string Type { get; set; } = "button";
        public string? CssClass { get; set; }
        public string? Icon { get; set; }
        public string? OnClickJs { get; set; }
        public bool Show { get; set; } = true;
        public string? StoredProcedureName { get; set; }
        public string? Operation { get; set; } = "custom";
        public string? Color { get; set; } // success, danger, info, secondary, warning
    }

    public class FormConfig
    {
        public string FormId { get; set; } = "smartForm";
        public string Title { get; set; } = "نموذج الإدخال";
        public string Method { get; set; } = "POST";
        public string ActionUrl { get; set; } = "/SmartComponent/Execute";
        public string SubmitText { get; set; } = "حفظ";
        public string CancelText { get; set; } = "إلغاء";
        public string? ResetText { get; set; } = "تفريغ";
        public bool ShowPanel { get; set; } = true;
        public bool ShowReset { get; set; } = false;
        public string? StoredProcedureName { get; set; }
        public string? Operation { get; set; } = "insert";
        public string? StoredSuccessMessageField { get; set; } = "Message";
        public string? StoredErrorMessageField { get; set; } = "Error";
        public string? SuccessMessage { get; set; }
        public string? ErrorMessage { get; set; }
        public string? RedirectUrl { get; set; }
        public List<FieldConfig> Fields { get; set; } = new();
        public List<FormButtonConfig> Buttons { get; set; } = new();

        
    }


    //خاص بالجدول
    public class TableBadgeConfig
    {
        public Dictionary<string, string> Map { get; set; } = new(); // قيمة => CSS Classes
        public string DefaultClass { get; set; } = "bg-gray-100 text-gray-700";
    }

    public class TableColumn
    {
        public string Field { get; set; } = string.Empty; // اسم العمود من الـ SP
        public string Label { get; set; } = string.Empty; // التسمية بالعربي/الانجليزي
        public bool Sortable { get; set; } = true;        // يدعم الفرز
        public bool Visible { get; set; } = true;         // إخفاء/إظهار
        public string? Width { get; set; }                // CSS عرض العمود
        public string? Align { get; set; } = "right";     // left | right | center
        public string? Type { get; set; } = "text";       // text | number | date | badge | bool | money | datetime
        public string? FormatString { get; set; }         // "{0:dd/MM/yyyy}"
        public string? FormatterJs { get; set; }          // JS function(row,col,table) => html/text
        public bool ShowInModal { get; set; } = true;     // تخصيص ظهور العمود في المودال
        public TableBadgeConfig? Badge { get; set; }      // خريطة ألوان/كلاسات للشارات
    }

    public class TableAction
    {
        public string Label { get; set; } = "";
        public string Icon { get; set; } = "";
        public string Color { get; set; } = "secondary";
        public string? OnClickJs { get; set; }

        public bool Show { get; set; } = true;
        public bool OpenModal { get; set; } = false;
        public string? ModalSp { get; set; }
        public string? ModalOp { get; set; } = "detail";
        public string? ModalTitle { get; set; }
        public List<TableColumn>? ModalColumns { get; set; }
        public string? ConfirmText { get; set; }

        public bool IsEdit { get; set; } = false;
        public string? SaveSp { get; set; }
        public string? SaveOp { get; set; } = "update";

        //  الجديد
        public FormConfig? OpenForm { get; set; }
        public string? FormUrl { get; set; }
    }

    public class TableToolbarConfig
    {
        public bool ShowAdd { get; set; } = false;
        public bool ShowRefresh { get; set; } = true;
        public bool ShowColumns { get; set; } = true;
        public bool ShowExportCsv { get; set; } = true;
        public bool ShowExportExcel { get; set; } = true;
        public bool ShowAdvancedFilter { get; set; } = false;
        public bool ShowBulkDelete { get; set; } = false;

        // زر الإضافة كمثال (بإمكانك لاحقًا تعمل Config لكل زر على حدة)
        public TableAction? Add { get; set; }

        public bool ShowEdit { get; set; } = false;
        public TableAction? Edit { get; set; }
    }

    public class TableConfig
    {
        public string? Endpoint { get; set; }
        public string StoredProcedureName { get; set; } = "";
        public string Operation { get; set; } = "select";  // اسم العملية في الـ SP
        public int PageSize { get; set; } = 10;
        public List<int> PageSizes { get; set; } = new() { 10, 25, 50, 100 };

        public bool ShowHeader { get; set; } = true;
        public bool ShowFooter { get; set; } = true;

        public bool Searchable { get; set; } = false;      // فلترة سريعة
        public string? SearchPlaceholder { get; set; } = "بحث…";
        public List<string>? QuickSearchFields { get; set; } // أعمدة البحث السريع

        public bool AllowExport { get; set; } = false;     // Excel/CSV
        public bool AutoRefreshOnSubmit { get; set; } = true;

        public List<TableColumn> Columns { get; set; } = new();
        public List<TableAction> RowActions { get; set; } = new();

        public bool Selectable { get; set; } = false;      // تمكين اختيار متعدد
        public string? RowIdField { get; set; } = "Id";    // الحقل الأساسي للصف
        public string? GroupBy { get; set; }               // تجميع حسب عمود
        public string? StorageKey { get; set; }            // لحفظ حالة المستخدم (حجم الصفحة/الأعمدة/الفرز)

        public TableToolbarConfig Toolbar { get; set; } = new();
    }
}