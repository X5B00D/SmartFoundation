# رسم الطبقات ومراجع المشاريع

درجة الرسم: **مثبت** من ملفات `.csproj` ونقطة التشغيل، مع إظهار SQL Server كوجهة تنفيذ لا كمشروع من الطبقات الأربع.

```mermaid
flowchart TB
    Browser["المتصفح / HTTP Client"]

    subgraph MVC["SmartFoundation.Mvc — التشغيل والعرض"]
        Program["Program.cs\nComposition Root"]
        Controllers["MVC Controllers"]
        Views["Razor Views"]
        Middleware["Middleware + Routing + Session"]
    end

    subgraph UI["SmartFoundation.UI — مكونات العرض المشتركة"]
        PageModel["SmartPageViewModel"]
        Renderer["SmartRenderer"]
        Components["SmartForm / SmartTableDS / Charts / Print"]
    end

    subgraph APP["SmartFoundation.Application — خدمات التطبيق"]
        Masters["MastersServies / BaseService"]
        Mapper["ProcedureMapper"]
    end

    subgraph DATA["SmartFoundation.DataEngine — تنفيذ البيانات"]
        SmartService["ISmartComponentService\nSmartComponentService"]
        Factory["ConnectionFactory"]
        Dapper["Dapper + SqlClient"]
    end

    DB[("SQL Server\nGateway + Feature Procedures")]
    DBSnapshot["SmartFoundation.Database\nSnapshot مرجعي خارج الطبقات"]
    Tests["SmartFoundation.Application.Tests"]

    Browser --> Middleware --> Controllers
    Controllers --> PageModel --> Views --> Renderer --> Components
    Controllers --> Masters --> Mapper
    Masters --> SmartService --> Factory --> Dapper --> DB

    Program -. "يسجل ويكوّن" .-> Middleware
    Program -. "Project Reference" .-> APP
    Program -. "Project Reference" .-> UI
    Program -. "Project Reference مباشر" .-> DATA
    UI -. "Project Reference" .-> DATA
    APP -. "Project Reference" .-> DATA
    DBSnapshot -. "مرجع فقط؛ ليس إثباتاً للحالة الحية" .-> DB
    Tests -. "يختبر Application" .-> APP
```

## قراءة الرسم

- الأسهم المتصلة تمثل مساراً تنفيذياً نموذجياً مثبتاً.
- الأسهم المتقطعة تمثل Project Reference أو علاقة توثيقية.
- وجود Reference مباشر لا يعني بالضرورة استخدامه في كل feature.
