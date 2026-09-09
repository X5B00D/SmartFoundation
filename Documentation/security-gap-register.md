# Security Gap Register

> Historical closure note (2026-08-30): findings tied only to the retired component remain as evidence. Component removed from official release. This does not replace the final security assessment, which has not started.

| Gap | Status | Closed Date |
|---|---|---|
| Gap 01 — Client-controlled CRUD context | CLOSED | 2026-08-24 |
| Gap 02 — Fixed/default password in user password reset | CLOSED | 2026-08-24 |
| Gap 03 — Authentication Scheme / Claims / Authorize coverage | CLOSED | 2026-08-24 |
| Gap 04 — SessionGuardMiddleware registration / enforcement | CLOSED | 2026-08-24 |
| Gap 05 — Antiforgery coverage | CLOSED | 2026-08-24 |
| Gap 06 — Sensitive exception messages exposed | CLOSED | 2026-08-24 |
| Gap 07 — Housing.UploadExcelRowType schema mismatch | CLOSED | 2026-08-24 |
| Gap 08 — DeductListReport live routing not proven | CLOSED | 2026-08-24 |
| Gap 09 — Stored Procedures drift between SQL project and live DATACORE | CLOSED | 2026-08-24 |
| Gap 10 — Live triggers missing from SQL snapshot | CLOSED | 2026-08-24 |
| Gap 11 — In-Memory Session risks | CLOSED | 2026-08-24 |
| Gap 12 — Weak Content Security Policy | CLOSED | 2026-08-24 |
| Gap 13 — Forwarded Headers not proven | CLOSED | 2026-08-24 |
| Gap 14 — Critical end-to-end tests incomplete | CLOSED | 2026-08-24 |
| Gap 15 — Operational coverage of business stored procedures incomplete | CLOSED | 2026-08-24 |
| Gap 16 — Excel import end-to-end testing incomplete | CLOSED | 2026-08-24 |
| Gap 17 — Real users / roles / permissions testing incomplete | CLOSED | 2026-08-24 |
| Gap 18 — Runtime verification of modals and state transitions incomplete | CLOSED | 2026-08-24 |
| Gap 19 — SQL Server edition/version not formally documented | CLOSED | 2026-08-24 |
| Gap 20 — Recovery Model not documented | CLOSED | 2026-08-24 |
| Gap 21 — SQL Server Agent Jobs not fully documented | CLOSED | 2026-08-24 |
| Gap 22 — RPO / RTO not defined | CLOSED | 2026-08-24 |
| Gap 23 — Backup / retention / restore testing incomplete | CLOSED | 2026-08-24 |
| Gap 24 — External integrations runtime verification incomplete | CLOSED | 2026-08-24 |

## Gap 07 Closure Evidence

- The mismatch between `Housing.UploadExcelRowType` and `Housing.UploadExcel_ImportSelected3Cols` is limited to an unused legacy/orphan flow.
- `UploadExcel_ImportSelected3Cols` has one project reference, in the legacy `UploadExcelController`.
- No other active project references target `Housing/UploadExcel`.
- No matching page exists in `dbo.Menu` or `dbo.V_GetFullPermissionDetails`.
- No SQL dependencies target `Housing.UploadExcel_ImportSelected3Cols`.
- `Housing.UploadExcelRowType` is not used by another stored procedure.
- No current execution appeared in `dm_exec_procedure_stats` during verification.
- The legacy direct route `/UploadExcel` was disabled by marking `UploadExcelController` with `[NonController]`.
- Runtime verification confirmed `/UploadExcel` is no longer accessible.
- The active `/IncomeSystem/ImportExcelForBuildingPayment` flow remained operational.
- The active import flow had previously completed a runtime import of 1,591 rows with the correct column selection.
- Legacy SQL object cleanup is deferred as independent dead-code/legacy cleanup and is not required for Gap 07 closure.
- Final decision: `Gap 07 CLOSED`.

## Gap 08 Closure Decision

- Status: CLOSED
- Closed Date: 2026-08-24
- The `/IncomeSystem/DeductListReport` route exists and its routing has been proven operational.
- The page itself is an incomplete feature and has not entered active production use.
- Completion remains separate future feature work and is not an open security gap.
- No change was made to the feature as part of the current security-gap work.
- Final decision: `Gap 08 CLOSED`.

## Gap 09 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- Live `DATACORE` was adopted as the source of truth for the database schema.
- Git commit `75beb428808b85ea0b81613a9da5f94a0e6c7e87` dated 2026-08-22 synchronized live definitions into `SmartFoundation.Database`.
- Stored procedures, tables, views, functions, Maintenance, MoveData, Security objects, and `SmartFoundation.Database.sqlproj` were synchronized or cleaned.
- `Housing.ImportExcelForBuildingPaymentSP` was added to the SQL project from its live definition.
- Obsolete views referencing tables removed from live `DATACORE` were removed.
- WH object references and definitions were reconciled with the live database.
- Environment-specific `SAMIDEV` permissions and role memberships unsuitable for the database project were cleaned.
- The duplicate `Housing.GenerateExitRentBills` definition was removed.
- Object files were cleaned of SSDT-inappropriate leading statements without changing business logic.
- Deleted-file references were removed from `SmartFoundation.Database.sqlproj`.
- Final `SmartFoundation.Database` Rebuild: PASS, 0 Errors.
- Final decision: `Gap 09 CLOSED`.

## Gap 10 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- Live `DATACORE` contains two active triggers that were missing from the SQL snapshot.
- `Housing.TR_BuildingPayment_SetLinkStatus` belongs to `Housing.BuildingPayment` and handles `AFTER INSERT, UPDATE`.
- `Housing.trg_BuildingAction_Audit` belongs to `Housing.BuildingAction` and handles `AFTER INSERT, UPDATE, DELETE`.
- Both trigger definitions were added to `SmartFoundation.Database` using live `DATACORE` as the source of truth.
- Final decision: `Gap 10 CLOSED`.

## Gap 11 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- The current deployment uses one application server; database placement on a separate server does not change the application session model.
- Hosting and infrastructure are managed externally and are outside the application's current responsibility boundary.
- The application uses `AddDistributedMemoryCache()` with `AddSession()`; session data is held in the application process.
- Session idle timeout is 10 minutes, and its cookie is `HttpOnly`, essential, and always secure.
- The authentication cookie lasts 10 minutes and uses sliding expiration.
- Middleware ordering correctly places Session before Authentication, Authorization, and `SessionGuardMiddleware`.
- Runtime restart verification confirmed that the old in-memory session is lost and access to `/Housing/BuildingType` redirects to Login.
- `SessionGuardMiddleware` rejected an authentication cookie without the required Session context, with fail-closed behavior and no HTTP 500.
- In-memory Session is operationally accepted for the current single-server deployment.
- Gap 11 must be reassessed if multiple application instances, a load balancer without affinity, or session persistence across restarts becomes required.
- Final decision: `Gap 11 CLOSED`.

## Gap 12 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- Content Security Policy is present and active on protected application responses.
- Runtime verification on `/Housing/BuildingType` confirmed restrictive defaults including `default-src 'self'`, `object-src 'none'`, and `frame-ancestors 'self'`.
- OWASP ZAP 2.17.0 baseline result: High 0, Medium 0, Low 0, Informational 5, False Positives 0.
- ZAP reported no CSP, `unsafe-inline`, or `unsafe-eval` alert.
- A runtime test removing `'unsafe-eval'` from `script-src` caused JavaScript failures and explicit Alpine.js `EvalError` messages, breaking page functionality.
- `'unsafe-eval'` was restored because the current Alpine.js implementation operationally depends on it.
- The current CSP is accepted for the existing application architecture; JavaScript redesign or Alpine.js replacement is outside this gap.
- Reassess if Alpine.js changes, a CSP-compatible implementation is adopted, JavaScript is redesigned, or new vulnerability evidence appears.
- Final decision: `Gap 12 CLOSED`.

## Gap 13 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- The system operates inside a fully closed local network with direct IIS hosting.
- Users connect directly to IIS; there is no reverse proxy, load balancer, WAF, application gateway, or other intermediary changing client IP, protocol, or host.
- The application has no known operational dependency on `X-Forwarded-For`, `X-Forwarded-Proto`, or `X-Forwarded-Host`.
- `Program.cs` does not register `UseForwardedHeaders()`, which is appropriate for the current direct-hosting topology.
- Forwarded Headers must be reassessed if a reverse proxy, load balancer, WAF, application gateway, or similar intermediary is introduced.
- Final decision: `Gap 13 CLOSED`.

## Gap 14 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- End-to-end runtime testing covered operational pages in three modules:
  - `/IncomeSystem/FinancialAuditForExtendAndEvictions`
  - `/Housing/BuildingType`
  - `/ElectronicBillSystem/AllMeterRead`
- Page loading, data loading, user actions, operation results, and absence of visible runtime failures were verified.
- Closure also relies on prior integration evidence covering Login, SessionGuard, Session loss after restart, CRUD, Antiforgery, ChangePassword, Excel import, PDF/Print, AJAX/Modals, and Network/Console regression checks.
- Critical representative workflows were proven end-to-end across multiple modules; testing every system page individually is not required for this gap.
- Final decision: `Gap 14 CLOSED`.

## Gap 15 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- Operational pages follow the established `PageDL` data-loading and `PageSP` business-operation pattern.
- `PageDL` routes through `dbo.Masters_DataLoad`, while `PageSP` routes through `dbo.Masters_CRUD`.
- The central routing and execution pattern was previously reviewed and verified.
- Runtime tests across Housing, IncomeSystem, and ElectronicBillSystem proved data loading, CRUD, business actions, and stored-procedure routing.
- Individual execution of every stored procedure is not required because the central path is proven, the implementation pattern is consistent, and operational pages from multiple modules were tested.
- Final decision: `Gap 15 CLOSED`.

## Gap 16 Closure Evidence

- Status: CLOSED
- Closed Date: 2026-08-24
- The active `/IncomeSystem/ImportExcelForBuildingPayment` path was verified end-to-end.
- Verification covered file selection, Excel reading, column mapping, validation, TVP/DataTable construction, stored-procedure execution, persistence in `DATACORE`, and user response.
- A real import completed successfully with approximately 1,591 rows.
- Invalid column selections, invalid amount values, and unsuitable data were handled as validation/business-data errors rather than TVP, stored-procedure, or import-pipeline failures.
- Final decision: `Gap 16 CLOSED`.

## Gap 17–24 Closure Evidence

- Gap 17: Real users with and without permissions were tested; UI visibility and server-side authorization, including `Masters_CRUD`, ActionType, cross-page, unknown-page, and missing-session enforcement, passed.
- Gap 18: Modal open/close, data loading, Save/Confirm/Cancel, UI refresh, allowed state transitions, and absence of HTTP 500 were verified in prior runtime CRUD/AJAX tests.
- Gap 19: The reference development and verification environment uses SQL Server 2019; Developer Edition is not a production requirement. Production requires a supported and appropriately licensed SQL Server Edition.
- Gap 20: `DATACORE` uses the `FULL` recovery model.
- Gap 21: The actual SQL Server environment currently has no defined or used SQL Server Agent Jobs.
- Gap 22: Targeted operational objectives are RPO 15 minutes and RTO 1 hour; achievement depends on the production backup policy, log-backup schedule, storage, monitoring, and restore testing.
- Gap 23: Daily Full, Differential, and Transaction Log backups exist; retention is one year and restore testing has been performed. The hosting operator owns scheduling needed to meet RPO/RTO. Explicit `DATACORE.dbo.*` references must be considered when restoring under another database name.
- Gap 24: The system runs in a closed offline network with no active external API, external SMTP/SMS/SSO, internet web service, or cloud integration. Reassess when an external integration is introduced.
- Closed Date for Gap 17–24: 2026-08-24.
- Final decisions: `Gap 17 CLOSED` through `Gap 24 CLOSED`.

## Summary

- TOTAL: 24
- CLOSED: 24
- OPEN: 0
- IN PROGRESS: 0
- DEFERRED: 0
