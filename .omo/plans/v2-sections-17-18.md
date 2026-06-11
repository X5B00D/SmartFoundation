# ITIL 4 Ticketing System Plan v2: Sections 17-18

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

```sql
-- Build ancestor paths for two DSDs, find lowest common ancestor
;WITH AncestorsA AS (
    SELECT DSDID, ParentDSDID, 0 AS Level_
    FROM dbo.DeptSecDiv WHERE DSDID = @DSDID_1
    UNION ALL
    SELECT d.DSDID, d.ParentDSDID, a.Level_ + 1
    FROM dbo.DeptSecDiv d
    JOIN AncestorsA a ON d.DSDID = a.ParentDSDID
),
AncestorsB AS (
    SELECT DSDID, ParentDSDID, 0 AS Level_
    FROM dbo.DeptSecDiv WHERE DSDID = @DSDID_2
    UNION ALL
    SELECT d.DSDID, d.ParentDSDID, b.Level_ + 1
    FROM dbo.DeptSecDiv d
    JOIN AncestorsB b ON d.DSDID = b.ParentDSDID
)
SELECT TOP 1 a.DSDID AS CommonAncestorDSDID
FROM AncestorsA a
INNER JOIN AncestorsB b ON a.DSDID = b.DSDID
ORDER BY a.Level_ ASC;
```

### 17.4 Escalation

If an arbitrator at the current level cannot resolve a dispute, the ticket escalates upward:

1. The arbitrator marks the arbitration row with a decision of `ESCALATE` and sets `DecisionTargetDSDID_FK` to the parent DSD.
2. The SP closes the current `TicketArbitration` row (sets `decidedAt`, `DecisionByUsersID_FK`).
3. A new `TicketArbitration` row is created at the parent level with `ArbitratorDSDID_FK` pointing to the parent's arbitrator DSD.
4. The ticket status remains `WAITING_ARBITRATION`.
5. A `TicketHistory` row records the escalation with `historyActionCode = 'ARBITRATION_ESCALATED'`.

Escalation is blocked at the Idara level. If an Idara-level arbitrator attempts to escalate, the SP rejects the action with a business error. The Idara level is the final escalation point.

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

The ticketing system supports four operational types, each with its own approval chain length, routing behavior, SLA profile, and access rules. These types map to `ticketClassID_FK` in `[Tickets].[Ticket]`. They are not just labels. Each type drives different behavior in `[Tickets].[TicketSP]` during `INSERTTICKET`, `SUBMITAPPROVAL`, and `RESOLVETICKET`.

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

Step templates come from `[Tickets].[ApprovalStepTemplate]` where `serviceID_FK` matches the selected service. If no specific template exists, the fallback template (null `serviceID_FK`) applies.

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
| SR-04 | The first approval step auto-approves when `requesterTypeID_FK` maps to the Resident type. | `[Tickets].[TicketSP]` `SUBMITAPPROVAL` |
| SR-05 | If the financial approval step's `isAutoApproved = 1`, it resolves immediately during `SUBMITAPPROVAL` without waiting for a human actor. | `[Tickets].[TicketSP]` `SUBMITAPPROVAL` |

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
- The finance unit must be configured in `[Tickets].[ApprovalStepTemplate]` for every disbursement service. If the template is missing the finance DSD, `SUBMITAPPROVAL` fails with a configuration error.

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
| DS-03 | All four approval steps are mandatory. Auto-approval (`isAutoApproved = 1`) is rejected for disbursement templates. | `[Tickets].[TicketSP]` `SUBMITAPPROVAL` |
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
| EX-03 | If the executing team rejects at step 2, the ticket returns to `WAITING_APPROVAL` at step 1 with a clarification row. The clarification target is the requester's DSD. | `[Tickets].[TicketSP]` `REJECTSTEP` |
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
- SLA clock pauses only if the inspection team requests clarification from the requester (e.g., access to the unit is blocked, resident is not available)
- If the inspection requires a follow-up visit, the inspector resolves this ticket and creates a new inspection ticket linked as a child

**Resident Access**

Yes. Residents can request inspections directly. Common scenarios: a resident notices damage in their unit, a resident disputes the condition assessment of a unit, a resident requests a pre-handover inspection.

When a resident creates the ticket, the approval step auto-approves (same pattern as service requests with resident requesters).

**Type-Specific Business Rules**

| Rule ID | Rule | Enforcement |
|---|---|---|
| IN-01 | Residents can create inspection tickets only for services where `allowResidentRequest = 1`. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| IN-02 | The approval step is auto-approved if the template has `isAutoApproved = 1`. Otherwise, the inspection supervisor must acknowledge within the response SLA window. | `[Tickets].[TicketSP]` `SUBMITAPPROVAL` |
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

All four types share the same `[Tickets].[Ticket]` table, distinguished by `ticketClassID_FK`. The type drives different approval templates, SLA policies, and SP validation branches, but the underlying data model is unified. This keeps the history, SLA, arbitration, and clarification mechanics consistent across all types.
