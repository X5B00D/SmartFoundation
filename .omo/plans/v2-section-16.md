# Section 16: Approval Chain Design

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
  , operationalTypeCode   NVARCHAR(50)  NOT NULL
  , serviceID_FK          BIGINT NULL FOREIGN KEY REFERENCES [Tickets].[Service].[serviceID]
  , stepOrder             INT NOT NULL
  , ApproverDSDID_FK      BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[DeptSecDiv].[DSDID]
  , ApproverDistributorID_FK BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Distributor].[distributorID]
  , isRequired            BIT NOT NULL
  , approvalStepActive    BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

Key columns:

- `operationalTypeCode` links the step to an operational type: `SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`. This matches the ticket class or a more granular operational category.
- `serviceID_FK` is nullable. When null, the step applies to all services under that operational type. When set, the step overrides the generic chain for that specific service.
- `stepOrder` is a 1-based integer. Step 1 must be decided before step 2 can be acted on.
- `ApproverDSDID_FK` identifies the organizational unit that holds the approver.
- `ApproverDistributorID_FK` identifies a specific role within that unit. When null, any active user in the DSD can approve.
- `isRequired` determines whether the step can be skipped. A value of 1 means mandatory. A value of 0 means an authorized user can skip it.

Unique constraint: `(IdaraID_FK, operationalTypeCode, serviceID_FK, stepOrder)` filtered to active rows.

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
  , isRequired            BIT NOT NULL
  , approvalStatus        NVARCHAR(50) NOT NULL
  , ActionedByUsersID_FK  BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Users].[usersID]
  , actionNotes           NVARCHAR(MAX) NULL
  , actionedAt            DATETIME NULL
  , ticketApprovalActive  BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

Key columns:

- `approvalStatus` tracks the decision: `PENDING`, `APPROVED`, `REJECTED`, or `SKIPPED`.
- `ActionedByUsersID_FK` records who made the decision.
- `actionedAt` records when.
- `actionNotes` carries optional comments from the approver.

Unique constraint: only one row per `(TicketID_FK, stepOrder)`.

## 16.2 Step Ordering and Mandatory/Optional Logic

Steps execute in `stepOrder` sequence. The system enforces this at the SP level.

When a ticket enters the approval flow, `[Tickets].[TicketSP]` does the following:

1. Reads all active `ApprovalStep` rows matching the ticket's `operationalTypeCode` and `IdaraID_FK`, considering service-specific overrides first (see section 16.8).
2. Creates one `TicketApproval` row per template step, all with `approvalStatus = 'PENDING'`.
3. Only the first step (`stepOrder = 1`) is immediately actionable. Steps with `stepOrder > 1` remain `PENDING` but cannot be acted on until the preceding step is resolved.

A step is considered resolved when its `approvalStatus` is `APPROVED`, `REJECTED`, or `SKIPPED`.

The mandatory/optional distinction works like this:

- **Mandatory** (`isRequired = 1`): the step must receive an explicit `APPROVED` or `REJECTED` decision. It cannot be skipped.
- **Optional** (`isRequired = 0`): the step can be skipped by an authorized user. When skipped, the system treats it as resolved for ordering purposes and moves to the next step.

If step 2 is optional and step 3 is mandatory, step 3 remains blocked until step 2 is either approved, rejected, or skipped.

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

When an approver acts on a step (via a new `APPROVESTEP` action in `TicketSP`):

1. The SP validates that the current step is the lowest unresolved step.
2. The SP validates that the acting user is eligible (see section 16.6).
3. The SP updates the `TicketApproval` row: sets `approvalStatus`, `ActionedByUsersID_FK`, `actionedAt`, and `actionNotes`.
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
    (IdaraID_FK, operationalTypeCode, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'SERVICE_REQUEST', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 3, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeCode, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'DISBURSEMENT', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 3, @financeDSDID, @financeDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 4, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeCode, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'EXECUTION', NULL, 1, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'EXECUTION', NULL, 2, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeCode, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'INSPECTION', NULL, 1, @sectionMgrDSDID, @sectionMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);
```

The actual DSD and Distributor IDs are resolved at seed time from the live `[dbo].[DeptSecDiv]` and `[dbo].[Distributor]` tables for the target Idara.

## 16.8 Service-Specific Overrides

Some services need a different approval chain than the default for their operational type. The `serviceID_FK` column on `[Tickets].[ApprovalStep]` handles this.

Resolution logic in `[Tickets].[TicketSP]` when building the approval chain for a new ticket:

1. First, check for active `ApprovalStep` rows where `serviceID_FK` matches the ticket's `serviceID_FK` and `operationalTypeCode` matches the ticket's operational type.
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
      AND operationalTypeCode = @operationalTypeCode
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

## 16.10 New SP Action: APPROVESTEP

The approval flow requires one new action in `[Tickets].[TicketSP]`.

**Action:** `APPROVESTEP`

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
| Spec 05 | Add `APPROVESTEP` action to `[Tickets].[TicketSP]`. Modify `INSERTTICKET` to check for approval chains. |
| Spec 11 | Add `WAITING_APPROVAL` resultsets to `TicketWorkbench` DL so the UI can render pending approval steps. |

No new spec is needed. The approval chain fits within the existing spec sequence.
