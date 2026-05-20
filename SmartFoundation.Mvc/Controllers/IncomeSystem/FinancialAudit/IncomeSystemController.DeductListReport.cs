using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Mvc.Helpers;
using SmartFoundation.MVC.Reports;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartPrint;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Linq;
using System.Text.Json;
using static System.Collections.Specialized.BitVector32;



namespace SmartFoundation.Mvc.Controllers.IncomeSystem
{
    public partial class IncomeSystemController : Controller
    {
        public async Task<IActionResult> DeductListReport(int pdf = 0)
        {

            if (!InitPageContext(out IActionResult? redirectResult))
                return redirectResult!;

            if (string.IsNullOrWhiteSpace(usersId))
            {
                return RedirectToAction("Index", "Login", new { logout = 4 });
            }

            string? meterServiceTypeID_ = Request.Query["U"].FirstOrDefault();

            meterServiceTypeID_ = string.IsNullOrWhiteSpace(meterServiceTypeID_) ? null : meterServiceTypeID_.Trim();

            bool ready = false;

            ready = !string.IsNullOrWhiteSpace(meterServiceTypeID_);



            string? billPeriodID_ = Request.Query["P"].FirstOrDefault();

            billPeriodID_ = string.IsNullOrWhiteSpace(billPeriodID_) ? null : billPeriodID_.Trim();

            bool ready1 = false;

            ready1 = !string.IsNullOrWhiteSpace(billPeriodID_);



            // Sessions 

            ControllerName = nameof(IncomeSystem);
            PageName = nameof(DeductListReport);

            var spParameters = new object?[] { "DeductListReport", IdaraId, usersId, HostName, billPeriodID_, meterServiceTypeID_ };



            DataSet ds;


            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();


            ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);




            SplitDataSet(ds);

            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }






            string rowIdField = "";
            bool canPRINTDEDUCTLISTREPORT = false;
            



            List<OptionItem> meterServiceTypeOptions = new();
            List<OptionItem> billPeriodIDOptions = new();



          


            FormConfig form = new();


            try
            {

                // ---------------------- DDLValues ----------------------




                JsonResult? result;
                string json;




                //// ---------------------- BuildingUtilityType ----------------------
                result = await _CrudController.GetDDLValues(
                    "meterServiceTypeName_A", "meterServiceTypeID", "1", nameof(DeductListReport), usersId, IdaraId, HostName
               ) as JsonResult;


                json = JsonSerializer.Serialize(result!.Value);

                meterServiceTypeOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;

                // ---------------------- BuildingRentType ----------------------
                result = await _CrudController.GetDDLValues(
                    "billPeriodName", "billPeriodID", "2", nameof(DeductListReport), usersId, IdaraId, HostName
                ) as JsonResult;


                json = JsonSerializer.Serialize(result!.Value);

                billPeriodIDOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;


                // ----------------------END DDLValues ----------------------


                // Determine which fields should be visible based on SearchID_

                form = new FormConfig
                {
                    Fields = new List<FieldConfig>
                {

                          new FieldConfig
                            {
                                SectionTitle = "نوع البحث",
                                Name = "permissinType",
                                Type = "select",
                                Select2 = true,
                                Options = meterServiceTypeOptions,
                                ColCss = "3",
                                Value = meterServiceTypeID_,
                                Placeholder = "اختر الخدمة",
                                Icon = "fa fa-user",
                                NavUrl = "/IncomeSystem/DeductListReport",
                                NavKey = "U",
                                OnChangeJs = "sfToggle(this); sfNav(this);"  //الدوال اللي تنفذ
                            },


                          new FieldConfig
                                    {
                                        Name = "Section",
                                        Type = "select",
                                        Options = billPeriodIDOptions,
                                        ColCss = "3",
                                        Placeholder = "اختر الفرع",
                                        Select2 = true,
                                        Icon = "fa fa-user",
                                        Value = billPeriodID_,
                                        DependsOn = "permissinType",
                                        DependsUrl = "/crud/DDLFiltered?FK=meterServiceTypeID_FK&textcol=billPeriodName&ValueCol=billPeriodID&PageName=DeductListReport&TableIndex=2",
                                        // ===== بيانات التنقّل (sfNav) =====
                                        NavUrl  = "/IncomeSystem/DeductListReport",
                                        NavKey  = "U",// قيمة الحقل بتروح هنا: U=UserID
                                        NavKey2 = "P",
                                        //NavVal2 = "1",
                                        OnChangeJs = "sfNav(this)"
                                    },

                             },
                    Buttons = new List<FormButtonConfig>
                    {

                    }
                };

                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    // اقرأ الجدول الأول

                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "PRINTDEDUCTLISTREPORT") canPRINTDEDUCTLISTREPORT= true;
                       
                    }


                    // نبحث عن صلاحيات محددة داخل الجدول



                    if (ds != null && ds.Tables.Count > 0)
                    {

                        // Resolve a correct row id field (case sensitive match to actual DataTable column)
                        rowIdField = "BillsID";
                        var possibleIdNames = new[] { "BillsID", "billsID", "Id", "ID" };

                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        //For change table name to arabic 
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["BillsID"] = "المعرف",
                            ["menuName_A"] = "اسم الصفحة",
                            ["permissionTypeName_A"] = "الصلاحية",
                            ["permissionStartDate"] = "تاريخ بداية الصلاحية",
                            ["permissionEndDate"] = "تاريخ نهاية الصلاحية",
                            ["permissionNote"] = "ملاحظات"
                        };


                        // build columns from DataTable schema
                        foreach (DataColumn c in dt1.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                            bool isuserID = c.ColumnName.Equals("userID", StringComparison.OrdinalIgnoreCase);
                            bool isPermissionID = c.ColumnName.Equals("PermissionID", StringComparison.OrdinalIgnoreCase);
                            bool isdistributorID_FK = c.ColumnName.Equals("distributorID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isRoleID_FK = c.ColumnName.Equals("RoleID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraID_FK = c.ColumnName.Equals("IdaraID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isDSDID_FK = c.ColumnName.Equals("DSDID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isdeptID = c.ColumnName.Equals("deptID", StringComparison.OrdinalIgnoreCase);
                            bool issecID = c.ColumnName.Equals("secID", StringComparison.OrdinalIgnoreCase);
                            bool isdivID = c.ColumnName.Equals("divID", StringComparison.OrdinalIgnoreCase);
                            bool isPermissionRoleID = c.ColumnName.Equals("PermissionRoleID", StringComparison.OrdinalIgnoreCase);
                            bool ismenuName_A = c.ColumnName.Equals("menuName_A", StringComparison.OrdinalIgnoreCase);


                            List<OptionItem> filterOpts = new();
                            if (ismenuName_A)
                            {
                                var field = c.ColumnName;

                                var distinctVals = dt1.AsEnumerable()
                                    .Select(r => (r[field] == DBNull.Value ? "" : r[field]?.ToString())?.Trim())
                                    .Where(s => !string.IsNullOrWhiteSpace(s))
                                    .Distinct()
                                    .OrderBy(s => s)
                                    .ToList();

                                filterOpts = distinctVals
                                    .Select(s => new OptionItem { Value = s!, Text = s! })
                                    .ToList();
                            }


                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                //if u want to hide any column 
                                ,
                                Visible = !(isuserID || isdistributorID_FK || isRoleID_FK || isIdaraID_FK || isDSDID_FK || isdeptID || issecID || isdivID)
                                ,
                                Filter = (ismenuName_A)
                                    ? new TableColumnFilter
                                    {
                                        Enabled = true,
                                        Type = "select",
                                        Options = filterOpts,
                                    }
                                    : new TableColumnFilter
                                    {
                                        Enabled = false
                                    }
                            });
                        }



                        // build rows (plain dictionaries) so JSON serialization is clean
                        foreach (DataRow r in dt1.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt1.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                            // Ensure the row id key actually exists with correct casing
                            if (!dict.ContainsKey(rowIdField))
                            {
                                // Try to copy from a differently cased variant
                                if (rowIdField.Equals("BillsID", StringComparison.OrdinalIgnoreCase) &&
                                    dict.TryGetValue("BillsID", out var alt))
                                    dict["BillsID"] = alt;
                                else if (rowIdField.Equals("BillsID", StringComparison.OrdinalIgnoreCase) &&
                                         dict.TryGetValue("BillsID", out var alt2))
                                    dict["BillsID"] = alt2;
                            }

                            // Prefill pXX fields on the row so Edit form (which uses pXX names) loads the selected row values
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("BillsID") ?? Get("BillsID") ?? Get("Id") ?? Get("ID");
                            dict["p02"] = Get("menuName_A");
                            dict["p03"] = Get("permissionTypeName_A");
                            dict["p04"] = Get("permissionStartDate");
                            dict["p05"] = Get("permissionEndDate");
                            dict["p06"] = Get("permissionNote");

                            rowsList.Add(dict);
                        }
                    }


                }
            }
            catch (Exception ex)
            {
                ViewBag.DataSetError = ex.Message;
                //TempData["info"] = ex.Message;
            }





            var dsModel = new SmartTableDsModel
            {
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                PageTitle = "المباني",
                PanelTitle = "المباني ",
                EnableCellCopy = true,
                ShowColumnVisibility = true,
                ShowFilter = true,
                FilterRow = true,
                FilterDebounce = 250,

                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowPrint1 = canPRINTDEDUCTLISTREPORT,
                    ShowBulkDelete = false,
                    Print1 = new TableAction
                    {
                        Label = "طباعة تقرير",
                        Icon = "fa fa-print",
                        Color = "info",
                        RequireSelection = false,
                        OnClickJs = @"
                        (function () {
                            var u = window.UtilityTypeID_ || '';
                        
                            sfPrintWithBusy(table, {
                              pdf: 1,
                              extraParams: { U: u },
                              busy: { title: 'طباعة سجلات انتظار' }
                            });
                        })();
                        ",

                       
                    },

                   
                }
            };






        
            var vm = new SmartPageViewModel
            {
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle,
                PanelIcon = "fa-home",
                Form = form,
                //TableDS = dsModel
                TableDS = ready ? dsModel : null

            };

  
            return View("FinancialAudit/DeductListReport", vm);
        }
    }
}
