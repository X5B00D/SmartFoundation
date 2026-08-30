# تدقيق ومطابقة قاعدة DATACORE الحية للمحادثات 1–7

## النطاق والمنهج

- تاريخ التحقق: 2026-08-22.
- المصدر النهائي لسلوك SQL: قاعدة `DATACORE` الحية. مصدر سلوك التطبيق: الكود النشط.
- ملفات `SmartFoundation.Database` استُخدمت للمقارنة التاريخية فقط.
- اقتصرت القراءة على catalog views المصرح بها. لم يُنفذ أي Business Stored Procedure، ولم تُنفذ كتابة أو DDL.
- استُخرج التعريف الكامل لكل module، وتوقيعات الإجراءات من `sys.parameters`، ثم قورنت النصوص بعد توحيد المسافات وصيغة `CREATE/ALTER` واستبعاد extended properties التصميمية للـ Views.

## النتيجة الرقمية

| المقياس | العدد |
| --- | ---: |
| الإجراءات المتحقق منها حياً | 51 |
| Live verified and matching | 40 |
| Live verified with differences | 11 |
| Missing from live database | 0 |
| Views/Functions المتحقق من تعريفها | 19 |
| Views/Functions المطابقة وظيفياً | 18 |
| Views/Functions المختلفة وظيفياً | 1 |
| Triggers ذات الصلة المكتشفة حياً | 1 |

المطابقة لا تعني تنفيذ الإجراء أو إثبات نتيجة بيانات فعلية. Result sets موثقة من عبارات التعريفات الحية، لا من تشغيل الإجراءات.

## جميع الإجراءات المتحقق منها

### Live verified and matching (40)

`dbo.Masters_ExtraDataLoad`, `dbo.GetSessionInfoForMVC`, `dbo.ReSetUserPassword`, `dbo.GetUserMenuTree`, `dbo.PagesManagmentSP`, `dbo.PermissionSP`, `dbo.UsersSP`, `dbo.SetUserPassword`, `dbo.Notifications_Create`, `Housing.BuildingClassDL`, `Housing.BuildingClassSP`, `Housing.BuildingTypeDL`, `Housing.BuildingTypeSP`, `Housing.buildingUtilityTypeDL`, `Housing.BuildingUtilityTypeSP`, `Housing.MilitaryLocationDL`, `Housing.MilitaryLocationSP`, `Housing.BuildingDetailsDL`, `Housing.BuildingDetailsSP`, `Housing.HousingResidentDL`, `Housing.HousingHandoverDL`, `Housing.HousingHandoverSP`, `Housing.HousingExitDL`, `Housing.BackfillResidentServiceBills`, `Housing.ResidentsDL`, `Housing.ResidentsSP`, `Housing.WaitingListByResidentDL`, `Housing.WaitingListByResidentSP`, `Housing.WaitingListMoveListDL`, `Housing.WaitingListMoveListSP`, `Housing.WaitingListDL`, `Housing.WaitingListSP`, `Housing.OtherWaitingListDL`, `Housing.OtherWaitingListSP`, `Housing.AssignStatusDL`, `Housing.AssignStatusSP`, `Housing.RentExemptionDL`, `Housing.RentExemptionSP`, `Housing.UploadExcel_ImportSelected3Cols`, `Housing.GenerateMonthlyRentBillForResident`.

### Live verified with differences (11)

| الإجراء | الفرق الحي عن Snapshot وأثره |
| --- | --- |
| `dbo.Masters_DataLoad` | أضاف ترتيباً تنازلياً لنتيجة `DistributorPermissionType` في تحميل Permission. |
| `dbo.Masters_CRUD` | أضيف routing صريح لـ `CANCELHOUSINGRESIDENT` إلى `HousingResidentSP`، مع تحديثات أخرى لفروع برامج لاحقة خارج النطاق. |
| `dbo.UsersDL` | توسع result set المستخدمين بـ `distributorID`, `distributorName_A`, `DepartmentID`, `DepartmentName` عبر أحدث ربط active. |
| `Housing.HousingResidentSP` | أضيف تحقق من صحة `OccupentDate` وأنه بعد آخر خروج، ومن سلسلة الحركة والتخصيص 38/40 وحالة المبنى، مع معالجة أوسع للفوترة والخدمات. |
| `Housing.HousingExtendDL` | literal الحساب `40` بدلاً من `40.00`؛ المقصود الوظيفي باقٍ 40 ضعف الإيجار مع المتبقي. |
| `Housing.HousingExtendSP` | تحقق التأمين صار typed بـ `TRY_CONVERT(decimal(18,2))` ويرفض القيم غير الرقمية أو الإجمالي `<= 0` ويثبت شروط الحالة و`InsuranceRequired`. |
| `Housing.HousingExitSP` | أعيد بناء فرع الغرامة/فوترة الخروج حول `BillPeriod`, `BillPeriodType`, الضريبة وتواريخ الفترة وربط/استبدال الفواتير. |
| `Housing.GenerateExitRentBills` | فرق صياغة `THROW` بالفاصلة المنقوطة فقط؛ القواعد مطابقة وظيفياً. |
| `Housing.AssignDL` | التعريف الحي يعرض الحالات `(5,39,41)` أو بلا حالة؛ Snapshot الحالي يضيف 42، ولذلك القائمة المرجعة حياً أضيق. |
| `Housing.AssignSP` | التعريف الحي يحتفظ بفحص للمبنى المحدد يسمح `(5,39,41,42)`، إضافة إلى فحص active/Idara مستقل؛ Snapshot الحالي أعاد ترتيب الفحص وضيّقه. يوجد عدم اتساق حي بين DL الذي لا يعرض 42 وSP الذي يقبلها. |
| `Housing.BuildingRentForOneMonth` | يأخذ `ExitDate` من `V_Occupant` ويشمل المقيم إذا كان الخروج NULL أو في/بعد بداية الشهر. |

## العقود والمعاملات الحية

- `Masters_DataLoad`: 24 معاملاً؛ أربعة سياق ثم `parameter_01..20`.
- `Masters_CRUD`: 55 معاملاً؛ خمسة سياق ثم `parameter_01..50`.
- `Masters_ExtraDataLoad`: 15 معاملاً؛ خمسة سياق ثم `parameter_01..10`.
- `GetSessionInfoForMVC`: `NationalID`, `Password`, `hostName`.
- `ReSetUserPassword`: ثمانية معاملات تشمل action والهوية وكلمات المرور وسياق التدقيق.
- `UploadExcel_ImportSelected3Cols`: سبعة معاملات حية، بينها أسماء أربعة أعمدة وTVP باسم `Housing.UploadExcelRowType`. هذا يؤكد عدم تطابق Controller ذي الأعمدة الثلاثة المختارة وDataTable ذي أربع خانات مع العقد/TVP الموثق بخمس خانات.
- استُخرج العدد والنوع والترتيب لكل معاملات الإجراءات الـ51؛ لم يظهر drift آخر في توقيعات features.

## Result sets الحية

- `Masters_DataLoad` يعيد `ft_UserPagePermissions` أولاً ثم نتائج الصفحة.
- أعداد ومصادر نتائج Housing Definitions/Procedures/Waiting تطابق التوثيق عندما كان DL مطابقاً.
- `UsersDL` وسع result set الأول بأربعة حقول، دون إضافة result set جديد.
- `HousingResidentDL` و`HousingExitDL` يعيدان feature set واحداً؛ طلب Controllers لجداول DDL إضافية لا يملك نتائج حية مقابلة.
- `BuildingDetailsDL` ما زال يعيد ثمانية feature sets بعد الصلاحيات، ومنها `dt8` غير المستهلك.

## Views وFunctions

### Live verified and matching (18)

`dbo.ft_UserPagePermissions`, `dbo.V_GetListUserPermission`, `dbo.V_GetListUsersInDSD`, `dbo.V_GetFullStructureForDSD`, `dbo.V_GetFullSystemUsersDetails`, `Housing.V_LastActionForBuilding`, `Housing.V_GetFullResidentDetails`, `Housing.V_GetGeneralListForBuilding`, `Housing.V_Occupant`, `Housing.V_buildingWithRent`, `Housing.V_SumBillsTotalPriceAndTotalPaidForResident`, `Housing.V_MoveWaitingList`, `Housing.V_WaitingListByLetter`, `Housing.V_WaitingListWithLetters`, `Housing.V_WaitingList_Ids`, `Housing.V_AssignList`, `Housing.fn_CalcMonthlyBuildingRent_ByBuildingDetailsID`, و`Housing.fn_BuildingAction_ChainToRoot`.

فروق `MS_DiagramPane` والـ extended properties في ملفات Views ليست فروقاً في تعريفات الـ Views الحية.

### Live verified with differences (1)

`Housing.V_WaitingList` يشمل جذور أنواع الحركة `(1,7,25)` في الـ anchor والفلتر النهائي، بينما Snapshot يستخدم `(1,7)`.

## الجداول والعلاقات والـ Triggers

تحققت حياً الجداول المباشرة الموثقة في المجالات الستة، ولم يظهر جدول موثق مفقود. تؤكد FKs الحية علاقات `BuildingDetails` مع class/type/utility/location، و`MilitaryLocation` مع city وIdara، و`BuildingRent` مع building/rent type، و`BuildingAction` مع building/action type/resident. لا يوجد FK حي مكتشف لـ `BuildingDetailsMeterServices`، فيبقى ارتباطه إجرائياً.

كائنات حية ظهرت من التعريفات أو FKs ولم تكن موثقة بوضوح:

- `Housing.BillPeriod`, `Housing.BillPeriodType`, `Housing.BillChargeType`, و`dbo.Tax` في فوترة/غرامات الخروج.
- `Housing.MeterReadType` عبر FK من `MeterRead`.
- `Housing.BuildingActionSource`, `Housing.BuildingPaymentType`, و`Housing.BuildingStatus` عبر FKs من `BuildingAction`.
- Trigger حي وفعال `Housing.trg_BuildingAction_Audit` على `Housing.BuildingAction`؛ وهو أثر تدقيق إضافي فوق `dbo.AuditLog` الصريح.

ظهر أيضاً `TR_BuildingPayment_SetLinkStatus` على `BuildingPayment`، لكنه يتصل بمرحلة IncomeSystem التالية ولم يدخل أعداد هذه المرحلة.

## الصلاحيات والأمان

- `ft_UserPagePermissions` و`V_GetListUserPermission` مطابقان حياً.
- `GetSessionInfoForMVC`, `ReSetUserPassword`, `SetUserPassword`, و`Notifications_Create` مطابقة حياً؛ لذلك تبقى مخاطر reset الإداري والسياق الأمني المرسل من العميل كما وثقت.
- `Masters_CRUD` ما زال يعتمد على `entrydata/pageName_/ActionType/idaraID` المرسلة من التطبيق؛ التحقق الحي لم يغلق خطر انتحال السياق.
- فرع `HousingHandover` مطابق للـ Snapshot؛ شرط `permissionTypeName_E=ActionType` ما زال معلقاً وتوجد صلاحية صفحة عامة فقط.
- collation الحية غير حساسة لحالة الأحرف؛ لذلك case وحده لا يعطل `AssignStatus/ASSIGNSTATUS`. لم تُقرأ بيانات الصلاحيات لإثبات `menuName_E`.

## الفجوات المغلقة

1. تحققت حياً إجراءات النطاق الـ51 والـ modules الأخرى الـ19.
2. ثبتت مطابقة تعريفات المصادقة وكلمات المرور والصلاحيات والإشعارات.
3. ثبت تباين UploadExcel من التوقيع الحي.
4. ثبت ضعف فحص `HousingHandover` الحي.
5. حُسم أثر case في `AssignStatus` وفق collation الحية.
6. صححت إتاحة المبنى: `AssignDL` الحي يعرض `(5,39,41)`، بينما `AssignSP` الحي يقبل `(5,39,41,42)`؛ وجذور `V_WaitingList` الحية هي `(1,7,25)`.
7. أضيفت قواعد التسكين بعد آخر إخلاء وقواعد فوترة الخروج الحية.

## الفجوات الجديدة والباقية

1. لم تُنفذ الإجراءات؛ لا يوجد تحقق E2E أو بيانات/permissions فعلية.
2. يحتاج `trg_BuildingAction_Audit` تحليلاً مستقلاً لأثره ومنع ازدواج التدقيق.
3. توسع كائنات فوترة الخروج العلاقة مع IncomeSystem وسيستكمل في `income_system`.
4. أخطاء binding/UI من الكود النشط لا تغلقها مطابقة SQL.
5. معاني كل IDs في `BuildingActionType` غير مثبتة من seed data.
6. UploadExcel ما زال direct SQL بلا permission gateway وTVP غير متوافق مع DataTable.

## التصنيف النهائي وما لم يتحقق

- **Live verified and matching:** 40 إجراءً و18 View/Function.
- **Live verified with differences:** 11 إجراءً و`Housing.V_WaitingList`.
- **Missing from live database:** لا يوجد ضمن القائمة المطلوبة.
- **Exists live but missing from documentation:** `Housing.trg_BuildingAction_Audit` وثمانية جداول مرجعية/FK أعلاه؛ أضيفت الآن.
- غير متحقق: بيانات الأعمال والـ seed، التنفيذ الفعلي، صلاحيات المستخدمين، modules خارج المحادثات 1–7، وسلوك triggers/PDF/uploads. تم التحقق لاحقاً من schema الحي لـ `UploadExcelRowType` وثبتت أعمدته الخمسة.

## تحديث التحليل النهائي 2026-08-23

أعاد [تحليل قاعدة البيانات النهائي](11-Live-Database-and-ERD.md) جرد Schema `Housing` كاملاً وميّز بين العلاقات المقيدة والمستنتجة. العدد 38 FK الوارد في مراحل البرامج كان subset للاعتماديات المباشرة، بينما العدد الحي الكامل لـHousing هو 75 FK. ثبت أيضاً أن Triggerي `trg_BuildingAction_Audit` و`TR_BuildingPayment_SetLinkStatus` حيان وفعالان لكنهما غير موجودين في Snapshot. لا توجد ملفات كائنات Housing في Snapshot مفقودة حياً بالمطابقة الاسمية.
