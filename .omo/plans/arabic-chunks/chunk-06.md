
## 13. خريطة العروض / تصاميم DL

### 13.1 `TicketCreate`
- فرع البوابة يستدعي `[Tickets].[TicketDL]`
- مجموعة النتائج 1: سياق مقدم الطلب وأي تحذيرات تتعلق بالتذاكر المفتوحة
- مجموعة النتائج 2: الخدمات
- مجموعة النتائج 3: فئات التذاكر
- مجموعة النتائج 4: التأثيرات
- مجموعة النتائج 5: درجات الاستعجال
- مجموعة النتائج 6: أنواع مقدمي الطلب
- **[v2]** مجموعة النتائج 7: الأنواع التشغيلية (لاختيار نوع تشغيلي)

### 13.2 `TicketMyTickets`
- مجموعة النتائج 1: قائمة تذاكر مقدم الطلب
- مجموعة النتائج 2: قائمة منسدلة لتصفية الحالة
- مجموعة النتائج 3: قائمة منسدلة لتصفية الأولوية

### 13.3 `TicketInbox`
- مجموعة النتائج 1: التذاكر المملوكة للطابور حسب `CurrentDSDID_FK`
- مجموعة النتائج 2: المكلفون المؤهلون من `[dbo].[V_getListUsersInDSD]`
- مجموعة النتائج 3: قائمة منسدلة لتصفية الحالة

### 13.4 `TicketList`
- مجموعة النتائج 1: قائمة الإدارة المحددة بالصلاحية والإدارة
- مجموعة النتائج 2: قائمة منسدلة لتصفية الحالة
- مجموعة النتائج 3: قائمة منسدلة لتصفية الفئة
- مجموعة النتائج 4: قائمة منسدلة لتصفية الأولوية
- مجموعة النتائج 5: قائمة منسدلة لتصفية الهيكل التنظيمي من `[dbo].[V_getFullStructureForDSD]`

### 13.5 `TicketWorkbench`
- مجموعة النتائج 1: عنوان تذكرة واحد
- مجموعة النتائج 2: الجدول الزمني للتاريخ
- مجموعة النتائج 3: صفوف التحكيم النشطة
- مجموعة النتائج 4: صفوف التوضيح النشطة
- مجموعة النتائج 5: التذاكر الفرعية
- مجموعة النتائج 6: صف اتفاقية مستوى الخدمة (SLA)
- مجموعة النتائج 7: عمليات البحث عن إجراءات المكلف/الـ DSD
- **[v2]** مجموعة النتائج 8: خطوات سلسلة الموافقات وحالتها الحالية (`PENDING`، `APPROVED`، `REJECTED`، `SKIPPED`). يعرض كل صف ترتيب الخطوة، وـ DSD للموافق، والمستخدم الموافق المحدد (إن وُجد)، وحالة الخطوة، والطوابع الزمنية لتنفيذ الخطوة.
- **[v2]** مجموعة النتائج 9: إجراءات الموافقة المعلقة المتاحة للمستخدم الحالي. تكون مجموعة النتائج هذه فارغة إذا لم يكن المستخدم يملك سلطة موافقة على هذه التذكرة. عند تعبئتها، تُشغّل أزرار القبول/الرفض في واجهة منصة العمل.

### 13.6 `TicketQualityReview`
- مجموعة النتائج 1: التذاكر المحلة التي تنتظر مراجعة الجودة
- مجموعة النتائج 2: جدول بحث نتائج المراجعة
- مجموعة النتائج 3: إحصائيات الأولوية/الحالة لبطاقات لوحة المراجع

### 13.7 `ServiceCatalog`
- فرع البوابة يستدعي `[Tickets].[ServiceCatalogDL]`
- مجموعة النتائج 1: الخدمات
- مجموعة النتائج 2: قواعد التوجيه
- مجموعة النتائج 3: سياسات اتفاقية مستوى الخدمة (SLA)
- مجموعة النتائج 4: فئات الخدمات
- مجموعة النتائج 5: عمليات البحث عن DSD
- مجموعة النتائج 6: اقتراحات الفهرس
- **[v2]** مجموعة النتائج 7: قوالب خطوات الموافقة، صف واحد لكل `[Tickets].[ApprovalStep]`، يعرض النوع التشغيلي، وترتيب الخطوة، وما إذا كانت الخطوة مطلوبة، وـ DSD/الدور الخاص بالموافق

### 13.8 `TicketReports`
- فرع البوابة يستدعي `[Tickets].[TicketReportDL]`
- مجموعات النتائج مخصصة للتقارير فقط ولا يجب إعادة استخدامها في صفحات CRUD

### 13.9 `TicketApprovals` **[v2]**
- فرع البوابة يستدعي `[Tickets].[TicketDL]`
- مجموعة النتائج 1: الموافقات المعلقة ضمن نطاق DSD للمستخدم الحالي. يعرض كل صف معرّف التذكرة، ورقم التذكرة، والعنوان، واسم مقدم الطلب، والنوع التشغيلي، وخطوة الموافقة المحددة التي يمكن للمستخدم تنفيذها، وتاريخ إنشاء الخطوة، ومعلومات العد التنازلي لاتفاقية مستوى الخدمة (SLA). تقتصر الصفوف على التذاكر حيث يتطابق DSD المستخدم مع `approverDSDID_FK` على خطوة `[Tickets].[TicketApproval]` المعلقة.
- مجموعة النتائج 2: سجل الموافقات. الموافقات المكتملة (سواء `APPROVED` أو `REJECTED`) التي نفّذها المستخدم الحالي، مع الطوابع الزمنية والملاحظات. تُستخدم للوحة "قراراتي الأخيرة" في صفحة الموافقات.
- مجموعة النتائج 3: قائمة منسدلة لتصفية الحالة. تسمح بتصفية قائمة المعلقات حسب حالة الموافقة (`PENDING`، `APPROVED`، `REJECTED`، `ALL`).

## 14. إضافات توجيه البوابة

### 14.1 `[dbo].[Masters_DataLoad]`
أضف فروع `@pageName_` التالية بأسلوب Housing الفعلي:

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

ELSE IF @pageName_ = 'TicketApprovals'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END
```

### 14.2 `[dbo].[Masters_CRUD]`
أضف فروع الصفحات التالية بأسلوب فحص الصلاحيات الفعلي المستخدم في `WaitingListByResident`:

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
