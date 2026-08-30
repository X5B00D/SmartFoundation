# رسم تدفق القراءة والكتابة

درجة الرسم: المسار حتى بوابات SQL **مثبت** من الكود النشط، وربط صفحات المحادثات 1–7 بإجراءات feature downstream **متحقق من DATACORE الحية** في 07A.

```mermaid
flowchart TB
    subgraph READ["مسار القراءة — Housing-style"]
        R1["Browser GET"] --> R2["MVC Action"]
        R2 --> R3["InitPageContext + Session context"]
        R3 --> R4["MastersServies.GetDataLoadDataSetAsync"]
        R4 --> R5["ProcedureMapper\nMastersDataLoad:getData"]
        R5 --> R6["SmartRequest\nOperation = sp"]
        R6 --> R7["SmartComponentService"]
        R7 --> R8["Dapper QueryMultipleAsync"]
        R8 --> R9["dbo.Masters_DataLoad"]
        R9 -. "routing by pageName_" .-> R10["Feature DL procedure"]
        R10 --> R11["Result sets"]
        R11 --> R12["SmartResponse.Datasets -> DataSet"]
        R12 --> R13["SplitDataSet\npermissions + feature tables"]
        R13 --> R14["SmartPageViewModel"]
        R14 --> R15["Thin Razor View -> SmartRenderer"]
        R15 --> R16["HTML Response"]
    end

    subgraph WRITE["مسار الكتابة — Generic CRUD"]
        W1["SmartForm POST\n/crud/insert|update|delete"] --> W2["CrudController"]
        W2 --> W3["Context fields\npageName_ / ActionType / idaraID / entrydata / hostname"]
        W2 --> W4["p01..p50"]
        W4 --> W5["parameter_01..parameter_50"]
        W3 --> W6["MastersServies.GetCrudDataSetAsync"]
        W5 --> W6
        W6 --> W7["ProcedureMapper\nMastersCrud:crud"]
        W7 --> W8["SmartComponentService + Dapper"]
        W8 --> W9["dbo.Masters_CRUD"]
        W9 -. "permission + routing by pageName_ and ActionType" .-> W10["Feature SP"]
        W10 --> W11["IsSuccessful + Message_"]
        W11 --> W12["DataSet -> TempData bucket"]
        W12 --> W13["Redirect"]
    end

    SQL[("SQL Server")]
    R9 --> SQL
    SQL --> R11
    W9 --> SQL
    SQL --> W11
```

## ثوابت العقد

- أسماء السياق وحالتها جزء من العقد ولا تعاد تسميتها منفردة.
- DataEngine يضيف `@` إلى أسماء Dapper parameters؛ Application code يرسل الأسماء دون `@`.
- ترتيب `pNN` له معنى يحدده `ActionType` وإجراء feature.
