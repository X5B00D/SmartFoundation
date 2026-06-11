# ITIL 4 Ticketing System Plan v2: Sections 12-15

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
