# التقارير والتكاملات والتشغيل والنشر في SmartFoundation

## تحديث التشغيل للإصدار 1.0.0

- استخدمت البيئة المرجعية SQL Server 2019 وWindows Integrated Security. لا تعد Developer Edition متطلب إنتاج؛ يعتمد الإنتاج إصدارًا مدعومًا وEdition مرخصة ومناسبة.
- النموذج الحالي Single Application Server مع Session محلية In-Memory. يتطلب التوسع إعادة تقييم distributed session وData Protection keys وload balancing وhealth checks والمراقبة المركزية.
- CSP مطبقة وفعالة، وإعدادات التوافق الحالية قرار معماري يعاد تقييمه عند تغير Alpine.js أو JavaScript أو مكتبات الواجهة.
- أهداف الاستمرارية التشغيلية المستهدفة: RPO = 15 minutes وRTO = 1 hour. تحقيقها يعتمد على سياسة الإنتاج وجدول Transaction Log Backup والتخزين والمراقبة وRestore Drill.
- Full Backup وDifferential Backup وTransaction Log Backup وRestore Drill أجزاء من النموذج التشغيلي. FULL Recovery Model وصف للبيئة المرجعية وليس ضمانًا لإعداد الإنتاج.
- Application Logging يجب أن يمنع كلمات المرور وSession Data والمعلومات الحساسة غير اللازمة، ويحمي السجلات ويطبق rotation وretention ومزامنة الوقت والوصول المقيد. SIEM/Centralized Logging مسؤولية بنية الاستضافة ما لم يعتمد خلاف ذلك.
- اعتبارات IIS التالية توصيات استضافة وقبول بعد النشر وليست إثباتًا بأنها منفذة على خادم إنتاج بعينه.

## الحالة والنطاق ودرجة الإثبات

- الحالة: مكتمل توثيقياً في 2026-08-23 للمجالات المشتركة المطلوبة فقط.
- البرامج المشمولة: `ControlPanel` و`Housing` و`IncomeSystem` و`ElectronicBillSystem` و`Home` و`Login`، إضافة إلى المكونات المشتركة التي تخدمها.
- مصدر SQL: كتالوج `DATACORE` الحي فقط. نجحت قراءة `sys.procedures` و`sys.parameters` و`sys.sql_expression_dependencies` لـ16 إجراء قراءة/بوابة و95 صف معاملات و111 تبعية مرتبطة بالتقارير.
- لم تُقرأ بيانات أعمال، ولم يُنفذ Business Stored Procedure، ولم تُنفذ كتابة SQL أو Build أو Publish أو Deploy أو Backup أو Restore.
- لم تُعرض أو تُنسخ أي قيمة اتصال أو سر. قيم التهيئة المذكورة أدناه أسماء مفاتيح أو متطلبات فقط.

تصنيف الإثبات في هذا المستند:

- **متحقق حياً**: اسم الإجراء ومعاملاته وتبعياته من كتالوج DATACORE الحي.
- **مثبت من الكود**: سلوك MVC أو المكتبة أو التهيئة الموجود في المستودع، ولم يُشغّل.
- **متطلب تشغيلي**: إجراء يلزم اعتماده في البيئة، وليس دليلاً على أنه مطبق حالياً.
- **فجوة**: لا يوجد دليل كافٍ أو توجد مشكلة مثبتة تحتاج اختباراً أو قراراً تشغيلياً.

## الخلاصة التنفيذية

لا توجد منصة تقارير مستقلة أو SSRS مثبتة في النطاق. التقارير الفعلية تُبنى داخل Actions نفسها من `DataTable` الذي أعادته بوابة القراءة، ثم يحوّلها `DataTableReportBuilder` و`QuestPdfReportRenderer` إلى PDF. توجد أيضاً نقطة عامة `POST /exports/pdf/table` تستقبل الأعمدة والصفوف المعروضة من المتصفح وتستخدم `QuestPdfExportService`. الطباعة على الشاشة تعتمد `SmartTableDS` و`SmartPrint` وiframe/`window.print()`.

التكامل الخارجي الفعلي الوحيد المثبت هو SQL Server. لم يوجد دليل نشط على Email أو SMS أو LDAP/Active Directory أو Cloud File Storage أو قاعدة بيانات خارجية ثانية أو خدمة طرف ثالث.

التطبيق Web على `.NET 8` ونقطة تشغيله `SmartFoundation.Mvc/Program.cs`. ملفات publish هي Folder profiles فقط؛ لا توجد ملفات IIS أو pipeline أو container تثبت شكل الإنتاج. لذلك ما يلي يميز بوضوح بين الإعداد المثبت والمتطلبات التي يجب على فريق التشغيل اعتمادها.

## بنية التقارير والطباعة والتصدير

### المسارات المشتركة

| المسار | المدخل | مصدر البيانات | المخرج | الضبط والصلاحية |
|---|---|---|---|---|
| Action مجال مع `pdf=1` أو `pdf=2` | Query filters وسياق Session | نفس `DataSet/DataTable` القادم من `Masters_DataLoad` | PDF inline عبر QuestPDF | ظهور زر الطباعة مضبوط غالباً بصلاحية الصفحة؛ فرع URL نفسه لا يضيف فحص صلاحية مستقلاً في أغلب Actions. |
| `POST /exports/pdf/table` | `Title`, paper/orientation, headers, columns, rows, filename | الصفوف التي يرسلها العميل، لا استعلام SQL جديد | PDF attachment | `[ApiController]` بلا فحص Session/permission محلي أو حد حجم مثبت؛ يعيد `ex.Message` عند الخطأ. |
| `SmartTableDS` | rows/columns الحالية | نموذج الجدول على الشاشة | Screen، client export، print | `ShowExportCsv/Excel/Pdf` و`ShowPrint*` تتحكم في الظهور؛ ليست بديلاً عن authorization خادمي. |
| `SmartPrint` | `SmartPrintConfig` وDocs/Blocks | ViewModel خادمي | HTML A4 و`window.print()` | قالب A4 Portrait فقط مثبت؛ iframe عام في `SmartRenderer`. |
| `/reports/test`, `/reports/dynamic` | لا مدخل أعمال | بيانات تجريبية منشأة داخل الكود | PDF inline | endpoints تجريبية بلا authorization محلي؛ يجب تعطيلها أو تقييدها في الإنتاج. |

`QuestPDF.Settings.License = Community` والخط `wwwroot/fonts/Tajawal-Regular.ttf` يسجلان عند startup. غياب الخط يمنع بدء التطبيق لأن الفتح غير محاط بمعالجة خطأ.

### جرد تقارير البرامج المشمولة

| البرنامج/الصفحة | التقرير أو المخرج | المعاملات والفلاتر | مصدر البيانات الحي | الصلاحية/الإتاحة المثبتة | قنوات العرض |
|---|---|---|---|---|---|
| ControlPanel / Users | تصدير PDF عام للجدول | الصفوف والأعمدة الظاهرة | بيانات الصفحة عبر بوابات ControlPanel الموثقة سابقاً؛ endpoint لا يعيد الاستعلام | `ShowExportPdf=true`; لا gate مستقل في endpoint | Screen وPDF؛ CSV/Excel معطلان في النموذج المعروض. |
| Housing / BuildingDetails | سجل المباني بحسب نوع المنفعة | `pdf=1`, query `U` -> utility type | `Masters_DataLoad -> Housing.BuildingDetailsDL`; المعامل الحي `@buildingUtilityTypeID_FK`; يعتمد على `BuildingDetails`, الأنواع، الإيجار، العدادات و`V_LastActionForBuilding` | زر الطباعة مربوط حالياً بـ`INSERTBUILDINGDETAILS`، وهو coupling يحتاج مراجعة | Screen وPDF. |
| Housing / BuildingType | تقرير الأنواع وخطاب تجريبي | `pdf=1` تقرير، `pdf=2` خطاب | `Housing.BuildingTypeDL`; يعتمد حياً على `Housing.BuildingType` و`dbo.City` | أزرار الطباعة القياسية معطلة، لكن Actions إضافية تنادي الفروع | Screen وPDF. |
| Housing / Residents | قائمة المستفيدين وخطاب | `pdf=1/2`; لا filter أعمال إضافي | `Housing.ResidentsDL`; يعتمد حياً على `V_GetFullResidentDetails` وGender/MaritalStatus/Nationality/Rank/militaryUnit | زر التقرير يستخدم `INSERTRESIDENTS` بدل صلاحية Print مستقلة | Screen وPDF؛ export العام معطل. |
| Housing / WaitingList | سجلات فئة الانتظار | `pdf=1`, `U=WaitingClassID` | `Housing.WaitingListDL(@WaitingClassID_nvar)`؛ يعتمد على `V_WaitingList`, resident, class, action type | `MOVETOASSIGNLIST` مع وجود بيانات | Screen وPDF. |
| Housing / OtherWaitingList | سجلات فئة الانتظار الأخرى | `pdf=1`, `U=WaitingClassID` | `Housing.OtherWaitingListDL(@WaitingClassID_nvar)`؛ resident/building/waiting dependencies حية | `MOVETOOCCUPENTPROCEDURES` مع وجود بيانات | Screen وPDF. |
| Housing / Assign | خطاب/مخرج إسناد | branch PDF يستعمل سياق الفترة/السجل كما يبنيه Action | `Housing.AssignDL(@WaitingClassID,@AssignPeriodID)`؛ `AssignPeriod`, `V_WaitingList`, resident/building | أزرار الجدول العامة معطلة؛ Action خطاب مخصص موجود | Screen وPDF Letter. |
| Housing / AssignStatus | إشعار مراجعة | `pdf=2`, `rowId`, `U=AssignPeriodID` | `Housing.AssignStatusDL(@AssignPeriodID)`؛ الفترة والانتظار والمستفيد والمبنى | `ShowPrint1=true` بلا gate مباشر ظاهر؛ عمليات الحالة نفسها permission-gated | Screen وPDF Letter. |
| Housing / HousingResident | قائمة المستفيدين | `pdf=1` | `Housing.HousingResidentDL`; يعتمد على resident/waiting/action/meter | لا يظهر زر Print1، لكن Excel وPDF العامان مفعّلان؛ صلاحيات العمليات لا تثبت صلاحية تصدير مستقلة | Screen وExcel client وPDF. |
| Housing / HousingExtend | قائمة وخطاب | `pdf=1` قائمة، `pdf=2` مع `rowId/NID` | `Housing.HousingExtendDL`; resident/waiting/rent/bills/insurance/reasons | القائمة مرتبطة بـ`HOUSINGEXTEND`; الخطاب يستدعى من صف مختار | Screen وPDF. |
| Housing / HousingExit | قائمة وخطاب إيقاف حسم | `pdf=1` قائمة، `pdf=2` مع `rowId/NID` | `Housing.HousingExitDL(@NationalID)`؛ resident/waiting/bills/action/meters | `ShowPrint1=true` دون اسم صلاحية طباعة مستقل ظاهر | Screen وPDF. |
| IncomeSystem / DeductListReport | مسير الاستقطاع حسب الخدمة والفترة | نوع خدمة ثم فترة؛ `pdf` | **فجوة حية:** لا branch لـ`DeductListReport` في بوابات DATACORE، لذلك لا مصدر تقرير موصول فعلياً | `PRINTDEDUCTLISTREPORT` | Screen/PDF مصممان، لكن البيانات الحية غير موصولة. |
| IncomeSystem / FinancialAuditForExtendAndEvictions | قائمة التدقيق المالي | `pdf=1`; resident/action context | `Housing.FinancialAuditForExtendAndEvictionsDL(@residentInfoID)`؛ ملخصات المقيم والفواتير والمبنى والانتظار | صلاحيات التدقيق/المراجعة/الدفع/التسوية؛ لا صلاحية Print مستقلة ظاهرة | Screen وPDF. |
| IncomeSystem / FinancialAuditForUser | شاشات تدقيق مستفيد | `NationalID` -> `@NationalID` | `Housing.FinancialAuditForUserDL`; resident, bills, payments, rent, waiting | صلاحيات الصفحة والعمليات الموثقة في مستند IncomeSystem | Screen؛ إعدادات CSV/Excel معطلة، ولا فرع PDF مثبت في Action. |
| IncomeSystem / ExtendInsurance | تقريران مصممان | `pdf=1/2` | `Housing.ExtendInsuranceDL`; insurance/resident/waiting/users | أزرار Print القياسية معطلة؛ Actions إضافية موجودة | Screen وPDF، لكن العنوان واسم الملف منسوخان من BuildingType. |
| ElectronicBillSystem / AllMeterRead | قائمة قراءات | `pdf=1`, filter `U=MeterServiceTypeID` -> `@meterServiceTypeID_FK` | `Housing.AllMeterReadDL`; periods, reads, bills, service types, meter views/functions | صلاحيات فتح/إغلاق/قراءة/تعديل/حذف؛ لا Print permission مستقلة | Screen وPDF؛ أزرار export في الجداول معطلة. |
| ElectronicBillSystem / MeterReadForOccubentAndExit | تقرير حركة/قراءات | `pdf=1`, `U=residentInfoID` -> `@residentInfoID` | `Housing.MeterReadForOccubentAndExitDL`; resident/waiting/building/meter/read/bill | صلاحيات إدخال/اعتماد القراءة؛ أزرار print/export معطلة حالياً | Screen وPDF قابل عبر URL فقط. |
| ElectronicBillSystem / Meters وFixedAmount | جداول تشغيل | filters الصفحة | `Housing.MetersDL` و`MeterServiceTypeFixedAmountDL` موثقان في المرحلة 9 | العمليات permission-gated | Screen؛ الطباعة/التصدير معطلان في النماذج الحالية. |

### جودة التقارير وفجواتها

- تقارير كثيرة تستخدم `reportId: "BuildingType"` واسم ملف `BuildingType.pdf` وعناوين مثل «قائمة المستفيدين» حتى في العدادات والتدقيق المالي والتأمين؛ هذه مشكلة naming/content مثبتة.
- لا يوجد اختبار بصري للتقارير الحالية، ولا اختبار للأعمدة العربية الطويلة أو الحجم الكبير أو بيانات null.
- export العام يثق في rows/columns المرسلة من العميل؛ لا يجوز اعتباره إعادة تحقق من المصدر أو الصلاحية.
- صلاحيات الطباعة غير موحدة: بعضها يعيد استخدام صلاحية Insert/Move، وبعضها ظاهر دون gate مستقل، وبعض PDF branches قابلة بالـquery رغم إخفاء الزر.
- لا توجد قيود request size أو حد صفوف أو rate limit مثبتة لـ`/exports/pdf/table`.
- CSV/Excel في `SmartTableDS` سلوك عميل؛ لا توجد مكتبة server-side لإنشاء `.xlsx` مثبتة. `ExcelDataReader 3.8.0` للقراءة والاستيراد فقط.

## المكتبات المرتبطة

| المكتبة | الإصدار المثبت | الاستخدام | ملاحظات تشغيلية |
|---|---:|---|---|
| QuestPDF | `2025.12.1` | PDF العام وتقارير DataTable والخطابات | Community license في startup؛ يحتاج خط Tajawal وصلاحية قراءة assets وذاكرة تكفي لحجم التقرير. |
| ExcelDataReader + DataSet | `3.8.0` | قراءة `.xls/.xlsx` في UploadExcel وIncome import | أول Sheet مع header؛ ليست مكتبة export. يلزم اختبار الملفات الكبيرة/المشفرة/التالفة. |
| Dapper / SqlClient | عبر Application/DataEngine | تنفيذ بوابات SQL وdirect import paths | connection string سري، وtimeouts ليست موحدة. |

## التكاملات

### APIs الداخلية

| API | الوظيفة | المصادقة/الصلاحية | Timeout/Error handling |
|---|---|---|---|
| `/api/Notifications/*` | أحدث الإشعارات وتعليم read/clicked | يرفض غياب `usersID` | طبقة الخدمة تسجل الأخطاء؛ get-latest يعيد رسالة عامة. واجهة العميل تستخدم abort بعد 10 ثوانٍ. |
| `POST /exports/pdf/table` | PDF من بيانات العميل | لا فحص Session/permission محلي مثبت | try/catch لكنه يعيد `ex.Message`; لا timeout/rate limit. |
| `POST /smart/execute` | تنفيذ `SmartRequest` عبر DataEngine | لا حارس Session محلي في Controller | whitelist للأسماء داخل DataEngine، logging للأخطاء؛ سطح قوي يحتاج authorization واختبار abuse. |
| `/reports/test`, `/reports/dynamic` | PDF تجريبي | لا gate مثبت | بيانات داخلية؛ يجب ألا تكون عامة في الإنتاج. |

لا توجد وثائق OpenAPI/Swagger أو versioning أو CORS policy مخصصة أو API keys مثبتة.

### Email وSMS وLDAP والخدمات الخارجية

- **Email/SMTP:** لا استخدام نشط لـ`SmtpClient`, MailKit أو مزود بريد في المشاريع المشمولة.
- **SMS:** لا Twilio أو بوابة SMS أو HTTP client مخصص مثبت.
- **LDAP/Active Directory:** لا `DirectoryServices`, `LdapConnection` أو Windows Authentication مثبتة؛ الدخول قاعدة بيانات/Session.
- **External databases:** connection واحدة منطقياً باسم `ConnectionStrings:Default` إلى DATACORE. لم يوجد اتصال قاعدة ثانية مثبت.
- **Third-party/cloud:** لا تكامل S3/Azure Blob/SharePoint أو API طرف ثالث مثبت في النطاق.
- أسماء Notifications في SQL ليست دليلاً على Email/SMS؛ المثبت إشعارات داخل التطبيق فقط.

### File storage وUploads

| المسار | الأنواع والحد | التخزين | دورة الحياة |
|---|---|---|---|
| Housing UploadExcel | `.xls/.xlsx`, MIME allow-list، 10MB، ملف واحد، signature validation | `wwwroot/uploads/excel` باسم GUID؛ metadata في Session | import مباشر إلى DATACORE عند الاعتماد؛ توجد فجوة TVP موثقة، وتعليق حذف اختياري لا يثبت تنظيفاً عاماً. |
| Income ImportExcelForBuildingPayment | `.xls/.xlsx`, MIME/signature، 10MB | نفس مجلد uploads/excel وSession | يحذف الملف بعد نجاح العملية/فشل القراءة؛ توجد دالة تنظيف أقدم من 7 أيام لكن يلزم إثبات استدعائها وجدولتها. |
| UploadLab | PDF/XLS/XLSX، 10MB، ملف واحد | `wwwroot/uploads/lab` وSession فقط | لا SQL؛ لا حذف من الصفحة ولا retention مثبت. المجلد مستبعد من Content في csproj، وقد لا يُنشأ في publish. |

المجلدان تحت web root، لذا الملفات قد تصبح قابلة للوصول المباشر إن عُرف URL. لا فحص malware، ولا تشفير at rest، ولا authorization على static files، ولا storage quota مثبتة. ينبغي نقل المرفقات الحساسة خارج web root وتقديمها عبر Action مفوض، لكن هذا توصية لا وصف للحالة الحالية.

## بيئة التطوير والتشغيل

### المتطلبات المثبتة

- `.NET 8` SDK يدعم `net8.0` وC# 12. لا يوجد `global.json` لتثبيت patch SDK؛ يجب على الفريق اعتماد إصدار SDK موحد متوافق.
- Visual Studio 2022 بإصدار يدعم .NET 8 وASP.NET and web development. SQL project في الحل قد يحتاج SQL Server Data Tools؛ ليس ضرورياً لبناء مشروع MVC منفرداً.
- SQL Server يمكنه استضافة DATACORE وتعريفاتها الحالية؛ الإصدار/edition/compatibility لم يُستعلم في هذه المرحلة، لذلك لا يُفترض رقم بعينه.
- Node/npm مطلوبان فقط لبناء Tailwind (`tw:watch`, `tw:build`) عندما تتغير assets.
- Startup Project الصحيح: `SmartFoundation.Mvc/SmartFoundation.Mvc.csproj`. ملف `Program.cs` في جذر المستودع ليس نقطة تشغيل.

### أوامر موثقة للاستخدام، غير منفذة في هذه المرحلة

```powershell
dotnet restore SmartFoundation.sln
dotnet build SmartFoundation.Mvc/SmartFoundation.Mvc.csproj
dotnet run --project SmartFoundation.Mvc/SmartFoundation.Mvc.csproj
dotnet test SmartFoundation.Application.Tests/SmartFoundation.Application.Tests.csproj
npm install --prefix SmartFoundation.Mvc
npm --prefix SmartFoundation.Mvc run tw:build
```

البناء الكامل للحل قد يتطلب tooling لمشروع `SmartFoundation.Database.sqlproj`. قاعدة SQL داخل المستودع Snapshot مرجعي وليست مصدر نشر أو حقيقة حية.

### Development وProduction وConfiguration

- ASP.NET Core يدمج `appsettings.json` ثم `appsettings.{Environment}.json` ثم environment variables والمصادر القياسية.
- المفاتيح المهمة: `ConnectionStrings:Default`, `SmartData:Whitelist`, `SmartData:MaxPageSize`, `Logging:LogLevel`، و`AllowedHosts`.
- لا تُخزن الأسرار في Documentation أو source control. استخدم environment variables أو secret store معتمد؛ مثال اسم فقط: `ConnectionStrings__Default`.
- Development launch profiles موجودة لـProject/IIS Express، لكنها لا تثبت إعداد خادم الإنتاج.
- Production config يحتوي connection وAI keys في الملف؛ يجب تدقيق تاريخ Git وتدوير أي قيمة حقيقية نُشرت سابقاً، دون نسخها إلى وثائق أو logs.
- `UseHsts` و`UseHttpsRedirection` يعملان دون شرط بيئة في الكود. Secure cookies تتطلب HTTPS حتى في Development؛ قد يفشل Session على HTTP محلي.

## النشر على IIS: Runbook توثيقي فقط

لم يُنفذ نشر. ملفات `FolderProfile*.pubxml` تنشر FileSystem إلى مسارين محليين مختلفين مع `DeleteExistingFiles=false`; لا تثبت IIS site أو App Pool أو طريقة promotion.

### المتطلبات

1. Windows Server مدعوم، IIS مع ASP.NET Core Module، و.NET 8 Hosting Bundle مطابق للمعمارية.
2. Application Pool مخصص، `No Managed Code`, Integrated pipeline، وهوية خدمة محدودة الصلاحيات. `AnyCPU` مثبت؛ اختر x64 وفق معمارية الخادم والمكتبات التشغيلية الحالية.
3. IIS Site/Binding باسم وhostname معتمدين، وشهادة TLS صحيحة وسلسلة موثوقة وتجديد مراقب.
4. مجلد إصدار غير قابل للكتابة لهوية App Pool، باستثناء مجلدات runtime المطلوبة صراحة: uploads، logs إن كان provider ملفياً، ومكان Data Protection keys إن اعتمد.
5. connection settings تحقن من بيئة آمنة. امنع تقديم `appsettings*` وlogs وملفات النسخ عبر static hosting.
6. انسخ الخطوط والأصول التشغيلية المطلوبة وتحقق من صلاحيات قراءتها قبل التحويل.

### خطوات Publish/Deploy المقترحة

1. اعتمد commit/tag وغيّر configuration إلى Release في pipeline موثوق.
2. نفذ restore/build/test/publish في CI أو محطة بناء؛ لا تبنِ على خادم IIS.
3. افحص artifact بحثاً عن أسرار، وتحقق من font/model/docs/static assets و`web.config` المولد.
4. خذ نسخة احتياطية معتمدة قبل التغيير وفق سياسة المؤسسة، ثم أوقف استقبال الطلبات بطريقة drain/app_offline.
5. انشر إلى مجلد إصدار جديد، اضبط ACLs، وبدّل binding/path أو symlink/junction بطريقة قابلة للرجوع.
6. شغّل smoke tests: startup، Login test account، Session، صفحة read-only، PDF صغير، upload غير حساس في بيئة اختبار، AI إن كان enabled، واتصال DATACORE.
7. راقب Event Viewer/IIS/ASP.NET/SQL logs، ثم أغلق نافذة التغيير أو نفذ rollback للـartifact السابق عند الفشل.

هذه خطوات توثيقية وليست دليلاً على تطبيقها.

### Reverse proxy وTLS وForwarded Headers

- HSTS/HTTPS redirection/security headers مثبتة في التطبيق.
- لا `UseForwardedHeaders` ولا `ForwardedHeadersOptions` مثبتين. خلف IIS خارج العملية قد يعالج ASP.NET Core Module بعض المعلومات، لكن أي proxy إضافي أو load balancer يحتاج Trusted Proxies/Networks وترتيب middleware قبل redirect/session/logging.
- الكود يقرأ `X-Forwarded-For` في سياقات سابقة دون سياسة trust موحدة؛ لا تعتمد عليه للتدقيق قبل ضبط forwarded headers.
- TLS termination، cipher policy، شهادة الإنتاج وHTTP→HTTPS binding فجوات بنية تحتية غير موجودة في المستودع.

## النسخ الاحتياطي والاستعادة

لم تُنفذ أي عملية. المطلوب خطة مترابطة واختبار استعادة دوري، لا مجرد نسخ ملفات منفصلة.

| الأصل | ما يجب نسخه | نقاط الاستعادة والتحقق |
|---|---|---|
| DATACORE | Full backups وفق RPO، Differential/Log backups إذا كان Recovery Model والسياسة يسمحان، ومفاتيح/شهادات تشفير SQL إن وجدت | `RESTORE VERIFYONLY` لا يكفي وحده؛ نفذ استعادة اختبارية مع DBCC وسيطرة وصول، ثم smoke test لتوافق التطبيق. الإصدار/Recovery Model/SQL Agent jobs فجوات حالية. |
| Uploads/attachments | `wwwroot/uploads/excel` و`wwwroot/uploads/lab` إن اعتبرت سجلات لازمة | نسخ متسق مع DB عند وجود references، retention واضح، malware scan، تشفير، وتجربة استرجاع ملف. بعض Excel مؤقت ويجب ألا يتحول تلقائياً إلى backup دائم. |
| Configuration | أسماء الإعدادات ونسخ آمنة من قيم الإنتاج في secret manager/IIS configuration | لا تعِد أسراراً قديمة بلا تدوير؛ تحقق من connection وAllowedHosts وwhitelist بعد الاستعادة. |
| Application artifact | حزمة الإصدار، `web.config`, static assets، وخط Tajawal | احتفظ بـchecksums ونسخة الإصدار السابق؛ source وحده لا يكفي لاستعادة سريعة. |
| Data Protection keys | key ring إذا تم تخصيصه لاحقاً | لا يوجد `PersistKeysToFileSystem/Redis/DB` مثبت حالياً. المفاتيح الافتراضية قد تتغير بين instances/redeploy؛ يؤثر ذلك على cookies/antiforgery. اعتمد مخزناً مشتركاً محمياً قبل scale-out. |
| IIS/OS | site bindings، App Pool identity/settings، ACLs، certificates references، environment variables | صدّر configuration بطريقة آمنة، ولا تضع private keys في repo. اختبر إعادة بناء خادم جديد. |
| Logs/Audit | logs التشغيلية بحسب retention، وDATACORE `AuditLog/ErrorLog` ضمن backup القاعدة | حافظ على الوصول المقيد والسلامة والحجم؛ لا توجد سياسة retention مثبتة. |

يجب تعريف RPO/RTO، مالك النسخ، الجدول، التشفير، off-site/immutable copy، alerting، وموعد restore drill. كلها فجوات تنظيمية حالياً.

## استكشاف الأخطاء

### أين تبدأ

1. سجل وقت المشكلة، URL، environment، المستخدم/Idara دون كلمة مرور أو token، correlation إن وجد، والعملية المطلوبة.
2. راجع IIS access logs وASP.NET stdout/Event Viewer إن فشل startup، ثم application `ILogger` وSQL `ErrorLog` وفق صلاحية قراءة معتمدة.
3. افصل بين خطأ أعمال 50001..50999 ورسالة تنفيذ عامة، وبين exception اتصال/تهيئة.
4. لا تعِد تنفيذ write/import تلقائياً قبل معرفة ما إذا كان transaction التزم؛ النظام لا يملك idempotency عامة.

### مصفوفة الأعراض

| العرض | فحوص آمنة | الأسباب المرجحة/الإجراء |
|---|---|---|
| التطبيق لا يبدأ | Event Viewer/ANCM stdout مؤقتاً، وجود runtime والخط، ACLs، environment | Hosting Bundle مفقود، `Tajawal-Regular.ttf` مفقود، config غير صالح، أو صلاحيات غير كافية. عطّل stdout بعد التشخيص ولا تترك أسراراً في السجل. |
| 500/502.5 على IIS | App Pool state، `dotnet --info` تشغيلياً، web.config، process identity | runtime mismatch أو startup exception. لا تمنح Full Control للمجلد كله كحل سريع. |
| redirect loop/Session مفقودة | HTTPS، Secure cookie، SameSite/domain، ترتيب Session، تعدد instances | Cookie `Secure=Always`; Memory cache غير مشترك. scale-out يحتاج distributed cache وData Protection مشتركة. |
| Login يفشل | log العام، اتصال DATACORE، وجود إجراء login في whitelist/mapper، وقت الخادم | لا تسجل password أو connection. لا تختبر بحساب إنتاجي دون موافقة. |
| Permission button مفقود | first DataTable result، `permissionTypeName_E`, pageName/action casing، Session Idara | افصل بين بيانات seed/gateway والـUI. إخفاء الزر لا يثبت منع endpoint. |
| SQL timeout/connection | network/DNS/TLS، pool، command timeout، blocking عبر DBA | Home direct command=60s وIncome import=120s؛ باقي paths قد تعتمد defaults. لا تضف retry لعملية write قبل idempotency. |
| خطأ 50001 | الرسالة الوظيفية والمدخلات والحالة الحالية | Business validation؛ صحح الطلب ولا تعاملها كعطل بنية. |
| خطأ SQL غير متوقع | application log + `dbo.ErrorLog` مع DBA، procedure/page/action | `Masters_CRUD` يسجل غير 50001..50999؛ بعض Controllers تعيد `ex.Message` وهي فجوة كشف معلومات. |
| PDF فارغ | filter/query، dt المختار، permission، logo/font، route | بعض التقارير تطبع `dt1` فقط وبعضها عناوين منسوخة. `DeductListReport` غير موصول حياً. |
| PDF بطيء/ذاكرة مرتفعة | عدد الصفوف/الأعمدة وحجم الطلب، CPU/memory | لا limits عامة؛ قلل dataset وأضف حدوداً واختبارات تحميل قبل الإنتاج. |
| Excel لا يقرأ | extension/MIME/signature، حماية الملف، أول sheet/header، 10MB | ExcelDataReader؛ أعد Save As دون تشفير في بيئة آمنة. لا ترسل `ex.Message` للمستخدم. |
| Upload 403/500 | ACL المجلد، وجود المجلد بعد publish، disk quota، antiforgery/Session | امنح Modify للمجلد المحدد فقط. `uploads/lab` قد لا ينسخ بسبب csproj. |
| ملف upload مكشوف | اختبر URL المباشر بسياسة معتمدة | الملفات تحت web root. انقلها خارج web root أو احمِ تقديمها عبر endpoint. |
| AI لا يبدأ | model path، RAM/CPU، file ACL، options | model يحمل عند startup؛ غيابه fatal. Provider option لا يبدل التسجيل الحالي تلقائياً. |
| AI timeout | `AI_TIMEOUT`, queue/pool، max parallel، حجم prompt | مهلة active 8s ولا retry. راقب saturation وخفف tokens/context أو وسّع الموارد بعد قياس. |
| Notifications تفشل | Session، browser fetch timeout 10s، SQL procedures/logs | APIs ترفض Session المفقودة؛ لا يوجد retry تلقائي مثبت. |
| عنوان/host/IP غير صحيح | proxy chain وforwarded headers | لا trust policy مثبتة. اضبط Forwarded Headers قبل الاعتماد التدقيقي. |

### Logging ومخاطر البيانات

- providers الافتراضية لـASP.NET Core فقط مثبتة من الكود؛ لا Serilog/NLog/file sink أو central aggregation مثبت.
- لا global exception handler مثبت في `Program.cs`; معالجة الخطأ موزعة، وبعض endpoints ترجع `ex.Message`.
- `MastersServies` يطبع raw menu JSON وfirst row إلى console، ويسجل في موضع parameters كاملة؛ يجب مراجعة PII/secrets قبل جمع مركزي.
- `AuditLog` و`ErrorLog` موجودان حياً ضمن DATACORE، لكن لم تُقرأ صفوفهما ولم تثبت retention/alerting/immutability.
- اعتمد structured logging مع correlation ID وredaction، وحدد مستويات Production، واجمع IIS/ANCM/app/SQL في منصة مراقبة مع صلاحيات محدودة.

## الفجوات التشغيلية ذات الأولوية

1. لا artifacts بنية تحتية تثبت IIS/App Pool/TLS/reverse proxy/ACLs/monitoring/backup jobs أو restore drills.
2. لا Forwarded Headers policy، ولا distributed Session أو Data Protection key ring مشترك للـscale-out.
3. endpoints قوية أو تجريبية بلا authorization محلي واضح: exports، reports demos، وsmart execute.
4. Permission الطباعة غير موحدة، وPDF URL branches لا تعيد فحص صلاحية طباعة مستقلة.
5. `DeductListReport` بلا routing حي، وتقارير عديدة تحمل عناوين وأسماء ملفات منسوخة.
6. لا حدود حجم/صفوف أو rate limiting للتصدير العام، ولا اختبار PDF بصري/تحميل.
7. uploads تحت web root، ولا malware scan/at-rest encryption/quota/retention موحد؛ UploadLab بلا حذف مثبت ومجلده قد يغيب عن artifact.
8. لا Email/SMS/LDAP integrations مثبتة؛ يجب عدم إدراجها كمتطلبات تشغيل قبل قرار معماري.
9. logging غير مركزي، ولا global exception page/handler، وتوجد احتمالات PII أو internal exception leakage.
10. إصدار SQL Server وRecovery Model وSQL Agent jobs وRPO/RTO وسياسات retention لم تتحقق ضمن مصادر catalog المسموحة.

## الأدلة والملفات المرتبطة

- نقطة التشغيل: `SmartFoundation.Mvc/Program.cs` و`SmartFoundation.Mvc/SmartFoundation.Mvc.csproj`.
- التقارير: `Controllers/ReportsController.cs`, `Controllers/ExportsController.cs`, `Reports/*`, `Services/Exports/Pdf/*`, و`SmartFoundation.UI` SmartTable/SmartPrint.
- التكاملات: `NotificationsController.cs` و`SmartComponentController.cs`.
- الرفع: Housing `UploadExcelController`, `UploadLabController`، وIncome `ImportExcelForBuildingPayment.cs`.
- قواعد البيانات الحية: [11-Live-Database-and-ERD.md](11-Live-Database-and-ERD.md) و[07A-Live-Database-Reconciliation.md](07A-Live-Database-Reconciliation.md).
- الرسومات: [21-Reports-and-Integrations-Flows.md](../Diagrams/21-Reports-and-Integrations-Flows.md) و[22-Deployment-Backup-and-Troubleshooting.md](../Diagrams/22-Deployment-Backup-and-Troubleshooting.md).

