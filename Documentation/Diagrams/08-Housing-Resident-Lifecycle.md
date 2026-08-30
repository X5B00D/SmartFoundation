# دورة الإقامة والتسليم والتمديد والإخلاء

الأرقام حالات `BuildingActionTypeID` مثبتة من التعريفات الحية ورسائل الواجهة، وليست قائمة seed كاملة. التسكين إلى 2 يشترط حياً أن يكون بعد آخر خروج.

```mermaid
stateDiagram-v2
    [*] --> Handover: تجهيز وتسليم المبنى
    Handover --> ApprovedHouse45: سلسلة HousingHandoverAction
    ApprovedHouse45 --> Meter46: عهد + توجد عدادات
    ApprovedHouse45 --> Ready47: عهد + لا توجد عدادات
    Meter46 --> Ready47: بعد قراءات الخدمات
    Ready47 --> Occupant2: اعتماد التسكين
    ApprovedHouse45 --> Rejected39: إلغاء أول تخصيص
    ApprovedHouse45 --> Ineligible42: إلغاء تخصيص ثان

    Occupant2 --> Extend48: إنشاء إمهال
    Extend48 --> Extend50: تعديل/إلغاء النسخة السابقة
    Extend50 --> Extend48: نسخة إمهال معدلة
    Extend48 --> Finance51: إرسال للمالية
    Finance51 --> Insurance61: تأمين مطلوب
    Finance51 --> Extended24: لا يتطلب تأميناً
    Insurance61 --> Extended24: اعتماد الإمهال
    Extend48 --> Occupant2: إلغاء الإمهال ونسخ أصل الإقامة

    Occupant2 --> Exit54: طلب إخلاء
    Extended24 --> Exit54: طلب إخلاء بعد الإمهال
    Exit54 --> ExitFinance: إرسال للمالية / غرامات
    ExitFinance --> Exited: اعتماد الإخلاء
    Exit54 --> Occupant2: إلغاء الإخلاء + تعطيل آثار النهاية
```

`buildingActionParentID` و`fn_BuildingAction_ChainToRoot` يحفظان التاريخ ويتيحان العودة لأصل الإقامة دون تعديل الحركة السابقة.
