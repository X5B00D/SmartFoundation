# رسم Authentication وSession

المسار التطبيقي مثبت من الكود، وتعريفات SQL ذات العلاقة قُرئت حياً في 2026-08-23 وطابقت الـSnapshot.

```mermaid
flowchart TB
    Browser["المتصفح"] --> Get["GET /Login/Index\nClear Session + no-cache"]
    Get --> Form["Login form + antiforgery"]
    Form --> Post["POST /Login/CheckLogin"]
    Post --> Service["MastersServies"] --> Mapper["auth:sessions_"] --> Proc["GetSessionInfoForMVC"]
    Proc --> User["Users active + validity dates"] --> Password["UsersPassword\n32-byte salt + SHA2_256"] --> Structure["active UsersDetails + Idara/Department"]
    Structure --> Success{"usersID وusersActive صالحان؟"}
    Success -- "لا" --> Error["رسالة فشل -> Login"]
    Success -- "نعم" --> Session["Session server-side\nidentity + organization + presentation"]
    Session --> Home["/Home/Index"] --> LocalGuard["InitPageContext\nusersID required"] --> HomeSideEffect["GET runs monthly billing SP\nthen Masters_DataLoad"]
    HomeSideEffect --> Page["Home view + shared layout"]
    Session --> Change["POST /Login/ChangePassword\nSession usersID"] --> Reset["ReSetUserPassword\nCHANGEUSERPASSWORD"]
    Reset --> Policy["server policy: 8+ chars\nEnglish letter + digit\nold password + different new"] --> ReLogin["ChangedPassword=1\nUI logs out for re-login"]
    Page --> Logout["GET Login/Logout أو POST session/logout"] --> Clear["Session.Clear"] --> Get
    Claims["لا ClaimsPrincipal/SignInAsync\nولا Authentication Scheme"] -. "ليس جزءاً من المسار" .-> Session
    Guard["SessionGuardMiddleware موجود\nغير مسجل"] -. "لا يحمي pipeline" .-> LocalGuard
```

- Session cookie ليست Authentication ticket.
- مسح Session مثبت؛ تدوير Session ID غير مثبت.
- `RESETUSERPASSWORD` الحي ما زال يستخدم كلمة مرور افتراضية ثابتة غير معروضة ويضبط `ChangedPassword=0`.
- تغيير كلمة المرور والخروج/keepalive لا يحملان حماية antiforgery مثبتة.
