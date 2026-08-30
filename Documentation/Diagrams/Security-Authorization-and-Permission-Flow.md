# رسم Authorization وPermissions

MVC والمعاملات مثبتة من الكود؛ `ft_UserPagePermissions` و`GetUserMenuTree` والبوابة ذات العلاقة متحققة حياً ومطابقة للـSnapshot.

```mermaid
flowchart TB
    Session["Session usersID"] --> Get["GET page"] --> Context["InitPageContext إن استدعته Action"] --> DL["Masters_DataLoad\nentrydata + pageName_"]
    Direct["Permission مباشر"] --> Function["ft_UserPagePermissions"]
    Role["UserDistributor -> Distributor -> Role"] --> Function
    DSD["DSD والهيكل"] --> Function
    Distributor["Distributor grants"] --> Function
    General["منحة عامة"] --> Function
    DL --> Function --> Set["result set 0\npermissionTypeName_E"] --> Flags["Controller flags"] --> UI["إظهار/إخفاء UI"]
    UI --> Post["POST /crud/insert|update|delete"]
    Session --> MenuVC["MenuItemsViewComponent"] --> MenuSP["GetUserMenuTree"]
    Function --> MenuSP
    MenuSP --> Tree["permitted menus + ancestors\nprogram nodes"] --> MenuSession["MENU_TREE Session"] --> Navigation["Sidebar + breadcrumb"]
    Client["form/JSON قابل للتعديل\nentrydata / idaraID / pageName_ / ActionType"] --> Post
    Post --> Crud["CrudController\np01..p50 -> parameter_01..50"] --> Gateway["Masters_CRUD"]
    Gateway --> Check{"صلاحية الصفحة والفعل للمستخدم؟"}
    Check -- "لا" --> Deny["رفض"]
    Check -- "نعم" --> Feature["Feature SP"] --> Audit["AuditLog"]
    Feature --> Notify["Notifications_Create"]
    Feature --> Result["IsSuccessful + Message_"]
    Warning["خطر حرج:\nالسياق الأمني من العميل\nلا من Session"]
    Client --> Warning -. "يضعف الفحص ونسبة Audit" .-> Check
```

- UI gating ليس Authorization boundary.
- لا توجد Claims roles أو `[Authorize(Roles=...)]` في المسار المثبت.
- عقد البرامج تظهر عندما تحتوي شجرتها على قائمة مصرح بها؛ العقد الأب قد تظهر مع `HasPermissionForUser=0` لتكوين المسار.
- `GetUserMenuTree` الكامل يُسجل حالياً في console وInformation log.
