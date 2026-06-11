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

ELSE IF @pageName_ = 'TicketApprovals'
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
```

قيم الصفحات المطلوب إضافتها بالضبط:

- `TicketCreate`
- `TicketMyTickets`
- `TicketInbox`
- `TicketList`
- `TicketWorkbench`
- `TicketQualityReview`
- `ServiceCatalog`
- `TicketReports`
- **[v2]** `TicketApprovals`

## 15. مصفوفة القواعد التجارية

| المعرف | القاعدة | موقع التنفيذ |
|---|---|---|
| BR-01 | يجب وجود مصدر طلب واحد فقط: `UsersID_FK` أو `residentInfoID_FK` (لا كلاهما) | `[Tickets].[TicketSP]` |
| BR-02 | الخدمة المعروفة تتطلب `serviceID_FK`؛ الخدمة غير المعروفة تتطلب `otherServiceText` | `[Tickets].[TicketSP]` |
| BR-03 | إنشاء التذكرة يجب أن يحسب الأولوية من `impactID_FK` ضرب `urgencyID_FK` عبر `[Tickets].[PriorityMatrix` | `[Tickets].[TicketSP]` |
| BR-04 | إنشاء التذكرة يجب أن يحمل اتفاقية مستوى الخدمة (SLA) من `[Tickets].[ServiceSLAPolicy]` عند وجود `serviceID_FK` | `[Tickets].[TicketSP]` |
| BR-05 | يجب تعبئة `CurrentDSDID_FK` دائماً في جدول `[Tickets].[Ticket` | `[Tickets].[TicketSP]` |
| BR-06 | التعيين إلى `AssignedToUsersID_FK` صالح فقط إذا كان المستخدم نشطاً ومؤهلاً في `[dbo].[V_GetListUsersInDSD]` للوحدة التنظيمية الحالية | `[Tickets].[TicketSP]` |
| BR-07 | لا يمكن أن يكون التحكيم والتوضيح نشطين معاً لنفس التذكرة في الوقت نفسه | `[Tickets].[TicketSP]` |
| BR-08 | لا يوجد سوى جلسة إيقاف واحدة نشطة لكل تذكرة | `[Tickets].[TicketSP]` مع فحص استعلام الجدول |
| BR-09 | يجب تعيين الروابط الأصلية والجذرية بشكل ذري عند إنشاء تذكرة فرعية | `[Tickets].[TicketSP]` |
| BR-10 | لا يمكن أن تنتقل التذكرة إلى `CLOSED` قبل نجاح مراجعة الجودة ما لم يُمنح إجراء تجاوز محدد | `[Tickets].[TicketSP]` وإعدادات الصلاحيات |
| BR-11 | `resolutionTypeID_FK` و `resolutionNotes` مطلوبان لإجراء `RESOLVETICKET` | `[Tickets].[TicketSP]` |
| BR-12 | `isMajorIncident = 1` يتطلب توجيهاً حرجاً وإظهاراً للمراجعين | `[Tickets].[TicketSP]` و `TicketReportDL` |
| BR-13 | كل عملية كتابة تُدرج سجلاً في السجل المحلي وفي `[dbo].[AuditLog]` المركزي | `[Tickets].[TicketSP]` و `[Tickets].[ServiceCatalogSP]` |
| BR-14 | تغييرات قواعد التوجيه يجب أن تكتب في `[Tickets].[ServiceRoutingRuleHistory]` | `[Tickets].[ServiceCatalogSP]` |
| BR-15 | جداول السجلات التاريخية للقراءة فقط (إلحاق فقط) | تصميم الإجراء المخزن بدون مسارات حذف أو تحديث |
| BR-16 | كل قراءة صفحة يجب أن تعيد مجموعة نتائج الصلاحيات أولاً عبر `[dbo].[ft_UserPagePermissions]` | `[dbo].[Masters_DataLoad]` |
| BR-17 | كل صفحة CRUD يجب أن تفحص صلاحية الصفحة عبر `[dbo].[V_GetListUserPermission]` قبل استدعاء الإجراء المخزن الفرعي | `[dbo].[Masters_CRUD]` |
| BR-18 | صندوق الوارد (`TicketInbox`) ومقعد العمل (`TicketWorkbench`) يجب أن يحدا التذاكر المرئية حسب صلاحية الصفحة والواقع التنظيمي الحالي | تصميم استعلام التحميل |
| BR-19 **[v2]** | `operationalTypeID_FK` مطلوب في كل تذكرة. إجراء `INSERTTICKET` يجب أن يرفض أي تذكرة لا تحدد نوع تشغيلي. | `[Tickets].[TicketSP]` |
| BR-20 **[v2]** | إذا وُجدت صفوف في `[Tickets].[ApprovalStep]` خاصة بالنوع التشغيلي للتذكرة، يجب على النظام إنشاء صفوف `[Tickets].[TicketApproval]` من القالب قبل أن تغادر التذكرة حالة `WAITING_APPROVAL`. إجراء `INSERTTICKET` يفحص خطوات القالب عند الإنشاء. إذا وُجدت خطوات، تبدأ التذكرة في حالة `WAITING_APPROVAL` مع جميع خطوات القالب محولة إلى صفوف موافقة معلقة وجلسة إيقاف اتفاقية مستوى الخدمة (SLA) نشطة. إذا لم توجد خطوات لهذا النوع التشغيلي، تسلك التذكرة مسار الحالات المعتاد بدون بوابة الموافقة. | `[Tickets].[TicketSP]` |
| BR-21 **[v2]** | جميع خطوات الموافقة الإلزامية (حيث `isRequired = 1` في `[Tickets].[ApprovalStep]`) يجب أن تصل إلى حالة `APPROVED` قبل أن تدخل التذكرة حالة `ASSIGNED` أو `IN_PROGRESS`. الخطوات الاختيارية (حيث `isRequired = 0`) يمكن تخطيها دون إيقاف التقدم. إجراء `APPROVETICKET` يفحص هذا الشرط بعد كل موافقة ولا يُقدم التذكرة إلا بعد تخليص جميع الخطوات الإلزامية. | `[Tickets].[TicketSP]` |
| BR-22 **[v2]** | إجراء `REJECTAPPROVAL` على أي خطوة إلزامية ينقل التذكرة إلى حالة `REJECTED` ويُعلم مقدم الطلب بملاحظات المرفق. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA). يمكن إعادة فتح التذكرة المرفوضة عبر `REOPENTICKET`، الذي يُعيدها إلى سلسلة الموافقات من البداية. | `[Tickets].[TicketSP]` |
| BR-23 **[v2]** | التذاكر الفرعية المتوازية: عندما تمتلك تذكرة أصل تذاكر فرعية مفتوحة، تكون حالة الأصل `WAITING_CHILD`. لا يمكن للأصل استئناف المعالجة المعتادة حتى تصل جميع التذاكر الفرعية إلى حالة نهائية (`RESOLVED` أو `CLOSED` أو `CANCELLED`). عندما تصل آخر تذكرة فرعية إلى حالة نهائية، تنتهي جلسة `PAUSETICKET` للأصل، وتُلغى إيقاف اتفاقية مستوى الخدمة (SLA)، وتعود حالة الأصل إلى حالتها ما قبل الانتظار. يجب أن يكون المشغل الذي يكتمل إكمال آخر تذكرة فرعية ذرياً لتجنب حالات السباق مع إكمال التذاكر الفرعية المتزامنة. | `[Tickets].[TicketSP]` |
| BR-24 **[v2]** | التوضيح بين الفنيين: عندما يطلب فني توضيحاً من وحدة تنظيمية أخرى، يجب أن يكون `RequestedFromDSDID_FK` مختلفاً عن الوحدة التنظيمية الحالية للتذكرة (`CurrentDSDID_FK`). طلب التوضيح الموجه لنفس الوحدة التنظيمية التي تملك التذكرة حالياً يُرفض كتوضيح ذاتي. | `[Tickets].[TicketSP]` |
| BR-25 **[v2]** | التحكيم الهرمي: عندما يكون التحكيم مطلوباً بسبب نزاع وحدتين تنظيميتين على المسؤولية، يتحدد مستوى التحكيم بإيجاد أقل أب مشترك `DSDID` للوحدتين المتنازعتين. يجب أن تكون الوحدة التنظيمية للمحكّم عند مستوى الأب المشترك أو أعلى منه. إذا لم تشارك الوحدتان المتنازعتان أبّاً مشتركاً ضمن نطاق `IdaraID`، يتحول التحكيم إلى الوحدة التنظيمية على مستوى الإدارة. | `[Tickets].[TicketSP]` |


يحدد هذا القسم نظام سلسلة الموافقات الفرعي لنظام التذاكر وفق معيار ITIL 4. ليست كل تذكرة تحتاج موافقة. عندما تكون الموافقة مطلوبة، يستخدم النظام نموذج قالب/نسخة بجدولين لفرض التوقيع المتتابع قبل بدء العمل.

## 16.1 آلية عمل سلاسل الموافقات

تستخدم سلسلة الموافقات نمط القالب إلى النسخة. جدولان يحركان الآلية بالكامل.

**`[Tickets].[ApprovalStep]`** يعرّف قوالب سلسلة الموافقات. كل صف يصف خطوة موافقة واحدة في السلسلة، مرتبطة بنوع تشغيلي واختيارياً بخدمة محددة. هذه الصفوف يُعدّها المسؤولون ونادراً ما تتغير يوماً بعد يوم. فكر فيها كالمخطط الأساسي.

**`[Tickets].[TicketApproval]`** يتتبع نسخ الموافقة الفعلية. عندما تدخل تذكرة مسار الموافقات، يقرأ النظام صفوف القالب ذات الصلة من `ApprovalStep` وأنشئ صف `TicketApproval` واحداً لكل خطوة. تحمل هذه النسخ القرار الفعلي، والموافق الذي تصرف، والطوابع الزمنية، والتعليقات.

هذا الفصل يعني أنك تستطيع تغيير القالب للتذاكر المستقبلية دون التأثير على التذاكر الجارية حالياً.

### ApprovalStep DDL

```sql
CREATE TABLE [Tickets].[ApprovalStep]
(
    approvalStepID        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY
  , IdaraID_FK            BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[Idara].[idaraID]
  , operationalTypeID_FK  INT NOT NULL FOREIGN KEY REFERENCES [Tickets].[OperationalType].[operationalTypeID]
  , serviceID_FK          BIGINT NULL FOREIGN KEY REFERENCES [Tickets].[Service].[serviceID]
  , stepOrder             INT NOT NULL
  , stepName_A            NVARCHAR(200) NOT NULL
  , stepName_E            NVARCHAR(200) NOT NULL
  , ApproverDSDID_FK      BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[DeptSecDiv].[DSDID]
  , ApproverDistributorID_FK BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Distributor].[distributorID]
  , isRequired            BIT NOT NULL DEFAULT 1
  , approvalStepActive    BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

الأعمدة الرئيسية:

- `operationalTypeID_FK` يربط الخطوة بنوع تشغيلي عبر مفتاح أجنبي إلى `[Tickets].[OperationalType]`.
- `serviceID_FK` يقبل القيم الفارغة. عندما يكون فارغاً، تنطبق الخطوة على جميع الخدمات تحت هذا النوع التشغيلي. عند تعيينه، تتجاوز الخطوة سلسلة الموافقات العامة لهذه الخدمة المحددة.
- `stepOrder` عدد صحيح يبدأ من 1. يجب الفصل في الخطوة 1 قبل أن يمكن التصرف على الخطوة 2.
- `ApproverDSDID_FK` يحدد الوحدة التنظيمية التي يتبع لها الموافق.
- `ApproverDistributorID_FK` يحدد دوراً محدداً داخل تلك الوحدة. عندما يكون فارغاً، يمكن لأي مستخدم نشط في الوحدة التنظيمية الموافقة.
- `isRequired` يحدد ما إذا كان يمكن تخطي الخطوة. القيمة 1 تعني إلزامية. القيمة 0 تعني أن مستخدماً مخولاً يستطيع تخطيها.

قيد التفرد: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)` مصفّى إلى الصفوف النشطة فقط.

### TicketApproval DDL

```sql
CREATE TABLE [Tickets].[TicketApproval]
(
    ticketApprovalID      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY
  , IdaraID_FK            BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[Idara].[idaraID]
  , TicketID_FK           BIGINT NOT NULL FOREIGN KEY REFERENCES [Tickets].[Ticket].[ticketID]
  , approvalStepID_FK     BIGINT NOT NULL FOREIGN KEY REFERENCES [Tickets].[ApprovalStep].[approvalStepID]
  , stepOrder             INT NOT NULL
  , ApproverDSDID_FK      BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[DeptSecDiv].[DSDID]
  , ApproverDistributorID_FK BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Distributor].[distributorID]
  , isRequired            BIT NOT NULL DEFAULT 1
  , approvalStatus        NVARCHAR(50) NOT NULL
  , ApproverUsersID_FK    BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Users].[usersID]
  , approvalNotes         NVARCHAR(MAX) NULL
  , requestedAt           DATETIME NOT NULL
  , decidedAt             DATETIME NULL
  , ticketApprovalActive  BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

الأعمدة الرئيسية:

- `approvalStatus` يتتبع القرار: `PENDING` أو `APPROVED` أو `REJECTED` أو `SKIPPED`.
- `ApproverUsersID_FK` يسجل من اتخذ القرار.
- `decidedAt` يسجل متى اتُخذ القرار.
- `approvalNotes` يحمل تعليقات اختيارية من الموافق.

قيد التفرد: صف واحد فقط لكل `(TicketID_FK, stepOrder)`.

## 16.2 ترتيب الخطوات ومنطق الإلزام والاختيارية

تُنفذ الخطوات بتسلسل `stepOrder`. يفرض النظام ذلك على مستوى الإجراء المخزن.

عندما تدخل تذكرة مسار الموافقات، يقوم `[Tickets].[TicketSP]` بما يلي:

1. يقرأ جميع صفوف `ApprovalStep` النشطة المطابقة لـ `operationalTypeID_FK` و `IdaraID_FK` الخاصة بالتذكرة، مع اعتبار التجاوزات الخاصة بالخدمة أولاً (انظر القسم 16.8).
2. ينشئ صف `TicketApproval` واحداً لكل خطوة قالب، جميعها بحالة `approvalStatus = 'PENDING'`.
3. فقط الخطوة الأولى (`stepOrder = 1`) يمكن التصرف عليها فوراً. الخطوات ذات `stepOrder > 1` تبقى بحالة `PENDING` لكن لا يمكن التصرف عليها حتى تُحل الخطوة السابقة.

تُعتبر الخطوة محسومة عندما تكون حالتها `approvalStatus` إما `APPROVED` أو `REJECTED` أو `SKIPPED`.

يعمل التمييز بين الإلزامي والاختياري كالتالي:

- **إلزامية** (`isRequired = 1`): يجب أن تتلقى الخطوة قرار `APPROVED` أو `REJECTED` صريحاً. لا يمكن تخطيها.
- **اختيارية** (`isRequired = 0`): يمكن تخطيها من قبل مستخدم مخول. عند التخطي، يعاملها النظام كمحسومة لأغراض الترتيب وينتقل إلى الخطوة التالية.

إذا كانت الخطوة 2 اختيارية والخطوة 3 إلزامية، تبقى الخطوة 3 محجوبة حتى تُحل الخطوة 2 بالموافقة أو الرفض أو التخطي.

## 16.3 مسار الموافقة (انتقالات الحالات)

يُدرج مسار الموافقات حالة مخصصة ضمن دورة حياة التذكرة الحالية.

تسلسل الحالات:

```
NEW  -->  WAITING_APPROVAL  -->  ASSIGNED  -->  IN_PROGRESS  -->  ...
```

عندما يعالج `[Tickets].[TicketSP]` إجراء `INSERTTICKET` ويجد خطوات موافقة مطابقة:

1. تُنشأ التذكرة بحيث يشير `ticketStatusID_FK` إلى `WAITING_APPROVAL` بدلاً من `NEW` أو `ASSIGNED`.
2. تُنشأ صفوف نسخ `TicketApproval` لكل خطوة قالب.
3. تبدأ جلسة إيقاف اتفاقية مستوى الخدمة (SLA) مع إشارة `pauseReasonID_FK` إلى سبب الإيقاف `WAITING_APPROVAL` (المزروع في القسم 11.8).

عندما يتصرف موافق على خطوة (عبر إجراء `APPROVETICKET` الجديد في `TicketSP`):

1. يتحقق الإجراء المخزن من أن الخطوة الحالية هي أقل خطوة غير محلومة.
2. يتحقق من أن المستخدم المتصرف مؤهل (انظر القسم 16.6).
3. يحدّث صف `TicketApproval`: يضبط `approvalStatus` و `ApproverUsersID_FK` و `decidedAt` و `approvalNotes`.
4. يكتب صف `TicketHistory` يسجل قرار الموافقة.
5. يفحص ما إذا كانت جميع الخطوات الإلزامية قد وُفق عليها. إذا نعم، تنتقل التذكرة إلى `ASSIGNED`، وتنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA)، وتدخل التذكرة في التوجيه المعتاد.
6. إذا بقيت خطوات أخرى، تبقى التذكرة في `WAITING_APPROVAL` وتصبح الخطوة التالية قابلة للتصرف.

هذا المنطق يعني أن التذكرة لا تصل إلى `ASSIGNED` حتى تُوافق على كل خطوة إلزامية في السلسلة.

## 16.4 مسار الرفض

أي خطوة إلزامية تستطيع رفض التذكرة.

عندما يضبط موافق `approvalStatus = 'REJECTED'` على خطوة إلزامية:

1. ينتقل الإجراء المخزن فوراً بالتذكرة إلى حالة الرفض. تصبح حالة التذكرة `REJECTED` (صف جديد مزروع في `[Tickets].[TicketStatus]`).
2. جميع الخطوات `PENDING` المتبقية تُضبط إلى `SKIPPED` تلقائياً. لا حاجة لأي إجراءات موافقة إضافية.
3. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA).
4. يسجل صف `TicketHistory` الرفض، متضمناً أي خطوة رفضت ولماذا.
5. يُرسل إشعار إلى مقدم الطلب.

تعود التذكرة المرفوضة إلى مقدم الطلب. يستطيع مقدم الطلب حينها:

- التعديل وإعادة الإرسال، مما ينشئ تذكرة جديدة (أو يعيد فتح نفس التذكرة إذا فضّل العمل ذلك، يتحكم فيه منطق الإجراء المخزن وإجراء على غرار `REOPENTICKET` يعيد تقييم سلسلة الموافقات).
- إلغاء التذكرة.

الرفض لا يمنع مقدم الطلب بشكل دائم. إنما يعيد الطلب إليه للتصحيح.

تتصرف الخطوات الاختيارية بشكل مختلف. إذا رُفضت خطوة اختيارية، يعاملها النظام كمحسومة (مثل التخطي) وينتقل إلى الخطوة التالية. فقط رفض الخطوات الإلزامية يشغّل مسار الرفض الكامل الموضح أعلاه.

## 16.5 التفاعل مع اتفاقية مستوى الخدمة (SLA)

يتوقف وقت اتفاقية مستوى الخدمة (SLA) خلال نافذة الموافقة. هذا أمر حاسم لتتبع عادل لاتفاقية مستوى الخدمة.

عندما تدخل التذكرة حالة `WAITING_APPROVAL`:

1. ينشئ `[Tickets].[TicketSP]` صف `TicketPauseSession` مع إشارة `pauseReasonID_FK` إلى سبب إيقاف `WAITING_APPROVAL` (المزروع في القسم 11.8).
2. ينتقل `[Tickets].[TicketSLA]` إلى `slaState = 'PAUSED'`.
3. يسجل صف `TicketSLAHistory` انتقال الإيقاف.

عندما تكتمل سلسلة الموافقات (جميع الخطوات الإلزامية وُفق عليها، تنتقل التذكرة إلى `ASSIGNED`):
