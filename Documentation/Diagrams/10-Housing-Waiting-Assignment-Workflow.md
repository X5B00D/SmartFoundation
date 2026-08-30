# سير الانتظار والإسناد والنقل والإعفاء

```mermaid
flowchart LR
    R["Residents\nإنشاء ملف المستفيد"] --> WR["WaitingListByResident\nانتظار + خطابات"]
    WR --> WL["WaitingList\nالفئات العامة"]
    WR --> OW["OtherWaitingList\nالفئات المحلية"]
    WR --> MR["طلب نقل إدارة"]
    MR --> ML["WaitingListMoveList"]
    ML -->|"رفض"| WR
    ML -->|"قبول + نقل الملف والسجلات"| WR2["WaitingListByResident\nفي الإدارة الجديدة"]
    WL -->|"رأس القائمة فقط"| A["Assign\nمحضر تخصيص"]
    A --> AS["AssignStatus\nمعالجة المحضر"]
    OW -->|"اختيار مبنى"| HP["Housing Handover/Resident"]
    AS --> HP
    HP --> O["Occupant"]
    O --> RE["RentExemption"]
    RE --> BILL["احتساب الإيجار الشهري/الخروج"]
```

الحركات تحفظ كسلسلة في `BuildingAction`; الإلغاء أو التبديل يضيف حركة جديدة ولا يمحو التاريخ.

التعريف الحي يضم نوع الجذر 25 في `V_WaitingList`. `AssignDL` يعرض حالات المبنى 5 و39 و41، بينما `AssignSP` يقبل أيضاً 42؛ وهذا فرق حي موثق.
