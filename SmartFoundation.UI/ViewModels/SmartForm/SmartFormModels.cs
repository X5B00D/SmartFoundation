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

    // ===== Enhanced DataTable Models =====

    // خاص بالجدول - تحديد خريطة ألوان للشارات
    public class TableBadgeConfig
    {
        public Dictionary<string, string> Map { get; set; } = new(); // قيمة => CSS Classes
        public string DefaultClass { get; set; } = "bg-gray-100 text-gray-700";
    }

    // تكوين الفلاتر للأعمدة
    public class TableColumnFilter
    {
        public string Type { get; set; } = "text"; // text | select | date | number | range
        public List<OptionItem> Options { get; set; } = new(); // للـ select
        public string? Placeholder { get; set; }
        public bool Enabled { get; set; } = true;
        public string? DefaultValue { get; set; }
    }

    // تكوين التجميع
    public class TableGroupConfig
    {
        public string Field { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public bool Expanded { get; set; } = true;
        public bool ShowCount { get; set; } = true;
        public List<string> AggregateFields { get; set; } = new(); // الحقول المراد جمعها
        public Dictionary<string, string> AggregateTypes { get; set; } = new(); // Field => sum|avg|count|min|max
    }

    // إعدادات التصدير
    public class TableExportConfig
    {
        public bool EnableExcel { get; set; } = true;
        public bool EnableCsv { get; set; } = true;
        public bool EnablePdf { get; set; } = false;
        public bool EnablePrint { get; set; } = true;
        public string? ExcelTemplate { get; set; }
        public string? PdfTemplate { get; set; }
        public List<string> ExcludeColumns { get; set; } = new();
        public string? Filename { get; set; }
    }

    // Enhanced TableColumn
    public class TableColumn
    {
        public string Field { get; set; } = string.Empty; // اسم العمود من الـ SP
        public string Label { get; set; } = string.Empty; // التسمية بالعربي/الانجليزي
        public bool Sortable { get; set; } = true;        // يدعم الفرز
        public bool Visible { get; set; } = true;         // إخفاء/إظهار
        public bool Resizable { get; set; } = true;       // قابل لتغيير الحجم
        public bool Reorderable { get; set; } = true;     // قابل لإعادة الترتيب
        public string? Width { get; set; }                // CSS عرض العمود
        public string? MinWidth { get; set; } = "80px";   // أقل عرض
        public string? MaxWidth { get; set; }             // أقصى عرض
        public string? Align { get; set; } = "right";     // left | right | center
        public string? Type { get; set; } = "text";       // text | number | date | badge | bool | money | datetime | image | link
        public string? FormatString { get; set; }         // "{0:dd/MM/yyyy}"
        public string? FormatterJs { get; set; }          // JS function(row,col,table) => html/text
        public bool ShowInModal { get; set; } = true;     // تخصيص ظهور العمود في المودال
        public bool ShowInExport { get; set; } = true;    // تخصيص ظهور العمود في التصدير
        public bool Frozen { get; set; } = false;         // تثبيت العمود
        public string? FrozenSide { get; set; } = "left"; // left | right
        public TableBadgeConfig? Badge { get; set; }      // خريطة ألوان/كلاسات للشارات
        public TableColumnFilter? Filter { get; set; }   // إعدادات الفلترة للعمود
        public bool Aggregatable { get; set; } = false;  // قابل للتجميع/الحساب
        public string? AggregateType { get; set; }        // sum | avg | count | min | max
        public string? LinkTemplate { get; set; }         // للنوع link: "/view/{id}"
        public string? ImageTemplate { get; set; }        // للنوع image: "data:image/png;base64,{data}"
        public Dictionary<string, object> CustomProperties { get; set; } = new(); // خصائص إضافية
    }

    // Enhanced TableAction
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
        
        // إضافات جديدة
        public bool RequireSelection { get; set; } = false; // يتطلب تحديد صف واحد أو أكثر
        public int MinSelection { get; set; } = 0;          // أقل عدد من الصفوف المطلوبة
        public int MaxSelection { get; set; } = 0;          // أقصى عدد من الصفوف المسموحة (0 = لا حد)
        public string? Tooltip { get; set; }                // نص المساعدة
        public string? KeyboardShortcut { get; set; }       // اختصار لوحة المفاتيح
        public List<string> Roles { get; set; } = new();    // الأدوار المسموحة
        public string? Condition { get; set; }              // شرط JavaScript لإظهار الزر
    }

    // Enhanced TableToolbarConfig
    public class TableToolbarConfig
    {
        public bool ShowAdd { get; set; } = false;
        public bool ShowRefresh { get; set; } = true;
        public bool ShowColumns { get; set; } = true;
        public bool ShowExportCsv { get; set; } = true;
        public bool ShowExportExcel { get; set; } = true;
        public bool ShowExportPdf { get; set; } = false;
        public bool ShowPrint { get; set; } = true;
        public bool ShowAdvancedFilter { get; set; } = false;
        public bool ShowBulkDelete { get; set; } = false;
        public bool ShowFullscreen { get; set; } = true;
        public bool ShowDensityToggle { get; set; } = true; // كثافة العرض
        public bool ShowThemeToggle { get; set; } = false;  // تبديل الثيم

        // زر الإضافة كمثال (بإمكانك لاحقًا تعمل Config لكل زر على حدة)
        public TableAction? Add { get; set; }

        public bool ShowEdit { get; set; } = false;
        public TableAction? Edit { get; set; }
        
        // إضافات جديدة
        public List<TableAction> CustomActions { get; set; } = new(); // أزرار مخصصة
        public TableExportConfig ExportConfig { get; set; } = new();
        public bool ShowSearch { get; set; } = true;
        public string? SearchPosition { get; set; } = "left"; // left | right | center
    }

    // Enhanced TableConfig
    public class TableConfig
    {
        public string? Endpoint { get; set; }
        public string StoredProcedureName { get; set; } = "";
        public string Operation { get; set; } = "select";  // اسم العملية في الـ SP
        public int PageSize { get; set; } = 10;
        public List<int> PageSizes { get; set; } = new() { 10, 25, 50, 100 };
        public int MaxPageSize { get; set; } = 1000;       // أقصى حجم صفحة مسموح

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
        
        // إضافات جديدة للميزات المتقدمة
        public bool ClientSideMode { get; set; } = false;  // تحميل كل البيانات في المتصفح
        public bool VirtualScrolling { get; set; } = false; // التمرير الافتراضي للبيانات الكبيرة
        public bool ResponsiveMode { get; set; } = true;   // التصميم المتجاوب
        public string? ResponsiveBreakpoint { get; set; } = "md"; // sm | md | lg | xl
        public bool ShowRowNumbers { get; set; } = false;  // إظهار أرقام الصفوف
        public bool ShowRowBorders { get; set; } = true;   // إظهار حدود الصفوف
        public bool HoverHighlight { get; set; } = true;   // إبراز الصف عند التمرير
        public bool StripedRows { get; set; } = false;     // صفوف متناوبة الألوان
        public string? Density { get; set; } = "normal";   // compact | normal | comfortable
        public string? Theme { get; set; } = "light";      // light | dark | auto
        public bool InlineEditing { get; set; } = false;   // التحرير المباشر
        public bool AutoSave { get; set; } = false;        // الحفظ التلقائي
        public int AutoSaveDelay { get; set; } = 2000;     // تأخير الحفظ التلقائي بالميلي ثانية
        public TableGroupConfig? GroupConfig { get; set; } // إعدادات التجميع
        public bool EnableKeyboardNavigation { get; set; } = true; // التنقل بلوحة المفاتيح
        public bool EnableContextMenu { get; set; } = false; // قائمة سياقية بالنقر الأيمن
        public Dictionary<string, object> CustomSettings { get; set; } = new(); // إعدادات مخصصة
        
        // إعدادات الأداء
        public bool LazyLoading { get; set; } = false;     // التحميل الكسول
        public int CacheTimeout { get; set; } = 300;       // مهلة انتهاء الكاش بالثواني
        public bool DebounceSearch { get; set; } = true;   // تأخير البحث
        public int SearchDebounceDelay { get; set; } = 500; // تأخير البحث بالميلي ثانية
        
        // إعدادات إمكانية الوصول
        public bool EnableScreenReader { get; set; } = true; // دعم قارئ الشاشة
        public string? AriaLabel { get; set; }              // تسمية الجدول للمكفوفين
        public bool HighContrast { get; set; } = false;    // التباين العالي
    }
}