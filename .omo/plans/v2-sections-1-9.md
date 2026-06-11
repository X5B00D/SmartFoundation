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

**Parallel children with AND-join.** A parent ticket can now spawn multiple children simultaneously. The parent enters a `BLOCKED` status and stays there until every child reaches a terminal state (resolved, closed, or cancelled). This is an AND-join: all children must complete before the parent can resume. The V1 parent-child model already existed, but V2 makes the blocking semantics explicit and adds the `WAITING_CHILD` pause reason as a first-class concept.

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
- AND-join parent-child semantics: parent enters `BLOCKED` status, resumes only when all children reach terminal state
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
16. **AND-join is the only parent-child blocking model.** When a parent spawns parallel children, the parent is blocked until every child completes. There is no partial or OR-join behavior.
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
- V2 adds AND-join blocking: parent is `BLOCKED` until all children reach terminal state.

### 6.5 Continual Improvement
- "Other" tickets can produce structured rows in `[Tickets].[ServiceCatalogSuggestion]`.
- Suggestions are reviewable and can be converted into catalogue entries through `[Tickets].[ServiceCatalogSP]`.

### 6.6 Monitoring and Event Management
- V1 reporting is view/DL driven through `[Tickets].[TicketReportDL]` and gateway `TicketReports`.
- Dashboards cover backlog, SLA breach risk, quality review queue, routing errors, clarification aging, major incidents, approval pipeline status, and blocked parents.

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
- V2 adds AND-join blocking: when a parent spawns multiple children simultaneously, the parent enters `BLOCKED` status.
- The parent stays `BLOCKED` until every child reaches a terminal state (resolved, closed, or cancelled).
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
4. The parent ticket enters `BLOCKED` status with a `WAITING_CHILD` pause session.
5. As each child reaches a terminal state (resolved, closed, cancelled), the system checks whether all children of the parent are now terminal.
6. When the last child reaches terminal state, the parent's `BLOCKED` status is cleared, the `WAITING_CHILD` pause session ends, and the parent resumes its normal lifecycle.

Implementation constraints:
- Only AND-join is supported. The parent waits for all children, not any child.
- Children cannot themselves spawn blocking children in V2 (no recursive blocking). A child can have sub-children for tracking purposes, but the parent only blocks on its direct children.
- A child that is cancelled counts as "complete" for AND-join purposes. The parent does not stay blocked because a child was cancelled.
- The parent's SLA accumulates paused time during the blocking period, so the SLA clock is not unfairly consumed by child execution time.

Use cases:
- Building maintenance: parent is the work order, children are electrical, plumbing, painting, HVAC.
- Event preparation: parent is the event request, children are venue setup, catering, security, IT setup.
- Multi-site inspection: parent is the inspection campaign, children are individual site inspections.

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
- V2 adds `BLOCKED` to the `TicketStatus` seed rows to represent the parent waiting state.
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
