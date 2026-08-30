# توثيق برنامج ControlPanel

> تحديث قاعدة البيانات 2026-08-23: المفاتيح والعلاقات الحية النهائية موثقة في [قاعدة DATACORE وERD](11-Live-Database-and-ERD.md) و[ERD الصلاحيات](../Diagrams/18-ControlPanel-Permissions-ERD.md). أي علاقة موسومة هناك “مستنتجة” ليست FK فعلياً.

## حالة المستند ونطاقه

- الحالة: مكتمل من الكود النشط وSQL snapshot بتاريخ 2026-08-21.
- النطاق: `ControlPanelController` بأجزائه الأربعة، وصفحات `PagesManagment` و`Permission` و`Users`، والـ Views والنماذج والخدمات ومسارات البيانات وقواعد الأعمال ودليل التشغيل الوظيفي.
- قاعدة الإثبات: الكود النشط هو المصدر الأول. تعريفات `SmartFoundation.Database` مرجع تصميم وليست إثباتاً لتطابق قاعدة البيانات الحية.
- لم يُنفذ أي Stored Procedure أو استعلام تجاري، ولم يُعدّل شيء خارج `Documentation/`.

## الهدف الوظيفي

`ControlPanel` هو برنامج الإدارة المركزية لثلاثة مجالات مترابطة:

1. تعريف البرامج والقوائم الجانبية والصفحات وصلاحيات الصفحة عبر `PagesManagment`.
2. إسناد الصلاحيات إلى مستخدم أو موزع أو دور أو إدارة أو تركيب تنظيمي عبر `Permission`.
3. إنشاء المستخدمين وتعديلهم وتعطيلهم وإعادة تعيين كلمات المرور عبر `Users`.

ينتج عن إدارة الصفحات كائنات `Program` و`Menu` و`Distributor` و`MenuDistributor` و`PermissionType` و`DistributorPermissionType`. ثم تستخدم صفحة الصلاحيات هذه التعريفات لإنشاء سجلات `Permission`. وتستخدم بقية برامج SmartFoundation ناتج هذه البنية في بناء القائمة وفحص العمليات.

## الجرد المكتمل

| النوع | العدد | العناصر |
| --- | ---: | --- |
| Controller منطقي | 1 | `ControlPanelController` |
| ملفات Controller | 4 | Base، PagesManagment، Permission، Users |
| Actions فعلية | 4 | `Index` و`PagesManagment` و`Permission` و`Users` |
| Views | 3 | PagesManagment، Permission، Users |
| عمليات كتابة من الواجهة | 20 | 12 + 4 + 4 |
| إجراءات SQL مباشرة/بوابات موثقة | 8 | Masters_DataLoad، Masters_CRUD، PagesManagmentSP، PermissionSP، UsersDL، UsersSP، ReSetUserPassword، SetUserPassword |
| Function أمنية مباشرة | 1 | `ft_UserPagePermissions` |

`Index` Action موجود في الملف الأساسي، لكن لا توجد View مكتشفة باسم `Views/ControlPanel/Index.cshtml`؛ لذلك لا يعد صفحة مكتملة ضمن الصفحات الثلاث.

## ControlPanelController وأجزاؤه

### الملف الأساسي

`ControlPanelController.Base.cs` يحقن `MastersServies` و`CrudController` و`ILogger<ControlPanelController>`. ويحتفظ بسياق الجلسة في حقول مثل `usersId` و`IdaraId` و`HostName`، وبـ `permissionTable` و`dt1..dt13`.

`InitPageContext` يرفض الطلب عند غياب `Session[usersID]` ويعيد التوجيه إلى `Login/Index?logout=1`، ثم يقرأ بيانات المستخدم والتنظيم. `SplitDataSet` يثبت العقد التالي: الجدول 0 للصلاحيات، والجداول 1 إلى 13 لبيانات الصفحة والـ DDL. لا توجد `[Authorize]` على الـ Controller؛ الحارس الفعلي للـ GET هو Session check المحلي.

### Actions

| Action | HTTP الفعلي | المدخلات | الناتج |
| --- | --- | --- | --- |
| `Index()` | GET بالمسار التقليدي | لا شيء | `View()`؛ View غير مكتشفة |
| `PagesManagment()` | GET | Session | `SmartPageViewModel` إلى `MenuManagment/PagesManagment` |
| `Permission()` | GET | Query filters + Session | نموذج بحث وجدول اختياري إلى `Permission/Permission` |
| `Users()` | GET | Session | جدول مستخدمين وأربعة نماذج CRUD إلى `Permission/Users` |

لا توجد Actions كتابة خاصة بالبرنامج؛ جميع النماذج ترسل إلى `/crud/insert` أو `/crud/update` أو `/crud/delete`.

## Views وModels وViewModels

الـ Views الثلاثة تستقبل `SmartPageViewModel` وتستدعي `SmartRenderer`. `Permission` و`Users` تزيلان query string من عنوان المتصفح بعد التحميل باستخدام `history.replaceState`، من دون إعادة طلب. `PagesManagment` يحتوي أيضاً كتلة Debug تظهر فقط عندما يضع Controller قيمة في `ViewBag.DebugInfo`.

لا توجد Models domain خاصة بـ ControlPanel. النماذج المستخدمة مشتركة من `SmartFoundation.UI`:

- `SmartPageViewModel`: حاوية الصفحة والنموذج والجداول.
- `SmartTableDsModel` و`TableColumn` و`TableToolbarConfig` و`TableAction`: الجدول والأعمدة والعمليات.
- `FormConfig` و`FieldConfig` و`FormButtonConfig` و`OptionItem`: النماذج والحقول والـ DDL.
- صفوف SQL تتحول إلى `Dictionary<string, object?>`، وتضاف aliases باسم `p01..pNN` لتعبئة modal والمرور بعقد CRUD الموضعي.

## صفحة PagesManagment

### الوظيفة والبيانات

تحمل الصفحة برامج النظام والقوائم والصفحات وصلاحيات الصفحات. القراءة تمر إلى `Masters_DataLoad` بالـ `pageName_ = PagesManagment`. في SQL snapshot لا يوجد downstream DL؛ تنفذ البوابة استعلامات مباشرة وتعيد جداول البرامج والقوائم والصفحات وصلاحياتها وقوائم مستويات التفويض.

### العمليات والصلاحيات

| مجموعة | ActionType | صلاحية البوابة المطلوبة | الأثر |
| --- | --- | --- | --- |
| برنامج | `AddProgram` | `ADDPROGRAM` | إدراج `Program` |
| برنامج | `EditProgram` | `EDITPROGRAM` | تعديل بيانات البرنامج |
| برنامج | `DeleteProgram` | `DELETEPROGRAM` | تغيير حالة البرنامج؛ حذف منطقي |
| قائمة | `AddMenuList` | `ADDMENU` | إدراج قائمة `Menu` مرتبطة ببرنامج |
| قائمة | `EditMenuList` | `EDITMENU` | تعديل القائمة |
| قائمة | `DeleteMenuList` | `DELETEMENU` | تغيير حالة القائمة |
| صفحة | `AddPage` | `ADDMENU` | إدراج Menu كصفحة، ثم Distributor وMenuDistributor |
| صفحة | `EditPage` | `EDITMENU` | تعديل الصفحة وموزعها المرتبط |
| صفحة | `DeletePage` | `DELETEMENU` | تغيير حالة Menu وMenuDistributor والموزع المرتبط |
| صلاحية صفحة | `AddPagePermission` | `ADDPERMISSION` | إنشاء PermissionType وربطه بالموزع |
| صلاحية صفحة | `EditPagePermission` | `EDITPERMISSION` | تعديل مستوى صلاحية DistributorPermissionType |
| صلاحية صفحة | `DeletePagePermission` | `DELETEPERMISSION` | تغيير حالة DistributorPermissionType |

الواجهة تقرأ التسع صلاحيات السابقة من table 0 وتظهر الأدوات الموافقة. البوابة تعيد mapping لأسماء Actions المختلطة case إلى أسماء الصلاحيات uppercase ثم تتحقق من `V_GetListUserPermission`؛ لذلك فحص الخادم هو الضمان النهائي.

### أهم الحقول وقواعد الأعمال

- البرنامج: اسم عربي وإنجليزي ووصف ورابط وأيقونة وترتيب؛ الأسماء يجب ألا تتكرر، والترتيب موجب، والحالة 0 أو 1.
- القائمة: برنامج أب، اسمان ووصف وترتيب؛ يلزم معرف برنامج صحيح ولا يقبل تكرار الاسم النشط.
- الصفحة: برنامج أو قائمة أب، اسم عربي/إنجليزي ووصف ورابط وترتيب ومستوى؛ لا يتكرر الاسم أو الرابط بين الصفحات النشطة.
- إضافة الصفحة تنشئ ثلاث حلقات مترابطة: `Menu -> Distributor -> MenuDistributor`.
- صلاحية الصفحة: اسم عربي/إنجليزي ومستوى تفويض؛ لا يتكرر نوع الصلاحية ولا ربطها بالموزع.
- الحذف في هذا المسار تغيير Active status وليس حذفاً فيزيائياً.
- الإجراءات تستخدم transaction و`XACT_ABORT` وTRY/CATCH، وتكتب `AuditLog`. أخطاء 50001 أعمال متوقعة، و50002 أخطاء تنفيذية.

## صفحة Permission

### الوظيفة والبحث

تدعم الصفحة البحث عن الصلاحيات حسب `SearchID_`: مستخدم، موزع، دور، إدارة، أو Department/Section/Division. يقرأ Controller query parameters (`UserID_`, `RoleID_`, `IdaraID_`, `Dept_`, `Section_`, `Divison_`, `distributorID_`) ويحوّلها إلى parameters موضعية. لا يظهر الجدول حتى يصبح معيار البحث المختار جاهزاً.

`Masters_DataLoad` ينفذ استعلامات Permission داخله ويعيد، إضافة إلى النتيجة، DDL للمستخدمين والموزعين وأنواع الصلاحيات والإدارات والأقسام والشعب والفروع والأدوار والبرامج والصفحات. مستوى `isAdmin` يقيّد PageLvl وpermissionAuthLvl إلى 1/2/3 أو 2/3 أو 3.

### العمليات

| ActionType | صلاحية مطلوبة | القاعدة |
| --- | --- | --- |
| `INSERTPERMISSION` | نفس الاسم | إسناد صلاحية محددة إلى نوع هدف واحد وسياق زمني اختياري |
| `INSERTFULLACCESS` | نفس الاسم | إضافة كل صلاحيات موزع غير المسندة إلى الهدف |
| `UPDATEPERMISSION` | نفس الاسم | تعطيل السجل القديم وإنشاء نسخة جديدة بالقيم المعدلة |
| `DELETEPERMISSION` | نفس الاسم | تعطيل الصلاحية منطقياً |

الواجهة تعرض “إضافة وصول كامل” تحت `canInsertPERMISSION` رغم أن Controller يقرأ أيضاً `canInsertFullAccess`; أي أن flag المتخصص لا يستخدم في `ShowAdd1`. لكن `Masters_CRUD` يفرض `INSERTFULLACCESS` فعلياً، فيمنع التنفيذ عند غيابها. هذه فجوة اتساق UI موثقة.

### Validation وقواعد الأعمال

- Action مطلوب، ومعرف المنفذ واسم المضيف مطلوبان في الإجراء.
- منع منح صلاحيات شديدة الحساسية في شروط خاصة داخل `PermissionSP`، ومنها checks مرتبطة بـ Role 20 والمستخدم 4 كما هي في snapshot؛ دلالتها التنظيمية تحتاج تأكيد مالك النظام.
- يجب تحديد `DistributorPermissionTypeID` للإسناد المفرد، ومنع duplicate نشط لنفس الهدف.
- Full access يضيف فقط الصلاحيات النشطة، السارية زمنياً، وغير الموجودة مسبقاً.
- تاريخ الانتهاء يجب أن يكون لاحقاً للبداية عندما يطبّق الفرع التحقق الزمني.
- UPDATE يعطل القديم ثم يدرج نسخة جديدة للحفاظ على الأثر، وDELETE soft delete.
- جميع الفروع تكتب `AuditLog` وتعيد `IsSuccessful/Message_`.

## صفحة Users

### الوظيفة والبيانات

`Users` يعرض الحسابات وبيانات الهوية والتنظيم والتصنيف. القراءة تسلك `Masters_DataLoad -> UsersDL`. يعيد `UsersDL` بيانات المستخدمين، ثم lookup tables لـ UsersAuthType وUserType وIdara وDistributor والبنية التنظيمية وGender وNationality وReligion وMaritalStatus وEducation.

الحقول الأساسية: الهوية الوطنية والرقم العام، الاسم العربي الإلزامي، الاسم الإنجليزي الاختياري، صلاحية النظام، نوع المستخدم، الإدارة والموزع، تاريخ إصدار الهوية والميلاد، الجنس والجنسية والديانة والحالة الاجتماعية والتعليم والملاحظات. `p35` سبب التعديل/التعطيل و`p36` الموزع.

### العمليات والصلاحيات

| ActionType | صلاحية مطلوبة | الأثر |
| --- | --- | --- |
| `INSERTUSERS` | نفس الاسم | إدراج Users وUsersDetails وUserDistributor وإنشاء كلمة مرور |
| `UPDATEUSERS` | نفس الاسم | تحديث الحساب والتفاصيل والربط التنظيمي |
| `DELETEUSERS` | نفس الاسم | تعطيل المستخدم وتحديث الروابط ذات الصلة |
| `RESETUSERPASSWORD` | نفس الاسم | استدعاء `ReSetUserPassword` وتحديث `usersPassword` |

`UPDATENATIONALID` صلاحية فرعية لا تمثل ActionType مستقل؛ تجعل حقل الهوية قابلاً للتحرير في نموذج UPDATE وتعرض رسالة تحذير. البوابة تتحقق فقط من `UPDATEUSERS` عند الحفظ، لذلك فرض عدم تغيير الهوية يعتمد في هذا snapshot على Readonly في الواجهة، لا على check مستقل ظاهر في `Masters_CRUD/UsersSP`؛ هذه فجوة أمنية يجب التحقق منها حياً.

إعادة كلمة المرور معرفة كنموذج وعملية Gateway، لكن قائمة flags في Controller لا تقرأ `RESETUSERPASSWORD`. يلزم التحقق هل الزر مربوط بأحد حقول Toolbar الأخرى أو غير ظاهر فعلياً؛ البوابة ستمنع العملية دون الصلاحية المطابقة في كل الأحوال.

### Validation وقواعد الأعمال

- الهوية والرقم العام بطول واجهة أقصى 10 وأسلوب رقمي، والأسماء العربية مطلوبة.
- lookup identifiers المطلوبة يجب أن تكون صالحة.
- `UsersSP` يمنع تكرار الهوية والرقم العام، ويتحقق من وجود المستخدم في التعديل/التعطيل.
- الإدراج والتعديل موزعان على `Users` و`UsersDetails` و`UserDistributor`، ويكتبان AuditLog.
- إنشاء كلمة المرور يستدعي `SetUserPassword`; إعادة الضبط تستدعي `ReSetUserPassword`. كلمة المرور مخزنة في `usersPassword` وفق منطق الإجراء، ولا يعرض هذا المستند أسراراً أو قيماً.
- أسباب التعديل/التعطيل مطلوبة في الواجهة عند UPDATE/DELETE.
- DELETE تعطيل منطقي وليس حذف صف الحساب فيزيائياً.

## Services وData Access

1. Controller يستدعي `MastersServies.GetDataLoadDataSetAsync` للقراءة.
2. `MastersServies` يحل `MastersDataLoad:getData` إلى `dbo.Masters_DataLoad` بواسطة `ProcedureMapper`.
3. `SmartComponentService` يبني Dapper parameters (ويضيف `@`) وينفذ `QueryMultipleAsync` عبر `ConnectionFactory`.
4. النتيجة تتحول من `SmartResponse.Datasets` إلى `DataSet` ثم `SplitDataSet`.
5. SmartRenderer يعرض Form/Table configs التي بناها Controller.
6. الكتابة ترسل إلى `CrudController`، الذي يحول `p01..p50` إلى `parameter_01..parameter_50` ويستدعي `MastersServies.GetCrudDataSetAsync`.
7. `ProcedureMapper` يحل `MastersCrud:crud` إلى `dbo.Masters_CRUD`، التي تتحقق من الصلاحية وتستدعي الإجراء المتخصص.

`CrudController.DDLFiltered` مستخدم في القوائم التابعة في Permission وUsers؛ يقرأ جدولاً محدداً من DataLoad ويصفيه حسب FK لبناء خيارات dependent select.

## العلاقات مع قاعدة البيانات

### الإجراءات

| الإجراء | الدور |
| --- | --- |
| `dbo.Masters_DataLoad` | بوابة القراءة والصلاحيات؛ تحمل Permission وPagesManagment مباشرة وتوجه Users إلى UsersDL |
| `dbo.Masters_CRUD` | بوابة الكتابة وفحص `V_GetListUserPermission` والتوجيه |
| `dbo.PagesManagmentSP` | قواعد البرامج والقوائم والصفحات وصلاحيات الصفحات |
| `dbo.PermissionSP` | إسناد/نسخ/تعطيل الصلاحيات |
| `dbo.UsersDL` | بيانات المستخدمين والـ lookups |
| `dbo.UsersSP` | إنشاء/تعديل/تعطيل المستخدمين |
| `dbo.ReSetUserPassword` | إعادة كلمة مرور المستخدم |
| `dbo.SetUserPassword` | إنشاء/تحديث كلمة المرور، ويستدعيه UsersSP |

### الجداول

- إدارة الصفحات: `Program`, `Menu`, `Distributor`, `MenuDistributor`, `PermissionType`, `DistributorPermissionType`, `permissionAuthLvl`.
- الصلاحيات: `Permission`, `UserDistributor`, `Role`, `Idara`, `Department`, `Section`, `Divison`, `DeptSecDiv`.
- المستخدمون: `Users`, `UsersDetails`, `UsersAuthType`, `UserType`, `usersPassword`, `Gender`, `Nationality`, `Religion`, `MaritalStatus`, `Education`.
- مشتركة: `AuditLog`, `ErrorLog`.

### Views وFunctions

- `V_GetListUserPermission`: عرض الصلاحيات الفعال، ويستخدم للتحميل وفحص كل كتابة.
- `V_GetListUsersInDSD` و`V_GetFullStructureForDSD`: المستخدمون والبنية التنظيمية.
- `V_GetFullSystemUsersDetails`: تفاصيل المستخدم الموسعة.
- `ft_UserPagePermissions(user,page)`: يعيد أسماء صلاحيات الصفحة في result set الأول.

لا يعتمد المسار الموثق على SQL triggers. جميع الأسماء أعلاه مثبتة من التعريفات المرجعية؛ حالة الكائنات الحية لم تعد فحصها في هذه المهمة.

## العلاقات مع البرامج الأخرى

- كل برنامج يستخدم قائمة التنقل الناتجة من Program/Menu/Distributor/MenuDistributor.
- كل كتابة Housing-style تعتمد على PermissionType/DistributorPermissionType/Permission و`V_GetListUserPermission` التي يديرها ControlPanel.
- Login وSession يمدان ControlPanel بـ `usersID` و`IdaraID` والسياق التنظيمي.
- `GetUserMenuTree` يبني قائمة المستخدم من نفس تعريفات القوائم والصلاحيات.
- AuditLog وErrorLog مشتركان بين ControlPanel وبقية البرامج.

## Workflows الفعلية

### نشر صفحة جديدة قابلة للتفويض

1. إنشاء/اختيار برنامج.
2. إنشاء قائمة جانبية اختيارية.
3. إضافة الصفحة؛ الإجراء ينشئ Menu وDistributor وMenuDistributor.
4. إضافة أنواع العمليات للصفحة؛ ينشئ PermissionType وDistributorPermissionType.
5. فتح Permission، اختيار الهدف، وإسناد صلاحية أو Full Access.
6. عند استخدام الصفحة، result set الأول يحدد أزرار UI، وMasters_CRUD يعيد فحص العملية عند POST.

### دورة المستخدم

1. UsersDL يحمل الحسابات والـ lookups.
2. INSERT ينشئ الحساب والتفاصيل والربط وكلمة المرور الأولية.
3. UPDATE يعدل البيانات ويتطلب سبباً في الواجهة.
4. UPDATENATIONALID يتحكم بقابلية تحرير الهوية في UI.
5. RESETUSERPASSWORD يمر إلى الإجراء المتخصص بعد فحص الصلاحية.
6. DELETE يعطل الحساب مع سبب، ولا يحذفه فيزيائياً.

### دورة الصلاحية

1. تحديد نوع الهدف والفلاتر.
2. DataLoad يعرض الصلاحيات المطابقة والـ DDL المقيدة بمستوى الإدارة.
3. إضافة صلاحية مفردة أو جميع صلاحيات موزع.
4. UPDATE يعطل السجل السابق وينشئ نسخة جديدة.
5. DELETE يعطل السجل.

## الأمان والقيود

- مثبت: GET pages تتطلب `Session[usersID]`.
- مثبت: إظهار العمليات مقيد بنتيجة `ft_UserPagePermissions`.
- مثبت: كل POST يمر عبر antiforgery في CrudController وبفحص صلاحية مستقل في `Masters_CRUD`.
- مثبت: SQL يستخدم معاملات وAuditLog ورسائل أخطاء business.
- فجوة: لا توجد `[Authorize]` ولا authentication scheme مثبتة في التركيب الحالي؛ الحماية تعتمد على Session والبوابة.
- فجوة: `SessionGuardMiddleware` غير مسجل كما وثقت المعمارية العامة.
- فجوة: قيم `entrydata`, `idaraID`, `hostname` تأتي كحقول hidden، ويلزم التأكد أن CrudController يعيد اشتقاقها من Session أو أن SQL لا يثق بها بلا تحقق. الكود الحالي يمرر posted form values.
- فجوة: صلاحية `UPDATENATIONALID` مفروضة في UI فقط حسب المسار المقروء.
- فجوة: اتساق زر `INSERTFULLACCESS` و`RESETUSERPASSWORD` مع flags الواجهة يحتاج اختباراً وظيفياً.
- فجوة: `Index` بلا View مكتشفة، وبعض catch blocks تعرض رسالة exception في ViewBag، ما قد يكشف تفاصيل داخلية في بيئة غير مضبوطة.

## Coverage

| البند | مكتشف | موثق | النسبة |
| --- | ---: | ---: | ---: |
| ملفات Controller | 4 | 4 | 100% |
| Controllers منطقية | 1 | 1 | 100% |
| Actions فعلية | 4 | 4 | 100% |
| صفحات ذات View | 3 | 3 | 100% |
| Views | 3 | 3 | 100% |
| عمليات UI/CRUD | 20 | 20 | 100% |
| إجراءات SQL المرتبطة مباشرة | 8 | 8 | 100% من snapshot |
| Views SQL المرتبطة مباشرة | 4 | 4 | 100% من snapshot |
| Functions SQL المرتبطة مباشرة | 1 | 1 | 100% من snapshot |

التغطية تعني اكتمال التتبع في ملفات المستودع، لا تحققاً من سلوك قاعدة البيانات الحية أو اختبار UI end-to-end.

## الفجوات المتبقية

1. مطابقة تعريفات snapshot مع SQL الحي وقياس schema drift باستعلامات catalog قراءة فقط.
2. اختبار كل ActionType بحسابات متعددة الصلاحيات في بيئة اختبار.
3. حسم دلالة magic identities في PermissionSP (Role 20 والمستخدم 4).
4. إثبات طريقة توليد/تخزين كلمة المرور وسياسة التعقيد والدوران تشغيلياً.
5. معالجة/تأكيد فجوات UPDATENATIONALID وFullAccess وReset Password المذكورة أعلاه.
6. تحديد المقصود بـ `ControlPanel/Index` أو إزالة الـ Action غير المستخدمة في عمل تطوير منفصل.

## تحديث المطابقة الحية 2026-08-22

- إجراءات ControlPanel/الأمان المتخصصة مطابقة حياً، باستثناء `UsersDL`.
- `UsersDL` الحي يضيف إلى result set المستخدمين: `distributorID`, `distributorName_A`, `DepartmentID`, و`DepartmentName` من أحدث ربط قسم active.
- `Masters_DataLoad` الحي يضيف ترتيب `DistributorPermissionType` تنازلياً، و`Masters_CRUD` مختلف في فروع أخرى موثقة في 07A.
- أُغلقت فجوة parity الحية؛ تبقى اختبارات الصلاحيات والواجهة وmagic identities غير منفذة.
