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
