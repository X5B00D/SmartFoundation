# التشغيل والنشر والنسخ الاحتياطي واستكشاف الأخطاء

```mermaid
flowchart TD
    SRC["Source + approved configuration names"] --> CI["Restore / Build / Test / Publish"]
    CI --> ART["Versioned Release Artifact"]
    ART --> IIS["IIS + .NET 8 Hosting Bundle"]
    IIS --> APP["Dedicated App Pool / No Managed Code"]
    APP --> MVC["SmartFoundation.Mvc"]
    MVC --> DB["DATACORE"]
    MVC --> FILES["Uploads + fonts + static assets"]
    MVC --> LOGS["IIS / ANCM / ILogger / SQL ErrorLog"]

    DB --> BDB["Full + Differential + Transaction Log backups"]
    BDB --> DRILL["Restore Drill\nTarget RPO 15m / RTO 1h"]
    FILES --> BFS["File backup by retention policy"]
    ART --> BAR["Artifact rollback copy"]
    CFG["Secret store + IIS settings + certificates"] --> BCFG["Protected configuration backup"]
    SCALE["Future multi-instance deployment"] --> KEYS["Distributed Session + shared Data Protection keys"] --> BKEYS["Protected key backup"]

    LOGS --> TRIAGE["Timestamp + URL + environment + correlation"]
    TRIAGE --> CLASSIFY{"Startup / HTTP / SQL / Permission / File"}
    CLASSIFY --> FIX["Scoped correction + smoke test"]
    FIX --> MON["Monitor or rollback"]
```

هذا Runbook توثيقي. أهداف RPO/RTO مستهدفة وتعتمد على سياسة وجدولة ومراقبة واختبارات بيئة الاستضافة؛ لا يثبت الرسم وحده قبول الإنتاج أو تحقيق الأهداف.

