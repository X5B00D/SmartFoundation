using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;

namespace SmartFoundation.Mvc.Controllers.Maintenance
{
    public partial class MaintenanceController : Controller
    {
        public async Task<IActionResult> MaintenanceDashboard()
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Maintenance);
            PageName = "MaintenanceDashboard";

            var spParameters = new object?[]
            {
                PageName,
                IdaraId,
                usersId,
                HostName
            };

            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);
            SplitDataSet(ds);

            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }

            DataTable? GetResultTable(int index)
            {
                return ds.Tables.Count > index ? ds.Tables[index] : null;
            }

            object? GetScalar(DataTable? table, string columnName)
            {
                if (table == null || table.Rows.Count == 0 || !table.Columns.Contains(columnName))
                    return 0;

                var value = table.Rows[0][columnName];
                return value == DBNull.Value ? 0 : value;
            }

            DataTable BuildIndicatorTable()
            {
                var table = new DataTable();
                table.Columns.Add("IndicatorName_A", typeof(string));
                table.Columns.Add("IndicatorValue", typeof(long));

                void AddIndicator(string name, DataTable? source, string columnName)
                {
                    var value = GetScalar(source, columnName);
                    table.Rows.Add(name, Convert.ToInt64(value ?? 0));
                }

                AddIndicator("الطلبات المفتوحة", GetResultTable(2), "OpenRequestsCount");
                AddIndicator("الطلبات المغلقة", GetResultTable(3), "ClosedRequestsCount");
                AddIndicator("الطلبات المتأخرة", GetResultTable(4), "LateRequestsCount");
                AddIndicator("النزاعات المفتوحة", GetResultTable(10), "OpenDisputesCount");
                AddIndicator("طلبات الموافقة المنتظرة", GetResultTable(11), "WaitingApprovalRequestsCount");
                AddIndicator("الطلبات الفرعية المفتوحة", GetResultTable(12), "OpenSubRequestsCount");

                return table;
            }

            SmartTableDsModel BuildDashboardTable(DataTable? table, string title)
            {
                var rowsList = new List<Dictionary<string, object?>>();
                var dynamicColumns = new List<TableColumn>();
                string rowIdField = table?.Columns.Count > 0 ? table.Columns[0].ColumnName : "ID";

                if (table != null)
                {
                    foreach (DataColumn c in table.Columns)
                    {
                        string colType = "text";
                        var t = c.DataType;
                        if (t == typeof(bool)) colType = "bool";
                        else if (t == typeof(DateTime)) colType = "date";
                        else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                 || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                            colType = "number";

                        dynamicColumns.Add(new TableColumn
                        {
                            Field = c.ColumnName,
                            Label = c.ColumnName,
                            Type = colType,
                            Sortable = true,
                            Visible = true
                        });
                    }

                    foreach (DataRow r in table.Rows)
                    {
                        var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                        foreach (DataColumn c in table.Columns)
                        {
                            var val = r[c];
                            dict[c.ColumnName] = val == DBNull.Value ? null : val;
                        }

                        rowsList.Add(dict);
                    }
                }

                return new SmartTableDsModel
                {
                    PageTitle = title,
                    Columns = dynamicColumns,
                    Rows = rowsList,
                    RowIdField = rowIdField,
                    PageSize = 10,
                    PageSizes = new List<int> { 10, 25, 50, 100 },
                    Searchable = true,
                    AllowExport = true,
                    PanelTitle = title,
                    Toolbar = new TableToolbarConfig
                    {
                        ShowRefresh = false,
                        ShowColumns = true,
                        ShowExportCsv = false,
                        ShowExportExcel = false,
                        ShowAdd = false,
                        ShowEdit = false,
                        ShowDelete = false,
                        ShowBulkDelete = false,
                        ShowExportPdf = false,
                        ShowPrint = false,
                        ShowPrint1 = false
                    }
                };
            }

            var page = new SmartPageViewModel
            {
                PageTitle = "لوحة مؤشرات الصيانة",
                PanelTitle = "لوحة مؤشرات الصيانة",
                PanelIcon = "fa-chart-line",
                TableDS = BuildDashboardTable(GetResultTable(1), "إجمالي الطلبات حسب الحالة"),
                TableDS1 = BuildDashboardTable(BuildIndicatorTable(), "المؤشرات العامة"),
                TableDS2 = BuildDashboardTable(GetResultTable(5), "الطلبات حسب نوع الصيانة"),
                TableDS3 = BuildDashboardTable(GetResultTable(6), "الطلبات حسب الجهة"),
                TableDS4 = BuildDashboardTable(GetResultTable(7), "الطلبات حسب الأولوية"),
                TableDS5 = BuildDashboardTable(GetResultTable(8), "آخر 20 طلب صيانة")
            };

            return View("MaintenanceDashboard", page);
        }
    }
}
