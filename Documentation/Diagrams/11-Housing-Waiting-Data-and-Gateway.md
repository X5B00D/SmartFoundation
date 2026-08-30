# بوابات وبيانات قوائم الانتظار والإسناد

```mermaid
flowchart TB
    UI["SmartRenderer\nFormConfig + SmartTableDsModel"] --> C["HousingController partial Actions"]
    C --> MS["MastersServies"] --> DL["dbo.Masters_DataLoad"]
    DL --> P["permission result set\nft_UserPagePermissions"]
    DL --> FDL["8 Housing feature DL procedures"]
    FDL --> V["V_GetFullResidentDetails\nV_WaitingList\nV_MoveWaitingList\nV_Occupant\nV_GetGeneralListForBuilding"]
    UI --> CRUD["CrudController\np01..p50 -> parameter_01..50"]
    CRUD --> MC["dbo.Masters_CRUD"]
    MC --> AUTH{"pageName_ + ActionType\npermission"}
    AUTH --> FSP["8 Housing feature SP procedures"]
    FSP --> BA["BuildingAction ledger"]
    FSP --> AP["AssignPeriod / AssignNote"]
    FSP --> RR["ResidentRentExemption"]
    FSP --> AUD["AuditLog"]
    BA --> V
```

المسار والـ routing والمعاملات متحققة من `DATACORE` الحية. من 17 feature procedures لهذا النطاق، 15 مطابقة و`AssignDL/SP` مختلفان؛ `BuildingRentForOneMonth` فرق إضافي مرتبط بالإعفاء وخارج هذا العدد.
