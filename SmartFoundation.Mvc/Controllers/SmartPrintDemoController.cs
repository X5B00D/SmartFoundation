using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartPrint;
using SmartFoundation.UI.ViewModels.SmartPage;

namespace SmartFoundation.Mvc.Controllers
{
    public class SmartPrintDemoController : Controller
    {
        public IActionResult Index()
        {
            // تقرير بجدول منتجات
            var doc = new SmartPrintDocument
            {
                Title = "تقرير المنتجات",
                SubTitle = "عرض قائمة المنتجات مع الأسعار",
                Page = new PageOptions
                {
                    Size = "A4",
                    Orientation = "portrait",
                    Direction = "rtl",
                    Theme = "zebra",
                    Culture = "ar-SA"
                },
                Headers = new List<HeaderSlot>
                {
                    new HeaderSlot
                    {
                        Slot = "default",
                        HeightCm = 2,
                        Blocks = new List<PrintBlock>
                        {
                            new TextBlock { Type="text", Text = "المتجر الذكي", Css="text-xl font-bold text-center" },
                            new DividerBlock { Type="divider" }
                        }
                    }
                },
                Footers = new List<FooterSlot>
                {
                    new FooterSlot
                    {
                        Slot = "default",
                        HeightCm = 1.5,
                        Blocks = new List<PrintBlock>
                        {
                            new TextBlock { Type="text", Text = "صفحة {page} من {total}", Css="text-sm text-gray-500 text-center" }
                        }
                    }
                },
                Blocks = new List<PrintBlock>
                {
                    new TableBlock
                    {
                        Type = "table",
                        Dataset = "Products",
                        Columns = new List<TableColumn>
                        {
                            new TableColumn { Field = "Name", Header = "المنتج", Align = "start" },
                            new TableColumn { Field = "Category", Header = "التصنيف", Align = "center" },
                            new TableColumn { Field = "Price", Header = "السعر", Align = "end", Format="n2" },
                            new TableColumn { Field = "Stock", Header = "المخزون", Align = "center" }
                        }
                    }
                }
            };

            // البيانات
            doc.Datasets["Products"] = new List<Dictionary<string, object?>>
            {
                new() { ["Name"] = "حاسوب محمول", ["Category"] = "إلكترونيات", ["Price"] = 3500, ["Stock"] = 12 },
                new() { ["Name"] = "هاتف ذكي", ["Category"] = "إلكترونيات", ["Price"] = 2500, ["Stock"] = 30 },
                new() { ["Name"] = "طابعة ليزر", ["Category"] = "أجهزة مكتبية", ["Price"] = 1200, ["Stock"] = 7 },
                new() { ["Name"] = "مكتب خشبي", ["Category"] = "أثاث", ["Price"] = 800, ["Stock"] = 5 },
            };

            var vm = new SmartPageViewModel
            {
                PageTitle = "تقرير المنتجات",
                PanelTitle = "عرض قائمة المنتجات",
                PrintDoc = doc
            };

            return View(vm);
        }
    }
}
