# قاعدة DATACORE الحية وERD للبرامج المشمولة

## الحالة والنطاق

- تاريخ التحقق: 2026-08-23.
- الحالة: مكتمل من كتالوج `DATACORE` الحي للبرامج `ControlPanel`, `Housing`, `IncomeSystem`, `ElectronicBillSystem`, `Home`, و`Login`.
- مصدر الحقيقة: تعريفات وMetadata القاعدة الحية. استُخدم `SmartFoundation.Database` للمقارنة التاريخية واكتشاف drift فقط.
- طريقة القراءة: PowerShell و`System.Data.SqlClient` من إعداد التطبيق المحلي، داخل `try/catch`. لم تُطبع أو تُحفظ بيانات الاتصال.
- لم يُنفذ أي Business Stored Procedure، ولم تُقرأ صفوف أعمال، ولم تُنفذ DML أو DDL أو Backup/Restore.
- الاستعلامات اقتصرت على catalog metadata والتعريفات المصرح بها. لم تُنشأ أداة .NET أو helper executable أو مشروع مؤقت.

## قاعدة البيانات والـ Schemas

نجح الاتصال بقاعدة `DATACORE`. الكائنات المباشرة للبرامج المشمولة موزعة فعلياً على Schemaين:

| Schema | الدور الحي ضمن النطاق |
| --- | --- |
| `dbo` | الهوية، المستخدمون، التركيب الإداري، ControlPanel، الصلاحيات، الإشعارات، التدقيق، وبوابات التطبيق المشتركة. |
| `Housing` | الإسكان وقوائم الانتظار، الدخل والتدقيق المالي، العدادات والفوترة الإلكترونية. |

لا توجد Schemas حية باسم `IncomeSystem` أو `ElectronicBillSystem`. الاسمان يمثلان برنامجين في MVC، لكن كائناتهما SQL موجودة تحت `Housing` وتصل إليها البوابات في `dbo`.

## أعداد الكائنات الموثقة

| النوع | `Housing` الحي | `dbo` المباشر المختار | الإجمالي الموثق |
| --- | ---: | ---: | ---: |
| Tables | 86 | 32 | 118 |
| Views | 40 | 4 | 44 |
| Stored Procedures | 61 | 15 | 76 |
| Functions | 33 | 1 | 34 |
| Triggers | 2 | 0 | 2 |
| **الإجمالي** | **222** | **52** | **274** |

`dbo` المختار ليس جرداً لكل `dbo`: استُبعدت كائنات البرامج المؤجلة والأدوات الإدارية والـ AI والـ database diagrams. أما `Housing` فجُرد كاملاً لأن البرامج الأربعة Housing/Income/ElectronicBill تستخدم Schema نفسها وتتشابك اعتمادياتها.

## الجداول المهمة والغرض من الأعمدة

### ControlPanel والهوية والصلاحيات

| الجدول | PK | أهم الأعمدة والغرض |
| --- | --- | --- |
| `dbo.Program` | `programID` | أسماء البرنامج، الرابط، الترتيب، وحالة النشاط. |
| `dbo.Menu` | `menuID` | `programID_FK`, الاسم الإنجليزي المطابق لـ`pageName_`, الرابط، الأب المنطقي، النشاط ومستوى الصفحة. |
| `dbo.Distributor` | `distributorID` | الوحدة الموزعة للصلاحية؛ ترتبط اختيارياً بـDSD وRole. |
| `dbo.MenuDistributor` | `menuDistributorID` | ربط Menu بـDistributor/Role/User مع `isDenied` والنشاط. |
| `dbo.PermissionType` | `permissionTypeID` | `permissionTypeName_E` هو اسم الفعل الذي تقرأه Controllers وتفحصه البوابة. |
| `dbo.DistributorPermissionType` | `distributorPermissionTypeID` | ربط Distributor بنوع الصلاحية وفترة سريانها ومستوى التفويض. |
| `dbo.Permission` | `permissionID` | المنحة لمستخدم/Role/Distributor/DSD مع Idara وفترة النشاط. |
| `dbo.Users` | `usersID` | هوية الحساب، National ID، النشاط وفترة الصلاحية وحالة تغيير كلمة المرور. |
| `dbo.UsersDetails` | `usersDetailsID` | `usersID_FK` والاسم والبيانات التنظيمية/الشخصية المساندة. |
| `dbo.UsersPassword` | `usersPasswordID` | `usersID_FK`, salt/hash، النشاط والفترة. لم تُقرأ أي قيمة. |
| `dbo.UserDistributor` | `UDID` | إسناد المستخدم إلى Distributor وفترة النشاط. |
| `dbo.DeptSecDiv` | `DSDID` | تجميع Organization/Idara/Department/Section/Division. بعض الروابط منطقية بلا FK فعلي. |
| `dbo.Notifications` | `NotificationId` | العنوان والنص والرابط والفترة والنشاط وIdara. |
| `dbo.UserNotifications` | `UserNotificationId` | FK إلى الإشعار والمستخدم وحالة القراءة. |
| `dbo.AuditLog` | `AuditID` | الجدول، الفعل، RecordID، المنفذ، الملاحظات والوقت. |
| `dbo.ErrorLog` | `ErrorLogID` | الخطأ والشدة والحالة والإجراء وسياق الإدخال. |

الجداول المشتركة الأخرى الموثقة في هذا النطاق: `Role`, `DistributorType`, `ProgramDistributor`, `UsersAuthType`, `Organization`, `Idara`, `Department`, `Section`, `Divison`, `City`, `Tax`, `Gender`, `MaritalStatus`, `MilitaryUnit`, `Nationality`, و`Rank`.

### Housing والإقامة والانتظار

| المجموعة | الجداول المحورية | الغرض |
| --- | --- | --- |
| التعريفات | `BuildingClass`, `BuildingType`, `BuildingUtilityType`, `MilitaryArea`, `MilitaryAreaCity`, `MilitaryLocation`, `BuildingDetails` | تصنيف المبنى وموقعه ونوعه ومنفعته وبياناته الأساسية. |
| المستفيد | `ResidentInfo`, `ResidentDetails`, `ResidentContactInfo`, `ResidentContactType`, `ResidentStatus` | هوية المستفيد وتفاصيله واتصالاته وحالته. |
| دورة المبنى | `BuildingAction`, `BuildingActionType`, `BuildingActionSource`, `BuildingStatus`, `BuildingHandover` | سجل التسليم/التسكين/الإمهال/الإخلاء والحالات والمصادر. |
| الانتظار والإسناد | `BuildingAssign`, `BuildingAssignStatus`, `BuildingAssignType`, `AssignPeriod`, `AssignNote`, `WaitingClass`, `WaitingOrderType` | قوائم الانتظار، الترشيح، الإسناد والحالة. |
| الإعفاء/الإمهال | `ResidentRentExemption`, `ResidentRentExemptionType`, `ExtendInsurance`, `ExtendInsuranceType`, `ExtendReasonType` | الإعفاءات وتأمين الإمهال والاعتماد. |
| الإيجار | `BuildingRent`, `BuildingRentType`, `RentBills`, `RentBillsAdjustment`, `BuildingRentActualPayment` | تعريف الإيجار، الفواتير والتسويات والمدفوع الفعلي. |

أعمدة `...ID` هي PKs في 79 من 86 جدول Housing. حقول `...Active`, تواريخ البداية/النهاية، `IdaraID_FK`, `entryDate`, `entryData`, و`hostName` تتكرر لضبط النطاق والنشاط والتدقيق. عدم وجود PK في سبعة جداول لا يعني عدم أهميتها، لكنه gap بنيوي يجب مراجعته تشغيلياً.

### IncomeSystem وElectronicBillSystem

| المجموعة | الجداول المحورية | أهم الأعمدة/الدور |
| --- | --- | --- |
| التدقيق المالي | `DeductList`, `DeductType`, `DeductListStatus`, `BillDeductList`, `BillDeductAction`, `BillsDeductListDetails` | رقم المطالبة/الخصم، الفترة، النوع، الحالة، المبلغ والربط بالفواتير. |
| الدفع والربط | `BuildingPayment`, `BuildingPayment_`, `BuildingPaymentType`, `BuildingPaymentDestaination`, `BuildingPaymentLinkStatus`, `BuildingPaymentLinkAudit` | الدفعة الخام/التاريخية، تصنيفها، وجهتها، حالة الربط وتدقيق الربط. |
| العدادات | `Meter`, `MeterType`, `MeterForBuilding`, `MeterRead`, `MeterReadType` | رقم العداد، نوع الخدمة، ربطه بالمبنى، القراءة والفترة ونوع القراءة. |
| التسعير | `MeterServiceType`, `MeterServicePrice`, `MeterSlide`, `MeterServiceTypeFixedAmount`, `MeterServiceTypeLinkedWithIdara`, `MeterTypeFixedAmount` | الخدمة، الشرائح، السعر الثابت، فترة السريان ونطاق الإدارة. |
| الفوترة | `Bills`, `BillType`, `BillPeriod`, `BillPeriodType`, `BillChargeType`, `billPayment`, `billPaymentType` | الفاتورة، الفترة، نوع الشحنة، الدفع وعلاقة الفاتورة الأصلية/البديلة. |
| الاستيراد | `UploadExcel`, `UploadExcelImportLog` | staging للأعمدة المختارة وسجل hash/الملف/الأعداد وربط DeductList. لا تُخزن التعريفات هنا أي بيانات فعلية. |

## Primary Keys وForeign Keys والقيود

- `Housing`: 79 PK و75 FK حيّاً.
- جداول `dbo` الـ32 المباشرة: 32 PK و43 FK حيّاً.
- جميع FKs المقروءة مفعلة. ظهر FK واحد غير موثوق (`is_not_trusted=1`) على `Housing.BuildingPayment_ -> Housing.BuildingPaymentType`؛ يجب عدم افتراض أن البيانات التاريخية اجتازت التحقق.
- إجراءات `ON DELETE` و`ON UPDATE` في مجموعة FKs المقروءة هي `NO_ACTION`; لا يوجد cascade مثبت في هذه المجموعة.

### علاقات FK محورية مثبتة حياً

- `Menu.programID_FK -> Program.programID`.
- `MenuDistributor -> Menu/Distributor/Role/Users`.
- `DistributorPermissionType -> Distributor/PermissionType`.
- `Permission -> DistributorPermissionType/Users/Role/Distributor/DeptSecDiv`.
- `UserDistributor -> Users/Distributor`.
- `UsersDetails.usersID_FK -> Users.usersID` و`UsersPassword.usersID_FK -> Users.usersID`.
- `BuildingDetails -> BuildingClass/BuildingType/BuildingUtilityType/MilitaryLocation`.
- `BuildingAction -> BuildingDetails/BuildingActionType/ResidentInfo/BuildingActionSource/BuildingPaymentType/BuildingStatus`.
- `MeterForBuilding -> Meter/BuildingDetails`; و`MeterRead -> Meter/BillPeriod/MeterReadType`.
- `BillPeriod -> BillPeriodType -> MeterServiceType`.
- `RentBills -> ResidentInfo/BuildingDetails`; و`RentBillsAdjustment -> RentBills/ResidentInfo/BuildingDetails`.
- `ResidentDetails -> ResidentInfo` وإلى lookups المشتركة للرتبة والوحدة والجنس والجنسية والحالة الاجتماعية والإدارة.
- `ResidentRentExemption -> ResidentInfo/ResidentRentExemptionType`.

### علاقات مستنتجة وليست قيوداً فعلية

هذه العلاقات مستخدمة في الأعمدة أو SQL الحي، لكن لم يظهر لها FK في الكتالوج؛ لذلك لا يجوز رسمها كقيود:

- `Menu.parentMenuID_FK -> Menu.menuID`: علاقة شجرية مستنتجة، وليست FK فعلياً.
- `DeptSecDiv.OrganizationID_FK/idaraID_FK`: علاقة تنظيمية مستنتجة؛ الـFKs الفعلية الموجودة تربط Department/Section/Division فقط.
- `Permission.IdaraID_FK -> Idara` و`Permission.InIdaraID -> Idara`: مستنتجة وليست FK.
- `BuildingDetailsMeterServices -> BuildingDetails/MeterServiceType`: مستنتجة من الإجراءات والأسماء، بلا FK حي.
- `BuildingAssign` إلى resident/building/status/type: مستنتجة من تعريفات الإجراءات/الأعمدة، ولا تظهر في قائمة FKs الحية.
- `MeterRead.residentInfoID_FK`, `buildingDetailsID`, و`buildingActionID_FK`: روابط منطقية بلا FK فعلي.
- `ResidentRentExemption.buildingDetailsID_FK -> BuildingDetails`: مستنتجة وليست قيداً.
- `ExtendInsurance` إلى BuildingAction/ResidentInfo/BuildingDetails: مستنتجة وليست قيوداً فعلية.
- `DeductList` إلى BillChargeType/ExtendInsurance/Idara: مستنتجة رغم لاحقة `_FK`.

## Views واعتمادها

### Views المشتركة المباشرة

`dbo.V_GetListUserPermission`, `dbo.V_GetListUsersInDSD`, `dbo.V_GetFullStructureForDSD`, و`dbo.V_GetFullSystemUsersDetails`.

### Views في Housing (40)

`V_AllResidentsWithMoreThanOneSera`, `V_AssignList`, `V_buildingWithRent`, `V_FirstMeterReadForAllMeter`, `V_GetFullResidentDetails`, `V_GetGeneralListActionForResident`, `V_GetGeneralListForBuilding`, `V_GetGeneralListForBuildingWithRent`, `V_GetGeneralListForResident`, `V_GetListAllMetersLastAndBeforeLastRead_WithWrap`, `V_GetListAllMetersLastRead`, `V_GetListMeterSlidesPrice`, `V_GetListMetersLinkedWithBuildings`, `V_GetListMetersLinkedWithBuildings_2026_02_28`, `V_LastActionForBuilding`, `V_LastActionForResident`, `V_LastActionTypeForBuilding`, `V_LastMeterRead_Type1`, `V_MeterLastBill`, `V_MetersDetails`, `V_moreOneActionforType1`, `V_MoveWaitingList`, `V_Occupant`, `V_Occupant_2026_02_04`, `V_OccupantExtend`, `V_ResidentBillsFinancialSummary`, `V_ResidentFinancialSummary`, `V_ResidentLastBill`, `V_ResidentPreviosBill`, `V_ResidentServiceAverageBills`, `V_SumBillsTotalPaidByResident`, `V_SumBillsTotalPriceAndTotalPaidForResident`, `V_SumBillsTotalPriceForResident`, `V_SumUnallocatedPaymentsForResident`, `V_UnresolvedBuildingPayments`, `V_WaitingList`, `V_WaitingList_Ids`, `V_WaitingListByLetter`, `V_WaitingListWithLetters`, و`V_WaitingListxx`.

اعتماد Views موثق من `sys.sql_expression_dependencies`. أمثلة محورية: `V_GetFullResidentDetails` يعتمد على عشرة كائنات، `V_GetGeneralListForBuildingWithRent` على 11، `V_MetersDetails` على ستة، و`V_WaitingList` و`V_WaitingListWithLetters` على سبعة لكل منهما. أسماء النسخ المؤرخة و`V_WaitingListxx` حية وليست دليلاً على أن التطبيق يستخدمها.

## Stored Procedures والمعاملات

### بوابات ومشترك `dbo` (15)

| الإجراء | عدد المعاملات | الدور |
| --- | ---: | --- |
| `Masters_DataLoad` | 24 | permission result set ثم routing للقراءة. |
| `Masters_CRUD` | 55 | permission/action routing ثم الكتابة عبر feature SP. |
| `Masters_ExtraDataLoad` | 15 | تحميل مساعد/DDL. |
| `GetSessionInfoForMVC` | 3 | مصادقة وبناء سياق Session. |
| `GetUserMenuTree` | 1 | شجرة البرامج والقوائم حسب الصلاحيات. |
| `HomeDL`, `ChartsDL` | 5 لكل منهما | تحميل Home/Charts. |
| `PagesManagmentSP` | 39 | CRUD لتعريف البرامج والقوائم والصفحات. |
| `PermissionSP` | 19 | CRUD لمنح الصلاحيات. |
| `UsersDL` | 4 | بيانات المستخدمين وDDL. |
| `UsersSP` | 30 | CRUD المستخدمين. |
| `ReSetUserPassword` | 8 | تغيير/reset كلمة المرور. |
| `SetUserPassword` | 6 | إنشاء/تحديث كلمة المرور. |
| `Notifications_Create` | 15 | إنشاء الإشعار وتحديد المستلمين. |
| `Notifications_CRUD` | 3 | تحديث حالة إشعار المستخدم. |

### إجراءات Housing/Income/ElectronicBill (61)

| المجموعة | الإجراءات الحية |
| --- | --- |
| تعريفات Housing | `BuildingClassDL/SP`, `BuildingTypeDL/SP`, `buildingUtilityTypeDL`, `BuildingUtilityTypeSP`, `MilitaryLocationDL/SP`, `BuildingDetailsDL/SP`. |
| إجراءات السكن | `HousingResidentDL/SP`, `HousingHandoverDL/SP`, `HousingExtendDL/SP`, `HousingExitDL/SP`, `GenerateExitRentBills`, `GenerateMonthlyRentBills`, `GenerateMonthlyRentBillForResident`, `BackfillResidentServiceBills`, `BuildingRentForOneMonth`, `BuildingRentForOneMonth_2026-05-12`. |
| الانتظار/الإسناد | `ResidentsDL/SP`, `WaitingListByResidentDL/SP`, `WaitingListMoveListDL/SP`, `WaitingListDL/SP`, `OtherWaitingListDL/SP`, `AssignDL/SP`, `AssignStatusDL/SP`, `RentExemptionDL/SP`, `UploadExcel_ImportSelected3Cols`. |
| IncomeSystem | `ExtendInsuranceDL/SP`, `FinancialAuditForExtendAndEvictionsDL/SP`, `FinancialAuditForUserDL/SP`, `ImportExcelForBuildingPayment`, `ImportExcelForBuildingPaymentDL/SP`, `usp_ClassifyAndLinkBuildingPayments`, `usp_ClassifyAndLinkBuildingPayments_V2`, `usp_LinkBuildingPaymentManually`. |
| ElectronicBillSystem | `MetersDL/SP`, `AllMeterReadDL/SP`, `MeterReadForOccubentAndExitDL/SP`, `MeterServiceTypeFixedAmountDL/SP`. |

أعداد معاملات الإجراءات الحية تتراوح من 4 إلى 36 في feature procedures. التوقيعات التفصيلية السابقة صحيحة؛ أبرز العقود المشتركة هي `pageName_`, `idaraID`, `entrydata`, `hostname`، ثم معاملات feature. لم تُنفذ الإجراءات لاكتشاف metadata ديناميكية.

## Result Sets المستنتجة من التعريفات الحية

- `Masters_DataLoad` يعيد أولاً `permissionTypeName_E` من `ft_UserPagePermissions`، ثم نتائج DL المختار.
- `Masters_CRUD` وإجراءات SP التابعة تعيد عادة عقد `IsSuccessful`/`Message_`; الفروع قد تعيد أخطاء أعمال ضمن 50001..50999. هذا استنتاج من عبارات `SELECT`/`THROW` الحية لا من التنفيذ.
- ControlPanel: `PagesManagment` يجمع تعريفات البرامج/القوائم/الموزعين/أنواع الصلاحيات؛ `Permission` يجمع المنح وDDL؛ `UsersDL` يعيد المستخدمين وlookups، وتوسع حياً بأربعة أعمدة تنظيمية موثقة في 07A.
- Housing Definitions: مجموع النتائج feature بعد permissions موثق سابقاً بـ18 عبر الصفحات الخمس؛ `BuildingDetailsDL` وحده يعيد ثمانية feature sets بعد permissions، ومنها نتيجة غير مستهلكة في Controller.
- Housing Procedures: `HousingResidentDL` و`HousingExitDL` يعيدان feature set واحداً فقط؛ طلب Controller لنتائج إضافية لا يملك مقابلاً حياً. بقية النتائج موثقة في مستند البرنامج.
- Waiting/Imports: 31 feature result sets و8 permission result sets في الصفحات التي تمر بالبوابة؛ import المباشر لا يضيف permission set.
- IncomeSystem: DLs تعيد القوائم المالية/التأمين/الدفعات والـDDL كما هو مفصل في مستند البرنامج. مسار import له DL وSP وعملية import مستقلة.
- ElectronicBillSystem: 20 result sets موثقة بما فيها permission sets للصفحات الأربع.
- Home/Login: نتائج الدخول، الشجرة وHome/Charts موثقة من التعريف الحي؛ لا يوجد تشغيل بحساب فعلي.

## الجداول التي تقرأ أو تعدل

اعتمد التحديد على `sys.sql_expression_dependencies` وعلى نصوص الوحدات الحية عندما لا يستطيع dependency catalog حل SQL الديناميكي:

- ControlPanel يقرأ/يعدل جداول البرامج والقوائم والموزعين وأنواع الصلاحيات والمنح والمستخدمين وكلمات المرور، ويكتب audit/error/notifications حسب الفرع.
- Housing Definitions يقرأ/يعدل lookups و`BuildingDetails`, `BuildingRent`, و`BuildingDetailsMeterServices`.
- Housing lifecycle يقرأ/يعدل `ResidentInfo/Details`, `BuildingAction`, `BuildingHandover`, `ExtendInsurance`, `RentBills`, `Bills`, وفترات/أنواع الفوترة.
- Waiting يقرأ/يعدل `BuildingAssign` وعائلات الانتظار/الحالة والمستفيد والإعفاء؛ upload يكتب staging/log عند تشغيله، لكنه لم يُشغّل.
- IncomeSystem يقرأ/يعدل عائلات Deduct/BillDeduct/BuildingPayment/ExtendInsurance والفواتير والتدقيق.
- ElectronicBillSystem يقرأ/يعدل Meter/MeterForBuilding/MeterRead والتسعير والفترات والفواتير.

سجل الكتالوج 611 dependency row لكائنات `Housing`. لا يثبت هذا العدد عدد الجداول الفريد، ولا يلتقط كل SQL ديناميكي.

## Functions

الدالة المشتركة المباشرة: `dbo.ft_UserPagePermissions`.

دوال `Housing` الحية (33): `BuildingNoIsExist`, `FirstLineInHousingnDashBoard`, `fn_GetResidentID`, `GeneralNumberIsExist`, `GetActionDateForBuildingExit`, `GetBuildingNoByResidentGeneralNo`, `GetCountAllMeter`, `GetCountAllResident`, `GetCountBuildingForActionTypeID`, `GetCountBuildingForActionTypeWithClassID`, `GetCountBuildingFromUtilityType`, `GetCountBuildingWithClass`, `GetCountBuildingWithType`, `GetCountForActionTypeByDates`, `GetCountForHousingWithPrivteConditions`, `GetCountMeterForUtilityType`, `GetCountRentType`, `GetLastActionForBuilding`, `GetLastActionForResident`, `GetLastMeterReadFromOldSystem`, `GetRentForBuilding`, `GetResdintGeneralNumberByBuildingNo`, `CalculteElectrictyBills_ByLastActiveRead_PeriodSource`, `CalculteElectrictyBills_ByNewReadValue`, `CalculteElectrictyBills_ByNewReadValue_ForInsert`, `fn_BuildingAction_ChainToRoot`, `fn_BuildingRent_ForMonth`, `fn_CalcBuildingRent_ForOneMonth`, `fn_CalcMonthlyBuildingRent_ByBuildingDetailsID`, `FN_EligibleMeters`, `GetGeneralListActionForResident`, `GetListAllMetersReadByPeriodID`, و`GetListMeterSlidesPrice`.

## Triggers

| Trigger | الجدول | الحالة | الأثر المستنتج من التعريف الحي |
| --- | --- | --- | --- |
| `Housing.trg_BuildingAction_Audit` | `Housing.BuildingAction` | فعال | تدقيق تغييرات BuildingAction؛ قد يتداخل مع AuditLog الصريح ويحتاج اختباراً تشغيلياً. |
| `Housing.TR_BuildingPayment_SetLinkStatus` | `Housing.BuildingPayment` | فعال | يحدّث حالة ربط الدفعة وفق الربط/التصنيف المالي. |

كلا Triggerين موجودان حياً وغير موجودين كتعريفات Trigger في Snapshot.

## Gateway routing

الكتالوج الحي يحتوي 81 قيمة `pageName_` في `Masters_DataLoad` و65 في `Masters_CRUD` عبر النظام كله. ضمن البرامج المشمولة، routing المثبت يشمل:

- ControlPanel: `PagesManagment`, `Permission`, `Users`.
- Housing Definitions: `BuildingClass`, `BuildingDetails`, `BuildingType`, `buildingUtilityType/BuildingUtilityType`, `MilitaryLocation`.
- Housing Procedures: `HousingResident`, `HousingHandover`, `HousingExtend`, `HousingExit`.
- Waiting: `Residents`, `WaitingListByResident`, `WaitingListMoveList`, `WaitingList`, `OtherWaitingList`, `Assign`, `AssignStatus/ASSIGNSTATUS`, `RentExemption`.
- IncomeSystem: `ExtendInsurance`, `FinancialAuditForExtendAndEvictions`, `FinancialAuditForUser`, `ImportExcelForBuildingPayment`.
- ElectronicBillSystem: `Meters`, `AllMeterRead`, `MeterReadForOccubentAndExit`, `MeterServiceTypeFixedAmount`.
- Home: `Home` في DataLoad. Login يستدعي إجراءات الدخول مباشرة عبر `ProcedureMapper` وليس routing الصفحة.

`Masters_DataLoad` يحتوي أيضاً routes لبرامج مستبعدة؛ لم تُدخل في هذا التوثيق. `Masters_CRUD` الحي يطابق `ActionType` ويفحص الصلاحية في غالبية الفروع، مع الفجوات الأمنية الموثقة سابقاً حول ثقة سياق العميل وفرع HousingHandover.

## SQL Agent Jobs

لم تُستعلم Jobs. قائمة المصادر المسموح بها لا تشمل catalog جداول `msdb` الخاصة بـSQL Agent، و`sys.*` داخل DATACORE لا يثبت جدولة Job خارج القاعدة. لذلك تبقى جدولة `GenerateMonthlyRentBills` أو backfill/import وأي owner/schedule/step فجوة تحقق تشغيلية؛ لا يجوز استنتاج وجود Job من اسم الإجراء.

## Schema drift: Live مقابل Snapshot

### موجود حياً وغير موجود في Snapshot

- `Housing.trg_BuildingAction_Audit`.
- `Housing.TR_BuildingPayment_SetLinkStatus`.

### موجود في Snapshot وغير موجود حياً

لا يوجد كائن باسم مختلف/مفقود ضمن تعريفات `Housing` المقروءة والمطابقة الاسمية، ولا ضمن قائمة `dbo` المباشرة المختارة. ملفات البرامج المستبعدة ليست جزءاً من هذه النتيجة.

### اختلافات تعريف وظيفية مثبتة

تظل قائمة 07A مرجع الفروق التفصيلي: 11 إجراءً و`Housing.V_WaitingList` مختلفون عن Snapshot، وأهمها gateway routing، `UsersDL`, قواعد التسكين/الإمهال/الإخلاء، `AssignDL/SP`, و`BuildingRentForOneMonth`. مراحل IncomeSystem وElectronicBillSystem وHome/Login لم تضف drift وظيفياً جديداً إلى الإجراءات التي قارنتها.

### Drift وقيود بنيوية تحتاج عناية

- Triggerان حيان بلا ملفات مشروع؛ deployment من Snapshot قد يحذف أثرهما أو لا يعيد إنشاءه.
- FK `BuildingPayment_ -> BuildingPaymentType` غير موثوق.
- سبعة جداول Housing بلا PK حي.
- عدة أعمدة مسماة `_FK` بلا قيد فعلي؛ لا يجوز اعتبار الاسم سلامة مرجعية.
- توجد كائنات حية مؤرخة/بديلة مثل `BuildingRentForOneMonth_2026-05-12`, `V_Occupant_2026_02_04`, و`V_GetListMetersLinkedWithBuildings_2026_02_28`; وجودها موثق، لكن استخدامها النشط غير مثبت.

## الرسومات

- [ERD العام المختصر](../Diagrams/17-Live-Database-Overview-ERD.md)
- [ERD ControlPanel والصلاحيات](../Diagrams/18-ControlPanel-Permissions-ERD.md)
- [ERD Housing](../Diagrams/19-Housing-Live-ERD.md)
- [ERD IncomeSystem وElectronicBillSystem](../Diagrams/20-Income-and-Electronic-Billing-ERD.md)

كل رسم مستقل ومختصر للطباعة على A4. الخط المتصل المسمى FK يعني قيداً حياً؛ الخط المتقطع/الوسم “مستنتجة” يعني علاقة منطقية بلا FK.

## Coverage والفجوات

التغطية البنيوية للكائنات المحددة ضمن النطاق 100%: 274/274 كائناً جُردت أسماؤها وأنواعها، مع توثيق الجداول المحورية والمفاتيح والاعتماديات والتوقيعات والتعريفات. لا تعني هذه النسبة اختبار الأعمال.

الفجوات المتبقية:

1. لم تُنفذ الإجراءات، لذلك Result Sets مستنتجة من التعريفات وليست runtime verified.
2. لم تُقرأ بيانات أو seed values أو صلاحيات فعلية.
3. SQL Agent Jobs وبيئة التشغيل/النسخ الاحتياطي خارج whitelist الحالية.
4. SQL الديناميكي قد لا يظهر كاملاً في `sys.sql_expression_dependencies`.
5. لا يوجد E2E أو اختبار triggers أو imports أو فوترة شهرية.
6. معنى IDs الثابتة في BuildingActionType وغيرها لم يُثبت من seed data.

