# التدفق الكامل لـ Housing Procedures

المسار حتى البوابات **مثبت**؛ feature routing **متحقق حياً**، مع فروق Resident/Extend/Exit المفصلة في 07A.

```mermaid
flowchart TB
    U["المستخدم يفتح صفحة Housing Procedure"] --> V["Razor View رقيقة / SmartRenderer"]
    V --> C["HousingController Action"]
    C --> S["InitPageContext + Session + query filters"]
    S --> MS["MastersServies.GetDataLoadDataSetAsync"]
    MS --> PM["ProcedureMapper: MastersDataLoad:getData"]
    PM --> MDL["dbo.Masters_DataLoad"]
    MDL --> PERM["ft_UserPagePermissions: result set 0"]
    MDL --> FDL["HousingResident/Handover/Extend/Exit DL"]
    FDL --> DS["DataSet feature tables"]
    PERM --> G{"صلاحية الصفحة؟"}
    G -- "لا" --> DENY["Home/Index + رسالة رفض"]
    G -- "نعم" --> VM["SmartPageViewModel + forms + table"]
    DS --> VM
    VM --> ACT{"اختيار عملية"}
    ACT --> CRUD["CrudController: pNN إلى parameter_NN"]
    CRUD --> MCS["MastersServies.GetCrudDataSetAsync"]
    MCS --> MC["dbo.Masters_CRUD"]
    MC --> AUTH{"pageName + ActionType permission"}
    AUTH -- "لا" --> FAIL["IsSuccessful=0"]
    AUTH -- "نعم" --> SP["Feature SP داخل transaction"]
    SP --> BA["إضافة BuildingAction / آثار مالية"]
    BA --> AUD["dbo.AuditLog"]
    AUD --> OUT["IsSuccessful/Message_ -> TempData -> redirect"]
```

ملاحظة: فرع Handover في snapshot يفحص وجود صلاحية للصفحة لكنه لا يقارن `permissionTypeName_E` بـ `ActionType`.
