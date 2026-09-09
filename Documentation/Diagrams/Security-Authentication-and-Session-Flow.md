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
    Success -- "نعم" --> Claims["ClaimsIdentity + Cookie Authentication ticket"] --> Session["Session server-side\nidentity + organization + presentation"]
    Session --> Home["/Home/Index"] --> Guard["SessionGuardMiddleware\nCookie/Claim + Session consistency"] --> LocalGuard["InitPageContext\nusersID required"] --> HomeSideEffect["GET runs monthly billing SP\nthen Masters_DataLoad"]
    HomeSideEffect --> Page["Home view + shared layout"]
    Session --> Change["POST /Login/ChangePassword\nSession usersID"] --> Reset["ReSetUserPassword\nCHANGEUSERPASSWORD"]
    Reset --> Policy["server policy: 8+ chars\nEnglish letter + digit\nold password + different new"] --> ReLogin["ChangedPassword=1\nUI logs out for re-login"]
    Page --> Logout["POST logout"] --> Clear["SignOutAsync + Session.Clear"] --> Get
```

- Cookie Authentication ticket وSession مكونان متكاملان، ويقارن SessionGuard الهوية بينهما.
- ترتيب middleware الحالي: Session ثم Authentication ثم Authorization ثم SessionGuardMiddleware.
- `RESETUSERPASSWORD` الحي ما زال يستخدم كلمة مرور افتراضية ثابتة غير معروضة ويضبط `ChangedPassword=0`.
- الوصف السابق لغياب Claims وSignInAsync وSessionGuard الفعال حالة تاريخية مغلقة ولا يمثل الإصدار 1.0.0.
