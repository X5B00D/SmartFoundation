# توثيق ElectronicBillSystem

> تحديث قاعدة البيانات 2026-08-23: العدد 38 FK في هذه المرحلة كان subset للاستعلام المباشر، وليس إجمالي Schema. الجرد النهائي يثبت 75 FK في `Housing` وTriggerين حيين؛ التفاصيل في [تحليل DATACORE](11-Live-Database-and-ERD.md).

## النطاق ودرجة الإثبات

- الصفحات: `Meters`، `AllMeterRead`، `MeterReadForOccubentAndExit`، `MeterServiceTypeFixedAmount`.
- سلوك MVC والتطبيق مثبت من الكود النشط بتاريخ 2026-08-23.
- اكتملت القراءة الحية من `DATACORE` بتاريخ 2026-08-23 باستخدام PowerShell و`System.Data.SqlClient` واستعلامات SELECT محصورة في `sys.databases`, `sys.objects`, `sys.sql_modules`, `sys.parameters`, `sys.sql_expression_dependencies`, `sys.foreign_keys` و`sys.triggers`.
- تحققت 8 إجراءات feature و3 بوابات: كلها موجودة ومطابقة وظيفياً للـSnapshot بعد توحيد `CREATE/ALTER` والمسافات وتأهيل `[DATACORE]`. لم ينفذ أي Business Stored Procedure أو DML/DDL، ولم تقرأ بيانات أعمال أو أسرار.

## البنية المشتركة ومسار التطبيق

`ElectronicBillSystemController` Controller منطقي واحد موزع على Base وأربعة ملفات صفحات. `InitPageContext` يفرض وجود `usersID` في Session ويقرأ `IdaraId/usersId/HostName`. `SplitDataSet` يفسر الجدول 0 كصلاحيات و`dt1..dt9` كبيانات. لا توجد Models خاصة بالمجال؛ الصفحات تبني `SmartPageViewModel`, `SmartTableDsModel`, `FormConfig`, `FieldConfig`, `OptionItem` و`SmartPrintModel` من `DataTable` ديناميكي. Views الأربع رقيقة وتستدعي `SmartRenderer`، مع رسائل TempData في AllMeterRead والأسعار الثابتة.

المسار المثبت تطبيقياً:

`View -> ElectronicBillSystemController -> MastersServies.GetDataLoadDataSetAsync -> ProcedureMapper -> SmartComponentService -> dbo.Masters_DataLoad`.

الكتابة: `Form -> /crud/insert|update|delete -> CrudController -> MastersServies.GetCrudDataSetAsync -> dbo.Masters_CRUD`. يحمل النموذج `pageName_`, `ActionType`, `idaraID`, `entrydata`, `hostname` و`p01..p50`، وتحول البوابة الموضعية الأخيرة إلى `parameter_01..50`. ربط البوابات بإجراءات Housing أدناه متحقق حياً.

## ملخص الصفحات

| الصفحة | الهدف | GET/View | مسار SQL الحي المثبت |
| --- | --- | --- | --- |
| `Meters` | تعريف العدادات وأنواعها وربطها بالمباني | `Meters(int pdf=0)` -> `Meter/Meters.cshtml`؛ ثلاث جداول Smart | `Masters_DataLoad -> Housing.MetersDL`; CRUD -> `Masters_CRUD -> Housing.MetersSP` |
| `AllMeterRead` | فتح/إغلاق فترة شهرية وتسجيل قراءات الكهرباء والماء والغاز وتعديلها/حذفها | `AllMeterRead(int pdf=0)`؛ فلتر `U=MeterServiceTypeID`; `MeterRead/AllMeterRead.cshtml` | `Masters_DataLoad -> Housing.AllMeterReadDL`; CRUD -> `Housing.AllMeterReadSP`; التفاصيل المرنة تستخدم forms بعمليات `MeterLastBill`, `MeterNewBill`, `EditBill` |
| `MeterReadForOccubentAndExit` | قراءات التسكين والإخلاء وربط اعتمادها بحركة المبنى/السكان والفواتير | `MeterReadForOccubentAndExit(int pdf=0)`؛ `U=residentInfoID`; View بالاسم نفسه | `Masters_DataLoad -> Housing.MeterReadForOccubentAndExitDL`; CRUD -> SP المناظر؛ DDL إضافي للساكن من result set 2 |
| `MeterServiceTypeFixedAmount` | إدارة مبلغ ثابت لكل خدمة وإدارة وتاريخ سريانه | GET واحد -> `Services/MeterServiceTypeFixedAmount.cshtml` | `Masters_DataLoad -> Housing.MeterServiceTypeFixedAmountDL`; CRUD -> SP المناظر |

## Meters

### Result sets وDDL

بعد permissions، يعيد `MetersDL` الحي ثمانية feature sets:

1. `dt1`: العدادات الفعالة مع نوع الخدمة، نوع العداد، طريقة الحساب، السعر/المبلغ الثابت وأول قراءة من `MeterRead` بنوع 4.
2. `dt2`: أنواع العدادات الفعالة مع الخدمة وطريقة الحساب والسعر أو المبلغ الثابت.
3. `dt3`: روابط العداد بالمبنى من `MeterForBuilding` و`V_GetGeneralListForBuilding`.
4. `dt4`: خدمات العدادات المفعلة للإدارة عبر `MeterServiceTypeLinkedWithIdara`.
5. `dt5`: أنواع العدادات المتاحة للإدارة والخدمة.
6. `dt6`: عدادات فعالة غير مرتبطة حالياً بمبنى.
7. `dt7`: المباني الفعالة مع ملخص عدد العدادات حسب الخدمة.
8. `dt8`: طرق الحساب الفعالة من `MeterCalculateType`.

الـController يطلب DDL indexes 5 و4 و7 و8؛ كما يستخدم `DDLFiltered` لتصفية نوع العداد بالخدمة والعداد بالنوع. هذه الأرقام عقود DataSet موضعية وليست أسماء مستقرة.

### العمليات والصلاحيات

| العملية | ActionType | أثر Snapshot |
| --- | --- | --- |
| إضافة نوع عداد | `INSERTNEWMETERTYPE` | إدراج `MeterType` ثم `MeterServicePrice` إذا طريقة الحساب 1 أو `MeterTypeFixedAmount` عند النوع الثابت |
| تعديل نوع عداد | `UPDATENEWMETERTYPE` | إنهاء/تحديث التعريف والأسعار التابعة وفق طريقة الحساب |
| حذف نوع عداد | `DELETENEWMETERTYPE` | تعطيل منطقي بعد فحوص الارتباط |
| إضافة عداد | `INSERTNEWMETER` | إدراج `Meter` وقراءة ابتدائية `MeterRead` |
| تعديل عداد | `EDITNEWMETER` | تحديث بيانات العداد |
| حذف عداد | `DELETENEWMETER` | تعطيل منطقي مع منع الحذف عند الاعتماديات |
| ربط بمبنى | `LINKMETERTOBUILDINGS` | إدراج `MeterForBuilding` وقراءة الربط |
| فك الربط | `UNLINKMETERTOBUILDINGS` | إنهاء الرابط وتسجيل قراءة الفصل |

الـController لا يقرأ سوى أربع صلاحيات: `INSERTNEWMETER`, `INSERTNEWMETERTYPE`, `UPDATENEWMETERTYPE`, `DELETENEWMETERTYPE`. أزرار تعديل/حذف العداد والربط/الفصل موجودة في التكوين، لكن لا توجد booleans مقابلة مستقلة ظاهرة في حلقة الصلاحيات؛ هذه فجوة UI يجب اختبارها. البوابة الحية تفحص `permissionTypeName_E = ActionType` لكل العمليات الثماني، والـcollation الحية `SQL_Latin1_General_CP1_CI_AS` غير حساسة للحالة.

### قواعد الأعمال والعلاقات

- الاسم العربي لنوع العداد يجب ألا يتكرر داخل الإدارة.
- نوع الحساب يحدد هل التسعير شرائح/سعر خدمة أم مبلغ ثابت على نوع العداد.
- العداد يتبع `MeterType`، والنوع يتبع `MeterServiceType` و`MeterCalculateType`.
- `MeterForBuilding` يحقق العلاقة الزمنية بين العداد و`BuildingDetails`; الارتباط الفعال واحد في الاستعلام، والفصل لا يحذف التاريخ.
- القراءة الابتدائية/قراءة الربط تحفظ في `MeterRead` وتصبح أساس الاستهلاك اللاحق.
- `IdaraId` يقيد العدادات والأنواع والمباني والخدمات. القيم والسياق تصل إلى CRUD من client-hidden fields وفق العقد المشترك.

لا توجد طباعة فعلية في الصفحة؛ flags للطباعة/PDF معطلة رغم وجود imports لتقارير.

## AllMeterRead

### Result sets وواجهة العمل

`AllMeterReadDL` الحي يأخذ `meterServiceTypeID_FK` إضافة إلى السياق ويعيد أربعة feature result sets: الفترة والعدادات، فواتير الفترة، خدمات الإدارة، والعدادات دون فاتورة في الفترة. Controller يستنتج الفترة الحالية من `dt1.billPeriodID` ويعرض فتح الفترة إن لم توجد، وإغلاقها إن وجدت. يستخدم `dt4` كقائمة عدادات، ويقسم العرض إلى جداول خدمة كهرباء/ماء/غاز بحسب الخدمة المختارة. نتيجة permissions لا تُفرض للوصول: كتلة رفض الصفحة معلقة، لكن booleans العمليات تتحكم بالأزرار.

المصادر الحية تشمل `BillPeriod`, `BillPeriodType`, `MeterServiceType`, `Meter`, `MeterType`, `MeterForBuilding`, `MeterRead`, `Bills`, `FN_EligibleMeters`, `V_GetListMeterSlidesPrice` و`V_GetListMetersLinkedWithBuildings`.

### العمليات والصلاحيات

- إدارة الفترة: `OPENMETERREADPERIOD`, `CLOSEMETERREADPERIOD`.
- كهرباء: `READELECTRICITYMETER`, `EDITELECTRICITYMETER`, `DELETEELECTRICITYMETER`.
- ماء: `READWATERMETER`, `EDITWATERMETER`, `DELETEWATERMETER`.
- غاز: `READGASMETER`, `EDITGASMETER`, `DELETEGASMETER`.

أسماء Controller وforms والبوابة الحية متطابقة حرفياً. الإجراء الحي يجمع عمليات القراءة الثلاث في فروع مشتركة، وكذلك التعديل والحذف. الفتح ينشئ فترة شهرية لخدمة/إدارة؛ الإغلاق يتطلب اكتمال القراءات ويثبت الفترة. القراءة تتحقق من الفترة والعداد والقيمة السابقة/القصوى والتكرار، تنشئ `MeterRead` ثم `Bills` للاستهلاك وفق نوع الحساب والأسعار/الشرائح والضريبة. التعديل يعيد بناء القراءة/المطالبة المرتبطة، والحذف يعطل القراءة والفاتورة منطقياً. أخطاء الأعمال تستخدم `THROW 50001` والمعاملات تستخدم `XACT_ABORT/TRY-CATCH`.

`pdf=1` يولد تقرير QuestPDF landscape من DataTable، لكن عناوين export الداخلية منسوخة من «إمهال المستفيدين» وبعض أسماء الملفات/العناوين لا تعكس العدادات؛ فجوة جودة تقرير. لا يوجد اختبار بصري أو تنفيذ PDF في هذه المرحلة.

## MeterReadForOccubentAndExit

### Workflow وResult sets

يختار المستخدم ساكناً من `dt2`، ثم يعرض `dt1` عدادات المبنى المرتبطة بحركة Housing الحالية. الحقول تجمع `ActionID`, resident/identity/general number, قرار الحركة، waiting class/order، `buildingDetailsID`, meter/service/type، القراءة السابقة والقصوى، `meterReadID`, `BillsID`, `LastActionTypeID`, `AssignPeriodID`, `LastActionID`, `buildingActionRoot` وحالة اكتمال القراءة.

الـDL الحي يعيد result set العدادات والحركة ثم DDL السكان، ويربط `V_WaitingList`, `V_GetFullResidentDetails`, `BuildingAction`, `MeterForBuilding`, `Meter/MeterType/MeterServiceType`, `MeterRead` و`Bills`. هذا هو جسر ElectronicBillSystem إلى Housing: حركة التسكين أو الإخلاء تحدد المبنى والساكن والجذر والتاريخ، والعدادات المرتبطة تحدد القراءات المطلوبة.

### العمليات والصلاحيات

| الصلاحية المقروءة | ActionType المرسل | الغرض |
| --- | --- | --- |
| `MeterReadForOccubentAndExit` (case-insensitive في C#) | `METERREADFOROCCUBENTANDEXIT` | إدخال القراءة |
| `UpdateMeterReadForOccubentAndExit` | `UPDATEMETERREADFOROCCUBENTANDEXIT` | تعديل قراءة قبل الاعتماد |
| `APPROVEMETERREADFOROCCUBENTANDEXIT` | نفسه | اعتماد كل القراءات وإنشاء انتقال Housing التالي |

هنا يوجد اختلاف حالة/صياغة بين اسمي permission الأولين في Controller وActionTypes العليا. البوابة الحية تطلب مساواة permission بالـActionType، لكن collation الحية غير حساسة للحالة؛ اختلاف الحالة وحده لا يسبب الرفض. يبقى اختلاف الاسم الكامل بحاجة إلى بيانات permission الفعلية لإثبات أثره.

الإجراء الحي يميز جذر التسكين عن الإخلاء، يمنع قراءة أقل من السابقة إلا ضمن wrap/max-read، يمنع التكرار، وينشئ أو يحدث `MeterRead` و`Bills`. الاعتماد يتطلب اكتمال جميع عدادات المبنى، ثم ينشئ `BuildingAction` جديداً ويكتب `dbo.AuditLog`. علاقات resident/building/meter/bill عديدة إجرائية وليست كلها FKs.

الصفحة تملك `pdf=1` لتقرير رسمي landscape، لكن أزرار الطباعة/التصدير في الجدول معطلة؛ يلزم التحقق من إمكانية الوصول الفعلية للرابط ومن جودة التقرير.

## MeterServiceTypeFixedAmount

### Result sets وDDL

الـDL الحي يعيد بعد permissions:

1. الأسعار الثابتة الفعالة للإدارة مع اسم `MeterServiceType` وتاريخ البدء/النهاية.
2. الخدمات التي لا يوجد لها مبلغ ثابت فعال في الإدارة، وتستخدمها `GetDDLValues` بـindex 2.

### العمليات والقواعد

- `INSERTSERVICEFIXEDAMOUNT`: يتطلب الخدمة والمبلغ وتاريخ البدء، يمنع سجل فعال مكرر، يدرج السعر، وينشئ `MeterServiceTypeLinkedWithIdara` إن لم يوجد.
- `EDITSERVICEFIXEDAMOUNT`: لا يحدث القيمة مكانياً؛ يغلق السجل القديم بتاريخ نهاية ثم يدرج نسخة فعالة جديدة، محافظاً على التاريخ.
- `DELETESERVICEFIXEDAMOUNT`: soft delete بإلغاء active ووضع تاريخ النهاية.
- الصلاحيات الثلاث في Controller مطابقة لأسماء ActionType العليا: `INSERTSERVICEFIXEDAMOUNT`, `EDITSERVICEFIXEDAMOUNT`, `DELETESERVICEFIXEDAMOUNT`.
- التعريف الحي يؤكد عيب التدقيق: فرع الحذف يكتب `RecordID = ISNULL(@NewID,0)` رغم أن الحذف لا يملأ `@NewID`، فيسجل غالباً 0. كما تستخدم JSON notes مفتاح `buildingClassActive` المنسوخ بدلاً من اسم المجال.

زر export العام مهيأ داخلياً لكن `ShowExportPdf=false`; لا يوجد تقرير خاص فعلي للصفحة.

## التكامل مع Housing وIncomeSystem

- Housing يملك schema الفعلي: `BuildingDetails`, `BuildingAction`, resident views و`MeterForBuilding`. التسكين والإخلاء يحددان من يتحمل الاستهلاك وفي أي فترة، واعتماد قراءة الدخول/الخروج يكمل انتقال حالة المبنى.
- ElectronicBillSystem يحول القراءة إلى `Bills` بحسب `BillPeriod`, الخدمة، طريقة الحساب، الأسعار/الشرائح والمبلغ الثابت والضريبة.
- IncomeSystem يستهلك `Bills` و`BillChargeType` وملخصات المقيم في التدقيق والتسوية، ثم يسجل التحصيل/الاسترداد في `DeductList` و`BuildingPayment`. لذلك تعديل/حذف قراءة بعد نشوء دفع قد يغير أساساً مالياً؛ الإجراءات الحية تفحص الروابط، ويبقى اختبار الأثر الفعلي خارج نطاق قراءة catalog.
- أسعار `MeterServiceTypeFixedAmount` تخص الخدمة على مستوى الإدارة، بينما `MeterTypeFixedAmount` يخص نوع عداد وطريقة حسابه؛ الخلط بينهما يغير نطاق الفوترة.

## Live مقابل Snapshot

التصنيف الحي النهائي:

- **Live verified and matching (11):** `dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `dbo.Masters_ExtraDataLoad`, `Housing.MetersDL/SP`, `Housing.AllMeterReadDL/SP`, `Housing.MeterReadForOccubentAndExitDL/SP`, `Housing.MeterServiceTypeFixedAmountDL/SP`.
- **Live verified with differences:** لا يوجد ضمن النطاق.
- **Missing from live:** لا يوجد ضمن النطاق.
- التوقيعات الحية: البوابات 24 و55 و15 معاملاً؛ `MetersDL/SP` أربعة و29؛ `AllMeterReadDL/SP` خمسة و30؛ `MeterReadForOccubentAndExitDL/SP` خمسة و30؛ و`MeterServiceTypeFixedAmountDL/SP` أربعة وثمانية.
- Result sets الحية: `MetersDL` ثمانية، `AllMeterReadDL` أربعة، `MeterReadForOccubentAndExitDL` اثنان، و`MeterServiceTypeFixedAmountDL` اثنان، إضافة إلى permission result set لكل صفحة؛ الإجمالي 20 result sets عبر الصفحات الأربع.
- استخرجت 284 تبعية catalog و38 FK في النطاق الموسع. ظهر Trigger حي فعال واحد هو `Housing.trg_BuildingAction_Audit` على `BuildingAction`.

المخالفات التطبيقية المثبتة دون Live:

1. فحص وصول الصفحة معلق في `AllMeterRead`.
2. صلاحيات `Meters` المقروءة أقل من العمليات الثماني المكونة.
3. اختلاف أسماء permissions المختلطة الحالة عن ActionTypes في صفحة التسكين/الإخلاء.
4. عناوين PDF في `AllMeterRead` منسوخة من صفحة الإمهال.
5. Audit delete للأسعار الثابتة يستخدم ID غير مضبوط ومفتاح JSON من مجال BuildingClass.
6. قيم السياق الأمني في CRUD ما زالت client-posted وفق العقد العام.

## Coverage والفجوات

- تغطية repository المطلوبة: 5 Controller files (Base + 4)، Controller منطقي واحد، 4 MVC actions، 4 Views، 25 ActionTypes (8 + 11 + 3 + 3)، و21 permission names مقروءة في واجهة الصفحات (4 + 11 + 3 + 3).
- 8 feature procedures و3 gateways وDataEngine/service path متحققة حياً؛ 284 dependency row و38 FK ضمن استعلام العلاقات، ورسمان ودليل مستخدم.
- 100% من أسطح الكود المطلوبة و100% من إجراءات/بوابات SQL المطلوبة موثقة ومطابقة حياً؛ 0 Business SP منفذ و0 كتابة قاعدة.
- غير مكتمل: بيانات permissions والـseed، E2E، احتساب فعلي وwrap/شرائح/ضريبة، concurrency والإغلاق، تحقق PDF بصري، وأثر التعديل بعد المدفوعات.
