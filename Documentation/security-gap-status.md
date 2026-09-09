# Security Gap Status

> Historical closure note (2026-08-30): component-specific evidence below is retained for audit history. Component removed from official release. Final security assessment status: NOT STARTED.

## Gap 01 — Client-controlled CRUD context

- Status: CLOSED
- Closed Date: 2026-08-24
- trusted Session/server-side `entrydata`
- trusted Session/server-side `idaraID`
- trusted server-side `hostname`
- fixed identity fallbacks removed
- `pageName_` constrained
- `ActionType` permission checked and explicitly constrained
- The retired component's historical identity-tampering and feedback-ownership checks passed before removal from the official release.
- Support ActionType whitelist tests PASS
- unknown page/action rejection PASS
- missing Session test PASS
- full `Masters_CRUD` block review PASS
- MVC Build: 0 Errors / 0 Warnings
- live changes applied successfully to:
  - `dbo.Masters_CRUD`
  - the retired component's feedback procedure (removed from the official release)
- test records cleaned with ROLLBACK
- final decision: `Gap 01 CLOSED`

## Gap 02 — Fixed/default password in user password reset

- Status: CLOSED
- Closed Date: 2026-08-24
- Reset password remains `Aa123456` by approved operational decision.
- Reset password validity is limited to 24 hours.
- Reset creates new Salt/Hash.
- `ChangedPassword = 0` after reset.
- `userPasswordStartDate` and `userPasswordEndDate` enforce reset validity.
- expired temporary password login is denied.
- legacy `ChangedPassword=0` with NULL expiry is denied.
- password change is enforced Server-side.
- direct application page access before password change is blocked.
- `/crud/*` and `/api/*` are blocked Server-side while password change is required.
- successful password change sets normal password state and clears Session.
- user must login again with the new password.
- existing users with `ChangedPassword=1` are unaffected.
- no bulk UPDATE was executed against the 75 legacy accounts.
- live SQL deployment succeeded for:
  - `dbo.ReSetUserPassword`
  - `dbo.GetSessionInfoForMVC`
- Middleware tests: PASS.
- SQL tests A/B/F/G/H/I/J: PASS.
- transaction safety and rollback: PASS.
- test user count after rollback: 0.
- test password rows after rollback: 0.
- related test rows after rollback: 0.
- MVC Build: PASS, 0 Errors / 0 Warnings.
- final decision: `Gap 02 CLOSED`

## Gap 03 — Authentication Scheme / Claims / Authorize coverage

- Status: CLOSED
- Closed Date: 2026-08-24
- ASP.NET Core Cookie Authentication enabled.
- Authentication Scheme: `Cookies`.
- Cookie name: `.SmartFoundation.Auth`.
- `ClaimsPrincipal` created on successful Login.
- `ClaimTypes.NameIdentifier` uses trusted `usersID`.
- `ClaimTypes.Name` uses trusted `fullName`.
- `SignInAsync` implemented.
- `SignOutAsync` implemented.
- Session continues to hold application context.
- Fallback Authorization Policy requires authenticated users by default.
- Controllers reviewed: 23.
- `[AllowAnonymous]` limited to:
  - `LoginController.Index`
  - `LoginController.CheckLogin`
- Reports, Exports, Uploads, SmartComponent, CRUD and business APIs are no longer anonymously accessible.
- SessionGuard performs authenticated-cookie/session consistency validation.
- Tests A-G: PASS.
- Tests H-I-J-K-L: PASS.
- Fallback Policy audit: PASS.
- Gap 02 regression: NO.
- Authentication Cookie + Session behavior: PASS.
- Logout behavior: PASS.
- Cookie-without-Session protection: PASS.
- Test users cleaned successfully.
- Remaining test users: 0.
- Related password rows: 0.
- Related test rows: 0.
- Build Errors: 0.
- New warnings introduced by Gap 03: 0.
- Existing legacy warnings: 324.
- final decision: `Gap 03 CLOSED`

## Gap 04 — SessionGuardMiddleware registration / enforcement

- Status: CLOSED
- Closed Date: 2026-08-24
- Pipeline:
  - `UseStaticFiles`
  - `UseRouting`
  - `UseSession`
  - `UseAuthentication`
  - `UseAuthorization`
  - `SessionGuardMiddleware`
  - `ForcePasswordChangeMiddleware`
  - `MapRazorPages / MapControllers / MapControllerRoute`
- SessionGuard registered exactly once.
- Required Session keys:
  - `usersID`
  - `fullName`
  - `IdaraID`
  - `nationalID`
- `ClaimTypes.NameIdentifier` is compared Server-side with `Session["usersID"]`.
- Missing or mismatched Session identity triggers `SignOutAsync` + `Session.Clear`.
- MVC redirects to Login.
- API/CRUD return 401.
- Session-only without Authentication Cookie is rejected.
- Tests A-L: PASS.
- Gap 02 regression: NO.
- Gap 03 regression: NO.
- Build: 0 Errors.
- New warnings introduced by Gap 04: 0.
- Legacy warnings: 324.
- No final source-code modification was required during Gap 04 verification.
- final decision: `Gap 04 CLOSED`

## Gap 05 — Antiforgery coverage

- Status: CLOSED
- Closed Date: 2026-08-24
- `AutoValidateAntiforgeryTokenAttribute` registered centrally on MVC.
- Antiforgery header: `RequestVerificationToken`.
- Tokens generated centrally using `IAntiforgery.GetAndStoreTokens()` and exposed by the Layout.
- SmartForm uses `@Html.AntiForgeryToken()` and does not derive tokens from request headers.
- Central JavaScript adds the token to same-origin `POST`, `PUT`, `PATCH`, and `DELETE` requests.
- State-changing GET remediation:
  - Logout converted to protected POST.
  - `SignOut` and `Session.Clear` removed from GET `Login/Index`.
  - state-changing Session/file cleanup removed from Excel GET paths.
- Unsafe endpoints reviewed: 24.
- Protected: 24.
- Unprotected: 0.
- Not Applicable: 0.
- `IgnoreAntiforgeryToken`: 0.
- Runtime tests A-O: PASS.
- Gap 01 regression: NO.
- Gap 02 regression: NO.
- Gap 03 regression: NO.
- Gap 04 regression: NO.
- Rejected requests were blocked before business logic:
  - ChangePassword state unchanged.
  - AI rows: 0.
  - Notification rows: 0.
  - SmartComponent did not reach DataEngine.
  - Export was not executed.
  - Logout did not execute `SignOut` or `Session.Clear`.
- Build: PASS, 0 Errors / 0 Warnings.
- Cleanup: PASS.
- Test users: 0.
- Test permissions: 0.
- Test password rows: 0.
- Test notifications: 0.
- Test AI rows: 0.
- Test upload files: 0.
- Related test data: 0.
- final decision: `Gap 05 CLOSED`

## Gap 06 — Sensitive exception messages exposed

- Status: CLOSED
- Closed Date: 2026-08-24
- Confirmed exception-detail response findings remediated: 27/27.
- Review findings sanitized: 45/45.
- Client-facing exception messages replaced with safe Arabic messages.
- Stored-procedure and SQL exception details are retained only in server-side logging/inner exceptions.
- Business-validation messages returned intentionally by stored procedures/DataSets remain unchanged.
- Final static scan:
  - VULNERABLE: 0.
  - REVIEW: 0.
  - SAFE server-side only: 2.
- MVC Release Build: PASS, 0 Errors.
- Existing legacy warnings: 324.
- Focused application tests: PASS, 12/12.
- Runtime verification of CRUD, Login, Export, Excel, Support, Vehicle, AJAX, and Network responses: PASS.
- Final decision: `Gap 06 CLOSED`.

## Gap 07 — Housing.UploadExcelRowType schema mismatch

- Status: CLOSED
- Closed Date: 2026-08-24
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
- No SQL schema, stored procedure, or user-defined type change was required.
- Legacy SQL object cleanup is deferred as independent dead-code/legacy cleanup.
- Final decision: `Gap 07 CLOSED`.

## Gap 08 — DeductListReport live routing not proven

- Status: CLOSED
- Closed Date: 2026-08-24
- The `/IncomeSystem/DeductListReport` route exists and its routing has been proven operational.
- The page itself is an incomplete feature and has not entered active production use.
- Completion remains separate future feature work and is not an open security gap.
- No change was made to the feature as part of the current security-gap work.
- Final decision: `Gap 08 CLOSED`.

## Gap 09 — Stored Procedures drift between SQL project and live DATACORE

- Status: CLOSED
- Closed Date: 2026-08-24
- Live `DATACORE` is the source of truth for the database schema.
- Git commit `75beb428808b85ea0b81613a9da5f94a0e6c7e87` dated 2026-08-22 synchronized live definitions into `SmartFoundation.Database`.
- Stored procedures, tables, views, functions, Maintenance, MoveData, Security objects, and the SQL project file were synchronized or cleaned.
- `Housing.ImportExcelForBuildingPaymentSP` was added from its live definition.
- Obsolete views, stale WH references, environment-specific `SAMIDEV` security entries, a duplicate `Housing.GenerateExitRentBills` definition, and stale project references were cleaned.
- SSDT-inappropriate leading statements were removed without changing business logic.
- Final `SmartFoundation.Database` Rebuild: PASS, 0 Errors.
- Final decision: `Gap 09 CLOSED`.

## Gap 10 — Live triggers missing from SQL snapshot

- Status: CLOSED
- Closed Date: 2026-08-24
- Live `DATACORE` contains two active triggers that were missing from `SmartFoundation.Database`.
- `Housing.TR_BuildingPayment_SetLinkStatus`:
  - Parent: `Housing.BuildingPayment`
  - Events: `AFTER INSERT, UPDATE`
- `Housing.trg_BuildingAction_Audit`:
  - Parent: `Housing.BuildingAction`
  - Events: `AFTER INSERT, UPDATE, DELETE`
- Both trigger definitions were added to the SQL snapshot with live `DATACORE` retained as the source of truth.
- Final decision: `Gap 10 CLOSED`.

## Gap 11 — In-Memory Session risks

- Status: CLOSED
- Closed Date: 2026-08-24
- The current deployment uses one application server; the database may be on a separate server without changing the Session model.
- Hosting and infrastructure are managed externally and are outside the application's current responsibility boundary.
- The application uses `AddDistributedMemoryCache()` and `AddSession()` with process-local Session storage.
- Session idle timeout: 10 minutes.
- Session cookie: `HttpOnly = true`, `IsEssential = true`, `SecurePolicy = Always`.
- Authentication cookie duration: 10 minutes with sliding expiration.
- Middleware order: Routing, Session, Authentication, Authorization, then `SessionGuardMiddleware`.
- Runtime restart verification:
  - Login succeeded and `/Housing/BuildingType` was accessible.
  - After stopping and restarting the application, refreshing the page redirected to `/Login?ReturnUrl=%2FHousing%2FBuildingType`.
  - The old Session was lost as expected.
  - Authentication Cookie alone did not preserve access.
  - `SessionGuardMiddleware` failed closed without HTTP 500.
- In-memory Session is accepted for the current single-server environment.
- Reassess if multiple application servers/instances, a load balancer without Session affinity, or persistence across application restarts becomes required.
- Final decision: `Gap 11 CLOSED`.

## Gap 12 — Weak Content Security Policy

- Status: CLOSED
- Closed Date: 2026-08-24
- Content Security Policy is present and active on protected application responses.
- Runtime response verification on `/Housing/BuildingType` confirmed the configured CSP header.
- OWASP ZAP 2.17.0 baseline scan:
  - High: 0
  - Medium: 0
  - Low: 0
  - Informational: 5
  - False Positives: 0
- ZAP reported no alert for CSP, `unsafe-inline`, or `unsafe-eval`.
- Removing `'unsafe-eval'` from `script-src` was tested at runtime and caused multiple JavaScript failures.
- Alpine.js generated explicit CSP `EvalError` messages and the page was functionally affected.
- `'unsafe-eval'` was restored to preserve current application behavior.
- The current CSP is accepted for the existing architecture; replacing Alpine.js or redesigning JavaScript is outside this gap.
- Reassess only after relevant JavaScript/CSP architecture changes or new security evidence.
- Final decision: `Gap 12 CLOSED`.

## Gap 13 — Forwarded Headers not proven

- Status: CLOSED
- Closed Date: 2026-08-24
- The system operates inside a fully closed local network and is hosted directly on IIS.
- Users connect directly to IIS.
- No reverse proxy, load balancer, WAF, application gateway, or similar intermediary exists in front of the application.
- There is no known operational dependency on `X-Forwarded-For`, `X-Forwarded-Proto`, or `X-Forwarded-Host`.
- The absence of `UseForwardedHeaders()` is appropriate for the current hosting topology.
- Reassess if the hosting architecture changes and an intermediary begins altering client IP, protocol, or host.
- Final decision: `Gap 13 CLOSED`.

## Gap 14 — Critical end-to-end tests incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- End-to-end runtime verification covered three operational pages from different modules:
  - IncomeSystem: `/IncomeSystem/FinancialAuditForExtendAndEvictions`
  - Housing: `/Housing/BuildingType`
  - ElectronicBillSystem: `/ElectronicBillSystem/AllMeterRead`
- Page Load, Data Load, User Actions, operation results, and absence of visible runtime errors were verified.
- Prior integration evidence also covers Login, SessionGuard, Session loss after restart, CRUD Insert/Update/Delete, Antiforgery, ChangePassword, Excel import, PDF/Print, AJAX/Modals, and Network/Console regression checks.
- Representative critical workflows were proven end-to-end across multiple modules; exhaustive testing of every page is not required for Gap 14 closure.
- Final decision: `Gap 14 CLOSED`.

## Gap 15 — Operational coverage of business stored procedures incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- Operational pages follow the established `PageDL` data-loading and `PageSP` business-operation pattern.
- `PageDL` routes through `dbo.Masters_DataLoad`.
- `PageSP` routes through `dbo.Masters_CRUD`.
- The central routing and execution pattern was previously reviewed and verified.
- Runtime testing across Housing, IncomeSystem, and ElectronicBillSystem proved Data Load, CRUD, Business Actions, and Stored Procedure routing.
- Testing every stored procedure individually is not required because the central route is proven, the execution pattern is consistent, and operational pages from multiple modules were tested.
- Final decision: `Gap 15 CLOSED`.

## Gap 16 — Excel import end-to-end testing incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- The active `/IncomeSystem/ImportExcelForBuildingPayment` flow was verified end-to-end.
- Verification covered Excel selection and reading, column selection/mapping, validation, TVP/DataTable conversion, stored-procedure execution, persistence in `DATACORE`, and the returned user result.
- A real import completed successfully with approximately 1,591 rows.
- Incorrect column selection, invalid amount values, and unsuitable data were handled as validation/business-data errors rather than failures in the TVP, stored procedure, or import path.
- Final decision: `Gap 16 CLOSED`.

## Gap 17 — Real users / roles / permissions testing incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- Real users with and without the required permissions were tested.
- Allowed actions were shown and executed according to permission; unauthorized actions were denied server-side, not merely hidden in the UI.
- Prior tests also covered `Masters_CRUD` permission and ActionType validation, cross-page tampering, unknown pages, missing Session, and server-side enforcement.
- Final decision: `Gap 17 CLOSED`.

## Gap 18 — Runtime verification of modals and state transitions incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- Runtime tests verified modal open/close, correct modal data, Save/Confirm/Cancel, UI refresh, and allowed state transitions.
- No incorrect transition, visible runtime failure, or HTTP 500 occurred in the tested CRUD/AJAX/modal flows.
- Final decision: `Gap 18 CLOSED`.

## Gap 19 — SQL Server edition/version not formally documented

- Status: CLOSED
- Closed Date: 2026-08-24
- البيئة المرجعية المستخدمة في التطوير والتحقق: SQL Server 2019؛ وردت Developer Edition بوصفها Edition للبيئة المرجعية فقط.
- بيئة الإنتاج تستخدم إصدار SQL Server مدعومًا وEdition مرخصة ومناسبة وفق سياسات الجهة المستضيفة؛ Developer Edition ليست Production Requirement.
- A personal development-machine SQL Server installation is not the reference for this decision.
- Final decision: `Gap 19 CLOSED`.

## Gap 20 — Recovery Model not documented

- Status: CLOSED
- Closed Date: 2026-08-24
- Official database: `DATACORE`.
- Recovery Model: `FULL`.
- Final decision: `Gap 20 CLOSED`.

## Gap 21 — SQL Server Agent Jobs not fully documented

- Status: CLOSED
- Closed Date: 2026-08-24
- Verification of the actual SQL Server environment found no currently defined or used SQL Server Agent Jobs.
- Final decision: `Gap 21 CLOSED`.

## Gap 22 — RPO / RTO not defined

- Status: CLOSED
- Closed Date: 2026-08-24
- Official RPO: 15 minutes.
- Official RTO: 1 hour.
- These values are the project's operational disaster-recovery targets.
- Final decision: `Gap 22 CLOSED`.

## Gap 23 — Backup / retention / restore testing incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- Daily Full Backup, Differential Backup, and Transaction Log Backup are present.
- Retention: one year.
- A real Restore test was previously completed.
- Restoring under a different database name requires attention to explicit references such as `DATACORE.dbo.*`, which may continue targeting `DATACORE`.
- The hosting/operator organization owns backup scheduling needed to meet RPO 15 minutes and RTO 1 hour, including an appropriate Transaction Log Backup schedule.
- Final decision: `Gap 23 CLOSED`.

## Gap 24 — External integrations runtime verification incomplete

- Status: CLOSED
- Closed Date: 2026-08-24
- The system runs in a fully closed local network without Internet connectivity.
- There are currently no operational external APIs, external SMTP/SMS/SSO, Internet web services, or Internet-dependent cloud integrations.
- The database and core services remain inside the internal environment.
- Reassess only when a new external integration is introduced.
- Final decision: `Gap 24 CLOSED`.

## Summary

- TOTAL: 24
- CLOSED: 24
- OPEN: 0
- IN PROGRESS: 0
- DEFERRED: 0
