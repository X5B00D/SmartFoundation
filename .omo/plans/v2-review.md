# plan-v2.md Cross-Section Consistency Review

**Reviewed:** 2026-06-11
**Document:** `plan-v2.md` (2933 lines, sections 1-25)
**Verdict:** **NEEDS FIXES** - 12 critical, 7 minor, 4 style issues

---

## CRITICAL Issues

### C-01. Three competing approval table schemas (Sections 4/10/11 vs 16 vs 21)

Three different agents defined approval tables with different names, DDLs, and column sets. No implementation can satisfy all three.

**Schema A** (Sections 4, 7.12, 8.10, 10, 11.18, 11.26):
- `[Tickets].[ApprovalStep]` - master, keyed by `operationalTypeID_FK`
- `[Tickets].[TicketApproval]` - transaction
- `[Tickets].[ApprovalStepHistory]` - history (listed in sec 4, 7.12, 8.10 but missing from sec 10.4)

**Schema B** (Section 16.1):
- `[Tickets].[ApprovalStep]` - master, keyed by `operationalTypeCode NVARCHAR(50)` (no FK)
- `[Tickets].[TicketApproval]` - transaction, different column names than Schema A
- No history table defined (ApprovalStepHistory not mentioned in section 16)

**Schema C** (Section 21.1):
- `[Tickets].[ApprovalStepTemplate]` - master, keyed by `ticketClassID_FK` (wrong concept)
- `[Tickets].[TicketApprovalStep]` - transaction (different name)
- `[Tickets].[TicketApprovalLog]` - history (different name)

**Fix:** Pick one schema. Schema A is the most widely referenced (sections 1-15, 19). Rewrite sections 16 and 21 to align, or rewrite sections 1-15 to match whichever schema the team prefers.

---

### C-02. Three different SP action naming conventions for approval

The document defines approval actions under three incompatible naming schemes.

**Convention A** (Section 12.2, Section 19.3, Section 20.8):
- `REQUESTAPPROVAL` - initiate approval chain
- `APPROVETICKET` - approve a step
- `REJECTAPPROVAL` - reject a step
- `UPDATEAPPROVALSTEP` - modify template

**Convention B** (Section 16.10):
- `APPROVESTEP` - single unified action with decision parameter (`APPROVED`, `REJECTED`, `SKIPPED`)

**Convention C** (Section 21, 22.7, 24):
- `SUBMITAPPROVAL` - initiate approval chain
- `APPROVESTEP` - approve a step
- `REJECTSTEP` - reject a step

Section 20.8 says `ActionType=APPROVETICKET` on post. Section 24 says `ActionType` of `APPROVESTEP` or `REJECTSTEP`. These will produce routing failures at runtime.

**Fix:** Pick one convention. Document the choice in section 12.2 and propagate everywhere.

---

### C-03. ApprovalStep key column: `operationalTypeID_FK` vs `operationalTypeCode` vs `ticketClassID_FK`

Three different columns link approval steps to operational types, across three different sections.

| Section | Column | Type | References |
|---|---|---|---|
| 11.18 | `operationalTypeID_FK` | `INT FK` | `[Tickets].[OperationalType]` |
| 16.1 | `operationalTypeCode` | `NVARCHAR(50)` | No FK (just a code string) |
| 21.1 | `ticketClassID_FK` | `INT FK` | `[Tickets].[TicketClass]` |

These are three different concepts. `TicketClass` holds INCIDENT/SERVICE_REQUEST/PROBLEM. `OperationalType` holds SERVICE_REQUEST/DISBURSEMENT/EXECUTION/INSPECTION. They are not interchangeable.

**Fix:** Use `operationalTypeID_FK INT FK -> [Tickets].[OperationalType]` everywhere (matches section 11.18 and the rest of the data model).

---

### C-04. Section 18 claims operational types map to `ticketClassID_FK`

Line 2084: "These types map to `ticketClassID_FK` in `[Tickets].[Ticket]`."

This contradicts the entire data model in sections 4-11, which clearly separates:
- `ticketClassID_FK` -> incident, service request, problem (section 11.2 seed rows)
- `operationalTypeID_FK` -> service request, disbursement, execution, inspection (section 11.12 seed rows)

Line 2312 repeats this error: "All four types share the same `[Tickets].[Ticket]` table, distinguished by `ticketClassID_FK`."

**Fix:** Rewrite lines 2084 and 2312 to say `operationalTypeID_FK`. The Ticket DDL in section 11.19 has both columns, and they serve different purposes.

---

### C-05. TicketApproval column names differ between section 11.26 and section 16.1

| Column purpose | Section 11.26 | Section 16.1 |
|---|---|---|
| Approver user | `ApproverUsersID_FK` | `ActionedByUsersID_FK` |
| Notes | `approvalNotes` | `actionNotes` |
| Decision timestamp | `decidedAt` | `actionedAt` |
| Request timestamp | `requestedAt` | (missing) |
| Approver DSD | (missing) | `ApproverDSDID_FK` |
| Approver Distributor | (missing) | `ApproverDistributorID_FK` |
| Mandatory flag | (missing) | `isRequired` |

These are supposed to be the same table.

**Fix:** Merge the column sets. Section 16.1 has the richer schema (includes approver DSD, isRequired). Use section 16.1 column names as the canonical DDL and update section 11.26.

---

### C-06. Approval chain seed data contradicts across sections

The same operational type gets different approval chains depending on which section you read.

**SERVICE_REQUEST chains:**
- Section 7.11 table: Technician -> Supervisor (2 steps)
- Section 16.7 seed data: Supervisor -> Branch Manager -> Department Manager (3 steps)
- Section 18.1: Requester's supervisor -> Service unit manager -> Financial reviewer (3 steps, different roles)

**DISBURSEMENT chains:**
- Section 7.11 table: Technician -> Supervisor -> Branch Manager -> Section Manager -> Department Manager (5 steps)
- Section 16.7 seed data: Supervisor -> Branch Manager -> Finance Section -> Department Manager (4 steps)
- Section 18.2: Section head -> Department director -> Finance budget -> Finance treasury (4 steps, different roles)

**EXECUTION chains:**
- Section 7.11 table: Technician -> Supervisor -> Branch Manager (3 steps)
- Section 16.7 seed data: Branch Manager -> Department Manager (2 steps)
- Section 18.3: Section head -> Executing team supervisor (2 steps, different roles)

**INSPECTION chains:**
- Section 7.11 table: Technician -> Supervisor (2 steps)
- Section 16.7 seed data: Section Manager (1 step)
- Section 18.4: Inspection team supervisor (1 step)

**Fix:** Pick one set of chains per type. Section 18 is the most detailed and business-grounded. Update sections 7.11 and 16.7 to match section 18.

---

### C-07. Section 21 introduces `CHANGE_REQUEST` as a fifth operational type

Line 2796: "adds the following rows to `[Tickets].[TicketClass]` if they do not already exist: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`, `CHANGE_REQUEST`"

Line 2876: "seed lookup data (including `CHANGE_REQUEST` in `[Tickets].[TicketClass]`)"

Line 2900: "operational type `CHANGE_REQUEST` is seeded but hidden"

Line 2852-2854: tests reference `CHANGE_REQUEST` ticket class

This introduces a fifth type that does not exist in sections 4-11 (which define exactly four operational types) and conflates TicketClass with OperationalType. Section 4.2 explicitly states "partial approval chain skipping or delegation" is out of scope, and the four-type model is defined in 7.11, 8.9, and 11.12.

**Fix:** Remove `CHANGE_REQUEST` from sections 21 and 22. If change requests are needed, add them to `OperationalType` (not `TicketClass`) in a future iteration.

---

### C-08. Section 10.4 missing `ApprovalStepHistory` from history table list

Section 10.4 lists three history tables:
- `[Tickets].[TicketHistory]`
- `[Tickets].[TicketSLAHistory]`
- `[Tickets].[ServiceRoutingRuleHistory]`

But `[Tickets].[ApprovalStepHistory]` is referenced in section 4 (line 61), section 7.12 (line 270), and section 8.10 (line 391). If using Schema A, this table belongs in section 10.4.

**Fix:** Add `[Tickets].[ApprovalStepHistory]` to section 10.4 and add its DDL as section 11.30.

---

### C-09. Section 10 does not list `ApprovalStepHistory` and section 11 has no DDL for it

Flowing from C-08: sections 4, 7.12, and 8.10 reference `[Tickets].[ApprovalStepHistory]` but there is no table-by-table DDL section for it. The closest equivalent is section 21.1's `[Tickets].[TicketApprovalLog]`, but that is a different table with different columns.

**Fix:** If keeping Schema A, add section 11.30 with `ApprovalStepHistory` DDL. If adopting Schema C, update all forward references from `ApprovalStepHistory` to `TicketApprovalLog`.

---

### C-10. V2 ClarificationReason seeds missing from section 11.10

Section 7.14 (line 306) states that V2 extends `ClarificationReason` with `CROSS_UNIT_QUERY`, `TECHNICAL_CONSULTATION`, and `RESOURCE_AVAILABILITY_CHECK`.

Section 11.10 (line 661) seed rows only list: `MISSING_DETAILS`, `MISSING_APPROVAL`, `MISSING_DOCUMENT`, `NEED_PARENT_INPUT`.

The V2 cross-unit reasons are never added to the seed list.

**Fix:** Add the three V2 reason codes to section 11.10's seed rows.

---

### C-11. Section 16.1 `operationalTypeCode` column contradicts `isRequired` absence in section 11.18

Section 11.18 (ApprovalStep DDL) has no `isRequired` column. Section 16.1 adds it. Section 21.1 uses `isAutoApproved` instead. The mandatory/optional/auto-approved concept is critical for approval chain behavior (section 16.2, BR-21, BR-22) and for each operational type in section 18 (which references `isAutoApproved`).

**Fix:** Decide on a single flag strategy. Either `isRequired` (binary mandatory/optional) or `isAutoApproved` (binary auto/manual), or both. Add to the canonical ApprovalStep DDL.

---

### C-12. Section 12.2 `REQUESTAPPROVAL` action vs section 16 auto-approval on INSERTTICKET

Section 12.2 defines `REQUESTAPPROVAL` as a separate action that creates TicketApproval rows and sets status to WAITING_APPROVAL.

Section 16.3 (line 1653) and section 16.9 say approval rows are created automatically during `INSERTTICKET` when matching ApprovalStep rows exist.

These are two different designs. Either approval is triggered by INSERTTICKET automatically, or it requires a separate REQUESTAPPROVAL action.

**Fix:** Pick one. The auto-create-on-INSERTTICKET model (section 16) is simpler and aligns with BR-20. Remove `REQUESTAPPROVAL` from section 12.2 if auto-create is the chosen path.

---

## MINOR Issues

### M-01. Section 4 mentions `ApprovalStepConfig` page but it never appears again

Line 69: "Approval chain configuration page (`ApprovalStepConfig`) as a new `pageName_`"

This page name does not appear in sections 13, 14, 19, 20, or 21. Approval configuration is handled through the existing `ServiceCatalog` page instead.

**Fix:** Remove `ApprovalStepConfig` from section 4, or add a note that it is handled under `ServiceCatalog`.

---

### M-02. Section 9 possible typo: `[dbo].[Divison]`

Line 425: `[dbo].[Divison]` - likely a typo for `[dbo].[Division]`. However, this might be the actual table name in the database. Needs verification.

**Fix:** Verify against `[dbo].[DeptSecDiv]` and other org tables. If the actual table is `Divison`, leave it. If it is `Division`, fix the reference.

---

### M-03. Section 16.1 ApprovalStep DDL uses `operationalTypeCode` but references `[Tickets].[OperationalType]`

Line 1567: `operationalTypeCode NVARCHAR(50) NOT NULL` - but there is no FK to `[Tickets].[OperationalType]`. The column name suggests it stores a code string, while section 11.18 uses a proper FK `operationalTypeID_FK INT`.

The seed SQL in section 16.7 (lines 1768-1800) inserts `operationalTypeCode` as string values like `'SERVICE_REQUEST'`. This works but loses referential integrity.

**Fix:** Align with section 11.18 and use `operationalTypeID_FK INT FK`.

---

### M-04. Section 11.3 TicketStatus seed rows missing WAITING_APPROVAL and REJECTED

Section 11.3 (line 538) lists seed rows: `NEW`, `TRIAGED`, `ASSIGNED`, `IN_PROGRESS`, `WAITING_ARBITRATION`, `WAITING_CLARIFICATION`, `WAITING_CHILD`, `RESOLVED`, `QUALITY_REVIEW`, `CLOSED`, `CANCELLED`, `REJECTED_BY_QUALITY`.

Missing: `WAITING_APPROVAL` and `REJECTED`. Section 16.11 adds them separately, but the master seed list in 11.3 should include all status values.

Also `BLOCKED` is referenced in sections 4.1, 7.7, 7.15, 8.13 but does not appear in the seed list either.

**Fix:** Add `WAITING_APPROVAL`, `REJECTED`, and `BLOCKED` to section 11.3 seed rows.

---

### M-05. Section 18 uses `isAutoApproved` column not present in any ApprovalStep DDL

Lines 2113, 2140, 2164, 2191, 2265, 2293: reference `isAutoApproved` on approval templates.

Section 11.18 has no such column. Section 16.1 has `isRequired`. Section 21.1 has `isAutoApproved`. Three different flag columns for the same concept.

**Fix:** Consolidate to a single column name and add it to the canonical DDL.

---

### M-06. Section 18 uses `SUBMITAPPROVAL` action not in section 12.2

Lines 2084, 2139, 2140, 2171, 2191, 2293: reference `SUBMITAPPROVAL` action in `[Tickets].[TicketSP]`.

Section 12.2 does not list `SUBMITAPPROVAL`. It lists `REQUESTAPPROVAL` and `APPROVETICKET`.

**Fix:** This is part of C-02. Resolve the action naming, then update section 18 accordingly.

---

### M-07. Section 22.8 tests reference `CHANGE_REQUEST` which is not a defined operational type

Lines 2852-2855: Tests check `CHANGE_REQUEST` ticket class behavior.

This type is not defined in sections 7.11, 8.9, or 11.12.

**Fix:** Remove or replace with one of the four defined operational types.

---

## STYLE Issues

### S-01. Merge artifact headings left in document

Four merge-seam headings break the markdown hierarchy:

- Line 1097: `# ITIL 4 Ticketing System Plan v2: Sections 12-15`
- Line 1546: `# Section 16: Approval Chain Design`
- Line 1923: `# ITIL 4 Ticketing System Plan v2: Sections 17-18`
- Line 2680: `# ITIL 4 Ticketing System Plan v2 - Sections 21-25`

These are H1-level headings that appear in the middle of an H1-level document. They should be removed or converted to HTML comments.

**Fix:** Remove all four lines. The `## 12`, `## 16`, `## 17`, `## 21` headings that follow are sufficient.

---

### S-02. `[v2]` markers throughout

Many lines carry `**[v2]**` markers (e.g., lines 1099, 1106, 1125, 1131, 1151-1154, 1177, 1199-1201, 1217, 1229, etc.). These are useful during drafting but should be cleaned before the document is treated as the canonical plan.

**Fix:** Remove or convert to a footnote convention once the document is finalized.

---

### S-03. Inconsistent `ApprovalStepConfig` page name references

Line 69 calls the admin page `ApprovalStepConfig`. Everywhere else it is handled under `ServiceCatalog`. This creates confusion about whether a separate page exists.

**Fix:** Remove the `ApprovalStepConfig` reference or add a clarifying note.

---

### S-04. Section 16.12 spec-kit references inconsistent with section 21

Section 16.12 says:
- Spec 04: "Create `[Tickets].[ApprovalStep]` and `[Tickets].[TicketApproval]`"
- Spec 05: "Add `APPROVESTEP` action"

Section 21 says:
- Spec 13: "Create `[Tickets].[ApprovalStepTemplate]`, `[Tickets].[TicketApprovalStep]`, `[Tickets].[TicketApprovalLog]`; add `SUBMITAPPROVAL`, `APPROVESTEP`, `REJECTSTEP`"

These describe the same work under different spec numbers and different table names.

**Fix:** Reconcile section 16.12 with section 21 spec definitions.

---

## Summary Table

| ID | Severity | Section(s) | Issue |
|---|---|---|---|
| C-01 | CRITICAL | 4/10/11 vs 16 vs 21 | Three competing approval table schemas |
| C-02 | CRITICAL | 12, 16, 19, 20, 21, 24 | Three SP action naming conventions |
| C-03 | CRITICAL | 11.18 vs 16.1 vs 21.1 | ApprovalStep key column differs (ID vs code vs wrong FK) |
| C-04 | CRITICAL | 18 (lines 2084, 2312) | Says operational types map to ticketClassID_FK |
| C-05 | CRITICAL | 11.26 vs 16.1 | TicketApproval column names and sets differ |
| C-06 | CRITICAL | 7.11 vs 16.7 vs 18.1-18.4 | Approval chain steps contradict per operational type |
| C-07 | CRITICAL | 21, 22 | Introduces CHANGE_REQUEST as fifth type |
| C-08 | CRITICAL | 4, 7.12, 8.10, 10.4 | ApprovalStepHistory missing from table list |
| C-09 | CRITICAL | 4, 7.12, 8.10, 11 | No DDL section for ApprovalStepHistory |
| C-10 | CRITICAL | 7.14, 11.10 | V2 clarification reason seeds not in seed list |
| C-11 | CRITICAL | 11.18, 16.1, 21.1, 18 | isRequired vs isAutoApproved flag confusion |
| C-12 | CRITICAL | 12.2 vs 16.3/16.9 | REQUESTAPPROVAL as separate action vs auto on INSERT |
| M-01 | MINOR | 4 (line 69) | ApprovalStepConfig page never appears again |
| M-02 | MINOR | 9 (line 425) | Possible typo: Divison vs Division |
| M-03 | MINOR | 16.1 vs 11.18 | operationalTypeCode string vs operationalTypeID_FK |
| M-04 | MINOR | 11.3, 16.11 | Missing WAITING_APPROVAL, REJECTED, BLOCKED in seed list |
| M-05 | MINOR | 18, 11.18, 16.1, 21.1 | isAutoApproved not in canonical DDL |
| M-06 | MINOR | 18 | SUBMITAPPROVAL action not in section 12.2 |
| M-07 | MINOR | 22.8 | Tests reference undefined CHANGE_REQUEST type |
| S-01 | STYLE | 1097, 1546, 1923, 2680 | Merge artifact H1 headings |
| S-02 | STYLE | Throughout | [v2] markers should be cleaned |
| S-03 | STYLE | 4 (line 69) | Orphan ApprovalStepConfig page name |
| S-04 | STYLE | 16.12 vs 21 | Spec numbers and table names for approval differ |

---

## Root Cause

The 12 critical issues share one root cause: sections 16 and 21 were written independently of sections 1-15 and 18, each inventing their own table names, column names, action names, and DDL shapes for the same approval subsystem. The merge preserved all three versions without reconciliation.

## Recommended Resolution Order

1. Decide on canonical table names (C-01): `ApprovalStep` + `TicketApproval` + `ApprovalStepHistory`
2. Decide on canonical key column (C-03): `operationalTypeID_FK INT FK`
3. Decide on canonical action names (C-02): pick one convention
4. Decide on mandatory/auto flag (C-11): pick `isRequired` or `isAutoApproved` or both
5. Merge DDL column sets (C-05): take the union from sections 11.26 and 16.1
6. Pick canonical seed chains (C-06): align all three sources to section 18
7. Rewrite sections 16 and 21 to match the canonical decisions
8. Fix the operationalType vs ticketClass error (C-04)
9. Remove CHANGE_REQUEST (C-07)
10. Add missing seed data (C-08, C-09, C-10, C-12, M-04, M-05, M-06)
11. Clean merge artifacts (S-01, S-02)
