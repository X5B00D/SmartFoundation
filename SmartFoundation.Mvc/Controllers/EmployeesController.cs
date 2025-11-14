using Microsoft.AspNetCore.Mvc;
using SmartFoundation.Application.Services;
using SmartFoundation.Mvc.Models;
using SmartFoundation.UI.ViewModels.SmartForm;
using SmartFoundation.UI.ViewModels.SmartPage;
using SmartFoundation.UI.ViewModels.SmartTable;
using System.Data;
using System.Text.Json;
using System.Linq; 

namespace SmartFoundation.Mvc.Controllers
{
    public class EmployeesController : Controller
    {
        private readonly MastersDataLoadService _mastersDataLoadService;
        private readonly MastersCrudServies _mastersCrudServies;

        bool canInsert = false;
        bool canUpdate = false;
        bool canUpdateGN = false;

        public EmployeesController(MastersDataLoadService mastersDataLoadService, MastersCrudServies mastersCrudServies)
        {
            _mastersDataLoadService = mastersDataLoadService;
            _mastersCrudServies = mastersCrudServies;
           
        }


        public async Task<IActionResult> Sami()
        {
            
            var spParameters = new object?[]{"BuildingType",1,60014016,"hostname"};


            DataSet ds = await _mastersDataLoadService.GetDataLoadDataSetAsync(spParameters);
            List<OptionItem> cityOptions = new();


            var rowsList = new List<Dictionary<string, object?>>();
            var dynamicColumns = new List<TableColumn>();
            string rowIdField = "Id";


            try
            {

                if (ds != null && ds.Tables.Count > 1 && ds.Tables[1].Rows.Count > 0)
                {
                    var cityTable = ds.Tables[2];

                    foreach (DataRow row in cityTable.Rows)
                    {
                        string value = row["cityID"]?.ToString()?.Trim() ?? "";
                        string text = row["cityName_A"]?.ToString()?.Trim() ?? "";

                        if (!string.IsNullOrEmpty(value))
                            cityOptions.Add(new OptionItem { Value = value, Text = text });
                    }
                }
               

                ViewBag.EmployeeDataSet = ds;

                // <-- new: pass table count to the view so client-side JS can show an alert
                ViewBag.EmployeeTableCount = ds?.Tables?.Count ?? 0;

                if (ds != null && ds.Tables.Count > 0 && ds.Tables[0].Rows.Count > 0)
                {
                    // اقرأ الجدول الأول
                    var permissionTable = ds.Tables[0];

                    // نبحث عن صلاحيات محددة داخل الجدول
                    foreach (DataRow row in permissionTable.Rows)
                    {
                        var permissionName = row["permissionTypeName_E"]?.ToString()?.Trim().ToUpper();

                        if (permissionName == "INSERT")
                            canInsert = true;

                        if (permissionName == "UPDATE")
                            canUpdate = true;

                        if (permissionName == "UPDATEGN" || permissionName == "UPDATEGN")
                            canUpdateGN = true;
                    }


                    if (ds != null && ds.Tables.Count > 0)
                    {
                        var dt = ds.Tables[1];

                        // pick a sensible row id field if present
                        var possibleIdNames = new[] { "EmployeeId", "Id", "ID", "employeeId", "id" };
                        rowIdField = possibleIdNames.FirstOrDefault(n => dt.Columns.Contains(n))
                                     ?? (dt.Columns.Count > 0 ? dt.Columns[0].ColumnName : "Id");


                        var headerMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                        {
                            ["buildingTypeID"] = "المعرف",
                            ["buildingTypeCode"] = "رمز المبنى",
                            ["buildingTypeName_A"] = "اسم المبنى بالعربي",
                            ["buildingTypeName_E"] = "اسم المبنى بالانجليزي",
                            ["buildingTypeDescription"] = "ملاحظات"
                        };


                        // build columns from DataTable schema
                        foreach (DataColumn c in dt.Columns)
                        {
                            string colType = "text";
                            var t = c.DataType;
                            if (t == typeof(bool)) colType = "bool";
                            else if (t == typeof(DateTime)) colType = "date";
                            else if (t == typeof(byte) || t == typeof(short) || t == typeof(int) || t == typeof(long)
                                     || t == typeof(float) || t == typeof(double) || t == typeof(decimal))
                                colType = "number";

                                bool isFullNameColumn = c.ColumnName.Equals("FullName", StringComparison.OrdinalIgnoreCase);

                            dynamicColumns.Add(new TableColumn
                            {
                                Field = c.ColumnName,
                                Label = headerMap.TryGetValue(c.ColumnName, out var label) ? label : c.ColumnName,
                                Type = colType,
                                Sortable = true
                                //,
                               // Visible = !(isFullNameColumn)
                            });
                        }

                        // build rows (plain dictionaries) so JSON serialization is clean
                        foreach (DataRow r in dt.Rows)
                        {
                            var dict = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                            foreach (DataColumn c in dt.Columns)
                            {
                                var val = r[c];
                                dict[c.ColumnName] = val == DBNull.Value ? null : val;
                            }
                            rowsList.Add(dict);
                        }
                    }


                }
            }
            catch (Exception ex)
            {
                ViewBag.EmployeeDataSetError = ex.Message;

                ViewBag.EmployeeTableCount = 0;
            }


            // Local helper: map TableColumn -> FieldConfig
            List<FieldConfig> BuildFieldsFromColumns(List<TableColumn> cols, string idField)
            {
                var list = new List<FieldConfig>();

                // ensure id hidden field is first
                list.Add(new FieldConfig { Name = idField, Type = "hidden" });

                foreach (var col in cols)
                {
                    if (string.Equals(col.Field, idField, StringComparison.OrdinalIgnoreCase))
                        continue;

                    var fc = new FieldConfig
                    {
                        Name = col.Field,
                        Label = string.IsNullOrWhiteSpace(col.Label) ? col.Field : col.Label,
                        ColCss = "3"
                    };

                    // map column type to field type with simple heuristics
                    switch ((col.Type ?? "text").ToLowerInvariant())
                    {
                        case "number":
                        case "int":
                        case "decimal":
                            fc.Type = "number";
                            fc.TextMode = "number";
                            break;
                        case "date":
                        case "datetime":
                            fc.Type = "date";
                            break;
                        case "bool":
                        case "boolean":
                            fc.Type = "checkbox";
                            break;
                        default:
                            fc.Type = "text";
                            break;
                    }

                    // name-based heuristics
                    var name = col.Field.ToLowerInvariant();
                    if (name.Contains("email"))
                    {
                        fc.TextMode = "email";
                    }
                    if (name.Contains("phone") || name.Contains("mobile"))
                    {
                        fc.Type = "phone";
                    }
                    if (name.Contains("iban"))
                    {
                        fc.Type = "iban";
                        fc.IsIban = true;
                    }
                    if (name == "city" || name.EndsWith("cityid"))
                    {
                        fc.Type = "select";
                        fc.Options = cityOptions; // reuse city options loaded from dataset
                    }

                    list.Add(fc);
                }

                return list;
            }

            // Local helper: build Edit1 fields (prefer dataset column for general number or fallback)
            List<FieldConfig> BuildEdit1Fields(List<TableColumn> cols, string idField)
            {
                var fields = new List<FieldConfig> { new FieldConfig { Name = idField, Type = "hidden" } };

                // try to find a "general number" column
                var gnCol = cols.FirstOrDefault(c => 
                    c.Field.Equals("GeneralNo", StringComparison.OrdinalIgnoreCase)  || c.Field.Equals("EmployeeId", StringComparison.OrdinalIgnoreCase) ||
                    c.Field.IndexOf("general", StringComparison.OrdinalIgnoreCase) >= 0 && c.Field.IndexOf("num", StringComparison.OrdinalIgnoreCase) >= 0
                );

                if (gnCol != null)
                {
                    fields.AddRange(BuildFieldsFromColumns(new List<TableColumn> { gnCol }, idField).Skip(1)); // skip duplicate id
                }
                else
                {
                    // fallback field
                    fields.Add(new FieldConfig { Name = "GeneralNumber", Label = "الرقمb العام", Type = "text", ColCss = "3", Required = true });
                }

                // include Notes if present in dataset
                //if (cols.Any(c => c.Field.Equals("Notes", StringComparison.OrdinalIgnoreCase)))
                //{
                //    fields.Add(new FieldConfig { Name = "Notes", Label = "ملاحظة", Type = "textarea", ColCss = "6" });
                //}
                //else
                //{
                //    fields.Add(new FieldConfig { Name = "Notes", Label = "ملاحظة", Type = "textarea", ColCss = "6" });
                //}

                return fields;
            }

            // build dynamic field lists
            // REPLACE Add form fields: hide dataset textboxes and use your own custom inputs
            var addFields = new List<FieldConfig>
            {
                // keep id hidden first so row id can flow when needed
                new FieldConfig { Name = rowIdField, Type = "hidden" },

                // your custom textboxes
                new FieldConfig { Name = "p01", Label = "رمز المبنى", Type = "number", ColCss = "3", Required = true },
                new FieldConfig { Name = "p02", Label = "اسم المبنى بالعربي", Type = "text", ColCss = "3" , Required = false},
                new FieldConfig { Name = "p03", Label = "اسم المبنى بالانجليزي", Type = "text", ColCss = "3" , Required = true},
                new FieldConfig { Name = "p04", Label = "ملاحظات", Type = "text", ColCss = "3", Required = false }
            };

            var editFields = BuildFieldsFromColumns(dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>(), rowIdField);
            var edit1Fields = BuildEdit1Fields(dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>(), rowIdField);

            // Inject required hidden headers for the add (insert) form BEFORE building dsModel:
            addFields.Insert(0, new FieldConfig { Name = "__RequestVerificationToken", Type = "hidden", Value = (Request.Headers["RequestVerificationToken"].FirstOrDefault() ?? "") });
            addFields.Insert(0, new FieldConfig { Name = "hostname", Type = "hidden", Value = Request.Host.Value });
            addFields.Insert(0, new FieldConfig { Name = "entrydata", Type = "hidden", Value = "60014016" });
            addFields.Insert(0, new FieldConfig { Name = "idaraID", Type = "hidden", Value = "1" });
            addFields.Insert(0, new FieldConfig { Name = "ActionType", Type = "hidden", Value = "INSERT" }); // upper-case
            addFields.Insert(0, new FieldConfig { Name = "pageName_", Type = "hidden", Value = "BuildingType" });

            // HIDE existing buildingTypeCode field in Add form (still present, not shown)
            var btcField = addFields.FirstOrDefault(f => f.Name.Equals("buildingTypeCode", StringComparison.OrdinalIgnoreCase));
            if (btcField != null)
            {
                btcField.Type = "hidden";
            }

            // Append new text field AFTER all other fields
           
            // then create dsModel (snippet shows toolbar parts that use the dynamic lists)
            var dsModel = new SmartFoundation.UI.ViewModels.SmartTable.SmartTableDsModel
            {
                Columns = dynamicColumns.Count > 0 ? dynamicColumns : new List<TableColumn>
                {
                    new TableColumn { Field="EmployeeId", Label="ID", Type="number", Width="80px", Align="center", Sortable=true },
                    new TableColumn { Field="FullName", Label="الاسم الكامل", Type="text", Sortable=true },
                    new TableColumn { Field="Email", Label="البريد الإلكتروني", Type="link", LinkTemplate="mailto:{Email}", Sortable=true },
                    new TableColumn { Field="PhoneNumber", Label="الجوال", Type="text", Sortable=true },
                    new TableColumn { Field="City", Label="المدينة", Sortable=true }
                },
                Rows = rowsList,
                RowIdField = rowIdField,
                PageSize = 10,
                PageSizes = new List<int> { 5, 10, 25, 50, 100 },
                QuickSearchFields = dynamicColumns.Select(c => c.Field).Take(4).ToList(),
                Searchable = true,
                AllowExport = true,
                Toolbar = new TableToolbarConfig
                {
                    ShowRefresh = false,
                    ShowColumns = true,
                    ShowExportCsv = true,
                    ShowExportExcel = true,
                    ShowAdd = canInsert,
                    ShowEdit = canUpdate,
                    ShowEdit1 = canUpdateGN,
                    ShowBulkDelete = false,

                    Add = new TableAction
                    {
                        Label = "إضافة موظف",
                        Icon = "fa fa-plus",
                        Color = "success",
                        OpenModal = true,
                        ModalTitle = "إضافة موظف",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeInsertForm",
                            Title = "بيانات الموظف الجديد",
                            Method = "post",
                            ActionUrl = "/employees/insert", // <-- added
                            SubmitText = "حفظ",
                            CancelText = "إلغاء",
                            Fields = addFields,
                            Buttons = new List<FormButtonConfig>
                            {
                                new FormButtonConfig { Text = "حفظ", Type = "submit", Color = "success", Icon = "fa fa-save" },
                                new FormButtonConfig { Text = "إلغاء", Type = "button", Color = "secondary", Icon = "fa fa-times", OnClickJs = "this.closest('.sf-modal').__x.$data.closeModal();" }
                            }
                        }
                        
                    },

                    // Edit: opens populated form for single selection and saves via SP
                    Edit = new TableAction
                    {
                        Label = "تعديل موظف",
                        Icon = "fa fa-pen-to-square",
                        Color = "info",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل بيانات الموظف",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditForm",
                            Title = "تعديل بيانات الموظف",
                            ActionUrl = "/smart/execute",
                            StoredProcedureName = "dbo.sp_SmartFormDemo",
                            Operation = "update_employee",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = editFields
                        },
                        SaveSp = "dbo.sp_SmartFormDemo",
                        SaveOp = "update_employee",
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    },

                    // Edit1: alternate edit (e.g., update general number) — similar wiring
                    Edit1 = new TableAction
                    {
                        Label = "تعديل الرقم العام",
                        Icon = "fa fa-pen-to-square",
                        Color = "danger",
                        IsEdit = true,
                        OpenModal = true,
                        ModalTitle = "تعديل الرقم العام",
                        OpenForm = new FormConfig
                        {
                            FormId = "employeeEditGNForm",
                            Title = "تعديل الرقم العام",
                            SubmitText = "حفظ التعديلات",
                            CancelText = "إلغاء",
                            Fields = edit1Fields
                        },
                        RequireSelection = true,
                        MinSelection = 1,
                        MaxSelection = 1
                    }
                }
            };

            return View("Sami", dsModel);
        }




        public IActionResult Index()
        {
            return View();
        }


        public IActionResult EmployeeFields(int? id)
        {
            return Content("<div class='p-4 text-gray-700'>هنا يمكن وضع فورم التعديل لاحقاً</div>", "text/html");
        }

        // 1) Add a POST action that reads all fields from employeeInsertForm and builds the object?[] array:
        [HttpPost]
        [Route("employees/insert")]
        public async Task<IActionResult> InsertEmployee()
        {
            try
            {
                var f = Request.Form;

                // Always provide required SP headers (do not rely on posted values)
                string pageName   = "BuildingType";
                string actionType = "INSERT";
                int? idaraID      = f.TryGetValue("idaraID", out var idv) && int.TryParse(idv, out var idParsed) ? idParsed : 1;
                int? entryData    = f.TryGetValue("entrydata", out var edv) && int.TryParse(edv, out var entryParsed) ? entryParsed : 60014016;
                string hostName   = Request.Host.Value;

                var parameters = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                {
                    ["pageName_"] = pageName,                 // guaranteed non-empty
                    ["ActionType"] = actionType,              // guaranteed non-empty
                    ["idaraID"] = idaraID,
                    ["entrydata"] = entryData,
                    ["hostname"] = hostName                   // guaranteed non-empty
                };

                // Map p01..p50 => parameter_01..parameter_50
                // Empty or missing inputs are sent as DBNull.Value (not removed by the engine)
                for (int idx = 1; idx <= 50; idx++)
                {
                    var key = $"p{idx:00}";
                    if (f.TryGetValue(key, out var val))
                    {
                        var s = val.ToString();
                        parameters[$"parameter_{idx:00}"] = string.IsNullOrWhiteSpace(s) ? DBNull.Value : s;
                    }
                    else
                    {
                        parameters[$"parameter_{idx:00}"] = DBNull.Value;
                    }
                }

                var dsInsert = await _mastersCrudServies.GetCrudDataSetAsync(parameters);

                string? message = null;
                bool? isSuccess = null;

                foreach (DataTable t in dsInsert.Tables)
                {
                    if (t.Rows.Count == 0) continue;
                    var row = t.Rows[0];

                    var msgCol = t.Columns.Cast<DataColumn>()
                        .FirstOrDefault(c =>
                            string.Equals(c.ColumnName, "Message_", StringComparison.OrdinalIgnoreCase) ||
                            string.Equals(c.ColumnName, "Message", StringComparison.OrdinalIgnoreCase) ||
                            string.Equals(c.ColumnName, "SuccessMessage", StringComparison.OrdinalIgnoreCase));

                    if (msgCol != null && row[msgCol] != DBNull.Value)
                        message = row[msgCol]?.ToString();

                    var succCol = t.Columns.Cast<DataColumn>()
                        .FirstOrDefault(c =>
                            string.Equals(c.ColumnName, "IsSuccessful", StringComparison.OrdinalIgnoreCase) ||
                            string.Equals(c.ColumnName, "Success", StringComparison.OrdinalIgnoreCase));

                    if (succCol != null && row[succCol] != DBNull.Value)
                    {
                        var v = row[succCol];
                        if (v is bool b) isSuccess = b;
                        else if (v is int intVal) isSuccess = intVal != 0;
                        else if (v is string s) isSuccess = s == "1" || s.Equals("true", StringComparison.OrdinalIgnoreCase) || s.Equals("Y", StringComparison.OrdinalIgnoreCase);
                    }

                    if (!string.IsNullOrWhiteSpace(message) || isSuccess.HasValue)
                        break;
                }

                if (isSuccess == true)
                {
                    TempData["InsertMessage"] = message ?? "Success";
                }
                else if (isSuccess == false)
                {
                    TempData["CrudError"] = message ?? "Insert failed.";
                }
                else
                {
                    TempData["InsertMessage"] = message ?? "تمت عملية الإدخال (لا توجد رسالة من المخزن).";
                }
            }
            catch (Exception ex)
            {
                TempData["CrudError"] = "Insert failed: " + ex.Message;
            }

            return RedirectToAction(nameof(Sami));
        }
    }
}
