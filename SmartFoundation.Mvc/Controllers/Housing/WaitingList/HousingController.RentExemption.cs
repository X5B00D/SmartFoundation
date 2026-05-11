using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using static System.Collections.Specialized.BitVector32;


namespace SmartFoundation.Mvc.Controllers.Housing
{
    public partial class HousingController : Controller
    {
        public async Task<IActionResult> RentExemption()
        {
            //  قراءة السيشن والكونتكست
            if (!InitPageContext(out var redirect))
                return redirect!;

            if (string.IsNullOrWhiteSpace(usersId))
            {
                return RedirectToAction("Index", "Login", new { logout = 4 });
            }

            string? NationalID_ = Request.Query["NID"].FirstOrDefault();

            ControllerName = nameof(Housing);
            PageName = string.IsNullOrWhiteSpace(PageName) ? "RentExemption" : PageName;

            var spParameters = new object?[]
            {
             PageName ?? "RentExemption",
             IdaraId,
             usersId,
             HostName,
             NationalID_
            };

           

            var rowsList = new List<Dictionary<string, object?>>();
            var rowsList_dt2 = new List<Dictionary<string, object?>>();

            var dynamicColumns = new List<TableColumn>();
            var dynamicColumns_dt2 = new List<TableColumn>();


            DataSet ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);

            //  تقسيم الداتا سيت للجدول الأول + جداول أخرى
            SplitDataSet(ds);


            

            //string residentInfoIdaraID = "";
            

            if (permissionTable is null || permissionTable.Rows.Count == 0)
            {
                TempData["Error"] = "تم رصد دخول غير مصرح به انت لاتملك صلاحية للوصول الى هذه الصفحة";
                return RedirectToAction("Index", "Home");
            }


            if (!string.IsNullOrWhiteSpace(NationalID_) && (dt1 == null || dt1.Rows.Count == 0))
            {
                TempData["Error"] = "صاحب الهوية رقم : " + NationalID_ +" غير ساكن حاليا";
                
            }




            string? residentInfoID_ = null;
            if (dt1 != null && dt1.Columns.Contains("residentInfoID") && dt1.Columns.Contains("residentInfoID"))
            {
                var row = dt1.AsEnumerable()
                    .FirstOrDefault(r => r["NationalID"] != DBNull.Value && r["NationalID"].ToString() == NationalID_);
                if (row != null)
                {
                    var val = row["residentInfoID"];
                    residentInfoID_ = val == DBNull.Value ? null : val.ToString();
                }
            }

            string? generalNo_FK_ = null;
            if (dt1 != null && dt1.Columns.Contains("generalNo_FK") && dt1.Columns.Contains("generalNo_FK"))
            {
                var row = dt1.AsEnumerable()
                    .FirstOrDefault(r => r["NationalID"] != DBNull.Value && r["NationalID"].ToString() == NationalID_);
                if (row != null)
                {
                    var val = row["generalNo_FK"];
                    generalNo_FK_ = val == DBNull.Value ? null : val.ToString();
                }
            }

            string? buildingDetailsNo_ = null;
            if (dt1 != null && dt1.Columns.Contains("buildingDetailsNo") && dt1.Columns.Contains("buildingDetailsNo"))
            {
                var row = dt1.AsEnumerable()
                    .FirstOrDefault(r => r["NationalID"] != DBNull.Value && r["NationalID"].ToString() == NationalID_);
                if (row != null)
                {
                    var val = row["buildingDetailsNo"];
                    buildingDetailsNo_ = val == DBNull.Value ? null : val.ToString();
                }
            }

            string? buildingDetailsID_ = null;
            if (dt1 != null && dt1.Columns.Contains("buildingDetailsID") && dt1.Columns.Contains("buildingDetailsID"))
            {
                var row = dt1.AsEnumerable()
                    .FirstOrDefault(r => r["NationalID"] != DBNull.Value && r["NationalID"].ToString() == NationalID_);
                if (row != null)
                {
                    var val = row["buildingDetailsID"];
                    buildingDetailsID_ = val == DBNull.Value ? null : val.ToString();
                }
            }



            string rowIdField = "";
            string rowIdField_dt2 = "";

            bool canADDRENTEXEMPTION = false;
            bool canEDITRENTEXEMPTION = false;
            bool canDELETERENTEXEMPTION = false;


           


            FormConfig form = new();


            List<OptionItem> ResidentRentExemptionTypeOptions = new();


            // ---------------------- DDLValues ----------------------




            JsonResult? result;
            string json;




            //// ---------------------- WaitingClass ----------------------
            result = await _CrudController.GetDDLValues(
                "ResidentRentExemptionTypeName_A", "ResidentRentExemptionTypeID", "3", nameof(RentExemption), usersId, IdaraId, HostName
           ) as JsonResult;


            json = JsonSerializer.Serialize(result!.Value);

            ResidentRentExemptionTypeOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;
          
            

            //// ---------------------- END DDL ----------------------

            try
            {

                form = new FormConfig
                {
                    Fields = new List<FieldConfig>
                    {
                                new FieldConfig
                                {
                                    SectionTitle= "نوع البحث",                 
                                    Label="البحث برقم الهوية الوطنية", 
                                    Name="NationalID",
                                    Type="text",
                                    ColCss="3",
                                    Icon="fa-solid fa-address-card",
                                    Placeholder="أدخل الرقم (مثال: 1xxxxxxxxx)",
                                    //HelpText="عشرةأرقام فقط*",
                                    Value= NationalID_,                 // القيمة الافتراضية (من السيرفر)
                                    MaxLength=10,
                                    Required=true,
                                    InputLang= "number",
                                    InputPattern= @"^[0-9]{10}$",
                                    PatternMsg= "رقم الهوية يجب أن يكون 10 أرقام",
                                    RequiredMsg= "الرجاء كتابة رقم الهوية الوطنية",
                                    IsNumericOnly=true,
                                    SubmitOnEnter =true,  // يفعل زر  Enter جديد
                                    // ===== زر داخل نفس الحقل =====
                                    InlineButton=true,               // تفعيل زر داخل الحقل
                                    InlineButtonText="بحـث",              // نص الزر
                                    InlineButtonIcon= "fa-solid fa-magnifying-glass",
                                    InlineButtonCss="btn btn-success", 
                                    InlineButtonPosition="end",              // مكان الزر (end / start)
                                    InlineButtonOnClickJs="sfNav(this)",      // استدعاء الدالة العامة )
                                    // ===== بيانات التنقل (sfNav) =====
                                    NavUrl="/Housing/RentExemption", // الصفحة الهدف
                                    NavKey="NID",                            // اسم باراميتر الـ QueryString

                                    }
                              }
                        };

                if (ds != null && ds.Tables.Count > 0 && permissionTable!.Rows.Count > 0)
                {
                    // صلاحيات
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "ADDRENTEXEMPTION") canADDRENTEXEMPTION = true;
                        if (permissionName == "EDITRENTEXEMPTION") canEDITRENTEXEMPTION = true;
                        if (permissionName == "DELETERENTEXEMPTION") canDELETERENTEXEMPTION = true;

                    }

                    if (dt1 != null && dt1.Columns.Count > 0)
                    {
                        // RowId
                        rowIdField = "residentInfoID";
                        var possibleIdNames = new[] { "residentInfoID", "ResidentInfoID", "Id", "ID" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt1.Columns.Contains(n))
                                     ?? dt1.Columns[0].ColumnName;

                        // عناوين الأعمدة بالعربي
                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["residentInfoID"] = "الرقم المرجعي",
                            ["NationalID"] = "رقم الهوية",
                            ["generalNo_FK"] = "الرقم العام",
                            ["rankNameA"] = "الرتبة",
                            ["militaryUnitName_A"] = "الوحدة",
                            ["maritalStatusName_A"] = "الحالة",
                            ["dependinceCounter"] = "التابعين",
                            ["nationalityName_A"] = "الجنسية",
                            ["genderName_A"] = "الجنس",
                            ["FullName_A"] = "الاسم بالعربي",
                            ["FullName_E"] = "الاسم بالانجليزي",
                            ["birthdate"] = "تاريخ الميلاد",
                            ["residentcontactDetails"] = "الجوال",
                            ["IdaraName"] = "موقع ملف المستفيد",
                            ["WaitingListCount"] = "عدد سجلات الانتظار",
                            ["WaitingListByLetterCount"] = "عدد خطابات التسكين",
                            ["note"] = "ملاحظات"
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

                            bool isfirstName_A = c.ColumnName.Equals("firstName_A", StringComparison.OrdinalIgnoreCase);
                            bool issecondName_A = c.ColumnName.Equals("secondName_A", StringComparison.OrdinalIgnoreCase);
                            bool isthirdName_A = c.ColumnName.Equals("thirdName_A", StringComparison.OrdinalIgnoreCase);
                            bool islastName_A = c.ColumnName.Equals("lastName_A", StringComparison.OrdinalIgnoreCase);
                            bool isfirstName_E = c.ColumnName.Equals("firstName_E", StringComparison.OrdinalIgnoreCase);
                            bool issecondName_E = c.ColumnName.Equals("secondName_E", StringComparison.OrdinalIgnoreCase);
                            bool isthirdName_E = c.ColumnName.Equals("thirdName_E", StringComparison.OrdinalIgnoreCase);
                            bool islastName_E = c.ColumnName.Equals("lastName_E", StringComparison.OrdinalIgnoreCase);
                            bool isrankID_FK = c.ColumnName.Equals("rankID_FK", StringComparison.OrdinalIgnoreCase);
                            bool ismilitaryUnitID_FK = c.ColumnName.Equals("militaryUnitID_FK", StringComparison.OrdinalIgnoreCase);
                            bool ismartialStatusID_FK = c.ColumnName.Equals("martialStatusID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isnationalityID_FK = c.ColumnName.Equals("nationalityID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isgenderID_FK = c.ColumnName.Equals("genderID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isresidentInfoID = c.ColumnName.Equals("residentInfoID", StringComparison.OrdinalIgnoreCase);
                            bool isFullName_E = c.ColumnName.Equals("FullName_E", StringComparison.OrdinalIgnoreCase);
                            bool isbirthdate = c.ColumnName.Equals("birthdate", StringComparison.OrdinalIgnoreCase);
                            bool isnote = c.ColumnName.Equals("note", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraID = c.ColumnName.Equals("IdaraID", StringComparison.OrdinalIgnoreCase);
                          

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                 ,
                                Visible = !(isfirstName_A || isfirstName_E || issecondName_A || issecondName_E || isthirdName_A || isthirdName_E || islastName_A || islastName_E || isrankID_FK || ismilitaryUnitID_FK || ismartialStatusID_FK || isnationalityID_FK || isgenderID_FK || isFullName_E || isbirthdate || isnote || isIdaraID|| isresidentInfoID)
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
                            dict["p01"] = Get("residentInfoID") ?? Get("ResidentInfoID");
                            dict["p02"] = Get("NationalID");
                            dict["p03"] = Get("generalNo_FK");
                            dict["p04"] = Get("firstName_A");
                            dict["p05"] = Get("secondName_A");
                            dict["p06"] = Get("thirdName_A");
                            dict["p07"] = Get("lastName_A");
                            dict["p08"] = Get("firstName_E");
                            dict["p09"] = Get("secondName_E");
                            dict["p10"] = Get("thirdName_E");
                            dict["p11"] = Get("lastName_E");
                            dict["p12"] = Get("FullName_A");
                            dict["p13"] = Get("FullName_E");
                            dict["p14"] = Get("rankID_FK");
                            dict["p15"] = Get("rankNameA");
                            dict["p16"] = Get("militaryUnitID_FK");
                            dict["p17"] = Get("militaryUnitName_A");
                            dict["p18"] = Get("martialStatusID_FK");
                            dict["p19"] = Get("maritalStatusName_A");
                            dict["p20"] = Get("dependinceCounter");
                            dict["p21"] = Get("nationalityID_FK");
                            dict["p22"] = Get("nationalityName_A");
                            dict["p23"] = Get("genderID_FK");
                            dict["p24"] = Get("genderName_A");
                            dict["p25"] = Get("birthdate");
                            dict["p26"] = Get("residentcontactDetails");
                            dict["p27"] = Get("note");

                            rowsList.Add(dict);
                        }
                    }

                    if (dt2 != null && dt2.Columns.Count > 0)
                    {
                        // RowId
                        rowIdField_dt2 = "residentRentExemptionID";
                        var possibleIdNames2 = new[] { "residentRentExemptionID", "ResidentRentExemptionID", "Id", "ID" };
                        rowIdField_dt2 = possibleIdNames2.FirstOrDefault(n => dt2.Columns.Contains(n))
                                     ?? dt2.Columns[0].ColumnName;

                        // عناوين الأعمدة بالعربي
                        var headerMap2 = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["residentRentExemptionID"] = "الرقم المرجعي",
                            ["residentRentExemptionLetterNo"] = "رقم قرار الاعفاء",
                            ["residentRentExemptionLetterDate"] = "تاريخ قرار الاعفاء",
                            ["residentRentExemptionStartDate"] = "بداية الاعفاء",
                            ["residentRentExemptionEndDate"] = "نهاية الاعفاء",
                            ["residentRentExemptionDescription"] = "ملاحظات",
                            ["ResidentRentExemptionTypeName_A"] = "نوع الاعفاء",
                            ["RentExemptionStatusText"] = "حالة الاعفاء",
                            ["buildingDetailsNo"] = "رقم المنزل",
                            ["ResidentRentExemptionTypePercentage"] = "نسبة الاعفاء من الايجار"
                        };

                        // الأعمدة
                        foreach (DataColumn c in dt2.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                            bool isresidentRentExemptionTypeID_FK = c.ColumnName.Equals("residentRentExemptionTypeID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isbuildingDetailsID = c.ColumnName.Equals("buildingDetailsID", StringComparison.OrdinalIgnoreCase);
                            bool isresidentRentExemptionActive = c.ColumnName.Equals("residentRentExemptionActive", StringComparison.OrdinalIgnoreCase);
                            bool isresidentInfoID_FK = c.ColumnName.Equals("residentInfoID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isIdaraID = c.ColumnName.Equals("idaraID_FK", StringComparison.OrdinalIgnoreCase);
                            bool isNationalID = c.ColumnName.Equals("NationalID", StringComparison.OrdinalIgnoreCase);
                            bool isgeneralNo_FK = c.ColumnName.Equals("generalNo_FK", StringComparison.OrdinalIgnoreCase);
                            bool isentryDate = c.ColumnName.Equals("entryDate", StringComparison.OrdinalIgnoreCase);
                            bool isentryData = c.ColumnName.Equals("entryData", StringComparison.OrdinalIgnoreCase);
                            bool isRentExemptionStatus = c.ColumnName.Equals("RentExemptionStatus", StringComparison.OrdinalIgnoreCase);
                            bool isResidentRentExemptionTypePercentage = c.ColumnName.Equals("ResidentRentExemptionTypePercentage", StringComparison.OrdinalIgnoreCase);
                            bool ishostName = c.ColumnName.Equals("hostName", StringComparison.OrdinalIgnoreCase);



                            dynamicColumns_dt2.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap2.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                 ,
                                Visible = !(isresidentRentExemptionTypeID_FK || isbuildingDetailsID || isresidentRentExemptionActive || isresidentInfoID_FK ||  isNationalID || isIdaraID || isgeneralNo_FK || isentryDate || isRentExemptionStatus || isResidentRentExemptionTypePercentage || ishostName || isentryData)
                            });
                        }

                        // الصفوف
                        foreach (DataRow r in dt2.Rows)
                        {
                            var dict2 = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt2.Columns)
                            {
                                var val = r[c];
                                dict2[c.ColumnName] = val == DBNull.Value ? null : val;
                            }

                            // p01..p05
                            object? Get(string key) => dict2.TryGetValue(key, out var v) ? v : null;
                            dict2["p01"] = Get("residentRentExemptionID") ?? Get("ResidentRentExemptionID");
                            dict2["p02"] = Get("residentRentExemptionTypeID_FK");
                            dict2["p03"] = Get("residentInfoID_FK");
                            dict2["p04"] = Get("residentRentExemptionActive");
                            dict2["p05"] = Get("residentRentExemptionStartDate");
                            dict2["p06"] = Get("residentRentExemptionEndDate");
                            dict2["p07"] = Get("residentRentExemptionDescription");
                            dict2["p08"] = Get("WaitingOrderTypeID");
                            dict2["p09"] = Get("idaraID_FK");
                            dict2["p10"] = Get("ResidentRentExemptionTypeName_A");
                            dict2["p11"] = Get("ResidentRentExemptionTypePercentage");
                            dict2["p12"] = Get("generalNo_FK");
                            dict2["p13"] = Get("NationalID");
                            dict2["p14"] = Get("residentRentExemptionLetterNo");
                            dict2["p15"] = Get("residentRentExemptionLetterDate");
                            dict2["p16"] = Get("buildingDetailsID");
                            dict2["p17"] = Get("buildingDetailsNo");


                            rowsList_dt2.Add(dict2);
                        }
                    }

                }
            }
            catch (Exception ex)
            {
                ViewBag.BuildingTypeDataSetError = ex.Message;
            }

            var currentUrl = Request.Path + Request.QueryString;


            // UPDATE fields
            var AddFieldsWaitingList = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "redirectUrl",  Type = "hidden", Value = currentUrl},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "ADDRENTEXEMPTION" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField_dt2,            Type = "hidden" },




                new FieldConfig { Name = "p03", Label = "residentInfoID_FK", Type = "hidden", ColCss = "6", Required = true,Value=residentInfoID_ }, 
                new FieldConfig { Name = "p13", Label = "رقم الهوية", Type = "hidden", ColCss = "6",Placeholder="1xxxxxxxxx",Value= NationalID_ },
                new FieldConfig { Name = "p12", Label = "الرقم العام", Type = "hidden", ColCss = "6", Required = true,Value=generalNo_FK_ },
                new FieldConfig { Name = "p16", Label = "buildingDetailsID_", Type = "text", ColCss = "6", Required = true,Value=buildingDetailsID_ },
                new FieldConfig { Name = "p17", Label = "buildingDetailsNo", Type = "text", ColCss = "6", Required = true,Value=buildingDetailsNo_ },



                new FieldConfig { Name = "p14", Label = "رقم القرار", Type = "text", ColCss = "4", MaxLength = 50,Required=true},
                new FieldConfig { Name = "p15", Label = "تاريخ القرار", Type = "date", ColCss = "4", MaxLength = 50 ,Required=true,Placeholder="YYYY-MM-DD"},
                new FieldConfig { Name = "p02", Label = "نوع الاعفاء", Type = "select", ColCss = "4", MaxLength = 50,Required=true,Options=ResidentRentExemptionTypeOptions},

                new FieldConfig { Name = "p05", Label = "تاريخ بداية الاعفاء", Type = "date", ColCss = "4", Required = true },
                new FieldConfig { Name = "p06", Label = "تاريخ نهاية الاعفاء", Type = "date", ColCss = "4", Required = false},
                new FieldConfig { Name = "p27", Label = "ملاحظات", Type = "textarea", ColCss = "4", Required = false },
            };



            var updateFieldsWaitingList = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "redirectUrl",  Type = "hidden", Value = currentUrl},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "EDITRENTEXEMPTION" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField_dt2,            Type = "hidden" },




                  new FieldConfig { Name = "p01", Label = "residentRentExemptionID", Type = "text", ColCss = "6", Required = true },
                new FieldConfig { Name = "p03", Label = "residentInfoID_FK", Type = "text", ColCss = "6", Required = true,Value=residentInfoID_ },
                new FieldConfig { Name = "p13", Label = "رقم الهوية", Type = "text", ColCss = "6",Placeholder="1xxxxxxxxx",Value= NationalID_ },
                new FieldConfig { Name = "p12", Label = "الرقم العام", Type = "text", ColCss = "6", Required = true,Value=generalNo_FK_ },
                new FieldConfig { Name = "p16", Label = "buildingDetailsID_", Type = "text", ColCss = "6", Required = true },
                new FieldConfig { Name = "p17", Label = "buildingDetailsNo", Type = "text", ColCss = "6", Required = true },




                new FieldConfig { Name = "p14", Label = "رقم القرار", Type = "text", ColCss = "4", MaxLength = 50,Required=true},
                new FieldConfig { Name = "p15", Label = "تاريخ القرار", Type = "date", ColCss = "4", MaxLength = 50 ,Required=true,Placeholder="YYYY-MM-DD"},
                new FieldConfig { Name = "p02", Label = "نوع الاعفاء", Type = "select", ColCss = "4", MaxLength = 50,Required=true,Options=ResidentRentExemptionTypeOptions},

                new FieldConfig { Name = "p05", Label = "تاريخ بداية الاعفاء", Type = "date", ColCss = "4", Required = true },
                new FieldConfig { Name = "p06", Label = "تاريخ نهاية الاعفاء", Type = "date", ColCss = "4", Required = false},
                new FieldConfig { Name = "p27", Label = "ملاحظات", Type = "textarea", ColCss = "4", Required = false },
            };



            // DELETE fields
            var deleteFieldsWaitingList = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName},
                new FieldConfig { Name = "redirectUrl",  Type = "hidden", Value = currentUrl},
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "DELETERENTEXEMPTION" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraId.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = usersId.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = Request.Host.Value },
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField_dt2,            Type = "hidden" },




                new FieldConfig { Name = "p01", Label = "residentRentExemptionID", Type = "text", ColCss = "6", Required = true },
                new FieldConfig { Name = "p03", Label = "residentInfoID_FK", Type = "text", ColCss = "6", Required = true,Value=residentInfoID_ },
                new FieldConfig { Name = "p13", Label = "رقم الهوية", Type = "text", ColCss = "6",Placeholder="1xxxxxxxxx",Value= NationalID_ },
                new FieldConfig { Name = "p12", Label = "الرقم العام", Type = "text", ColCss = "6", Required = true,Value=generalNo_FK_ },
                new FieldConfig { Name = "p16", Label = "buildingDetailsID_", Type = "text", ColCss = "6", Required = true },
                new FieldConfig { Name = "p17", Label = "buildingDetailsNo", Type = "text", ColCss = "6", Required = true },





                new FieldConfig { Name = "p14", Label = "رقم القرار", Type = "text", ColCss = "4", MaxLength = 50,Required=true},
                new FieldConfig { Name = "p15", Label = "تاريخ القرار", Type = "date", ColCss = "4", MaxLength = 50 ,Required=true,Placeholder="YYYY-MM-DD"},
                new FieldConfig { Name = "p02", Label = "نوع الاعفاء", Type = "select", ColCss = "4", MaxLength = 50,Required=true,Options=ResidentRentExemptionTypeOptions},

                new FieldConfig { Name = "p05", Label = "تاريخ بداية الاعفاء", Type = "date", ColCss = "4", Required = true },
                new FieldConfig { Name = "p06", Label = "تاريخ نهاية الاعفاء", Type = "date", ColCss = "4", Required = false},
                new FieldConfig { Name = "p27", Label = "ملاحظات", Type = "textarea", ColCss = "4", Required = false },

            };


       


            var dsModel = new SmartTableDsModel
            {
                PageTitle = "بيانات المستفيد",
                Columns = dynamicColumns,
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 200, },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = false, // جديد

                AllowExport = true,
                ShowRowBorders = false,
                PanelTitle = "بيانات المستفيد",
                EnablePagination = false, // جديد
                ShowPageSizeSelector = false, // جديد
                ShowToolbar = false,
                EnableCellCopy = false,
                //RenderAsToggle = true,
                //ToggleLabel = "بيانات المستفيد",
                //ToggleIcon = "fa-solid fa-list",
                //ToggleDefaultOpen = true,
                //ShowToggleCount = false,
                RenderMode = SmartTableRenderMode.Tab,
                RenderAsToggle = false,
                RenderAsSection = false,
                RenderAsTab = true,
                TabGroupKey = "waiting-list-by-resident",
                TabKey = "resident-info",
                TabLabel = "بيانات المستفيد",
                TabIcon = "fa-solid fa-user",
                TabDefaultActive = true,
                ShowTabCount = false,
                TabOrder = 1,

                ViewMode = TableViewMode.Table,
                Selectable = true,




                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canADDRENTEXEMPTION,
                    ShowEdit = canEDITRENTEXEMPTION ,
                    ShowEdit1 = canDELETERENTEXEMPTION ,
                    
                    ShowBulkDelete = false,

                
                }
            };

            var dsModel1 = new SmartTableDsModel
            {
                PageTitle = "اعفاء المستفيدين من الايجار",
                Columns = dynamicColumns_dt2,
                Rows = rowsList_dt2,
                RowIdField = rowIdField_dt2,
                PageSize = 10,
                PageSizes = new List<int> { 10, 25, 50, 200, },
                QuickSearchFields = dynamicColumns_dt2.Select(c => c.Field).Take(4).ToList(),
                Searchable = false, // جديد
                AllowExport = true,
                ShowRowBorders = false, 
                PanelTitle = "اعفاء المستفيدين من الايجار",
                EnablePagination = false, // جديد
                ShowPageSizeSelector=false, // جديد
                ShowToolbar = true,
                EnableCellCopy = false,
               
                RenderMode = SmartTableRenderMode.Tab,
                RenderAsToggle = false,
                RenderAsSection = false,
                RenderAsTab = true,
                TabGroupKey = "waiting-list-by-resident",
                TabKey = "resident-waiting-lists",
                TabLabel = "سجلات الاعفاء",
                TabIcon = "fa-solid fa-list",
                TabDefaultActive = false,
                ShowTabCount = true,
                TabOrder = 3,




                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,


                    ShowAdd = canADDRENTEXEMPTION,
                    ShowEdit = canEDITRENTEXEMPTION,
                    ShowDelete = canDELETERENTEXEMPTION,

                    ShowBulkDelete = false,
                    

       
                   
                    Add = new TableAction
                    {
                        Label = "اضافة اعفاء جديد",
                        Icon = "fa fa-plus",
                        Color = "success",
                        //Placement = TableActionPlacement.ActionsMenu,
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "اضافة اعفاء جديد",
                        ModalMessage = "ملاحظة: جميع التعديلات مرصودة",
                        ModalMessageIcon = "fa-solid fa-circle-info",
                        ModalMessageClass = "bg-sky-100 text-sky-700",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeEditForm",
                            Title = "اضافة اعفاء جديد",
                            Method = "post",
                            ActionUrl = "/crud/update",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = AddFieldsWaitingList
                        },
                       
                    },


                    Edit= new TableAction
                    {
                        Label = "تعديل سجل اعفاء",
                        Icon = "fa fa-trash",
                        Color = "warning",
                        //Placement = TableActionPlacement.ActionsMenu,
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تحذير",
                        ModalMessage = "هل أنت متأكد من تعديل سجل اعفاء؟",
                        ModalMessageIcon = "fa fa-exclamation-triangle text-red-600",
                        ModalMessageClass = "bg-red-50 text-red-700",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeDeleteForm",
                            Title = "تأكيد تعديل سجل اعفاء",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "تعديل", Type = "submit", Color = "success", },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            },
                            Fields = updateFieldsWaitingList
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },

                    Delete = new TableAction
                    {
                        Label = "الغاء سجل اعفاء",
                        Icon = "fa fa-trash",
                        Color = "danger",
                        //Placement = TableActionPlacement.ActionsMenu,
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تحذير",
                        ModalMessage = "هل أنت متأكد من الغاء سجل اعفاء؟",
                        ModalMessageIcon = "fa fa-exclamation-triangle text-red-600",
                        ModalMessageClass = "bg-red-50 text-red-700",
                        OpenForm = new FormConfig
                        {
                            FormId = "BuildingTypeDeleteForm",
                            Title = "تأكيد الغاء سجل اعفاء",
                            Method = "post",
                            ActionUrl = "/crud/delete",
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حذف", Type = "submit", Color = "danger", },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            },
                            Fields = deleteFieldsWaitingList
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                }
            };

        

      

            bool dsModelHasRows = dt1 != null && dt1.Rows.Count > 0;
            bool dsModel1HasRows = dt2 != null && dt2.Rows.Count > 0;


                ViewBag.dsModelHasRows = dsModelHasRows;
                ViewBag.dsModel1HasRows = dsModel1HasRows;

            
            //return View("HousingDefinitions/BuildingType", dsModel);

            var page = new SmartPageViewModel
            {
                PageTitle = dsModel1.PageTitle,
                PanelTitle = dsModel1.PanelTitle,
                PanelIcon = "fa fa-list",

                Form =form,
                TableDS = dsModelHasRows ? dsModel : null,
                TableDS1 = dsModelHasRows ? dsModel1 : null,


            };

            return View("WaitingList/RentExemption", page);

        }
    }
}