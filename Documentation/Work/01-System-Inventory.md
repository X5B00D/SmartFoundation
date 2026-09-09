# جرد نظام SmartFoundation ونطاق التوثيق

## حالة المستند

- المرحلة: الجرد وتحديد النطاق.
- الحالة: مكتملة.
- مصدر الحقائق: الكود الفعلي أولاً، ثم Metadata قاعدة `DATACORE` الحية باستعلامات قراءة فقط.
- لم يُعدّل أي ملف في النظام أو قاعدة البيانات.
- ملفات مشروع قاعدة البيانات Snapshot مرجعي وليست دليلاً نهائياً على حالة القاعدة الحية.

## الحل والمشاريع

اسم الحل هو `SmartFoundation.sln`، ويتكون من المشاريع التالية:

| المشروع | النوع | الإطار | الدور الأولي المثبت |
| --- | --- | --- | --- |
| `SmartFoundation.Mvc` | ASP.NET Core MVC | .NET 8 | تطبيق الويب ونقطة التشغيل الفعلية في `SmartFoundation.Mvc/Program.cs` |
| `SmartFoundation.Application` | Class Library | .NET 8 | خدمات التطبيق وربط العمليات بإجراءات الدخول عبر `ProcedureMapper` |
| `SmartFoundation.DataEngine` | Class Library | .NET 8 | تنفيذ طلبات Dapper والاتصال بـ SQL Server |
| `SmartFoundation.UI` | Class Library | .NET 8 | ViewComponents وViewModels ومكونات العرض المشتركة |
| `SmartFoundation.Application.Tests` | Test Project | .NET 8 | اختبارات xUnit الحالية |
| `SmartFoundation.Database` | SQL Server Database Project | SQL project | Snapshot/مرجع لتعريفات قاعدة البيانات، وليس المصدر الحي النهائي |

## الطبقات الأربع الفعلية

التقسيم الأولي المثبت من Project References ومسار التنفيذ هو:

1. طبقة العرض والتشغيل: `SmartFoundation.Mvc`.
2. طبقة مكونات واجهة المستخدم المشتركة: `SmartFoundation.UI`.
3. طبقة التطبيق والخدمات: `SmartFoundation.Application`.
4. طبقة تنفيذ البيانات: `SmartFoundation.DataEngine`، وتتصل بقاعدة SQL Server الحية.

يوجد `SmartFoundation.Database` كمرجع لتكوين قاعدة البيانات خارج طبقات التطبيق الأربع، ويوجد مشروع اختبارات منفصل.

## أهم مراجع المشاريع والحزم

- `SmartFoundation.Mvc` يعتمد على Application وDataEngine وUI.
- `SmartFoundation.Application` يعتمد على DataEngine.
- `SmartFoundation.UI` يعتمد على DataEngine.
- من الحزم المهمة المكتشفة: Dapper، Microsoft.Data.SqlClient، ExcelDataReader، QuestPDF، xUnit، Moq وFluentAssertions.

## التهيئة ونقطة التشغيل

ثبت مبدئياً من `SmartFoundation.Mvc/Program.cs` وجود:

- MVC Controllers with Views وRazor Pages.
- Distributed Memory Cache وSession.
- Response Compression وAntiforgery وHSTS وHTTPS Redirection.
- Authentication وAuthorization في HTTP pipeline.
- تسجيل `ConnectionFactory` و`ISmartComponentService` و`CrudController` وخدمة PDF وخدمات التطبيق.
- مسارات Attribute Controllers ومسار MVC تقليدي.

تفاصيل المصادقة والترخيص وترتيب Middleware ستوثق في مهمة المعمارية والأمان، ولا تعتبر هذه القائمة تحليلاً نهائياً.

## نطاق التوثيق

### البرامج المشمولة

| البرنامج | مسار Controller الأساسي | ملفات Controller | Controllers منطقية | Views مرتبطة | الحالة |
| --- | --- | ---: | ---: | ---: | --- |
| ControlPanel | `Controllers/ControlPanel` | 4 | 1 | 3 | Included |
| Housing | `Controllers/Housing` | 20 | 3 | 20 | Included |
| IncomeSystem | `Controllers/IncomeSystem` | 6 | 1 | 5 | Included |
| ElectronicBillSystem | `Controllers/ElectronicBillSystem` | 5 | 1 | 4 | Included |
| Home | `Controllers/Home` | 2 | 1 | 2 | Included |
| Login | `Controllers/Login` | 1 | 1 | 1 | Included |
| **الإجمالي** |  | **38** | **8** | **35** |  |

الفرق بين 38 ملفاً و8 Controllers منطقية سببه أن النظام يقسم Controllers الكبيرة باستخدام `partial class`. Controllers المنطقية هي `ControlPanelController` و`HousingController` و`UploadExcelController` و`UploadLabController` و`IncomeSystemController` و`ElectronicBillSystemController` و`HomeController` و`LoginController`.

يشمل رقم Housing صفحتي `UploadExcel` و`UploadLab` لأن Controllers الخاصة بهما داخل Housing، مع أن Views موجودة في مجلدين مستقلين تحت `Views`.

### البرامج المؤجلة

- HousingCommandCenter
- Maintenance
- Support
- Vehicle
- Dashboard
- Statistics
- PopulationDensity
- RealCharts

هذه الوحدات لا تدخل في Coverage الحالي. ستوثق فقط أي علاقة ضرورية منها مع برنامج مشمول في المراحل التفصيلية.

### أسطح مشتركة أو غير محسومة كوحدات مستقلة

توجد Controllers ومكونات مشتركة مثل `CrudController` و`ExportsController` و`ReportsController` و`NotificationsController` و`SessionController` و`SmartComponentController` وAPI وShared Views. لا تعامل كبرامج مستقلة، لكن ستوثق حيث تخدم البرامج المشمولة.

## الصفحات المكتشفة ضمن النطاق

### ControlPanel

- PagesManagment
- Permission
- Users

### Housing

- BuildingClass
- BuildingDetails
- BuildingType
- BuildingUtilityType
- MilitaryLocation
- HousingExit
- HousingExtend
- HousingHandover
- HousingResident
- Assign
- AssignStatus
- OtherWaitingList
- RentExemption
- Residents، إضافة إلى ResidentsPrint
- WaitingList
- WaitingListByResident
- WaitingListMoveList
- UploadExcel
- UploadLab

### IncomeSystem

- DeductListReport
- FinancialAuditForExtendAndEvictions
- FinancialAuditForUser
- ImportExcelForBuildingPayment
- ExtendInsurance

### ElectronicBillSystem

- Meters
- AllMeterRead
- MeterReadForOccubentAndExit
- MeterServiceTypeFixedAmount

### Home وLogin

- Home: Index وPrivacy.
- Login: Index.

## الخدمات وطبقة البيانات

الخدمات الأساسية المكتشفة:

- `MastersServies`: بوابة DataSet النشطة للتحميل وCRUD والمصادقة.
- `BaseService`: أساس للخدمات الضيقة ذات الاستجابة JSON.
- `EmployeeService` و`DashboardService` و`ChartDataService` و`VehicleService`: خدمات موجودة، وستحدد علاقتها الدقيقة بالنطاق لاحقاً.
- `SmartComponentService`: محرك Dapper الذي ينفذ `SmartRequest` ويدعم result sets متعددة.
- `ConnectionFactory`: مسؤول إنشاء اتصال SQL Server.
- `CrudController`: عقد CRUD مشترك بين صفحات عديدة، ويحوّل `p01..p50` إلى `parameter_01..parameter_50`.

المسار الغالب المثبت مبدئياً للصفحات المشمولة هو:

`View -> MVC Controller -> MastersServies -> SmartComponentService -> dbo.Masters_DataLoad / dbo.Masters_CRUD -> downstream procedure -> SQL objects`

## قاعدة البيانات الحية: جرد Metadata

تم الاتصال بقاعدة `DATACORE` الحية وقراءة `sys.schemas` و`sys.objects` فقط. النتائج لحظة الجرد:

| Schema | Tables | Views | Procedures | Functions | Triggers |
| --- | ---: | ---: | ---: | ---: | ---: |
| dbo | 82 | 25 | 35 | 13 | 0 |
| Demo | 1 | 0 | 1 | 0 | 0 |
| Housing | 86 | 40 | 61 | 33 | 2 |
| Maintenance | 14 | 9 | 14 | 0 | 0 |
| MoveData | 1 | 0 | 16 | 2 | 0 |
| support | 10 | 0 | 10 | 0 | 0 |
| Tickets | 30 | 0 | 0 | 0 | 0 |
| VIC | 20 | 2 | 77 | 0 | 0 |
| WH | 15 | 11 | 1 | 3 | 0 |

وجود Schema في القاعدة لا يعني دخوله تلقائياً في نطاق التوثيق. الجداول والـ Views والـ Functions المهمة للبرامج المشمولة ستحدد بالتتبع المرجعي في مهمة قاعدة البيانات.

## Stored Procedures المحددة مبدئياً

### إجراءات الدخول المشتركة المثبتة

- `dbo.Masters_DataLoad`
- `dbo.Masters_CRUD`
- `dbo.Masters_ExtraDataLoad`
- `dbo.GetSessionInfoForMVC`
- `dbo.ReSetUserPassword`
- `dbo.GetUserMenuTree`

### مطابقة أولية من صفحات النطاق إلى إجراءات حية

- ControlPanel: `dbo.PagesManagmentSP`، `dbo.PermissionSP`، `dbo.UsersDL`، `dbo.UsersSP`.
- Housing definitions and procedures: أزواج `DL` و`SP` المطابقة لأسماء BuildingClass وBuildingDetails وBuildingType وBuildingUtilityType وMilitaryLocation وHousingExit وHousingExtend وHousingHandover وHousingResident.
- Housing waiting-list features: أزواج `DL` و`SP` المطابقة لأسماء Assign وAssignStatus وOtherWaitingList وRentExemption وResidents وWaitingList وWaitingListByResident وWaitingListMoveList.
- IncomeSystem: `Housing.ExtendInsuranceDL/SP`، `Housing.FinancialAuditForExtendAndEvictionsDL/SP`، `Housing.FinancialAuditForUserDL/SP`، وإجراءات ImportExcelForBuildingPayment الثلاثة المكتشفة.
- ElectronicBillSystem: أزواج `DL` و`SP` المطابقة لأسماء Meters وAllMeterRead وMeterReadForOccubentAndExit وMeterServiceTypeFixedAmount.
- Home: `dbo.HomeDL`.

تم تحديد 62 إجراءً أولياً شاملاً بوابات الدخول والمصادقة والمطابقات الاسمية الحية. هذا **ليس Coverage نهائياً**: ما زال يلزم إثبات routing والاستخدام الفعلي، خصوصاً DeductListReport، وصفحتي UploadExcel/UploadLab، والإجراءات التي قد تستدعيها بوابات SQL بأسماء غير مطابقة للصفحة.

## ملاحظات الدقة والمخاطر

- معلومة مثبتة: المشروع يستخدم DataSet وبوابتي `Masters_DataLoad` و`Masters_CRUD` في غالبية الصفحات المشمولة.
- معلومة مثبتة: Metadata القاعدة الحية تحتوي على الكائنات والأعداد المبينة أعلاه وقت الفحص.
- استنتاج أولي: تطابق اسم الصفحة مع إجراء `DL` أو `SP` يرجح أنه downstream procedure، لكنه لا يصبح علاقة نهائية إلا بعد قراءة routing وتعريف الإجراء.
- لم يتم التحقق بشكل كافٍ بعد من جميع الجداول والـ Views والـ Functions المرتبطة بكل صفحة.
- لم ينفذ أي Stored Procedure تجاري، ولم تنفذ أي عملية كتابة في قاعدة البيانات.

## نتيجة المرحلة

اكتمل Inventory والنطاق، وأصبح المشروع جاهزاً لمهمة تحليل المعمارية والمكونات المشتركة دون إعادة الجرد الأساسي.
