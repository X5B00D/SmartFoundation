using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Text.Json;


namespace SmartFoundation.Mvc.Controllers.Housing
{
    public partial class HousingController : Controller
    {
        public async Task<IActionResult> BuildingDetails()
        {

            if (!InitPageContext(out IActionResult? redirectResult))
                return redirectResult!;

            if (string.IsNullOrWhiteSpace(usersId))
            {
                return RedirectToAction("Index", "Login", new { logout = 4 });
            }

            string? UtilityTypeID_ = Request.Query["U"].FirstOrDefault();

            UtilityTypeID_ = string.IsNullOrWhiteSpace(UtilityTypeID_) ? null : UtilityTypeID_.Trim();
           





            // Sessions 

            ControllerName = nameof(ControlPanel);
            PageName = nameof(BuildingDetails);

            var spParameters = new object?[] { "BuildingDetails", IdaraId, usersId, HostName, UtilityTypeID_};

            //var spParameters = new object?[] { "Permission", IdaraID, userID, HostName, SearchID_, UserID_, distributorID_, RoleID_, Idara_, Dept_, Section_, Divison_ };

            DataSet ds;


            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();


            ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);





            DataTable? permissionTable = (ds?.Tables?.Count ?? 0) > 0 ? ds.Tables[0] : null;

           

            dt1 = (ds?.Tables?.Count ?? 0) > 1 ? ds.Tables[1] : null;
            dt2 = (ds?.Tables?.Count ?? 0) > 2 ? ds.Tables[2] : null;
            dt3 = (ds?.Tables?.Count ?? 0) > 3 ? ds.Tables[3] : null;
            dt4 = (ds?.Tables?.Count ?? 0) > 4 ? ds.Tables[4] : null;
            dt5 = (ds?.Tables?.Count ?? 0) > 5 ? ds.Tables[5] : null;
            dt6 = (ds?.Tables?.Count ?? 0) > 6 ? ds.Tables[6] : null;
            dt7 = (ds?.Tables?.Count ?? 0) > 7 ? ds.Tables[7] : null;
            dt8 = (ds?.Tables?.Count ?? 0) > 8 ? ds.Tables[8] : null;
            dt9 = (ds?.Tables?.Count ?? 0) > 9 ? ds.Tables[9] : null;

            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }





            string rowIdField = "";
            bool canInsert = false;
            bool canUpdate = false;
            bool canDelete = false;



            List<OptionItem> UtilityTypeOptions = new();
            List<OptionItem> BuildingRentTypeOptions = new();
           


            FormConfig form = new();


            try
            {

                // ---------------------- DDLValues ----------------------




                JsonResult? result;
                string json;


               

                //// ---------------------- BuildingUtilityType ----------------------
                result = await _CrudController.GetDDLValues(
                    "buildingUtilityTypeName_A", "buildingUtilityTypeID", "2", nameof(BuildingDetails), usersId, IdaraId, HostName
               ) as JsonResult;


                json = JsonSerializer.Serialize(result!.Value);

                UtilityTypeOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;

                // ---------------------- BuildingRentType ----------------------
                result = await _CrudController.GetDDLValues(
                    "buildingRentTypeName_A", "buildingRentTypeID", "3", nameof(BuildingDetails), usersId, IdaraId, HostName
                ) as JsonResult;


                json = JsonSerializer.Serialize(result!.Value);

                BuildingRentTypeOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;



                // ----------------------END DDLValues ----------------------





                // Determine which fields should be visible based on SearchID_

                form = new FormConfig
                {
                    FormId = "dynamicForm",
                    Title = "نموذج الإدخال",
                    Method = "POST",
                    SubmitText = null,


                    StoredProcedureName = "sp_SaveDemoForm",
                    Operation = "insert",
                    StoredSuccessMessageField = "Message",
                    StoredErrorMessageField = "Error",

                    Fields = new List<FieldConfig>
                {


                     new FieldConfig {

                         Name = "UtilityType",
                         Type = "select",
                         Options = UtilityTypeOptions,
                         ColCss = "3",
                         Placeholder = "اختر المرفق",
                         Icon = "fa fa-user",
                         Value = UtilityTypeID_,
                         OnChangeJs = @"
                                       var UserID_ = value.trim();
                                       if (!UserID_) {
                                           if (typeof toastr !== 'undefined') {
                                               toastr.info('الرجاء الاختيار اولا');
                                           }
                                           return;
                                       }
                                       var url = '/Housing/BuildingDetails?S=1&U=' + encodeURIComponent(UtilityTypeID_);
                                       window.location.href = url;
                                   "
                     }


                 },


                    Buttons = new List<FormButtonConfig>
                    {

                    }
                };

                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    // اقرأ الجدول الأول


                    // نبحث عن صلاحيات محددة داخل الجدول
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "INSERT")
                            canInsert = true;

                        if (permissionName == "UPDATE")
                            canUpdate = true;

                        if (permissionName == "DELETE")
                            canDelete = true;
                    }


                    if (ds != null && ds.Tables.Count > 0)
                    {

                        // Resolve a correct row id field (case sensitive match to actual DataTable column)
                        rowIdField = "permissionID";
                        var possibleIdNames = new[] { "permissionID", "PermissionID", "Id", "ID" };

                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        //For change table name to arabic 
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["buildingDetailsNo"] = "رقم المبنى",
                            ["buildingDetailsRooms"] = "عدد الغرف",
                            ["buildingLevelsCount"] = "عدد الطوابق",
                            ["buildingDetailsArea"] = "مكان المبنى",
                            ["buildingDetailsCoordinates"] = "احداثيات المبنى",
                            ["buildingTypeName_A"] = "نوع المبنى",
                            ["buildingUtilityTypeName_A"] = "نوع المرفق",
                            ["militaryLocationName_A"] = "حي المبنى",
                            ["buildingClassName_A"] = "فئة المبنى",
                            ["buildingDetailsTel_1"] = "تليفون 1",
                            ["buildingDetailsTel_2"] = "تليفون 2",
                            ["buildingDetailsRemark"] = "ملاحظات",
                            ["buildingRentTypeName_A"] = "نوع الايجار",
                            ["buildingRentAmount"] = "الايجار"
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

                            bool isbuildingDetailsID = c.ColumnName.Equals("buildingDetailsID", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingTypeID_FK = c.ColumnName.Equals("buildingTypeID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingUtilityTypeID_FK = c.ColumnName.Equals("buildingUtilityTypeID_FK", StringComparison.OrdinalIgnoreCase);
                            bool ismilitaryLocationID_FK = c.ColumnName.Equals("militaryLocationID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingClassID_FK = c.ColumnName.Equals("buildingClassID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsStartDate = c.ColumnName.Equals("buildingDetailsStartDate", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsEndDate = c.ColumnName.Equals("buildingDetailsEndDate", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsActive = c.ColumnName.Equals("buildingDetailsActive", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingRentStartDate = c.ColumnName.Equals("buildingRentStartDate", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingRentEndDate = c.ColumnName.Equals("buildingRentEndDate", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraId_FK = c.ColumnName.Equals("IdaraId_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsTel_1 = c.ColumnName.Equals("buildingDetailsTel_1", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsTel_2 = c.ColumnName.Equals("buildingDetailsTel_2", StringComparison.OrdinalIgnoreCase);

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                //if u want to hide any column 
                                ,
                                Visible = !(isbuildingDetailsID || isbuildingTypeID_FK || isbuildingUtilityTypeID_FK || ismilitaryLocationID_FK
                                || isbuildingClassID_FK || isbuildingDetailsStartDate || isbuildingDetailsEndDate || isbuildingDetailsActive
                                || isbuildingRentStartDate || isbuildingRentEndDate || isIdaraId_FK || isbuildingDetailsTel_1 || isbuildingDetailsTel_2)
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
                                if (rowIdField.Equals("permissionID", StringComparison.OrdinalIgnoreCase) &&
                                    dict.TryGetValue("permissionID", out var alt))
                                    dict["permissionID"] = alt;
                                else if (rowIdField.Equals("permissionID", StringComparison.OrdinalIgnoreCase) &&
                                         dict.TryGetValue("permissionID", out var alt2))
                                    dict["permissionID"] = alt2;
                            }

                            // Prefill pXX fields on the row so Edit form (which uses pXX names) loads the selected row values
                            object? Get(string key) => dict.TryGetValue(key, out var v) ? v : null;
                            dict["p01"] = Get("buildingDetailsID") ?? Get("buildingDetailsID") ?? Get("BuildingDetailsID") ?? Get("ID");
                            dict["p02"] = Get("buildingDetailsNo");
                            dict["p03"] = Get("buildingDetailsRooms");
                            dict["p04"] = Get("buildingLevelsCount");
                            dict["p05"] = Get("buildingDetailsArea");
                            dict["p06"] = Get("buildingDetailsCoordinates");
                            dict["p07"] = Get("buildingTypeID_FK");
                            dict["p08"] = Get("buildingTypeName_A");
                            dict["p09"] = Get("buildingUtilityTypeID_FK");
                            dict["p10"] = Get("buildingUtilityTypeName_A");
                            dict["p11"] = Get("militaryLocationID_FK");
                            dict["p12"] = Get("militaryLocationName_A");
                            dict["p13"] = Get("buildingClassID_FK");
                            dict["p14"] = Get("buildingClassName_A");
                            dict["p15"] = Get("buildingDetailsTel_1");
                            dict["p16"] = Get("buildingDetailsTel_2");
                            dict["p17"] = Get("buildingRentTypeName_A");
                            dict["p18"] = Get("buildingDetailsRemark");
                            dict["p19"] = Get("buildingDetailsStartDate");
                            dict["p20"] = Get("buildingDetailsEndDate");
                            dict["p21"] = Get("buildingDetailsActive");
                            dict["p22"] = Get("buildingRentStartDate");
                            dict["p23"] = Get("buildingRentEndDate");
                            dict["p24"] = Get("IdaraId_FK");

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


            // Local helper: map TableColumn -> FieldConfig


            // Local helper: build Edit1 fields (prefer dataset column for general number or fallback)

            // build dynamic field lists
            // REPLACE Add form fields: hide dataset textboxes and use your own custom inputs

            //ADD
           


            var currentUrl = Request.Path + Request.QueryString;

            //var addFields = new List<FieldConfig>
            //{

            //    // keep id hidden first so row id can flow when needed
            //    new FieldConfig { Name = rowIdField, Type = "hidden" },

            //    // your custom textboxes
            //    new FieldConfig
            //    {
            //        Name = "p01",
            //        Label = "الموزع",
            //        Type = "select",
            //        Options = distributorOptions,
            //        ColCss = "3",
            //        Required = true
            //    },

            //    new FieldConfig
            //    {
            //        Name = "p02",
            //        Label = "الصلاحية",
            //        Type = "select",
            //        Options = new List<OptionItem> { new OptionItem { Value = "-1", Text = "اختر الموزع أولاً"     } }, //       Initial empty state
            //        ColCss = "3",
            //        Required = true,
            //        DependsOn = "p01",
            //        DependsUrl = "/crud/DDLFiltered?FK=distributorID_FK&textcol=permissionTypeName_A&ValueCol=distributorPermissionTypeID&PageName=Permission&TableIndex=4"
            //    },
            //    new FieldConfig { Name = "p03", Label = "تاريخ بداية الصلاحية", Type = "date", ColCss = "3", Required = false, Icon = "fa fa-calendar" },
            //    new FieldConfig { Name = "p04", Label = "تاريخ نهاية الصلاحية", Type = "date", ColCss = "3", Required = false, Icon = "fa fa-calendar" },
            //    new FieldConfig { Name = "p05", Label = "ملاحظات", Type = "textarea", ColCss = "6", Required = false },

            //      new FieldConfig { Name = "p06",Value=UserID_, Type = "hidden" },
            //      new FieldConfig { Name = "p07",Value=RoleID_, Type = "hidden" },

            //      new FieldConfig { Name = "p08", Value = p08Value as string, Type = "hidden" },
            //      new FieldConfig { Name = "p09",Value=Dept_, Type = "hidden" },
            //      new FieldConfig { Name = "p10",Value=Section_, Type = "hidden" },
            //      new FieldConfig { Name = "p11",Value=Divison_, Type = "hidden" },
            //      new FieldConfig { Name = "p12",Value=distributorID_, Type = "hidden" },
            //      new FieldConfig { Name = "p13",Value=SearchID_, Type = "hidden" },
            //};



            //// Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            //addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            //addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = HostName });
            //addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId });
            //addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId });
            //addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERT" }); // upper-case
            //addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });



            //// Optional: help the generic endpoint know where to go back

            //addFields.Insert(0, new FieldConfig { Name = "redirectUrl", Type = "hidden", Value = currentUrl });
            //addFields.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            //addFields.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });
            //addFields.Insert(0, new FieldConfig { Name = "UserID_", Type = "hidden", Value = UserID_ });




            //var addFields1 = new List<FieldConfig>
            //{
            //    // keep id hidden first so row id can flow when needed
            //    new FieldConfig { Name = rowIdField, Type = "hidden" },

            //    // your custom textboxes
            //    new FieldConfig
            //    {
            //        Name = "p01",
            //        Label = "الموزع",
            //        Type = "select",
            //        Options = distributorOptions,
            //        ColCss = "3",
            //        Required = true
            //    },

            //    new FieldConfig { Name = "p02", Label = "تاريخ بداية الصلاحية", Type = "date", ColCss = "3", Required = false,Icon = "fa fa-calendar" },
            //    new FieldConfig { Name = "p03", Label = "تاريخ نهاية الصلاحية", Type = "date", ColCss = "3", Required = false,Icon = "fa fa-calendar" },
            //    new FieldConfig { Name = "p04", Label = "ملاحظات", Type = "textarea", ColCss = "6", Required = false },

            //      new FieldConfig { Name = "p05",Value=UserID_, Type = "hidden" },
            //      new FieldConfig { Name = "p06",Value=RoleID_, Type = "hidden" },

            //      new FieldConfig { Name = "p07", Value = p08Value as string, Type = "hidden" },
            //      new FieldConfig { Name = "p08",Value=Dept_, Type = "hidden" },
            //      new FieldConfig { Name = "p09",Value=Section_, Type = "hidden" },
            //      new FieldConfig { Name = "p10",Value=Divison_, Type = "hidden" },
            //      new FieldConfig { Name = "p11",Value=distributorID_, Type = "hidden" },
            //      new FieldConfig { Name = "p12",Value=SearchID_, Type = "hidden" },
            //};



            //// Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            //addFields1.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            //addFields1.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = HostName });
            //addFields1.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = usersId });
            //addFields1.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraId });
            //addFields1.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERTFULLACCESS" }); // upper-case
            //addFields1.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });



            //// Optional: help the generic endpoint know where to go back
            //addFields1.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            //addFields1.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });
            //addFields1.Insert(0, new FieldConfig { Name = "redirectUrl", Type = "hidden", Value = currentUrl });
            //addFields1.Insert(0, new FieldConfig { Name = "UserID_", Type = "hidden", Value = UserID_ });





            //var updateFields = new List<FieldConfig>
            //{

            //    new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
            //    new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName },
            //    new FieldConfig { Name = "redirectUrl",  Type = "hidden", Value = currentUrl },
            //    new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
            //    new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "UPDATE" },
            //    new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId },
            //    new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId },
            //    new FieldConfig { Name = "hostname",            Type = "hidden", Value = HostName},
            //    new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
            //    new FieldConfig { Name = rowIdField,            Type = "hidden" },

            //    new FieldConfig { Name = "p01", Label = "المعرف",             Type = "hidden", Readonly = true, ColCss = "3" },
            //    new FieldConfig { Name = "p02", Label = "اسم الصفحة",         Type = "hidden", Required = true,  ColCss = "3" },
            //    new FieldConfig { Name = "p03", Label = "الصلاحية", Type = "hidden",   ColCss = "3", TextMode = "arabic" },
            //    // new FieldConfig
            //    //{
            //    //    Name = "p02",
            //    //    Label = "الموزع",
            //    //    Type = "select",
            //    //    Options = distributorOptions,
            //    //    ColCss = "3",
            //    //    Required = true,
            //    //},

            //    //new FieldConfig
            //    //{
            //    //    Name = "p03",
            //    //    Label = "الصلاحية",
            //    //    Type = "select",
            //    //    Options = new List<OptionItem> { new OptionItem { Value = "-1", Text = "اختر الموزع أولاً"     } }, //       Initial empty state
            //    //    ColCss = "3",
            //    //    Required = true,
            //    //    DependsOn = "p02",
            //    //    DependsUrl = "/crud/DDLFiltered?FK=distributorID_FK&textcol=permissionTypeName_A&ValueCol=distributorPermissionTypeID&PageName=Permission&TableIndex=4"
            //    //},
            //    new FieldConfig { Name = "p04", Label = "تاريخ بداية الصلاحية", Type = "date", Required = false, ColCss = "3",Icon = "fa fa-calendar" },
            //     new FieldConfig { Name = "p05", Label = "تاريخ نهاية الصلاحية", Type = "date", Required = false, ColCss = "3",Icon = "fa fa-calendar" },
            //    new FieldConfig { Name = "p06", Label = "ملاحظات",            Type = "textarea",   ColCss = "6" }
            //};


            //// Delete fields: show confirmation as a label (not textbox) and show ID as label while still posting p01
            //var deleteFields = new List<FieldConfig>
            //{

            //    new FieldConfig { Name = "pageName_",          Type = "hidden", Value = PageName },
            //    new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETE" },
            //    new FieldConfig { Name = "idaraID",            Type = "hidden", Value = IdaraId },
            //    new FieldConfig { Name = "entrydata",          Type = "hidden", Value = usersId },
            //    new FieldConfig { Name = "hostname",           Type = "hidden", Value = HostName },

            //    new FieldConfig { Name = "redirectUrl",     Type = "hidden", Value = currentUrl },
            //    new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = PageName },
            //    new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
            //    new FieldConfig { Name = "UserID_", Type = "hidden", Value = UserID_ },


            //    new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },

            //    // selection context
            //    new FieldConfig { Name = rowIdField, Type = "hidden" },

            //    // hidden p01 actually posted to SP
            //    new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "permissionID" }
            //};


            ////bool hasRows = dt1 is not null && dt1.Rows.Count > 0 && rowsList.Count > 0;

            //ViewBag.HideTable = false;
            //string.IsNullOrWhiteSpace(UserID_);

            // then create dsModel (snippet shows toolbar parts that use the dynamic lists)
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
                PageTitle = "إدارة الصلاحيات",
                PanelTitle = "إدارة الصلاحيات ",

                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowDelete = canDelete,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة صلاحية",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة صلاحية جديدة",
                        OpenForm = new FormConfig
                        {
                            FormId = "InsertForm",
                            Title = "بيانات الموظف الجديد",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = null,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success" /*Icon = "fa fa-save"*/ },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", /*Icon = "fa fa-times",*/ OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" },

                            }
                        }
                    },

                    Add1 = new TableAction
                    {
                        Label = "إضافة وصول كامل",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة وصول كامل",
                        OpenForm = new FormConfig
                        {
                            FormId = "InsertBackageForm",
                            Title = "إضافة وصول كامل",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = null,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success" /*Icon = "fa fa-save"*/ },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", /*Icon = "fa fa-times",*/ OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" },

                            }
                        }
                    },

                    // Edit: opens populated form for single selection and saves via SP
                    Edit = new TableAction
                    {
                        Label = "تعديل صلاحية",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل بيانات الموظف",
                        //ModalMessage = "بسم الله الرحمن الرحيم",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل بيانات الموظف",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = null
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1


                    },

                    Delete = new TableAction
                    {
                        Label = "ايقاف صلاحية",
                        Icon = "fa fa-trash",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        //ModalTitle = "رسالة تحذيرية",
                        ModalTitle = "<i class='fa fa-exclamation-triangle text-red-600 text-xl mr-2'></i> تحذير",
                        ModalMessage = "هل أنت متأكد من حذف هذا السجل؟",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeDeleteForm",
                            Title = "تأكيد حذف السجل",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حذف", Type = "submit", Color = "danger", Icon = "fa fa-save" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", Icon = "fa fa-times", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            },
                            Fields = null
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                }
            };

            //var vm = new FormTableViewModel
            //{
            //    Form = form,
            //    Table = dsModel,
            //    PageTitle = dsModel.PageTitle,
            //    PanelTitle = dsModel.PanelTitle
            //};
            //return View("Permission/Permission", vm);
            var vm = new SmartPageViewModel
            {
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle,
                PanelIcon = "fa-user-shield",
                Form = form,
                TableDS = dsModel
                //TableDS = ready ? dsModel : null

            };

            return View("HousingDefinitions/BuildingDetails", vm);
        }
    }
}
