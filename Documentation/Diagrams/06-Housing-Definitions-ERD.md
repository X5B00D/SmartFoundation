# ERD جزئي لـ Housing Definitions

العلاقات المتصلة FK constraints متحققة من DATACORE الحية في 2026-08-23؛ المنقطة علاقات يستخدمها SQL دون FK حي. Snapshot مرجع مقارنة فقط.

```mermaid
erDiagram
    BUILDING_CLASS ||--o{ BUILDING_DETAILS : "FK class"
    BUILDING_TYPE ||--o{ BUILDING_DETAILS : "FK type"
    BUILDING_UTILITY_TYPE ||--o{ BUILDING_DETAILS : "FK utility"
    MILITARY_LOCATION ||--o{ BUILDING_DETAILS : "FK location"
    MILITARY_AREA ||--o{ MILITARY_AREA_CITY : "FK area"
    MILITARY_AREA_CITY ||--o{ MILITARY_LOCATION : "FK city"
    IDARA ||--o{ MILITARY_LOCATION : "FK idara"
    BUILDING_DETAILS ||--o{ BUILDING_RENT : "FK building"
    BUILDING_RENT_TYPE ||--o{ BUILDING_RENT : "FK rent type"
    BUILDING_DETAILS ||--o{ BUILDING_ACTION : "FK building"
    BUILDING_ACTION_TYPE ||--o{ BUILDING_ACTION : "FK action type"
    BUILDING_DETAILS ||..o{ BUILDING_DETAILS_METER_SERVICES : "procedure join"
    METER_SERVICE_TYPE ||..o{ BUILDING_DETAILS_METER_SERVICES : "IDs 1/2/3"
    IDARA ||..o{ BUILDING_DETAILS : "scope"

    BUILDING_CLASS {
        bigint buildingClassID PK
        bit active
        int IdaraId_FK
    }
    BUILDING_TYPE {
        bigint buildingTypeID PK
        bit active
        int IdaraId_FK
    }
    BUILDING_UTILITY_TYPE {
        bigint buildingUtilityTypeID PK
        bit buildingUtilityIsRent
        bit active
    }
    MILITARY_LOCATION {
        int militaryLocationID PK
        int militaryAreaCityID_FK FK
        bigint IdaraId_FK FK
    }
    BUILDING_DETAILS {
        bigint buildingDetailsID PK
        bigint buildingTypeID_FK FK
        bigint buildingUtilityTypeID_FK FK
        int militaryLocationID_FK FK
        bigint buildingClassID_FK FK
    }
    BUILDING_RENT {
        int buildingRentID PK
        bigint buildingDetailsID_FK FK
        int buildingRentTypeID_FK FK
        decimal amount
        bit active
    }
    BUILDING_DETAILS_METER_SERVICES {
        bigint id PK
        bigint BuildingDetailsID_FK
        int MeterServicesTypeID_FK
        bit active
    }
    BUILDING_ACTION {
        bigint buildingActionID PK
        bigint buildingDetailsID_FK FK
        int buildingActionTypeID_FK FK
    }
```

`V_LastActionForBuilding` View وليس كيان تخزين. أكد الكتالوج الحي عدم وجود FK لـ`BuildingDetailsMeterServices`، لذلك بقيت علاقاته منقطة/مستنتجة. الرسم الأشمل: [19-Housing-Live-ERD.md](19-Housing-Live-ERD.md).
