1. تُغلق جلسة `TicketPauseSession` المفتوحة. ويتم حساب `endedAt` و`pausedMinutes`.
2. يُزاد `totalPausedMinutes` في سجل `TicketSLA` بمدة الإيقاف.
3. تُعاد حساب تواريخ الاستجابة والحل المحددة بإضافة دقائق الإيقاف إلى المواعيد النهائية الأصلية.
4. يعود `slaState` إلى الحالة `RUNNING`.
5. يُسجّل صف `TicketSLAHistory` انتقال الاستئناف.

عند رفض تذكرة أثناء الموافقة:

1. تُغلق جلسة الإيقاف.
2. يُعلَّم سجل اتفاقية مستوى الخدمة بالحالة `slaState = 'CLOSED`' (لن تنتقل التذكرة إلى مرحلة التنفيذ).

هذا النهج يضمن أن الوقت المستغرق في انتظار موافقة الإدارة لا يُحتسب ضمن ساعة اتفاقية مستوى الخدمة الخاصة بمنفذ التذكرة.

## 16.6 من يمكنه الموافقة (الأهلية عبر V_GetListUsersInDSD)

الأهلية مبنية على الهيكل التنظيمي القائم فعلياً، وليس على جدول صلاحيات جديد.

يتحقق الإجراء المخزن من الأهلية بهذه الطريقة:

1. يجب أن يكون المُوافق مستخدماً نشطاً في `ApproverDSDID_FK`. يتحقق الإجراء المخزن من ذلك بالاستعلام عن `[dbo].[V_GetListUsersInDSD]` المُصفَّى حسب DSD.
2. إذا لم يكن `ApproverDistributorID_FK` فارغاً، فيجب أن يحمل المستخدم أيضاً دور الموزع المحدد في DSD. يتحقق الإجراء المخزن من ذلك بالربط عبر `[dbo].[UserDistributor]`.
3. لا يمكن أن يكون المُوافق هو نفس المستخدم الذي فتح التذكرة (`OpenedByUsersID_FK`). هذا يمنع الموافقة الذاتية.

نمط استعلام الأهلية:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM [dbo].[V_GetListUsersInDSD] v
    WHERE v.usersID = @actingUserID
      AND v.DSDID = @approverDSDID
      AND v.isActive = 1
      AND (@approverDistributorID IS NULL
           OR EXISTS (
               SELECT 1
               FROM [dbo].[UserDistributor] ud
               WHERE ud.usersID = @actingUserID
                 AND ud.distributorID = @approverDistributorID
           ))
      AND @actingUserID <> @openedByUserID
)
BEGIN
    THROW 50001, N'You are not authorized to approve this step.', 1;
END
```

هذا يعني أن النظام لا يُشفّر أسماء مستخدمين محددين داخل سلسلة الموافقات. بل يُحدّد المنصب التنظيمي، وأي شخص يشغل هذا المنصب حالياً يمكنه الموافقة.

## 16.7 أمثلة على البيانات الأساسية

يعرض الجدول التالي قوالب سلسلة الموافقات الافتراضية المُدمجة لكل نوع تشغيلي. هذه القوالب الأساسية. يمكن للمسؤولين إضافة خطوات أو إزالتها أو إعادة ترتيبها من خلال صفحة إدارة كتالوج الخدمات.

| Operational Type | Step 1 | Step 2 | Step 3 | Step 4 |
|---|---|---|---|---|
| SERVICE_REQUEST | المشرف (إلزامي) | مدير الفرع (إلزامي) | مدير الإدارة (إلزامي) | -- |
| DISBURSEMENT | المشرف (إلزامي) | مدير الفرع (إلزامي) | قسم المالية (إلزامي) | مدير الإدارة (إلزامي) |
| EXECUTION | مدير الفرع (إلزامي) | مدير الإدارة (إلزامي) | -- | -- |
| INSPECTION | مدير القسم (إلزامي) | -- | -- | -- |

في كل صف، يرتبط DSD الخاص بكل خطوة بوحدة التنظيمية المقابلة في `[dbo].[DeptSecDiv]`. أما الدور (المشرف، مدير الفرع، إلخ) فيرتبط بـ `DistributorID` محدد عندما ترغب المنظمة في موافقة قائمة على المنصب، أو يُترك فارغاً عندما يمكن لأي مستخدم نشط في ذلك DSD الموافقة.

نمط SQL للبيانات الأساسية:

```sql
INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'SERVICE_REQUEST', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 3, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'DISBURSEMENT', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 3, @financeDSDID, @financeDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 4, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'EXECUTION', NULL, 1, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'EXECUTION', NULL, 2, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'INSPECTION', NULL, 1, @sectionMgrDSDID, @sectionMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);
```

تُحل مُعرِّفات DSD وDistributor الفعلية وقت الإدراج من جداول `[dbo].[DeptSecDiv]` و`[dbo].[Distributor]` الحية للإدارة العامة (Idara) المستهدفة.

## 16.8 تجاوزات خاصة بالخدمة

بعض الخدمات تحتاج إلى سلسلة موافقات مختلفة عن الافتراضية لنوعها التشغيلي. يعالج عمود `serviceID_FK` في `[Tickets].[ApprovalStep]` هذا الأمر.

منطق الحل في `[Tickets].[TicketSP]` عند بناء سلسلة الموافقات لتذكرة جديدة:

1. أولاً، البحث عن صفوف `ApprovalStep` النشطة حيث يتطابق `serviceID_FK` مع `serviceID_FK` الخاص بالتذكرة ويتطابق `operationalTypeID_FK` مع النوع التشغيلي للتذكرة.
2. إذا وُجدت صفوف خاصة بالخدمة، تُستخدم كقالب لسلسلة الموافقات. ويتم تجاهل الصفوف العامة لذلك النوع التشغيلي.
3. إذا لم توجد صفوف خاصة بالخدمة، يُعود النظام إلى الصفوف العامة حيث `serviceID_FK IS NULL`.

هذا يعني:

- قد تتطلب سلسلة `SERVICE_REQUEST` العامة المشرف ثم مدير الفرع ثم مدير الإدارة.
- خدمة محددة مثل "نقل وحدة سكنية" يمكنها تجاوز ذلك بمدير الفرع ومدير الإسكان فقط، متخطية خطوة المشرف تماماً.
- التجاوز يكون لكل خدمة، وليس لكل تذكرة. بمجرد إعداده، كل تذكرة لتلك الخدمة تتبع سلسلة الموافقات المتجاوزة.

يدير المسؤولون التجاوزات من خلال صفحة `ServiceCatalog`. يتضمن مجموعة نتائج `ServiceCatalogDL` خطوات الموافقة الحالية لكل خدمة. ويتيح إجراء `UPDATEAPPROVALSTEP` في `ServiceCatalogSP` للمسؤولين إضافة خطوات أو إزالتها أو إعادة ترتيبها.

## 16.9 الموافقة التلقائية

إذا لم توجد صفوف `ApprovalStep` للنوع التشغيلي للتذكرة (ولم يوجد تجاوز خاص بالخدمة)، تتجاوز التذكرة تدفق الموافقة بالكامل.

في `[Tickets].[TicketSP]`، يتحقق إجراء `INSERTTICKET`:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM [Tickets].[ApprovalStep]
    WHERE IdaraID_FK = @idaraID_FK
      AND operationalTypeID_FK = @operationalTypeID_FK
      AND approvalStepActive = 1
      AND (serviceID_FK IS NULL OR serviceID_FK = @serviceID_FK)
)
BEGIN
    -- No approval chain defined. Bypass WAITING_APPROVAL.
    -- Set ticket status directly to ASSIGNED (or TRIAGED, depending on routing).
    -- Do not create any TicketApproval rows.
    -- Do not start an SLA pause session.
END
```

الموافقة التلقائية تعني:

- لا تُنشأ صفوف `TicketApproval`.
- لا تبدأ جلسة إيقاف اتفاقية مستوى الخدمة.
- تتبع التذكرة مسار الإنشاء والتوجيه العادي: من `NEW` إلى `ASSIGNED` بناءً على قاعدة التوجيه.
- لا تُكتب إدخالات سجل متعلقة بالموافقة.

هذا يحافظ على بساطة النظام للأنواع التشغيلية التي لا تحتاج إلى توقيع إداري. الحالة الافتراضية هي "لا حاجة لموافقة". الموافقة طبقة اختيارية يُعدّها المسؤولون.

## 16.10 إجراء مخزن جديد: APPROVETICKET

يتطلب تدفق الموافقة إجراءً جديداً واحداً في `[Tickets].[TicketSP]`.

**الإجراء:** `APPROVETICKET`

**المُعامِلات:**
- `@param1` = مُعرِّف التذكرة
- `@param2` = ترتيب الخطوة
- `@param3` = القرار (`APPROVED`, `REJECTED`, `SKIPPED`)
- `@param4` = ملاحظات الإجراء (اختياري)

**منطق الإجراء المخزن:**

1. التحقق من وجود التذكرة وأنها في حالة `WAITING_APPROVAL`.
2. تحميل صف `TicketApproval` لترتيب الخطوة المحدد.
3. التحقق من أن جميع خطوات الترتيب الأدنى تم حلها بالفعل (ليست `PENDING`).
4. إذا كان `decision = 'SKIPPED'`، التحقق من أن `isRequired = 0` في تلك الخطوة. الخطوات الإلزامية لا يمكن تخطيها.
5. التحقق من أهلية المستخدم المُنفِّذ عبر `V_GetListUsersInDSD` (القسم 16.6).
6. تحديث صف `TicketApproval`.
7. كتابة إدخالات `TicketHistory` و`AuditLog`.
8. إذا كان `decision = 'REJECTED`' و`isRequired = 1`، رفض التذكرة (القسم 16.4).
9. إذا كانت جميع الخطوات الإلزامية موافق عليها الآن، نقل التذكرة إلى حالة `ASSIGNED`، وإنهاء إيقاف اتفاقية مستوى الخدمة، وإعادة حساب المواعيد النهائية.
10. إرجاع `SELECT 1 AS IsSuccessful, N'...' AS Message_`.

يُوجَّه هذا الإجراء عبر `[dbo].[Masters_CRUD]` تحت اسم صفحة `TicketWorkbench`، ويُتحقق من الصلاحيات بنفس طريقة جميع إجراءات التذاكر الأخرى.

## 16.11 إضافة بيانات أساسية لـ TicketStatus

صف حالة واحد جديد مطلوب:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'WAITING_APPROVAL', N'في انتظار الموافقة', 'Waiting for Approval',
     2, 0, 1, 1);
```

لاحظ أن `isPauseStatus = 1` حتى يتعرف نظام اتفاقية مستوى الخدمة على هذه الحالة كحالة إيقاف. وترتيب الفرز `sortOrder` بقيمة 2 يضعها بين `NEW` (1) و`TRIAGED` (3) في تسلسل دورة الحياة.

صف ثانٍ لحالة الرفض النهائية:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'REJECTED', N'مرفوض', 'Rejected',
     12, 1, 0, 1);
```

`isClosedStatus = 1` لأن التذكرة المرفوضة هي حالة نهائية. لا يمكنها مغادرة هذه الحالة إلا عبر إجراء `REOPENTICKET`.

## 16.12 الأثر على تسلسل المواصفات

سلسلة الموافقات تمس مواصفتين قائمتين وتضيف قدراً قليلاً من العمل:

| Spec | Addition |
|---|---|
| Spec 01 | إدراج `WAITING_APPROVAL` و`REJECTED` في `[Tickets].[TicketStatus]`. إدراج `WAITING_APPROVAL` في `[Tickets].[PauseReason]` (مُدرج بالفعل). |
| Spec 04 | إنشاء `[Tickets].[ApprovalStep]` و`[Tickets].[TicketApproval]` إلى جانب جداول المعاملات الأخرى. |
| Spec 05 | إضافة إجراء `APPROVETICKET` إلى `[Tickets].[TicketSP]`. تعديل `INSERTTICKET` للتحقق من سلاسل الموافقات. |
| Spec 11 | إضافة مجموعات نتائج `WAITING_APPROVAL` إلى `TicketWorkbench` DL حتى يتمكن واجهة المستخدم من عرض خطوات الموافقة المعلقة. |

لا حاجة لمواصفة جديدة. سلسلة الموافقات تتلاءم مع تسلسل المواصفات القائم.


> هذه أقسام جديدة أُضيفت في الإصدار v2. يغطي القسم 17 تصميم التحكيم الهرمي. ويُعرّف القسم 18 أربعة أنواع تشغيلية من التذاكر مع سلاسل موافقات وقواعد توجيه وتوقعات اتفاقية مستوى الخدمة وقواعد العمل.

## 17. تصميم التحكيم الهرمي

يتولى التحكيم سيناريوهين: نزاعات المسؤولية بين الوحدات التنظيمية، وتوجيه الخدمات غير المعروفة حيث لا تتطابق أي قاعدة من كتالوج الخدمات. يسير نظام التحكيم صعوداً في تسلسل `DeptSecDiv` للعثور على صانع القرار المناسب في المستوى المناسب.

### 17.1 تصعيد النزاعات عبر المستويات التنظيمية

تتبع المنظمة هيكلاً من أربعة مستويات عبر `[dbo].[DeptSecDiv]`: قسم/شعبة ← فرع ← إدارة ← إدارة عامة (Idara). عندما تختلف وحدتان حول من يملك التذكرة، يعثر النظام على أقرب سلف مشترك بينهما ويُعيّن محكِّماً على ذلك المستوى.

| مستوى النزاع | مثال | مستوى المحكِّم |
|---|---|---|
| قسمان داخل نفس الفرع | القسم أ والقسم ب كلاهما يدّعي "ليس لنا" | محكِّم على مستوى الفرع |
| فرعان داخل نفس الإدارة | الفرع س والفرع ص يتنازعان على التوجيه | محكِّم على مستوى الإدارة |
| إدارتان داخل نفس الإدارة العامة | الإدارة م والإدارة ن تختلفان | محكِّم على مستوى الإدارة العامة |
| وحدة واحدة، خدمة غير معروفة | وحدة واحدة تتلقى تذكرة لخدمة غير مُدرجة | محكِّم على مستوى الوحدة الأصل |

يستخدم انتقال التسلسل الهرمي `[dbo].[V_GetFullStructureForDSD]` للسير من أي `DSDID` صعوداً عبر سلسلة الآباء. خوارزمية أقرب سلف مشترك تعمل بجمع المسار الكامل للأسلاف لكلا DSD المتنازعين، ثم إيجاد أول عقدة مشتركة بدءاً من الأسفل.

### 17.2 هوية المحكِّم

المحكِّم هو صف في `[dbo].[Distributor]` مع `distributorType_FK = 5`. هذه قيمة جديدة أُدخلت لنظام التذاكر.
