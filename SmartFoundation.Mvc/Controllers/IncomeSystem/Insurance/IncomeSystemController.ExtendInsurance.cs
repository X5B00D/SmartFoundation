using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using SmartFoundation.MVC.Reports;



namespace SmartFoundation.Mvc.Controllers.IncomeSystem
{
    public partial class IncomeSystemController : Controller
    {

        
        public async Task<IActionResult> ExtendInsurance(int pdf = 0)
        {
            //  قراءة السيشن والكونتكست
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(IncomeSystem);
            PageName = string.IsNullOrWhiteSpace(PageName) ? "ExtendInsurance" : PageName;

            var spParameters = new object?[]
            {
             PageName ?? "ExtendInsurance",
             IdaraId,
             usersId,
             HostName
            };

           

            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();

            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

            //  تقسيم الداتا سيت للجدول الأول + جداول أخرى
            SplitDataSet(ds);

            //  التحقق من الصلاحيات
            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }

            string rowIdField = "";
            bool canApproveExtendInsurance = false;
            

            try
            {
                if (ds != null && ds.Tables.Count > 0 && permissionTable!.Rows.Count > 0)
                {
                    // صلاحيات
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "APPROVEEXTENDINSURANCE") canApproveExtendInsurance = true;
                    }

                    if (dt1 != null && dt1.Columns.Count > 0)
                    {
                        // RowId
                        rowIdField = "ExtendInsuranceID";
                        var possibleIdNames = new[] { "ExtendInsuranceID", "extendInsuranceID", "Id", "ID" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        // عناوين الأعمدة بالعربي
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["ExtendInsuranceID"] = "الرقم المرجعي",
                            ["generalNo_FK"] = "الرقم العام",
                            ["NationalID"] = "رقم الهوية",
                            ["FullName_A"] = "الاسم",
                            ["rankNameA"] = "الرتبة",
                            ["WaitingClassName"] = "الفئة",
                            ["buildingDetailsNo"] = "رقم المنزل",
                            ["InsuranceAmount"] = "مبلغ التأمين",
                            ["Remaining"] = "المطالبات المتبقية",
                            ["InsuranceAmountWithRemaining"] = "الاجمالي",
                            ["ExtendInsuranceNo"] = "رقم وثيقة طلب التأمين",
                            ["ExtendInsuranceDate"] = "تاريخ وثيقة طلب التأمين",
                            ["ExtendInsuranceTypeName_A"] = "نوع التأمين",
                            ["ExtendInsuranceNote"] = "ملاحظات",
                            ["ExtendInsuranceApprovedDate"] = "تاريخ الموافقة على التأمين",
                            ["ExtendInsuranceApprovedStatusText"] = "الحالة",
                            ["ExtendInsuranceIncomeNo"] = "رقم وثيقة اعتماد التأمين",
                            ["ExtendInsuranceIncomeDate"] = "تاريخ وثيقة اعتماد التأمين",
                            ["ApprovedeEntryUser"] = "معتمد التأمين",
                            ["InsuranceEntryUser"] = "منفذ طلب التأمين"
                        };

                        // الأعمدة
                        foreach (DataColumn c in dt1.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                            bool isbuildingActionID_FK = c.ColumnName.Equals("buildingActionID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isresidentInfoID_FK = c.ColumnName.Equals("residentInfoID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsID_FK = c.ColumnName.Equals("buildingDetailsID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isExtendInsuranceType = c.ColumnName.Equals("ExtendInsuranceType", StringComparison.OrdinalIgnoreCase);
                            bool isExtendInsuranceActive = c.ColumnName.Equals("ExtendInsuranceActive", StringComparison.OrdinalIgnoreCase);
                            bool isExtendInsuranceApproved = c.ColumnName.Equals("ExtendInsuranceApproved", StringComparison.OrdinalIgnoreCase);
                            bool isExtendInsuranceApprovedby = c.ColumnName.Equals("ExtendInsuranceApprovedby", StringComparison.OrdinalIgnoreCase);
                            bool isExtendInsuranceApprovedStatus = c.ColumnName.Equals("ExtendInsuranceApprovedStatus", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraId_FK = c.ColumnName.Equals("IdaraId_FK", StringComparison.OrdinalIgnoreCase);
                            bool isentryDate = c.ColumnName.Equals("entryDate", StringComparison.OrdinalIgnoreCase);
                            bool isentryData = c.ColumnName.Equals("entryData", StringComparison.OrdinalIgnoreCase);
                            bool ishostName = c.ColumnName.Equals("hostName", StringComparison.OrdinalIgnoreCase);
                            bool ismilitaryUnitID_FK = c.ColumnName.Equals("militaryUnitID_FK", StringComparison.OrdinalIgnoreCase);
                            
                            
                            
                            
                            bool isExtendInsuranceApprovedStatusText = c.ColumnName.Equals("ExtendInsuranceApprovedStatusText", StringComparison.OrdinalIgnoreCase);

                            List<OptionItem> filterOpts = new();

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true,
                                Visible = !(isbuildingActionID_FK
                                            || isresidentInfoID_FK
                                            || isbuildingDetailsID_FK
                                            || isExtendInsuranceType
                                            || isExtendInsuranceActive
                                            || isExtendInsuranceApproved
                                            || isExtendInsuranceApprovedby
                                            || isExtendInsuranceApprovedStatus
                                            || isIdaraId_FK
                                            || isentryDate
                                            || isentryData
                                            || ismilitaryUnitID_FK
                                            || ishostName),

                                             Filter = (isExtendInsuranceApprovedStatusText)
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

                        // الصفوف
                        foreach (DataRow r in dt1.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt1.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                            // p01..p05
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("ExtendInsuranceID") ?? Get("extendInsuranceID");
                            dict["p02"] = Get("buildingActionID_FK");
                            dict["p03"] = Get("residentInfoID_FK");
                            dict["p04"] = Get("generalNo_FK");
                            dict["p05"] = Get("NationalID");
                            dict["p06"] = Get("FullName_A");
                            dict["p07"] = Get("rankNameA");
                            dict["p08"] = Get("WaitingClassName");
                            dict["p09"] = Get("buildingDetailsID_FK");
                            dict["p10"] = Get("buildingDetailsNo");

                            object? rem = Get("InsuranceAmount");
                            dict["p11"] = rem == null ? null : rem.ToString();
                            object? rem1 = Get("Remaining");
                            dict["p12"] = rem1 == null ? null : rem1.ToString();
                            object? rem2 = Get("InsuranceAmountWithRemaining");
                            dict["p13"] = rem2 == null ? null : rem2.ToString();

                            
                            dict["p14"] = Get("ExtendInsuranceNo");
                            dict["p15"] = Get("ExtendInsuranceDate");
                            dict["p16"] = Get("ExtendInsuranceType");
                            dict["p17"] = Get("ExtendInsuranceTypeName_A");
                            dict["p18"] = Get("ExtendInsuranceNote");
                            dict["p19"] = Get("ExtendInsuranceActive");
                            dict["p20"] = Get("ExtendInsuranceApproved");
                            dict["p21"] = Get("ExtendInsuranceIncomeNo");
                            dict["p22"] = Get("ExtendInsuranceIncomeDate");
                            dict["p23"] = Get("ExtendInsuranceApprovedby");
                            dict["p24"] = Get("ExtendInsuranceApprovedStatus");
                            dict["p25"] = Get("ExtendInsuranceApprovedStatusText");
                            dict["p26"] = Get("ExtendInsuranceApprovedDate");
                            dict["p27"] = Get("IdaraId_FK");
                            dict["p28"] = Get("entryDate");
                            dict["p29"] = Get("entryData");
                            dict["p30"] = Get("hostName");
                            dict["p31"] = Get("InsuranceEntryUser");
                            dict["p32"] = Get("militaryUnitID_FK");


                            if (!dict.TryGetValue(rowIdField, out var idVal) || idVal == null)
                            {
                                // fallback: find by case-insensitive key and assign under exact rowIdField casing
                                var kv = dict.FirstOrDefault(k => string.Equals(k.Key, rowIdField, StringComparison.OrdinalIgnoreCase));
                                dict[rowIdField] = kv.Value;
                            }

                            rowsList.Add(dict);
                        }
                    }
                }
            }
            catch (Exception)
            {
                ViewBag.BuildingTypeDataSetError = "حدث خطأ أثناء تحميل البيانات. يرجى المحاولة مرة أخرى.";
            }

           
            // UPDATE fields
            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "APPROVEEXTENDINSURANCE" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "الرقم المرجعي",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p02", Label = "buildingActionID_FK",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p03", Label = "residentInfoID_FK",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p04", Label = "الرقم العام",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p05", Label = "رقم الهوية",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p06", Label = "الاسم",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p07", Label = "الرتبة",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p08", Label = "الفئة",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p09", Label = "buildingDetailsID_FK",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p10", Label = "رقم المنزل",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p11", Label = "مبلغ التأمين",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p12", Label = "المطالبات المتبقية",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p13", Label = "اجمالي مبلغ التأمين",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p14", Label = "رقم وثيقة مطالبة التأمين",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p15", Label = "تاريخ وثيقة مطالبة التأمين",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p16", Label = "ExtendInsuranceType",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p17", Label = "نوع سداد مطالبة التأمين",Type ="text", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p18", Label = "ملاحظات مطالبة التأمين",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p19", Label = "ExtendInsuranceActive",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p20", Label = "ExtendInsuranceApproved",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p21", Label = "ExtendInsuranceIncomeNo",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p22", Label = "ExtendInsuranceIncomeDate",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p23", Label = "ExtendInsuranceApprovedby",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p24", Label = "ExtendInsuranceApprovedStatus",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p25", Label = "ExtendInsuranceApprovedStatusText",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p26", Label = "ExtendInsuranceApprovedDate",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p27", Label = "IdaraId_FK",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p28", Label = "entryDate",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p29", Label = "entryData",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p30", Label = "hostName",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p31", Label = "InsuranceEntryUser",Type ="hidden", Readonly = true, ColCss = "4" },
                new FieldConfig { Name = "p32", Label = "militaryUnitID_FK",Type ="hidden", Readonly = true, ColCss = "4" },



                new FieldConfig { Name = "p40", Label = "رقم اعتماد التامين",Type ="text",Required =true, Readonly = false, ColCss = "4" },
                new FieldConfig { Name = "p41", Label = "تاريخ اعتماد التامين",Type ="date",Required =true, Readonly = false, ColCss = "4" },
                new FieldConfig { Name = "p42", Label = "ملاحظات اعتماد التامين",Type ="textarea",Required =true, Readonly = false, ColCss = "4" },
                
            };

            // DELETE fields
            var deleteFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_",          Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETEBUILDINGTYPE" },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField, Type = "hidden" },
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "ExtendInsuranceID" },

                new FieldConfig { Name = "p02", Label = "رمز نوع المباني",Type ="text", Required = true,Readonly=true,  ColCss = "4",Icon = "fa fa-building" },
                new FieldConfig { Name = "p03", Label = "اسم نوع المباني بالعربي", Type ="text",ColCss = "4", Required = true,Readonly=true, TextMode = "arabic",Icon = "fa fa-home" },
                new FieldConfig { Name = "p04", Label = "اسم نوع المباني بالانجليزي", Type ="text", ColCss = "4",Readonly=true,TextMode = "english",Icon = "fa fa-home" },
                
            };

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
                PageTitle = "التحقق من التأمين الاحترازي",
                PanelTitle = "التحقق من التأمين الاحترازي ",
                EnableCellCopy = true,
                ShowColumnVisibility = true,
                ShowFilter = true,
                FilterRow = true,
                FilterDebounce = 250,
                Selectable = true,
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowEdit = canApproveExtendInsurance,
                    ShowPrint = false, // شرطك
                    ShowPrint1 = false, // شرطك
                    ShowBulkDelete = false,

                    Edit = new TableAction
                    {
                        Label = "اعتماد التأمين الاحترازي",
                        Icon = "fa fa-check",
                        Color = "success",
                       // Placement = TableActionPlacement.ActionsMenu, //   أي زر بعد ما نسويه ونبيه يظهر في الاجراءات نحط هذا السطر فقط عشان ما يصير زحمة في التيبل اكشن
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "اعتماد التأمين الاحترازي",
                        ModalMessage = "في حال اعتماد التأمين الاحترازي لايمكن التراجع عن ذلك نهائيا وسيتم اعتماده للمستفيد ومعالجة المطالبات منه لذلك يجب أن تتأكد من جميع البيانات قبل الاعتماد",
                        ModalMessageClass = "bg-red-50 text-red-700",
                        ModalMessageIcon = "fa-solid fa-triangle-exclamation",

                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeEditForm",
                            Title = "اعتماد التأمين الاحترازي",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = updateFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1,

                        Guards = new TableActionGuards
                        {
                            AppliesTo = "any",
                            DisableWhenAny = new List<TableActionRule>
                        {

                              new TableActionRule
                            {
                                Field = "ExtendInsuranceApprovedStatus",
                                Op = "eq",
                                Value = "1",
                                Message = "تم اعتماد التأمين الاحترازي مسبقا",
                                Priority = 3
                            },
                           

                          }
                        }
                    },

                   

                    Print = new TableAction
                    {
                        Label = "طباعة أنواع المباني",
                        Icon = "fa fa-print",
                        Color = "primary",
                        Placement = TableActionPlacement.ActionsMenu,
                        RequireSelection = false,
                        OnClickJs = @"
                                sfPrintWithBusy(table, {
                                  pdf: 1,
                                  busy: { title: 'طباعة أنواع المباني'}
                                });
                                "

                    },

                    Print1 = new TableAction
                    {
                        Label = "طباعة خطاب تجريبي",
                        Icon = "fa fa-print",
                        Color = "primary",
                        Placement = TableActionPlacement.ActionsMenu,
                        RequireSelection = false,
                        OnClickJs = @"
                                sfPrintWithBusy(table, {
                                  pdf: 2,
                                  busy: { title: 'طباعة خطاب تجريبي'}
                                });
                                "

                    },

                }
            };

            //return View("HousingDefinitions/BuildingType", dsModel);

            var page = new SmartPageViewModel
            {
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle,
                PanelIcon = "fa-layer-group",
                TableDS = dsModel
            };


            dsModel.StyleRules = new List<TableStyleRule>
                        {

                            new TableStyleRule
                            {
                                Target="row", Field="ExtendInsuranceApprovedStatus", Op="eq", Value="0", Priority=1,
                                PillEnabled=true,
                                PillField="ExtendInsuranceApprovedStatusText",
                                PillTextField="ExtendInsuranceApprovedStatusText",
                                PillCssClass="pill pill-yellow",
                                PillMode="replace"
                            },
                              new TableStyleRule
                            {
                                Target="row", Field="ExtendInsuranceApprovedStatus", Op="eq", Value="1", Priority=1,
                                PillEnabled=true,
                                PillField="ExtendInsuranceApprovedStatusText",
                                PillTextField="ExtendInsuranceApprovedStatusText",
                                PillCssClass="pill pill-green",
                                PillMode="replace"
                            },
                            new TableStyleRule
                            {
                                Target="row", Field="ExtendInsuranceApprovedStatus", Op="eq", Value="2", Priority=1,
                                PillEnabled=true,
                                PillField="ExtendInsuranceApprovedStatusText",
                                PillTextField="ExtendInsuranceApprovedStatusText",
                                PillCssClass="pill pill-red",
                                PillMode="replace"
                            }
                           
                        };



            // ===== PDF Export (same request, no extra DB call) =====
            if (pdf == 1)
            {
                var printTable = dt1;

                if (printTable == null || printTable.Rows.Count == 0)
                    return Content("لا توجد بيانات للطباعة.");


                var reportColumns = new List<ReportColumn>
{
    new("buildingTypeCode",   "رمز نوع المباني",       Align:"center", Weight:1, FontSize:9),
    new("buildingTypeName_A", "اسم نوع المباني بالعربي",Align:"center", Weight:2, FontSize:10),
    new("buildingTypeName_E", "اسم نوع المباني بالإنجليزي",Align:"center", Weight:2, FontSize:9),
    //new ReportColumn("buildingTypeDescription", "ملاحظات",Align: "right",  Weight: 4, FontSize:9),
};

              

                var logo = Path.Combine(_env.WebRootPath, "img", "Royal_Saudi_Land_Forces.png");

                var header = new Dictionary<string, string>
                {
                    ["no"] = "١٢٣/٤٥",
                    ["date"] = DateTime.Now.ToString("yyyy/MM/dd"),
                    ["attach"] = "—",
                    ["subject"] = "تقرير أنواع المباني",

                    ["right1"] = "المملكة العربية السعودية",
                    ["right2"] = "وزارة الدفاع",
                    ["right3"] = "القوات البرية الملكية السعودية",
                    ["right4"] = OrganizationName,
                    ["right5"] = IdaraName,

                    ["bismillah"] = "بسم الله الرحمن الرحيم",
                    ["midCaption"] = ""
                };

                var report = DataTableReportBuilder.FromDataTable(
                    reportId: "BuildingType",
                    title: "تقرير أنواع المباني",
                    table: printTable,
                    columns: reportColumns,
                    headerFields: header,
                    //footerFields: new(),
                   footerFields: new(),
                    
                    orientation: ReportOrientation.Landscape,
                    headerType: ReportHeaderType.LetterOfficial,
                    logoPath: logo
                );
                


                

                var pdfBytes = QuestPdfReportRenderer.Render(report);
                Response.Headers["Content-Disposition"] = "inline; filename=BuildingType.pdf";
                return File(pdfBytes, "application/pdf");


            }


         




            return View("Insurance/ExtendInsurance", page);

        }

       

    }
}
