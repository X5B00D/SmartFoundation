# تدفق التقارير والتكاملات المشتركة

```mermaid
flowchart LR
    U["مستخدم مصادق عبر Session"] --> P["صفحة برنامج مشمول"]
    P --> G["Masters_DataLoad"]
    G --> D["DATACORE: DL حي"]
    D --> T["DataSet / DataTable"]
    T --> S["SmartTableDS: Screen"]
    T --> Q["DataTableReportBuilder"]
    Q --> PDF["QuestPDF: PDF inline"]
    S --> X["Client Excel / Print"]
    S --> E["POST /exports/pdf/table"]
    E --> PDF2["QuestPdfExportService"]

    U --> N["Notifications API"]
    N --> ND["DATACORE notifications"]

    U --> UP["Excel/PDF uploads"]
    UP --> FS["wwwroot/uploads"]
    FS --> XR["ExcelDataReader"]
    XR --> IMP["Direct SQL import paths"]
```

درجة الإثبات: مسارات MVC والمكتبات من الكود؛ أسماء ومعاملات وتبعيات إجراءات التقارير من كتالوج DATACORE الحي. لم ينفذ تقرير أو import أو Business Stored Procedure.

