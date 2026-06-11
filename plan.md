# ITIL 4 Ticketing System Plan

## 1. Document Status
- Status: Replanned draft for user review
- Language: English
- Baseline pattern: `SmartFoundation.Mvc/Controllers/Housing/WaitingList/HousingController.WaitingListByResident.cs`
- Runtime contract: `MastersServies` -> `Masters_DataLoad` / `Masters_CRUD` -> `[Tickets].[...DL]` / `[Tickets].[...SP]`
- Database grounding: existing org, user, permission, resident, audit, notification, and gateway objects already present in the repository snapshot
- Scope note: this document defines the V1 design; it is not itself the deployment script

## 2. Executive Summary
This plan replaces the prior ticketing design with a Housing-style implementation that fits the real SmartFoundation architecture and the real database naming already in use.

The V1 system lives entirely in the `[Tickets]` schema, but it does not create a new identity model, a new permission model, or a separate API layer. It reuses `[dbo].[Users]`, `[dbo].[UsersDetails]`, `[dbo].[Distributor]`, `[dbo].[UserDistributor]`, `[dbo].[Permission]`, `[dbo].[DeptSecDiv]`, `[dbo].[ft_UserPagePermissions]`, and the gateway procedures `[dbo].[Masters_DataLoad]` and `[dbo].[Masters_CRUD]`.

The operational design follows ITIL 4 and the existing Housing page pattern:
- all pages route by `@pageName_`
- reads return permission resultset first, then page data and DDL resultsets
- writes go through `CrudController` using `p01..p50` mapped to `parameter_01..parameter_50`
- downstream `[Tickets].[...SP]` procedures own business validation, audit trail, and database writes
- MVC controllers build `SmartPageViewModel`, `FormConfig`, and `SmartTableDsModel` server-side

V1 supports both requester types from day one:
- internal users through `UsersID_FK -> [dbo].[Users].[usersID]`
- residents / beneficiaries through `residentInfoID_FK -> [Housing].[ResidentInfo].[residentInfoID]`

V1 also covers the full functional scope requested: service catalogue, intake, routing, assignment, arbitration, clarification, parent-child linkage, SLA tracking with pause/resume, quality review, catalogue learning, and reporting.

## 3. Business Problem
The business needs a ticketing system that can:

1. Accept requests from both internal users and residents.
2. Route known services to the correct organizational queue using existing organizational truth.
3. Route unknown or unclear requests to an arbitrator without breaking the audit trail.
4. Separate wrong routing from missing information and from dependency-based delay.
5. Support incident handling, service request handling, and problem/root-cause relationships in one controlled model.
6. Track service levels fairly, including paused time caused by arbitration, clarification, approvals, and dependent child work.
7. Support quality closure instead of allowing every resolved ticket to become finally closed immediately.
8. Improve the service catalogue over time based on recurring "Other" tickets.
9. Produce dashboards and management reporting without bypassing the existing application and permission architecture.
10. Preserve central audit and error logging standards already used by Housing.

## 4. Scope

### 4.1 In Scope for V1
- `[Tickets]` schema data model
- lookup, master, transaction, and history tables
- gateway branches inside `[dbo].[Masters_DataLoad]` and `[dbo].[Masters_CRUD]`
- downstream `[Tickets].[TicketDL]`, `[Tickets].[TicketSP]`, `[Tickets].[ServiceCatalogDL]`, `[Tickets].[ServiceCatalogSP]`, and `[Tickets].[TicketReportDL]`
- Housing-style MVC pages backed by `MastersServies`, `DataSet`, and `SplitDataSet`
- service catalogue and routing rule administration
- ticket creation from both requester types
- queue assignment and user assignment
- arbitration workflow
- clarification workflow
- parent-child ticketing for dependency and problem tracking
- SLA tracking with pause/resume
- quality review before final closure
- catalogue suggestions from repeated "Other" tickets
- dashboards and reporting read models

### 4.2 Out of Scope for V1
- standalone REST or JSON API endpoints
- replacing `[dbo].[CrudController]` or the `p01..p50` contract
- replacing `[dbo].[Notifications_Create]`
- attachment subsystem
- public portal redesign
- automatic escalations by SQL Agent or background jobs
- CMDB / asset registry
- merging the separate `[support]` schema into this system

## 5. Key Design Principles
1. Gateway routing is mandatory. Every page must go through `[dbo].[Masters_DataLoad]` or `[dbo].[Masters_CRUD]` using `@pageName_` branches.
2. Housing conventions win over generic redesign ideas. The controller, `DataSet`, `SplitDataSet`, and thin Razor pattern are preserved.
3. `DSDID_FK` is the routing truth. Any display level is descriptive only.
4. `IdaraID_FK` exists on every `[Tickets]` table.
5. `UsersID_FK` keeps the existing repository convention with the trailing `s`.
6. Requester identity is dual-source. A ticket can point to either `[dbo].[Users]` or `[Housing].[ResidentInfo]`, but never neither.
7. Ticket status, arbitration, clarification, pause, resolution, and quality decisions must remain distinct business concepts.
8. ITIL 4 alignment must be visible in schema, procedures, and page design, not just in narrative text.
9. Every write operation must produce both local history rows and central `[dbo].[AuditLog]` entries.
10. Business validation errors must use `THROW 50001`; unexpected failures must be logged to `[dbo].[ErrorLog]` and rethrown.
11. Transaction and history tables use `BIGINT IDENTITY`; lookup tables use `INT IDENTITY`.
12. History tables are append-only and do not use soft delete.

## 6. ITIL 4 Practice Alignment

### 6.1 Incident Management
- Lifecycle: intake -> triage -> assignment -> in progress -> resolved -> quality review -> closed.
- Core tables: `[Tickets].[Ticket]`, `[Tickets].[TicketHistory]`, `[Tickets].[TicketQualityReview]`.
- Core fields: `ticketStatusID_FK`, `impactID_FK`, `urgencyID_FK`, `ticketPriorityID_FK`, `resolutionTypeID_FK`, `resolutionNotes`, `isMajorIncident`.

### 6.2 Service Catalogue Management
- Catalogue ownership sits in `[Tickets].[ServiceCategory]`, `[Tickets].[Service]`, `[Tickets].[ServiceRoutingRule]`, `[Tickets].[ServiceSLAPolicy]`.
- Known services route directly from catalogue rule; "Other" routes to arbitration.

### 6.3 Service Level Management
- Priority is derived through `[Tickets].[PriorityMatrix]` from impact x urgency.
- Ticket deadlines and accumulated clocks live in `[Tickets].[TicketSLA]`.
- Pause windows live in `[Tickets].[TicketPauseSession]`.
- Every SLA state transition is copied to `[Tickets].[TicketSLAHistory]`.

### 6.4 Problem Management
- `[Tickets].[Ticket]` carries `ParentTicketID_FK` and `RootTicketID_FK`.
- `ticketClassID_FK` distinguishes incident, service request, and problem records.
- Parent-child chains are used for blocking and root-cause tracking, not just informal grouping.

### 6.5 Continual Improvement
- "Other" tickets can produce structured rows in `[Tickets].[ServiceCatalogSuggestion]`.
- Suggestions are reviewable and can be converted into catalogue entries through `[Tickets].[ServiceCatalogSP]`.

### 6.6 Monitoring and Event Management
- V1 reporting is view/DL driven through `[Tickets].[TicketReportDL]` and gateway `TicketReports`.
- Dashboards cover backlog, SLA breach risk, quality review queue, routing errors, clarification aging, and major incidents.

### 6.7 Change Enablement
- Changes to routing rules and SLA policies are made only through `[Tickets].[ServiceCatalogSP]`.
- Each change writes central audit plus local `[Tickets].[ServiceRoutingRuleHistory]`.

## 7. Confirmed Functional Model

### 7.1 Request Sources
- Internal requester: `requesterTypeID_FK` seeded to Internal User and `UsersID_FK` populated.
- Resident requester: `requesterTypeID_FK` seeded to Resident and `residentInfoID_FK` populated.
- Ticket creation procedure rejects rows where both are null or both are populated.

### 7.2 Catalogue Selection
- Known service: `serviceID_FK` is populated and default routing/SLA derive from catalogue configuration.
- Other service: `serviceID_FK` is null and `otherServiceText` is required.

### 7.3 Routing Model
- Routing target is the current `CurrentDSDID_FK` on `[Tickets].[Ticket]`.
- Optional `CurrentDistributorID_FK` identifies the queue role if the organization wants a position-based inbox.
- `AssignedToUsersID_FK` is the current execution assignee and may remain null while the ticket is only in queue.

### 7.4 Assignment Model
- A queue owner or permitted supervisor assigns work to a real user.
- Eligibility is checked against active data in `[dbo].[V_GetListUsersInDSD]` and current DSD scope.
- Reassignment keeps the ticket inside authorized scope and writes a new history row.

### 7.5 Arbitration Model
- Arbitration is for responsibility dispute or unknown service routing.
- Clarification is not arbitration.
- Open arbitration state is represented by ticket status plus an active row in `[Tickets].[TicketArbitration]`.

### 7.6 Clarification Model
- Clarification is for missing or ambiguous information.
- Clarification may target requester, current queue, parent owner, or another internal unit.
- Clarification pauses SLA only when the pause reason is configured as SLA-pausing.

### 7.7 Parent-Child and Problem Model
- A child ticket has one `ParentTicketID_FK` and inherits `RootTicketID_FK` from the top node.
- A problem ticket is represented by `ticketClassID_FK` and may act as the parent/root record for related incidents.

### 7.8 SLA Model
- Priority is set on create and can be recalculated only by permitted action.
- Response and resolution due dates are stored on `[Tickets].[TicketSLA]`.
- Pauses create rows in `[Tickets].[TicketPauseSession]` with exact start and end timestamps.

### 7.9 Quality Review Model
- Executor resolves the ticket.
- Reviewer in `TicketQualityReview` accepts, rejects, or returns it.
- Final closure happens only after successful quality review or by an explicitly permitted bypass action.

### 7.10 Reporting Model
- Queue view: `TicketInbox`
- Requester view: `TicketMyTickets`
- Supervisor view: `TicketList`
- Resolver view: `TicketWorkbench`
- Reviewer view: `TicketQualityReview`
- Management dashboard: `TicketReports`

## 8. Confirmed Data Architecture Decisions

### 8.1 Schema Decision
All new business objects for this system are created under `[Tickets]` only.

### 8.2 Existing Identity and Org Truth
- User identity: `[dbo].[Users]` and `[dbo].[UsersDetails]`
- Resident identity: `[Housing].[ResidentInfo]` and `[Housing].[ResidentDetails]`
- Organizational truth: `[dbo].[DeptSecDiv]`
- Organizational assignment truth: `[dbo].[Distributor]` plus `[dbo].[UserDistributor]`

### 8.3 Foreign Key Conventions
- User FK: `UsersID_FK`
- Org FK: `IdaraID_FK`
- DSD FK: `DSDID_FK`
- Parent ticket FK: `ParentTicketID_FK`
- Root ticket FK: `RootTicketID_FK`

### 8.4 Audit Columns
Every `[Tickets]` table includes exactly:

```sql
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

### 8.5 Routing Truth Decision
- `CurrentDSDID_FK` on `[Tickets].[Ticket]` is the current responsible organizational node.
- `TargetDSDID_FK` on `[Tickets].[ServiceRoutingRule]` is the default routing node for catalogue intake.
- Any textual routing level is descriptive only and never replaces DSD keys.

### 8.6 Page and Procedure Truth
- Application layer still maps only gateway entries in `ProcedureMapper`.
- `MastersServies.GetDataLoadDataSetAsync(...)` and `GetCrudDataSetAsync(...)` remain the only app-layer data access path for the UI pages in this design.

### 8.7 Soft Delete Decision
- Lookup, master, and long-lived transaction tables use active flags where appropriate.
- History tables are append-only and never soft-deleted.

### 8.8 Support Schema Separation
`[support].[Ticket]` and related `[support]` objects remain a separate website bug-tracking solution for the internal dev team. They are not part of the ITIL 4 Tickets design and are not reused here.

## 9. External Dependencies
The `[Tickets]` schema assumes these existing objects exist and remain authoritative:

| Object | Purpose in Tickets |
|---|---|
| `[dbo].[Idara]` | mandatory `IdaraID_FK` parent |
| `[dbo].[Department]` | org reference for reporting and derived display |
| `[dbo].[Section]` | org reference for reporting and derived display |
| `[dbo].[Divison]` | org reference for reporting and derived display |
| `[dbo].[DeptSecDiv]` | routing truth through `DSDID_FK` |
| `[dbo].[Users]` | internal requester and assignee parent |
| `[dbo].[UsersDetails]` | display name and employee data |
| `[dbo].[Distributor]` | queue / role receiver |
| `[dbo].[UserDistributor]` | validates which users can act in which queue scope |
| `[dbo].[Permission]` | existing permission structure |
| `[dbo].[PermissionType]` | existing permission type structure |
| `[Housing].[ResidentInfo]` | resident requester parent |
| `[Housing].[ResidentDetails]` | resident display and Idara-scoped data |
| `[dbo].[AuditLog]` | central write audit |
| `[dbo].[ErrorLog]` | unexpected SQL error logging |
| `[dbo].[Notifications]` | stored notification records |
| `[dbo].[UserNotifications]` | recipient notification records |
| `[dbo].[Notifications_Create]` | existing notification dispatch procedure |
| `[dbo].[ft_UserPagePermissions]` | read permission resultset for page loads |
| `[dbo].[V_GetListUserPermission]` | CRUD permission validation |
| `[dbo].[V_GetListUsersInDSD]` | active eligible users by DSD |
| `[dbo].[V_GetFullStructureForDSD]` | org hierarchy display and reporting |

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

### 10.2 Master Tables
- `[Tickets].[ServiceCategory]`
- `[Tickets].[Service]`
- `[Tickets].[ServiceRoutingRule]`
- `[Tickets].[ServiceSLAPolicy]`
- `[Tickets].[PriorityMatrix]`

### 10.3 Transaction Tables
- `[Tickets].[Ticket]`
- `[Tickets].[TicketArbitration]`
- `[Tickets].[TicketClarification]`
- `[Tickets].[TicketPauseSession]`
- `[Tickets].[TicketSLA]`
- `[Tickets].[TicketQualityReview]`
- `[Tickets].[ServiceCatalogSuggestion]`

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
Constraints and notes:
- Unique: `(IdaraID_FK, serviceCategoryCode)`

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
Constraints and notes:
- Unique: `(IdaraID_FK, serviceCode)`
- `isOtherPlaceholder = 0` for real services; the UI handles "Other" as null `serviceID_FK`

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
Constraints and notes:
- Unique filtered design target: one active row per `(IdaraID_FK, serviceID_FK, requesterTypeID_FK)` and date window
- `TargetDSDID_FK` is the routing truth
- `ArbitratorDSDID_FK` is mandatory so wrong-scope and other-service cases always have a valid destination

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
Constraints and notes:
- Unique active policy target: `(IdaraID_FK, serviceID_FK, ticketPriorityID_FK)`

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
Constraints and notes:
- Unique: `(IdaraID_FK, impactID_FK, urgencyID_FK)`
- This is the mandatory ITIL priority mapping source

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
Constraints and notes:
- Unique: `(IdaraID_FK, ticketNo)`
- Check rule in SP: exactly one of `UsersID_FK` or `residentInfoID_FK` must be populated
- Check rule in SP: `serviceID_FK` or `otherServiceText` must be populated
- `RootTicketID_FK` equals self for root records after insert finalization

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
Constraints and notes:
- Only one active arbitration row per ticket at a time
- Closure logic sits in `[Tickets].[TicketSP]`

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
Constraints and notes:
- Only one active clarification row per ticket at a time
- At least one of `RequestedFromUsersID_FK` or `RequestedFromDSDID_FK` must be populated

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
Constraints and notes:
- Only one active pause session per ticket at a time
- `pausedMinutes` is finalized when the session ends

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
Constraints and notes:
- One active SLA row per ticket
- `slaState` values are controlled in SP logic: `RUNNING`, `PAUSED`, `RESOLVED`, `CLOSED`, `BREACHED`

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
Constraints and notes:
- Only one active quality review row per ticket
- Review starts when the ticket enters `QUALITY_REVIEW`

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
Constraints and notes:
- One ticket may create zero or one active suggestion
- `reviewDecision` is controlled by SP values such as `PENDING`, `ACCEPTED`, `REJECTED`, `MERGED`

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
Constraints and notes:
- Append-only
- Used for timeline rendering on `TicketWorkbench`

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
Constraints and notes:
- Append-only

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
Constraints and notes:
- Append-only
- This is the local change-enablement audit trail for routing changes

## 12. Stored Procedure Map

### 12.1 `[Tickets].[TicketDL]`
Purpose:
- page data loads for `TicketCreate`, `TicketMyTickets`, `TicketInbox`, `TicketList`, `TicketWorkbench`, `TicketQualityReview`

Signature pattern:
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

Resultset rules:
- Resultset 0 comes from `[dbo].[Masters_DataLoad]` via `[dbo].[ft_UserPagePermissions]`
- Resultset 1 is always the main page data
- Resultset 2+ are lookup datasets for `SmartRenderer` forms and filters

### 12.2 `[Tickets].[TicketSP]`
Purpose:
- all ticket lifecycle writes

Action groups:
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

Common responsibilities:
- validate requester identity
- validate service or other-service path
- calculate priority from `[Tickets].[PriorityMatrix]`
- load SLA from `[Tickets].[ServiceSLAPolicy]`
- validate DSD/user eligibility from `[dbo].[V_GetListUsersInDSD]`
- write `[Tickets].[TicketHistory]`, `[Tickets].[TicketSLAHistory]`, and `[dbo].[AuditLog]`
- log unexpected errors to `[dbo].[ErrorLog]`
- optionally call `[dbo].[Notifications_Create]`

### 12.3 `[Tickets].[ServiceCatalogDL]`
Purpose:
- read service catalogue maintenance page data for `ServiceCatalog`

Main resultsets:
- services grid
- routing rule grid
- SLA policy grid
- category/status/priority/DSD lookups
- suggestion review queue

### 12.4 `[Tickets].[ServiceCatalogSP]`
Purpose:
- catalogue, routing, SLA, and suggestion writes

Action groups:
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
Purpose:
- reporting datasets for `TicketReports`

Main resultsets:
- KPI summary
- backlog by status
- backlog by DSD
- SLA breach summary
- major incident summary
- clarification aging
- arbitration aging
- catalogue suggestion volume

## 13. View / DL Design Map

### 13.1 `TicketCreate`
- Gateway branch calls `[Tickets].[TicketDL]`
- Resultset 1: requester context and any open-ticket warnings
- Resultset 2: services
- Resultset 3: ticket classes
- Resultset 4: impacts
- Resultset 5: urgencies
- Resultset 6: requester types

### 13.2 `TicketMyTickets`
- Resultset 1: requester ticket list
- Resultset 2: status filter DDL
- Resultset 3: priority filter DDL

### 13.3 `TicketInbox`
- Resultset 1: queue-owned tickets by `CurrentDSDID_FK`
- Resultset 2: eligible assignees from `[dbo].[V_GetListUsersInDSD]`
- Resultset 3: status filter DDL

### 13.4 `TicketList`
- Resultset 1: management list scoped by permission and Idara
- Resultset 2: status filter DDL
- Resultset 3: class filter DDL
- Resultset 4: priority filter DDL
- Resultset 5: org filter DDL from `[dbo].[V_GetFullStructureForDSD]`

### 13.5 `TicketWorkbench`
- Resultset 1: one ticket header
- Resultset 2: history timeline
- Resultset 3: active arbitration rows
- Resultset 4: active clarification rows
- Resultset 5: child tickets
- Resultset 6: SLA row
- Resultset 7: assignee/DSD action lookups

### 13.6 `TicketQualityReview`
- Resultset 1: resolved tickets waiting for quality review
- Resultset 2: review result lookup
- Resultset 3: priority/status stats for reviewer dashboard cards

### 13.7 `ServiceCatalog`
- Gateway branch calls `[Tickets].[ServiceCatalogDL]`
- Resultset 1: services
- Resultset 2: routing rules
- Resultset 3: SLA policies
- Resultset 4: service categories
- Resultset 5: DSD lookups
- Resultset 6: catalogue suggestions

### 13.8 `TicketReports`
- Gateway branch calls `[Tickets].[TicketReportDL]`
- Resultsets are reporting-only and should not be reused for CRUD pages

## 14. Gateway Routing Additions

### 14.1 `[dbo].[Masters_DataLoad]`
Add these `@pageName_` branches following the real Housing style:

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
Add these page branches following the real `WaitingListByResident` permission-check style:

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

Page values to add exactly:
- `TicketCreate`
- `TicketMyTickets`
- `TicketInbox`
- `TicketList`
- `TicketWorkbench`
- `TicketQualityReview`
- `ServiceCatalog`
- `TicketReports`

## 15. Business Rule Matrix

| ID | Rule | Enforcement Location |
|---|---|---|
| BR-01 | Exactly one requester source must be present: `UsersID_FK` xor `residentInfoID_FK` | `[Tickets].[TicketSP]` |
| BR-02 | Known service requires `serviceID_FK`; unknown service requires `otherServiceText` | `[Tickets].[TicketSP]` |
| BR-03 | Ticket create must calculate priority from `impactID_FK` x `urgencyID_FK` via `[Tickets].[PriorityMatrix]` | `[Tickets].[TicketSP]` |
| BR-04 | Ticket create must load SLA from `[Tickets].[ServiceSLAPolicy]` when `serviceID_FK` is present | `[Tickets].[TicketSP]` |
| BR-05 | `CurrentDSDID_FK` must always be populated on `[Tickets].[Ticket]` | `[Tickets].[TicketSP]` |
| BR-06 | Assignment to `AssignedToUsersID_FK` is valid only if the user is active and eligible in `[dbo].[V_GetListUsersInDSD]` for the current DSD | `[Tickets].[TicketSP]` |
| BR-07 | Arbitration and clarification cannot both be active for the same ticket at the same time | `[Tickets].[TicketSP]` |
| BR-08 | Only one active pause session exists per ticket | `[Tickets].[TicketSP]` plus table query check |
| BR-09 | Parent and root links must be set atomically when creating a child ticket | `[Tickets].[TicketSP]` |
| BR-10 | A ticket cannot move to `CLOSED` before successful quality review unless a specific bypass action is granted | `[Tickets].[TicketSP]` and permission config |
| BR-11 | `resolutionTypeID_FK` and `resolutionNotes` are required for `RESOLVETICKET` | `[Tickets].[TicketSP]` |
| BR-12 | `isMajorIncident = 1` requires critical routing and reviewer visibility | `[Tickets].[TicketSP]` plus `TicketReportDL` |
| BR-13 | Every write action inserts both local history and central `[dbo].[AuditLog]` | `[Tickets].[TicketSP]`, `[Tickets].[ServiceCatalogSP]` |
| BR-14 | Routing rule changes must write `[Tickets].[ServiceRoutingRuleHistory]` | `[Tickets].[ServiceCatalogSP]` |
| BR-15 | History tables are append-only | SP design and no delete/update paths |
| BR-16 | Every page read must return permission resultset first through `[dbo].[ft_UserPagePermissions]` | `[dbo].[Masters_DataLoad]` |
| BR-17 | Every CRUD page must check page permission through `[dbo].[V_GetListUserPermission]` before calling downstream SP | `[dbo].[Masters_CRUD]` |
| BR-18 | `TicketInbox` and `TicketWorkbench` must scope visible tickets by page permission and current organizational truth | DL query design |

## 16. Spec-Kit Implementation Sequence

| Spec | Capability | Depends On |
|---|---|---|
| Spec 01 | Create lookup tables and seed data | none |
| Spec 02 | Create master catalogue tables `[Tickets].[ServiceCategory]`, `[Tickets].[Service]`, `[Tickets].[PriorityMatrix]` | Spec 01 |
| Spec 03 | Create routing and SLA master tables `[Tickets].[ServiceRoutingRule]`, `[Tickets].[ServiceSLAPolicy]` | Spec 01, Spec 02 |
| Spec 04 | Create `[Tickets].[Ticket]`, `[Tickets].[TicketHistory]`, `[Tickets].[TicketSLA]`, `[Tickets].[TicketSLAHistory]` | Spec 01, Spec 02, Spec 03 |
| Spec 05 | Implement `[Tickets].[TicketSP]` actions for `INSERTTICKET`, `ASSIGNTICKET`, `STARTPROGRESS`, `RESOLVETICKET` | Spec 04 |
| Spec 06 | Add arbitration tables and `REQUESTARBITRATION` / `DECIDEARBITRATION` actions | Spec 04, Spec 05 |
| Spec 07 | Add clarification tables and `REQUESTCLARIFICATION` / `RESPONDCLARIFICATION` actions | Spec 04, Spec 05 |
| Spec 08 | Add child ticket and problem flow with `CREATECHILDTICKET`, `PAUSETICKET`, `RESUMETICKET` | Spec 04, Spec 05 |
| Spec 09 | Add quality review table and `STARTQUALITYREVIEW`, `COMPLETEQUALITYREVIEW`, `CLOSETICKET` | Spec 04, Spec 05 |
| Spec 10 | Add catalogue suggestion table and `[Tickets].[ServiceCatalogSP]` review/convert actions | Spec 02, Spec 03, Spec 05 |
| Spec 11 | Add DL procedures, report procedure, and gateway branches | Specs 01-10 as needed |
| Spec 12 | Add Housing-style MVC pages and controller actions using `MastersServies`, `SplitDataSet`, and `SmartRenderer` | Spec 11 |

## 17. Testing Strategy

### 17.1 Database DDL Validation
- create all tables in a disposable database
- validate PK, FK, identity, and nullability rules
- validate no table is missing `IdaraID_FK`, `entryDate`, `entryData`, or `hostName`

### 17.2 Procedure Unit Tests
- `INSERTTICKET` for internal user
- `INSERTTICKET` for resident
- priority calculation from impact/urgency matrix
- routing to service DSD
- routing to arbitration for unknown service
- invalid dual-requester rejection
- invalid assignee rejection
- quality review required before closure

### 17.3 Gateway Tests
- each `@pageName_` branch reaches the expected downstream procedure
- `[dbo].[Masters_DataLoad]` still returns permission resultset first
- `[dbo].[Masters_CRUD]` blocks unauthorized actions with the existing Arabic message

### 17.4 SLA Tests
- response and resolution deadlines are calculated correctly
- pause/resume updates `totalPausedMinutes`
- arbitration and clarification pauses behave according to `[Tickets].[PauseReason]`

### 17.5 MVC Pattern Tests
- controllers build positional parameter arrays in Housing style
- `SplitDataSet` order matches page assumptions
- `TicketWorkbench` timeline renders from `[Tickets].[TicketHistory]`

### 17.6 Audit and Error Tests
- every successful write creates a `[dbo].[AuditLog]` row
- thrown business errors use `50001`
- unexpected errors write to `[dbo].[ErrorLog]`

## 18. Deployment and Rollback Considerations

### 18.1 Deployment Order
1. create lookup tables
2. seed lookup data
3. create master tables
4. create transaction and history tables
5. create downstream `[Tickets]` procedures
6. add gateway branches in `[dbo].[Masters_DataLoad]` and `[dbo].[Masters_CRUD]`
7. deploy MVC controller and views
8. deploy permissions/menu configuration for page names

### 18.2 Rollback Strategy
- if deployment fails before gateway changes, drop new `[Tickets]` objects in reverse dependency order
- if deployment fails after gateway changes, first remove new `@pageName_` branches, then disable menus/permissions, then roll back `[Tickets]` objects
- history and audit records are not deleted from production rollback without explicit business approval

### 18.3 Data Migration Considerations
- `[Tickets]` is currently an empty shell schema, so V1 can start clean
- no migration from `[support]` is part of this plan

## 19. Execution Notes
- `ProcedureMapper` should continue to expose only the gateway entries, not every `[Tickets]` stored procedure.
- The controller should follow the Housing style exactly: `InitPageContext(out redirectResult)`, `ControllerName`, `PageName`, positional parameters, `GetDataLoadDataSetAsync`, `SplitDataSet`, server-built page model, thin view.
- Suggested controller surface:
  `TicketsController.TicketCreate`, `TicketsController.TicketMyTickets`, `TicketsController.TicketInbox`, `TicketsController.TicketList`, `TicketsController.TicketWorkbench`, `TicketsController.TicketQualityReview`, `TicketsController.ServiceCatalog`, `TicketsController.TicketReports`.
- `CrudController` remains the write entrypoint. Forms continue to post `p01..p50` and hidden fields such as `pageName_`, `ActionType`, `idaraID`, `entrydata`, and `hostname`.
- Read models should keep Housing ordering discipline: permissions first, then primary grid/header, then DDL/result helpers.
- Notifications should use `[dbo].[Notifications_Create]` from downstream SP logic where operationally needed; the notification subsystem itself is not redesigned here.

## 20. Support Schema Clarification
The existing `[support]` schema is explicitly out of scope for this design.

`[support].[Ticket]`, `[support].[TicketType]`, `[support].[TicketPriority]`, `[support].[TicketStatus]`, `[support].[TicketReply]`, `[support].[TicketAttachment]`, `[support].[TicketTask]`, `[support].[TeamMember]`, and `[support].[TeamMemberRole]` remain the internal website bug-tracking solution for the dev team.

This plan does not merge, rename, extend, or depend on those `[support]` objects. The ITIL 4 ticketing system in this document is a separate business solution implemented only under `[Tickets]` and routed only through the existing Housing-style gateway architecture.
