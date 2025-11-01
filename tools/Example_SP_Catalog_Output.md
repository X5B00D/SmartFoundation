# Example Stored Procedure Catalog Output

This CSV demonstrates the expected output from Extract-StoredProcedures.ps1

```csv
"ControllerName","FileName","SPName","LineNumber","Pattern","Category","UsesMapper"
"HomeController","HomeController.cs","dbo.sp_GetDashboardSummary","42","SmartRequest","Read","False"
"HomeController","HomeController.cs","dbo.ListOfMenuByUser_MVC","58","ExecuteAsync","List","False"
"EmployeesController","EmployeesController.cs","employee:list","35","ProcedureMapper","Mapped","True"
"EmployeesController","EmployeesController.cs","employee:insert","78","ProcedureMapper","Mapped","True"
"EmployeesController","EmployeesController.cs","dbo.sp_GetEmployeeDetails","102","DirectAssignment","Read","False"
"ProductController","ProductController.cs","dbo.sp_GetProducts","25","SmartRequest","Read","False"
"ProductController","ProductController.cs","dbo.sp_InsertProduct","45","ExecuteAsync","Create","False"
"ProductController","ProductController.cs","dbo.sp_UpdateProduct","67","ExecuteAsync","Update","False"
"ProductController","ProductController.cs","dbo.sp_DeleteProduct","89","ExecuteAsync","Delete","False"
"OrderController","OrderController.cs","dbo.sp_GetOrders","30","StringLiteral","Read","False"
"OrderController","OrderController.cs","dbo.sp_GetOrderDetails","52","SmartRequest","Read","False"
"ReportController","ReportController.cs","dbo.sp_GenerateReport","20","ExecuteAsync","Execute","False"
```

## Column Definitions

| Column | Description |
|--------|-------------|
| **ControllerName** | Name of the controller class (without .cs extension) |
| **FileName** | Full filename including extension |
| **SPName** | Stored procedure name (may include schema prefix like dbo.) |
| **LineNumber** | Line number where the SP reference was found |
| **Pattern** | How the SP was detected (ExecuteAsync, SmartRequest, DirectAssignment, ProcedureMapper, StringLiteral) |
| **Category** | Operational category (Read, Create, Update, Delete, List, Execute, Mapped, Other) |
| **UsesMapper** | Boolean indicating if ProcedureMapper was used (True) or hard-coded (False) |

## Analysis Insights

### Pattern Distribution
- **ProcedureMapper**: 2 (GOOD - using Application Layer pattern)
- **Hard-coded**: 10 (NEEDS MIGRATION)

### Category Distribution
- Read: 5
- Create: 1
- Update: 1
- Delete: 1
- List: 1
- Execute: 1
- Mapped: 2

### Migration Priority
Controllers with **UsesMapper=False** should be prioritized for migration to use the Application Layer's ProcedureMapper pattern.

### Common Issues Found
1. EmployeesController partially migrated (some calls use ProcedureMapper, one is hard-coded)
2. ProductController uses hard-coded SP names for all CRUD operations
3. ReportController uses hard-coded SP names

## Usage

```powershell
# Extract SP catalog
.\Extract-StoredProcedures.ps1 -ProjectPath "C:\SmartFoundation\SmartFoundation.Mvc"

# View results
Import-Csv .\StoredProcedure_Catalog.csv | Out-GridView

# Filter by pattern
Import-Csv .\StoredProcedure_Catalog.csv | Where-Object UsesMapper -eq $false | Format-Table

# Group by controller
Import-Csv .\StoredProcedure_Catalog.csv | Group-Object ControllerName | Sort-Object Count -Descending
```
