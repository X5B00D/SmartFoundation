# توثيق Housing Procedures

> تحديث قاعدة البيانات 2026-08-23: فصل [التحليل النهائي](11-Live-Database-and-ERD.md) بين FKs الحية وروابط دورة الإقامة المستنتجة، ووثق Trigger التدقيق الحي على `BuildingAction` غير الموجود في Snapshot.

## الحالة والنطاق

- النطاق: `HousingResident` و`HousingHandover` و`HousingExtend` و`HousingExit` فقط.
- اكتمل التتبع من الكود النشط وSQL snapshot بتاريخ 2026-08-21، دون تنفيذ Stored Procedures أو تعديل قاعدة البيانات.
- **مثبت** يعني من MVC/Application النشط، و**Snapshot** يعني من مشروع `SmartFoundation.Database` المرجعي غير المضمون التطابق مع القاعدة الحية.
- المخرجات المصاحبة: [07-Housing-Procedures-End-to-End.md](../Diagrams/07-Housing-Procedures-End-to-End.md)، [08-Housing-Resident-Lifecycle.md](../Diagrams/08-Housing-Resident-Lifecycle.md)، [09-Housing-Procedures-Data-Impact.md](../Diagrams/09-Housing-Procedures-Data-Impact.md)، ودليل [Housing-Procedures.md](../UserManual/Housing-Procedures.md).

## المسار التنفيذي المشترك

كل صفحة GET جزء من `partial HousingController`: تنفذ `InitPageContext`، تقرأ `usersId/IdaraId/HostName`، ثم ترسل array موضعية إلى `MastersServies.GetDataLoadDataSetAsync`. يحول `MastersServies` القيم إلى `pageName_`, `idaraID`, `entrydata`, `hostname`, `parameter_01..50` ويحل `MastersDataLoad:getData` عبر `ProcedureMapper` إلى `dbo.Masters_DataLoad`. تعيد البوابة permission result set أولاً ثم تنفذ DL الخاص بالصفحة.

الـ Views الأربع رقيقة ومتطابقة: تضبط العنوان وتستدعي `SmartRenderer`. يبني Controller `SmartPageViewModel`, `SmartTableDsModel`, `FormConfig` وحقول `p01..pNN`. الكتابة تمر عبر `/crud/insert|update|delete` إلى `CrudController`، ثم `MastersServies.GetCrudDataSetAsync` و`dbo.Masters_CRUD`. تفحص البوابة الصفحة والصلاحية، تحول المعاملات إلى عقد SP، ثم تعيد `IsSuccessful/Message_` إلى `TempData` وredirect.

## مصفوفة الصفحات

| الصفحة | Action/View | Result sets بعد الصلاحية | العمليات | الغرض |
| --- | --- | ---: | ---: | --- |
| HousingResident | `HousingResident(int pdf=0)` / `HousingProcedures/HousingResident` | 1 فعلياً؛ 5 DDL calls تطلب جداول غير معادة | 3 | العهد، اعتماد التسكين، إلغاء التسكين |
| HousingHandover | `HousingHandover()` / `HousingProcedures/HousingHandover` | 3 | 1 | تمرير المبنى بين حالات/جهات التسليم |
| HousingExtend | `HousingExtend(int pdf=0,int? rowId=null)` / يعيد خطأً View `HousingResident` | 3 | 6 | طلب الإمهال، مراجعته مالياً، التأمين، الاعتماد |
| HousingExit | `HousingExit(int pdf=0,int? rowId=null)` / `HousingProcedures/HousingExit` | 1 فعلياً؛ 5 DDL calls تطلب جداول غير معادة | 6 | طلب الإخلاء، الغرامات، المالية، الاعتماد |

أوضاع `pdf` فروع داخل Actions وليست Actions مستقلة. `HousingExit` يدعم البحث بـ `NID` ويمرره `parameter_01`; إذا لم توجد نتيجة يضع تحذيراً. `HousingHandover` يتطلب query `U` للحالة الحالية، ويعرض اختيار الحالة قبل الجدول.

## HousingResident

### الواجهة والعقد

تعرض سجلات `V_WaitingList` ضمن الإدارة، مع بيانات المستفيد والمبنى وآخر حركة وعدد العدادات. العمليات:

| ActionType / صلاحية | واجهة المستخدم | أهم الحقول |
| --- | --- | --- |
| `HOUSINGESRESIDENTSCUSTDY` | تسجيل العهد والملاحظات | `p01 ActionID`, `p02 residentInfoID`, `p12 CustdyRecord/notes`, `p18 buildingDetailsID`, `p21 LastActionID`, `p22 meterscount` |
| `HOUSINGESRESIDENTS` | تسكين نهائي | السابق + `p23` رقم خطاب، `p24` تاريخه، `p25` تاريخ التسكين |
| `CANCELHOUSINGRESIDENT` | إلغاء التسكين | السابق + `p12` سبب الإلغاء؛ بيانات الخطاب/التسكين مخفية |

الصلاحيات الثلاث تتحكم في `ShowEdit`, `ShowEdit1`, `ShowDelete`. حالات تلوين UI الظاهرة: 45 موافقة منزل، 46 انتظار قراءة عدادات مع خدمات، 47 بلا خدمات، و2 ساكن.

### SQL والقواعد

- **Snapshot read:** `Masters_DataLoad -> HousingResidentDL -> V_WaitingList + V_GetFullResidentDetails + BuildingActionType`، مع subquery إلى `MeterForBuilding`. الفلتر `IdaraId=@idaraID` وحالات `LastActionTypeID IN (45,46,47,2)`.
- العهد: يتطلب ملاحظات في واجهة المستخدم. SP يقبل الفرع `HOUSINGESRESIDENTSCUSTDY` لكنه validation المشترك مكتوب على الاسم غير المستخدم `CustdyRecord`؛ ثم يشترط سجل موجوداً وحالة 45، وينشئ حركة 46 إذا للمبنى عدادات و47 إن لم توجد.
- التسكين: يمنع وجود المستفيد في `V_Occupant` بإدارة أخرى أو أثناء الإخلاء، ويشترط ActionID وحالة 47. ينشئ حركة نوع 2، يستدعي `BackfillResidentServiceBills`، وينشئ فاتورة إيجار عبر `fn_CalcMonthlyBuildingRent_ByBuildingDetailsID` إن أعادت قيمة.
- الإلغاء: يتطلب معرفات صحيحة وسبباً، ويقفل حركة 45 بـ `UPDLOCK/HOLDLOCK` ويتأكد أنها آخر حركة. يتتبع parent: 38 تعود إلى 39 (رفض تخصيص أول)، و40 إلى 42 (إلغاء أهلية نهائي)، ثم ينشئ الحركة الجديدة.
- لا يوجد UPDATE/DELETE فعلي لـ `BuildingAction`; “التعديل/الإلغاء” append-only state transitions. الفواتير المولدة ليست soft delete في هذا الفرع.
- كل فرع ناجح يكتب `dbo.AuditLog`. `XACT_ABORT` وtransaction محروسة بـ `@@TRANCOUNT`; 50001 للأعمال، 50002 لفشل insert/identity/rent، وCATCH يعمل rollback ثم يعيد الخطأ.

### أثره على البرامج الأخرى

اعتماد السكن يجعل المستفيد ضمن `V_Occupant` الذي تعتمد عليه إجراءات الإخلاء، ويولد `Bills` التي تظهر في التدقيق المالي والفواتير الإلكترونية/الدخل حسب المستهلكين اللاحقين. هذا **أثر بيانات مثبت في Snapshot**؛ مسار UI داخل IncomeSystem/ElectronicBillSystem لم يُتتبع في هذا النطاق.

## HousingHandover

### الواجهة والحالات والصلاحيات

الصفحة تختار الحالة الحالية `U`, ثم تحمل المباني التي آخر حالتها تطابقها. `HousingHandoverDL` يعيد: (1) المباني، (2) حالات المصدر المسموح بها للمستخدم، (3) الحالات التالية المسموحة من جدول `BuildingHandover`. النموذج يرسل `p01` المبنى، `p02` رقمه، `p07` الحالة التالية، `p10` الحالية، `p11` الملاحظات، `p12` آخر حركة.

زر الإجراء يظهر إذا امتلك المستخدم أياً من خمس صلاحيات مسؤول: الصيانة، الجودة، الخدمات العامة، الإسكان، أو التنفيذ. داخل DL تقيد الحالات أيضاً بـ `permissionTypeRoleID=20` من `dbo.V_GetListUserPermission`.

**فجوة أمنية Snapshot:** `Masters_CRUD` لصفحة HousingHandover علق شرط `permissionTypeName_E=@ActionType`؛ يفحص وجود أي صلاحية للصفحة فقط، خلاف gating الدقيق في الواجهة وDL.

### Validation وBusiness Rules

- Action الوحيد `HousingHandoverAction`; يتطلب معرف/رقم المبنى، الحالة الحالية والتالية، والملاحظات.
- يمنع تكرار نفس `LastActionID` كأب لحركة فعالة.
- ينشئ `BuildingAction` بالحالة التالية، ويربطها بآخر حركة، ويأخذ alias/message من `BuildingActionType`.
- Transaction و50001/50002 وAuditLog موجودة؛ لا update/delete ولا soft delete.
- جدول `BuildingHandover` هو مصفوفة الانتقالات والصلاحيات، لا سجل تنفيذ؛ التنفيذ يضاف في `BuildingAction`.

## HousingExtend

### الواجهة والصلاحيات

| ActionType المرسل | صلاحية UI | الوظيفة |
| --- | --- | --- |
| `HOUSINGEXTEND` | `HOUSINGEXTEND` | إنشاء طلب إمهال |
| `EDITHOUSINGEXTEND` | `EDITHOUSINGEXTEND` | تعديل الطلب كحركات جديدة |
| `CANCELHOUSINGEXTEND` | `CANCELHOUSINGEXTEND` | إلغاء الطلب والرجوع لأصل الإقامة |
| `SENDHOUSINGEXTENDTOFINANCE` | نفسها | إرسال للتدقيق المالي |
| `EXTENDINSURANCE` | نفسها | تسجيل التأمين الاحترازي |
| `ApproveExtend` | Controller يبحث عن `APPROVEEXTEND` | اعتماد الإمهال |

الحقول الأساسية: خطاب الموافقة وتاريخه `p22/p23`، البداية والنهاية `p24/p25`، الملاحظات `p26`، السبب `p27`. التأمين يعرض غير المسدد `p28`، إيجار المبنى `p29`، مبلغ التأمين `p30` والإجمالي `p31`، رقم/تاريخ/نوع وثيقته `p33/p35/p36`. DL يعيد جدول البيانات، أسباب الإمهال، وأنواع التأمين.

### الحالات والقواعد

- البداية: من حالة 2 ينشئ 48، ومن 48 ينشئ 49؛ غير ذلك 50001.
- التعديل يتطلب حالة 48؛ ينشئ 50 ثم 48 جديدة، أي يحفظ التاريخ ولا يعدل صفاً.
- الإلغاء يتطلب 48؛ ينشئ 50 ثم ينسخ حركة الإقامة الأصلية نوع 2 من `fn_BuildingAction_ChainToRoot`.
- الإرسال المالي يتطلب 48 وينشئ 51، ويمنع الإرسال المكرر.
- التأمين يتطلب انتهاء المالية/حالة 61 وسبباً `InsuranceRequired=1` وعدم وجود تنفيذ سابق؛ المبلغ لا يكون صفراً. ينشئ حركة 61 وسجل `ExtendInsurance` فعالاً وAudit لكل منهما.
- الاعتماد يتطلب الحالة المالية الملائمة، ويشترط تنفيذ التأمين إن كان السبب يتطلبه، ثم ينشئ حالة 24.
- التواريخ ورقم/تاريخ خطاب الموافقة مطلوبة، والنهاية أكبر من البداية.
- transaction شاملة، 50001 business و50002 execution، وAuditLog لكل انتقال.

### فجوات مؤكدة

1. validation المشترك يسمي `EditExtend/SendExtendToFinance` بينما الفروع الفعلية uppercase؛ بعض الفروع لا تستفيد منه.
2. UI يرسل `ApproveExtend` لكن permission flag اسمه `APPROVEEXTEND`; تعتمد المطابقة في البوابة على وجود صلاحية باسم ActionType المرسل، ما قد يمنع الاعتماد إن كانت الصلاحية المسجلة uppercase.
3. Action يرجع `View("HousingProcedures/HousingResident", page)` بدل `HousingExtend`; لأن الـ Views متطابقة قد يبدو العرض صحيحاً لكن المسار غير متسق.
4. رسالة نجاح `EXTENDINSURANCE` تقول اعتماد طلب الإمهال، لا تسجيل التأمين.

## HousingExit

### الواجهة والصلاحيات

العمليات الست: `HOUSINGEXIT`, `HOUSINGEXITPENALTYRECORD`, `EDITHOUSINGEXIT`, `CANCELHOUSINGEXIT`, `SENDHOUSINGEXITTOFINANCE`, `APPROVEHOUSINGEXIT`. كل واحدة لها flag مطابق في Controller وتظهر في أزرار الجدول. الطلب/التعديل يستخدمان تاريخ الإخلاء `p22` وملاحظات؛ الغرامة تستخدم الإجمالي `p40`, `BillsID p41`, التفاصيل `p31`, وعدد العدادات `p42`.

### الحالات والقواعد والآثار

- الإنشاء من حالة 2 أو 24 فقط، وينشئ 54 ثم يستدعي `GenerateExitRentBills` لتسوية إيجار الخروج.
- التعديل يتطلب 54؛ ينشئ حركة إلغاء/تاريخ 55 ثم 54 جديدة ويعيد توليد إيجار الخروج.
- الإلغاء يتطلب 54؛ يستدعي مولد الفواتير، يعطل `Bills` للغرامة (charge 5) وفواتير الخدمات النهائية (charges 2/3/4 مع type 3)، ويعطل `MeterRead` المرتبط، ثم ينشئ حركة إلغاء ويعيد نسخ أصل الإقامة من chain. هذه هي الحذف المنطقي الفعلي للآثار المالية/القراءات.
- الإرسال للمالية يمنع التكرار وينشئ حالة تالية (المسار UI يلون 58/59/60 ضمن مراحل الإخلاء).
- الاعتماد لا يتم قبل انتهاء التدقيق المالي؛ ينشئ حركة الاعتماد ويقصر أي `ResidentRentExemption` فعال حتى تاريخ الإخلاء.
- الغرامات متاحة فقط في الحالة المسموحة؛ تنشئ حركة وسجل `Bills` charge type 5، أو تعطل الفاتورة القديمة وتنشئ بديلاً عند التعديل؛ لا تعدل الفاتورة مكانياً.
- `HousingExitDL` يقرأ `V_WaitingList`, `V_GetFullResidentDetails`, `BuildingActionType`, `Bills`, `MeterForBuilding`، ويعيد حالة/فاتورة الغرامة وعدد العدادات. يدعم NID ويقيد الإدارة.
- transaction وAuditLog في الفروع؛ 50001 للقواعد و50002 لفشل الحركة/الفاتورة/identity. رسالة نجاح الإرسال المالي تقول خطأً “طلب الإمهال”.

### أثره على البرامج الأخرى

يؤثر مباشرة في `Bills`, `MeterRead`, `ResidentRentExemption` وحالة الإشغال. بالتالي تتغير المطالبات التي تستهلكها شاشات التدقيق المالي والفواتير/الدخل، وتصبح إعادة تسكين المستفيد ممكنة فقط بعد خروجـه من `V_Occupant`. لا يُدّعى اكتمال مسارات البرامج الأخرى دون تتبعها في مراحلها المخصصة.

## الترابط بين العمليات الأربع

1. `HousingHandover` يمرر المبنى عبر حالات الجاهزية/التسليم التي تغذي سلسلة `BuildingAction`.
2. `HousingResident` يحول موافقة المنزل 45 إلى انتظار عدادات 46 أو جاهزية 47، ثم إلى ساكن 2، وينشئ الالتزامات الأولية.
3. من ساكن 2 يمكن بدء `HousingExtend` (48...) أو `HousingExit` (54...). الإمهال المعتمد 24 يظل مؤهلاً لبدء الإخلاء.
4. إلغاء الإمهال يعيد حركة الإقامة الأصلية؛ إلغاء الإخلاء يعيد أصل الإقامة ويلغي الآثار المالية النهائية؛ اعتماد الإخلاء ينهي الإعفاء ويقود لخروج المستفيد من الإشغال.
5. العمود `buildingActionParentID` و`fn_BuildingAction_ChainToRoot` يحفظان شجرة التاريخ؛ لذلك الحالات هي ledger وليست status column واحداً.

## كائنات SQL الموثقة

### Procedures

`dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `HousingResidentDL/SP`, `HousingHandoverDL/SP`, `HousingExtendDL/SP`, `HousingExitDL/SP`, `BackfillResidentServiceBills`, `GenerateExitRentBills`.

### Tables

`Housing.BuildingAction`, `BuildingActionType`, `BuildingHandover`, `MeterForBuilding`, `Bills`, `MeterRead`, `ExtendReasonType`, `ExtendInsuranceType`, `ExtendInsurance`, `ResidentRentExemption`, و`dbo.AuditLog`. `AssignPeriod` ورد في SQL مع result set معلق، فلا يعد نتيجة فعلية.

### Views

`Housing.V_WaitingList`, `V_GetFullResidentDetails`, `V_GetGeneralListForBuilding`, `V_Occupant`, `V_buildingWithRent`, `V_SumBillsTotalPriceAndTotalPaidForResident`, و`dbo.V_GetListUserPermission`.

### Functions

`dbo.ft_UserPagePermissions` في بوابة القراءة، `Housing.fn_CalcMonthlyBuildingRent_ByBuildingDetailsID`, و`Housing.fn_BuildingAction_ChainToRoot`.

## المعاملات والأخطاء وAudit

الـ SPs الأربعة تستخدم `SET XACT_ABORT ON`, `BEGIN TRY/CATCH` ومعاملة تبدأ فقط عند `@@TRANCOUNT=0`; النجاح يعمل commit للمعاملة المحلية، والفشل rollback ثم `THROW`. 50001 أخطاء أعمال قابلة للعرض؛ 50002 فشل برمجي/كتابة/identity. `Masters_CRUD` يعامل 50001..50999 كرسالة أعمال، ويسجل غير المتوقع في `dbo.ErrorLog` ويعيد رسالة عامة. كل العمليات الـ16 تكتب AuditLog؛ التأمين يكتب أثرين للحركة وسجل التأمين.

## Coverage

| البند | التغطية |
| --- | ---: |
| صفحات/Controller files/Views | 4/4 لكل منها |
| MVC Actions | 4/4؛ أوضاع PDF فروع داخلية |
| Feature DL/SP | 8/8 |
| عمليات كتابة | 16/16: 3 + 1 + 6 + 6 |
| صلاحيات/مفاتيح إظهار | 20 موثقة: 3 + 5 handover roles + 6 للتمديد + 6 للإخلاء |
| DataSet feature result sets | 8: Resident 1، Handover 3، Extend 3، Exit 1؛ إضافة إلى 4 permission sets |
| Workflows/رسومات | 3 |

التغطية 100% للأسطح المطلوبة في المستودع، لا تعني تطابق DB الحية أو نجاح E2E.

## الفجوات

- **فجوة تاريخية أُغلقت في 07A:** لم يكن Snapshot مقارناً حياً عند كتابة المرحلة؛ تمت المطابقة في 2026-08-22. لم تنفذ إجراءات أعمال.
- لا توجد اختبارات آلية مخصصة ولا تحقق browser للـ modals وشروط ظهور الأزرار.
- DDL calls الخمسة في Resident وExit تطلب indexes غير موجودة في DL الحالي.
- فروق أسماء Actions في Extend، وضعف فحص Handover، وView الخاطئة للتمديد موضحة أعلاه.
- أسماء/معاني جميع IDs في `BuildingActionType` لا يمكن إثباتها من schema وحده؛ استخدمت معاني الفروع ورسائل UI فقط.
- أثر IncomeSystem/ElectronicBillSystem موثق على مستوى الجداول المشتركة فقط، ويحتاج تتبعاً مستقلاً داخل كل برنامج.

## تحديث المطابقة الحية 2026-08-22

- DLs الأربعة و`HousingHandoverSP` و`BackfillResidentServiceBills` مطابقة حياً.
- `HousingResidentSP` الحي يفرض تاريخ تسكين صالحاً ولاحقاً لآخر إخلاء، ويتحقق من سلسلة الحركة والتخصيص 38/40 وحالة المبنى قبل التسكين.
- `HousingExtendSP` الحي يحول مبالغ التأمين إلى `decimal(18,2)` ويرفض غير الرقمي والإجمالي `<=0`; فرق `HousingExtendDL` هو literal `40` مقابل `40.00`.
- `HousingExitSP` الحي وسع الغرامة وفوترة الخروج باستخدام `BillPeriod`, `BillPeriodType`, `BillChargeType`, `dbo.Tax` وتواريخ الفترة؛ `GenerateExitRentBills` مختلف صياغياً فقط في `THROW`.
- اكتُشف Trigger حي `Housing.trg_BuildingAction_Audit` على `BuildingAction`، إضافة إلى AuditLog الصريح.
