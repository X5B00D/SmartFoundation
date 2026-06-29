# ITIL 4 Ticketing System Plan — V2

## 1. Document Status

- Status: V2 replanned draft for user review
- Version: V2 (extends V1 with operational types, approval chains, hierarchical arbitration, AND-join children, and inter-technician clarification)
- Language: English
- Baseline pattern: `SmartFoundation.Mvc/Controllers/Housing/WaitingList/HousingController.WaitingListByResident.cs`
- Runtime contract: `MastersServies` -> `Masters_DataLoad` / `Masters_CRUD` -> `[Tickets].[...DL]` / `[Tickets].[...SP]`
- Database grounding: existing org, user, permission, resident, audit, notification, and gateway objects already present in the repository snapshot
- Scope note: this document defines the V2 design; it is not itself the deployment script
- V1 relationship: V2 is backwards-compatible with V1 tables and procedures. New tables (`OperationalType`, `ApprovalStep`, `TicketApproval`, `ApprovalStepHistory`) extend the schema without breaking existing V1 contracts.

## 2. Executive Summary

This plan extends the V1 Housing-style ticketing design with capabilities the business has identified since the initial scope was frozen. V2 preserves everything V1 built: the `[Tickets]` schema, the dual-requester model, the gateway procedure routing, the `MastersServies` / `DataSet` / `SplitDataSet` page assembly pipeline, and the thin Razor / `SmartRenderer` rendering approach.

V2 adds five new capabilities on top of the V1 foundation.

**Operational ticket types.** Tickets now carry an `operationalTypeID_FK` that classifies them as one of four types: طلب خدمة (service request), طلب صرف (disbursement), طلب تنفيذ (execution), or طلب معاينة (inspection). Each type has distinct routing rules, approval requirements, and workflow behavior. The type is set at intake and influences every downstream decision.

**Multi-level approval chains.** Approval is no longer a single binary gate. Approval steps are stored in `[Tickets].[ApprovalStep]` with an ordered chain: technician, supervisor, branch manager, section manager, department manager. The chain varies by operational type and by service. Progress is tracked row by row in `[Tickets].[TicketApproval]`. A ticket cannot proceed past an approval step until the required approver has acted. Approval pauses SLA while the step is pending.

**Hierarchical arbitration.** When two organizational units dispute ownership, the system now resolves the dispute at the correct hierarchical level. Sections escalate to an arbitrator at the branch level. Branches escalate to the department level. Departments escalate to the Idara level. The arbitrator is a new `Distributor` type linked to the parent org's DSDID. This replaces the V1 flat arbitration model with one that mirrors the real chain of authority.

**Parallel children with AND-join.** A parent ticket can now spawn multiple children simultaneously. The parent enters a `WAITING_CHILD` status and stays there until every child reaches a terminal state (resolved, closed, or cancelled). This is an AND-join: all children must complete before the parent can resume. The V1 parent-child model already existed, but V2 makes the blocking semantics explicit and adds the `WAITING_CHILD` pause reason as a first-class concept.

**Inter-technician clarification.** Clarification is no longer limited to "requester is missing information." V2 supports technician-to-technician coordination between different organizational units. The clarification model now carries both a `RequestedFromDSDID_FK` and a `RequestedFromUsersID_FK`, allowing one technician to ask another unit's technician for input without going through arbitration. This keeps the audit trail clean and avoids unnecessary escalations.

All frontend pages follow the Housing baseline: controllers build `SmartPageViewModel`, `FormConfig`, `SmartTableDsModel`, and `FieldConfig` server-side. Views invoke `SmartRenderer`. Reads return the permission resultset first. Writes go through `CrudController` using the `p01..p50` to `parameter_01..parameter_50` mapping. Downstream `[Tickets].[...SP]` procedures own business validation, audit trail, and database writes. The gateway contract is unchanged.

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
11. **Distinguish between four operational ticket types** (service request, disbursement, execution, inspection) because each type follows different routing paths, approval chains, and resolution workflows.
12. **Enforce multi-level approval chains** where a disbursement request might need technician, supervisor, and department manager approval before execution begins, while a simple inspection might need only technician and supervisor sign-off.
13. **Handle maintenance work orders** that span multiple organizational units, where a single parent request (for example, building maintenance) spawns parallel child tickets for electrical work, plumbing work, and painting, and the parent cannot close until all children complete.
14. **Support technician-to-technician coordination** across organizational boundaries without forcing every cross-unit question into the formal arbitration process.
15. **Resolve organizational disputes at the correct hierarchical level**, so that section-level disagreements are handled at the branch level, branch-level disagreements at the department level, and department-level disagreements at the Idara level.

## 4. Scope

### 4.1 In Scope for V2

Everything in V1, plus:

- `[Tickets].[OperationalType]` lookup table and `operationalTypeID_FK` on `[Tickets].[Ticket]`
- `[Tickets].[ApprovalStep]` master table defining ordered approval chains per operational type and service
- `[Tickets].[TicketApproval]` transaction table tracking individual approval decisions
- `[Tickets].[ApprovalStepHistory]` history table for approval chain changes
- `WAITING_APPROVAL` ticket status and `WAITING_APPROVAL` pause reason
- Hierarchical arbitration routing: section disputes to branch arbitrator, branch disputes to department arbitrator, department disputes to Idara arbitrator
- Arbitrator as a new `Distributor` type linked to parent org DSDID
- AND-join parent-child semantics: parent enters `WAITING_CHILD` status, resumes only when all children reach terminal state
- Inter-technician clarification: clarification requests can target a specific DSD and user in another organizational unit
- Permission matrix entries for all ticket pages and actions
- Housing-style dynamic frontend pages using `SmartRenderer`, `SmartPageViewModel`, `FormConfig`, `SmartTableDsModel`
- Approval chain configuration page (`ApprovalStepConfig`) as a new `pageName_`
- Ticket approval workflow page (`TicketApprovals`) as a new `pageName_`

Full V1 scope carried forward:

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

### 4.2 Out of Scope for V2

- standalone REST or JSON API endpoints
- replacing `[dbo].[CrudController]` or the `p01..p50` contract
- replacing `[dbo].[Notifications_Create]`
- attachment subsystem
- public portal redesign
- automatic escalations by SQL Agent or background jobs
- CMDB / asset registry
- merging the separate `[support]` schema into this system
- parallel children with OR-join semantics (only AND-join is in scope)
- partial approval chain skipping or delegation (each step must be acted on by the designated approver)

## 5. Key Design Principles

1. **Gateway routing is mandatory.** Every page must go through `[dbo].[Masters_DataLoad]` or `[dbo].[Masters_CRUD]` using `@pageName_` branches.
2. **Housing conventions win over generic redesign ideas.** The controller, `DataSet`, `SplitDataSet`, and thin Razor pattern are preserved.
3. **`DSDID_FK` is the routing truth.** Any display level is descriptive only.
4. **`IdaraID_FK` exists on every `[Tickets]` table.**
5. **`UsersID_FK` keeps the existing repository convention with the trailing `s`.**
6. **Requester identity is dual-source.** A ticket can point to either `[dbo].[Users]` or `[Housing].[ResidentInfo]`, but never neither.
7. **Ticket status, arbitration, clarification, approval, pause, resolution, and quality decisions must remain distinct business concepts.** Approval is not the same as quality review. Waiting for approval is not the same as waiting for clarification.
8. **ITIL 4 alignment must be visible in schema, procedures, and page design, not just in narrative text.**
9. **Every write operation must produce both local history rows and central `[dbo].[AuditLog]` entries.**
10. **Business validation errors must use `THROW 50001`; unexpected failures must be logged to `[dbo].[ErrorLog]` and rethrown.**
11. **Transaction and history tables use `BIGINT IDENTITY`; lookup tables use `INT IDENTITY`.**
12. **History tables are append-only and do not use soft delete.**
13. **Operational type drives workflow, not the other way around.** The operational type (service request, disbursement, execution, inspection) determines which approval chain applies, how routing works, and what resolution looks like. It is not a cosmetic label.
14. **Approval steps are ordered, stored data, not hardcoded logic.** The chain (technician, supervisor, branch manager, section manager, department manager) lives in `[Tickets].[ApprovalStep]` with an explicit `stepOrder`. This means the chain can differ by operational type and by service without changing stored procedure code.
15. **Hierarchical arbitration mirrors the real org chart.** Disputes escalate one level: sections to branches, branches to departments, departments to Idara. The arbitrator is identified by org structure, not by configuration.
16. **AND-join is the only parent-child blocking model.** When a parent spawns parallel children, the parent waits until every child completes. There is no partial or OR-join behavior.
17. **Inter-technician clarification is a first-class workflow, not an informal chat.** It creates a traceable row in `[Tickets].[TicketClarification]`, pauses SLA when configured to do so, and requires a formal response before the ticket can proceed.

## 6. ITIL 4 Practice Alignment

### 6.1 Incident Management
- Lifecycle: intake -> triage -> assignment -> in progress -> resolved -> quality review -> closed.
- Core tables: `[Tickets].[Ticket]`, `[Tickets].[TicketHistory]`, `[Tickets].[TicketQualityReview]`.
- Core fields: `ticketStatusID_FK`, `impactID_FK`, `urgencyID_FK`, `ticketPriorityID_FK`, `resolutionTypeID_FK`, `resolutionNotes`, `isMajorIncident`.

### 6.2 Service Catalogue Management
- Catalogue ownership sits in `[Tickets].[ServiceCategory]`, `[Tickets].[Service]`, `[Tickets].[ServiceRoutingRule]`, `[Tickets].[ServiceSLAPolicy]`.
- Known services route directly from catalogue rule; "Other" routes to arbitration.
- Services now carry `operationalTypeID_FK` to classify them by operational type.

### 6.3 Service Level Management
- Priority is derived through `[Tickets].[PriorityMatrix]` from impact x urgency.
- Ticket deadlines and accumulated clocks live in `[Tickets].[TicketSLA]`.
- Pause windows live in `[Tickets].[TicketPauseSession]`.
- Every SLA state transition is copied to `[Tickets].[TicketSLAHistory]`.
- SLA pauses during approval steps when the pause reason `WAITING_APPROVAL` is configured as SLA-pausing.

### 6.4 Problem Management
- `[Tickets].[Ticket]` carries `ParentTicketID_FK` and `RootTicketID_FK`.
- `ticketClassID_FK` distinguishes incident, service request, and problem records.
- Parent-child chains are used for blocking and root-cause tracking, not just informal grouping.
- V2 adds AND-join blocking: parent is `WAITING_CHILD` until all children reach terminal state.

### 6.5 Continual Improvement
- "Other" tickets can produce structured rows in `[Tickets].[ServiceCatalogSuggestion]`.
- Suggestions are reviewable and can be converted into catalogue entries through `[Tickets].[ServiceCatalogSP]`.

### 6.6 Monitoring and Event Management
- V1 reporting is view/DL driven through `[Tickets].[TicketReportDL]` and gateway `TicketReports`.
- Dashboards cover backlog, SLA breach risk, quality review queue, routing errors, clarification aging, major incidents, approval pipeline status, and waiting parents.

### 6.7 Change Enablement
- Changes to routing rules and SLA policies are made only through `[Tickets].[ServiceCatalogSP]`.
- Each change writes central audit plus local `[Tickets].[ServiceRoutingRuleHistory]`.

### 6.8 Workflow Approval Practice
- Approval chains are defined in `[Tickets].[ApprovalStep]` with ordered steps per operational type and service combination.
- Approval progress is tracked in `[Tickets].[TicketApproval]` with individual approver decisions.
- Approval chain is a mandatory gate between intake and execution for operational types that require it.
- Approval pauses SLA when `WAITING_APPROVAL` is an SLA-pausing reason.
- Rejection at any step returns the ticket to the previous stage with a recorded reason.
- Approval history writes both `[Tickets].[ApprovalStepHistory]` and `[dbo].[AuditLog]`.

## 7. Functional Model

### 7.1 Request Sources
- Internal requester: `requesterTypeID_FK` seeded to Internal User and `UsersID_FK` populated.
- Resident requester: `requesterTypeID_FK` seeded to Resident and `residentInfoID_FK` populated.
- Ticket creation procedure rejects rows where both are null or both are populated.

### 7.2 Catalogue Selection
- Known service: `serviceID_FK` is populated and default routing/SLA derive from catalogue configuration.
- Other service: `serviceID_FK` is null and `otherServiceText` is required.
- Services carry `operationalTypeID_FK`, so selecting a known service also sets the operational type.

### 7.3 Routing Model
- Routing target is the current `CurrentDSDID_FK` on `[Tickets].[Ticket]`.
- Optional `CurrentDistributorID_FK` identifies the queue role if the organization wants a position-based inbox.
- `AssignedToUsersID_FK` is the current execution assignee and may remain null while the ticket is only in queue.
- Routing rules can vary by operational type, allowing disbursement tickets to route to finance and inspection tickets to route to field operations even for the same service.

### 7.4 Assignment Model
- A queue owner or permitted supervisor assigns work to a real user.
- Eligibility is checked against active data in `[dbo].[V_GetListUsersInDSD]` and current DSD scope.
- Reassignment keeps the ticket inside authorized scope and writes a new history row.

### 7.5 Arbitration Model
- Arbitration is for responsibility dispute or unknown service routing.
- Clarification is not arbitration.
- Open arbitration state is represented by ticket status plus an active row in `[Tickets].[TicketArbitration]`.
- Hierarchical routing: section-level disputes escalate to an arbitrator at the branch level; branch-level disputes escalate to the department level; department-level disputes escalate to the Idara level.
- The arbitrator is identified as a `Distributor` record linked to the parent org's DSDID.
- `[Tickets].[TicketArbitration]` carries `ArbitratorDSDID_FK` pointing to the appropriate hierarchical level.

### 7.6 Clarification Model
- Clarification is for missing or ambiguous information.
- V2 extends clarification beyond requester-facing requests: technicians can now request clarification from technicians in other organizational units.
- Clarification may target requester, current queue, parent owner, or another internal unit's specific user or DSD.
- Clarification pauses SLA only when the pause reason is configured as SLA-pausing.
- Inter-technician clarification rows in `[Tickets].[TicketClarification]` carry both `RequestedFromDSDID_FK` and `RequestedFromUsersID_FK`, making cross-unit coordination traceable.

### 7.7 Parent-Child and Problem Model
- A child ticket has one `ParentTicketID_FK` and inherits `RootTicketID_FK` from the top node.
- A problem ticket is represented by `ticketClassID_FK` and may act as the parent/root record for related incidents.
- V2 adds AND-join blocking: when a parent spawns multiple children simultaneously, the parent enters `WAITING_CHILD` status.
- The parent stays `WAITING_CHILD` until every child reaches a terminal state (resolved, closed, or cancelled).
- The `WAITING_CHILD` pause reason tracks the blocking period in `[Tickets].[TicketPauseSession]`.
- Typical use case: a maintenance work order spawns parallel child tickets for electrical, plumbing, and painting. The parent cannot close until all three children complete.

### 7.8 SLA Model
- Priority is set on create and can be recalculated only by permitted action.
- Response and resolution due dates are stored on `[Tickets].[TicketSLA]`.
- Pauses create rows in `[Tickets].[TicketPauseSession]` with exact start and end timestamps.
- V2 adds `WAITING_APPROVAL` as a valid pause reason, so SLA clocks pause during approval steps when configured.

### 7.9 Quality Review Model
- Executor resolves the ticket.
- Reviewer in `TicketQualityReview` accepts, rejects, or returns it.
- Final closure happens only after successful quality review or by an explicitly permitted bypass action.
- Quality review is separate from approval: approval gates happen before or during execution, quality review happens after resolution.

### 7.10 Reporting Model
- Queue view: `TicketInbox`
- Requester view: `TicketMyTickets`
- Supervisor view: `TicketList`
- Resolver view: `TicketWorkbench`
- Reviewer view: `TicketQualityReview`
- Approval view: `TicketApprovals`
- Management dashboard: `TicketReports`
- V2 reporting includes approval pipeline metrics: average approval time by step, rejection rates, and bottleneck identification.

### 7.11 Operational Type Model

The system supports four operational ticket types, each with distinct behavior:

| Code | Arabic Name | English Name | Typical Routing | Typical Approval Chain |
|---|---|---|---|---|
| `SERVICE_REQUEST` | طلب خدمة | Service Request | Service queue by catalogue rule | Technician -> Supervisor |
| `DISBURSEMENT` | طلب صرف | Disbursement | Finance section | Technician -> Supervisor -> Branch Manager -> Section Manager -> Department Manager |
| `EXECUTION` | طلب تنفيذ | Execution | Operations/field queue by service | Technician -> Supervisor -> Branch Manager |
| `INSPECTION` | طلب معاينة | Inspection | Field inspection queue | Technician -> Supervisor |

Operational type is set at ticket creation based on the selected service's `operationalTypeID_FK`. The type influences:
- Which approval chain applies (via `[Tickets].[ApprovalStep]` configuration)
- Default routing target when the service routing rule does not specify one
- SLA policy selection (different operational types can have different SLA expectations)
- Resolution workflow (disbursement requires financial confirmation, inspection requires field report)

The `OperationalType` table is a lookup table seeded with exactly these four rows. The `[Tickets].[Ticket]` table carries `operationalTypeID_FK` as a required foreign key.

### 7.12 Approval Chain Model

Approval chains are stored as data, not as hardcoded logic. This allows different chains for different operational types and services without changing stored procedure code.

Structure:
- `[Tickets].[ApprovalStep]` defines the ordered steps in an approval chain. Each row specifies `stepOrder`, `approverRoleTypeID_FK` (technician, supervisor, branch manager, section manager, department manager), and optionally a specific `ApproverDSDID_FK` or `ApproverUsersID_FK`.
- A chain is identified by the combination of `operationalTypeID_FK` and `serviceID_FK`. When `serviceID_FK` is null, the chain acts as the default for that operational type.
- `[Tickets].[TicketApproval]` tracks progress. Each row records which step, who approved or rejected, when, and with what notes.

Workflow:
1. Ticket is created. If the operational type requires approval, the system loads the matching chain from `[Tickets].[ApprovalStep]`.
2. The first step's approver is notified. The ticket enters `WAITING_APPROVAL` status. SLA pauses if configured.
3. The approver acts: approve, reject, or return.
4. If approved, the system moves to the next step. If this was the last step, the ticket exits approval and proceeds to the next lifecycle stage.
5. If rejected, the ticket returns to the previous stage with the rejection reason recorded. The approval chain can be restarted later if allowed.
6. Every approval action writes `[Tickets].[ApprovalStepHistory]` and `[dbo].[AuditLog]`.

The chain varies by operational type and service. A simple service request might need only technician and supervisor approval. A disbursement for a high-value item might need the full five-step chain. The configuration page `ApprovalStepConfig` allows administrators to define and modify chains without developer intervention.

### 7.13 Hierarchical Arbitration Model

When two organizational units dispute ticket ownership, the system resolves the dispute at the correct hierarchical level rather than routing to a static arbitrator.

Escalation rules:
- **Section disputes section:** arbitrator sits at the branch level. The arbitrator's DSD is the parent branch's DSDID.
- **Branch disputes branch:** arbitrator sits at the department level. The arbitrator's DSD is the parent department's DSDID.
- **Department disputes department:** arbitrator sits at the Idara level. The arbitrator's DSD is the Idara's own DSDID.

Implementation:
- The arbitrator is a `Distributor` record with a new distributor type linked to the parent org's DSDID. This is an organizational configuration concern, not a schema change.
- When arbitration is requested, `[Tickets].[TicketSP]` determines the correct arbitration level by looking up the org hierarchy for both the requesting DSD and the target DSD, then selecting the lowest common parent.
- `[Tickets].[TicketArbitration]` already carries `ArbitratorDSDID_FK`. In V2, this field is populated with the correct hierarchical arbitrator DSD rather than a statically configured one.
- The arbitrator's decision can reassign the ticket to either disputing unit or to a third unit entirely.

This model replaces the V1 flat arbitration approach where the arbitrator DSD was always taken from the service routing rule. V2 falls back to the routing rule arbitrator when there is no dispute (for example, unknown service routing), but uses hierarchical resolution when the arbitration reason is a cross-unit dispute.

### 7.14 Inter-Technician Clarification Model

Clarification in V2 is not limited to "requester is missing information." Technicians in different organizational units can request input from each other through a formal, traceable workflow.

How it works:
- A technician working on a ticket in DSD-A needs information from a technician in DSD-B.
- The technician creates a clarification request targeting `RequestedFromDSDID_FK = DSD-B` and optionally `RequestedFromUsersID_FK = specific-user`.
- The ticket enters `WAITING_CLARIFICATION` status. SLA pauses if configured.
- The target DSD's queue shows the clarification request. The target technician responds.
- The response is recorded in `[Tickets].[TicketClarification]` with `respondedAt` and `responseText`.
- The original ticket resumes.

Key differences from V1:
- V1 clarification was requester-facing: the ticket's own requester was asked for more information.
- V2 clarification is multi-directional: it can target the requester, another unit, a specific user, or the parent ticket's owner.
- The `clarificationReasonID_FK` values are extended to include cross-unit reasons like `CROSS_UNIT_QUERY`, `TECHNICAL_CONSULTATION`, `RESOURCE_AVAILABILITY_CHECK`.

This model keeps cross-unit communication inside the audit trail instead of relying on phone calls or messaging apps that leave no record.

### 7.15 Parallel Child Model

V2 introduces explicit parallel child spawning with AND-join semantics.

How it works:
1. A parent ticket (for example, a maintenance work order) needs multiple tasks done in parallel.
2. The system creates multiple child tickets simultaneously, each with `ParentTicketID_FK` pointing to the parent.
3. Each child gets its own DSD routing, assignment, SLA, and lifecycle.
4. The parent ticket enters `WAITING_CHILD` status with a `WAITING_CHILD` pause session.
5. As each child reaches a terminal state (resolved, closed, cancelled), the system checks whether all children of the parent are now terminal.
6. When the last child reaches terminal state, the parent's `WAITING_CHILD` status is cleared, the pause session ends, and the parent resumes its normal lifecycle.

Implementation constraints:
- Only AND-join is supported. The parent waits for all children, not any child.
- Children cannot themselves spawn blocking children in V2 (no recursive blocking). A child can have sub-children for tracking purposes, but the parent only blocks on its direct children.
- A child that is cancelled counts as "complete" for AND-join purposes. The parent does not stay waiting because a child was cancelled.
- The parent's SLA accumulates paused time during the blocking period, so the SLA clock is not unfairly consumed by child execution time.

Use cases:
- Building maintenance: parent is the work order, children are electrical, plumbing, painting, HVAC.
- Event preparation: parent is the event request, children are venue setup, catering, security, IT setup.
- Multi-site inspection: parent is the inspection campaign, children are individual site inspections.

### 7.17 Ticket Number Generation

Every ticket receives a human-readable, unique ticket number at creation time. The format is:

```
TKT-YYYY-NNNNNNN
```

Where:
- `TKT` is a fixed prefix
- `YYYY` is the four-digit year
- `NNNNNNN` is a zero-padded sequential number starting from 0000001, reset each year

Example: `TKT-2025-0000142`

**Concurrency-safe generation**:

The `INSERTTICKET` action in `[Tickets].[TicketSP]` generates the ticket number using a SQL Server `SEQUENCE`:

```sql
CREATE SEQUENCE [Tickets].[TicketNoSeq]
    AS INT
    START WITH 1
    INCREMENT BY 1
    NO CACHE;
```

Inside `INSERTTICKET`:
```sql
DECLARE @seqVal INT = NEXT VALUE FOR [Tickets].[TicketNoSeq];
SET @ticketNo = FORMAT(@seqVal, 'TKT-' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-{0:0000000}');
```

Using a `SEQUENCE` with `NO CACHE` ensures that concurrent `INSERTTICKET` calls never produce duplicate numbers. The sequence is not tied to a transaction, so rolled-back inserts will create gaps — this is acceptable and standard practice.

The unique constraint on `ticketNo` (section 11.19) is a safety net, not the primary guard.

## 8. Data Architecture Decisions

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
- Operational type FK: `operationalTypeID_FK`
- Approval step FK: `approvalStepID_FK`

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

### 8.9 OperationalType Decision
- `[Tickets].[OperationalType]` is a lookup table with exactly four seeded rows: `SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`.
- `[Tickets].[Ticket]` gains `operationalTypeID_FK INT NOT NULL` pointing to this table.
- `[Tickets].[Service]` gains `operationalTypeID_FK INT NOT NULL` so that selecting a service automatically determines the operational type.
- The operational type is immutable after ticket creation. It cannot be changed later.
- Each operational type can have different default approval chains, routing rules, and SLA policies.

### 8.10 ApprovalStep Decision
- `[Tickets].[ApprovalStep]` is a master table that stores ordered approval chains.
- A chain is identified by `operationalTypeID_FK` plus optionally `serviceID_FK`. When `serviceID_FK` is null, the chain is the default for that operational type.
- Each row has `stepOrder INT NOT NULL` defining the sequence.
- Each row has `approverRoleTypeID_FK INT NOT NULL` identifying the role (technician, supervisor, branch manager, section manager, department manager).
- Each row optionally has `ApproverDSDID_FK BIGINT NULL` or `ApproverUsersID_FK BIGINT NULL` to pin the step to a specific org unit or person.
- Changes to approval steps write `[Tickets].[ApprovalStepHistory]`.

### 8.11 TicketApproval Decision
- `[Tickets].[TicketApproval]` is a transaction table with one row per approval action per step per ticket.
- Each row carries `approvalStepID_FK`, `TicketID_FK`, `ApproverUsersID_FK`, `approvalDecision` (approved, rejected, returned), `approvalNotes`, and timestamps.
- A ticket in `WAITING_APPROVAL` status has exactly one pending step at a time. Previous steps are recorded as approved rows.
- Rejection at any step is recorded with the rejection reason. The ticket returns to the previous lifecycle stage.
- Approval actions write both local history and central `[dbo].[AuditLog]`.

### 8.12 Hierarchical Arbitration Data Decision
- No new table is needed for hierarchical arbitration. The `[Tickets].[TicketArbitration]` table already carries `ArbitratorDSDID_FK`.
- In V2, the `ArbitratorDSDID_FK` value is computed at runtime by resolving the lowest common parent in the org hierarchy between the two disputing DSDs.
- The arbitrator `Distributor` type is a new distributor classification linked to the parent org's DSDID. This is a data configuration change in `[dbo].[Distributor]`, not a schema change.

### 8.13 AND-Join Child Data Decision
- No new table is needed for the AND-join model. The existing `ParentTicketID_FK` on `[Tickets].[Ticket]` already supports parent-child relationships.
- V2 uses `WAITING_CHILD` (already in the `TicketStatus` seed rows) to represent the parent waiting state.
- V2 adds `WAITING_CHILD` to the `PauseReason` seed rows with `pausesSLA = 1`.
- The AND-join check is enforced in `[Tickets].[TicketSP]`: when a child reaches a terminal state, the procedure counts remaining active children. If zero, the parent's blocking is cleared.

### 8.14 Inter-Technician Clarification Data Decision
- The existing `[Tickets].[TicketClarification]` table already carries `RequestedFromDSDID_FK` and `RequestedFromUsersID_FK`, which are exactly the columns needed for inter-technician clarification.
- V2 extends the `ClarificationReason` seed rows to include cross-unit reasons.
- No schema change is needed. The clarification model already supports the multi-directional workflow; V1 simply did not populate the cross-unit fields.

## 9. External Dependencies

The `[Tickets]` schema assumes these existing objects exist and remain authoritative:

| Object | Purpose in Tickets |
|---|---|
| `[dbo].[Idara]` | mandatory `IdaraID_FK` parent |
| `[dbo].[Department]` | org reference for reporting, derived display, and hierarchical arbitration |
| `[dbo].[Section]` | org reference for reporting, derived display, and hierarchical arbitration |
| `[dbo].[Divison]` | org reference for reporting and derived display |
| `[dbo].[DeptSecDiv]` | routing truth through `DSDID_FK`, org hierarchy for arbitration resolution |
| `[dbo].[Users]` | internal requester, assignee, and approver parent |
| `[dbo].[UsersDetails]` | display name and employee data |
| `[dbo].[Distributor]` | queue / role receiver, arbitrator type for hierarchical arbitration |
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
| `[dbo].[V_GetListUsersInDSD]` | active eligible users by DSD, used for assignment and approval eligibility |
| `[dbo].[V_GetFullStructureForDSD]` | org hierarchy display, reporting, and hierarchical arbitration level resolution |


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
isAutoApproved BIT NOT NULL DEFAULT 0
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


> These sections replace sections 12-15 of the base plan. New and changed items are marked with **[v2]**.

## 12. Stored Procedure Map

### 12.1 `[Tickets].[TicketDL]`

Purpose:
- page data loads for `TicketCreate`, `TicketMyTickets`, `TicketInbox`, `TicketList`, `TicketWorkbench`, `TicketQualityReview`, **[v2]** `TicketApprovals`

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

**[v2]** When `@pageName_ = 'TicketWorkbench'`, additional resultsets return the approval chain status for the ticket being viewed. See section 13.5 for the full resultset map.

### 12.2 `[Tickets].[TicketSP]`

Purpose:
- all ticket lifecycle writes including **[v2]** approval workflow actions

Action groups:
- `INSERTTICKET` **[v2]** updated: validates `operationalTypeID_FK`, loads approval chain from `[Tickets].[ApprovalStep]` if the operational type requires approval, creates `[Tickets].[TicketApproval]` rows, sets initial status to `WAITING_APPROVAL` when approval is needed
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
- `CANCELTICKET`: requester or authorized user cancels the ticket. Sets `ticketStatusID_FK` to `CANCELLED`. Validates that the ticket has not passed a point-of-no-return (e.g., DS-06: disbursement tickets cannot be cancelled after treasury execution step 4). Writes `TicketHistory`, `AuditLog`, closes any open SLA pause session, and sends a notification to assigned technician if one exists.
- `MARKMAJORINCIDENT`
- **[v2]** `REQUESTAPPROVAL`: creates `[Tickets].[TicketApproval]` rows from `[Tickets].[ApprovalStep]` template for the ticket's operational type. Each step gets a row with status `PENDING`. The ticket status moves to `WAITING_APPROVAL` and an SLA pause session starts.
- **[v2]** `APPROVETICKET`: approver approves one `[Tickets].[TicketApproval]` step. The step status moves to `APPROVED`. If all mandatory steps are complete, the ticket advances to `ASSIGNED` and the SLA pause session ends. If further steps remain, the next `PENDING` step becomes actionable and the ticket stays in `WAITING_APPROVAL`.
- **[v2]** `REJECTAPPROVAL`: approver rejects one `[Tickets].[TicketApproval]` step. The step status moves to `REJECTED`. The ticket status moves to `REJECTED`. A notification is sent to the requester with the rejection notes. The SLA pause session ends.
- **[v2]** `UPDATEAPPROVALSTEP`: admin updates the approval chain template in `[Tickets].[ApprovalStep]`. Changes affect new tickets only and do not retroactively modify existing `[Tickets].[TicketApproval]` rows.

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
- **[v2]** approval step template grid

### 12.4 `[Tickets].[ServiceCatalogSP]`

Purpose:
- catalogue, routing, SLA, suggestion, and **[v2]** approval step template writes

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
- **[v2]** `INSERTAPPROVALSTEP`: creates a new approval chain template row in `[Tickets].[ApprovalStep]` for a given operational type. Sets `stepOrder`, `isRequired`, `approverDSDID_FK`, and `approverRole`.
- **[v2]** `UPDATEAPPROVALSTEP`: modifies an existing `[Tickets].[ApprovalStep]` row. Changes take effect on new tickets only.
- **[v2]** `DELETEAPPROVALSTEP`: soft-deletes an `[Tickets].[ApprovalStep]` row. Existing `[Tickets].[TicketApproval]` rows referencing this step are unaffected.

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
- **[v2]** approval bottleneck summary: average time in `WAITING_APPROVAL`, approval rejection rates, approval chain completion rates by operational type

## 13. View / DL Design Map

### 13.1 `TicketCreate`
- Gateway branch calls `[Tickets].[TicketDL]`
- Resultset 1: requester context and any open-ticket warnings
- Resultset 2: services
- Resultset 3: ticket classes
- Resultset 4: impacts
- Resultset 5: urgencies
- Resultset 6: requester types
- **[v2]** Resultset 7: operational types (for operational type selection)

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
- **[v2]** Resultset 8: approval chain steps and their current status (`PENDING`, `APPROVED`, `REJECTED`, `SKIPPED`). Each row shows the step order, the approver DSD, the assigned approver user (if any), the step status, and timestamps for when the step was actioned.
- **[v2]** Resultset 9: pending approval actions available to the current logged-in user. This resultset is empty if the user has no approval authority on this ticket. When populated, it drives the approve/reject buttons on the workbench UI.

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
- **[v2]** Resultset 7: approval step templates, one row per `[Tickets].[ApprovalStep]`, showing the operational type, step order, whether the step is required, and the approver DSD/role

### 13.8 `TicketReports`
- Gateway branch calls `[Tickets].[TicketReportDL]`
- Resultsets are reporting-only and should not be reused for CRUD pages

### 13.9 `TicketApprovals` **[v2]**
- Gateway branch calls `[Tickets].[TicketDL]`
- Resultset 1: pending approvals for the current user's DSD scope. Each row shows the ticket ID, ticket number, title, requester name, operational type, the specific approval step the user can action, when the step was created, and SLA countdown information. Rows are scoped to tickets where the user's DSD matches the `approverDSDID_FK` on the pending `[Tickets].[TicketApproval]` step.
- Resultset 2: approval history. Completed approvals (both `APPROVED` and `REJECTED`) that the current user has actioned, with timestamps and notes. Used for the "my recent decisions" panel on the approvals page.
- Resultset 3: status filter DDL. Allows filtering the pending list by approval status (`PENDING`, `APPROVED`, `REJECTED`, `ALL`).

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

Page values to add exactly:
- `TicketCreate`
- `TicketMyTickets`
- `TicketInbox`
- `TicketList`
- `TicketWorkbench`
- `TicketQualityReview`
- `ServiceCatalog`
- `TicketReports`
- **[v2]** `TicketApprovals`

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
| BR-19 **[v2]** | `operationalTypeID_FK` is required on every ticket. The INSERTTICKET action must reject any ticket that does not specify an operational type. | `[Tickets].[TicketSP]` |
| BR-20 **[v2]** | If `[Tickets].[ApprovalStep]` rows exist for the ticket's operational type, the system must create `[Tickets].[TicketApproval]` rows from the template before the ticket leaves `WAITING_APPROVAL`. INSERTTICKET checks for template steps at creation time. If steps exist, the ticket starts in `WAITING_APPROVAL` with all template steps materialized as pending approval rows and an SLA pause session active. If no steps exist for that operational type, the ticket follows the standard status flow without the approval gate. | `[Tickets].[TicketSP]` |
| BR-21 **[v2]** | All mandatory approval steps (where `isRequired = 1` in `[Tickets].[ApprovalStep]`) must reach `APPROVED` status before the ticket can enter `ASSIGNED` or `IN_PROGRESS`. Optional steps (where `isRequired = 0`) can be skipped without blocking advancement. The `APPROVETICKET` action checks this condition after each approval and advances the ticket only when all mandatory steps are cleared. | `[Tickets].[TicketSP]` |
| BR-22 **[v2]** | `REJECTAPPROVAL` on any mandatory step moves the ticket to `REJECTED` status and notifies the requester with the approver's rejection notes. The SLA pause session ends. A rejected ticket can be reopened through `REOPENTICKET`, which sends it back through the approval chain from the beginning. | `[Tickets].[TicketSP]` |
| BR-23 **[v2]** | Parallel children: when a parent ticket has open child tickets, the parent status is `WAITING_CHILD`. The parent cannot resume normal processing until all children reach a terminal status (`RESOLVED`, `CLOSED`, or `CANCELLED`). When the last child reaches a terminal status, the parent's `PAUSETICKET` session ends, the parent SLA unpauses, and the parent status returns to its pre-wait state. The trigger that detects last-child completion must be atomic to avoid race conditions with concurrent child resolutions. | `[Tickets].[TicketSP]` |
| BR-24 **[v2]** | Inter-technician clarification: when a technician requests clarification from another organizational unit, `RequestedFromDSDID_FK` must be different from the requester's current ticket DSD (`CurrentDSDID_FK`). A clarification request targeting the same DSD as the ticket's current holder is rejected as a self-clarification. | `[Tickets].[TicketSP]` |
| BR-25 **[v2]** | Hierarchical arbitration: when arbitration is needed because two organizational units dispute responsibility, the arbitration level is determined by finding the lowest common parent DSDID of the two disputing org units. The arbitrator DSD must be at or above this common parent level. If the disputing units share no common parent within the `IdaraID` scope, the arbitration defaults to the Idara-level DSD. | `[Tickets].[TicketSP]` |
| BR-26 **[v2]** | **Circular reference prevention**: `CREATECHILDTICKET` must reject any attempt to create a child whose `parentTicketID_FK` creates a cycle. The SP checks by walking up the parent chain (parent → grandparent → root) and rejecting if the proposed child's `ticketID` already appears in that chain. This prevents A→B→A loops. | `[Tickets].[TicketSP]` `CREATECHILDTICKET` |
| BR-27 **[v2]** | **Atomic approval guard**: `APPROVETICKET` must use `UPDATE ... WHERE approvalStatus = 'PENDING'` with `@@ROWCOUNT` verification. If `@@ROWCOUNT = 0`, another approver already acted on this step concurrently. The SP returns a business error: "This approval step has already been actioned by another user." This prevents double-approval race conditions when `ApproverDistributorID_FK` is NULL (any user in DSD can approve). | `[Tickets].[TicketSP]` `APPROVETICKET` |
| BR-28 **[v2]** | **Parent-child completion atomicity**: when the last child ticket reaches a terminal status, the parent status transition from `WAITING_CHILD` must be atomic. The SP uses `UPDATE ... WITH (UPDLOCK, HOLDLOCK)` on the parent ticket row before counting active children. If another concurrent child resolution has already triggered the parent resume, the SP detects `ticketStatusID_FK != WAITING_CHILD` and skips the redundant transition. | `[Tickets].[TicketSP]` |
| BR-29 **[v2]** | **New child during WAITING_CHILD**: while a parent is in `WAITING_CHILD` status, additional children can still be created via `CREATECHILDTICKET`. Each new child resets the parent's "all children complete" check. The SP must re-count active children after any child reaches terminal status, not assume the count is stable. This prevents a race where the last existing child completes, the parent begins resuming, but a new child is created in the same instant. | `[Tickets].[TicketSP]` `CREATECHILDTICKET` |


This section defines the approval chain subsystem for the ITIL 4 ticketing system. Not every ticket requires approval. When approval is required, the system uses a two-table template/instance model to enforce sequential sign-off before work can begin.

## 16.1 How Approval Chains Work

The approval chain uses a template-to-instance pattern. Two tables drive the whole mechanism.

**`[Tickets].[ApprovalStep]`** defines chain templates. Each row describes one approval step in a chain, tied to an operational type and optionally to a specific service. These rows are configured by administrators and rarely change day to day. Think of them as the blueprint.

**`[Tickets].[TicketApproval]`** tracks live approval instances. When a ticket enters the approval flow, the system reads the relevant template rows from `ApprovalStep` and creates one `TicketApproval` row per step. These instance rows carry the actual decision, the approver who acted, timestamps, and comments.

This separation means you can change the template for future tickets without affecting tickets already in flight.

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
  , isAutoApproved        BIT NOT NULL DEFAULT 0
  , approvalStepActive    BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

Key columns:

- `operationalTypeID_FK` links the step to an operational type via FK to `[Tickets].[OperationalType]`.
- `serviceID_FK` is nullable. When null, the step applies to all services under that operational type. When set, the step overrides the generic chain for that specific service.
- `stepOrder` is a 1-based integer. Step 1 must be decided before step 2 can be acted on.
- `ApproverDSDID_FK` identifies the organizational unit that holds the approver.
- `ApproverDistributorID_FK` identifies a specific role within that unit. When null, any active user in the DSD can approve.
- `isRequired` determines whether the step can be skipped. A value of 1 means mandatory. A value of 0 means an authorized user can skip it.
- `isAutoApproved` determines whether the step auto-resolves during `REQUESTAPPROVAL` without human action. When 1, the SP immediately sets `approvalStatus = 'APPROVED'` for this step. This is separate from `isRequired`: a step can be both mandatory AND auto-approved (e.g., a no-cost financial check that must pass but requires no human decision).

Unique constraint: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)` filtered to active rows.

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

Key columns:

- `approvalStatus` tracks the decision: `PENDING`, `APPROVED`, `REJECTED`, or `SKIPPED`.
- `ApproverUsersID_FK` records who made the decision.
- `decidedAt` records when.
- `approvalNotes` carries optional comments from the approver.

Unique constraint: only one row per `(TicketID_FK, stepOrder)`.

## 16.2 Step Ordering and Mandatory/Optional Logic

Steps execute in `stepOrder` sequence. The system enforces this at the SP level.

When a ticket enters the approval flow, `[Tickets].[TicketSP]` does the following:

1. Reads all active `ApprovalStep` rows matching the ticket's `operationalTypeID_FK` and `IdaraID_FK`, considering service-specific overrides first (see section 16.8).
2. Creates one `TicketApproval` row per template step, all with `approvalStatus = 'PENDING'`.
3. Only the first step (`stepOrder = 1`) is immediately actionable. Steps with `stepOrder > 1` remain `PENDING` but cannot be acted on until the preceding step is resolved.

A step is considered resolved when its `approvalStatus` is `APPROVED`, `REJECTED`, or `SKIPPED`.

The mandatory/optional distinction works like this:

- **Mandatory** (`isRequired = 1`): the step must receive an explicit `APPROVED` or `REJECTED` decision. It cannot be skipped.
- **Optional** (`isRequired = 0`): the step can be skipped by an authorized user. When skipped, the system treats it as resolved for ordering purposes and moves to the next step.

If step 2 is optional and step 3 is mandatory, step 3 remains waiting until step 2 is either approved, rejected, or skipped.

## 16.3 Approval Flow (Status Transitions)

The approval flow inserts a dedicated status into the existing ticket lifecycle.

Status sequence:

```
NEW  -->  WAITING_APPROVAL  -->  ASSIGNED  -->  IN_PROGRESS  -->  ...
```

When `[Tickets].[TicketSP]` handles the `INSERTTICKET` action and finds matching approval steps:

1. The ticket is created with `ticketStatusID_FK` pointing to `WAITING_APPROVAL` instead of `NEW` or `ASSIGNED`.
2. `TicketApproval` instance rows are created for every template step.
3. An SLA pause session starts with `pauseReasonID_FK` pointing to `WAITING_APPROVAL` (seeded in section 11.8).

When an approver acts on a step (via a new `APPROVETICKET` action in `TicketSP`):

1. The SP validates that the current step is the lowest unresolved step.
2. The SP validates that the acting user is eligible (see section 16.6).
3. The SP updates the `TicketApproval` row: sets `approvalStatus`, `ApproverUsersID_FK`, `decidedAt`, and `approvalNotes`.
4. The SP writes a `TicketHistory` row recording the approval decision.
5. The SP checks whether all mandatory steps are approved. If yes, the ticket transitions to `ASSIGNED`, the SLA pause session ends, and the ticket enters normal routing.
6. If more steps remain, the ticket stays in `WAITING_APPROVAL` and the next step becomes actionable.

This logic means the ticket never reaches `ASSIGNED` until every mandatory step in the chain is approved.

## 16.4 Rejection Flow

Any mandatory step can reject the ticket.

When an approver sets `approvalStatus = 'REJECTED'` on a mandatory step:

1. The SP immediately transitions the ticket to a rejected state. The ticket status becomes `REJECTED` (a new seed row in `[Tickets].[TicketStatus]`).
2. All remaining `PENDING` steps are set to `SKIPPED` automatically. No further approval actions are needed.
3. The SLA pause session ends.
4. A `TicketHistory` row records the rejection, including which step rejected it and why.
5. A notification is sent to the requester.

A rejected ticket returns to the requester. The requester can then:

- Edit and resubmit, which creates a new ticket (or reopens the same ticket if the business prefers, controlled by SP logic and a `REOPENTICKET`-style action that re-evaluates the approval chain).
- Cancel the ticket.

The rejection does not permanently block the requester. It sends the request back for correction.

Optional steps behave differently. If an optional step is rejected, the system treats it as resolved (similar to a skip) and continues to the next step. Only mandatory step rejections trigger the full rejection flow described above.

## 16.5 SLA Interaction

SLA time pauses during the approval window. This is critical for fair SLA tracking.

When a ticket enters `WAITING_APPROVAL`:

1. `[Tickets].[TicketSP]` creates a `TicketPauseSession` row with `pauseReasonID_FK` pointing to the `WAITING_APPROVAL` pause reason (seeded in section 11.8).
2. `[Tickets].[TicketSLA]` transitions to `slaState = 'PAUSED'`.
3. A `TicketSLAHistory` row records the pause transition.

When the approval chain completes (all mandatory steps approved, ticket moves to `ASSIGNED`):

1. The open `TicketPauseSession` is closed. `endedAt` and `pausedMinutes` are calculated.
2. `totalPausedMinutes` on `TicketSLA` is incremented by the paused duration.
3. Response and resolution due dates are recalculated by adding the paused minutes to the original deadlines.
4. `slaState` returns to `RUNNING`.
5. A `TicketSLAHistory` row records the resume transition.

When a ticket is rejected during approval:

1. The pause session is closed.
2. The SLA row is marked `slaState = 'CLOSED'` (the ticket will not proceed to work).

This approach ensures that time spent waiting for managerial approval does not count against the executor's SLA clock.

## 16.6 Who Can Approve (Eligibility via V_GetListUsersInDSD)

Eligibility is grounded in the existing organizational truth, not in a new permission table.

The SP checks eligibility like this:

1. The approver must be an active user in `ApproverDSDID_FK`. The SP validates this by querying `[dbo].[V_GetListUsersInDSD]` filtered to the DSD.
2. If `ApproverDistributorID_FK` is not null, the user must also hold that specific distributor role in the DSD. The SP validates this by joining through `[dbo].[UserDistributor]`.
3. The approver cannot be the same user who opened the ticket (`OpenedByUsersID_FK`). This prevents self-approval.

The eligibility query pattern:

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

This means the system does not hardcode specific user names into the approval chain. It defines the organizational position, and whoever currently occupies that position can approve.

## 16.7 Seed Data Examples

The following table shows the default approval chain templates seeded per operational type. These are baseline templates. Administrators can add, remove, or reorder steps through the service catalogue administration page.

| Operational Type | Step 1 | Step 2 | Step 3 | Step 4 |
|---|---|---|---|---|
| SERVICE_REQUEST | Supervisor (mandatory) | Branch Manager (mandatory) | Department Manager (mandatory) | -- |
| DISBURSEMENT | Supervisor (mandatory) | Branch Manager (mandatory) | Finance Section (mandatory) | Department Manager (mandatory) |
| EXECUTION | Branch Manager (mandatory) | Department Manager (mandatory) | -- | -- |
| INSPECTION | Section Manager (mandatory) | -- | -- | -- |

In each row, the DSD for each step maps to the corresponding org unit in `[dbo].[DeptSecDiv]`. The role (Supervisor, Branch Manager, etc.) maps to a specific `DistributorID` when the organization wants position-based approval, or is left null when any active user in that DSD can approve.

Seed SQL pattern:

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

The actual DSD and Distributor IDs are resolved at seed time from the live `[dbo].[DeptSecDiv]` and `[dbo].[Distributor]` tables for the target Idara.

## 16.8 Service-Specific Overrides

Some services need a different approval chain than the default for their operational type. The `serviceID_FK` column on `[Tickets].[ApprovalStep]` handles this.

Resolution logic in `[Tickets].[TicketSP]` when building the approval chain for a new ticket:

1. First, check for active `ApprovalStep` rows where `serviceID_FK` matches the ticket's `serviceID_FK` and `operationalTypeID_FK` matches the ticket's operational type.
2. If service-specific rows exist, use those as the chain template. Ignore the generic rows for that operational type.
3. If no service-specific rows exist, fall back to the generic rows where `serviceID_FK IS NULL`.

This means:

- A generic `SERVICE_REQUEST` chain might require Supervisor, Branch Manager, Department Manager.
- A specific service like "Housing Unit Transfer" could override that with just Branch Manager and Housing Director, skipping the supervisor step entirely.
- The override is per service, not per ticket. Once configured, every ticket for that service follows the override chain.

Administrators manage overrides through the `ServiceCatalog` page. The `ServiceCatalogDL` resultset includes the current approval steps for each service. The `ServiceCatalogSP` action `UPDATEAPPROVALSTEP` lets admins add, remove, or reorder steps.

## 16.9 Auto-Approval

If no `ApprovalStep` rows exist for a ticket's operational type (and no service-specific override), the ticket skips the approval flow entirely.

In `[Tickets].[TicketSP]`, the `INSERTTICKET` action checks:

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

Auto-approval means:

- No `TicketApproval` rows are created.
- No SLA pause session starts.
- The ticket follows the normal create-and-route path: `NEW` to `ASSIGNED` based on the routing rule.
- No approval-related history entries are written.

This keeps the system simple for operational types that don't need managerial sign-off. The default state is "no approval required." Approval is an opt-in layer configured by administrators.

## 16.10 New SP Action: APPROVETICKET

The approval flow requires one new action in `[Tickets].[TicketSP]`.

**Action:** `APPROVETICKET`

**Parameters:**
- `@param1` = ticket ID
- `@param2` = step order
- `@param3` = decision (`APPROVED`, `REJECTED`, `SKIPPED`)
- `@param4` = action notes (optional)

**SP logic:**

1. Validate the ticket exists and is in `WAITING_APPROVAL` status.
2. Load the `TicketApproval` row for the given step order.
3. Validate that all lower step orders are already resolved (not `PENDING`).
4. If `decision = 'SKIPPED'`, validate that `isRequired = 0` on that step. Mandatory steps cannot be skipped.
5. Validate the acting user's eligibility via `V_GetListUsersInDSD` (section 16.6).
6. Update the `TicketApproval` row.
7. Write `TicketHistory` and `AuditLog` entries.
8. If `decision = 'REJECTED'` and `isRequired = 1`, reject the ticket (section 16.4).
9. If all mandatory steps are now approved, transition ticket to `ASSIGNED`, end the SLA pause, recalculate deadlines.
10. Return `SELECT 1 AS IsSuccessful, N'...' AS Message_`.

This action is routed through `[dbo].[Masters_CRUD]` under the `TicketWorkbench` page name, permission-checked the same way as all other ticket actions.

## 16.11 TicketStatus Seed Addition

One new status row is needed:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'WAITING_APPROVAL', N'في انتظار الموافقة', 'Waiting for Approval',
     2, 0, 1, 1);
```

Note that `isPauseStatus = 1` so the SLA subsystem recognizes this status as SLA-pausing. The `sortOrder` of 2 places it between `NEW` (1) and `TRIAGED` (3) in the lifecycle sequence.

A second row for the rejection terminal state:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'REJECTED', N'مرفوض', 'Rejected',
     12, 1, 0, 1);
```

`isClosedStatus = 1` because a rejected ticket is a terminal state. It can only leave this state through a `REOPENTICKET` action.

## 16.12 Impact on the Spec-Kit Sequence

The approval chain touches two existing specs and adds a small amount of work:

| Spec | Addition |
|---|---|
| Spec 01 | Seed `WAITING_APPROVAL` and `REJECTED` into `[Tickets].[TicketStatus]`. Seed `WAITING_APPROVAL` into `[Tickets].[PauseReason]` (already listed). |
| Spec 04 | Create `[Tickets].[ApprovalStep]` and `[Tickets].[TicketApproval]` alongside the other transaction tables. |
| Spec 05 | Add `APPROVETICKET` action to `[Tickets].[TicketSP]`. Modify `INSERTTICKET` to check for approval chains. |
| Spec 11 | Add `WAITING_APPROVAL` resultsets to `TicketWorkbench` DL so the UI can render pending approval steps. |

No new spec is needed. The approval chain fits within the existing spec sequence.


> These are new sections added in v2. Section 17 covers hierarchical arbitration design. Section 18 defines four operational ticket types with approval chains, routing rules, SLA expectations, and business rules.

## 17. Hierarchical Arbitration Design

Arbitration handles two scenarios: responsibility disputes between organizational units, and unknown service routing where no catalogue rule matches. The arbitration system walks the `DeptSecDiv` hierarchy upward to find the right decision maker at the right level.

### 17.1 Dispute Escalation Through Org Levels

The organization follows a four-level hierarchy through `[dbo].[DeptSecDiv]`: Section/Division -> Branch -> Department -> Idara. When two units disagree about who owns a ticket, the system finds their lowest common ancestor and assigns an arbitrator at that level.

| Dispute Level | Example | Arbitrator Level |
|---|---|---|
| Two sections within the same branch | Section A and Section B both claim "not ours" | Branch-level arbitrator |
| Two branches within the same department | Branch X and Branch Y dispute routing | Department-level arbitrator |
| Two departments within the same Idara | Department P and Department Q disagree | Idara-level arbitrator |
| Single unit, unknown service | One unit receives a ticket for an unlisted service | Parent-level arbitrator |

The hierarchy traversal uses `[dbo].[V_GetFullStructureForDSD]` to walk from any `DSDID` upward through its parent chain. The lowest common ancestor algorithm works by collecting the full ancestor path for both disputing DSDs, then finding the first shared node starting from the bottom.

### 17.2 Arbitrator Identity

An arbitrator is a row in `[dbo].[Distributor]` with `distributorType_FK = 5`. This is a new value introduced for the ticketing system.

| `distributorType_FK` | Meaning | Usage |
|---|---|---|
| 1 | Org position | Standard queue holder (manager, section head, etc.) |
| 3 | Rank | Rank-based role |
| **5** | **Ticket arbitrator** | Designated dispute resolver for a given DSD |

Each arbitrator row in `Distributor` points to a specific `DSDID_FK` representing the organizational node it serves. For example, a department-level arbitrator has `DSDID_FK` pointing to the department's DSD row. The system locates the correct arbitrator by matching `distributorType_FK = 5` against the target DSD.

Arbitrator rows are created during seeding or through the `ServiceCatalog` admin page. Every organizational level that might need to resolve disputes should have at least one arbitrator distributor row.

### 17.3 Finding the Arbitrator for a Dispute

The procedure `[Tickets].[TicketSP]` handles arbitrator lookup when `REQUESTARBITRATION` is called. The logic follows these steps:

1. **Single-party arbitration** (unknown service): The ticket sits in a unit with no matching catalogue rule. The system reads the ticket's `CurrentDSDID_FK`, walks up one level to its parent DSD, and searches for a `Distributor` row with `distributorType_FK = 5` at that parent.

2. **Two-party arbitration** (responsibility dispute): Two units have both touched the ticket or both been proposed as targets. The system:
   - Collects ancestor chain A for `DSDID_1` using `V_GetFullStructureForDSD`
   - Collects ancestor chain B for `DSDID_2` using `V_GetFullStructureForDSD`
   - Finds the lowest common ancestor DSD
   - Searches for a `Distributor` row with `distributorType_FK = 5` at that ancestor

3. **Fallback**: If no `distributorType_FK = 5` row exists at the common ancestor, walk up one more level and try again. If the top of the hierarchy (Idara level) has no arbitrator, the SP throws a business error (`THROW 50001`) indicating that arbitration configuration is incomplete.

SQL sketch for the common ancestor lookup:

**IMPORTANT**: `DeptSecDiv` does NOT have a self-referencing parent DSD column. The hierarchy is implicit through `DSDLevel` (1=Organization, 2=Idara, 3=Department, 4=Section, 5=Division) and FK columns linking each level to its parent entity. The view `[dbo].[V_GetFullStructureForDSD]` exposes the materialized hierarchy path.

```sql
-- Find the lowest common ancestor DSD using DSDLevel and the hierarchy view.
-- Both DSDs share the same Idara (guaranteed by IdaraID_FK on tickets).

-- Step 1: Get the hierarchy path and level for both disputing DSDs
SELECT @pathA = hierarchyPath, @levelA = DSDLevel
FROM [dbo].[V_GetFullStructureForDSD]
WHERE DSDID = @DSDID_1;

SELECT @pathB = hierarchyPath, @levelB = DSDLevel
FROM [dbo].[V_GetFullStructureForDSD]
WHERE DSDID = @DSDID_2;

-- Step 2: Walk up from the deeper DSD until both are at the same level,
-- then compare. The first matching ancestor is the lowest common parent.
-- If both DSDs are at the same level and share the same parent entity
-- at level-1, that parent is the arbitrator scope.
-- If they diverge at a higher level, arbitration escalates to the
-- Idara-level DSD (DSDLevel = 2) as the fallback arbitrator.
--
-- Example: Section A (level 4) and Section B (level 4) under the same
-- Department (level 3) → Department DSD is the common ancestor.
-- Section A (level 4) under Dept X and Section B (level 4) under Dept Y,
-- both under the same Idara (level 2) → Idara DSD is the common ancestor.
```

### 17.4 Escalation

If an arbitrator at the current level cannot resolve a dispute, the ticket escalates upward:

1. The arbitrator marks the arbitration row with a decision of `ESCALATE` and sets `DecisionTargetDSDID_FK` to the parent DSD.
2. The SP closes the current `TicketArbitration` row (sets `decidedAt`, `DecisionByUsersID_FK`).
3. A new `TicketArbitration` row is created at the parent level with `ArbitratorDSDID_FK` pointing to the parent's arbitrator DSD.
4. The ticket status remains `WAITING_ARBITRATION`.
5. A `TicketHistory` row records the escalation with `historyActionCode = 'ARBITRATION_ESCALATED'`.

Escalation stops at the Idara level. If an Idara-level arbitrator attempts to escalate, the SP rejects the action with a business error. The Idara level is the final escalation point.

The escalation chain is preserved in `[Tickets].[TicketArbitration]` as multiple rows per ticket, each with a different `ArbitratorDSDID_FK`. The `TicketWorkbench` view displays the full escalation history as a timeline.

### 17.5 Arbitration Flow

```
WAITING_ARBITRATION
        |
        v
  Arbitrator reviews ticket
        |
        +---> DECIDE: sets DecisionTargetDSDID_FK
        |         |
        |         v
        |     Ticket re-routed to decided DSD
        |     Status -> ASSIGNED or TRIAGED
        |
        +---> ESCALATE: escalate to parent level
        |         |
        |         v
        |     New TicketArbitration row at parent
        |     Status remains WAITING_ARBITRATION
        |
        +---> REQUEST_CLARIFICATION_FROM_DISPUTANT
                  |
                  v
              Clarification row created
              SLA pauses (if configured)
              Status -> WAITING_CLARIFICATION
              After response -> back to WAITING_ARBITRATION
```

Key data fields on `[Tickets].[TicketArbitration]`:

| Field | Purpose |
|---|---|
| `ArbitratorDSDID_FK` | The DSD where the arbitrator role sits |
| `DecisionTargetDSDID_FK` | Where the ticket goes after the decision. Null while pending, populated on decision |
| `decisionNotes` | The arbitrator's written justification |
| `requestedAt` / `decidedAt` | Timestamps for SLA tracking and aging reports |

### 17.6 Arbitration and SLA Interaction

When a ticket enters `WAITING_ARBITRATION`:

1. `[Tickets].[TicketSP]` starts a `TicketPauseSession` with `pauseReasonID_FK` pointing to the `ARBITRATION` pause reason row.
2. The SLA clock stops accumulating.
3. When arbitration is decided, the pause session ends, `pausedMinutes` is calculated, and the SLA clock resumes.
4. If arbitration escalates, the pause session continues. It does not restart.

### 17.7 Arbitration History Tracking

The existing `[Tickets].[TicketArbitration]` table supports escalation tracking through its natural row-per-event structure:

- Each arbitration attempt is one row.
- Escalation creates a second row for the same `TicketID_FK` with a higher-level `ArbitratorDSDID_FK`.
- The `TicketWorkbench` DL query returns all arbitration rows for a ticket ordered by `requestedAt`, giving the full escalation story.

No schema changes to `TicketArbitration` are needed for escalation support. The existing DDL already has all required columns. The `DECIDEARBITRATION` action in `[Tickets].[TicketSP]` gains escalation logic as a new internal branch.

### 17.8 Arbitration Reason Codes

The seeded rows in `[Tickets].[ArbitrationReason]` cover the common dispute scenarios:

| Code | When Used |
|---|---|
| `UNKNOWN_SERVICE` | No routing rule matches the service. The ticket landed in a default queue and needs manual routing. |
| `WRONG_SCOPE` | The ticket was routed to this unit, but the unit believes the work belongs elsewhere. |
| `CROSS_DEPARTMENT` | Two departments both have a claim on the work and neither will accept it unilaterally. |
| `MANAGER_DECISION_REQUIRED` | The routing is technically clear, but the business decision has political or budget implications that require management input. |

Arbitration reason is required when calling `REQUESTARBITRATION`. It is stored on `TicketArbitration.arbitrationReasonID_FK` and displayed to the arbitrator so they understand the context.

## 18. Operational Ticket Types

The ticketing system supports four operational types, each with its own approval chain length, routing behavior, SLA profile, and access rules. These types map to `operationalTypeID_FK` in `[Tickets].[Ticket]`. They are not just labels. Each type drives different behavior in `[Tickets].[TicketSP]` during `INSERTTICKET`, `REQUESTAPPROVAL`, and `RESOLVETICKET`.

The types differ in three dimensions:

1. **Who can create them** (internal users, residents, or both)
2. **What approval chain they require** before work begins
3. **How SLA clocks are configured** (response-heavy vs. resolution-heavy)

### 18.1 SERVICE_REQUEST (طلب خدمة)

**Description**

A service request is a formal ask from a user or resident for a predefined service from the catalogue. This is the most common ticket type. The requester picks a known service, fills in the description, and the system routes it through approval to the executing team.

Typical examples: "Issue a housing certificate," "Update resident contact information," "Request a maintenance visit for my unit."

**Who Can Create**

- Internal users: yes
- Residents: yes (only services where `[Tickets].[Service].[allowResidentRequest] = 1`)

**Approval Chain (3 steps)**

| Step | Role | Action | Notes |
|---|---|---|---|
| 1 | Requester's direct supervisor | Validate the request is legitimate | Confirms the employee has the right to ask. For residents, this step is auto-approved. |
| 2 | Service unit manager | Confirm the service unit can deliver | Checks capacity, staffing, and whether the request fits the service definition. |
| 3 | Financial reviewer (if applicable) | Approve any cost implication | Auto-approved when the service has no cost flag. Real approval only for paid services. |

Step templates come from `[Tickets].[ApprovalStep]` where `serviceID_FK` matches the selected service. If no specific template exists, the fallback template (null `serviceID_FK`) applies.

**Routing Behavior**

- The ticket routes to `TargetDSDID_FK` from `[Tickets].[ServiceRoutingRule]` matching the selected service and requester type.
- If the service is not found in the catalogue (`serviceID_FK` is null, `otherServiceText` is populated), the ticket routes to arbitration instead.
- After all approvals clear, the ticket moves to `ASSIGNED` and the service unit queue becomes the current owner.

**SLA Expectations**

- Response target: 4 business hours (default, configurable per service and priority in `[Tickets].[ServiceSLAPolicy]`)
- Resolution target: 5 business days (default for P3, configurable)
- SLA clock pauses during approval steps (`WAITING_APPROVAL` pause reason)
- SLA clock pauses during clarification

**Resident Access**

Yes. Residents can submit service requests through the intake form. The resident's `residentInfoID_FK` is stored on the ticket. When a resident creates the ticket, the first approval step (direct supervisor) is auto-approved because there is no supervisor chain for external requesters.

**Type-Specific Business Rules**

| Rule ID | Rule | Enforcement |
|---|---|---|
| SR-01 | `serviceID_FK` is required for service requests. The `otherServiceText` path is not available for this type. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| SR-02 | If `allowResidentRequest = 0` for the selected service and the requester is a resident, the SP rejects with business error. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| SR-03 | Quality review is required before closure (`requiresQualityReview = 1` on the service). | `[Tickets].[TicketSP]` `CLOSETICKET` |
| SR-04 | The first approval step auto-approves when `requesterTypeID_FK` maps to the Resident type. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| SR-05 | If the financial approval step has `isAutoApproved = 1` (no-cost service), it resolves immediately during `REQUESTAPPROVAL` without waiting for a human actor. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |

### 18.2 DISBURSEMENT (طلب صرف)

**Description**

A disbursement request is an internal financial transaction. An employee requests that funds be released, a payment be processed, or a budget allocation be executed. This type has the longest approval chain because it involves financial accountability at multiple levels.

Typical examples: "Disburse housing subsidy for approved applicants," "Process vendor payment for completed maintenance work," "Release emergency housing assistance funds."

**Who Can Create**

- Internal users: yes
- Residents: no

**Approval Chain (4 steps)**

| Step | Role | Action | Notes |
|---|---|---|---|
| 1 | Requester's section head | Validate the business need | Confirms the request is justified within the section's scope. |
| 2 | Department director | Authorize the expenditure | Confirms budget availability and alignment with department plans. |
| 3 | Finance section (budget control) | Verify budget allocation | Checks that funds exist in the correct budget line and that no holds or conflicts block the disbursement. |
| 4 | Finance section (treasury) | Execute the payment | Performs the actual disbursement and records the transaction reference. |

All four steps are serial. Each step must complete before the next one unlocks. Auto-approval is not available for disbursement steps.

**Routing Behavior**

- The ticket routes to the finance section's DSD after the first two approval steps clear.
- Steps 1 and 2 route through the requester's own org hierarchy (section -> department).
- Steps 3 and 4 route to the finance unit identified in the approval template's `approverDSDID_FK`.
- The finance unit must be configured in `[Tickets].[ApprovalStep]` for every disbursement service. If the template is missing the finance DSD, `REQUESTAPPROVAL` fails with a configuration error.

**SLA Expectations**

- Response target: 1 business day (disbursements get fast initial attention)
- Resolution target: 10 business days (longer because of the four-step chain and bank processing time)
- SLA clock pauses during every approval step
- SLA clock pauses during any clarification (financial clarifications are common)
- No SLA pause for arbitration (disputes on disbursements are rare and should be resolved quickly)

**Resident Access**

No. Disbursement is an internal financial process. Residents never create disbursement tickets. If a resident needs a payment, the resident submits a service request, and an internal user creates a linked disbursement ticket as a child.

**Type-Specific Business Rules**

| Rule ID | Rule | Enforcement |
|---|---|---|
| DS-01 | Only internal users can create disbursement tickets. `requesterTypeID_FK` must map to `INTERNAL_USER`. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| DS-02 | `serviceID_FK` is required. The disbursement type does not support "other" services. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| DS-03 | All four approval steps are mandatory (`isRequired = 1`). The `isAutoApproved` flag must be 0 for all disbursement steps — auto-approval is not available for disbursement templates. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| DS-04 | Quality review is always required. `requiresQualityReview` is forced to 1 for disbursement services regardless of the catalogue setting. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| DS-05 | The resolution must include a transaction reference in `resolutionNotes`. The SP validates that `resolutionNotes` is not null and meets a minimum length. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| DS-06 | A disbursement ticket cannot be cancelled after step 4 (treasury execution) begins. Cancellation is only possible before the final step. | `[Tickets].[TicketSP]` cancel logic |

### 18.3 EXECUTION (طلب تنفيذ)

**Description**

An execution request is a work order for a team to perform a physical or technical task. This type has a short approval chain because the work is typically well-defined and the executing team's capacity is the main concern.

Typical examples: "Execute plumbing repair in Building 5, Unit 12," "Install new electrical panel in the maintenance shed," "Paint and prepare Unit 8B for new occupant."

**Who Can Create**

- Internal users: yes
- Residents: no

**Approval Chain (2 steps)**

| Step | Role | Action | Notes |
|---|---|---|---|
| 1 | Requester's section head | Approve the work order | Confirms the task is needed and within scope. |
| 2 | Executing team supervisor | Accept the work into the team's queue | Confirms the team has capacity and the right skills. Can reject if the team is overloaded, which sends the ticket back to step 1 for re-routing. |

Steps are serial. Step 2 cannot start until step 1 completes.

**Routing Behavior**

- The ticket routes to the executing team's DSD after step 1 approval.
- The executing team DSD comes from `[Tickets].[ServiceRoutingRule].[TargetDSDID_FK]` for the selected service.
- If the executing team supervisor rejects at step 2, the ticket returns to the requester's section for re-routing, and a clarification row is created asking the requester to identify an alternative team.
- The ticket stays in `WAITING_APPROVAL` until both steps clear, then moves to `ASSIGNED`.

**SLA Expectations**

- Response target: 2 business hours (fast acknowledgement that the request was received)
- Resolution target: 3 business days (physical work takes less time than financial processing)
- SLA clock pauses during approval
- SLA clock does not pause for clarification unless the clarification reason is `MISSING_DOCUMENT` or `MISSING_APPROVAL` (field visit clarifications should not freeze the clock)

**Resident Access**

No. Execution tickets are internal work orders. Residents who need physical work done submit a service request. The service desk creates an execution ticket as a child linked to the parent service request.

**Type-Specific Business Rules**

| Rule ID | Rule | Enforcement |
|---|---|---|
| EX-01 | Only internal users can create execution tickets. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| EX-02 | `serviceID_FK` is required. Every execution ticket must reference a catalogue service that has a routing rule pointing to the executing team's DSD. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| EX-03 | If the executing team rejects at step 2, the ticket returns to `WAITING_APPROVAL` at step 1 with a clarification row. The clarification target is the requester's DSD. | `[Tickets].[TicketSP]` `REJECTAPPROVAL` |
| EX-04 | Child tickets are allowed (`allowChildTickets = 1` on execution services). A large execution task can be broken into sub-tasks. | Catalogue config |
| EX-05 | Quality review is optional for execution tickets. The default is `requiresQualityReview = 0`, but the service catalogue can override this for high-value execution tasks. | `[Tickets].[Service]` |

### 18.4 INSPECTION (طلب معاينة)

**Description**

An inspection request sends an inspector to verify a condition, assess damage, confirm completion of work, or evaluate a resident's situation. This type has the shortest approval chain and the fastest SLA because inspections are time-sensitive: delays can block other work (like disbursements or executions) that depend on the inspection result.

Typical examples: "Inspect water damage in Unit 3A," "Verify completion of electrical repair in Building 2," "Assess structural condition of Building 9 before renovation," "Pre-occupancy inspection for new housing allocation."

**Who Can Create**

- Internal users: yes
- Residents: yes (only services where `allowResidentRequest = 1`)

**Approval Chain (1 step)**

| Step | Role | Action | Notes |
|---|---|---|---|
| 1 | Inspection team supervisor | Acknowledge and assign an inspector | Confirms the inspection is within scope and assigns it to a specific inspector. This step is more about assignment than approval. The supervisor rarely rejects unless the request is outside the team's mandate. |

The single step is auto-approved if the service's approval template has `isAutoApproved = 1`, which is common for routine inspections. In that case, the ticket skips straight to `ASSIGNED`.

**Routing Behavior**

- The ticket routes directly to the inspection team's DSD from the service routing rule.
- Because the approval chain is short, the ticket often reaches `ASSIGNED` status within hours.
- The inspection team supervisor assigns a specific inspector through `AssignedToUsersID_FK`.
- If the inspection reveals that further work is needed, the inspector creates a child execution ticket linked to this inspection ticket.

**SLA Expectations**

- Response target: 1 business hour (fast assignment is critical)
- Resolution target: 1 business day (the inspection itself should happen quickly)
- SLA clock does not pause for the single approval step (it's too short to matter)
- SLA clock pauses only if the inspection team requests clarification from the requester (e.g., access to the unit is unavailable, resident is not available)
- If the inspection requires a follow-up visit, the inspector resolves this ticket and creates a new inspection ticket linked as a child

**Resident Access**

Yes. Residents can request inspections directly. Common scenarios: a resident notices damage in their unit, a resident disputes the condition assessment of a unit, a resident requests a pre-handover inspection.

When a resident creates the ticket, the approval step auto-approves (same pattern as service requests with resident requesters).

**Type-Specific Business Rules**

| Rule ID | Rule | Enforcement |
|---|---|---|
| IN-01 | Residents can create inspection tickets only for services where `allowResidentRequest = 1`. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| IN-02 | The approval step is auto-approved if the template has `isAutoApproved = 1` (routine inspection). Otherwise, the inspection supervisor must acknowledge within the response SLA window. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| IN-03 | When the inspection is complete, `resolutionNotes` must contain the inspector's findings. The SP validates that `resolutionNotes` is not null. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| IN-04 | Quality review is not required by default for inspections. The inspection result itself serves as the quality artifact. If the service catalogue sets `requiresQualityReview = 1`, the inspection report goes through a second reviewer before final closure. | `[Tickets].[Service]` |
| IN-05 | An inspection ticket can be the parent of execution tickets. When an inspector identifies work that needs doing, they create a child execution ticket from the workbench. The parent inspection ticket enters `WAITING_CHILD` status, pausing its SLA until the execution completes. | `[Tickets].[TicketSP]` `CREATECHILDTICKET` |

### 18.5 Cross-Type Interaction Summary

The four types interact with each other through parent-child relationships:

| Parent Type | Child Type | Scenario |
|---|---|---|
| SERVICE_REQUEST | INSPECTION | A service request triggers an inspection before the service can be delivered. |
| SERVICE_REQUEST | EXECUTION | A service request requires physical work to fulfill the service. |
| SERVICE_REQUEST | DISBURSEMENT | A resident's service request leads to a financial payment, so an internal disbursement ticket is created. |
| INSPECTION | EXECUTION | An inspection reveals work that needs doing. |
| INSPECTION | SERVICE_REQUEST | An inspector determines the resident needs a different service than what was originally requested. |

When a child ticket is created from a parent, the parent enters `WAITING_CHILD` status. The parent's SLA pauses until all children resolve. This applies regardless of the types involved.

All four types share the same `[Tickets].[Ticket]` table, distinguished by `operationalTypeID_FK`. The type drives different approval templates, SLA policies, and SP validation branches, but the underlying data model is unified. This keeps the history, SLA, arbitration, and clarification mechanics consistent across all types.


## 19. Permission Setup Matrix

The ticketing system requires permission entries in the existing permission infrastructure for every page and every action. This section defines the exact entries needed.

### 19.1 Permission Architecture Recap

The existing permission flow:
- `Menu` table defines page names (`menuName_E`)
- `MenuDistributor` links pages to Distributor types
- `Permission` table maps `UsersID_FK` → `menuName_E` access
- `PermissionType` defines action verbs (select, insert, update, delete, etc.)
- `DistributorPermissionType` links a Distributor to allowed PermissionTypes per page
- `ft_UserPagePermissions` returns the first resultset on every page load
- `V_GetListUserPermission` validates write actions in `Masters_CRUD`

### 19.2 Ticket Page Names

All ticket pages use these `menuName_E` values:

| menuName_E | Page Purpose |
|---|---|
| `TicketCreate` | Create new ticket |
| `TicketMyTickets` | View own tickets |
| `TicketInbox` | Queue view for assigned org unit |
| `TicketList` | Management list with filters |
| `TicketWorkbench` | Single ticket detail and actions |
| `TicketQualityReview` | Quality review queue |
| `ServiceCatalog` | Admin: services, routing, SLA, approval steps |
| `TicketApprovals` | Approval queue for approvers |
| `TicketReports` | Dashboard and KPI reports |

### 19.3 Permission Types Required

These `PermissionType` entries must exist or be created:

| permissionTypeName_E | Description | Used On |
|---|---|---|
| `select` | View / read page data | All pages |
| `insert` | Create new records | TicketCreate, ServiceCatalog |
| `update` | Edit existing records | TicketWorkbench, ServiceCatalog, TicketApprovals, TicketQualityReview |
| `delete` | Soft delete records | TicketWorkbench, ServiceCatalog |
| `ASSIGNTICKET` | Assign ticket to a user | TicketInbox, TicketWorkbench |
| `STARTPROGRESS` | Begin working on a ticket | TicketWorkbench |
| `RESOLVETICKET` | Mark ticket as resolved | TicketWorkbench |
| `CLOSETICKET` | Final close after quality review | TicketQualityReview |
| `REQUESTARBITRATION` | Request arbitration for dispute | TicketWorkbench |
| `DECIDEARBITRATION` | Decide arbitration outcome | TicketWorkbench |
| `REQUESTCLARIFICATION` | Request info from requester or technician | TicketWorkbench |
| `RESPONDCLARIFICATION` | Respond to clarification request | TicketWorkbench |
| `CREATECHILDTICKET` | Create child/parallel ticket | TicketWorkbench |
| `PAUSETICKET` | Pause SLA clock | TicketWorkbench |
| `RESUMETICKET` | Resume SLA clock | TicketWorkbench |
| `APPROVETICKET` | Approve an approval step | TicketApprovals |
| `REJECTAPPROVAL` | Reject an approval step | TicketApprovals |
| `REVIEWQUALITY` | Accept/reject/return resolved ticket | TicketQualityReview |
| `INSERTROUTINGRULE` | Add routing rule | ServiceCatalog |
| `UPDATEROUTINGRULE` | Change routing rule | ServiceCatalog |
| `DELETEROUTINGRULE` | Remove routing rule | ServiceCatalog |
| `INSERTSLAPOLICY` | Add SLA policy | ServiceCatalog |
| `UPDATESLAPOLICY` | Change SLA policy | ServiceCatalog |
| `DELETESLAPOLICY` | Remove SLA policy | ServiceCatalog |
| `INSERTAPPROVALSTEP` | Add approval chain step | ServiceCatalog |
| `UPDATEAPPROVALSTEP` | Change approval chain step | ServiceCatalog |
| `DELETEAPPROVALSTEP` | Remove approval chain step | ServiceCatalog |
| `print` | Print ticket or report | TicketWorkbench, TicketReports |
| `export` | Export data to Excel/PDF | TicketList, TicketReports |

### 19.4 Permission Matrix by Page

#### 19.4.1 TicketCreate

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `insert` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.2 TicketMyTickets

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.3 TicketInbox

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | ✅ | ✅ | ✅ | ✅ |
| `ASSIGNTICKET` | — | — | ✅ | ✅ | ✅ |

#### 19.4.4 TicketList

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | — | ✅ | ✅ | ✅ |
| `export` | — | — | ✅ | ✅ | ✅ |

#### 19.4.5 TicketWorkbench

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | ✅ (own) | ✅ (assigned) | ✅ (team) | ✅ (all) | ✅ |
| `update` | — | ✅ | ✅ | ✅ | ✅ |
| `ASSIGNTICKET` | — | — | ✅ | ✅ | ✅ |
| `STARTPROGRESS` | — | ✅ | ✅ | ✅ | ✅ |
| `RESOLVETICKET` | — | ✅ | ✅ | ✅ | ✅ |
| `REQUESTARBITRATION` | — | ✅ | ✅ | ✅ | ✅ |
| `DECIDEARBITRATION` | — | — | ✅ | ✅ | ✅ |
| `REQUESTCLARIFICATION` | — | ✅ | ✅ | ✅ | ✅ |
| `RESPONDCLARIFICATION` | — | ✅ | ✅ | ✅ | ✅ |
| `CREATECHILDTICKET` | — | — | ✅ | ✅ | ✅ |
| `PAUSETICKET` | — | — | ✅ | ✅ | ✅ |
| `RESUMETICKET` | — | — | ✅ | ✅ | ✅ |
| `print` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.6 TicketQualityReview

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | — | — | ✅ | ✅ |
| `REVIEWQUALITY` | — | — | — | ✅ | ✅ |
| `CLOSETICKET` | — | — | — | ✅ | ✅ |

#### 19.4.7 ServiceCatalog

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | — | — | — | ✅ |
| `insert` | — | — | — | — | ✅ |
| `update` | — | — | — | — | ✅ |
| `delete` | — | — | — | — | ✅ |
| `INSERTROUTINGRULE` | — | — | — | — | ✅ |
| `UPDATEROUTINGRULE` | — | — | — | — | ✅ |
| `DELETEROUTINGRULE` | — | — | — | — | ✅ |
| `INSERTSLAPOLICY` | — | — | — | — | ✅ |
| `UPDATESLAPOLICY` | — | — | — | — | ✅ |
| `DELETESLAPOLICY` | — | — | — | — | ✅ |
| `INSERTAPPROVALSTEP` | — | — | — | — | ✅ |
| `UPDATEAPPROVALSTEP` | — | — | — | — | ✅ |
| `DELETEAPPROVALSTEP` | — | — | — | — | ✅ |

#### 19.4.8 TicketApprovals

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | — | ✅ | ✅ | ✅ |
| `APPROVETICKET` | — | — | ✅ | ✅ | ✅ |
| `REJECTAPPROVAL` | — | — | ✅ | ✅ | ✅ |

#### 19.4.9 TicketReports

| PermissionType | Requester | Technician | Supervisor | Manager | Admin |
|---|---|---|---|---|---|
| `select` | — | — | ✅ | ✅ | ✅ |
| `export` | — | — | ✅ | ✅ | ✅ |

### 19.5 Seeding Notes

Permission seeding must create:
1. `Menu` rows for each of the 9 page names
2. `MenuDistributor` rows linking pages to relevant Distributor types
3. `Permission` rows granting `select` to all users who need page access
4. `DistributorPermissionType` rows for each role × action combination above
5. All seeding should be Idara-scoped and repeatable (idempotent)

## 20. Frontend Page Design

All pages follow the Housing `WaitingListByResident` pattern:
- Controller calls `InitPageContext(out redirectResult)` early
- Sets `ControllerName` and `PageName`
- Builds positional parameter arrays
- Calls `MastersServies.GetDataLoadDataSetAsync(...)`
- Uses `SplitDataSet(...)` to get `dt0` (permissions), `dt1` (main data), `dt2+` (DDLs)
- Builds `SmartPageViewModel`, `FormConfig`, `SmartTableDsModel` server-side
- View invokes `SmartRenderer`
- Writes go through `CrudController` → `/crud/insert|update|delete` with `p01..p50`

### 20.0 Form Field Convention (Housing Pattern)

All ticket forms follow the Housing `CrudController` contract. Visible form fields bind as `p01` through `p50`. The controller converts them to `parameter_01` through `parameter_50` before calling `[Tickets].[TicketSP]` or `[Tickets].[ServiceCatalogSP]` via `Masters_CRUD`.

Every ticket form MUST include these hidden fields:

| Hidden Field | Value Source | Purpose |
|---|---|---|
| `pageName_` | Set per page (e.g., `TicketCreate`, `TicketInbox`) | Routes through `Masters_CRUD` to the correct downstream SP |
| `ActionType` | `insert`, `update`, or `delete` | Selects the action branch in the SP |
| `idaraID` | Session `IdaraId` | Organizational scope |
| `entrydata` | Session `usersId` | Acting user identity |
| `hostname` | `Environment.MachineName` or request host | Audit trail |
| `redirectUrl` | URL to return to after action | Post-action navigation |
| `redirectController` | Controller name (e.g., `Tickets`) | Post-action navigation fallback |
| `redirectAction` | Action name (e.g., `TicketInbox`) | Post-action navigation fallback |
| `__RequestVerificationToken` | Anti-forgery token | CSRF protection |

Field mapping for `TicketCreate` form:

| p-field | Semantic Name | SP Parameter | Type |
|---|---|---|---|
| `p01` | operational type | `parameter_01` | INT (operationalTypeID) |
| `p02` | service | `parameter_02` | BIGINT (serviceID, 0 if other) |
| `p03` | ticket title | `parameter_03` | NVARCHAR(200) |
| `p04` | description | `parameter_04` | NVARCHAR(MAX) |
| `p05` | requester type | `parameter_05` | INT (requesterTypeID) |
| `p06` | resident info | `parameter_06` | BIGINT (residentInfoID, NULL if internal) |
| `p07` | impact | `parameter_07` | INT (impactID) |
| `p08` | urgency | `parameter_08` | INT (urgencyID) |
| `p09` | other service text | `parameter_09` | NVARCHAR(500) (NULL if service selected) |
| `p10` | parent ticket ID | `parameter_10` | BIGINT (NULL if not a child) |

Remaining `p11` through `p50` are reserved for future form fields and default to NULL.

### 20.1 TicketCreate

- **Controller**: `TicketsController.TicketCreate`
- **View**: `Views/Tickets/TicketCreate.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: requester context (user info, any open ticket warnings)
  - dt2: services (filtered by requester type and operational type)
  - dt3: ticket classes
  - dt4: impacts
  - dt5: urgencies
  - dt6: requester types
  - dt7: operational types
- **FormConfig fields**:
  - `operationalTypeID_FK` — select (from dt7)
  - `requesterTypeID_FK` — select (from dt6)
  - `serviceID_FK` — select (from dt2, filtered by operational type)
  - `impactID_FK` — select (from dt4)
  - `urgencyID_FK` — select (from dt5)
  - `ticketClassID_FK` — select (from dt3)
  - `ticketTitle` — text (required)
  - `ticketDescription` — textarea (required)
  - `otherServiceText` — text (visible when serviceID_FK is null/other)
  - `residentInfoID_FK` — hidden (set by controller when requester is resident)
  - `UsersID_FK` — hidden (set by controller when requester is internal)
- **Toolbar**: Submit button (gated by `insert` permission)
- **Post**: `/crud/insert` with `pageName_=TicketCreate`, `ActionType=INSERTTICKET`

### 20.2 TicketMyTickets

- **Controller**: `TicketsController.TicketMyTickets`
- **View**: `Views/Tickets/TicketMyTickets.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: requester's tickets (paginated grid)
  - dt2: status filter DDL
  - dt3: priority filter DDL
- **SmartTableDsModel columns**:
  - ticketNo, ticketTitle, serviceName, ticketStatusName_A, ticketPriorityName_A, openedAt, resolvedAt
- **Toolbar**: Create New Ticket button (links to TicketCreate)
- **Filters**: Status, Priority dropdowns

### 20.3 TicketInbox

- **Controller**: `TicketsController.TicketInbox`
- **View**: `Views/Tickets/TicketInbox.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: queue tickets by `CurrentDSDID_FK` (paginated)
  - dt2: eligible assignees from `V_GetListUsersInDSD`
  - dt3: status filter DDL
- **SmartTableDsModel columns**:
  - ticketNo, ticketTitle, requesterName, ticketStatusName_A, ticketPriorityName_A, openedAt, AssignedToUsersID_FK
- **Toolbar**: Assign To Me button (gated by `ASSIGNTICKET`)
- **Row actions**: View (opens TicketWorkbench), Assign (modal with assignee dropdown from dt2)

### 20.4 TicketList

- **Controller**: `TicketsController.TicketList`
- **View**: `Views/Tickets/TicketList.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: management ticket list (scoped by permission and Idara)
  - dt2: status filter DDL
  - dt3: class filter DDL
  - dt4: priority filter DDL
  - dt5: org filter DDL from `V_GetFullStructureForDSD`
- **SmartTableDsModel columns**:
  - ticketNo, ticketTitle, requesterName, currentDSDName, assigneeName, statusName, priorityName, openedAt, resolvedAt, operationalTypeName_A
- **Toolbar**: Export button (gated by `export` permission)
- **Filters**: Status, Class, Priority, Org Unit dropdowns

### 20.5 TicketWorkbench

- **Controller**: `TicketsController.TicketWorkbench`
- **View**: `Views/Tickets/TicketWorkbench.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: ticket header (single row)
  - dt2: history timeline (from TicketHistory)
  - dt3: active arbitration rows
  - dt4: active clarification rows
  - dt5: child tickets list
  - dt6: SLA row
  - dt7: assignee/DSD action lookups
  - dt8: approval chain steps with status (PENDING/APPROVED/REJECTED/SKIPPED)
  - dt9: pending approval actions available to current user
- **FormConfig** (for edit actions):
  - `resolutionTypeID_FK` — select (for resolve action)
  - `resolutionNotes` — textarea (for resolve action)
  - `clarificationReasonID_FK` — select (for clarification action)
  - `requestText` — textarea (for clarification action)
  - `arbitrationReasonID_FK` — select (for arbitration action)
  - `TargetDSDID_FK` — select (for reassign action, from dt7)
  - `TargetUsersID_FK` — select (for assign action, from dt7)
- **Toolbar** (permission-gated buttons):
  - Start Progress (`STARTPROGRESS`)
  - Request Arbitration (`REQUESTARBITRATION`)
  - Request Clarification (`REQUESTCLARIFICATION`)
  - Create Child Ticket (`CREATECHILDTICKET`)
  - Pause SLA (`PAUSETICKET`)
  - Resolve (`RESOLVETICKET`)
  - Assign (`ASSIGNTICKET`)
  - Print (`print`)
- **Modals**:
  - Assign modal (select user from eligible list)
  - Resolve modal (resolution type + notes)
  - Clarification modal (reason + text)
  - Arbitration modal (reason + notes)
  - Create Child modal (operational type + description)
- **Timeline section**: renders from dt2 (TicketHistory) showing all status changes, assignments, approvals, clarifications, arbitrations

### 20.6 TicketQualityReview

- **Controller**: `TicketsController.TicketQualityReview`
- **View**: `Views/Tickets/TicketQualityReview.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: resolved tickets waiting for quality review
  - dt2: review result lookup (APPROVED, RETURNED, REJECTED)
  - dt3: priority/status stats for reviewer dashboard cards
- **SmartTableDsModel columns**:
  - ticketNo, ticketTitle, resolverName, resolvedAt, ticketPriorityName_A, operationalTypeName_A
- **Toolbar**: (none — actions are row-level)
- **Row actions**: Review (opens modal with review result dropdown + notes)

### 20.7 ServiceCatalog

- **Controller**: `TicketsController.ServiceCatalog`
- **View**: `Views/Tickets/ServiceCatalog.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: services grid
  - dt2: routing rules grid
  - dt3: SLA policies grid
  - dt4: service categories
  - dt5: DSD lookups
  - dt6: catalogue suggestions
  - dt7: approval step templates grid
- **SmartTableDsModel** (3 tables, tabbed):
  - Tab 1 Services: serviceCode, serviceName_A, categoryName, operationalTypeName, allowResidentRequest, allowInternalRequest, requiresQualityReview, active
  - Tab 2 Routing Rules: serviceName, targetDSDName, arbitratorDSDName, rulePriority, effectiveFrom, active
  - Tab 3 SLA Policies: serviceName, priorityName, responseTargetMinutes, resolutionTargetMinutes, effectiveFrom, active
  - Tab 4 Approval Steps: operationalTypeName, serviceName (nullable), stepOrder, stepName_A, approverDSDName, isRequired, active
- **Toolbar**: Add Service, Add Routing Rule, Add SLA Policy, Add Approval Step (all gated by corresponding `insert` permissions)
- **Modals**:
  - Service modal (full service fields)
  - Routing Rule modal (service, DSD, arbitrator DSD)
  - SLA Policy modal (service, priority, targets)
  - Approval Step modal (operational type, service, step order, approver DSD, isRequired)

### 20.8 TicketApprovals

- **Controller**: `TicketsController.TicketApprovals`
- **View**: `Views/Tickets/TicketApprovals.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: pending approvals for current user's DSD scope
  - dt2: approval history (completed approvals)
  - dt3: status filter DDL
- **SmartTableDsModel columns**:
  - ticketNo, ticketTitle, operationalTypeName_A, stepOrder, stepName_A, requesterName, openedAt, approvalStatus
- **Toolbar**: (none — actions are row-level)
- **Row actions**:
  - Approve (gated by `APPROVETICKET`, posts with ActionType=APPROVETICKET)
  - Reject (gated by `REJECTAPPROVAL`, opens modal with rejection notes, posts with ActionType=REJECTAPPROVAL)

### 20.9 TicketReports

- **Controller**: `TicketsController.TicketReports`
- **View**: `Views/Tickets/TicketReports.cshtml`
- **Resultsets**:
  - dt0: permissions
  - dt1: KPI summary (total open, avg resolution time, SLA breach rate, etc.)
  - dt2: backlog by status
  - dt3: backlog by DSD
  - dt4: SLA breach summary
  - dt5: major incident summary
  - dt6: clarification aging
  - dt7: arbitration aging
  - dt8: approval bottleneck summary
  - dt9: catalogue suggestion volume
- **UI layout**:
  - Top row: KPI cards from dt1
  - Grid section: SmartTableDsModel tables for each breakdown (dt2-dt9)
- **Toolbar**: Export button (gated by `export` permission)
- **Filters**: Date range (parameter_01, parameter_02), Org unit (parameter_03)


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
| Spec 13 | Create approval tables `[Tickets].[ApprovalStep]`, `[Tickets].[TicketApproval]`, `[Tickets].[ApprovalStepHistory]`; add `REQUESTAPPROVAL`, `APPROVETICKET`, `REJECTAPPROVAL` actions to `[Tickets].[TicketSP]` | Spec 04, Spec 05 |
| Spec 14 | Create `TicketApprovals` DL resultsets and gateway branch; add `TicketApprovals` page to MVC controller surface with queue view, pending/completed filters, and per-step approve/reject actions | Spec 13, Spec 11 |
| Spec 15 | Seed approval step templates per service catalogue entry; seed operational type lookup rows (`Incident`, `ServiceRequest`, `Problem`, `ChangeRequest`); seed permission rows for all ticket page names into `[dbo].[Permission]` and `[dbo].[PermissionType]` | Spec 01, Spec 02, Spec 13 |

### 21.1 Approval Table Specs (Spec 13)

**`[Tickets].[ApprovalStep]`** defines the approval chain template for a given operational type and optionally a specific service:

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
isAutoApproved BIT NOT NULL DEFAULT 0
approvalStepActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

Constraints: unique filtered on `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)` where active. When `serviceID_FK` is null the step applies as a fallback to all services under that operational type.

**`[Tickets].[TicketApproval]`** tracks the live approval instances for a specific ticket:

```sql
ticketApprovalID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
approvalStepID_FK BIGINT NOT NULL FK -> [Tickets].[ApprovalStep].[approvalStepID]
stepOrder INT NOT NULL
ApproverDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ApproverDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
isRequired BIT NOT NULL DEFAULT 1
approvalStatus NVARCHAR(50) NOT NULL
ApproverUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
approvalNotes NVARCHAR(MAX) NULL
requestedAt DATETIME NOT NULL
decidedAt DATETIME NULL
ticketApprovalActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

Constraints: `approvalStatus` controlled values are `PENDING`, `APPROVED`, `REJECTED`, `SKIPPED`. Unique: only one row per `(TicketID_FK, stepOrder)`. Steps execute in `stepOrder` sequence — only the lowest unresolved step is actionable at any time.

**`[Tickets].[ApprovalStepHistory]`** is the append-only audit trail for approval chain template changes:

```sql
approvalStepHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
approvalStepID_FK BIGINT NOT NULL FK -> [Tickets].[ApprovalStep].[approvalStepID]
fieldName NVARCHAR(100) NOT NULL
oldValue NVARCHAR(MAX) NULL
newValue NVARCHAR(MAX) NULL
changedBy NVARCHAR(100) NOT NULL
changedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

**NOTE**: Section 21.1 DDL must match sections 11.18 and 16.1 EXACTLY. Those are the canonical definitions. This section is a spec summary that must not introduce new columns or rename existing ones.

### 21.2 TicketApprovals Page Spec (Spec 14)

The `TicketApprovals` page follows the Housing pattern exactly:

- Controller: `TicketsController.TicketApprovals`
- Gateway read branch: `@pageName_ = 'TicketApprovals'` routes to `[Tickets].[TicketDL]`
- Resultset 0: permissions from `[dbo].[ft_UserPagePermissions]`
- Resultset 1: pending approval steps assigned to the current user's DSD scope
- Resultset 2: completed approval history for context
- Resultset 3: approval result lookup DDL
- Gateway write branch: `@pageName_ = 'TicketApprovals'` in `[dbo].[Masters_CRUD]` with permission check, then calls `[Tickets].[TicketSP]` with `APPROVETICKET` or `REJECTAPPROVAL`
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

TicketClass seeding adds the following rows if they do not already exist: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`. These are the three ITIL 4 ticket classes. The four operational types (`SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`) are seeded separately into `[Tickets].[OperationalType]`.

Approval step template seeding creates default single-step approval templates for high-priority services and a fallback template (null `serviceID_FK`) that applies to any ticket without a specific template. The fallback uses the ticket's current `CurrentDSDID_FK` department head as the approver.

## 22. Testing Strategy

### 22.1 Database DDL Validation
- create all tables in a disposable database
- validate PK, FK, identity, and nullability rules
- validate no table is missing `IdaraID_FK`, `entryDate`, `entryData`, or `hostName`
- validate approval tables have correct FK chains: `TicketApproval` -> `ApprovalStep`, `ApprovalStepHistory` -> `TicketApproval`

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
- approval actions write both `[Tickets].[ApprovalStepHistory]` and `[dbo].[AuditLog]`

### 22.7 Approval Workflow Tests
- `REQUESTAPPROVAL` creates approval step rows from `[Tickets].[ApprovalStep]`
- single-step approval: `APPROVETICKET` marks the step approved and advances the ticket status
- multi-step serial approval: second step remains pending until first step is approved
- `REJECTAPPROVAL` marks the step rejected, writes log, and returns the ticket to the previous routing DSD
- approval by unauthorized user (wrong DSD) is rejected with permission error
- approval on a ticket that is not in an approval-eligible status is rejected with business error
- auto-approved steps (`isAutoApproved = 1`) skip to `APPROVED` immediately during `REQUESTAPPROVAL`

### 22.8 Operational Type Tests
- `SERVICE_REQUEST` operational type is selectable on `TicketCreate` when permitted
- all four operational types require approval before assignment (when ApprovalStep rows exist), enforced by `INSERTTICKET` SP logic
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
2. seed lookup data (including ticket classes and operational types)
3. create master tables
4. create approval template table `[Tickets].[ApprovalStep]`
5. create transaction and history tables
6. create approval live tables `[Tickets].[TicketApproval]`, `[Tickets].[ApprovalStepHistory]`
7. create downstream `[Tickets]` procedures
8. add gateway branches in `[dbo].[Masters_DataLoad]` and `[dbo].[Masters_CRUD]`
9. seed approval step templates for existing services and fallback template
10. seed operational type rows (`SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`) into `[Tickets].[OperationalType]`
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
- operational types are seeded into `[Tickets].[OperationalType]` and visible on the intake form

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
- `TicketApprovals` follows the same Housing controller pattern: `InitPageContext`, read session fields, build parameters, call `GetDataLoadDataSetAsync`, split resultsets, build `SmartPageViewModel`, render through `SmartRenderer`. The approve/reject actions post through `CrudController` using `pageName_ = 'TicketApprovals'` and `ActionType` of `APPROVETICKET` or `REJECTAPPROVAL`.
- Permission seeding must complete before controllers go live. Without seeded rows in `[dbo].[Permission]` and `[dbo].[PermissionType]`, every ticket page will return zero permissions and the UI will render as read-only or blank. Verify seeding by checking `ft_UserPagePermissions` returns at least one row per ticket page name for a test user after deployment.
- The `TicketApprovals` page name must be added to the permission seeding script and menu configuration. If this page name is missing from `[dbo].[Permission]`, the gateway will reject all read and write attempts for the approval workflow.

## 25. Support Schema Clarification
The existing `[support]` schema is explicitly out of scope for this design.

`[support].[Ticket]`, `[support].[TicketType]`, `[support].[TicketPriority]`, `[support].[TicketStatus]`, `[support].[TicketReply]`, `[support].[TicketAttachment]`, `[support].[TicketTask]`, `[support].[TeamMember]`, and `[support].[TeamMemberRole]` remain the internal website bug-tracking solution for the dev team.

This plan does not merge, rename, extend, or depend on those `[support]` objects. The ITIL 4 ticketing system in this document is a separate business solution implemented only under `[Tickets]` and routed only through the existing Housing-style gateway architecture.

