# توثيق IncomeSystem والتحقق الحي

> تحديث قاعدة البيانات 2026-08-23: لا يوجد Schema حي باسم IncomeSystem؛ جميع كائنات البرنامج المباشرة تحت `Housing`. يوثق [ERD الدخل والفوترة](../Diagrams/20-Income-and-Electronic-Billing-ERD.md) FKs الفعلية ويميز الروابط المنطقية.

## النطاق والحالة

- تاريخ التحقق: 2026-08-22.
- الصفحات: `DeductListReport`، `FinancialAuditForExtendAndEvictions`، `FinancialAuditForUser`، `ImportExcelForBuildingPayment`، `ExtendInsurance`.
- مصدر سلوك التطبيق: الكود النشط. مصدر SQL النهائي: تعريفات DATACORE الحية المقروءة من `sys.*`. استخدم Snapshot للمقارنة التاريخية فقط.
- مرحلة `live_database_reconciliation_for_conversations_1_to_7` كانت مكتملة قبل البدء.
- لم ينفذ Business Stored Procedure ولم تقرأ بيانات أعمال ولم ينفذ Upload أو Import.

## البنية المشتركة

الـController المنطقي هو `IncomeSystemController` موزع على ستة ملفات. `IncomeSystemController.Base` يقرأ `usersId` و`IdaraId` و`HostName` من Session ويقسم DataSet إلى `permissionTable` ثم `dt1..dt15`. Views الخمس رقيقة وتستدعي `SmartRenderer`؛ الاستثناء الوحيد JavaScript في View الاستيراد لتعبئة الأشهر بحسب السنة. لا توجد Models خاصة؛ التكوين كله من `SmartPageViewModel` و`FormConfig` و`FieldConfig` و`SmartTableDsModel`.

المسار العام:

`View -> IncomeSystemController -> MastersServies -> ProcedureMapper -> SmartComponentService -> gateway -> live Housing procedure -> live objects`.

## ملخص الصفحات والمسارات الحية

| الصفحة | الهدف | Actions / UI | المسار الحي المثبت |
| --- | --- | --- | --- |
| DeductListReport | تقرير مسيرات الاستقطاع حسب نوع خدمة العداد والفترة | `DeductListReport(pdf)`؛ فلتران DDL؛ طباعة PDF؛ صلاحية `PRINTDEDUCTLISTREPORT` | Controller يستدعي `Masters_DataLoad` باسم الصفحة، لكن لا يوجد branch حي في `Masters_DataLoad` أو `Masters_CRUD` أو `Masters_ExtraDataLoad`. النتيجة المتوقعة من البوابة هي permissions فقط؛ بيانات التقرير غير موصولة حياً. |
| FinancialAuditForExtendAndEvictions | تدقيق مالي لطلبات الإمهال والإخلاء، مراجعة المطالبات، الدفع/الاسترداد والتسوية | GET واحد يبني عدة forms وtables؛ عمليات `FINANCIALAUDITFOREXTENDANDEVICTIONS` و`PAYMENTANDREFUNDFOREXTENDANDEXIT` و`FINANCIALSETTLEMENT` | `Masters_DataLoad -> Housing.FinancialAuditForExtendAndEvictionsDL`; الكتابة `CrudController -> Masters_CRUD -> Housing.FinancialAuditForExtendAndEvictionsSP`; التفاصيل الديناميكية عبر `Masters_ExtraDataLoad`. |
| FinancialAuditForUser | تدقيق ملف مالي لمستفيد محدد ومراجعة المطالبات والتسوية | GET واحد؛ `FinancialAuditForUser` و`REVIEWCLAIMSANDPAYMENTSFORUSER` و`PAYMENTANDREFUNDFORUSER` و`FINANCIALSETTLEMENTFORUSER` | `Masters_DataLoad -> Housing.FinancialAuditForUserDL`; `Masters_CRUD -> Housing.FinancialAuditForUserSP`; تحميل تفاصيل الفواتير عبر `Masters_ExtraDataLoad`. |
| ImportExcelForBuildingPayment | رفع ملف مسير، معاينته، اختيار أعمدة الهوية/الوحدة/الرقم العام/المبلغ ثم إنشاء المسير والمدفوعات | `ImportExcelForBuildingPayment` و`ImportExcelForBuildingPaymentUpload` و`ImportExcelForBuildingPaymentProcess` و`GetMonthsByYear` | القراءة `Masters_DataLoad -> Housing.ImportExcelForBuildingPaymentDL`; التفاصيل `Masters_ExtraDataLoad/GetBuildingPaymentByDeductList`; المعالجة تتجاوز `Masters_CRUD` وتستدعي مباشرة `Housing.ImportExcelForBuildingPaymentSP` بTVP. |
| ExtendInsurance | اعتماد تحصيل التأمين الاحترازي الناتج من تمديد السكن | `ExtendInsurance(pdf)`؛ form اعتماد؛ تقريران PDF | `Masters_DataLoad -> Housing.ExtendInsuranceDL`; `CrudController -> Masters_CRUD -> Housing.ExtendInsuranceSP` عند `APPROVEEXTENDINSURANCE`. |

## DataSet وDDL وSmart UI

- كل تحميل gateway يبدأ بجدول `ft_UserPagePermissions`، ثم result sets الخاصة بالـDL.
- صفحات التدقيق تحول أعمدة DataTables ديناميكياً إلى `TableColumn` وتضيف aliases `p01..` للنوافذ؛ وتبني عدة `SmartTableDsModel` للمستفيد والفواتير والمطالبات/المدفوعات.
- مصادر DDL التطبيقية تمر عبر `CrudController.GetDDLValues` و`Masters_ExtraDataLoad`: أنواع المطالبات `BillChargeType`، أنواع الدفع، المستفيدون، السنوات والأشهر، وخدمات العدادات وفتراتها.
- `ImportExcelForBuildingPaymentDL` يعيد أربع feature sets بعد permissions: أنواع المطالبة، السنوات 2017 حتى السنة الحالية، الأشهر، ومسيرات الاستيراد السابقة للإدارة.
- `ExtendInsuranceDL` يعيد feature set واحداً لطلبات التأمين ذات `InsuranceAmountWithRemaining <> 0`.
- تقرير DeductList يطلب DDL من table indexes 1 و2، لكن لا يوجد DL routing حي للصفحة؛ لذلك هذا العقد غير مكتمل حياً.

## الصلاحيات والعمليات

| الصفحة | الصلاحيات التي يقرأها Controller |
| --- | --- |
| DeductListReport | `PRINTDEDUCTLISTREPORT` |
| FinancialAuditForExtendAndEvictions | `FINANCIALAUDITFOREXTENDANDEVICTIONS`, `REVIEWCLAIMSANDPAYMENTS`, `PAYMENTANDREFUNDFOREXTENDANDEXIT`, `FINANCIALSETTLEMENT` |
| FinancialAuditForUser | `FinancialAuditForUser`, `REVIEWCLAIMSANDPAYMENTSFORUSER`, `PAYMENTANDREFUNDFORUSER`, `FINANCIALSETTLEMENTFORUSER` |
| ImportExcelForBuildingPayment | `IMPORTEXCELFORBUILDINGPAYMENT` للعرض؛ المعالجة المباشرة لا تمر بفحص permission في gateway |
| ExtendInsurance | `APPROVEEXTENDINSURANCE` |

`Masters_CRUD` يفحص `V_GetListUserPermission` على `entrydata/pageName_/ActionType` قبل إجراءات التدقيق والتأمين. تبقى هذه القيم client-posted وفق العقد المشترك. الاستيراد المباشر يعتمد على session context في Controller لكنه لا يمر بمصفاة `Masters_CRUD`.

## قواعد الأعمال والتدقيق المالي

- مسار الإمهال/الإخلاء يعمل على حالات `LastActionTypeID` 51 و57؛ الاعتماد ينشئ انتقالات 52 أو 58، مع منع إنهاء الحالة مرتين وتسجيل `dbo.AuditLog`.
- الدفع/الاسترداد والتسوية تتحقق من وجود السجل والمستفيد، المبلغ، اختلاف خدمة المصدر والوجهة، وكفاية الرصيد؛ ثم تنشئ `DeductList` و`BuildingPayment` وتدقيقاً.
- تدقيق المستخدم يستخدم ملخصات الفواتير والمدفوعات لكل مستفيد/خدمة/مبنى وينفذ عمليات مماثلة ضمن نطاق المستخدم.
- اعتماد التأمين يتحقق من السجل والمبلغ والحالة، ويحدث `ExtendInsurance` وينشئ الأثر المالي المرتبط وفق Action.
- أخطاء الأعمال تستخدم `THROW 50001` وتعيد البوابة رسائلها؛ الإجراءات تستخدم transaction/TRY-CATCH و`XACT_ABORT`.

## استيراد Excel دون تشغيله

1. Upload يقبل Excel ويقرأ أول sheet عبر ExcelDataReader، ويخزن ملفاً مؤقتاً/session token ويعرض حتى 20,000 صف.
2. Process يعيد قراءة الملف ويتحقق من اختيار أربعة أعمدة، الخلايا الفارغة، الشهر/السنة ونوع المطالبة، ثم يحسب SHA-256.
3. يبني TVP حي `Housing.ImportExcelForBuildingPaymentRowType`: `RowNo`, `IDNumber`, `unitID`, `generalNo_FK`, `amount`.
4. يستدعي مباشرة `Housing.ImportExcelForBuildingPaymentSP`؛ الإجراء يمنع hash مكرر، ينشئ `DeductList`، ينظف المبالغ إلى `decimal(10,2)`، يدرج `BuildingPayment` لكل صف، ثم يستدعي `Housing.usp_ClassifyAndLinkBuildingPayments` ويكتب `UploadExcelImportLog`.
5. الإجراء المصنف يربط الدفع بفترة السكن من `BuildingAction` ويضبط `BuildingPaymentLinkStatus`; Trigger الحي الفعال `TR_BuildingPayment_SetLinkStatus` يضع حالة أولية إن لم تُرسل.

لم تنفذ أي خطوة رفع أو معالجة في هذا التوثيق.

## كائنات SQL الحية

الإجراءات: `dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `dbo.Masters_ExtraDataLoad`, `Housing.FinancialAuditForExtendAndEvictionsDL/SP`, `Housing.FinancialAuditForUserDL/SP`, `Housing.ImportExcelForBuildingPaymentDL/SP`, `Housing.ExtendInsuranceDL/SP`, `Housing.usp_ClassifyAndLinkBuildingPayments`.

الجداول الرئيسية: `Housing.Bills`, `BillChargeType`, `BillPeriod`, `MeterServiceType`, `DeductList`, `DeductType`, `DeductListStatus`, `BuildingPayment`, `BuildingPaymentType`, `BuildingPaymentLinkStatus`, `BuildingPaymentLinkAudit`, `UploadExcelImportLog`, `ExtendInsurance`, `ExtendInsuranceType`, `BuildingAction`, `ResidentDetails`, و`dbo.AuditLog`.

Views/Functions المباشرة المثبتة: `Housing.V_WaitingList`, `V_GetFullResidentDetails`, `V_GetGeneralListForBuilding`, `V_buildingWithRent`, `V_ResidentFinancialSummary`, `V_SumBillsTotalPriceAndTotalPaidForResident`, `Housing.fn_BuildingAction_ChainToRoot`, `dbo.V_GetFullSystemUsersDetails`, و`dbo.V_GetListIdara`.

العلاقات الحية المهمة: `DeductList` إلى `DeductType` و`DeductListStatus` و`BuildingPaymentType`; `UploadExcelImportLog.DeductListID_FK -> DeductList`; و`BuildingPayment.buildingPaymentLinkStatusID_FK -> BuildingPaymentLinkStatus`. عدة روابط أخرى إجرائية بلا FK، خصوصاً resident/building/service fields.

## Live مقابل Snapshot

- أزواج DL/SP الأربعة موجودة حياً، وتعريفات Snapshot مفيدة لفهم التاريخ لكنها ليست المرجع.
- Live يضيف منظومة تصنيف ربط المدفوعات: `usp_ClassifyAndLinkBuildingPayments`, `BuildingPaymentLinkStatus`, `BuildingPaymentLinkAudit` وTrigger `TR_BuildingPayment_SetLinkStatus`; هذه غير ممثلة بالكامل في توثيق Snapshot القديم.
- Live `DeductList` يحوي `ToBillChargeTypeID_FK` و`ExtendInsuranceID_FK`، و`ExtendInsurance` يستخدم أطوالاً وأنواعاً موسعة مقارنة ببعض ملفات Snapshot.
- عقد TVP الحي يطابق Snapshot ذي خمسة أعمدة ويطابق DataTable الحالي في Controller.
- أهم فرق routing: لا يوجد أي routing حي لـ`DeductListReport`، فلا يجوز استنتاج إجراء من الاسم.
- الاستيراد الحي يستدعي إجراء التصنيف بعد الإدراج؛ هذا اعتماد حيوي يجب ألا يحذف عند صيانة Snapshot.

## العلاقة مع Housing وElectronicBillSystem

IncomeSystem ليس schema مستقلاً؛ يستخدم schema `Housing`. مصدر الرصيد والفواتير من `Bills` و`BillChargeType` وملخصات المقيم، ومصدر حالات الإمهال والإخلاء من `V_WaitingList/BuildingAction`. ElectronicBillSystem يكتب قراءات وفواتير العدادات التي تصبح مدخلات التدقيق والتقارير هنا؛ IncomeSystem يسجل التحصيل/الاسترداد في `BuildingPayment` و`DeductList`.

## الفجوات

مغلقة: routing لأربع صفحات، عقد TVP، إجراء التصنيف، trigger وحالات الربط، واعتماديات Views/Functions. جديدة: `DeductListReport` غير موصول حياً؛ صلاحية import لا يعاد فحصها في SQL؛ ActionTypes خاطئة منسوخة داخل بعض forms في import و`DELETEBUILDINGTYPE` غير مستخدم في ExtendInsurance؛ أسماء ملفات PDF في ExtendInsurance ما زالت `BuildingType.pdf`. متبقية: E2E، بيانات permissions/seed، تنفيذ Excel، تحقق PDF بصري، وسلوك concurrency/rollback تحت حمل.

## Coverage

التغطية 100% لأسطح المستودع المطلوبة: 6 controller files/Controller منطقي واحد، 5 views، 8 MVC actions (5 صفحات + upload + process + months)، 10 `SmartTableDsModel`، 12 إجراء feature/gateway مباشر بما فيها classifier، 9 Views/Functions مباشرة، TVP واحد وTrigger واحد. لا تعني التغطية اختبار التنفيذ.
