ticketQualityReviewActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف مراجعة جودة نشط واحد فقط لكل تذكرة
- تبدأ المراجعة عندما تدخل التذكرة حالة `QUALITY_REVIEW`

### 11.25 `[Tickets].[ServiceCatalogSuggestion]`
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
- يمكن للتذكرة إنشاء صفر أو اقتراح نشط واحد
- يتحكم الإجراء المخزن في قيم `reviewDecision` مثل `PENDING`، و`ACCEPTED`، و`REJECTED`، و`MERGED`

### 11.26 `[Tickets].[TicketApproval]`
```sql
ticketApprovalID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
approvalStepID_FK BIGINT NOT NULL FK -> [Tickets].[ApprovalStep].[approvalStepID]
stepOrder INT NOT NULL
ApproverUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
approvalStatus NVARCHAR(50) NOT NULL
approvalNotes NVARCHAR(MAX) NULL
requestedAt DATETIME NOT NULL
decidedAt DATETIME NULL
ticketApprovalActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف واحد لكل خطوة موافقة لكل تذكرة
- القيم المحددة لـ `approvalStatus`: `PENDING`، و`APPROVED`، و`REJECTED`، و`SKIPPED`
- يُملأ `ApproverUsersID_FK` عندما يتصرّف مستخدم محدد من وحدة `ApproverDSDID_FK` على الخطوة
- حالة `SKIPPED` صالحة فقط للخطوات التي يكون فيها `[Tickets].[ApprovalStep].isRequired = 0` المقابل
- تُنشأ سلسلة الموافقات من `[Tickets].[ApprovalStep]` عند إنشاء التذكرة، مع مطابقة `operationalTypeID_FK` الخاصة بالتذكرة، واختيارياً `serviceID_FK`
- يجب أن تصل جميع الخطوات إلى حالة `APPROVED` أو `SKIPPED` قبل أن تتمكن التذكرة من تجاوز مرحلة الموافقة

### 11.27 `[Tickets].[TicketHistory]`
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
- إلحاقي فقط (لا تعديل ولا حذف)
- يُستخدم لعرض الخط الزمني على `TicketWorkbench`

### 11.28 `[Tickets].[TicketSLAHistory]`
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
- إلحاقي فقط (لا تعديل ولا حذف)

### 11.29 `[Tickets].[ServiceRoutingRuleHistory]`
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
- إلحاقي فقط (لا تعديل ولا حذف)
- سجل تدقيق محلي لتغييرات التوجيه


> تحل هذه الأقسام محل الأقسام 12-15 من الخطة الأساسية. العناصر الجديدة والمُعدّلة مُعلّمة بـ **[v2]**.

## 12. خريطة الإجراءات المخزنة

### 12.1 `[Tickets].[TicketDL]`

الغرض:
- تحميل بيانات الصفحات `TicketCreate`، و`TicketMyTickets`، و`TicketInbox`، و`TicketList`، و`TicketWorkbench`، و`TicketQualityReview`، و**[v2]** `TicketApprovals`

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

قواعد مجموعات النتائج:
- مجموعة النتائج 0 تأتي من `[dbo].[Masters_DataLoad]` عبر `[dbo].[ft_UserPagePermissions]`
- مجموعة النتائج 1 هي دائماً بيانات الصفحة الرئيسية
- مجموعة النتائج 2 فما فوق هي مجموعات بيانات البحث لنماذج وفلاتر `SmartRenderer`

**[v2]** عندما يكون `@pageName_ = 'TicketWorkbench'`، تُرجع مجموعات نتائج إضافية حالة سلسلة الموافقات للتذكرة المعروضة. راجع القسم 13.5 لخريطة مجموعات النتائج الكاملة.

### 12.2 `[Tickets].[TicketSP]`

الغرض:
- جميع عمليات الكتابة لدورة حياة التذكرة بما في ذلك **[v2]** إجراءات سير عمل الموافقة

مجموعات الإجراءات:
- `INSERTTICKET` **[v2]** مُحدّث: يتحقق من صحة `operationalTypeID_FK`، ويحمّل سلسلة الموافقات من `[Tickets].[ApprovalStep]` إذا كان النوع التشغيلي يتطلب موافقة، وينشئ صفوف `[Tickets].[TicketApproval]`، ويضبط الحالة الأولية على `WAITING_APPROVAL` عند الحاجة إلى موافقة
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
- **[v2]** `REQUESTAPPROVAL`: ينشئ صفوف `[Tickets].[TicketApproval]` من قالب `[Tickets].[ApprovalStep]` الخاص بالنوع التشغيلي للتذكرة. تحصل كل خطوة على صف بحالة `PENDING`. تنتقل حالة التذكرة إلى `WAITING_APPROVAL` وتبدأ جلسة إيقاف اتفاقية مستوى الخدمة (SLA) مؤقتاً.
- **[v2]** `APPROVETICKET`: يوافق المعتمد على خطوة واحدة من `[Tickets].[TicketApproval]`. تنتقل حالة الخطوة إلى `APPROVED`. إذا اكتملت جميع الخطوات الإلزامية، تنتقل التذكرة إلى `ASSIGNED` وتنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA). إذا بقيت خطوات أخرى، تصبح الخطوة `PENDING` التالية قابلة للتنفيذ وتبقى التذكرة في حالة `WAITING_APPROVAL`.
- **[v2]** `REJECTAPPROVAL`: يرفض المعتمد خطوة واحدة من `[Tickets].[TicketApproval]`. تنتقل حالة الخطوة إلى `REJECTED`. تنتقل حالة التذكرة إلى `REJECTED`. يُرسل إشعار إلى مقدم الطلب مع ملاحظات الرفض. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA).
- **[v2]** `UPDATEAPPROVALSTEP`: يُحدّث المسؤول قالب سلسلة الموافقات في `[Tickets].[ApprovalStep]`. التغييرات تؤثر على التذاكر الجديدة فقط ولا تُعدّل بأثر رجعي صفوف `[Tickets].[TicketApproval]` الموجودة.

المسؤوليات المشتركة:
- التحقق من هوية مقدم الطلب
- التحقق من صحة مسار الخدمة أو الخدمة الأخرى
- حساب الأولوية من `[Tickets].[PriorityMatrix]`
- تحميل اتفاقية مستوى الخدمة (SLA) من `[Tickets].[ServiceSLAPolicy]`
- التحقق من أهلية الوحدة/المستخدم من `[dbo].[V_getListUsersInDSD]`
- كتابة `[Tickets].[TicketHistory]`، و`[Tickets].[TicketSLAHistory]`، و`[dbo].[AuditLog]`
- تسجيل الأخطاء غير المتوقعة في `[dbo].[ErrorLog]`
- استدعاء `[dbo].[Notifications_Create]` اختيارياً

### 12.3 `[Tickets].[ServiceCatalogDL]`

الغرض:
- قراءة بيانات صفحة صيانة دليل الخدمات لصفحة `ServiceCatalog`

مجموعات النتائج الرئيسية:
- شبكة الخدمات
- شبكة قواعد التوجيه
- شبكة سياسات اتفاقية مستوى الخدمة (SLA)
- عمليات البحث عن الفئة/الحالة/الأولوية/الوحدة
- طابور مراجعة الاقتراحات
- **[v2]** شبكة قالب خطوات الموافقة

### 12.4 `[Tickets].[ServiceCatalogSP]`

الغرض:
- عمليات الكتابة للدليل، والتوجيه، واتفاقية مستوى الخدمة (SLA)، والاقتراحات، و**[v2]** قالب خطوات الموافقة

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
- **[v2]** `INSERTAPPROVALSTEP`: ينشئ صفاً جديداً في قالب سلسلة الموافقات في `[Tickets].[ApprovalStep]` لنوع تشغيلي محدد. يضبط `stepOrder` و`isRequired` و`approverDSDID_FK` و`approverRole`.
- **[v2]** `UPDATEAPPROVALSTEP`: يُعدّل صفاً موجوداً في `[Tickets].[ApprovalStep]`. التغييرات تسري على التذاكر الجديدة فقط.
- **[v2]** `DELETEAPPROVALSTEP`: حذف مُنعطف (soft delete) لصف في `[Tickets].[ApprovalStep]`. صفوف `[Tickets].[TicketApproval]` الموجودة التي تشير إلى هذه الخطوة لا تتأثر.

### 12.5 `[Tickets].[TicketReportDL]`

الغرض:
- مجموعات بيانات التقارير لصفحة `TicketReports`

مجموعات النتائج الرئيسية:
- ملخص مؤشرات الأداء
- التراكم حسب الحالة
- التراكم حسب الوحدة
- ملخص تجاوزات اتفاقية مستوى الخدمة (SLA)
- ملخص الحوادث الكبرى
- تقادم طلبات التوضيح
- تقادم طلبات التحكيم
- حجم اقتراحات الدليل
- **[v2]** ملخص اختناقات الموافقة: متوسط الوقت في حالة `WAITING_APPROVAL`، ومعدلات رفض الموافقة، ومعدلات إكمال سلسلة الموافقات حسب النوع التشغيلي
