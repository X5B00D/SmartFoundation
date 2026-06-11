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
- فريد: `(IdaraID_FK, requesterTypeCode)`
- صفوف أولية: `INTERNAL_USER`, `RESIDENT`

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
- فريد: `(IdaraID_FK, ticketClassCode)`
- صفوف أولية: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`

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
- فريد: `(IdaraID_FK, ticketStatusCode)`
- صفوف أولية: `NEW`, `TRIAGED`, `ASSIGNED`, `IN_PROGRESS`, `WAITING_ARBITRATION`, `WAITING_CLARIFICATION`, `WAITING_CHILD`, `RESOLVED`, `QUALITY_REVIEW`, `CLOSED`, `CANCELLED`, `REJECTED_BY_QUALITY`

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
- فريد: `(IdaraID_FK, impactCode)`
- صفوف أولية: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

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
- فريد: `(IdaraID_FK, urgencyCode)`
- صفوف أولية: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

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
- فريد: `(IdaraID_FK, ticketPriorityCode)`
- صفوف أولية: `P1`, `P2`, `P3`, `P4`

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
- فريد: `(IdaraID_FK, resolutionTypeCode)`
- صفوف أولية: `FIXED`, `WORKAROUND`, `KNOWN_ERROR`, `NOT_REPRODUCIBLE`, `DUPLICATE`

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
- فريد: `(IdaraID_FK, pauseReasonCode)`
- صفوف أولية: `ARBITRATION`, `CLARIFICATION`, `WAITING_CHILD`, `WAITING_APPROVAL`, `EXTERNAL_DEPENDENCY`

### 11.9 `[Tickets].[ArbitrationReason]`
```sql
arbitrationReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
arbitrationReasonCode NVARCHAR(50) NOT NULL
arbitrationReasonName_A NVARCHAR(200) NOT NULL
arbitrationReasonName_E NVARCHAR(200) NOT NULL
arbitrationReasonDescription NVARCHAR(1000) NULL
arbitrationReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, arbitrationReasonCode)`
- صفوف أولية: `UNKNOWN_SERVICE`, `WRONG_SCOPE`, `CROSS_DEPARTMENT`, `MANAGER_DECISION_REQUIRED`

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
- صفوف أولية: `MISSING_DETAILS`, `MISSING_APPROVAL`, `MISSING_DOCUMENT`, `NEED_PARENT_INPUT`

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
- صفوف أولية: `APPROVED`, `RETURNED`, `REJECTED`

### 11.12 `[Tickets].[OperationalType]`
```sql
operationalTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
operationalTypeCode NVARCHAR(50) NOT NULL
operationalTypeName_A NVARCHAR(200) NOT NULL
operationalTypeName_E NVARCHAR(200) NOT NULL
operationalTypeDescription NVARCHAR(1000) NULL
operationalTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, operationalTypeCode)`
- صفوف أولية: `SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`
- يُصنّف الطبيعة التشغيلية لسير العمل المرفق بالتذكرة
- يُستخدم من قبل `[Tickets].[ApprovalStep]` لتحديد قالب سلسلة الموافقات المناسب

### 11.13 `[Tickets].[ServiceCategory]`
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

### 11.14 `[Tickets].[Service]`
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
```
