using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.DataEngine.Core.Models;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text.Json;
using System.Text.RegularExpressions;
using static System.Net.Mime.MediaTypeNames;



namespace SmartFoundation.Mvc.Controllers
{
    public class ControlPanel : Controller
    {

       // private readonly MastersDataLoadService _mastersDataLoadService;
        private readonly MastersServies _mastersServies;
        private readonly CrudController _CrudController;



        public ControlPanel(MastersServies mastersServies, CrudController crudController)
        {
           // _mastersDataLoadService = mastersDataLoadService;
            _mastersServies = mastersServies;
            _CrudController = crudController;

        }

        string? ControllerName;
        string? PageName;
        int userID;
        string? fullName;
        int IdaraID;
        string? DepartmentName;
        string? ThameName;
        string? DeptCode;
        string? IDNumber;
        string? HostName;

        
        DataSet ds;

        DataTable? permissionTable;
        DataTable? dt1;
        DataTable? dt2;
        DataTable? dt3;
        DataTable? dt4;
        DataTable? dt5;
        DataTable? dt6;
        DataTable? dt7;
        DataTable? dt8;
        DataTable? dt9;



        public async Task<IActionResult> Permission()
        {


            if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("userID")))
                return RedirectToAction("Index", "Login", new { logout = 1 });

            string? Q1 = Request.Query["Q1"].FirstOrDefault();
            string? Q2 = Request.Query["Q2"].FirstOrDefault();
            Q1 = string.IsNullOrWhiteSpace(Q1) ? null : Q1.Trim();
            Q2 = string.IsNullOrWhiteSpace(Q2) ? null : Q2.Trim();

            userID = Convert.ToInt32(HttpContext.Session.GetString("userID"));
             fullName = HttpContext.Session.GetString("fullName");
             IdaraID = Convert.ToInt32(HttpContext.Session.GetString("IdaraID"));
             DepartmentName = HttpContext.Session.GetString("DepartmentName");
             ThameName = HttpContext.Session.GetString("ThameName");
             DeptCode = HttpContext.Session.GetString("DeptCode");
             IDNumber = HttpContext.Session.GetString("IDNumber");
             HostName = HttpContext.Session.GetString("HostName");
             ControllerName = nameof(ControlPanel);
             PageName = nameof(Permission);

            var spParameters = new object?[] { "Permission", IdaraID, userID, HostName, Q1 };

            DataSet ds;


            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();


            ds = await _mastersServies.GetDataLoadDataSetAsync(spParameters);


           


            DataTable? permissionTable = (ds?.Tables?.Count ?? 0) > 0 ? ds.Tables[0] : null;

            //DataTable? rawDt1 = (ds?.Tables?.Count ?? 0) > 1 ? ds.Tables[1] : null;
            //if (rawDt1 != null)
            //{
            //    if (!string.IsNullOrWhiteSpace(Q1))
            //    {
            //        // Escape single quotes for DataView filter
            //        var escaped = Q1.Replace("'", "''");

            //        // Exact match (use LIKE '%value%' for contains)
            //        var view = new DataView(rawDt1)
            //        {
            //            RowFilter = $"userID = '{escaped}'"
            //            // RowFilter = $"buildingTypeName_A LIKE '%{escaped}%'" // contains alternative
            //        };
            //        dt1 = view.ToTable();
            //    }
            //    else
            //    {
            //        dt1 = rawDt1.Clone();
            //    }
            //}
            //else
            //{
            //    dt1 = null;
            //}

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
            bool canInsertFullAccess = false;
            bool canUpdate = false;
            bool canDelete = false;



            List<OptionItem> permissionsOptions = new();
            List<OptionItem> distributorOptions = new();
            List<OptionItem> UsersOptions = new();


            FormConfig form = new();
            try
            {

                // ---------------------- DDLValues ----------------------

                JsonResult? result;
                string json;

                // ---------------------- Users ----------------------
                result = await _CrudController.GetDDLValues(
                    "FullName", "userID_", "2", nameof(Permission), userID, IdaraID, HostName
                ) as JsonResult;

                json = JsonSerializer.Serialize(result!.Value);

                UsersOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;

                // ---------------------- Distributors ----------------------
                result = await _CrudController.GetDDLValues(
                    "distributorName_A", "distributorID", "3", nameof(Permission), userID, IdaraID, HostName
                ) as JsonResult;

                json = JsonSerializer.Serialize(result!.Value);

                distributorOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;

                // ---------------------- Distributors ----------------------
                result = await _CrudController.GetDDLValues(
                    "permissionTypeName_A", "distributorPermissionTypeID", "4", nameof(Permission), userID, IdaraID, HostName
                ) as JsonResult;

                json = JsonSerializer.Serialize(result!.Value);

                permissionsOptions = JsonSerializer.Deserialize<List<OptionItem>>(json)!;

                // ----------------------END DDLValues ----------------------





                form = new FormConfig
                {
                    FormId = "dynamicForm",
                    Title = "نموذج الإدخال",
                    Method = "POST",
                    //   ActionUrl = "/AllComponentsDemo/ExecuteDemo",
                    SubmitText = null,
                    

                    StoredProcedureName = "sp_SaveDemoForm",
                    Operation = "insert",
                    StoredSuccessMessageField = "Message",
                    StoredErrorMessageField = "Error",

                    Fields = new List<FieldConfig>
                {
                    // ========= البيانات الشخصية =========
                    

                    

                     new FieldConfig {
                         SectionTitle = "البحث عن مستخدم",
                         Name = "Users",
                         Type = "select",
                         Options = UsersOptions,
                         ColCss = "6",
                         Placeholder = "اختر المستخدم",
                         Icon = "fa fa-user",
                         Value = Q1,
                     },

                    //      new FieldConfig
                    //{


                    //    Name = "FullName",
                    //    Label = "إدخال نص",
                    //    Type = "text",
                    //    Required = true,
                    //    Placeholder = "حقل عربي فقط",
                    //    Icon = "fa-solid fa-user",
                    //    ColCss = "col-span-12 md:col-span-3",
                    //    MaxLength = 50,
                    //    TextMode = "text",
                    //    Value = filterNameAr,
                    //},


                        },


                    Buttons = new List<FormButtonConfig>
                {
                         new FormButtonConfig
                {
                    Text="بحث",
                    Icon="fa-solid fa-search",
                    Type="button",
                    Color="success",
                    // Replace the OnClickJs of the "تجربة" button with this:
                    OnClickJs = "(function(){"
              + "var hidden=document.querySelector('input[name=Users]');"
              + "if(!hidden){toastr.error('لا يوجد حقل مستخدم');return;}"
              + "var userId = (hidden.value||'').trim();"
              + "var anchor = hidden.parentElement.querySelector('.sf-select');"
              + "var userName = anchor && anchor.querySelector('.truncate') ? anchor.querySelector('.truncate').textContent.trim() : '';"
              + "if(!userId){toastr.info('اختر مستخدم أولاً');return;}"
              + "var url = '/ControlPanel/Permission?Q1=' + encodeURIComponent(userId);"
              + "window.location.href = url;"
              + "})();"
                },
             
              

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

                        if (permissionName == "INSERTFULLACCESS")
                            canInsertFullAccess = true;

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
                            ["permissionID"] = "المعرف",
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

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                //if u want to hide any column 
                                ,
                                Visible = !(isuserID)
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
                            dict["p01"] = Get("permissionID") ?? Get("permissionID") ?? Get("Id") ?? Get("ID");
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

            }


            // Local helper: map TableColumn -> FieldConfig


            // Local helper: build Edit1 fields (prefer dataset column for general number or fallback)

            // build dynamic field lists
            // REPLACE Add form fields: hide dataset textboxes and use your own custom inputs

            //ADD
            var addFields = new List<FieldConfig>
            {
                // keep id hidden first so row id can flow when needed
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // your custom textboxes
                new FieldConfig
                {
                    Name = "p01",
                    Label = "الموزع",
                    Type = "select",
                    Options = distributorOptions,
                    ColCss = "3",
                    Required = true
                },
                
                new FieldConfig
                {
                    Name = "p02",
                    Label = "الصلاحية",
                    Type = "select",
                    Options = new List<OptionItem> { new OptionItem { Value = "-1", Text = "اختر الموزع أولاً"     } }, //       Initial empty state
                    ColCss = "3",
                    Required = true,
                    DependsOn = "p01",          
                    DependsUrl = "/crud/DDLFiltered?FK=distributorID_FK&textcol=permissionTypeName_A&ValueCol=distributorPermissionTypeID&PageName=Permission&TableIndex=4"
                },
                new FieldConfig { Name = "p03", Label = "تاريخ بداية الصلاحية", Type = "date", ColCss = "3", Required = false },
                new FieldConfig { Name = "p04", Label = "تاريخ نهاية الصلاحية", Type = "date", ColCss = "3", Required = false },
                new FieldConfig { Name = "p05", Label = "ملاحظات", Type = "text", ColCss = "3", Required = false },

                  new FieldConfig { Name = "p06",Value=Q1, Type = "hidden" },
            };



            // Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = HostName });
            addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = userID.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraID.ToString() });
            addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERT" }); // upper-case
            addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });



            // Optional: help the generic endpoint know where to go back
            addFields.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            addFields.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });
            addFields.Insert(0, new FieldConfig { Name = "Q1", Type = "hidden", Value = Q1 });




            var addFields1 = new List<FieldConfig>
            {
                // keep id hidden first so row id can flow when needed
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // your custom textboxes
                new FieldConfig
                {
                    Name = "p01",
                    Label = "الموزع",
                    Type = "select",
                    Options = distributorOptions,
                    ColCss = "3",
                    Required = true
                },

                new FieldConfig { Name = "p02", Label = "تاريخ بداية الصلاحية", Type = "date", ColCss = "3", Required = false },
                new FieldConfig { Name = "p03", Label = "تاريخ نهاية الصلاحية", Type = "date", ColCss = "3", Required = false },
                new FieldConfig { Name = "p04", Label = "ملاحظات", Type = "text", ColCss = "3", Required = false },

                  new FieldConfig { Name = "p05",Value=Q1, Type = "hidden" },
            };



            // Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            addFields1.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields1.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = HostName });
            addFields1.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = userID.ToString() });
            addFields1.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = IdaraID.ToString() });
            addFields1.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERTFULLACCESS" }); // upper-case
            addFields1.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = PageName });



            // Optional: help the generic endpoint know where to go back
            addFields1.Insert(0, new FieldConfig { Name = "redirectAction", Type = "hidden", Value = PageName });
            addFields1.Insert(0, new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName });
            addFields1.Insert(0, new FieldConfig { Name = "Q1", Type = "hidden", Value = Q1 });




            var updateFields = new List<FieldConfig>
            {
                new FieldConfig { Name = "redirectAction",      Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController",  Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "pageName_",           Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",          Type = "hidden", Value = "UPDATE" },
                new FieldConfig { Name = "idaraID",             Type = "hidden", Value = IdaraID.ToString() },
                new FieldConfig { Name = "entrydata",           Type = "hidden", Value = userID.ToString() },
                new FieldConfig { Name = "hostname",            Type = "hidden", Value = HostName},
                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },
                new FieldConfig { Name = rowIdField,            Type = "hidden" },

                new FieldConfig { Name = "p01", Label = "المعرف",             Type = "hidden", Readonly = true, ColCss = "3" },
                new FieldConfig { Name = "p02", Label = "اسم الصفحة",         Type = "text", Required = true,  ColCss = "3" },
                new FieldConfig { Name = "p03", Label = "الصلاحية", Type = "text",   ColCss = "3", TextMode = "arabic" },
                new FieldConfig { Name = "p04", Label = "تاريخ بداية الصلاحية", Type = "date", Required = true, ColCss = "3" },
                 new FieldConfig { Name = "p05", Label = "تاريخ نهاية الصلاحية", Type = "date", Required = true, ColCss = "3" },
                new FieldConfig { Name = "p06", Label = "ملاحظات",            Type = "text",   ColCss = "6" }
            };


            // Delete fields: show confirmation as a label (not textbox) and show ID as label while still posting p01
            var deleteFields = new List<FieldConfig>
            {

                new FieldConfig { Name = "pageName_",          Type = "hidden", Value = PageName },
                new FieldConfig { Name = "ActionType",         Type = "hidden", Value = "DELETE" },
                new FieldConfig { Name = "idaraID",            Type = "hidden", Value = IdaraID.ToString() },
                new FieldConfig { Name = "entrydata",          Type = "hidden", Value = userID.ToString() },
                new FieldConfig { Name = "hostname",           Type = "hidden", Value = HostName },

                                new FieldConfig { Name = "redirectAction",     Type = "hidden", Value = PageName },
                new FieldConfig { Name = "redirectController", Type = "hidden", Value = ControllerName },
                new FieldConfig { Name = "Q1", Type = "hidden", Value = Q1 },


                new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") },

                // selection context
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // hidden p01 actually posted to SP
                new FieldConfig { Name = "p01", Type = "hidden", MirrorName = "permissionID" }
            };


            //bool hasRows = dt1 is not null && dt1.Rows.Count > 0 && rowsList.Count > 0;

            ViewBag.HideTable = string.IsNullOrWhiteSpace(Q1);

            // then create dsModel (snippet shows toolbar parts that use the dynamic lists)
            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
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
                PanelTitle = "عرض ",
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = false,
                    ShowExportExcel = false,
                    ShowAdd = canInsert,
                    ShowAdd1 = canInsertFullAccess,
                    ShowEdit = canUpdate,
                    ShowDelete = canDelete,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة صلاحية",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة صلاحية جديد",
                        OpenForm = new FormConfig
                        {
                            FormId = "InsertForm",
                            Title = "بيانات الموظف الجديد",
                            Method = "post",
                            ActionUrl = "/crud/insert",
                            Fields = addFields,
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
                            Fields = addFields1,
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
                            Fields = updateFields
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
                            Fields = deleteFields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },
                }
            };

            var vm = new SmartFoundation.UI.ViewModels.SmartPage.FormTableViewModel
            {
                Form = form,
                Table = dsModel,
                PageTitle = dsModel.PageTitle,
                PanelTitle = dsModel.PanelTitle
            };
            return View("Permission", vm);
        }



        public IActionResult Index()

        {
            return View();
        }

        public IActionResult ssss()

        {
            var baseUrl = Url.Action(PageName, ControllerName) ?? "/";
            return Redirect(baseUrl);
        }


        // Add an endpoint that returns permissions options filtered by distributorID_FK
        //[HttpGet]
        //public async Task<IActionResult> PermissionsByDistributor1(string p01) // Changed from int distributorId
        //{


        //    if (string.IsNullOrWhiteSpace(HttpContext.Session.GetString("userID")))
        //        return Unauthorized();

        //    if (!int.TryParse(p01, out int distributorId) || distributorId == -1)
        //        return Json(new List<object> { new { value = "-1", text = "الرجاء الاختيار" } });

        //    int userID = Convert.ToInt32(HttpContext.Session.GetString("userID"));
        //    int IdaraID = Convert.ToInt32(HttpContext.Session.GetString("IdaraID"));
        //    string HostName = HttpContext.Session.GetString("HostName");

        //    var ds = await _mastersServies.GetDataLoadDataSetAsync("Permission", IdaraID, userID, HostName);
        //    var table = (ds?.Tables?.Count ?? 0) > 4 ? ds.Tables[4] : null;

        //    var items = new List<object>();
        //    if (table is not null && table.Rows.Count > 0 && table.Columns.Contains("distributorID_FK"))
        //    {
        //        foreach (DataRow row in table.Rows)
        //        {
        //            var fk = row["distributorID_FK"]?.ToString()?.Trim();
        //            if (fk == distributorId.ToString())
        //            {
        //                var value = row["distributorPermissionTypeID"]?.ToString()?.Trim() ?? "";
        //                var text = row["permissionTypeName_A"]?.ToString()?.Trim() ?? "";
        //                if (!string.IsNullOrEmpty(value))
        //                    items.Add(new { value, text });
        //            }
        //        }
        //    }

        //    if (!items.Any())
        //        items.Add(new { value = "-1", text = "لا توجد صلاحيات لهذا الموزع" });

        //    return Json(items);
        //}


    }
}