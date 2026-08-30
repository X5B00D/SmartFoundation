# توثيق Housing Definitions

> تحديث قاعدة البيانات 2026-08-23: صحح [ERD Housing الحي](../Diagrams/19-Housing-Live-ERD.md) العلاقات وفق 75 FK حياً في Schema `Housing`. بقي ارتباط `BuildingDetailsMeterServices` إجرائياً/مستنتجاً وليس قيد FK.

## الحالة والنطاق

- الصفحات: `BuildingClass` و`BuildingDetails` و`BuildingType` و`BuildingUtilityType` و`MilitaryLocation` فقط.
- مكتمل من الكود النشط وSQL snapshot بتاريخ 2026-08-21.
- لم يُنفذ أي Stored Procedure أو طلب يغير البيانات، ولم يُعدّل شيء خارج `Documentation/`.
- الكود النشط يثبت السلوك التطبيقي. `SmartFoundation.Database` مرجع Snapshot، فلا يثبت تطابق القاعدة الحية.
- **مثبت** = من الكود النشط؛ **Snapshot** = من مشروع SQL؛ **فجوة** = تعارض أو نقطة تحتاج اختباراً.

## النمط المشترك الفعلي

الصفحات الخمس أجزاء من `partial HousingController`. يبدأ كل GET بـ `InitPageContext`، ويستدعي `MastersServies.GetDataLoadDataSetAsync`، ثم يفصل `SplitDataSet` Table 0 للصلاحيات و`dt1..dt9` لبقية النتائج. غياب صف صلاحية يعيد المستخدم إلى `Home/Index` برسالة رفض.

لا توجد domain models خاصة. يحول Controller كل `DataRow` إلى `Dictionary<string, object?>` ويضيف `p01..pNN`، ثم يبني `FieldConfig/FormConfig` و`TableColumn/SmartTableDsModel` داخل `SmartPageViewModel`. الـ Views رقيقة وتستدعي `SmartRenderer`; View المباني تضيف فقط `window.UtilityTypeID_` للطباعة.

القراءة: `GET -> HousingController -> MastersServies -> ProcedureMapper -> dbo.Masters_DataLoad -> feature DL -> DataSet -> SmartRenderer`.

الكتابة: `modal -> /crud/insert|update|delete -> CrudController -> pNN إلى parameter_NN -> dbo.Masters_CRUD -> permission check -> feature SP -> IsSuccessful/Message_ -> TempData -> redirect`.

الرسومات: [05-Housing-Definitions-Flows.md](../Diagrams/05-Housing-Definitions-Flows.md) و[06-Housing-Definitions-ERD.md](../Diagrams/06-Housing-Definitions-ERD.md).

## مصفوفة الصفحات

| الصفحة | الهدف | Controller Actions | View | Result sets بعد permission | DDL |
| --- | --- | --- | --- | ---: | --- |
| BuildingClass | تعريف فئات المباني | `BuildingClass()` | `HousingDefinitions/BuildingClass` | 1 | لا يوجد |
| BuildingType | تعريف الأنواع | `BuildingType(int pdf=0)`, `Print()` | `HousingDefinitions/BuildingType` | 2 | Cities زائد غير مستخدم |
| BuildingUtilityType | أنواع المرافق وسريانها وهل تتطلب إيجاراً | `BuildingUtilityType()` | `HousingDefinitions/BuildingUtilityType` | 1 | نعم/لا محلية |
| MilitaryLocation | المواقع/الأحياء وربطها بمدينة | `MilitaryLocation()` | `HousingDefinitions/MilitaryLocation` | 2 | المدن من Table 2 |
| BuildingDetails | المباني وروابط التعريفات والإيجار والخدمات | `BuildingDetails(int pdf=0)` | `HousingDefinitions/BuildingDetails` | 8 | Tables 2..6 + خيارات محلية |

## BuildingClass

### الهدف وUI وModels

تعرض الفئات النشطة العامة أو التابعة للإدارة، ببحث وترتيب وpagination وإظهار أعمدة. المفتاح `buildingClassID`، ويخفي الجدول `buildingClassOrder` و`buildingClassActive`. النموذج النهائي `SmartPageViewModel.TableDS` وعنوانه «فئات المباني».

| العملية | عقد الحقول |
| --- | --- |
| Insert | `p01` العربي مطلوب، `p02` الإنجليزي، `p03` الملاحظات |
| Update | `p01` المعرف، `p02` العربي، `p03` الإنجليزي، `p10` الملاحظات |
| Delete | `p01` المعرف، و`p02/p03` readonly |

### DataSet وServices وSQL

- Table 0: `permissionTypeName_E`.
- `dt1`: المعرف، الاسمان، الوصف، الترتيب، active من `Housing.BuildingClass`; active فقط، وIdara عامة أو مطابقة، بترتيب ID تنازلي.
- Services: `MastersServies`, `SmartComponentService`, `ConnectionFactory`, و`CrudController` للكتابة.
- **Snapshot routing:** `BuildingClass -> Housing.BuildingClassDL`; والكتابة إلى `Housing.BuildingClassSP`.
- SQL مباشر: `dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `dbo.ft_UserPagePermissions`, `dbo.V_GetListUserPermission`, `Housing.BuildingClassDL/SP`, `Housing.BuildingClass`, `dbo.AuditLog`.

### الصلاحيات وCRUD

`INSERTBUILDINGCLASS`, `UPDATEBUILDINGCLASS`, `DELETEBUILDINGCLASS`. تتحكم في إظهار Add/Edit/Delete؛ التعديل والحذف لسجل واحد. **Snapshot:** تعيد `Masters_CRUD` فحص المستخدم والصفحة و`ActionType` قبل SP.

### Validation وBusiness Rules

- UI يطلب الاسم العربي ويستخدم TextMode عربي.
- **Snapshot:** Action والاسم العربي مطلوبان؛ يمنع الاسم العربي المكرر active في نطاق الإدارة؛ update/delete يتطلبان معرفاً وسجلاً active.
- delete منطقي (`buildingClassActive=0`)؛ كل العمليات تسجل `AuditLog`.
- **فجوة:** الصف يملأ الوصف في `p04` بينما update form ينتظر `p10`.
- لا توجد قاعدة في SP تمنع soft delete عند ارتباط الفئة بمبانٍ؛ ادعاء ملف المساعدة القديم بهذا المنع غير مثبت.

### خطوات المستخدم

1. افتح فئات المباني وابحث أو رتب.
2. للإضافة أدخل الاسم العربي ثم احفظ.
3. للتعديل أو الحذف حدد سجلاً واحداً واستخدم الزر الظاهر حسب الصلاحية.

## BuildingType

### الهدف وUI وModels

تعرض أنواع المباني النشطة العامة/التابعة للإدارة. الجدول قابل للبحث والترتيب، ومفتاحه `buildingTypeID`; يعرض الرمز والاسمين والوصف.

| العملية | عقد الحقول |
| --- | --- |
| Insert | `p01` الرمز، `p02` العربي، `p03` الإنجليزي، `p04` الوصف |
| Update | `p01` المعرف، `p02` الرمز، `p03` العربي، `p04` الإنجليزي، `p10` الوصف |
| Delete | `p01` المعرف، والتفاصيل readonly |

يوجد مسارا PDF: `pdf=1` تقرير، و`pdf=2` خطاب تجريبي. لكن `ShowPrint=false` و`ShowPrint1=false`، فلا يظهر الزران. Action `Print()` يقرأ `TempData[PdfBytes]` ولا يرتبط بمسار PDF الحالي.

### DataSet وDDL وSQL

- Table 0: permissions.
- `dt1`: أنواع active ضمن الإدارة/العامة بترتيب تنازلي.
- `dt2`: `dbo.City` active، لكن Controller لا يستهلكه؛ DDL زائد.
- **Snapshot routing:** `BuildingType -> Housing.BuildingTypeDL/SP`.
- SQL: البوابات وكائنات الصلاحية المشتركة، `Housing.BuildingTypeDL/SP`, `Housing.BuildingType`, `dbo.City`, `dbo.AuditLog`.

### الصلاحيات والقواعد

- `INSERTBUILDINGTYPE`, `UPDATEBUILDINGTYPE`, `DELETEBUILDINGTYPE`.
- UI يطلب الرمز والعربي؛ العربي `MaxLength=50` وTextMode عربي.
- **Snapshot:** العربي مطلوب وفريد بين السجلات active في النطاق؛ update/delete يحتاجان معرفاً وسجلاً active؛ delete منطقي وAudit لكل عملية.
- **فجوة:** row alias للوصف `p05` بينما update ينتظر `p10`.
- **فجوة:** التقرير يحوي header ثابتاً جزئياً ولا يوجد زر ظاهر للوصول إليه.

### خطوات المستخدم

1. افتح أنواع المباني واستعرض القائمة.
2. أضف الرمز والاسم العربي، ثم احفظ.
3. حدد سجلاً واحداً للتعديل أو soft delete.

## BuildingUtilityType

### الهدف وUI وModels

تعرف أنواع المرافق وفترة السريان وهل تتطلب إيجاراً. تعرض `buildingUtilityIsRent` كنص «نعم/لا»، وتخفي active. القراءة مرتبة تصاعدياً.

| العملية | عقد الحقول |
| --- | --- |
| Insert | `p01` العربي، `p02` الإنجليزي، `p03` الوصف، `p04` البداية، `p05` النهاية، `p06` يتطلب إيجاراً |
| Update | `p01` المعرف، `p02` العربي، `p03` الإنجليزي، `p06` البداية، `p07` النهاية، `p08` الإيجار، `p10` الوصف |
| Delete | `p01` المعرف والاسمان readonly |

قائمة نعم/لا `OptionItem(1/0)` محلية.

### DataSet وSQL والصلاحيات

- Table 0: permissions؛ `dt1`: بيانات النوع والتواريخ بصيغة `yyyy-MM-dd` وflag كنص `0/1`.
- الصلاحيات: `INSERTBUILDINGUTILITYTYPE`, `UPDATEBUILDINGUTILITYTYPE`, `DELETEBUILDINGUTILITYTYPE`.
- **Snapshot routing:** القراءة تقارن `@pageName_='buildingUtilityType'` وتنفذ `Housing.buildingUtilityTypeDL`; الكتابة تستخدم حالة أحرف `BuildingUtilityType` وتوجه إلى `Housing.BuildingUtilityTypeSP`. نجاح التطابق يعتمد على collation إن كان حساساً للحالة.
- SQL: البوابات/الصلاحية، `Housing.buildingUtilityTypeDL`, `Housing.BuildingUtilityTypeSP`, `Housing.BuildingUtilityType`, `dbo.AuditLog`.

### Validation وBusiness Rules

- UI يطلب العربي والبداية وflag الإيجار؛ النهاية اختيارية.
- **Snapshot:** الاسم مطلوب؛ وعند وجود التاريخين يجب أن تكون النهاية بعد البداية؛ يمنع duplicate active؛ update/delete لسجل active؛ delete منطقي وAudit.
- **فجوة:** alias الوصف `p04` وupdate ينتظر `p10`.
- `BuildingDetails` يرتبط بالنوع بـ FK. لا يمنع SP soft delete لنوع مستخدم؛ وقد تختفي المباني المرتبطة من `BuildingDetailsDL` لأنه يشترط النوع active.

### خطوات المستخدم

1. افتح أنواع المرافق.
2. أدخل الاسم والبداية وحدد هل المرفق إيجاري.
3. اجعل النهاية بعد البداية إن أدخلتها.
4. حدد سجلاً واحداً للتعديل أو الحذف المنطقي.

## MilitaryLocation

### الهدف وUI وModels

تعرف المواقع/الأحياء مع رمز ومدينة واسمين وإحداثيات ووصف. يخفي الجدول FK المدينة وactive وIdara، ويعرض اسم المدينة من join. Excel export ظاهر.

| العملية | عقد الحقول |
| --- | --- |
| Insert | `p01` الرمز، `p02` المدينة، `p04` العربي، `p05` الإنجليزي، `p06` الإحداثيات، `p07` الوصف |
| Update | `p01` المعرف، `p02` الرمز، `p03` المدينة، `p05` العربي، `p06` الإنجليزي، `p07` الإحداثيات، `p08` الوصف |
| Delete | `p01` المعرف، والتفاصيل readonly |

### DataSet وDDL وSQL

- Table 0: permissions.
- `dt1`: مواقع active ضمن الإدارة/العامة مع inner join إلى `Housing.MilitaryAreaCity`؛ موقع بلا city مطابق لا يظهر.
- `dt2`: المدن active؛ `GetDDLValues(..., tableIndex="2")` يحولها إلى `CityOptions` لـ Select2.
- **Snapshot routing:** `MilitaryLocation -> Housing.MilitaryLocationDL/SP`.
- SQL: البوابات/الصلاحية، `Housing.MilitaryLocationDL/SP`, `Housing.MilitaryLocation`, `Housing.MilitaryAreaCity`, `dbo.AuditLog`.
- علاقات Snapshot: Location -> City، وLocation -> `dbo.Idara`.

### الصلاحيات والقواعد

- `INSERTMILITARYLOCATION`, `UPDATEMILITARYLOCATION`, `DELETEMILITARYLOCATION`.
- UI يطلب الرمز والمدينة والعربي.
- **Snapshot:** SP يفرض العربي فقط، ويمنع تكراره active ضمن الإدارة؛ update/delete يحتاجان معرفاً وسجلاً active؛ delete منطقي وAudit.
- **فجوة:** Required للرمز والمدينة في UI لا يقابله تحقق صريح في SP؛ FK المدينة nullable في الجدول.
- لا يمنع SP soft delete لموقع مرتبط بمبانٍ؛ قد تختفي المباني من القراءة لأنها تشترط location active.

### خطوات المستخدم

1. افتح المواقع وابحث في الجدول.
2. اختر المدينة وأدخل الرمز والاسم العربي ثم احفظ.
3. حدد موقعاً واحداً للتعديل أو الحذف.

## BuildingDetails

### الهدف وController Actions

تدير المباني الفعلية. يقرأ `BuildingDetails(int pdf=0)` query parameter `U` كنوع مرفق، ولا يعرض الجدول قبل وجوده. معامل التحميل هو `["BuildingDetails", IdaraId, usersId, HostName, U]`. عند `pdf=1` يبني QuestPDF من `dt1` نفسه بلا DB call إضافي. لا توجد POST Actions محلية؛ CRUD مشترك.

### View وUI configuration

- `SmartPageViewModel.Form`: اختيار نوع المرفق؛ `sfNav` يعيد GET إلى `/Housing/BuildingDetails?U={value}&S=1`.
- `TableDS` يظهر فقط بعد الاختيار، ويدعم البحث وpagination ونسخ الخلايا وإظهار الأعمدة وfilter row.
- حقول الإيجار والحالة والخدمات تخفى للنوع غير الإيجاري.
- زر التقرير يرسل `pdf=1` و`U`، لكنه مربوط حالياً بـ `canInsertBUILDINGDETAILS`.
- View تستدعي `SmartRenderer` وتضبط `window.UtilityTypeID_`.

### Models وViewModels

`SmartPageViewModel`, `FormConfig/FieldConfig/OptionItem`, `SmartTableDsModel/TableColumn/TableToolbarConfig/TableAction`، و`ReportColumn/ReportResult/DataTableReportBuilder/QuestPdfReportRenderer`. صفوف الجدول dictionaries مع `p01..p21`.

### DataSet result sets وDDL

| # | Controller | الغرض |
| ---: | --- | --- |
| 0 | `permissionTable` | الصلاحيات |
| 1 | `dt1` | المباني المطابقة لـ U وIdara مع التعريفات والإيجار الحالي وآخر action وعدادات الخدمات |
| 2 | `dt2` | أنواع المرافق active + `buildingUtilityIsRent`; filter DDL وقرار الإيجار |
| 3 | `dt3` | نوع الإيجار active ذو ID=1 |
| 4 | `dt4` | أنواع المباني active ضمن الإدارة/العامة |
| 5 | `dt5` | المواقع active؛ بلا scope إدارة في SQL الحالي |
| 6 | `dt6` | الفئات active ضمن الإدارة/العامة |
| 7 | `dt7` | availability للكهرباء/الماء/الغاز للإدارة من linked service + fixed amount |
| 8 | `dt8` | flag الإيجار للنوع المختار؛ لا يستخدمه Controller |

`GetDDLValues` يقرأ Tables 2..6 من نفس DataSet. خيارات نعم/لا للخدمات محلية.

### عقد CRUD

Insert: `p02` رقم المبنى، `p03` الغرف، `p04` الطوابق، `p05` المساحة، `p06` الإحداثيات، `p16` النوع، `p07` الفئة، `p08` الموقع، `p15` نوع المرفق، `p09/p10` الهاتفان، `p13/p18` البداية/النهاية، `p14` الملاحظات. للنوع الإيجاري: `p11/p12` نوع ومبلغ الإيجار. للخدمات المتاحة: `p19/p20/p21` كهرباء/مياه/غاز.

Update: `p01` المعرف؛ `p07` النوع، `p08` المرفق، `p09` الموقع، `p10` الفئة، `p11/p12` الهاتفان، `p13/p14` الإيجار، `p15` البداية، `p16` الملاحظات، `p17` U المخفي، `p18` النهاية، `p19..p21` الخدمات.

### الصلاحيات وrouting

- `INSERTBUILDINGDETAILS`: الإضافة وظهور التقرير حالياً.
- `UPDATEBUILDINGDETAILS`: تعديل سجل واحد.
- `DELETEBUILDINGDETAILS`: حذف سجل واحد.
- **Snapshot read:** `BuildingDetails -> Housing.BuildingDetailsDL`, و`@parameter_01 -> @buildingUtilityTypeID_FK`.
- **Snapshot write:** Actions الثلاثة -> `Housing.BuildingDetailsSP` بعقود موضعية مختلفة.

### Procedures والجداول والـ Views والـ Functions

- Procedures: `dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `Housing.BuildingDetailsDL/SP`.
- Tables مباشرة: `Housing.BuildingDetails`, `BuildingType`, `BuildingUtilityType`, `MilitaryLocation`, `BuildingClass`, `BuildingRent`, `BuildingRentType`, `BuildingDetailsMeterServices`, `MeterServiceTypeLinkedWithIdara`, `MeterServiceTypeFixedAmount`, `BuildingAction`, `BuildingActionType`, و`dbo.AuditLog`.
- View مباشرة: `Housing.V_LastActionForBuilding`.
- لا توجد Housing function مستدعاة مباشرة من DL/SP. مجرد إشارة functions أخرى للمباني لا يجعلها جزءاً من مسار الصفحة المثبت.

### Validation وBusiness Rules

- UI يفرض رقم المبنى والغرف والطوابق والمساحة والإحداثيات والتعريفات والبداية؛ الهاتفان والملاحظات والنهاية اختيارية.
- **Snapshot insert:** رقم المبنى والإدارة والمرفق صالحون؛ النهاية بعد البداية عند المقارنة؛ للنوع الإيجاري يلزم نوع إيجار ومبلغ رقمي؛ يمنع رقم مبنى active مكرر داخل الإدارة.
- **Snapshot update:** يشترط السجل active ويمنع رقم مبنى مكرر لدى سجل آخر، ثم يحدث المبنى.
- الإيجار: insert ينشئ `BuildingRent`; update يغلق active السابق وينشئ جديداً، أو يغلق الإيجار إن لم يعد النوع إيجارياً.
- الخدمات IDs ثابتة: 1 كهرباء، 2 ماء، 3 غاز. Insert ينشئ الروابط المختارة؛ update يعطل المطلوب إلغاؤه ويضيف المفقود.
- delete منطقي للمبنى ويضع تاريخ النهاية الحالي ويغلق الإيجار active؛ لا يعطل meter-service links صراحة.
- transaction + `XACT_ABORT`; 50001 business، و50002..50004 تنفيذية؛ Audit للعمليات الرئيسية.

### العلاقات والـ Workflow

`BuildingDetails` محور التعريفات الأربع عبر FKs. له تاريخ إيجارات عبر `BuildingRent`، وخدمات عبر `BuildingDetailsMeterServices`، وحالة أخيرة عبر `V_LastActionForBuilding -> BuildingAction -> BuildingActionType`.

### خطوات المستخدم

1. اختر نوع المرفق؛ قبل ذلك لا يظهر الجدول.
2. راجع المباني واستخدم البحث/filters.
3. للإضافة أدخل الأساسيات والتعريفات؛ تظهر حقول الإيجار والخدمات فقط عند تحقق شروطها.
4. للتعديل حدد مبنى واحداً وحدّث البيانات والإيجار والخدمات.
5. للحذف حدد مبنى وأكد؛ التنفيذ المرجعي soft delete وإغلاق الإيجار.
6. اطبع التقرير إذا ظهر؛ ظهوره مرتبط حالياً بصلاحية الإضافة.

### فجوات مهمة

1. block تحقق update في SP يستخدم `@Action IN('UPDATE')` بينما البوابة ترسل `UPDATEBUILDINGDETAILS`; لذا لا يعمل ذلك block حسب Snapshot.
2. delete form يضبط `p01` مع `MirrorName="UtilityTypeID_"` بينما البوابة تتوقع `buildingDetailsID`; قد يرسل U بدل معرف المبنى.
3. update/delete يضعان `Value=buildingUtilityIsRent.ToString()` في حقل اسم المبنى `p02`; يلزم اختبار population الفعلي.
4. `dt8` زائد وغير مستخدم، ومواقع `dt5` غير مقيدة بالإدارة.
5. لا تظهر FK declarations لـ `BuildingDetailsMeterServices` في Snapshot رغم الاعتماد المنطقي.
6. زر التقرير محكوم بصلاحية insert لا بصلاحية طباعة.

## ERD والعلاقات المثبتة

راجع [06-Housing-Definitions-ERD.md](../Diagrams/06-Housing-Definitions-ERD.md). FKs المثبتة في Snapshot:

- `BuildingDetails -> BuildingClass/BuildingType/BuildingUtilityType/MilitaryLocation`.
- `MilitaryLocation -> MilitaryAreaCity -> MilitaryArea`، و`MilitaryLocation -> dbo.Idara`.
- `BuildingRent -> BuildingDetails/BuildingRentType`.
- `BuildingAction -> BuildingDetails/BuildingActionType`.

## قائمة SQL المجمعة

### Procedures

`dbo.Masters_DataLoad`, `dbo.Masters_CRUD`, `Housing.BuildingClassDL/SP`, `Housing.BuildingTypeDL/SP`, `Housing.buildingUtilityTypeDL`, `Housing.BuildingUtilityTypeSP`, `Housing.MilitaryLocationDL/SP`, `Housing.BuildingDetailsDL/SP`.

### Tables

`Housing.BuildingClass`, `BuildingType`, `BuildingUtilityType`, `MilitaryLocation`, `MilitaryAreaCity`, `MilitaryArea`, `BuildingDetails`, `BuildingRent`, `BuildingRentType`, `BuildingDetailsMeterServices`, `MeterServiceTypeLinkedWithIdara`, `MeterServiceTypeFixedAmount`, `BuildingAction`, `BuildingActionType`, `dbo.City`, `dbo.Idara`, `dbo.AuditLog`.

### Views وFunctions

- `Housing.V_LastActionForBuilding`, `dbo.V_GetListUserPermission`.
- `dbo.ft_UserPagePermissions` هي table-valued function مشتركة في بوابة القراءة.
- لا توجد Housing functions مباشرة في feature DL/SP الخمسة.

## Coverage

| البند | موثق |
| --- | ---: |
| صفحات Housing Definitions | 5/5 |
| Controller files | 5/5 |
| Actions | 6/6: خمس page actions + `BuildingType.Print()`؛ أوضاع `pdf` فروع داخل Action وليست Actions مستقلة |
| Razor Views | 5/5 |
| Feature DL/SP | 10/10 |
| CRUD operations | 15/15 |
| Permissions | 15/15 |
| DataSet result sets | 18/18: خمس permissions + 13 feature sets |
| الرسومات | 2 |

التغطية العامة بعد دمج ControlPanel: 9 من 38 Controller files، و8 من 35 Views، و18 من 62 stored procedures المحددة مبدئياً. Coverage يعني اكتمال تتبع المستودع، لا اختباراً حياً.

## الفجوات العامة

- **فجوة تاريخية أُغلقت في 07A:** لم تكن تعريفات Snapshot قد قورنت حياً عند كتابة المرحلة؛ تمت المقارنة في 2026-08-22. لم تنفذ إجراءات أعمال.
- لم تختبر modals أو POSTs المختلف عليها في browser/end-to-end.
- لا توجد اختبارات آلية مخصصة لهذه الصفحات في المشروع المكتشف.
- لا توجد حماية صريحة تمنع soft delete لتعريف مرتبط؛ ادعاءات ملفات المساعدة القديمة بهذا الشأن غير مثبتة.
- فعالية صلاحيات المستخدمين الحية لم تفحص.

## تحديث المطابقة الحية 2026-08-22

إجراءات Definitions العشرة متحققة حياً ومطابقة للـ Snapshot، وكذلك `V_LastActionForBuilding` وFKs الأساسية في ERD. تأكد حياً عدم وجود FK مكتشف لـ `BuildingDetailsMeterServices`. ظهر Trigger فعال `Housing.trg_BuildingAction_Audit` على جدول الحركات؛ لا يغير CRUD التعريفات مباشرة لكنه يؤثر في الحركات اللاحقة. لم تُنفذ إجراءات أعمال أو صلاحيات فعلية.
