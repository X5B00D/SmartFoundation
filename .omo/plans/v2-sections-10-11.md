## 10. V1 Table Set

### 10.1 Lookup Tables
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
- `[Tickets].[OperationalType]`

### 10.2 Master Tables
- `[Tickets].[ServiceCategory]`
- `[Tickets].[Service]`
- `[Tickets].[ServiceRoutingRule]`
- `[Tickets].[ServiceSLAPolicy]`
- `[Tickets].[PriorityMatrix]`
- `[Tickets].[ApprovalStep]`

### 10.3 Transaction Tables
- `[Tickets].[Ticket]`
- `[Tickets].[TicketArbitration]`
- `[Tickets].[TicketClarification]`
- `[Tickets].[TicketPauseSession]`
- `[Tickets].[TicketSLA]`
- `[Tickets].[TicketQualityReview]`
- `[Tickets].[ServiceCatalogSuggestion]`
- `[Tickets].[TicketApproval]`

### 10.4 History Tables
- `[Tickets].[TicketHistory]`
- `[Tickets].[TicketSLAHistory]`
- `[Tickets].[ServiceRoutingRuleHistory]`

## 11. Table-by-Table DDL Decisions

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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
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
Constraints and notes:
- Unique: `(IdaraID_FK, pauseReasonCode)`
- Seed rows: `ARBITRATION`, `CLARIFICATION`, `WAITING_CHILD`, `WAITING_APPROVAL`, `EXTERNAL_DEPENDENCY`

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
Constraints and notes:
- Unique: `(IdaraID_FK, arbitrationReasonCode)`
- Seed rows: `UNKNOWN_SERVICE`, `WRONG_SCOPE`, `CROSS_DEPARTMENT`, `MANAGER_DECISION_REQUIRED`

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
Constraints and notes:
- Unique: `(IdaraID_FK, clarificationReasonCode)`
- Seed rows: `MISSING_DETAILS`, `MISSING_APPROVAL`, `MISSING_DOCUMENT`, `NEED_PARENT_INPUT`

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
Constraints and notes:
- Unique: `(IdaraID_FK, qualityReviewResultCode)`
- Seed rows: `APPROVED`, `RETURNED`, `REJECTED`

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
Constraints and notes:
- Unique: `(IdaraID_FK, operationalTypeCode)`
- Seed rows: `SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`
- Classifies the operational nature of the workflow attached to a ticket
- Used by `[Tickets].[ApprovalStep]` to define which approval chain template applies

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
Constraints and notes:
- Unique: `(IdaraID_FK, serviceCategoryCode)`

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
allowInternalRequest BIT NOT NULL
requiresQualityReview BIT NOT NULL
allowChildTickets BIT NOT NULL
isOtherPlaceholder BIT NOT NULL
serviceActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
Constraints and notes:
- Unique: `(IdaraID_FK, serviceCode)`
- `isOtherPlaceholder = 0` for real services; the UI handles "Other" as null `serviceID_FK`

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
Constraints and notes:
- Unique filtered design target: one active row per `(IdaraID_FK, serviceID_FK, requesterTypeID_FK)` and date window
- `TargetDSDID_FK` is the routing truth
- `ArbitratorDSDID_FK` is mandatory so wrong-scope and other-service cases always have a valid destination

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
Constraints and notes:
- Unique active policy target: `(IdaraID_FK, serviceID_FK, ticketPriorityID_FK)`

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
Constraints and notes:
- Unique: `(IdaraID_FK, impactID_FK, urgencyID_FK)`
- This is the mandatory ITIL priority mapping source

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
Constraints and notes:
- Unique: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)`
- When `serviceID_FK` is NULL, the step applies to all services under that operational type
- `ApproverDSDID_FK` identifies the organizational unit whose approval is required at this step
- `ApproverDistributorID_FK` optionally narrows to a specific role within that unit
- `isRequired = 0` marks advisory or optional steps that can be skipped during workflow execution
- Together, the rows for a given `(operationalTypeID_FK, serviceID_FK)` ordered by `stepOrder` define the full approval chain template

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
Constraints and notes:
- Unique: `(IdaraID_FK, ticketNo)`
- Check rule in SP: exactly one of `UsersID_FK` or `residentInfoID_FK` must be populated
- Check rule in SP: `serviceID_FK` or `otherServiceText` must be populated
- `RootTicketID_FK` equals self for root records after insert finalization
- `operationalTypeID_FK` is required and determines which approval chain template is instantiated for this ticket

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
Constraints and notes:
- Only one active arbitration row per ticket at a time
- Closure logic sits in `[Tickets].[TicketSP]`

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
Constraints and notes:
- Only one active clarification row per ticket at a time
- At least one of `RequestedFromUsersID_FK` or `RequestedFromDSDID_FK` must be populated

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
Constraints and notes:
- Only one active pause session per ticket at a time
- `pausedMinutes` is finalized when the session ends

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
Constraints and notes:
- One active SLA row per ticket
- `slaState` values are controlled in SP logic: `RUNNING`, `PAUSED`, `RESOLVED`, `CLOSED`, `BREACHED`

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
ticketQualityReviewActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
Constraints and notes:
- Only one active quality review row per ticket
- Review starts when the ticket enters `QUALITY_REVIEW`

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
Constraints and notes:
- One ticket may create zero or one active suggestion
- `reviewDecision` is controlled by SP values such as `PENDING`, `ACCEPTED`, `REJECTED`, `MERGED`

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
Constraints and notes:
- One row per approval step instance per ticket
- `approvalStatus` controlled values: `PENDING`, `APPROVED`, `REJECTED`, `SKIPPED`
- `ApproverUsersID_FK` is populated when a specific user from the `ApproverDSDID_FK` unit acts on the step
- `SKIPPED` status is only valid for steps where the corresponding `[Tickets].[ApprovalStep].isRequired = 0`
- Approval chain is instantiated from `[Tickets].[ApprovalStep]` at ticket creation, matching the ticket's `operationalTypeID_FK` and optionally `serviceID_FK`
- All steps must reach `APPROVED` or `SKIPPED` before the ticket can proceed past the approval phase

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
Constraints and notes:
- Append-only
- Used for timeline rendering on `TicketWorkbench`

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
Constraints and notes:
- Append-only

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
Constraints and notes:
- Append-only
- This is the local change-enablement audit trail for routing changes
