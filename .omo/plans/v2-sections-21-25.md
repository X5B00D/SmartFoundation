# ITIL 4 Ticketing System Plan v2 - Sections 21-25

## 21. Spec-Kit Implementation Sequence

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
| Spec 13 | Create approval tables `[Tickets].[ApprovalStepTemplate]`, `[Tickets].[TicketApprovalStep]`, `[Tickets].[TicketApprovalLog]`; add `SUBMITAPPROVAL`, `APPROVESTEP`, `REJECTSTEP` actions to `[Tickets].[TicketSP]` | Spec 04, Spec 05 |
| Spec 14 | Create `TicketApprovals` DL resultsets and gateway branch; add `TicketApprovals` page to MVC controller surface with queue view, pending/completed filters, and per-step approve/reject actions | Spec 13, Spec 11 |
| Spec 15 | Seed approval step templates per service catalogue entry; seed operational type lookup rows (`Incident`, `ServiceRequest`, `Problem`, `ChangeRequest`); seed permission rows for all ticket page names into `[dbo].[Permission]` and `[dbo].[PermissionType]` | Spec 01, Spec 02, Spec 13 |

### 21.1 Approval Table Specs (Spec 13)

**`[Tickets].[ApprovalStepTemplate]`** defines the approval chain for a given service:

```sql
approvalStepTemplateID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceID_FK BIGINT NULL FK -> [Tickets].[Service].[serviceID]
ticketClassID_FK INT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
stepNumber INT NOT NULL
stepName_A NVARCHAR(200) NOT NULL
stepName_E NVARCHAR(200) NOT NULL
approverDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
approverDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
isAutoApproved BIT NOT NULL
effectiveFrom DATETIME NOT NULL
effectiveTo DATETIME NULL
approvalStepTemplateActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

Constraints: unique filtered on `(IdaraID_FK, serviceID_FK, ticketClassID_FK, stepNumber)` where active and effective window overlaps. When `serviceID_FK` is null the template applies as a fallback to any service without its own template.

**`[Tickets].[TicketApprovalStep]`** tracks the live approval chain for a specific ticket:

```sql
ticketApprovalStepID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
approvalStepTemplateID_FK BIGINT NOT NULL FK -> [Tickets].[ApprovalStepTemplate].[approvalStepTemplateID]
stepNumber INT NOT NULL
stepStatus NVARCHAR(50) NOT NULL
AssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
assignedAtDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
actedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
actedAt DATETIME NULL
actionNotes NVARCHAR(MAX) NULL
ticketApprovalStepActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

Constraints: `stepStatus` controlled values are `PENDING`, `APPROVED`, `REJECTED`, `SKIPPED`. One ticket can have multiple pending steps in parallel, but a step must be acted on before the next sequential step unlocks. The SP logic decides whether steps are serial or parallel based on the template configuration.

**`[Tickets].[TicketApprovalLog]`** is the append-only audit trail:

```sql
ticketApprovalLogID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
ticketApprovalStepID_FK BIGINT NOT NULL FK -> [Tickets].[TicketApprovalStep].[ticketApprovalStepID]
logAction NVARCHAR(100) NOT NULL
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
logNotes NVARCHAR(MAX) NULL
performedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

### 21.2 TicketApprovals Page Spec (Spec 14)

The `TicketApprovals` page follows the Housing pattern exactly:

- Controller: `TicketsController.TicketApprovals`
- Gateway read branch: `@pageName_ = 'TicketApprovals'` routes to `[Tickets].[TicketDL]`
- Resultset 0: permissions from `[dbo].[ft_UserPagePermissions]`
- Resultset 1: pending approval steps assigned to the current user's DSD scope
- Resultset 2: completed approval history for context
- Resultset 3: approval result lookup DDL
- Gateway write branch: `@pageName_ = 'TicketApprovals'` in `[dbo].[Masters_CRUD]` with permission check, then calls `[Tickets].[TicketSP]` with `APPROVESTEP` or `REJECTSTEP`
- The view uses `SmartRenderer` with a grid of pending steps and modal approve/reject forms

### 21.3 Permission Seeding Spec (Spec 15)

Permission seeding covers every ticket page name:

| Page Name | Required Permission Types |
|---|---|
| `TicketCreate` | insert, update |
| `TicketMyTickets` | select |
| `TicketInbox` | select, update |
| `TicketList` | select |
| `TicketWorkbench` | select, insert, update |
| `TicketQualityReview` | select, update |
| `ServiceCatalog` | select, insert, update, delete |
| `TicketReports` | select |
| `TicketApprovals` | select, update |

Seeding must insert rows into `[dbo].[Permission]` (page registration) and `[dbo].[PermissionType]` (action registration) for each page name above. The seeding script should be idempotent: check existence before inserting, and never overwrite rows that are already present. This script runs after gateway branches are in place and before the MVC controllers are deployed.

Operational type seeding adds the following rows to `[Tickets].[TicketClass]` if they do not already exist: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`, `CHANGE_REQUEST`. The `CHANGE_REQUEST` row is new in v2 and supports change-enablement tickets routed through the approval workflow.

Approval step template seeding creates default single-step approval templates for high-priority services and a fallback template (null `serviceID_FK`) that applies to any ticket without a specific template. The fallback uses the ticket's current `CurrentDSDID_FK` department head as the approver.

## 22. Testing Strategy

### 22.1 Database DDL Validation
- create all tables in a disposable database
- validate PK, FK, identity, and nullability rules
- validate no table is missing `IdaraID_FK`, `entryDate`, `entryData`, or `hostName`
- validate approval tables have correct FK chains: `TicketApprovalStep` -> `ApprovalStepTemplate`, `TicketApprovalLog` -> `TicketApprovalStep`

### 22.2 Procedure Unit Tests
- `INSERTTICKET` for internal user
- `INSERTTICKET` for resident
- priority calculation from impact/urgency matrix
- routing to service DSD
- routing to arbitration for unknown service
- invalid dual-requester rejection
- invalid assignee rejection
- quality review required before closure

### 22.3 Gateway Tests
- each `@pageName_` branch reaches the expected downstream procedure
- `[dbo].[Masters_DataLoad]` still returns permission resultset first
- `[dbo].[Masters_CRUD]` blocks unauthorized actions with the existing Arabic message
- `TicketApprovals` branch routes read to `[Tickets].[TicketDL]` and write to `[Tickets].[TicketSP]`

### 22.4 SLA Tests
- response and resolution deadlines are calculated correctly
- pause/resume updates `totalPausedMinutes`
- arbitration and clarification pauses behave according to `[Tickets].[PauseReason]`
- approval-related pause (`WAITING_APPROVAL`) pauses SLA clock and resumes on final approval or rejection

### 22.5 MVC Pattern Tests
- controllers build positional parameter arrays in Housing style
- `SplitDataSet` order matches page assumptions
- `TicketWorkbench` timeline renders from `[Tickets].[TicketHistory]`
- `TicketApprovals` controller reads permissions from resultset 0, pending steps from resultset 1, and builds the approval grid model correctly

### 22.6 Audit and Error Tests
- every successful write creates a `[dbo].[AuditLog]` row
- thrown business errors use `50001`
- unexpected errors write to `[dbo].[ErrorLog]`
- approval actions write both `[Tickets].[TicketApprovalLog]` and `[dbo].[AuditLog]`

### 22.7 Approval Workflow Tests
- `SUBMITAPPROVAL` creates approval step rows from `[Tickets].[ApprovalStepTemplate]`
- single-step approval: `APPROVESTEP` marks the step approved and advances the ticket status
- multi-step serial approval: second step remains pending until first step is approved
- `REJECTSTEP` marks the step rejected, writes log, and returns the ticket to the previous routing DSD
- approval by unauthorized user (wrong DSD) is rejected with permission error
- approval on a ticket that is not in an approval-eligible status is rejected with business error
- auto-approved steps (`isAutoApproved = 1`) skip to `APPROVED` immediately during `SUBMITAPPROVAL`

### 22.8 Operational Type Tests
- `CHANGE_REQUEST` ticket class is selectable on `TicketCreate` when permitted
- `CHANGE_REQUEST` tickets require approval before assignment, enforced by `INSERTTICKET` SP logic
- each ticket class code is unique within an Idara scope
- switching a ticket's class updates `ticketClassID_FK` and writes a `TicketHistory` row

### 22.9 Hierarchical Arbitration Tests
- arbitration can escalate from section level to department level when the current DSD is not the top-level node
- hierarchical escalation checks parent DSD from `[dbo].[V_GetFullStructureForDSD]`
- an arbitration decision at department level re-routes to the correct section if the decision identifies a lower-level DSD
- circular escalation (department back to same section) is rejected with a business error
- arbitration history preserves all escalation levels in `[Tickets].[TicketArbitration]` rows

### 22.10 Parallel Children Tests
- a parent ticket can have multiple child tickets active simultaneously
- each child ticket gets its own `TicketID`, `ParentTicketID_FK`, and shared `RootTicketID_FK`
- when all children are resolved, the parent ticket's `WAITING_CHILD` pause session ends automatically
- partial child completion (some resolved, some in progress) keeps the parent in `WAITING_CHILD` status
- a child ticket cannot be closed if its parent is cancelled or rejected
- parent SLA pause resumes only when the last active child is resolved, not when the first child resolves

## 23. Deployment and Rollback Considerations

### 23.1 Deployment Order
1. create lookup tables
2. seed lookup data (including `CHANGE_REQUEST` in `[Tickets].[TicketClass]`)
3. create master tables
4. create approval template table `[Tickets].[ApprovalStepTemplate]`
5. create transaction and history tables
6. create approval live tables `[Tickets].[TicketApprovalStep]`, `[Tickets].[TicketApprovalLog]`
7. create downstream `[Tickets]` procedures
8. add gateway branches in `[dbo].[Masters_DataLoad]` and `[dbo].[Masters_CRUD]`
9. seed approval step templates for existing services and fallback template
10. seed operational type rows (`CHANGE_REQUEST`) into `[Tickets].[TicketClass]`
11. seed permission rows for all ticket page names into `[dbo].[Permission]` and `[dbo].[PermissionType]`
12. seed menu entries for ticket pages
13. deploy MVC controller and views
14. verify permission and menu visibility on staging

### 23.2 Rollback Strategy
- if deployment fails before gateway changes, drop new `[Tickets]` objects in reverse dependency order
- if deployment fails after gateway changes, first remove new `@pageName_` branches, then disable menus/permissions, then roll back `[Tickets]` objects
- history and audit records are not deleted from production rollback without explicit business approval
- approval template and approval step data is treated as transactional: rollback drops the tables but preserves any approval log records that were written to `[dbo].[AuditLog]`

### 23.3 Data Migration Considerations
- `[Tickets]` is currently an empty shell schema, so V1 can start clean
- no migration from `[support]` is part of this plan
- approval step templates start seeded; they can be modified through `ServiceCatalog` admin after deployment
- operational type `CHANGE_REQUEST` is seeded but hidden from the intake form until the approval workflow is verified on staging

### 23.4 Seeding Script Requirements

All seeding scripts must be:

- **Idempotent**: check `WHERE NOT EXISTS` before inserting. No script should fail on re-run.
- **Idara-scoped**: lookup and template seeds reference a specific `IdaraID_FK`. Multi-Idara deployments run the script once per Idara.
- **Ordered**: operational types and approval templates run after their parent lookup and service tables exist.
- **Audited**: every seed insert records `entryData` and `hostName` from the deployment operator context.

The permission seeding script inserts page names into `[dbo].[Permission]` with the correct `menuName_E` value matching what the MVC controller sets as `PageName`. It inserts permission type rows (select, insert, update, delete) into `[dbo].[PermissionType]` only for the action types each page needs, as listed in section 21.3.

## 24. Execution Notes

- `ProcedureMapper` should continue to expose only the gateway entries, not every `[Tickets]` stored procedure.
- The controller should follow the Housing style exactly: `InitPageContext(out redirectResult)`, `ControllerName`, `PageName`, positional parameters, `GetDataLoadDataSetAsync`, `SplitDataSet`, server-built page model, thin view.
- Suggested controller surface:
  `TicketsController.TicketCreate`, `TicketsController.TicketMyTickets`, `TicketsController.TicketInbox`, `TicketsController.TicketList`, `TicketsController.TicketWorkbench`, `TicketsController.TicketQualityReview`, `TicketsController.TicketApprovals`, `TicketsController.ServiceCatalog`, `TicketsController.TicketReports`.
- `CrudController` remains the write entrypoint. Forms continue to post `p01..p50` and hidden fields such as `pageName_`, `ActionType`, `idaraID`, `entrydata`, and `hostname`.
- Read models should keep Housing ordering discipline: permissions first, then primary grid/header, then DDL/result helpers.
- Notifications should use `[dbo].[Notifications_Create]` from downstream SP logic where operationally needed; the notification subsystem itself is not redesigned here.
- `TicketApprovals` follows the same Housing controller pattern: `InitPageContext`, read session fields, build parameters, call `GetDataLoadDataSetAsync`, split resultsets, build `SmartPageViewModel`, render through `SmartRenderer`. The approve/reject actions post through `CrudController` using `pageName_ = 'TicketApprovals'` and `ActionType` of `APPROVESTEP` or `REJECTSTEP`.
- Permission seeding must complete before controllers go live. Without seeded rows in `[dbo].[Permission]` and `[dbo].[PermissionType]`, every ticket page will return zero permissions and the UI will render as read-only or blank. Verify seeding by checking `ft_UserPagePermissions` returns at least one row per ticket page name for a test user after deployment.
- The `TicketApprovals` page name must be added to the permission seeding script and menu configuration. If this page name is missing from `[dbo].[Permission]`, the gateway will reject all read and write attempts for the approval workflow.

## 25. Support Schema Clarification
The existing `[support]` schema is explicitly out of scope for this design.

`[support].[Ticket]`, `[support].[TicketType]`, `[support].[TicketPriority]`, `[support].[TicketStatus]`, `[support].[TicketReply]`, `[support].[TicketAttachment]`, `[support].[TicketTask]`, `[support].[TeamMember]`, and `[support].[TeamMemberRole]` remain the internal website bug-tracking solution for the dev team.

This plan does not merge, rename, extend, or depend on those `[support]` objects. The ITIL 4 ticketing system in this document is a separate business solution implemented only under `[Tickets]` and routed only through the existing Housing-style gateway architecture.
