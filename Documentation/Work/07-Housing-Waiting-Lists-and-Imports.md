# قوائم الانتظار والإسناد والاستيراد في Housing

> تحديث قاعدة البيانات 2026-08-23: علاقات `BuildingAssign` بالمستفيد والمبنى والحالات مستخدمة من SQL لكنها ليست FKs حية؛ يعرضها [ERD Housing](../Diagrams/19-Housing-Live-ERD.md) كعلاقات مستنتجة بوضوح.

## الحالة وحدود الدليل

- النطاق: `Assign`, `AssignStatus`, `OtherWaitingList`, `RentExemption`, `Residents` و`ResidentsPrint`, `WaitingList`, `WaitingListByResident`, `WaitingListMoveList`, `UploadExcel`, و`UploadLab`.
- الكود النشط في `SmartFoundation.Mvc` هو المصدر الأول. تمت مطابقة النطاق مع تعريفات قاعدة `DATACORE` الحية بتاريخ 2026-08-22 بقراءة catalog فقط؛ ملفات `SmartFoundation.Database` لقطة مرجعية، والفروق موثقة في `07A-Live-Database-Reconciliation.md`.
- لم تُشغّل عمليات Upload أو Import أو CRUD، ولم تُقرأ أو تُعدّل بيانات أعمال. تحليل Excel وSQL ثابت فقط.
- المسار المشترك المثبت: Action يقرأ Session/query، ثم `MastersServies -> dbo.Masters_DataLoad -> feature DL`; الكتابة عبر `CrudController -> dbo.Masters_CRUD -> feature SP`. الاستثناءان هما `UploadExcel` الذي يتصل مباشرةً بـ SQL في `Process`، و`UploadLab` الذي يحفظ ملفاً وبيانات Session فقط.

## مصفوفة الصفحات

| الصفحة | Action/View | نموذج العرض | Result sets بعد permission | الكتابة/العملية الخاصة |
| --- | --- | --- | ---: | --- |
| Residents | `Residents(int pdf=0)` / `WaitingList/Residents` و`ResidentsPrint` | جدول + 3 Forms | 7 | INSERT/UPDATE/DELETE، PDF 1 و2 |
| WaitingListByResident | `WaitingListByResident()` / View رقيقة | بحث + 4 جداول + 9 Forms | 8 | 9 عمليات انتظار/خطاب/نقل |
| WaitingListMoveList | `WaitingListMoveList()` / View رقيقة | جدول + Formي قرار | 1 | قبول/رفض النقل |
| WaitingList | `WaitingList(int pdf=0)` / View رقيقة | فلتر + جدول + Form | 2 | نقل إلى قائمة التخصيص، PDF |
| OtherWaitingList | `OtherWaitingList(int pdf=0)` / View رقيقة | فلتر + جدول + Form | 3 | نقل لإجراءات التسكين، PDF |
| Assign | `Assign(int pdf=0)` / View رقيقة | فلاتر + جدول + 5 Forms | 4 | فتح/إغلاق محضر، تخصيص/تبديل/استبعاد، PDF |
| AssignStatus | `AssignStatus(int pdf=0,int? rowId=null)` / View رقيقة | فلتر + جدول + Formين | 3 | إنهاء محضر/معالجة حالة، PDF صف |
| RentExemption | `RentExemption()` / View رقيقة | بحث + جدول مقيم + جدول إعفاءات + 3 Forms | 3 | إضافة/تعديل/إلغاء |
| UploadExcel | `Index`, `Upload`, `Process` / `UploadExcel/Index` | جدول معاينة + Formي رفع واعتماد | لا DataSet | رفع/قراءة ثم TVP مباشر |
| UploadLab | `Index`, `Upload` / `UploadLab/Index` | جدول Session + Form رفع | لا SQL | حفظ ملف فعلي فقط |

كل Views المذكورة عدا `ResidentsPrint` رقيقة: تضبط `ViewData["Title"]` وتستدعي `SmartRenderer`. لا توجد classes مستقلة لصفوف المجال في الصفحات الثماني؛ Controllers تحول `DataRow` إلى `Dictionary<string,object?>`. نموذج `UploadLabRow` nested ويحمل `Id`, `OriginalName`, `RelativePath`, `UploadedAt`.

## Residents وResidentsPrint

### القراءة وواجهة المستخدم

`Residents` يتحقق من Session بواسطة `InitPageContext`، يرسل `pageName_/idaraID/entrydata/hostname`، ويشغل بالتوازي DDL indexes 2..7 للرتبة والوحدة والحالة الاجتماعية والجنسية والجنس والمقيم. `ResidentsDL` المرجعي يعيد:

1. تفاصيل المقيمين في الإدارة من `Housing.V_GetFullResidentDetails`.
2. الرتب النشطة.
3. الوحدات العسكرية.
4. الحالات الاجتماعية النشطة.
5. الجنسيات النشطة.
6. الجنس.
7. قائمة المقيمين في الإدارة.

`SmartTableDsModel` قابل للبحث والفرز وتصفية الأعمدة، ويضيف aliases موضعية لتعبئة Forms. `FormConfig` يغطي بيانات الهوية والرقم العام والأسماء العربية والإنجليزية والرتبة والوحدة والحالة الاجتماعية والجنسية وعدد المعالين والجنس وتاريخ الميلاد والجوال والملاحظات.

### CRUD والصلاحيات والقواعد

الصلاحيات: `INSERTRESIDENTS`, `UPDATERESIDENTS`, `DELETERESIDENTS`. البوابة تطابق `permissionTypeName_E = ActionType` ثم تربط `pNN` بمعاملات `ResidentsSP`. الإجراء المرجعي:

- INSERT: يتحقق من الحقول الأساسية وتفرد الهوية/الرقم العام، ينشئ `ResidentInfo` و`ResidentDetails` وعلاقات الإدارة، ويسجل Audit.
- UPDATE: يتحقق من السجل والتعارضات، يغلق/يحدث النسخ الفعالة بحسب الفرع ويحفظ تاريخ التفاصيل.
- DELETE: حذف منطقي/تعطيل مع منع الحالات غير الصالحة، لا حذف مادي مثبت.

### التقارير والطباعة

`pdf=1` و`pdf=2` يبنيان PDF في Controller باستخدام QuestPDF؛ أحدهما قائمة/تقرير والآخر نموذج تفصيلي بحسب بيانات الجدول. `ResidentsPrint.cshtml` View طباعة HTML مستقلة تعرض بيانات المقيم، لكنها ليست مسار PDF الوحيد. زر الطباعة مرتبط في الكود بصلاحية الإضافة، وهو اقتران يحتاج مراجعة سياسة الصلاحيات.

## WaitingListByResident

### القراءة وResult sets

تبحث الصفحة بـ `NID`؛ عدم وجود نتيجة يضع رسالة خطأ. بعد جدول الصلاحيات يعيد `WaitingListByResidentDL` المرجعي ثمانية sets:

1. المقيم المطابق من `V_GetFullResidentDetails`.
2. سجلات الانتظار للمقيم من `V_WaitingList`.
3. خطابات/سجلات انتظار مرتبطة بالمقيم.
4. طلبات نقل الإدارة من `V_MoveWaitingList`.
5. فئات الانتظار المتاحة للإدارة.
6. أنواع ترتيب الانتظار.
7. الإدارات الأخرى.
8. أسباب الإلغاء/إنهاء الكل من `BuildingActionType` للقيم 19 و53.

Controller يعرض أربعة `SmartTableDsModel`: بيانات المقيم، الانتظار، الخطابات، وطلبات النقل. يستدعي DDL indexes 5..8 أيضاً عبر endpoint المشترك. يوجد طلب extra-data بـ `ActionType=GetWaitingListActions` لعرض تاريخ الحركة.

### العمليات والصلاحيات

| ActionType | الغرض | أهم binding |
| --- | --- | --- |
| `INSERTWAITINGLIST` | إضافة سجل انتظار | المقيم، القرار، الفئة، نوع الترتيب، ملاحظات |
| `UPDATEWAITINGLIST` | تعديل سجل | ActionID ثم بيانات السجل |
| `DELETEWAITINGLIST` | إلغاء سجل | ActionID؛ الإجراء يضيف حركة ولا يمحو التاريخ |
| `INSERTOCCUBENTLETTER` | إضافة خطاب إشغال | المقيم وبيانات القرار |
| `UPDATEOCCUBENTLETTER` | تعديل الخطاب | ActionID وحقول القرار |
| `DELETEOCCUBENTLETTER` | إلغاء الخطاب | ActionID |
| `MOVEWAITINGLIST` | طلب نقل كل قوائم المقيم لإدارة أخرى | الإدارة الجديدة وقرار/سبب الطلب |
| `DELETEMOVEWAITINGLIST` | إلغاء طلب النقل | معرف حركة النقل وملاحظاتها |
| `DELETERESIDENTALLWAITINGLIST` | إنهاء جميع سجلات المقيم | السبب 19 أو53 وبيانات القرار |

الأسماء التسعة نفسها هي permissions التي تتحكم في الأزرار. `Masters_CRUD` يعيد التحقق، يستدعي `WaitingListByResidentSP`، وينشئ Notifications في فروع النقل.

### Business rules

الإجراء المرجعي يستخدم ledger في `BuildingAction`: يمنع فئة مكررة، يمنع الإضافة/التعديل عند طلب نقل قائم، يتحقق من تبعية ملف المستفيد للإدارة، ويمنع العمل بعد حالات التقاعد/الفصل. التعديل والحذف يتطلبان ActionID وسجلاً قابلاً للحركة. النقل يتطلب إدارة هدف وبيانات قرار، وإلغاء النقل يتطلب طلباً قائماً غير محسوم. جميع الفروع تعمل بمعاملة، تستخدم 50001 لأخطاء الأعمال و50002 للفشل البرمجي، وتسجل Audit.

## WaitingListMoveList

`WaitingListMoveListDL` يعيد طلبات `V_MoveWaitingList` الموجهة إلى `@idaraID`. الجدول يخفي المعرفات التقنية ويعرض الإدارة المرسلة/المستقبلة وحالة الحركة. Formا القرار هما:

- `MOVEWAITINGLISTAPPROVE`: قبول النقل.
- `MOVEWAITINGLISTREJECT`: رفض النقل.

وهما أيضاً permissions. `WaitingListMoveListSP` يمنع معالجة الطلب مرتين. الرفض يضيف حركة رفض. القبول يضيف حركة قبول، ينقل سجلات الانتظار ذات الصلة، ينسخ/يحدث تفاصيل المقيم وربط الإدارة، ويحدث سجلات الإدارة السابقة، ثم يسجل Audit. البوابة تنشئ إشعارات وترابطاً عكسياً إلى `WaitingListByResident?NID=...`.

## WaitingList

الصفحة تعرض الفئات النظامية العامة فقط (IDs 1,2,3,4,11 في snapshot). `FormConfig` يطلب فئة، ثم `WaitingListDL` يعيد قائمة مرتبة بتاريخ/رقم القرار والرقم العام، إضافة إلى DDL الفئات. الجدول يسمح بعملية `MOVETOASSIGNLIST` فقط لمن يملك الصلاحية.

`WaitingListSP` يتحقق من وجود السجل، وأنه لم يُعالج، وأن المستفيد هو الأول فعلياً في ترتيب فئته داخل الإدارة؛ إذا لم يكن رأس القائمة يرفض برسالة أعمال. النجاح يضيف حركة نقل إلى قائمة التخصيص ويسجل Audit. `pdf=1` يولد تقرير QuestPDF للقائمة المختارة.

## OtherWaitingList

تختص بالفئات المحلية غير (1,2,3,4,11) والمقيدة بالإدارة. `OtherWaitingListDL` يعيد القائمة، DDL الفئات المحلية، وDDL المباني النشطة. العملية الوحيدة `MOVETOOCCUPENTPROCEDURES` تنقل المستفيد مباشرةً إلى إجراءات التسكين مع اختيار مبنى.

`OtherWaitingListSP` يتحقق من السجل وعدم معالجته، وتوفر المبنى وصحة تبعيته/حالته، ثم يضيف حركة مرتبطة بالمبنى نحو مسار الإشغال ويسجل Audit. `pdf=1` يولد تقريراً للفئة. الصلاحية نفسها تتحكم في العملية والطباعة في Controller.

## Assign

### Result sets وFormConfig

يقبل `WaitingClassID` و`AssignPeriodID` من query. `AssignDL` المرجعي يعيد:

1. قائمة المرشحين مع آخر حركة وحالة الإسناد، ويربط المحضر الحالي عبر CTE.
2. DDL فئات الانتظار.
3. محاضر التخصيص المفتوحة/النشطة مع بيانات منشئها والفئة.
4. المباني النشطة المتاحة للإدارة.

Forms والصلاحيات: `OPENASSIGNPERIOD`, `CLOSEASSIGNPERIOD`, `ASSIGNHOUSE`, `UPDATEASSIGNHOUSE`, `CANCLEASSIGNHOUSE`. الجدول يطبق شروط ظهور حسب `LastActionTypeID` وحالة المحضر، ويعرض status pills. `pdf=2` ينشئ محضر تخصيص PDF باستخدام QuestPDF.

### قواعد الإسناد

- فتح محضر يتطلب وصفاً وفئة، ويمنع وجود محضر نشط متعارض.
- إغلاق المحضر يتطلب محضراً نشطاً ووجود مستفيد واحد على الأقل خُصص له منزل؛ يغلق الفترة ويولد حركات نهاية مرتبطة.
- تخصيص منزل يتطلب سجلاً قائماً ومحضراً نشطاً ومبنى متاحاً، ويطبق حد فرص التخصيص. الحالات 38/40 مستخدمة كحالات تخصيص في الكود المرجعي.
- الاستبعاد (`CANCLEASSIGNHOUSE` بالتهجئة الفعلية) يعكس/يسلسل الحركة ولا يحذف التخصيص السابق.
- التبديل `UPDATEASSIGNHOUSE` ينشئ حركة إلغاء للمبنى السابق ثم حركة تخصيص للمبنى الجديد.
- يوجد فرع `AssignNote` في `AssignSP` غير موصول ببوابة الصفحة أو Form نشط، فيوثق ككود غير قابل للوصول من المسار الحالي.

## AssignStatus

الصفحة تختار محضر تخصيص منتهي وتعرض مرشحيه. `AssignStatusDL` يعيد: (1) صفوف المحضر وحالاتها والمبنى والعداد، (2) DDL المحاضر المغلقة ذات تاريخ نهاية، (3) حالات المعالجة 39 و45. العمليات:

- `ENDASSIGNPERIOD`: إنهاء/تثبيت معالجة المحضر.
- `ASSIGNSTATUS`: اختيار حالة معالجة للمستفيد وإضافة حركة جديدة مرتبطة بالمحضر والمبنى.

`pdf=2` و`rowId` يولدان نموذج PDF لصف محدد. توجد صيغتا `AssignStatus` و`ASSIGNSTATUS` في routing الحي، لكن قاعدة `DATACORE` تستخدم `SQL_Latin1_General_CP1_CI_AS` غير الحساس للحالة؛ ثبت حياً وجود مساري القراءة والكتابة، لذلك case لا يعطل المسار الحالي. يبقى توحيد الاسم مطلوباً، ولم تُقرأ بيانات `menuName_E` الفعلية.

## RentExemption

تبحث الصفحة بهوية مقيم يشغل مبنى. `RentExemptionDL` يعيد: (1) المقيم/الإشغال الحالي من `V_GetFullResidentDetails` و`V_Occupant`، (2) سجل إعفاءاته، (3) أنواع الإعفاء النشطة المسموحة للإدارة. الجدول الأول سياق المقيم، والثاني تاريخ الإعفاء مع حالة رقمية/نصية (نشط، منتهي، ملغي).

الصلاحيات والعمليات: `ADDRENTEXEMPTION`, `EDITRENTEXEMPTION`, `DELETERENTEXEMPTION`. Forms تربط النوع والمقيم وتاريخ البداية والنهاية ورقم/تاريخ الخطاب والمبنى والوصف. `RentExemptionSP` يتحقق من المقيم/المبنى والنوع والفترات، يمنع التداخل غير النظامي، ويضيف/يعدل السجل؛ الحذف إلغاء منطقي يسجل `CanceldBy/CanceldDate/CanceldWhy`. الإعفاء يُستهلك لاحقاً في `BuildingRentForOneMonth`, `GenerateMonthlyRentBillForResident`, و`GenerateExitRentBills` لقص فترة الإعفاء على فترة احتساب الإيجار وتطبيق نسبة النوع.

## UploadExcel

### الرفع والمعاينة

`Index` يبني `SmartTableDsModel` ديناميكياً من أعمدة المعاينة في Session. Form الرفع يقبل ملفاً واحداً `.xls/.xlsx` حتى 10MB، مع request limit 20MB وantiforgery. `Upload` يعيد التحقق من الامتداد وMIME والحجم، يحفظ باسم UUID تحت `wwwroot/uploads/excel`، يقرأ أول sheet عبر ExcelDataReader مع أول صف headers، ويخزن أسماء الأعمدة وحتى 200 صف معاينة في Session. refresh يمسح Session ويحاول حذف الملف الفعلي.

### الاعتماد والاستيراد

Form المعالجة يختار ثلاثة أعمدة مختلفة (`p14,p15,p03`). `Process` يعيد قراءة الملف، يثبت وجود الأعمدة، يرفض الخلايا الفارغة ويعرض حتى 15 رقم صف لكل عمود، يبني TVP، يحسب SHA-256 للملف، ثم يتصل مباشرة بـ `[Housing].[UploadExcel_ImportSelected3Cols]`. الإجراء ينظف النص، يمنع تكرار الملف ببصمة `UploadExcelImportLog.FileHash`, يدرج في `Housing.UploadExcel` ويسجل عدد الصفوف، ويرجع `IsSuccessful/Message_/InsertedRows`.

لا يمر هذا المسار بـ `MastersServies`, `ProcedureMapper`, `Masters_CRUD`, أو permission gateway، ولا يوجد Session identity check داخل Controller. توجد فجوة تنفيذية مثبتة من الكود والـ schema الحي: النوع `Housing.UploadExcelRowType` يحتوي خمسة أعمدة (`RowNo` وUploadExcel1..4)، بينما `Process` يبني DataTable بأربعة أعمدة فقط (`RowNo` و1..3). TVP يتطلب تطابق shape/ordinal، ولذلك يلزم تصحيح قبل الاعتماد. كما ثبت حياً أن جدول log يملك أعمدة أسماء الأعمدة والإحصاءات، بينما الإجراء الحالي لا يملؤها عدا الاسم والبصمة والعدد.

## UploadLab

`Index` يعرض صفوف `UploadLab.Rows` من Session في جدول (`Id`, الاسم الأصلي، المسار النسبي، وقت الرفع). Form الرفع يقبل PDF/XLS/XLSX واحداً حتى 10MB، request limit 20MB وantiforgery. `Upload` يفحص الامتداد وMIME والحجم، يحفظ UUID تحت `wwwroot/uploads/lab`، ثم يضيف metadata إلى Session ويرجع JSON.

لا يقرأ محتوى Excel، ولا يستورد إلى قاعدة، ولا يملك delete/cleanup، ولا يستخدم gateway أو permission/session guard. فحص MIME/extension لا يثبت توقيع الملف، والمسار داخل `wwwroot` يجعل الملف قابلاً للخدمة إذا عُرف URL؛ هذه فجوات تحقق وأمان وليست عمليات نُفذت أثناء التوثيق.

## Gateway routing وSQL objects

### Entry routes

ثبت حياً أن `dbo.Masters_DataLoad` يوجه الصفحات الثماني إلى `ResidentsDL`, `WaitingListByResidentDL`, `WaitingListMoveListDL`, `WaitingListDL`, `OtherWaitingListDL`, `AssignDL`, `AssignStatusDL`, و`RentExemptionDL`، وأن `dbo.Masters_CRUD` يحتوي مسارات الكتابة إلى SPs المقابلة وفحص `permissionTypeName_E = @ActionType`. `UploadExcel_ImportSelected3Cols` direct entry، وUploadLab بلا SQL.

### Procedures

`dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `dbo.Masters_ExtraDataLoad`, `Housing.ResidentsDL/SP`, `WaitingListByResidentDL/SP`, `WaitingListMoveListDL/SP`, `WaitingListDL/SP`, `OtherWaitingListDL/SP`, `AssignDL/SP`, `AssignStatusDL/SP`, `RentExemptionDL/SP`, `UploadExcel_ImportSelected3Cols`, إضافة إلى إجراءات احتساب الإيجار المتأثرة بالإعفاء.

### Tables/types

`ResidentInfo`, `ResidentDetails`, جداول ربط الإدارة، `BuildingAction`, `BuildingActionType`, `WaitingClass`, `WaitingOrderType`, `AssignPeriod`, `AssignNote`, `BuildingAssign`, `BuildingAssignStatus`, `BuildingAssignCount`, `BuildingAssignType`, `ResidentRentExemption`, `ResidentRentExemptionType`, `UploadExcel`, `UploadExcelImportLog`, `AuditLog`, والنوع `Housing.UploadExcelRowType`.

### Views/functions

Views المباشرة: `V_GetFullResidentDetails`, `V_WaitingList`, `V_MoveWaitingList`, `V_AssignList`, `V_Occupant`, `V_GetGeneralListForBuilding`, `V_WaitingListByLetter`, `V_WaitingListWithLetters`, `V_WaitingList_Ids`, و`V_GetListUserPermission`. تستخدم الحركة المتسلسلة `Housing.fn_BuildingAction_ChainToRoot` في المسارات المرتبطة؛ وتستخدم فوترة الإيجار حسابات/إجراءات تقاطع الإعفاء مع فترة الفاتورة. لا يُعامل `V_WaitingListxx` كمسار نشط لمجرد وجوده.

## العلاقات وسير العمل

السجل المركزي ليس status قابلاً للاستبدال، بل سلسلة `BuildingAction` ذات `LastActionID/LastActionTypeID` وعلاقة parent. التسلسل الوظيفي:

`Residents -> WaitingListByResident -> WaitingList/OtherWaitingList -> Assign -> AssignStatus -> HousingHandover/HousingResident`، مع فرع نقل `WaitingListByResident -> WaitingListMoveList -> الإدارة الجديدة`، وفرع مالي `Occupant -> RentExemption -> rent billing/exit`.

- الصفحات الفردية تنشئ سجلات الانتظار والخطابات وتدير النقل.
- WaitingList يفرض أولوية رأس القائمة قبل إدخال المرشح إلى التخصيص.
- Assign يفتح محضراً للفئة ويخصص الموارد؛ AssignStatus يغلق دورة المحضر ويقرر الحالة التالية.
- OtherWaitingList يتجاوز محضر التخصيص للفئات المحلية وينقل مباشرة لمسار التسكين.
- قبول النقل يعيد تموضع ملف المستفيد وقوائمه في إدارة الهدف، لا مجرد تغيير حقل عرض.
- الإعفاء لا يغير حالة السكن؛ يقلص أساس الإيجار خلال فترة ونسبة محددتين.

الرسومات: [10-Housing-Waiting-Assignment-Workflow.md](../Diagrams/10-Housing-Waiting-Assignment-Workflow.md)، [11-Housing-Waiting-Data-and-Gateway.md](../Diagrams/11-Housing-Waiting-Data-and-Gateway.md)، [12-Housing-Excel-Import-Flows.md](../Diagrams/12-Housing-Excel-Import-Flows.md).

## Coverage

| البند | التغطية المستودعية |
| --- | ---: |
| الصفحات المطلوبة | 10/10، مع ResidentsPrint ضمن Residents |
| Controller files | 10/10 |
| Views | 11/11 |
| MVC Actions | 13/13: صفحات Housing الثماني + UploadExcel 3 + UploadLab 2؛ أوضاع PDF فروع داخل Actions |
| عمليات الكتابة/الخاصة | 29/29: Residents 3، WLBResident 9، Move 2، WaitingList 1، Other 1، Assign 5، AssignStatus 2، Exemption 3، UploadExcel 2، UploadLab 1 |
| Feature DL/SP | 17/17: 8 DL + 8 SP + Excel import SP |
| DataSet feature result sets | 31/31، إضافة إلى 8 permission sets؛ Uploads لا تستخدم DataSet |
| Permissions المسماة | 26/26؛ لا permissions داخل Upload controllers |
| مسارات PDF/طباعة | Residents 2 + ResidentsPrint، WaitingList 1، Other 1، Assign 1، AssignStatus 1 |
| الرسومات | 3 |

التغطية 100% لأسطح المستودع المطلوبة، ولا تعني تطابق SQL الحي أو نجاح E2E/Excel.

## الفجوات والتحقق المطلوب

1. **فجوة تاريخية أُغلقت في 07A:** تمت مقارنة التعريفات حياً في 2026-08-22؛ لم تنفذ أي عملية أعمال.
2. TVP الحي في UploadExcel لا يطابق DataTable المُرسل (خمسة أعمدة مقابل أربعة).
3. UploadExcel يتجاوز gateway والصلاحيات، وUploadLab بلا session guard/permission؛ كلاهما يحتاج authorization review.
4. `AssignStatus`/`ASSIGNSTATUS` يعملان حالياً بسبب collation غير الحساس للحالة، لكن التسمية غير موحدة وبيانات `menuName_E` غير مفحوصة.
5. UploadLab لا يحذف الملفات ولا يثبت محتواها بالتوقيع؛ UploadExcel يكشف نص الاستثناء للعميل في بعض المسارات.
6. تقارير QuestPDF و`ResidentsPrint` لم تُرندر بصرياً ولم تختبر العربية/الخطوط/الصفحات الكبيرة.
7. conditions المعتمدة على IDs مثبتة من التعريفات الحية، لكن معاني كل ID غير مثبتة من seed data؛ ويوجد فرق حي بين `AssignDL` الذي يعرض 5 و39 و41 وبين `AssignSP` الذي يقبل أيضاً 42.
8. يوجد `AssignNote` في SP دون route/UI نشط، وViews قديمة/بديلة مثل `V_WaitingListxx` لا يثبت استخدامها.
9. CRUD ما زال يأخذ `entrydata/idaraID/pageName_/ActionType` من العميل كما وثق مستند الأمان.

## تحديث المطابقة الحية 2026-08-22

- من 17 feature procedures لهذا النطاق: 15 مطابقة، و`AssignDL` و`AssignSP` مختلفان عن Snapshot. `BuildingRentForOneMonth` اختلاف إضافي مرتبط بأثر الإعفاء، لكنه خارج عدّ الإجراءات السبعة عشر.
- `AssignDL` الحي يعرض المباني ذات الحالات `(5,39,41)` أو بلا حركة، بينما Snapshot يضيف 42. `AssignSP` الحي يقبل للمبنى المحدد `(5,39,41,42)`، فيوجد عدم اتساق حي بين قائمة الاختيار والتحقق الكتابي.
- `Housing.V_WaitingList` الحي يستخدم جذور `(1,7,25)` بدلاً من `(1,7)` في Snapshot.
- `BuildingRentForOneMonth` الحي يراعي `ExitDate` ويشمل الخروج NULL أو الواقع في/بعد بداية الشهر.
- توقيع `UploadExcel_ImportSelected3Cols` الحي يؤكد أربعة أسماء أعمدة وTVP؛ فجوة DataTable/TVP مثبتة حياً.
- case وحده لا يعطل `AssignStatus` لأن collation الحية غير حساسة للحالة؛ يبقى تطابق بيانات `menuName_E` غير متحقق.
