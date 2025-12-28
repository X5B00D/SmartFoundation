using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartCharts;
using SmartFoundation.UI.ViewModels.SmartPage;
using System.Data;

namespace SmartFoundation.Mvc.Controllers
{
    public class RealChartsController : Controller
    {
        private readonly SmartFoundation.Application.Services.MastersServies _mastersServies;

        public RealChartsController(SmartFoundation.Application.Services.MastersServies mastersServies)
        {
            _mastersServies = mastersServies;
        }

        [HttpGet]
        public async Task<IActionResult> Demo()
        {
            var pageName = "RealChartsDemo";

            // TODO: اربطها بالسشن بعدين
            var idaraId = 1;
            var userId = 1;
            var hostName = HttpContext?.Request?.Host.Value ?? "localhost";

            var spParameters = new object?[]
            {
                pageName,   // pageName_
                idaraId,    // idaraID
                userId,     // entrydata
                hostName    // hostname
            };

            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

            // ✅ نختار جدول البيانات الحقيقي:
            // غالبًا Table1 = data ، لكن لو ما موجودة نرجع لـ Table0
            var dt = (ds != null && ds.Tables.Count > 1) ? ds.Tables[1]
                   : (ds != null && ds.Tables.Count > 0) ? ds.Tables[0]
                   : null;

            var slices = new List<Pie3DSlice>();

            if (dt != null)
            {
                // ✅ أسماء الأعمدة عندك في الداتا بيس (حسب الصورة):
                // SegmentKey, SegmentLabel_A, SegmentValue, SegmentHref, SegmentHint
                bool hasSegmentCols =
                    dt.Columns.Contains("SegmentKey") ||
                    dt.Columns.Contains("SegmentLabel_A") ||
                    dt.Columns.Contains("SegmentValue") ||
                    dt.Columns.Contains("SegmentHref") ||
                    dt.Columns.Contains("SegmentHint");

                foreach (DataRow r in dt.Rows)
                {
                    // ✅ اقرأ أعمدتك الفعلية أولًا، وإن ما وجدت استخدم البدائل العامة (Key/Label/Value/Href/Hint)
                    string key =
                        hasSegmentCols
                            ? (dt.Columns.Contains("SegmentKey") ? (r["SegmentKey"]?.ToString() ?? "") : "")
                            : (dt.Columns.Contains("Key") ? (r["Key"]?.ToString() ?? "") : "");

                    string label =
                        hasSegmentCols
                            ? (dt.Columns.Contains("SegmentLabel_A") ? (r["SegmentLabel_A"]?.ToString() ?? "") : "")
                            : (dt.Columns.Contains("Label") ? (r["Label"]?.ToString() ?? "") : "");

                    decimal value =
                        hasSegmentCols
                            ? (dt.Columns.Contains("SegmentValue") ? Convert.ToDecimal(r["SegmentValue"] ?? 0) : 0m)
                            : (dt.Columns.Contains("Value") ? Convert.ToDecimal(r["Value"] ?? 0) : 0m);

                    string? href =
                        hasSegmentCols
                            ? (dt.Columns.Contains("SegmentHref") ? (r["SegmentHref"]?.ToString()) : null)
                            : (dt.Columns.Contains("Href") ? (r["Href"]?.ToString()) : null);

                    string? hint =
                        hasSegmentCols
                            ? (dt.Columns.Contains("SegmentHint") ? (r["SegmentHint"]?.ToString()) : null)
                            : (dt.Columns.Contains("Hint") ? (r["Hint"]?.ToString()) : null);

                    // ✅ نظّف فراغات
                    key = key?.Trim() ?? "";
                    label = label?.Trim() ?? "";
                    href = string.IsNullOrWhiteSpace(href) ? null : href.Trim();
                    hint = string.IsNullOrWhiteSpace(hint) ? null : hint.Trim();

                    // ✅ تجاهل صفوف بدون Label
                    if (string.IsNullOrWhiteSpace(label))
                        continue;

                    slices.Add(new Pie3DSlice
                    {
                        Key = key,
                        Label = label,
                        Value = value,
                        Href = href,
                        Hint = hint
                    });
                }
            }

            var card = new ChartCardConfig
            {
                Type = ChartCardType.Pie3D,
                Title = "توزيع الوحدات حسب فئة المستفيد",
                Subtitle = "بيانات من قاعدة البيانات",
                Icon = "fa-solid fa-chart-pie",
                Tone = ChartTone.Info,
                ColCss = "6 md:6",
                Dir = "rtl",

                Pie3DSize = 320,
                Pie3DHeight = 22,
                Pie3DInnerHole = 0,
                Pie3DShowLegend = true,
                Pie3DShowCenterTotal = true,
                Pie3DValueFormat = "0",
                Pie3DExplodeOnHover = true,

                Pie3DSlices = slices
            };

            var charts = new SmartChartsConfig
            {
                Title = "بياناة الشارت من الداسا بيز حقيقية",
                Cards = new List<ChartCardConfig> { card }
            };

            var page = new SmartPageViewModel
            {
                PageTitle = "Real Charts",
                PanelTitle = "تجربة الشارتات",
                PanelIcon = "fa-chart-pie",
                Charts = charts
            };

            return View("~/Views/RealCharts/Demo.cshtml", page);
        }
    }
}
