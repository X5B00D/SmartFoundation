using Microsoft.AspNetCore.Mvc;
using SmartFoundation.MVC.Reports;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;

namespace SmartFoundation.Mvc.Controllers.Housing
{
    public partial class HousingController : Controller
    {
        public async Task<IActionResult> HousingExtendFollowUp(int pdf = 0)
        {
            if (!InitPageContext(out var redirect))
                return redirect!;

            ControllerName = nameof(Housing);
            PageName = nameof(HousingExtendFollowUp);

            var spParameters = new object?[] { PageName, IdaraId, usersId, HostName };
            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);
            SplitDataSet(ds);

            var canViewHousingExtendFollowUp = permissionTable?.AsEnumerable().Any(row =>
                string.Equals(
                    row["permissionTypeName_E"]?.ToString()?.Trim(),
                    "VIEWHOUSINGEXTENDFOLLOWUP",
                    StringComparison.OrdinalIgnoreCase)) == true;

            if (!canViewHousingExtendFollowUp)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به. لا تملك صلاحية الوصول إلى الصفحة.";
                return RedirectToAction("Index", "Home");
            }

            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();
            var rowIdField = "ActionID";

            if (dt1 is not null && dt1.Columns.Count > 0)
            {
                var possibleIdNames = new[] { "ActionID", "actionID", "Id", "ID" };
                rowIdField = possibleIdNames.FirstOrDefault(dt1.Columns.Contains) ?? dt1.Columns[0].ColumnName;

                var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["NationalID"] = "رقم الهوية",
                    ["GeneralNo"] = "الرقم العام",
                    ["FullName_A"] = "الاسم",
                    ["rankNameA"] = "الرتبة",
                    ["buildingDetailsNo"] = "رقم المنزل",
                    ["OccupentDate"] = "تاريخ السكن",
                    ["WaitingClassName"] = "فئة سجل الانتظار",
                    ["WaitingOrderTypeName"] = "نوع سجل الانتظار",
                    ["WaitingListOrder"] = "الترتيب",
                    ["LastActionDecisionNo"] = "رقم خطاب الموافقة",
                    ["LastActionDecisionDate"] = "تاريخ خطاب الموافقة",
                    ["ExtendFromDate"] = "بداية الإمهال",
                    ["ExtendToDate"] = "نهاية الإمهال",
                    ["ExtendReasonTypeName_A"] = "سبب الإمهال",
                    ["buildingActionTypeResidentAlias"] = "حالة الإمهال",
                    ["InsuranceStatusName"] = "حالة التأمين الاحترازي",
                    ["ExtendRemainingDays"] = "الأيام المتبقية للإمهال",
                    ["ExtendExpiryStatus"] = "حالة انتهاء الإمهال",
                    ["ActionNote"] = "ملاحظات"
                };

                foreach (DataColumn column in dt1.Columns)
                {
                    var type = column.DataType == typeof(DateTime) ? "date" :
                        column.DataType == typeof(byte) || column.DataType == typeof(short) || column.DataType == typeof(int) ||
                        column.DataType == typeof(long) || column.DataType == typeof(decimal) || column.DataType == typeof(double) ? "number" : "text";

                    var isActionID = column.ColumnName.Equals("ActionID", StringComparison.OrdinalIgnoreCase);
                    var isWaitingClassID = column.ColumnName.Equals("WaitingClassID", StringComparison.OrdinalIgnoreCase);
                    var isWaitingOrderTypeID = column.ColumnName.Equals("WaitingOrderTypeID", StringComparison.OrdinalIgnoreCase);
                    var isWaitingClassSequence = column.ColumnName.Equals("waitingClassSequence", StringComparison.OrdinalIgnoreCase);
                    var isIdaraId = column.ColumnName.Equals("IdaraId", StringComparison.OrdinalIgnoreCase);
                    var isResidentInfoID = column.ColumnName.Equals("residentInfoID", StringComparison.OrdinalIgnoreCase);
                    var isLastActionTypeID = column.ColumnName.Equals("LastActionTypeID", StringComparison.OrdinalIgnoreCase);
                    var isBuildingDetailsID = column.ColumnName.Equals("buildingDetailsID", StringComparison.OrdinalIgnoreCase);
                    var isLastActionID = column.ColumnName.Equals("LastActionID", StringComparison.OrdinalIgnoreCase);
                    var isWaitingOrderTypeName = column.ColumnName.Equals("WaitingOrderTypeName", StringComparison.OrdinalIgnoreCase);
                    var isWaitingListOrder = column.ColumnName.Equals("WaitingListOrder", StringComparison.OrdinalIgnoreCase);
                    var isInsuranceStatusNo = column.ColumnName.Equals("InsuranceStatusNo", StringComparison.OrdinalIgnoreCase);
                    var isExtendReasonTypeID = column.ColumnName.Equals("ExtendReasonTypeID", StringComparison.OrdinalIgnoreCase);
                    var isLastActionExtendReasonTypeID = column.ColumnName.Equals("LastActionExtendReasonTypeID", StringComparison.OrdinalIgnoreCase);
                    var isRemaining = column.ColumnName.Equals("Remaining", StringComparison.OrdinalIgnoreCase);
                    var isBuildingRentAmount = column.ColumnName.Equals("buildingRentAmount", StringComparison.OrdinalIgnoreCase);
                    var isInsuranceAmount = column.ColumnName.Equals("InsuranceAmount", StringComparison.OrdinalIgnoreCase);
                    var isInsuranceAmountWithRemaining = column.ColumnName.Equals("InsuranceAmountWithRemaining", StringComparison.OrdinalIgnoreCase);
                    var isStatus = column.ColumnName.Equals("buildingActionTypeResidentAlias", StringComparison.OrdinalIgnoreCase);
                    var isWaitingClassName = column.ColumnName.Equals("WaitingClassName", StringComparison.OrdinalIgnoreCase);
                    var isRank = column.ColumnName.Equals("rankNameA", StringComparison.OrdinalIgnoreCase);
                    var isInsuranceStatus = column.ColumnName.Equals("InsuranceStatusName", StringComparison.OrdinalIgnoreCase);
                    
                    
                    var isLastActionDecisionNo = column.ColumnName.Equals("LastActionDecisionNo", StringComparison.OrdinalIgnoreCase);
                    var isLastActionDecisionDate = column.ColumnName.Equals("LastActionDecisionDate", StringComparison.OrdinalIgnoreCase);
                    var isbuildingActionTypeResidentAlias = column.ColumnName.Equals("buildingActionTypeResidentAlias", StringComparison.OrdinalIgnoreCase);
                    var isActionNote = column.ColumnName.Equals("ActionNote", StringComparison.OrdinalIgnoreCase);
                    var isExtendRemainingDays = column.ColumnName.Equals("ExtendRemainingDays", StringComparison.OrdinalIgnoreCase);
                    var isInsuranceStatusName = column.ColumnName.Equals("InsuranceStatusName", StringComparison.OrdinalIgnoreCase);

                    var filterOptions = new List<OptionItem>();
                    if (isStatus || isWaitingClassName || isRank || isInsuranceStatus)
                    {
                        filterOptions = dt1.AsEnumerable()
                            .Select(row => row[column] == DBNull.Value ? null : row[column]?.ToString()?.Trim())
                            .Where(value => !string.IsNullOrWhiteSpace(value))
                            .Distinct()
                            .OrderBy(value => value)
                            .Select(value => new OptionItem { Value = value!, Text = value! })
                            .ToList();
                    }

                    dynamicColumns.Add(new TableColumn
                    {
                        Field = column.ColumnName,
                        Label = headerMap.TryGetValue(column.ColumnName, out var label) ? label : column.ColumnName,
                        Type = type,
                        Sortable = true,
                        Visible = !(isActionID || isWaitingClassID || isWaitingOrderTypeID || isWaitingClassSequence ||
                            isIdaraId || isWaitingOrderTypeName || isWaitingListOrder || isLastActionID || isLastActionTypeID ||
                            isExtendReasonTypeID || isLastActionExtendReasonTypeID || isRemaining || isBuildingRentAmount ||
                            isInsuranceAmount || isInsuranceStatusNo || isBuildingDetailsID || isInsuranceAmountWithRemaining || isResidentInfoID || isLastActionDecisionNo || isLastActionDecisionDate || isbuildingActionTypeResidentAlias || isActionNote || isExtendRemainingDays || isInsuranceStatusName ),
                        Filter = (isStatus || isWaitingClassName || isRank || isInsuranceStatus)
                            ? new TableColumnFilter { Enabled = true, Type = "select", Options = filterOptions }
                            : new TableColumnFilter { Enabled = false }
                    });
                }

                    foreach (DataRow row in dt1.Rows)
                    {
                    var item = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                        foreach (DataColumn column in dt1.Columns)
                            item[column.ColumnName] = row[column] == DBNull.Value ? null : row[column];

                        object? Get(string key) => item.TryGetValue(key, out var value) ? value : null;
                        item["p01"] = Get("ActionID");
                        item["p02"] = Get("residentInfoID");
                        item["p03"] = Get("NationalID");
                        item["p04"] = Get("GeneralNo");
                        item["p07"] = Get("WaitingClassID");
                        item["p08"] = Get("WaitingClassName");
                        item["p09"] = Get("WaitingOrderTypeID");
                        item["p10"] = Get("WaitingOrderTypeName");
                        item["p11"] = Get("waitingClassSequence");
                        item["p12"] = Get("ActionNote");
                        item["p13"] = Get("IdaraId");
                        item["p14"] = Get("WaitingListOrder");
                        item["p15"] = Get("FullName_A");
                        item["p16"] = Get("LastActionTypeID");
                        item["p17"] = Get("buildingActionTypeResidentAlias");
                        item["p18"] = Get("buildingDetailsID");
                        item["p19"] = Get("buildingDetailsNo");
                        item["p21"] = Get("LastActionID");
                        item["p22"] = Get("LastActionDecisionDate");
                        item["p23"] = Get("LastActionDecisionNo");
                        item["p24"] = Get("ExtendFromDate");
                        item["p25"] = Get("ExtendToDate");
                        item["p27"] = Get("LastActionExtendReasonTypeID");
                        item["p28"] = Get("Remaining")?.ToString();
                        item["p29"] = Get("buildingRentAmount")?.ToString();
                        item["p30"] = Get("InsuranceAmount")?.ToString();
                        item["p31"] = Get("InsuranceAmountWithRemaining")?.ToString();
                        item["p32"] = Get("ExtendReasonTypeName_A");
                        item["p45"] = Get("OccupentDate");

                    rowsList.Add(item);
                }
            }

            var dsModel = new SmartTableDsModel
            {
                PageTitle = "متابعة انتهاء الإمهال",
                PanelTitle = "متابعة انتهاء الإمهال",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 200 },
                QuickSearchFields = dynamicColumns.Select(column => column.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                ShowPageSizeSelector = true,
                EnableCellCopy = true,
                ShowColumnVisibility = true,
                HeaderMode = SmartTableHeaderMode.Smart,
                EnableColumnHeaderMenu = true,
                ShowFilter = false,
                ShowAdvancedFilter = true,
                FilterRow = true,
                FilterDebounce = 250,
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowEdit = false,
                    ShowEdit1 = false,
                    ShowEdit2 = false,
                    ShowDelete = false,
                    ShowDelete1 = false,
                    ShowDelete2 = false,
                    ShowBulkDelete = false,
                    ShowPrint1 = rowsList.Count > 0,
                    ShowExportPdf = false,
                    Print1 = new TableAction
                    {
                        Label = "طباعة تقرير متابعة الإمهال",
                        Icon = "fa fa-print",
                        Color = "info",
                        RequireSelection = false,
                        OnClickJs = @"
                            sfPrintWithBusy(table, {
                                pdf: 1,
                                busy: { title: 'طباعة تقرير متابعة الإمهال' }
                            });"
                    },
                    ExportConfig = new TableExportConfig
                    {
                        EnablePdf = true,
                        PdfEndpoint = "/exports/pdf/table",
                        PdfTitle = "متابعة انتهاء الإمهال",
                        PdfPaper = "A4",
                        PdfOrientation = "landscape",
                        PdfShowPageNumbers = true,
                        Filename = "HousingExtendFollowUp",
                        PdfShowGeneratedAt = true,
                        PdfShowSerial = true,
                        PdfSerialLabel = "م",
                        RightHeaderLine1 = "المملكة العربية السعودية",
                        RightHeaderLine2 = "وزارة الدفاع",
                        RightHeaderLine3 = "القوات البرية الملكية السعودية",
                        RightHeaderLine4 = OrganizationName,
                        RightHeaderLine5 = IdaraName,
                        PdfLogoUrl = "/img/Royal_Saudi_Land_Forces.png"
                    },
                    CustomActions = new List<TableAction>
                    {
                        new()
                        {
                            Label = "عرض التفاصيل",
                            ModalTitle = "<i class='fa-solid fa-circle-info text-emerald-600 text-xl mr-2'></i> تفاصيل الإمهال",
                            Icon = "fa-regular fa-file",
                            OpenModal = true,
                            RequireSelection = true,
                            MinSelection = 1,
                            MaxSelection = 1
                        }
                    }
                }
            };

            dsModel.StyleRules = new List<TableStyleRule>
                {
                    new()
                    {
                        Target = "row", Field = "ExtendRemainingDays",
                        Op = "lt", Value = "0", Priority = 1,
                        PillEnabled = true,
                        PillField = "ExtendExpiryStatus",
                        PillTextField = "ExtendExpiryStatus",
                        PillCssClass = "pill pill-red",
                        PillMode = "replace"
                    },
                    new()
                    {
                        Target = "row", Field = "ExtendRemainingDays",
                        Op = "eq", Value = "0", Priority = 2,
                        PillEnabled = true,
                        PillField = "ExtendExpiryStatus",
                        PillTextField = "ExtendExpiryStatus",
                        PillCssClass = "pill pill-red",
                        PillMode = "replace"
                    },
                    new()
                    {
                        Target = "row", Field = "ExtendRemainingDays",
                        Op = "gt", Value = "0", Priority = 3,
                        PillEnabled = true,
                        PillField = "ExtendExpiryStatus",
                        PillTextField = "ExtendExpiryStatus",
                        PillCssClass = "pill pill-yellow",
                        PillMode = "replace"
                    }
                };

            if (pdf == 1)
            {
                if (dt1 is null || dt1.Rows.Count == 0)
                    return Content("لا توجد بيانات للطباعة.");

                var expiredRows = dt1.AsEnumerable()
                    .Where(row =>
                    {
                        if (!dt1.Columns.Contains("ExtendRemainingDays") ||
                            row["ExtendRemainingDays"] == DBNull.Value)
                        {
                            return false;
                        }

                        return decimal.TryParse(
                                   row["ExtendRemainingDays"]?.ToString(),
                                   out var remainingDays)
                               && remainingDays <= 0;
                    })
                    .ToList();

                if (expiredRows.Count == 0)
                    return Content("لا توجد إمهالات منتهية للطباعة.");

                string GetValue(DataRow row, string column)
                {
                    if (!dt1.Columns.Contains(column) || row[column] == DBNull.Value)
                        return string.Empty;
                    return row[column]?.ToString() ?? string.Empty;
                }

                var printTable = new DataTable();
                foreach (var column in new[] {  "FullName_A", "NationalID", "GeneralNo", "rankNameA","OccupentDate", "ExtendFromDate", "ExtendToDate", "buildingDetailsNo", "ExtendReasonTypeName_A", "ExtendExpiryStatus",  "ActionNote" })
                    printTable.Columns.Add(column, typeof(string));

                foreach (DataRow row in expiredRows)
                    printTable.Rows.Add(printTable.Columns.Cast<DataColumn>().Select(column => GetValue(row, column.ColumnName)).ToArray());

                var columns = new List<ReportColumn>
                {
                    new("FullName_A", "الاسم", Align:"center", Weight:4, FontSize:8),
                    new("NationalID", "رقم الهوية", Align:"center", Weight:2, FontSize:8),
                    new("GeneralNo", "الرقم العام", Align:"center", Weight:2, FontSize:8),
                    new("rankNameA", "الرتبة", Align:"center", Weight:2, FontSize:8),
                    new("OccupentDate", "تاريخ السكن", Align:"center", Weight:2, FontSize:8),
                    new("ExtendFromDate", "بداية الإمهال", Align:"center", Weight:2, FontSize:8),
                    new("ExtendToDate", "نهاية الإمهال", Align:"center", Weight:2, FontSize:8),
                    new("buildingDetailsNo", "المنزل", Align:"center", Weight:2, FontSize:8),
                    new("ExtendReasonTypeName_A", "سبب الإمهال", Align:"center", Weight:3, FontSize:8),
                    new("ExtendExpiryStatus", "حالة الانتهاء", Align:"center", Weight:4, FontSize:8),
                    new("ActionNote", "ملاحظات", Align:"center", Weight:3, FontSize:8)
                };

                var logo = Path.Combine(_env.WebRootPath, "img", "Royal_Saudi_Land_Forces.png");
                var report = DataTableReportBuilder.FromDataTable(
                    reportId: "HousingExtendFollowUp",
                    title: "قائمة متابعة انتهاء الإمهال",
                    table: printTable,
                    columns: columns,
                    headerFields: new Dictionary<string, string>
                    {
                        ["no"] =  "-", ["date"] = DateTime.Now.ToString("yyyy/MM/dd"), ["attach"] = "—",
                        ["subject"] = "قائمة متابعة انتهاء الإمهال",
                        ["right1"] = "المملكة العربية السعودية", ["right2"] = "وزارة الدفاع",
                        ["right3"] = "القوات البرية الملكية السعودية", ["right4"] = OrganizationName, ["right5"] = IdaraName,
                        ["midCaption"] = ""
                    },
                    footerFields: new Dictionary<string, string>
                    {
                        ["تمت الطباعة بواسطة"] = FullName ?? "", ["عدد السجلات"] = printTable.Rows.Count.ToString(),
                        ["تاريخ ووقت الطباعة"] = DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss")
                    },
                    orientation: ReportOrientation.Landscape,
                    headerType: ReportHeaderType.LetterOfficial,
                    logoPath: logo,
                    headerRepeat: ReportHeaderRepeat.AllPages,
                    showSerial: true,
                    serialLabel: "م",
                    serialStart: 1);

                var pdfBytes = QuestPdfReportRenderer.Render(report);
                Response.Headers["Content-Disposition"] = "inline; filename=HousingExtendFollowUp.pdf";
                return File(pdfBytes, "application/pdf");
            }

            return View("HousingProcedures/HousingExtendFollowUp", new SmartPageViewModel
            {
                PageTitle = "متابعة انتهاء الإمهال",
                PanelTitle = "متابعة انتهاء الإمهال",
                PanelIcon = "fa-solid fa-calendar-days",
                Panel = new SmartPagePanelConfig
                {
                    Show = true,
                    ShowIcon = true,
                    ShowSubtitle = true,
                    ShowDescription = true,
                    ShowBadges = true,
                    Layout = "compact",
                    Title = "متابعة انتهاء الإمهال",
                    Subtitle = "الإمهالات المعتمدة والسارية التي انتهت أو يتبقى على انتهائها أقل من 60 يوماً.",
                    Description = "صفحة للاستعراض والتفاصيل والطباعة فقط، ولا تتضمن إجراءات تعديل أو اعتماد أو إلغاء.",
                    Icon = "fa-solid fa-calendar-days",
                    Badges = new List<SmartPagePanelBadge>
                    {
                        new() { Label = "نطاق العرض", Value = "إمهال معتمد وسارٍ فقط", Icon = "fa-solid fa-filter", Tone = "success" },
                        new() { Label = "المدة", Value = "منتهٍ أو متبقٍ أقل من 60 يوماً", Icon = "fa-solid fa-calendar-days", Tone = "warning" },
                        new() { Label = "الإجراءات", Value = "استعراض وطباعة فقط", Icon = "fa-solid fa-print", Tone = "default" }
                    }
                },
                TableDS = dsModel
            });
        }
    }
}
