using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.UI.ViewModels.SmartTable;


namespace SmartFoundation.Mvc.Controllers
{
    [Route("[controller]")]
    public class AllComponentsDemoController : Controller
    {
        [HttpGet("")]
        [HttpGet("Index")]
        public IActionResult Index()

        {
            var form = new FormConfig
            {
                FormId = "dynamicForm",
                Title = "نموذج الإدخال",
                Method = "POST",
                ActionUrl = "/AllComponentsDemo/ExecuteDemo",
                SubmitText = "حفظ",
                ResetText = "تفريغ",
                ShowPanel = true,
                ShowReset = true,
                StoredProcedureName = "sp_SaveDemoForm",
                Operation = "insert",
                StoredSuccessMessageField = "Message",
                StoredErrorMessageField = "Error",

                Fields = new List<FieldConfig>
                {
                    // ========= البيانات الشخصية =========
                    new FieldConfig
                    {

                        SectionTitle="البيانات",
                        Name="FullName",
                        Label="إدخال نص",
                        Type="text",
                        Required=true,
                        Placeholder="حقل عربي فقط",
                        Icon="fa-solid fa-user",
                        ColCss="col-span-12 md:col-span-3",
                        MaxLength=50,
                        TextMode="arsentence",
                    },
                    new FieldConfig
                    {
                        
                        Name="Email",
                        Label = "البريد الإلكتروني",
                        Type = "text",
                        Required = true,
                        Placeholder = "example@example.com",
                        Icon = "fa-solid fa-envelope",
                        ColCss = "col-span-12 md:col-span-3",
                        MaxLength = 100,
                        TextMode = "email",
                        Autocomplete = "email",
                        Autocapitalize = "none",
                        Autocorrect = "on",
                        Spellcheck = true,
                        HelpText="أدخل بريد إلكتروني صحيح"
                    },

                    
                    new FieldConfig
                    {
                        Name="Email",
                        Label="كلمة المرور",
                        Type="password",
                        Required=true,
                        Icon="fa-solid fa-lock",
                        MaxLength=20,
                        ColCss="col-span-12 md:col-span-3",
                        Autocomplete="new-password",
                        Placeholder="اكتب كلمة المرور",
                        HelpText="الحد الأدنى 6 خانات"
                    },
                    new FieldConfig
                    {
                        Name="Age",
                        Label="عداد رقمي",
                        Type="number",
                        Min=1,
                        Max=120,
                        InputLang="number",
                        Icon="fa-solid fa-calculator",
                        MaxLength=3,
                        ColCss="col-span-12 md:col-span-3",
                    },
                    new FieldConfig
                    {
                        Name="NationalId",
                        Label="رقم الهوية",
                        Type="text",
                        Required=true,
                        Placeholder="1234567890",
                        InputLang="number",
                        InputPattern=@"^[0-9]{10}$",
                        Icon="fa-solid fa-id-card",
                        ColCss="col-span-12 md:col-span-3",
                        IsNumericOnly=true,
                        MaxLength=10,
                        HelpText="10 أرقام فقط",
                        Autocomplete="off",
                    },

                    // ========= الاتصال والحساب =========
                    new FieldConfig
                    {
                        Name="User",
                        Label="رقم الجوال",
                        Type="phone",
                        Required=true,
                        Placeholder="05xxxxxxxx",
                        Icon="fa-solid fa-phone",
                        IsNumericOnly=true,
                        MaxLength=10,
                        ColCss="col-span-12 md:col-span-3",
                        Autocomplete="off",
                        HelpText="أدخل رقم جوال يبدأ بـ 05"
                    },
                    new FieldConfig
                    {
                        Name="IBAN",
                        Label="الحساب البنكي (IBAN)",
                        Type="iban",
                        Required=true,
                        Placeholder="SAxxxxxxxxxxxxxxxxxxxx",
                        Icon="fa-solid fa-money-bill-transfer",
                        IsIban=true,
                        MaxLength=20,
                        ColCss="3",
                        HelpText="يجب أن يبدأ بـ SA"
                    },

                    // ========= الموقع =========
                    new FieldConfig
                    {
                        Name="Country",
                        Label="الدولة",
                        Type="select",
                        Required=true,
                        Options=new List<OptionItem>
                        {
                            new OptionItem { Value="SA", Text="السعودية" },
                            new OptionItem { Value="EG", Text="مصر" },
                            new OptionItem { Value="JO", Text="الأردن" }
                        },
                        ColCss="col-span-12 md:col-span-3",
                    },
                    new FieldConfig
                    {
                        Name="City",
                        Label="المدينة",
                        Type="select",
                        Required=true,
                        DependsOn="Country",
                        DependsUrl="/api/location/cities",
                        ColCss="col-span-12 md:col-span-3",
                    },
                    new FieldConfig
                    {
                        Name="District",
                        Label="الحي",
                        Type="text",
                        ColCss="col-span-12 md:col-span-3",
                        MaxLength=50,
                        Placeholder="اسم الحي",
                        HelpText="أدخل اسم الحي فقط",
                        Icon="fa-solid fa-city"
                    },
                    new FieldConfig
                    {
                        Name="readonlyField",
                        Label="للقراءة فقط",
                        Type="text",
                        Readonly=true,
                        Placeholder="حقل للقراءة فقط",
                        ColCss="col-span-12 md:col-span-3",
                        Value="نص ثابت",
                        HelpText="هذا الحقل للعرض فقط",
                        Icon="fa-solid fa-eye"
                    },
                    new FieldConfig
                    {
                        Name="Address",
                        Label="العنوان الكامل",
                        Type="text",
                        MaxLength=200,
                        Placeholder="اكتب عنوانك بالتفصيل",
                        Icon="fa-solid fa-location-dot",
                        ColCss="col-span-12 md:col-span-3",
                        HelpText="الرجاء إدخال العنوان الكامل",
                    },

                    // ========= التواريخ =========
                    new FieldConfig
                    {
                        Name="BirthDate",
                        Label="تاريخ ميلادي",
                        Type="date",
                        Placeholder="YYYY-MM-DD",
                        Icon="fa-regular fa-calendar",
                        Calendar="both",
                        DateInputCalendar="gregorian",
                        MirrorName="BirthDateHijri",
                        MirrorCalendar="hijri",
                        DateDisplayLang="ar",
                        DateNumerals="latn",
                        ShowDayName=true,
                        DefaultToday=false,
                        MinDateStr="1950-01-01",
                        MaxDateStr="2025-12-31",
                        DisplayFormat="yyyy-mm-dd",
                        ColCss="col-span-12 md:col-span-3",
                        HelpText="اختر تاريخ ميلاد صحيح"
                    },
                    new FieldConfig
                    {
                        Name="Vacation",
                        Label="الإجازة (من - إلى)",
                        Type="date-range",
                        Calendar="both",
                        DateInputCalendar="gregorian",
                        MirrorName="VacationHijri",
                        MirrorCalendar="hijri",
                        DateDisplayLang="ar",
                        DateNumerals="latn",
                        ShowDayName=true,
                        MinDateStr="1990-01-01",
                        MaxDateStr="2025-12-31",
                        DisplayFormat="yyyy-mm-dd",
                        HelpText="سيتم حساب عدد الأيام تلقائيًا",
                        Icon="fa-regular fa-calendar-days",
                        ColCss="col-span-12 md:col-span-6",
                    },

                    // ========= الملاحظات =========
                    new FieldConfig
                    {

                        SectionTitle="ملاحظات",
                        Name="Bio",
                        Label="ملاحظات",
                        Type="textarea",
                        MaxLength=500,
                        Placeholder="يسمح بكتابة 500 حرف",
                        Icon="fa-solid fa-file-lines",
                        ColCss="col-span-12 md:col-span-5",
                        Spellcheck=true,
                        Autocapitalize="sentences",
                        HelpText="يمكنك إدخال وصف مختصر هنا"
                    },

                    // ========= جدول للتجربة =========
                    
new FieldConfig
{
    SectionTitle = "جدول بيانات",
    Name = "DemoTable",
    Type = "datatable",
    ColCss = "col-span-12",
    Table = new TableConfig
    {
        Endpoint = "/AllComponentsDemo/ExecuteDemo",
        StoredProcedureName = "sp_GetDemoData",
        Operation = "select",
        PageSize = 6,
        PageSizes = new List<int> { 5, 10, 25, 50, 100 },
        ShowHeader = true,
        ShowFooter = true,
        Searchable = true,
        SearchPlaceholder = "اكتب للبحث...",
        QuickSearchFields = new List<string> { "FullName", "Email" },
        AllowExport = false,
        AutoRefreshOnSubmit = true,
        Selectable = true,
        RowIdField = "Id",
        GroupBy = null,
        StorageKey = "demo_table_storage",

        Columns = new List<TableColumn>
        {
            new TableColumn { Field="Id", Label="رقم", Sortable=true, Visible=true, Width="80px", Align="center", Type="number", ShowInModal=true },
            new TableColumn { Field="FullName", Label="الاسم الكامل", Sortable=true, Align="right", Type="text", ShowInModal=true },
            new TableColumn { Field="Email", Label="البريد الإلكتروني", Sortable=true, Align="left", Type="text", ShowInModal=true },
            new TableColumn { Field="CreatedAt", Label="تاريخ الإدخال", Sortable=true, Type="datetime", FormatString="yyyy-MM-dd HH:mm", ShowInModal=true },
            new TableColumn { Field="Status", Label="الحالة", Sortable=false, Type="badge", Badge=new TableBadgeConfig {
                Map = new Dictionary<string,string> {
                    { "نشط", "bg-green-100 text-green-800" },
                    { "موقوف", "bg-red-100 text-red-800" }
                },
                DefaultClass = "bg-gray-100 text-gray-600"
            }, ShowInModal=true }
        },

        //RowActions = new List<TableAction>
        //{
        //    new TableAction
        //    {
        //        Label="حذف",
        //        Icon="fa fa-trash",
        //        Color="danger",
        //        Show=true,
        //        ConfirmText="هل أنت متأكد من حذف هذا السجل؟",
        //        OnClickJs="alert('تنفيذ حذف للسجل رقم: ' + row.Id)"
        //    },
        //    new TableAction
        //    {
        //        Label="تنبيه",
        //        Icon="fa fa-bell",
        //        Color="warning",
        //        Show=true,
        //        OnClickJs="alert('تم الضغط على تنبيه للسجل: ' + row.Id)"
        //    }
        //},

        Toolbar = new TableToolbarConfig
        {
            ShowAdd = true,
            ShowEdit = false,
            ShowRefresh = false,
            ShowColumns = true,
            ShowExportCsv = false,
            ShowExportExcel = false,
            ShowAdvancedFilter = true,
            ShowBulkDelete = true,

            // زر الإضافة
            Add = new TableAction
            {
                Label = "إضافة",
                Icon = "fa fa-plus",
                Color = "success",
                Show = true,
                OpenModal = true,
                ModalTitle = "إضافة سجل جديد",
                ModalSp = "sp_AddDemoData",
                ModalOp = "insert",
                SaveSp = "sp_AddDemoData",
                SaveOp = "insert",
                ModalColumns = new List<TableColumn>
                {
                    new TableColumn { Field="FullName", Label="الاسم الكامل" },
                    new TableColumn { Field="Email", Label="البريد الإلكتروني" },
                    new TableColumn { Field="Phone", Label="الهاتف" }
                }
            },

            // زر التعديل
            Edit = new TableAction
            {
                Label = "تعديل",
                Icon = "fa fa-edit",
                Color = "info",
                Show = false,
                OpenModal = true,
                IsEdit = true,  // ✅ يحدد أنه زر تعديل
                ModalTitle = "تعديل بيانات المستخدم",
                ModalSp = "sp_GetUserDetail",   // SP لجلب البيانات للتعديل
                ModalOp = "detail",
                SaveSp = "sp_UpdateUser",       // SP لحفظ التعديلات
                SaveOp = "update",
                ModalColumns = new List<TableColumn>
                {
                    new TableColumn { Field="Id", Label="رقم", Visible=false }, // رقم معرف فقط
                    new TableColumn { Field="FullName", Label="الاسم الكامل" },
                    new TableColumn { Field="Email", Label="البريد الإلكتروني" },
                    new TableColumn { Field="Phone", Label="الهاتف" },
                    new TableColumn { Field="Address", Label="العنوان" }
                }
            }
        }
    }
},
                    // ========= إقرار =========
                    new FieldConfig
                    {
                        SectionTitle="إقرار",
                        Name="AgreeTerms",
                        Label="أوافق على الشروط والأحكام",
                        Type="checkbox",
                        Required=true,
                        Icon="fa-solid fa-check",
                        ColCss="col-span-12 md:col-span-3"
                    },

                    // ========= حقل مخفي =========
                    new FieldConfig
                    {
                        Name="HiddenToken",
                        Type="hidden",
                        Value="xyz-123",
                        IsHidden=true
                    }
                },

                Buttons = new List<FormButtonConfig>
                {
                    new FormButtonConfig
                    {
                        Text="طباعة",
                        Icon="fa-solid fa-print",
                        Type="button",
                        Color="danger",
                        OnClickJs="window.print();"
                    },


                    new FormButtonConfig
                    {
                        Text="رجوع",
                        Icon="fa-solid fa-arrow-left",
                        Type="button",
                        Color="info",
                        OnClickJs="history.back();"
                    },

                }
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "جميع المكونات",
                PanelTitle = "عرض ",
                SpName = "sp_SaveDemoForm",
                Operation = "insert",
                Form = form
            };

            return View(vm);
        }

        [HttpPost("Submit")]
        public IActionResult Submit()
        {
            TempData["Success"] = "تم تنفيذ العملية بنجاح!";
            return RedirectToAction("Index");
        }

        [HttpPost("ExecuteDemo")]
        public IActionResult ExecuteDemo([FromBody] SmartRequest req)
        {
            
            if (req.SpName == "sp_GetDemoData")
            {
                // تحديد عدد السجلات المطلوبة حسب الصفحة المطلوبة
                int pageSize = req.Paging?.Size ?? 10;
                int pageNumber = req.Paging?.Page ?? 1;
                int totalItems = 25; 
                
                // حساب السجلات المطلوبة للصفحة الحالية
                int startIndex = (pageNumber - 1) * pageSize;
                int endIndex = Math.Min(startIndex + pageSize, totalItems);
                int itemsToReturn = Math.Max(0, endIndex - startIndex);
                
                // إنشاء بيانات تجريبية
                var rows = Enumerable.Range(startIndex + 1, itemsToReturn).Select(i => new Dictionary<string, object?>
                {
                    ["Id"] = i,
                    ["FullName"] = $"مستخدم {i}",
                    ["Email"] = $"user{i}@example.com",
                    ["CreatedAt"] = DateTime.Now.AddDays(-i).ToString("yyyy-MM-dd")
                }).ToList();

                // فلترة حسب البحث إذا وجد
                if (req.Filters?.Count > 0)
                {
                   
                    var searchFilter = req.Filters.FirstOrDefault(f => f.Field == "q" || f.Field == "search");
                    if (searchFilter != null && searchFilter.Value != null)
                    {
                        string searchTerm = searchFilter.Value.ToString()?.ToLower() ?? "";
                        if (!string.IsNullOrWhiteSpace(searchTerm))
                        {
                            rows = rows.Where(r => 
                                r["FullName"]?.ToString()?.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) == true ||
                                r["Email"]?.ToString()?.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) == true
                            ).ToList();
                        }
                    }
                }

               
                if (req.Sort != null && !string.IsNullOrEmpty(req.Sort.Field))
                {
                   
                    bool isDesc = req.Sort.Dir?.ToLower() == "desc";
                    
                    if (req.Sort.Field == "Id")
                    {
                        rows = isDesc 
                            ? rows.OrderByDescending(r => Convert.ToInt32(r["Id"])).ToList() 
                            : rows.OrderBy(r => Convert.ToInt32(r["Id"])).ToList();
                    }
                    else if (req.Sort.Field == "FullName")
                    {
                        rows = isDesc
                            ? rows.OrderByDescending(r => r["FullName"]?.ToString()).ToList()
                            : rows.OrderBy(r => r["FullName"]?.ToString()).ToList();
                    }
                    else if (req.Sort.Field == "Email")
                    {
                        rows = isDesc
                            ? rows.OrderByDescending(r => r["Email"]?.ToString()).ToList()
                            : rows.OrderBy(r => r["Email"]?.ToString()).ToList();
                    }
                    else if (req.Sort.Field == "CreatedAt")
                    {
                        rows = isDesc
                            ? rows.OrderByDescending(r => r["CreatedAt"]?.ToString()).ToList()
                            : rows.OrderBy(r => r["CreatedAt"]?.ToString()).ToList();
                    }
                }

                return Ok(new SmartResponse
                {
                    Success = true,
                    Data = rows,
                    Total = totalItems,
                    Page = pageNumber,
                    Size = pageSize
                });
            }

            // أي طلب آخر
            return Ok(new SmartResponse
            {
                Success = false,
                Error = $"SP غير معروف: {req.SpName}"
            });
        }
    }
}
