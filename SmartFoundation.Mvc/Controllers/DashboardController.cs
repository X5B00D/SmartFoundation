using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartCharts;

namespace SmartFoundation.Mvc.Controllers
{
    public class DashboardController : Controller
    {
        public IActionResult Index()
        {
           
          

            var charts = new SmartChartsConfig
            {
                Title = "لوحة مؤشرات الإسكان والمباني والصيانة والساكنين ( شاشة تجريبية قيد التطوير لعرض المكونات )",
                Dir = "rtl",
                Cards = new List<ChartCardConfig>
                {
                    // ================== 1) الإسكان: توزيع أنواع الوحدات ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.Donut,
                        Title = "توزيع أنواع الوحدات",
                        Subtitle = "حسب نوع العقار",
                        Icon = "fa-solid fa-chart-pie",
                        Tone = ChartTone.Info,
                        ColCss = "3 md:6",
                        Dir = "rtl",

                        DonutMode = "donut",
                        DonutThickness = 0.30m,
                        DonutShowLegend = true,
                        DonutShowCenterText = true,
                        DonutValueFormat = "0",

                        Slices = new List<DonutSlice>
                        {
                            new DonutSlice { Label = "شقق سكنية", Value = 4200 },
                            new DonutSlice { Label = "فلل",       Value = 1800 },
                            new DonutSlice { Label = "أراضي",     Value = 950  },
                            new DonutSlice { Label = "تجاري",     Value = 400  },
                        }
                    },

                    // ================== 2) لوحة تشغيل: مؤشرات متعددة (Radial Rings) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.RadialRings,
                        Title = "مؤشرات التشغيل",
                        Subtitle = "إشغال • جاهزية • SLA • شواغر",
                        Icon = "fa-solid fa-circle-nodes",
                        Tone = ChartTone.Info,
                        ColCss = "4 md:6",
                        Dir = "rtl",

                        RadialRingSize = 280,
                        RadialRingThickness = 10,
                        RadialRingGap = 8,
                        RadialRingShowLegend = true,
                        RadialRingValueFormat = "0",

                        RadialRings = new List<RadialRingItem>
                        {
                            new RadialRingItem { Key="occupancy", Label="الإشغال",         Value=92,  Max=100, ValueText="92%", Href="/Residents/Occupancy" },
                            new RadialRingItem { Key="readiness", Label="جاهزية الوحدات",  Value=86,  Max=100, ValueText="86%", Href="/Housing/Readiness" },
                            new RadialRingItem { Key="sla",       Label="صيانة ضمن SLA",   Value=78,  Max=100, ValueText="78%", Href="/Maintenance/Sla" },
                            new RadialRingItem { Key="vacancy",   Label="الشواغر الجاهزة", Value=410, Max=800, ValueText="410", Href="/Housing/Vacant" },
                        }
                    },

                    // ================== 3) الأداء: Actual vs Target (Bullet) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.Bullet,
                        Title = "الأداء مقابل الأهداف",
                        Subtitle = "ملخص مؤشرات التشغيل الرئيسية",
                        Icon = "fa-solid fa-bullseye",
                        Tone = ChartTone.Info,
                        ColCss = "4 md:6",
                        Dir = "rtl",

                        BulletValueFormat = "0",
                        BulletShowLegend = false,

                        Bullets = new List<BulletItem>
                        {
                            new BulletItem { Key="sla_close",   Label="إغلاق البلاغات ضمن SLA", Actual=78, Target=90, Max=100, OkFrom=70, GoodFrom=90, Unit="%", Href="/Maintenance/Sla" },
                            new BulletItem { Key="occupancy",   Label="نسبة الإشغال",           Actual=92, Target=95, Max=100, OkFrom=85, GoodFrom=95, Unit="%", Href="/Residents/Occupancy" },
                            new BulletItem { Key="readiness",   Label="جاهزية الوحدات",         Actual=86, Target=90, Max=100, OkFrom=80, GoodFrom=90, Unit="%", Href="/Housing/Readiness" },
                            new BulletItem { Key="inspections", Label="إنجاز فحوصات المباني",   Actual=64, Target=80, Max=100, OkFrom=60, GoodFrom=80, Unit="%", Href="/Buildings/Inspections" },
                        }
                    },

                    // ================== 4) الصيانة: سير البلاغات (Funnel) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.Funnel,
                        Title = "سير بلاغات الصيانة",
                        Subtitle = "مراحل معالجة البلاغات",
                        Icon = "fa-solid fa-screwdriver-wrench",
                        Tone = ChartTone.Info,
                        ColCss = "6 md:6",
                        Dir = "rtl",

                        FunnelValueFormat = "0",
                        FunnelShowPercent = true,
                        FunnelShowDelta = true,
                        FunnelClickable = true,

                        FunnelStages = new List<FunnelStage>
                        {
                            new FunnelStage { Key="new",         Label="جديد",         Value=420, Href="/Maintenance?status=new" },
                            new FunnelStage { Key="assigned",    Label="تم الإسناد",   Value=310, Href="/Maintenance?status=assigned" },
                            new FunnelStage { Key="in_progress", Label="قيد التنفيذ",  Value=260, Href="/Maintenance?status=in_progress" },
                            new FunnelStage { Key="waiting",     Label="بانتظار قطع",  Value=95,  Href="/Maintenance?status=waiting" },
                            new FunnelStage { Key="closed",      Label="مغلق",         Value=180, Href="/Maintenance?status=closed" },
                        }
                    },

                    // ================== 5) الإسكان: حالة الوحدات (Occupancy Matrix) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.Occupancy,
                        Title = "حالة الوحدات السكنية",
                        Subtitle = "مأهولة • شاغرة • صيانة • محجوزة • غير صالحة",
                        Icon = "fa-solid fa-building-circle-check",
                        Tone = ChartTone.Info,
                        ColCss = "6 md:6",
                        Dir = "rtl",

                        OccupancyShowPercent = true,

                        OccupancyStatuses = new List<OccupancyStatus>
                        {
                            new OccupancyStatus { Key="occupied",    Label="مأهولة",      Units=8120, Color="#22c55e", Href="/Housing?status=occupied" },
                            new OccupancyStatus { Key="vacant",      Label="شاغرة",       Units=1240, Color="#0ea5e9", Href="/Housing?status=vacant" },
                            new OccupancyStatus { Key="maintenance", Label="تحت الصيانة", Units=430,  Color="#f59e0b", Href="/Housing?status=maintenance" },
                            new OccupancyStatus { Key="reserved",    Label="محجوزة",      Units=210,  Color="#8b5cf6", Href="/Housing?status=reserved" },
                            new OccupancyStatus { Key="inactive",    Label="غير صالحة",   Units=95,   Color="#ef4444", Href="/Housing?status=inactive" },
                        }
                    },

                    // ================== 6) الإسكان: اتجاه الطلب (Line) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.Line,
                        Title = "اتجاه طلبات الإسكان",
                        Subtitle = "آخر 12 شهر",
                        Icon = "fa-solid fa-chart-line",
                        Tone = ChartTone.Info,
                        ColCss = "6 md:6",
                        Dir = "rtl",

                        XLabels = new List<string>
                        {
                            "يناير","فبراير","مارس","أبريل","مايو","يونيو",
                            "يوليو","أغسطس","سبتمبر","أكتوبر","نوفمبر","ديسمبر"
                        },
                        LineSeries = new List<ChartSeries>
                        {
                            new ChartSeries
                            {
                                Name = "طلبات الإسكان",
                                Data = new List<decimal> { 120, 135, 128, 142, 160, 170, 168, 180, 175, 190, 205, 220 }
                            }
                        },
                        LineFillArea = true,
                        LineShowGrid = true,
                        LineShowDots = true,
                        LineValueFormat = "0",
                        LineMaxXTicks = 6
                    },

                    // ================== 7) الإسكان/الأصول: الوحدات حسب الحي (ColumnPro) ==================
                    new ChartCardConfig
                    {
                        Type = ChartCardType.ColumnPro,
                        Title = "الوحدات حسب الحي",
                        Subtitle = "مقارنة عدد الوحدات بين الأحياء",
                        Icon = "fa-solid fa-city",
                        Tone = ChartTone.Info,
                        ColCss = "6 md:6",
                        Dir = "rtl",

                        ColumnProLabels = new List<string>
                        {
                            "النرجس","الياسمين","الملقا","العارض","القيروان","حطين","الندى"
                        },
                        ColumnProSeries = new List<ChartSeries>
                        {
                            new ChartSeries { Name="الوحدات", Data = new List<decimal> { 1240, 980, 760, 540, 410, 390, 360 } }
                        },
                        ColumnProShowValues = true,
                        ColumnProValueFormat = "0",
                        ColumnProMinBarWidth = 56,
                        ColumnProHrefs = new List<string>
                        {
                            "/Housing?district=nargis",
                            "/Housing?district=yasmin",
                            "/Housing?district=malqa",
                            "/Housing?district=aredh",
                            "/Housing?district=qirawan",
                            "/Housing?district=hittin",
                            "/Housing?district=nada"
                        }
                    },

                    // ================== 8) الشريط السفلي: مؤشرات سريعة + توزيع غرف ==================
                    new ChartCardConfig
                        {
                            Type = ChartCardType.Gauge,
                            Title = "التزام الإسكان بزمن معالجة الطلبات",
                            Subtitle = "طلبات الإسكان خلال 48 ساعة",
                            Icon = "fa-solid fa-file-signature",
                            Tone = ChartTone.Info,
                            ColCss = "6 md:3",
                            Dir = "rtl",

                            // KPI الفعلي: نسبة الطلبات التي تم التعامل معها خلال المدة المستهدفة
                            GaugeLabel = "طلبات ضمن 48 ساعة",
                            GaugeMin = 0,
                            GaugeMax = 100,
                            GaugeValue = 87,          // مثال: 87% من الطلبات أُنجزت/عولجت خلال 48 ساعة
                            GaugeUnit = "%",

                            // حدود الأداء
                            GaugeWarnFrom = 80,       // أقل من 80% يعتبر مقلق
                            GaugeGoodFrom = 92,       // 92%+ ممتاز
                            GaugeValueText = "87%",
                            GaugeShowThresholds = true
                        },


                    new ChartCardConfig
                    {
                        Type = ChartCardType.Kpi,
                        Title = "إجمالي الساكنين",
                        Subtitle = "النشطون حالياً",
                        Icon = "fa-solid fa-users",
                        BigValue = "21K",
                        Note = "عدد الساكنين المسجلين بالنظام",
                        SecondaryLabel = "التغير الشهري",
                        SecondaryValue = "↑ 3.4%",
                        SecondaryIsPositive = true,
                        Tone = ChartTone.Success,
                        ColCss = "6 md:3",
                        Dir = "rtl"
                    },

                    new ChartCardConfig
                    {
                        Type = ChartCardType.BarHorizontal,
                        Title = "توزيع الوحدات حسب غرف النوم",
                        Subtitle = "ملخص سريع لطرازات الوحدات",
                        Icon = "fa-solid fa-bed",
                        Tone = ChartTone.Warning,
                        ColCss = "6 md:6",
                        Dir = "rtl",

                        Labels = new List<string>
                        {
                            "غرفة واحدة","غرفتان","٣ غرف","٤ غرف","٥ غرف","٦ غرف فأكثر"
                        },
                        Series = new List<ChartSeries>
                        {
                            new ChartSeries
                            {
                                Name = "عدد الوحدات",
                                Data = new List<decimal> { 274, 2760, 9824, 6882, 1601, 272 }
                            }
                        },
                        ShowValues = true,
                        ValueFormat = "0",
                        LabelMaxChars = 22
                    },

                    
                }
            };

            var page = new SmartPageViewModel
            {
                PageTitle = "لوحة التحكم",
                PanelIcon = "fa-solid fa-city",
                Charts = charts
            };

            return View("Index", page);
        }
    }
}
