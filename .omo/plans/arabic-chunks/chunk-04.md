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
- `isOtherPlaceholder = 0` للخدمات الفعلية؛ واجهة المستخدم تتعامل مع "أخرى" كقيمة `serviceID_FK` فارغة

### 11.15 `[Tickets].[ServiceRoutingRule]`
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
- تصمية فريدة مُصفّاة مستهدفة: صف فعّال واحد فقط لكل مجموعة `(IdaraID_FK, serviceID_FK, requesterTypeID_FK)` ونافذة زمنية
- `TargetDSDID_FK` هو المرجع الحقيقي للتوجيه
- `ArbitratorDSDID_FK` إلزامي حتى يكون لحالات النطاق الخاطئ والخدمات الأخرى وجهة صالحة دائماً

### 11.16 `[Tickets].[ServiceSLAPolicy]`
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
- هدف السياسة الفعّالة الفريدة: `(IdaraID_FK, serviceID_FK, ticketPriorityID_FK)`

### 11.17 `[Tickets].[PriorityMatrix]`
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
- هذا هو المصدر الإلزامي لترتيب الأولويات وفق منهجية ITIL

### 11.18 `[Tickets].[ApprovalStep]`
```sql
approvalStepID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
operationalTypeID_FK INT NOT NULL FK -> [Tickets].[OperationalType].[operationalTypeID]
serviceID_FK BIGINT NULL FK -> [Tickets].[Service].[serviceID]
stepOrder INT NOT NULL
stepName_A NVARCHAR(200) NOT NULL
stepName_E NVARCHAR(200) NOT NULL
ApproverDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ApproverDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
isRequired BIT NOT NULL DEFAULT 1
approvalStepActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)`
- عندما يكون `serviceID_FK` فارغاً، تُطبَّق الخطوة على جميع الخدمات التابعة لذلك النوع التشغيلي
- `ApproverDSDID_FK` يُحدِّد الوحدة التنظيمية المطلوب موافقتها في هذه الخطوة
- `ApproverDistributorID_FK` يُضيِّق الاختيار اختيارياً إلى دور محدد داخل تلك الوحدة
- `isRequired = 0` يُميِّز الخطوات الاستشارية أو الاختيارية التي يمكن تخطيها أثناء تنفيذ سير العمل
- مجتمعةً، تُشكِّل الصفوف المرتّبة حسب `stepOrder` لمجموعة `(operationalTypeID_FK, serviceID_FK)` معينة قالب سلسلة الموافقات الكامل

### 11.19 `[Tickets].[Ticket]`
```sql
ticketID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketNo NVARCHAR(30) NOT NULL
ticketClassID_FK INT NOT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
operationalTypeID_FK INT NOT NULL FK -> [Tickets].[OperationalType].[operationalTypeID]
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
- قاعدة تحقق في الإجراء المخزن: يجب تعبئة حقل واحد بالضبط من `UsersID_FK` أو `residentInfoID_FK`
- قاعدة تحقق في الإجراء المخزن: يجب تعبئة `serviceID_FK` أو `otherServiceText`
- `RootTicketID_FK` يساوي نفس التذكرة للسجلات الجذرية بعد إتمام الإدراج
- `operationalTypeID_FK` مطلوب ويُحدِّد قالب سلسلة الموافقات الذي يتم تفعيله لهذه التذكرة

### 11.20 `[Tickets].[TicketArbitration]`
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
- صف تحكيم فعّال واحد فقط لكل تذكرة في الوقت الواحد
- منطق الإغلاق موجود في `[Tickets].[TicketSP]`

### 11.21 `[Tickets].[TicketClarification]`
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
- صف توضيح فعّال واحد فقط لكل تذكرة في الوقت الواحد
- يجب تعبئة حقل واحد على الأقل من `RequestedFromUsersID_FK` أو `RequestedFromDSDID_FK`

### 11.22 `[Tickets].[TicketPauseSession]`
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
- جلسة إيقاف فعّالة واحدة فقط لكل تذكرة في الوقت الواحد
- يتم حساب `pausedMinutes` النهائي عند انتهاء الجلسة

### 11.23 `[Tickets].[TicketSLA]`
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
- صف اتفاقية مستوى الخدمة (SLA) فعّال واحد لكل تذكرة
- قيم `slaState` يتحكم بها منطق الإجراء المخزن: `RUNNING`، `PAUSED`، `RESOLVED`، `CLOSED`، `BREACHED`

### 11.24 `[Tickets].[TicketQualityReview]`
```sql
ticketQualityReviewID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
qualityReviewResultID_FK INT NULL FK -> [Tickets].[QualityReviewResult].[qualityReviewResultID]
ReviewerUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
reviewNotes NVARCHAR(MAX) NULL
reviewStartedAt DATETIME NOT NULL
reviewCompletedAt DATETIME NULL