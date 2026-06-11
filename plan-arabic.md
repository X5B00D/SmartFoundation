# خطة نظام التذاكر ITIL 4

## 1. حالة المستند
- الحالة: مسودة معاد التخطيط لها لمراجعة المستخدم
- اللغة: English
- النمط الأساسي: `SmartFoundation.Mvc/Controllers/Housing/WaitingList/HousingController.WaitingListByResident.cs`
- عقدة التشغيل: `MastersServies` -> `Masters_DataLoad` / `Masters_CRUD` -> `[Tickets].[...DL]` / `[Tickets].[...SP]`
- الأساس في قاعدة البيانات: كائنات المنظمة والمستخدم والصلاحيات والمقيمين والتدقيق والإشعارات والبوابة موجودة بالفعل في لقطة المستودع
- ملاحظة النطاق: هذا المستند يحدد تصميم V1؛ وهو ليس هو نص النشر نفسه

## 2. الملخص التنفيذي
هذه الخطة تستبدل تصميم التذاكر السابق بتطبيق على نمط Housing يتوافق مع بنية SmartFoundation الحقيقية وتسميات قاعدة البيانات الحقيقية المستخدمة بالفعل.

يعيش نظام V1 بالكامل داخل المخطط `[Tickets]`، لكنه لا ينشئ نموذج هوية جديدًا، ولا نموذج صلاحيات جديدًا، ولا طبقة API منفصلة. بل يعيد استخدام `[dbo].[Users]` و`[dbo].[UsersDetails]` و`[dbo].[Distributor]` و`[dbo].[UserDistributor]` و`[dbo].[Permission]` و`[dbo].[DeptSecDiv]` و`[dbo].[ft_UserPagePermissions]`، وكذلك إجراءات البوابة `[dbo].[Masters_DataLoad]` و`[dbo].[Masters_CRUD]`.

التصميم التشغيلي يتبع ITIL 4 ونمط صفحة Housing الموجود:
- كل الصفحات تمر عبر `@pageName_`
- القراءات تعيد نتيجة الصلاحيات أولًا، ثم بيانات الصفحة ونتائج DDL
- الكتابات تمر عبر `CrudController` باستخدام `p01..p50` mapped to `parameter_01..parameter_50`
- الإجراءات التابعة `[Tickets].[...SP]` تمتلك التحقق التجاري، ومسار التدقيق، وعمليات الكتابة في قاعدة البيانات
- Controllers في MVC تبني `SmartPageViewModel` و`FormConfig` و`SmartTableDsModel` على الخادم

يدعم V1 كلا النوعين من مقدمي الطلبات منذ اليوم الأول:
- المستخدمون الداخليون عبر `UsersID_FK -> [dbo].[Users].[usersID]`
- المقيمون / المستفيدون عبر `residentInfoID_FK -> [Housing].[ResidentInfo].[residentInfoID]`

كما يغطي V1 كامل النطاق الوظيفي المطلوب: كتالوج الخدمات، الاستقبال، التوجيه، الإسناد، التحكيم، التوضيح، الربط الأب-الابن، تتبع SLA مع الإيقاف/الاستئناف، المراجعة النوعية، تعلم الكتالوج، والتقارير.

## 3. المشكلة التجارية
تحتاج الأعمال إلى نظام تذاكر يمكنه:

1. قبول الطلبات من كل من المستخدمين الداخليين والمقيمين.
2. توجيه الخدمات المعروفة إلى صف المنظمة الصحيح باستخدام الحقيقة التنظيمية الموجودة.
3. توجيه الطلبات غير المعروفة أو غير الواضحة إلى محكّم دون كسر مسار التدقيق.
4. فصل التوجيه الخاطئ عن نقص المعلومات وعن التأخير الناتج من الاعتماديات.
5. دعم معالجة الحوادث، ومعالجة طلبات الخدمة، وعلاقات المشكلة/السبب الجذري في نموذج واحد مضبوط.
6. تتبع مستويات الخدمة بعدالة، بما في ذلك الزمن الموقوف بسبب التحكيم، والتوضيح، والموافقات، والعمل الفرعي المعتمد.
7. دعم الإغلاق النوعي بدل أن تتحول كل تذكرة محلولة إلى مغلقة نهائيًا فورًا.
8. تحسين كتالوج الخدمات مع الوقت بناءً على تذاكر "Other" المتكررة.
9. إنتاج لوحات معلومات وتقارير إدارية دون تجاوز بنية التطبيق والصلاحيات الحالية.
10. الحفاظ على معايير التدقيق المركزي وتسجيل الأخطاء المستخدمة بالفعل في Housing.

## 4. النطاق

### 4.1 ضمن النطاق في V1
- نموذج بيانات المخطط `[Tickets]`
- جداول البحث، والبيانات الرئيسية، والمعاملات، والسجل التاريخي
- فروع البوابة داخل `[dbo].[Masters_DataLoad]` و`[dbo].[Masters_CRUD]`
- الإجراءات التابعة `[Tickets].[TicketDL]` و`[Tickets].[TicketSP]` و`[Tickets].[ServiceCatalogDL]` و`[Tickets].[ServiceCatalogSP]` و`[Tickets].[TicketReportDL]`
- صفحات MVC بأسلوب Housing مبنية على `MastersServies` و`DataSet` و`SplitDataSet`
- إدارة كتالوج الخدمات وقواعد التوجيه
- إنشاء التذاكر من كلا نوعي مقدمي الطلبات
- إسناد الصفوف وإسناد المستخدمين
- سير عمل التحكيم
- سير عمل التوضيح
- التذاكر الأب-الابن لتتبع الاعتماديات والمشاكل
- تتبع SLA مع الإيقاف/الاستئناف
- المراجعة النوعية قبل الإغلاق النهائي
- اقتراحات الكتالوج الناتجة من تذاكر "Other" المتكررة
- لوحات المعلومات ونماذج القراءة للتقارير

### 4.2 خارج النطاق في V1
- نقاط نهاية REST أو JSON مستقلة
- استبدال `[dbo].[CrudController]` أو عقد `p01..p50`
- استبدال `[dbo].[Notifications_Create]`
- نظام المرفقات
- إعادة تصميم البوابة العامة
- التصعيد التلقائي عبر SQL Agent أو مهام الخلفية
- CMDB / سجل الأصول
- دمج المخطط المنفصل `[support]` ضمن هذا النظام

## 5. مبادئ التصميم الأساسية
1. التوجيه عبر البوابة إلزامي. يجب أن تمر كل صفحة عبر `[dbo].[Masters_DataLoad]` أو `[dbo].[Masters_CRUD]` باستخدام فروع `@pageName_`.
2. اتفاقيات Housing تتقدم على أفكار إعادة التصميم العامة. يتم الحفاظ على controller و`DataSet` و`SplitDataSet` ونمط Razor النحيف.
3. `DSDID_FK` هو حقيقة التوجيه. أي مستوى عرضي هو وصفي فقط.
4. `IdaraID_FK` موجود في كل جدول داخل `[Tickets]`.
5. `UsersID_FK` يحافظ على اصطلاح المستودع الحالي مع الحرف `s` في النهاية.
6. هوية مقدم الطلب مزدوجة المصدر. يمكن للتذكرة أن تشير إلى `[dbo].[Users]` أو `[Housing].[ResidentInfo]`، ولكن ليس إلى كليهما معًا ولا إلى ولا واحد منهما.
7. حالة التذكرة، والتحكيم، والتوضيح، والإيقاف، والحل، وقرارات الجودة يجب أن تبقى مفاهيم تجارية منفصلة.
8. يجب أن يظهر توافق ITIL 4 بوضوح في المخطط والإجراءات وتصميم الصفحات، لا في النص فقط.
9. كل عملية كتابة يجب أن تنتج صفوف سجل محلي وكذلك إدخالات مركزية في `[dbo].[AuditLog]`.
10. أخطاء التحقق التجارية يجب أن تستخدم `THROW 50001`; أما الفشل غير المتوقع فيجب تسجيله في `[dbo].[ErrorLog]` ثم إعادة رميه.
11. جداول المعاملات والسجل التاريخي تستخدم `BIGINT IDENTITY`; وجداول البحث تستخدم `INT IDENTITY`.
12. جداول السجل التاريخي append-only ولا تستخدم soft delete.

## 6. مواءمة ممارسات ITIL 4

### 6.1 إدارة الحوادث
- دورة الحياة: intake -> triage -> assignment -> in progress -> resolved -> quality review -> closed.
- الجداول الأساسية: `[Tickets].[Ticket]` و`[Tickets].[TicketHistory]` و`[Tickets].[TicketQualityReview]`.
- الحقول الأساسية: `ticketStatusID_FK` و`impactID_FK` و`urgencyID_FK` و`ticketPriorityID_FK` و`resolutionTypeID_FK` و`resolutionNotes` و`isMajorIncident`.

### 6.2 إدارة كتالوج الخدمات
- ملكية الكتالوج موجودة في `[Tickets].[ServiceCategory]` و`[Tickets].[Service]` و`[Tickets].[ServiceRoutingRule]` و`[Tickets].[ServiceSLAPolicy]`.
- الخدمات المعروفة تُوجَّه مباشرة من قاعدة الكتالوج؛ أما "Other" فتُوجَّه إلى التحكيم.

### 6.3 إدارة مستوى الخدمة
- الأولوية تُشتق عبر `[Tickets].[PriorityMatrix]` من impact x urgency.
- مواعيد التذكرة والساعة المتراكمة محفوظة في `[Tickets].[TicketSLA]`.
- نوافذ الإيقاف محفوظة في `[Tickets].[TicketPauseSession]`.
- كل انتقال في حالة SLA يُنسخ إلى `[Tickets].[TicketSLAHistory]`.

### 6.4 إدارة المشكلة
- `[Tickets].[Ticket]` يحمل `ParentTicketID_FK` و`RootTicketID_FK`.
- `ticketClassID_FK` يميز سجلات incident وservice request وproblem.
- سلاسل الأب-الابن تُستخدم للحجب وتتبع السبب الجذري، وليس للتجميع غير الرسمي فقط.

### 6.5 التحسين المستمر
- تذاكر "Other" يمكن أن تنتج صفوفًا منظمة في `[Tickets].[ServiceCatalogSuggestion]`.
- يمكن مراجعة الاقتراحات وتحويلها إلى إدخالات كتالوج عبر `[Tickets].[ServiceCatalogSP]`.

### 6.6 المراقبة وإدارة الأحداث
- تقارير V1 تعتمد على view/DL عبر `[Tickets].[TicketReportDL]` والبوابة `TicketReports`.
- لوحات المعلومات تغطي backlog، وخطر تجاوز SLA، وqueue المراجعة النوعية، وأخطاء التوجيه، وaging التوضيح، والحوادث الكبرى.

### 6.7 تمكين التغيير
- التغييرات في قواعد التوجيه وسياسات SLA تُجرى فقط عبر `[Tickets].[ServiceCatalogSP]`.
- كل تغيير يكتب audit مركزيًا بالإضافة إلى `[Tickets].[ServiceRoutingRuleHistory]` المحلي.

## 7. النموذج الوظيفي المؤكد

### 7.1 مصادر الطلبات
- مقدم طلب داخلي: يتم تهيئة `requesterTypeID_FK` إلى Internal User ويتم ملء `UsersID_FK`.
- مقدم طلب مقيم: يتم تهيئة `requesterTypeID_FK` إلى Resident ويتم ملء `residentInfoID_FK`.
- إجراء إنشاء التذكرة يرفض الصفوف التي تكون فيها الحالتان null أو مملوءتين معًا.

### 7.2 اختيار الكتالوج
- خدمة معروفة: يتم ملء `serviceID_FK` ويُشتق التوجيه/SLA الافتراضي من إعدادات الكتالوج.
- خدمة أخرى: يكون `serviceID_FK` null ويكون `otherServiceText` مطلوبًا.

### 7.3 نموذج التوجيه
- وجهة التوجيه هي `CurrentDSDID_FK` الحالية على `[Tickets].[Ticket]`.
- `CurrentDistributorID_FK` اختياري ويحدد دور الصف إذا أرادت المنظمة inbox يعتمد على المنصب.
- `AssignedToUsersID_FK` هو المعين التنفيذي الحالي ويمكن أن يبقى null عندما تكون التذكرة داخل الصف فقط.

### 7.4 نموذج الإسناد
- مالك الصف أو مشرف مخول يسند العمل إلى مستخدم حقيقي.
- الأهلية تُفحص مقابل البيانات النشطة في `[dbo].[V_GetListUsersInDSD]` ونطاق DSD الحالي.
- إعادة الإسناد تُبقي التذكرة داخل النطاق المصرح به وتكتب صف سجل تاريخي جديد.

### 7.5 نموذج التحكيم
- التحكيم مخصص لنزاع المسؤولية أو توجيه الخدمة غير المعروف.
- التوضيح ليس تحكيمًا.
- حالة التحكيم المفتوحة تُمثل بحالة التذكرة بالإضافة إلى صف نشط في `[Tickets].[TicketArbitration]`.

### 7.6 نموذج التوضيح
- التوضيح مخصص للمعلومات الناقصة أو المبهمة.
- قد يوجَّه التوضيح إلى مقدم الطلب أو الصف الحالي أو مالك الأب أو وحدة داخلية أخرى.
- التوضيح يوقف SLA فقط عندما يكون سبب الإيقاف مضبوطًا على أنه يوقف SLA.

### 7.7 نموذج الأب-الابن والمشكلة
- التذكرة الابن لها `ParentTicketID_FK` واحد وتَرِث `RootTicketID_FK` من العقدة العليا.
- تذكرة المشكلة تمثل عبر `ticketClassID_FK` وقد تعمل كسجل أب/جذر للحوادث المرتبطة.

### 7.8 نموذج SLA
- الأولوية تُضبط عند الإنشاء ويمكن إعادة حسابها فقط عبر إجراء مصرح به.
- مواعيد الاستجابة والانتهاء محفوظة في `[Tickets].[TicketSLA]`.
- الإيقافات تنشئ صفوفًا في `[Tickets].[TicketPauseSession]` مع طوابع زمنية دقيقة للبداية والنهاية.

### 7.9 نموذج المراجعة النوعية
- المنفذ يحل التذكرة.
- المراجع في `TicketQualityReview` يقبلها أو يرفضها أو يعيدها.
- الإغلاق النهائي يحدث فقط بعد مراجعة نوعية ناجحة أو عبر إجراء bypass مسموح به صراحة.

### 7.10 نموذج التقارير
- عرض الصف: `TicketInbox`
- عرض مقدم الطلب: `TicketMyTickets`
- عرض المشرف: `TicketList`
- عرض المنفذ: `TicketWorkbench`
- عرض المراجع: `TicketQualityReview`
- لوحة الإدارة: `TicketReports`

## 8. قرارات معمارية البيانات المؤكدة

### 8.1 قرار المخطط
كل كائنات الأعمال الجديدة لهذا النظام تُنشأ تحت `[Tickets]` فقط.

### 8.2 حقيقة الهوية والتنظيم الموجودة
- هوية المستخدم: `[dbo].[Users]` و`[dbo].[UsersDetails]`
- هوية المقيم: `[Housing].[ResidentInfo]` و`[Housing].[ResidentDetails]`
- الحقيقة التنظيمية: `[dbo].[DeptSecDiv]`
- حقيقة الإسناد التنظيمي: `[dbo].[Distributor]` مع `[dbo].[UserDistributor]`

### 8.3 اصطلاحات المفاتيح الخارجية
- مفتاح المستخدم: `UsersID_FK`
- مفتاح المنظمة: `IdaraID_FK`
- مفتاح DSD: `DSDID_FK`
- مفتاح التذكرة الأب: `ParentTicketID_FK`
- مفتاح الجذر: `RootTicketID_FK`

### 8.4 أعمدة التدقيق
كل جدول داخل `[Tickets]` يتضمن بالضبط:

```sql
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

### 8.5 قرار حقيقة التوجيه
- `CurrentDSDID_FK` على `[Tickets].[Ticket]` هو العقدة التنظيمية المسؤولة الحالية.
- `TargetDSDID_FK` على `[Tickets].[ServiceRoutingRule]` هو عقدة التوجيه الافتراضية لاستقبال الكتالوج.
- أي مستوى توجيه نصي هو وصفي فقط ولا يستبدل مفاتيح DSD أبدًا.

### 8.6 حقيقة الصفحة والإجراء
- طبقة التطبيق ما زالت تربط فقط إدخالات البوابة في `ProcedureMapper`.
- `MastersServies.GetDataLoadDataSetAsync(...)` و`GetCrudDataSetAsync(...)` يظلان مسار الوصول الوحيد للبيانات في طبقة التطبيق لصفحات UI في هذا التصميم.

### 8.7 قرار soft delete
- جداول البحث والبيانات الرئيسية وجداول المعاملات طويلة العمر تستخدم أعلام active حيثما كان مناسبًا.
- جداول السجل التاريخي append-only ولا تُحذف soft delete أبدًا.

### 8.8 فصل مخطط الدعم
`[support].[Ticket]` وكائنات `[support]` المرتبطة به تبقى حلاً منفصلًا لتتبع أخطاء موقع الويب لفريق التطوير الداخلي. وهي ليست جزءًا من تصميم ITIL 4 Tickets ولا يعاد استخدامها هنا.

## 9. الاعتماديات الخارجية
يفترض المخطط `[Tickets]` أن الكائنات الموجودة التالية موجودة وتبقى هي المصدر المعتمد:

| الكائن | دوره في Tickets |
|---|---|
| `[dbo].[Idara]` | الأصل الإلزامي لـ `IdaraID_FK` |
| `[dbo].[Department]` | مرجع تنظيمي للتقارير والعرض المشتق |
| `[dbo].[Section]` | مرجع تنظيمي للتقارير والعرض المشتق |
| `[dbo].[Divison]` | مرجع تنظيمي للتقارير والعرض المشتق |
| `[dbo].[DeptSecDiv]` | حقيقة التوجيه عبر `DSDID_FK` |
| `[dbo].[Users]` | أصل مقدم الطلب الداخلي والمُسند إليه |
| `[dbo].[UsersDetails]` | الاسم المعروض وبيانات الموظف |
| `[dbo].[Distributor]` | المستقبل في الصف / الدور |
| `[dbo].[UserDistributor]` | يتحقق من المستخدمين الذين يمكنهم التصرف داخل أي نطاق صف |
| `[dbo].[Permission]` | هيكل الصلاحيات الحالي |
| `[dbo].[PermissionType]` | هيكل نوع الصلاحية الحالي |
| `[Housing].[ResidentInfo]` | الأصل لمقدم الطلب المقيم |
| `[Housing].[ResidentDetails]` | العرض وبيانات المقيم المرتبطة بـ Idara |
| `[dbo].[AuditLog]` | تدقيق الكتابات المركزي |
| `[dbo].[ErrorLog]` | تسجيل أخطاء SQL غير المتوقعة |
| `[dbo].[Notifications]` | سجلات الإشعارات المخزنة |
| `[dbo].[UserNotifications]` | سجلات إشعارات المستلمين |
| `[dbo].[Notifications_Create]` | إجراء إرسال الإشعارات الحالي |
| `[dbo].[ft_UserPagePermissions]` | نتيجة صلاحيات القراءة عند تحميل الصفحة |
| `[dbo].[V_GetListUserPermission]` | التحقق من صلاحيات CRUD |
| `[dbo].[V_GetListUsersInDSD]` | المستخدمون النشطون المؤهلون حسب DSD |
| `[dbo].[V_GetFullStructureForDSD]` | عرض وتسـجيل هيكل المنظمة |

## 10. مجموعة جداول V1

### 10.1 جداول البحث
- `[Tickets].[RequesterType]`
- `[Tickets].[TicketClass]`
- `[Tickets].[TicketStatus]`
- `[Tickets].[TicketImpact]`
- `[Tickets].[TicketUrgency]`
- `[Tickets].[TicketPriority]`
- `[Tickets].[ResolutionType]`
- `[Tickets].[PauseReason]`
- `[Tickets].[ArbitrationReason]`
- `[Tickets].[ClarificationReason]`
- `[Tickets].[QualityReviewResult]`

### 10.2 الجداول الرئيسية
- `[Tickets].[ServiceCategory]`
- `[Tickets].[Service]`
- `[Tickets].[ServiceRoutingRule]`
- `[Tickets].[ServiceSLAPolicy]`
- `[Tickets].[PriorityMatrix]`

### 10.3 جداول المعاملات
- `[Tickets].[Ticket]`
- `[Tickets].[TicketArbitration]`
- `[Tickets].[TicketClarification]`
- `[Tickets].[TicketPauseSession]`
- `[Tickets].[TicketSLA]`
- `[Tickets].[TicketQualityReview]`
- `[Tickets].[ServiceCatalogSuggestion]`

### 10.4 جداول السجل التاريخي
- `[Tickets].[TicketHistory]`
- `[Tickets].[TicketSLAHistory]`
- `[Tickets].[ServiceRoutingRuleHistory]`

## 11. قرارات DDL جدول-بجدول

### 11.1 `[Tickets].[RequesterType]`
```sql
requesterTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
requesterTypeCode NVARCHAR(50) NOT NULL
requesterTypeName_A NVARCHAR(200) NOT NULL
requesterTypeName_E NVARCHAR(200) NOT NULL
requesterTypeDescription NVARCHAR(1000) NULL
requesterTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, requesterTypeCode)`
- Seed rows: `INTERNAL_USER`, `RESIDENT`

### 11.2 `[Tickets].[TicketClass]`
```sql
ticketClassID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketClassCode NVARCHAR(50) NOT NULL
ticketClassName_A NVARCHAR(200) NOT NULL
ticketClassName_E NVARCHAR(200) NOT NULL
ticketClassDescription NVARCHAR(1000) NULL
ticketClassActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, ticketClassCode)`
- Seed rows: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`

### 11.3 `[Tickets].[TicketStatus]`
```sql
ticketStatusID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketStatusCode NVARCHAR(50) NOT NULL
ticketStatusName_A NVARCHAR(200) NOT NULL
ticketStatusName_E NVARCHAR(200) NOT NULL
sortOrder INT NOT NULL
isClosedStatus BIT NOT NULL
isPauseStatus BIT NOT NULL
ticketStatusActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, ticketStatusCode)`
- Seed rows: `NEW`, `TRIAGED`, `ASSIGNED`, `IN_PROGRESS`, `WAITING_ARBITRATION`, `WAITING_CLARIFICATION`, `WAITING_CHILD`, `RESOLVED`, `QUALITY_REVIEW`, `CLOSED`, `CANCELLED`, `REJECTED_BY_QUALITY`

### 11.4 `[Tickets].[TicketImpact]`
```sql
impactID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
impactCode NVARCHAR(50) NOT NULL
impactName_A NVARCHAR(200) NOT NULL
impactName_E NVARCHAR(200) NOT NULL
impactScore INT NOT NULL
impactDescription NVARCHAR(1000) NULL
impactActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, impactCode)`
- Seed rows: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

### 11.5 `[Tickets].[TicketUrgency]`
```sql
urgencyID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
urgencyCode NVARCHAR(50) NOT NULL
urgencyName_A NVARCHAR(200) NOT NULL
urgencyName_E NVARCHAR(200) NOT NULL
urgencyScore INT NOT NULL
urgencyDescription NVARCHAR(1000) NULL
urgencyActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, urgencyCode)`
- Seed rows: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

### 11.6 `[Tickets].[TicketPriority]`
```sql
ticketPriorityID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketPriorityCode NVARCHAR(50) NOT NULL
ticketPriorityName_A NVARCHAR(200) NOT NULL
ticketPriorityName_E NVARCHAR(200) NOT NULL
sortOrder INT NOT NULL
ticketPriorityColor NVARCHAR(30) NULL
ticketPriorityActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, ticketPriorityCode)`
- Seed rows: `P1`, `P2`, `P3`, `P4`

### 11.7 `[Tickets].[ResolutionType]`
```sql
resolutionTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
resolutionTypeCode NVARCHAR(50) NOT NULL
resolutionTypeName_A NVARCHAR(200) NOT NULL
resolutionTypeName_E NVARCHAR(200) NOT NULL
resolutionTypeDescription NVARCHAR(1000) NULL
resolutionTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, resolutionTypeCode)`
- Seed rows: `FIXED`, `WORKAROUND`, `KNOWN_ERROR`, `NOT_REPRODUCIBLE`, `DUPLICATE`

### 11.8 `[Tickets].[PauseReason]`
```sql
pauseReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
pauseReasonCode NVARCHAR(50) NOT NULL
pauseReasonName_A NVARCHAR(200) NOT NULL
pauseReasonName_E NVARCHAR(200) NOT NULL
pausesSLA BIT NOT NULL
pauseReasonDescription NVARCHAR(1000) NULL
pauseReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- Unique: `(IdaraID_FK, pauseReasonCode)`
- Seed rows: `ARBITRATION`, `CLARIFICATION`, `WAITING_CHILD`, `WAITING_APPROVAL`, `EXTERNAL_DEPENDENCY`

### 11.9 `[Tickets].[ArbitrationReason]`
```sql
arbitrationReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
arbitrationReasonCode NVARCHAR(50) NOT NULL
arbitrationReasonName_A NVARCHAR(200) NOT NULL
arbitrationReasonName_E NVARCHAR(200) NOT NULL
```
arbitrationReasonDescription NVARCHAR(1000) NULL
arbitrationReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, arbitrationReasonCode)`
- الصفوف الأولية: `UNKNOWN_SERVICE`, `WRONG_SCOPE`, `CROSS_DEPARTMENT`, `MANAGER_DECISION_REQUIRED`

### 11.10 `[Tickets].[ClarificationReason]`
```sql
clarificationReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
clarificationReasonCode NVARCHAR(50) NOT NULL
clarificationReasonName_A NVARCHAR(200) NOT NULL
clarificationReasonName_E NVARCHAR(200) NOT NULL
clarificationReasonDescription NVARCHAR(1000) NULL
clarificationReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, clarificationReasonCode)`
- الصفوف الأولية: `MISSING_DETAILS`, `MISSING_APPROVAL`, `MISSING_DOCUMENT`, `NEED_PARENT_INPUT`

### 11.11 `[Tickets].[QualityReviewResult]`
```sql
qualityReviewResultID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
qualityReviewResultCode NVARCHAR(50) NOT NULL
qualityReviewResultName_A NVARCHAR(200) NOT NULL
qualityReviewResultName_E NVARCHAR(200) NOT NULL
qualityReviewResultDescription NVARCHAR(1000) NULL
qualityReviewResultActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, qualityReviewResultCode)`
- الصفوف الأولية: `APPROVED`, `RETURNED`, `REJECTED`

### 11.12 `[Tickets].[ServiceCategory]`
```sql
serviceCategoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceCategoryCode NVARCHAR(50) NOT NULL
serviceCategoryName_A NVARCHAR(200) NOT NULL
serviceCategoryName_E NVARCHAR(200) NOT NULL
serviceCategoryDescription NVARCHAR(1000) NULL
sortOrder INT NOT NULL
serviceCategoryActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, serviceCategoryCode)`

### 11.13 `[Tickets].[Service]`
```sql
serviceID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceCategoryID_FK BIGINT NOT NULL FK -> [Tickets].[ServiceCategory].[serviceCategoryID]
ticketClassID_FK INT NOT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
defaultImpactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
defaultUrgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
defaultPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
serviceCode NVARCHAR(50) NOT NULL
serviceName_A NVARCHAR(200) NOT NULL
serviceName_E NVARCHAR(200) NOT NULL
serviceDescription NVARCHAR(MAX) NULL
allowResidentRequest BIT NOT NULL
allowInternalRequest BIT NOT NULL
requiresQualityReview BIT NOT NULL
allowChildTickets BIT NOT NULL
isOtherPlaceholder BIT NOT NULL
serviceActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, serviceCode)`
- `isOtherPlaceholder = 0` للخدمات الحقيقية؛ الواجهة تتعامل مع "Other" على أنه `serviceID_FK` فارغ

### 11.14 `[Tickets].[ServiceRoutingRule]`
```sql
serviceRoutingRuleID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
requesterTypeID_FK INT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
TargetDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
TargetDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
ArbitratorDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ArbitratorDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
rulePriority INT NOT NULL
effectiveFrom DATETIME NOT NULL
effectiveTo DATETIME NULL
serviceRoutingRuleActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- تصميم فريد مفلتر: صف نشط واحد لكل `(IdaraID_FK, serviceID_FK, requesterTypeID_FK)` ونطاق تاريخي
- `TargetDSDID_FK` هو مرجع التوجيه الصحيح
- `ArbitratorDSDID_FK` إلزامي حتى تكون حالات النطاق الخاطئ وحالات الخدمة الأخرى لها وجهة صالحة دائمًا

### 11.15 `[Tickets].[ServiceSLAPolicy]`
```sql
serviceSLAPolicyID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
responseTargetMinutes INT NOT NULL
resolutionTargetMinutes INT NOT NULL
allowPause BIT NOT NULL
requiresMajorIncidentReview BIT NOT NULL
effectiveFrom DATETIME NOT NULL
effectiveTo DATETIME NULL
serviceSLAPolicyActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- هدف سياسة نشطة فريد: `(IdaraID_FK, serviceID_FK, ticketPriorityID_FK)`

### 11.16 `[Tickets].[PriorityMatrix]`
```sql
priorityMatrixID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
impactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
urgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
isMajorIncidentDefault BIT NOT NULL
priorityMatrixActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, impactID_FK, urgencyID_FK)`
- هذا هو مصدر تعيين أولوية ITIL الإلزامي

### 11.17 `[Tickets].[Ticket]`
```sql
ticketID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketNo NVARCHAR(30) NOT NULL
ticketClassID_FK INT NOT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
ticketStatusID_FK INT NOT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
requesterTypeID_FK INT NOT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
serviceID_FK BIGINT NULL FK -> [Tickets].[Service].[serviceID]
UsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
residentInfoID_FK BIGINT NULL FK -> [Housing].[ResidentInfo].[residentInfoID]
OpenedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
CurrentDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
CurrentDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
AssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
impactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
urgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
resolutionTypeID_FK INT NULL FK -> [Tickets].[ResolutionType].[resolutionTypeID]
ParentTicketID_FK BIGINT NULL FK -> [Tickets].[Ticket].[ticketID]
RootTicketID_FK BIGINT NULL FK -> [Tickets].[Ticket].[ticketID]
ticketTitle NVARCHAR(500) NOT NULL
ticketDescription NVARCHAR(MAX) NOT NULL
otherServiceText NVARCHAR(500) NULL
resolutionNotes NVARCHAR(MAX) NULL
isMajorIncident BIT NOT NULL
openedAt DATETIME NOT NULL
firstRespondedAt DATETIME NULL
resolvedAt DATETIME NULL
closedAt DATETIME NULL
lastStatusChangedAt DATETIME NOT NULL
ticketActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, ticketNo)`
- قاعدة تحقق في SP: يجب أن يكون أحد `UsersID_FK` أو `residentInfoID_FK` فقط ممتلئًا
- قاعدة تحقق في SP: يجب أن يكون `serviceID_FK` أو `otherServiceText` ممتلئًا
- `RootTicketID_FK` يساوي السجل نفسه للسجلات الجذرية بعد إنهاء الإضافة

### 11.18 `[Tickets].[TicketArbitration]`
```sql
ticketArbitrationID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
arbitrationReasonID_FK INT NOT NULL FK -> [Tickets].[ArbitrationReason].[arbitrationReasonID]
RequestedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
RequestedFromDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ArbitratorDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
DecisionByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
DecisionTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
decisionNotes NVARCHAR(MAX) NULL
requestedAt DATETIME NOT NULL
decidedAt DATETIME NULL
ticketArbitrationActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يوجد صف تحكيم نشط واحد فقط لكل تذكرة في نفس الوقت
- منطق الإغلاق موجود في `[Tickets].[TicketSP]`

### 11.19 `[Tickets].[TicketClarification]`
```sql
ticketClarificationID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
clarificationReasonID_FK INT NOT NULL FK -> [Tickets].[ClarificationReason].[clarificationReasonID]
RequestedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
RequestedFromUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
RequestedFromDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
requestText NVARCHAR(MAX) NOT NULL
responseText NVARCHAR(MAX) NULL
respondedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
requestedAt DATETIME NOT NULL
respondedAt DATETIME NULL
ticketClarificationActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يوجد صف توضيح نشط واحد فقط لكل تذكرة في نفس الوقت
- يجب أن يكون أحد `RequestedFromUsersID_FK` أو `RequestedFromDSDID_FK` ممتلئًا على الأقل

### 11.20 `[Tickets].[TicketPauseSession]`
```sql
ticketPauseSessionID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
pauseReasonID_FK INT NOT NULL FK -> [Tickets].[PauseReason].[pauseReasonID]
StartedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
EndedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
pauseNotes NVARCHAR(MAX) NULL
startedAt DATETIME NOT NULL
endedAt DATETIME NULL
pausedMinutes INT NULL
ticketPauseSessionActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يوجد جلسة إيقاف نشطة واحدة فقط لكل تذكرة في نفس الوقت
- يتم تثبيت `pausedMinutes` عندما تنتهي الجلسة

### 11.21 `[Tickets].[TicketSLA]`
```sql
ticketSLAID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
serviceSLAPolicyID_FK BIGINT NULL FK -> [Tickets].[ServiceSLAPolicy].[serviceSLAPolicyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
responseTargetMinutes INT NOT NULL
resolutionTargetMinutes INT NOT NULL
responseDueAt DATETIME NOT NULL
resolutionDueAt DATETIME NOT NULL
totalPausedMinutes INT NOT NULL
responseBreached BIT NOT NULL
resolutionBreached BIT NOT NULL
slaState NVARCHAR(50) NOT NULL
ticketSLAActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يوجد صف SLA نشط واحد لكل تذكرة
- قيم `slaState` يتم التحكم بها في منطق SP: `RUNNING`, `PAUSED`, `RESOLVED`, `CLOSED`, `BREACHED`

### 11.22 `[Tickets].[TicketQualityReview]`
```sql
ticketQualityReviewID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
qualityReviewResultID_FK INT NULL FK -> [Tickets].[QualityReviewResult].[qualityReviewResultID]
ReviewerUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
reviewNotes NVARCHAR(MAX) NULL
reviewStartedAt DATETIME NOT NULL
reviewCompletedAt DATETIME NULL
ticketQualityReviewActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يوجد صف مراجعة جودة نشط واحد فقط لكل تذكرة
- تبدأ المراجعة عندما تدخل التذكرة إلى `QUALITY_REVIEW`

### 11.23 `[Tickets].[ServiceCatalogSuggestion]`
```sql
serviceCatalogSuggestionID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
requesterTypeID_FK INT NOT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
proposedServiceName NVARCHAR(200) NOT NULL
proposedCategoryName NVARCHAR(200) NULL
proposedTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
reviewedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
reviewDecision NVARCHAR(50) NULL
reviewNotes NVARCHAR(MAX) NULL
reviewedAt DATETIME NULL
serviceCatalogSuggestionActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يمكن لتذكرة واحدة أن تنشئ اقتراحًا نشطًا واحدًا أو لا تنشئ أي اقتراح
- يتم التحكم في `reviewDecision` بقيم SP مثل `PENDING`, `ACCEPTED`, `REJECTED`, `MERGED`

### 11.24 `[Tickets].[TicketHistory]`
```sql
ticketHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
historyActionCode NVARCHAR(100) NOT NULL
oldTicketStatusID_FK INT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
newTicketStatusID_FK INT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
oldDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
oldAssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
newAssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
historyNotes NVARCHAR(MAX) NULL
performedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إضافة فقط
- يُستخدم لعرض الخط الزمني في `TicketWorkbench`

### 11.25 `[Tickets].[TicketSLAHistory]`
```sql
ticketSLAHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
TicketSLAID_FK BIGINT NOT NULL FK -> [Tickets].[TicketSLA].[ticketSLAID]
slaActionCode NVARCHAR(100) NOT NULL
oldSlaState NVARCHAR(50) NULL
newSlaState NVARCHAR(50) NULL
responseDueAt DATETIME NULL
resolutionDueAt DATETIME NULL
totalPausedMinutes INT NULL
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
performedAt DATETIME NOT NULL
historyNotes NVARCHAR(MAX) NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إضافة فقط

### 11.26 `[Tickets].[ServiceRoutingRuleHistory]`
```sql
serviceRoutingRuleHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceRoutingRuleID_FK BIGINT NOT NULL FK -> [Tickets].[ServiceRoutingRule].[serviceRoutingRuleID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
historyActionCode NVARCHAR(100) NOT NULL
oldTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
oldArbitratorDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newArbitratorDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
historyNotes NVARCHAR(MAX) NULL
performedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إضافة فقط
- هذا هو سجل التدقيق المحلي لتفعيل التغييرات على التوجيه

## 12. خريطة Stored Procedure

### 12.1 `[Tickets].[TicketDL]`
الهدف:
- تحميل بيانات الصفحة لـ `TicketCreate`, `TicketMyTickets`, `TicketInbox`, `TicketList`, `TicketWorkbench`, `TicketQualityReview`

نمط التوقيع:
```sql
CREATE PROCEDURE [Tickets].[TicketDL]
    @pageName_ NVARCHAR(400)
  , @idaraID INT
  , @entrydata INT
  , @hostname NVARCHAR(400)
  , @parameter_01 NVARCHAR(400) = NULL
  , @parameter_02 NVARCHAR(400) = NULL
  , @parameter_03 NVARCHAR(400) = NULL
```

قواعد Resultset:
- Resultset 0 يأتي من `[dbo].[Masters_DataLoad]` عبر `[dbo].[ft_UserPagePermissions]`
- Resultset 1 هو دائمًا بيانات الصفحة الرئيسية
- Resultset 2+ هي مجموعات lookup لـ نماذج `SmartRenderer` والمرشحات

### 12.2 `[Tickets].[TicketSP]`
الهدف:
- كل عمليات الكتابة في دورة حياة التذكرة

مجموعات Action:
- `INSERTTICKET`
- `UPDATETICKETDETAILS`
- `ASSIGNTICKET`
- `REASSIGNTICKET`
- `STARTPROGRESS`
- `REQUESTARBITRATION`
- `DECIDEARBITRATION`
- `REQUESTCLARIFICATION`
- `RESPONDCLARIFICATION`
- `CREATECHILDTICKET`
- `PAUSETICKET`
- `RESUMETICKET`
- `RESOLVETICKET`
- `STARTQUALITYREVIEW`
- `COMPLETEQUALITYREVIEW`
- `CLOSETICKET`
- `REOPENTICKET`
- `MARKMAJORINCIDENT`

المسؤوليات الشائعة:
- التحقق من هوية طالب الإجراء
- التحقق من مسار service أو other-service
- حساب الأولوية من `[Tickets].[PriorityMatrix]`
- تحميل SLA من `[Tickets].[ServiceSLAPolicy]`
- التحقق من أهلية DSD/المستخدم من `[dbo].[V_GetListUsersInDSD]`
- كتابة `[Tickets].[TicketHistory]` و `[Tickets].[TicketSLAHistory]` و `[dbo].[AuditLog]`
- تسجيل الأخطاء غير المتوقعة في `[dbo].[ErrorLog]`
- استدعاء `[dbo].[Notifications_Create]` عند الحاجة

### 12.3 `[Tickets].[ServiceCatalogDL]`
الغرض:
- قراءة بيانات صفحة صيانة كتالوج الخدمات لـ `ServiceCatalog`

مجموعات النتائج الرئيسية:
- شبكة الخدمات
- شبكة قواعد التوجيه
- شبكة سياسة SLA
- lookups الفئات/الحالات/الأولويات/DSD
- قائمة مراجعة الاقتراحات

### 12.4 `[Tickets].[ServiceCatalogSP]`
الغرض:
- كتابات الكتالوج والتوجيه وSLA والاقتراحات

مجموعات الإجراءات:
- `INSERTSERVICECATEGORY`
- `UPDATESERVICECATEGORY`
- `DELETESERVICECATEGORY`
- `INSERTSERVICE`
- `UPDATESERVICE`
- `DELETESERVICE`
- `INSERTROUTINGRULE`
- `UPDATEROUTINGRULE`
- `DELETEROUTINGRULE`
- `INSERTSLAPOLICY`
- `UPDATESLAPOLICY`
- `DELETESLAPOLICY`
- `REVIEWCATALOGSUGGESTION`
- `CONVERTSUGGESTIONTOSERVICE`

### 12.5 `[Tickets].[TicketReportDL]`
الغرض:
- مجموعات بيانات التقارير لـ `TicketReports`

مجموعات النتائج الرئيسية:
- ملخص KPI
- التراكم حسب الحالة
- التراكم حسب DSD
- ملخص خرق SLA
- ملخص الحوادث الكبرى
- تقادم التوضيحات
- تقادم التحكيم
- حجم اقتراحات الكتالوج

## 13. خريطة تصميم العرض / DL

### 13.1 `TicketCreate`
- فرع الـ Gateway يستدعي `[Tickets].[TicketDL]`
- مجموعة النتائج 1: سياق طالب الإجراء وأي تحذيرات لتذاكر مفتوحة
- مجموعة النتائج 2: الخدمات
- مجموعة النتائج 3: فئات التذاكر
- مجموعة النتائج 4: التأثيرات
- مجموعة النتائج 5: حالات الاستعجال
- مجموعة النتائج 6: أنواع طالبي الإجراء

### 13.2 `TicketMyTickets`
- مجموعة النتائج 1: قائمة تذاكر طالب الإجراء
- مجموعة النتائج 2: DDL فلتر الحالة
- مجموعة النتائج 3: DDL فلتر الأولوية

### 13.3 `TicketInbox`
- مجموعة النتائج 1: التذاكر المملوكة للطابور حسب `CurrentDSDID_FK`
- مجموعة النتائج 2: المعينون المؤهلون من `[dbo].[V_GetListUsersInDSD]`
- مجموعة النتائج 3: DDL فلتر الحالة

### 13.4 `TicketList`
- مجموعة النتائج 1: قائمة الإدارة ضمن نطاق الصلاحية وIdara
- مجموعة النتائج 2: DDL فلتر الحالة
- مجموعة النتائج 3: DDL فلتر الفئة
- مجموعة النتائج 4: DDL فلتر الأولوية
- مجموعة النتائج 5: DDL المنظمة من `[dbo].[V_GetFullStructureForDSD]`

### 13.5 `TicketWorkbench`
- مجموعة النتائج 1: ترويسة تذكرة واحدة
- مجموعة النتائج 2: الخط الزمني للسجل
- مجموعة النتائج 3: صفوف التحكيم النشطة
- مجموعة النتائج 4: صفوف التوضيح النشطة
- مجموعة النتائج 5: التذاكر الفرعية
- مجموعة النتائج 6: صف SLA
- مجموعة النتائج 7: lookups إجراءات المعيّن/DSD

### 13.6 `TicketQualityReview`
- مجموعة النتائج 1: التذاكر المحلولة المنتظرة لمراجعة الجودة
- مجموعة النتائج 2: lookup نتيجة المراجعة
- مجموعة النتائج 3: إحصاءات الأولوية/الحالة لبطاقات لوحة المراجع

### 13.7 `ServiceCatalog`
- فرع الـ Gateway يستدعي `[Tickets].[ServiceCatalogDL]`
- مجموعة النتائج 1: الخدمات
- مجموعة النتائج 2: قواعد التوجيه
- مجموعة النتائج 3: سياسات SLA
- مجموعة النتائج 4: فئات الخدمات
- مجموعة النتائج 5: lookups DSD
- مجموعة النتائج 6: اقتراحات الكتالوج

### 13.8 `TicketReports`
- فرع الـ Gateway يستدعي `[Tickets].[TicketReportDL]`
- مجموعات النتائج خاصة بالتقارير فقط ولا يجب إعادة استخدامها لصفحات CRUD

## 14. إضافات توجيه الـ Gateway

### 14.1 `[dbo].[Masters_DataLoad]`
أضف فروع `@pageName_` التالية باتباع نمط Housing الحقيقي:

```sql
ELSE IF @pageName_ = 'TicketCreate'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
END

ELSE IF @pageName_ = 'TicketMyTickets'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketInbox'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketList'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
      , @parameter_03 = @parameter_03
END

ELSE IF @pageName_ = 'TicketWorkbench'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketQualityReview'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'ServiceCatalog'
BEGIN
    EXEC [Tickets].[ServiceCatalogDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketReports'
BEGIN
    EXEC [Tickets].[TicketReportDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
END
```

### 14.2 `[dbo].[Masters_CRUD]`
أضف فروع الصفحات هذه باتباع أسلوب التحقق من الصلاحية الحقيقي في `WaitingListByResident`:

```sql
ELSE IF @pageName_ = 'TicketCreate'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03;
END

ELSE IF @pageName_ = 'TicketWorkbench'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03
      , @param4       = @parameter_04
      , @param5       = @parameter_05;
END

ELSE IF @pageName_ = 'TicketQualityReview'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03;
END

ELSE IF @pageName_ = 'ServiceCatalog'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[ServiceCatalogSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03
      , @param4       = @parameter_04
      , @param5       = @parameter_05;
END
```

قيم الصفحات التي يجب إضافتها بالضبط:
- `TicketCreate`
- `TicketMyTickets`
- `TicketInbox`
- `TicketList`
- `TicketWorkbench`
- `TicketQualityReview`
- `ServiceCatalog`
- `TicketReports`

## 15. مصفوفة القواعد التجارية

| المعرف | القاعدة | مكان التنفيذ |
|---|---|---|
| BR-01 | يجب أن يوجد مصدر طلب واحد فقط بالضبط: `UsersID_FK` xor `residentInfoID_FK` | `[Tickets].[TicketSP]` |
| BR-02 | الخدمة المعروفة تتطلب `serviceID_FK`; والخدمة غير المعروفة تتطلب `otherServiceText` | `[Tickets].[TicketSP]` |
| BR-03 | إنشاء التذكرة يجب أن يحسب الأولوية من `impactID_FK` x `urgencyID_FK` عبر `[Tickets].[PriorityMatrix]` | `[Tickets].[TicketSP]` |
| BR-04 | إنشاء التذكرة يجب أن يحمل SLA من `[Tickets].[ServiceSLAPolicy]` عندما يكون `serviceID_FK` موجودًا | `[Tickets].[TicketSP]` |
| BR-05 | يجب أن يكون `CurrentDSDID_FK` معبأ دائمًا على `[Tickets].[Ticket]` | `[Tickets].[TicketSP]` |
| BR-06 | الإسناد إلى `AssignedToUsersID_FK` صحيح فقط إذا كان المستخدم نشطًا ومؤهلًا في `[dbo].[V_GetListUsersInDSD]` لـ DSD الحالي | `[Tickets].[TicketSP]` |
| BR-07 | لا يمكن أن يكون التحكيم والتوضيح نشطين معًا لنفس التذكرة في الوقت نفسه | `[Tickets].[TicketSP]` |
| BR-08 | لا توجد إلا جلسة إيقاف نشطة واحدة لكل تذكرة | `[Tickets].[TicketSP]` بالإضافة إلى تحقق استعلام الجدول |
| BR-09 | يجب ضبط الروابط الأصلية والجذرية بشكل ذري عند إنشاء تذكرة فرعية | `[Tickets].[TicketSP]` |
| BR-10 | لا يمكن للتذكرة أن تنتقل إلى `CLOSED` قبل مراجعة الجودة الناجحة إلا إذا مُنح إجراء تجاوز محدد | `[Tickets].[TicketSP]` وتهيئة الصلاحيات |
| BR-11 | `resolutionTypeID_FK` و `resolutionNotes` مطلوبان لـ `RESOLVETICKET` | `[Tickets].[TicketSP]` |
| BR-12 | `isMajorIncident = 1` يتطلب توجيهًا حرجًا ورؤية للمراجع | `[Tickets].[TicketSP]` بالإضافة إلى `TicketReportDL` |
| BR-13 | كل عملية كتابة تُدخل سجل تاريخ محليًا وسجلًا مركزيًا في `[dbo].[AuditLog]` | `[Tickets].[TicketSP]` و `[Tickets].[ServiceCatalogSP]` |
| BR-14 | تغييرات قواعد التوجيه يجب أن تكتب في `[Tickets].[ServiceRoutingRuleHistory]` | `[Tickets].[ServiceCatalogSP]` |
| BR-15 | جداول السجل append-only | تصميم SP وعدم وجود مسارات delete/update |
| BR-16 | كل قراءة صفحة يجب أن تعيد مجموعة نتائج الصلاحيات أولًا عبر `[dbo].[ft_UserPagePermissions]` | `[dbo].[Masters_DataLoad]` |
| BR-17 | كل صفحة CRUD يجب أن تتحقق من صلاحية الصفحة عبر `[dbo].[V_GetListUserPermission]` قبل استدعاء SP downstream | `[dbo].[Masters_CRUD]` |
| BR-18 | يجب أن يحدد `TicketInbox` و `TicketWorkbench` التذاكر المرئية حسب صلاحية الصفحة والحقيقة التنظيمية الحالية | تصميم استعلام DL |

## 16. تسلسل تنفيذ Spec-Kit

| Spec | القدرة | يعتمد على |
|---|---|---|
| Spec 01 | إنشاء جداول lookup وبيانات البدء | none |
| Spec 02 | إنشاء جداول الكتالوج الرئيسية `[Tickets].[ServiceCategory]` و `[Tickets].[Service]` و `[Tickets].[PriorityMatrix]` | Spec 01 |
| Spec 03 | إنشاء جداول التوجيه وSLA الرئيسية `[Tickets].[ServiceRoutingRule]` و `[Tickets].[ServiceSLAPolicy]` | Spec 01, Spec 02 |
| Spec 04 | إنشاء `[Tickets].[Ticket]` و `[Tickets].[TicketHistory]` و `[Tickets].[TicketSLA]` و `[Tickets].[TicketSLAHistory]` | Spec 01, Spec 02, Spec 03 |
| Spec 05 | تنفيذ إجراءات `[Tickets].[TicketSP]` لـ `INSERTTICKET` و `ASSIGNTICKET` و `STARTPROGRESS` و `RESOLVETICKET` | Spec 04 |
| Spec 06 | إضافة جداول التحكيم وإجراءات `REQUESTARBITRATION` / `DECIDEARBITRATION` | Spec 04, Spec 05 |
| Spec 07 | إضافة جداول التوضيح وإجراءات `REQUESTCLARIFICATION` / `RESPONDCLARIFICATION` | Spec 04, Spec 05 |
| Spec 08 | إضافة تذكرة فرعية وتدفق المشكلة مع `CREATECHILDTICKET` و `PAUSETICKET` و `RESUMETICKET` | Spec 04, Spec 05 |
| Spec 09 | إضافة جدول مراجعة الجودة وإجراءات `STARTQUALITYREVIEW` و `COMPLETEQUALITYREVIEW` و `CLOSETICKET` | Spec 04, Spec 05 |
| Spec 10 | إضافة جدول اقتراحات الكتالوج وإجراءات المراجعة/التحويل في `[Tickets].[ServiceCatalogSP]` | Spec 02, Spec 03, Spec 05 |
| Spec 11 | إضافة إجراءات DL وإجراء التقارير وفروع الـ gateway | Specs 01-10 حسب الحاجة |
| Spec 12 | إضافة صفحات MVC بنمط Housing وأفعال المتحكم باستخدام `MastersServies` و `SplitDataSet` و `SmartRenderer` | Spec 11 |

## 17. استراتيجية الاختبار

### 17.1 التحقق من DDL قاعدة البيانات
- إنشاء كل الجداول في قاعدة بيانات مؤقتة
- التحقق من قواعد PK وFK وidentity وnullability
- التحقق من عدم وجود أي جدول يفتقد `IdaraID_FK` أو `entryDate` أو `entryData` أو `hostName`

### 17.2 اختبارات الوحدات للإجراءات
- `INSERTTICKET` للمستخدم الداخلي
- `INSERTTICKET` للمقيم
- حساب الأولوية من مصفوفة التأثير/الاستعجال
- التوجيه إلى service DSD
- التوجيه إلى التحكيم عند الخدمة غير المعروفة
- رفض الطلب المزدوج غير الصحيح
- رفض المعيّن غير الصحيح
- اشتراط مراجعة الجودة قبل الإغلاق

### 17.3 اختبارات الـ Gateway
- كل فرع `@pageName_` يصل إلى الإجراء downstream المتوقع
- `[dbo].[Masters_DataLoad]` لا يزال يعيد مجموعة نتائج الصلاحيات أولًا
- `[dbo].[Masters_CRUD]` يمنع الأفعال غير المصرح بها بنفس الرسالة العربية الحالية

### 17.4 اختبارات SLA
- يتم حساب مواعيد الاستجابة والإنهاء بشكل صحيح
- الإيقاف/الاستئناف يحدّث `totalPausedMinutes`
- توقفات التحكيم والتوضيح تعمل وفق `[Tickets].[PauseReason]`

### 17.5 اختبارات نمط MVC
- المتحكمات تبني مصفوفات معاملات موضعية بنمط Housing
- ترتيب `SplitDataSet` يطابق افتراضات الصفحة
- خط `TicketWorkbench` الزمني يُعرض من `[Tickets].[TicketHistory]`

### 17.6 اختبارات التدقيق والأخطاء
- كل كتابة ناجحة تنشئ صفًا في `[dbo].[AuditLog]`
- أخطاء الأعمال المرمية تستخدم `50001`
- الأخطاء غير المتوقعة تُكتب في `[dbo].[ErrorLog]`

## 18. اعتبارات النشر والتراجع

### 18.1 ترتيب النشر
1. إنشاء جداول lookup
2. تعبئة بيانات lookup
3. إنشاء الجداول الرئيسية
4. إنشاء جداول المعاملات والتاريخ
5. إنشاء إجراءات `[Tickets]` downstream
6. إضافة فروع الـ gateway في `[dbo].[Masters_DataLoad]` و `[dbo].[Masters_CRUD]`
7. نشر المتحكم وطرق العرض MVC
8. نشر إعدادات الصلاحيات/القائمة لأسماء الصفحات

### 18.2 استراتيجية التراجع
- إذا فشل النشر قبل تغييرات الـ gateway، فاحذف كائنات `[Tickets]` الجديدة بترتيب الاعتماد العكسي
- إذا فشل النشر بعد تغييرات الـ gateway، فأزل أولًا فروع `@pageName_` الجديدة، ثم عطّل القوائم/الصلاحيات، ثم ارجع كائنات `[Tickets]`
- سجلات التاريخ والتدقيق لا تُحذف من تراجع الإنتاج بدون موافقة أعمال صريحة

### 18.3 اعتبارات ترحيل البيانات
- مخطط `[Tickets]` موجود حاليًا كهيكل فارغ، لذا يمكن أن تبدأ V1 نظيفة
- لا يوجد ترحيل من `[support]` ضمن هذا المخطط

## 19. ملاحظات التنفيذ
- يجب أن يواصل `ProcedureMapper` إظهار مداخل الـ gateway فقط، وليس كل Stored Procedure في `[Tickets]`.
- يجب أن يتبع المتحكم نمط Housing حرفيًا: `InitPageContext(out redirectResult)` و `ControllerName` و `PageName` و المعاملات الموضعية و `GetDataLoadDataSetAsync` و `SplitDataSet` و model الصفحة المبني من السيرفر و view النحيف.
- سطح المتحكم المقترح:
  `TicketsController.TicketCreate` و `TicketsController.TicketMyTickets` و `TicketsController.TicketInbox` و `TicketsController.TicketList` و `TicketsController.TicketWorkbench` و `TicketsController.TicketQualityReview` و `TicketsController.ServiceCatalog` و `TicketsController.TicketReports`.
- يبقى `CrudController` نقطة الدخول للكتابة. تواصل النماذج الإرسال بـ `p01..p50` والحقول المخفية مثل `pageName_` و `ActionType` و `idaraID` و `entrydata` و `hostname`.
- يجب أن تحافظ نماذج القراءة على انضباط ترتيب Housing: الصلاحيات أولًا، ثم الـ grid/header الأساسي، ثم مساعدات DDL/result.
- يجب أن تستخدم الإشعارات `[dbo].[Notifications_Create]` من منطق SP downstream عند الحاجة التشغيلية؛ لا يُعاد تصميم نظام الإشعارات نفسه هنا.

## 20. توضيح مخطط الدعم
مخطط `[support]` الحالي خارج نطاق هذا التصميم بشكل صريح.

`[support].[Ticket]` و `[support].[TicketType]` و `[support].[TicketPriority]` و `[support].[TicketStatus]` و `[support].[TicketReply]` و `[support].[TicketAttachment]` و `[support].[TicketTask]` و `[support].[TeamMember]` و `[support].[TeamMemberRole]` تبقى حل تتبع أخطاء الموقع الداخلي لفريق التطوير.

هذا المخطط لا يدمج أو يعيد تسمية أو يوسع أو يعتمد على كائنات `[support]` تلك. نظام التذاكر ITIL 4 في هذا المستند هو حل أعمال مستقل يُنفذ فقط تحت `[Tickets]` ويُوجَّه فقط عبر بنية الـ gateway الحالية بنمط Housing.
