# معمارية SmartFoundation والمكونات المشتركة

> تحديث نهائي 2026-08-23: يثبت [توثيق DATACORE وERD](11-Live-Database-and-ERD.md) أن البرامج المشمولة تستخدم فعلياً `dbo` و`Housing` فقط؛ IncomeSystem وElectronicBillSystem اسما برنامجين وليسا Schemas حية. كما يوثق 274 كائناً ضمن النطاق وأربعة ERDs.

## حالة المستند وحدوده

- المهمة: تحليل معمارية النظام والمكونات المشتركة.
- الحالة: مكتملة على مستوى الأدلة الموجودة في المستودع بتاريخ 2026-08-21.
- النطاق: المشاريع الأربع الفعلية، نقطة التشغيل، HTTP pipeline، Dependency Injection، Configuration، Session، ووصف معماري أولي للمصادقة والترخيص والتسجيل ومعالجة الأخطاء، ومسارا القراءة والكتابة، ومكونات UI المشتركة.
- خارج النطاق: تحليل الأمان التفصيلي، تحليل البرامج صفحة بصفحة، وإثبات حالة قاعدة البيانات الحية.
- قاعدة الأدلة: الكود النشط أولاً. ملفات `SmartFoundation.Database` استُخدمت فقط لتأكيد شكل بوابات SQL والمسار المرجعي، وليست دليلاً على النسخة الحية.
- لم تُعرض أي Connection String أو قيمة سرية في هذا المستند.

## مفتاح درجة الثقة

| الوسم | المعنى |
| --- | --- |
| **مثبت** | تؤيده ملفات تنفيذ أو إعدادات نشطة محددة. |
| **مستنتج** | نتيجة منطقية من أكثر من دليل، لكن لم تُثبت باختبار تشغيل أو بيئة حية. |
| **غير متحقق منه** | لا تكفي أدلة المستودع لإثباته، أو يحتاج فحصاً تشغيلياً/بيئياً لاحقاً. |

## الخلاصة المعمارية

**مثبت:** التطبيق الفعلي هو ASP.NET Core MVC على .NET 8، ونقطة تركيبه وتشغيله هي `SmartFoundation.Mvc/Program.cs`. يتكون المسار التطبيقي الأساسي من أربع طبقات مشاريع: MVC للتشغيل والعرض، UI لمكونات العرض المشتركة، Application للخدمات وربط العمليات بإجراءات الدخول، وDataEngine لتنفيذ Dapper والاتصال بـ SQL Server.

**مثبت:** نمط Housing الحالي هو المرجع الأقوى للمسار السائد. القراءة تمر غالباً من Controller إلى `MastersServies` ثم `ProcedureMapper` ثم `SmartComponentService` ثم `dbo.Masters_DataLoad`، ومنها إلى إجراء feature downstream. الكتابة تمر من نماذج `SmartFoundation.UI` إلى `/crud/insert|update|delete` ثم `CrudController`، الذي يحول `p01..p50` إلى `parameter_01..parameter_50` قبل الوصول إلى `dbo.Masters_CRUD`.

**مثبت:** واجهات Housing رقيقة على مستوى Razor؛ يبني Controller تكوين الصفحة على الخادم، ثم تستدعي View مكون `SmartRenderer` الذي يوزع النموذج على `SmartForm` و`SmartTableDS` و`SmartDatePicker` و`SmartPrint` و`SmartCharts` بحسب الخصائص المتاحة.

الرسم العام: [01-System-Layers-and-References.md](../Diagrams/01-System-Layers-and-References.md).

## المشاريع والطبقات الأربع الفعلية

| الطبقة | المشروع | المسؤولية المثبتة | أهم الأدلة |
| --- | --- | --- | --- |
| التشغيل والعرض | `SmartFoundation.Mvc` | Composition Root، Controllers، Views، static files، routing، session، middleware، وخدمات تخص التطبيق الويب | `SmartFoundation.Mvc.csproj`، `Program.cs` |
| واجهة مشتركة | `SmartFoundation.UI` | Razor Class Library لمكونات ViewComponents وViewModels القابلة لإعادة الاستخدام | `SmartFoundation.UI.csproj`، `SmartRendererViewComponent.cs`، `SmartPageViewModel.cs` |
| التطبيق | `SmartFoundation.Application` | خدمات التطبيق، تحويل استجابات البيانات، وربط module/operation باسم entry stored procedure | `MastersServies.cs`، `BaseService.cs`، `ProcedureMapper.cs` |
| تنفيذ البيانات | `SmartFoundation.DataEngine` | إنشاء اتصال SQL، بناء Dapper parameters، تنفيذ stored procedures، وإرجاع `SmartResponse` وresult sets متعددة | `ConnectionFactory.cs`، `SmartComponentService.cs` |

مشروع `SmartFoundation.Database` خارج الطبقات التطبيقية الأربع؛ هو SQL project/Snapshot مرجعي. مشروع `SmartFoundation.Application.Tests` مشروع اختبار منفصل وليس طبقة تشغيلية.

## Project References

**مثبت من ملفات المشاريع:**

| المشروع المصدر | Project References المباشرة |
| --- | --- |
| `SmartFoundation.Mvc` | `SmartFoundation.Application`، `SmartFoundation.DataEngine`، `SmartFoundation.UI` |
| `SmartFoundation.Application` | `SmartFoundation.DataEngine` |
| `SmartFoundation.UI` | `SmartFoundation.DataEngine` |
| `SmartFoundation.DataEngine` | لا يوجد Project Reference إلى مشروع من الحل |

**ملاحظة معمارية مثبتة:** MVC يستطيع الوصول مباشرة إلى DataEngine وUI بالإضافة إلى Application؛ لذلك الاعتماد ليس Onion/Clean Architecture صارماً. UI يعتمد كذلك على DataEngine رغم أن المسار المرجعي لـ Housing يمر عادة عبر Application. لا يثبت هذا وحده أن كل Reference مستخدم في كل feature.

## نقطة التشغيل الفعلية

**مثبت:** نقطة التشغيل الوحيدة المعتمدة في هذا التحليل هي `SmartFoundation.Mvc/Program.cs`. ملف `Program.cs` في جذر المستودع ليس نقطة تشغيل التطبيق.

تقوم نقطة التشغيل بما يلي:

1. تنشئ `WebApplicationBuilder` وتستخدم Configuration وEnvironment الافتراضيين لـ ASP.NET Core.
2. تضبط ترخيص QuestPDF وتسجل خطاً من `wwwroot/fonts` أثناء startup.
3. تسجل MVC مع camelCase لـ JSON، وتسجل Razor Pages.
4. تسجل distributed memory cache وSession وresponse compression وantiforgery وHSTS.
5. تسجل خدمات البيانات والتطبيق وUI المساندة وخدمات PDF وAI وChart.
6. تبني التطبيق، ثم تضبط `UserPermissionSessionAccessor` باستخدام `IHttpContextAccessor`.
7. تنشئ middleware pipeline بالترتيب الموثق أدناه.
8. تربط Razor Pages وattribute controllers والمسار التقليدي الافتراضي إلى `Login/Index`، ثم تشغل التطبيق.

**مستنتج:** فشل فتح ملف الخط أو غيابه أثناء startup سيمنع اكتمال الإقلاع، لأن القراءة والتسجيل يحدثان دون معالجة استثناء محلية. يحتاج هذا إلى اختبار تشغيل لإثبات الأثر في حزمة النشر الفعلية.

## Middleware وترتيبه الفعلي

ترتيب pipeline مثبت من `Program.cs`:

1. `UseResponseCompression()`.
2. `UseHsts()`.
3. `UseHttpsRedirection()`.
4. `UseCookiePolicy(...)` مع فرض Secure.
5. middleware inline يضيف response security headers وCSP عند `OnStarting`، مع سياسة أشد لسطح Login وسياسة development للاتصال المحلي.
6. `UseStaticFiles()`.
7. `UseRouting()`.
8. `UseAuthentication()`.
9. `UseAuthorization()`.
10. `UseSession()`.
11. endpoint mappings: Razor Pages، attribute controllers، ثم route تقليدي `{controller=Login}/{action=Index}/{id?}`.

الرسم التفصيلي: [02-HTTP-Request-Pipeline.md](../Diagrams/02-HTTP-Request-Pipeline.md).

ملاحظات الدقة:

- **مثبت:** `SessionGuardMiddleware` موجود ويختبر مفاتيح Session المطلوبة ويعيد 401 لطلبات AJAX/JSON أو يحول إلى Login، لكنه غير مسجل بـ `UseMiddleware` في pipeline الفعلي؛ لذلك لا يجوز اعتباره حماية تشغيلية حالية.
- **مثبت:** `UseSession()` يأتي بعد `UseAuthentication()` و`UseAuthorization()`. Controllers تستطيع استخدام Session لأن endpoints تنفذ بعد اكتمال pipeline.
- **مثبت:** لا يوجد `UseExceptionHandler()` أو `UseDeveloperExceptionPage()` في `Program.cs`.
- **مستنتج:** `UseHsts()` يُطبق في كل البيئات وفق الكود، وليس داخل شرط Production. يلزم اختبار headers في الاستضافة الفعلية لإثبات السلوك الخارجي وراء proxy/IIS.

## Dependency Injection

### التسجيلات الأساسية

| الخدمة | العمر | التنفيذ/الغرض |
| --- | --- | --- |
| `ConnectionFactory` | Singleton | يحتفظ بقيمة Connection String المقروءة من Configuration وينشئ `SqlConnection` عند الطلب |
| `ISmartComponentService` | Scoped | `SmartComponentService`، محرك تنفيذ Dapper |
| `CrudController` | Scoped | مسجل كخدمة إضافة إلى كونه Controller، ويُحقن في Controllers لبناء DDL helpers |
| `MastersServies` | Scoped | بوابة DataSet والعمليات المشتركة |
| `EmployeeService`، `DashboardService` | Scoped | خدمات Application مسجلة بواسطة `AddApplicationServices()` |
| `IPdfExportService` | Scoped | `QuestPdfExportService` |
| `IHttpContextAccessor` | Framework registration | وصول غير مباشر إلى HttpContext |
| `IAiKnowledgeBase`، `LLamaModelHolder`، `IAiChatService` | Singleton | خدمات AI المحلية وفق التسجيل الحالي |
| `Chart` | Scoped | خدمة chart في MVC |

**مثبت:** `AddApplicationServices()` يسجل `EmployeeService` و`DashboardService` و`MastersServies` فقط. وجود `ChartDataService` و`VehicleService` في المشروع لا يعني أنهما مسجلان هنا.

**مثبت:** الاعتماد على concrete services شائع، وبالأخص حقن `MastersServies` و`CrudController` مباشرة. `SmartComponentService` يستخدم interface.

**مستنتج:** Singleton `ConnectionFactory` آمن من ناحية أنه لا يحتفظ باتصال مفتوح؛ `Create()` ينشئ اتصالاً جديداً. لم يُجر اختبار concurrency تشغيلي.

## Configuration وبيئات التشغيل

مصادر الإعداد المثبتة في مشروع MVC:

- `appsettings.json`: إعداد الاتصال الافتراضي، `SmartData`، مستويات Logging، و`AllowedHosts`.
- `appsettings.Development.json`: overrides للتسجيل وإعدادات `AiAssistant`.
- `appsettings.Production.json`: override للاتصال والتسجيل وإعدادات `AiAssistant`.
- `Properties/launchSettings.json`: ملفات تشغيل HTTP وHTTPS وIIS Express تضبط `ASPNETCORE_ENVIRONMENT=Development` محلياً.
- Environment variables وcommand-line configuration تدخل ضمن السلوك الافتراضي لـ `WebApplication.CreateBuilder`، لكن القيم الفعلية في بيئة النشر غير متحققة.

**مثبت:** ملفات appsettings الثلاثة معرفة كـ Content وتنسخ إلى output عند الحاجة. ملفات نماذج AI ووثائق AI المعرفة في `.csproj` تنسخ أيضاً.

**مثبت دون كشف قيم:** يحتوي مستودع الإعدادات على Connection String افتراضي حساس/قابل للاستخدام، وتوجد بدائل معلقة داخل ملفات الإعداد. هذا يذكر كواقع تكوين فقط؛ تقييمه ومعالجته يؤجلان لمهمة الأمان.

**غير متحقق منه:** مصدر Configuration النهائي في Production، القيم التي تتغلب على الملفات، اسم البيئة الفعلي، إدارة الأسرار، إعدادات IIS/reverse proxy، وصلاحية الوصول لمسارات الخط والنموذج وقاعدة المعرفة.

## Session

**مثبت من `Program.cs`:**

- مخزن Session هو distributed memory cache داخل عملية التطبيق.
- `IdleTimeout` عشر دقائق.
- Session cookie: `HttpOnly=true`، `IsEssential=true`، و`SecurePolicy=Always`.

**مثبت من Login:** بعد نجاح `GetLoginsDataSetAsync` واستخراج بيانات المستخدم، يخزن `LoginController` سياق المستخدم والتنظيم والإدارة والقسم والشعبة والهوية والصور والثيم واسم المضيف وحالة تغيير كلمة المرور ووقت آخر نشاط في Session. `Index` و`Logout` يمسحان Session.

**مثبت:** Controllers الأساسية مثل Housing تستخدم `InitPageContext` للتحقق من `usersID` ثم قراءة قيم Session المشتركة وإتاحة بعض القيم عبر `ViewBag`. `SessionController` يحدث `LastActivityUtc` ويستطيع مسح الجلسة.

**مستنتج:** لأن المخزن in-memory، Session ليست موزعة بين أكثر من instance ولا تستمر بعد إعادة تشغيل العملية إلا إذا عالجت البنية التحتية ذلك بطريقة خارج الكود؛ لا يوجد دليل مستودع على sticky sessions.

**غير متحقق منه:** اسم cookie النهائي وSameSite الفعلي، سياسة Data Protection keys في الاستضافة، وآلية استدعاء heartbeat وتوافقها مع مهلة عشر دقائق.

## Authentication وAuthorization: صورة معمارية أولية

### المصادقة

**مثبت:** Login form يرسل National ID وكلمة المرور إلى `LoginController.CheckLogin` مع antiforgery. Controller يستدعي `MastersServies.GetLoginsDataSetAsync`، الذي يصل عبر mapping `auth:sessions_` إلى `dbo.GetSessionInfoForMVC`. نجاح المصادقة يحدد من البيانات المرجعة ثم يُخزن سياق المستخدم في Session.

**مثبت:** `AllowAnonymous` موجود على GET Login وPOST CheckLogin. توجد imports لـ Cookie Authentication في Login، لكن لا يوجد `SignInAsync` فعال؛ `Logout` يمسح Session ولا ينفذ `SignOutAsync`.

**مثبت:** `UseAuthentication()` و`UseAuthorization()` موجودان، لكن لم يُعثر في composition root أو امتداد التسجيل النشط على `AddAuthentication()` أو `AddAuthorization()` أو scheme/handler أو policy مخصصة. لذلك لا يوجد دليل كافٍ على هوية Claims/Cookie فعالة.

### الترخيص

**مثبت في نمط Housing:** بوابة القراءة تعيد permissions في result set الأول، ويقرأ Controller `permissionTypeName_E` ويبني flags تتحكم في إظهار إجراءات UI. في مسار الكتابة، يمر `ActionType` و`pageName_` إلى `Masters_CRUD`، وتبين نسخة SQL المرجعية أن البوابة تتحقق من الصلاحية قبل استدعاء downstream procedure.

**مثبت:** Controllers الأساسية تتحقق من وجود `usersID` في Session وتعيد التوجيه إلى Login عند غيابه. هذا تحقق تطبيقي موزع داخل Controllers، وليس middleware عاماً مثبتاً.

**غير متحقق منه:** اكتمال تغطية كل endpoint بهذه الفحوص، فعالية `[Authorize]` في runtime، وثبات صلاحيات قاعدة البيانات الحية مقارنة بالـ snapshot. هذه نقاط لمهمة الأمان التفصيلية.

## Logging وError Handling

**مثبت:** التطبيق يستخدم logging المدمج لـ ASP.NET Core عبر `ILogger<T>`. الإعداد الافتراضي هو Information، وMicrosoft.AspNetCore هو Warning في ملفات الإعداد المفحوصة.

طبقات التعامل المثبتة:

- `BaseService` يسجل بدء العملية ونجاحها وأخطاء mapping والتنفيذ، ويرجع JSON success/failure للخدمات الضيقة.
- `MastersServies` يسجل parameters ونتائج بعض العمليات، يحول `SmartResponse` إلى `DataSet`، ويرمي `InvalidOperationException` عند فشل التنفيذ.
- `SmartComponentService` يقيس مدة التنفيذ، يسجل عدد result sets والسجلات، ويلتقط الاستثناء في `SmartResponse` مع `Success=false` و`Error`.
- `CrudController` يقرأ contract النتيجة `IsSuccessful`/`Message_` ويحولها إلى `TempData` buckets: `Success` أو `Warning` أو `Error` أو `Info`، ثم يعيد التوجيه.
- Controllers أخرى تستخدم `TempData` أو JSON errors محلياً.
- SQL gateway المرجعي يميز أخطاء الأعمال ويعيدها، ويسجل الأخطاء غير المتوقعة في `dbo.ErrorLog`؛ هذا يحتاج تحققاً من القاعدة الحية لاحقاً.

**مثبت:** لا يوجد global exception middleware ظاهر في `Program.cs`. لذلك تعتمد الاستثناءات المعالجة على catch محلي أو سلوك الاستضافة/framework الافتراضي.

**ملاحظة معمارية فقط:** توجد مواضع تسجل parameters أو استجابات كاملة، وبعض رسائل الخطأ تُضمّن نص الاستثناء للمستخدم. تقييم التعرض والتصحيح خارج هذه المهمة ويؤجل لتحليل الأمان.

## تدفق HTTP Request

### طلب صفحة نموذجي

1. يصل HTTPS request إلى pipeline ويمر بالضغط وHSTS والتحويل وcookie policy وsecurity headers.
2. تخدم static files قبل routing عند المطابقة.
3. يحدد routing endpoint، ثم تمر مرحلتا authentication وauthorization المسجلتان في pipeline، ثم تتاح Session.
4. يختار endpoint Controller/Action عبر attribute routing أو route التقليدي.
5. في Housing، يستدعي Action `InitPageContext`; غياب `usersID` يؤدي إلى Redirect إلى Login.
6. يبني Controller معاملات التحميل ويطلب DataSet من `MastersServies`.
7. يفصل `SplitDataSet` الجداول: permissions أولاً ثم feature datasets.
8. يبني Controller `FormConfig` و`SmartTableDsModel` و`SmartPageViewModel` مع permission gating.
9. Razor View تستدعي `SmartRenderer`، ثم تتكون HTML من ViewComponents الفرعية.
10. تعود الاستجابة عبر middleware، وتضاف headers عند بدء الإرسال، وقد تضغط الاستجابة.

### طلب CRUD نموذجي

1. SmartForm ينشر إلى `/crud/insert` أو `/crud/update` أو `/crud/delete`.
2. `CrudController` يقرأ form fields والسياق المخفي.
3. يحول `p01..p50` إلى `parameter_01..parameter_50` ويحمل context fields.
4. ينفذ `MastersServies.GetCrudDataSetAsync`.
5. يفسر نتيجة الإجراء، يضع رسالة Toastr في TempData، ويعيد التوجيه إلى URL أو Controller/Action محدد.

## تدفق البيانات من View إلى SQL Server

الرسم الكامل لمساري القراءة والكتابة: [03-Data-Read-and-CRUD-Flows.md](../Diagrams/03-Data-Read-and-CRUD-Flows.md).

### القراءة: مسار Housing المثبت

`Browser -> MVC Action -> InitPageContext -> MastersServies.GetDataLoadDataSetAsync -> ProcedureMapper(MastersDataLoad:getData) -> SmartRequest(Operation=sp) -> ISmartComponentService.ExecuteAsync -> ConnectionFactory -> Dapper QueryMultipleAsync -> dbo.Masters_DataLoad -> feature DL -> SmartResponse.Datasets -> DataSet -> SplitDataSet -> SmartPageViewModel -> Razor -> SmartRenderer -> HTML`

في `WaitingListByResident` تحديداً:

- يقرأ Controller query parameters وSession context.
- يمرر `pageName_` و`idaraID` و`entrydata` و`hostname` ثم positional extras.
- `MastersServies` يسمي extras حتى `parameter_20` في overload التحميل الحالي.
- table 0 permissions، والجداول اللاحقة بيانات المقيم وقوائم الانتظار والخطابات وطلبات النقل/lookup datasets بحسب الصفحة.
- يتحول كل `DataRow` إلى dictionary، وتضاف aliases مثل `p01` لتعبئة modal forms.

### الكتابة: مسار CRUD المثبت

`SmartForm -> POST /crud/{operation} -> CrudController -> core context + p01..p50 mapping -> MastersServies.GetCrudDataSetAsync -> ProcedureMapper(MastersCrud:crud) -> SmartComponentService -> dbo.Masters_CRUD -> permission/action routing -> feature SP -> IsSuccessful/Message_ -> DataSet -> TempData -> Redirect`

**حد الدليل:** routing إلى `WaitingListByResidentDL/SP` مدعوم من snapshot SQL وتعليمات المستودع، لكنه لا يثبت تطابق القاعدة الحية لحظة التشغيل.

## MastersServies

**مثبت:** `MastersServies` يرث `BaseService` ويعتمد على `ISmartComponentService` و`ILogger`. وهو بوابة مشتركة لأنماط متعددة:

- DataSet للتحميل عبر `Masters_DataLoad`.
- DataSet للتحميل الإضافي عبر `Masters_ExtraDataLoad`.
- DataSet للكتابة عبر `Masters_CRUD`.
- المصادقة وتغيير كلمة المرور عبر mappings منفصلة.
- عمليات menu/notification وبعض عمليات AI عبر `ExecuteOperation` أو mappings مشتركة.

وظيفته المعمارية الأساسية هي تطبيع أسماء المعاملات، إنشاء `SmartRequest`، استدعاء محرك البيانات، ثم تحويل `SmartResponse.Data/Datasets` إلى `System.Data.DataSet/DataTable` الذي تتعامل معه Controllers الحالية.

**مثبت:** الاسم في الكود هو `MastersServies` بالتهجئة الحالية، وهو contract فعلي واسع الاستخدام.

## ProcedureMapper

**مثبت:** mapping مركزي ثابت من مفتاح `module:operation` إلى اسم stored procedure. مفاتيح البوابات الأساسية هي:

- `MastersDataLoad:getData` -> `dbo.Masters_DataLoad`.
- `MastersExtraDataLoad:getData` -> `dbo.Masters_ExtraDataLoad`.
- `MastersCrud:crud` -> `dbo.Masters_CRUD`.
- `auth:sessions_` -> `dbo.GetSessionInfoForMVC`.
- `auth:changePassword` -> `dbo.ReSetUserPassword`.

**مثبت:** mapper يحتوي entry/gateway procedures وليس كل feature downstream procedure. هذا يحافظ على routing داخل بوابات SQL بحسب `pageName_` و`ActionType`.

## SmartComponentService وConnectionFactory

**مثبت:** `SmartComponentService.ExecuteAsync`:

1. يتحقق من وجود `SpName`.
2. يقرأ `SmartData:Whitelist`; إذا كانت القائمة غير فارغة يرفض الاسم غير المسموح، وإذا كانت فارغة فلا يطبق تقييد الاسم.
3. يبني `DynamicParameters` ويضيف بادئة `@` داخلياً إلى أسماء parameters؛ لذا لا يضيفها Application code.
4. يطبق paging/sort/filter helpers فقط عندما `Operation == "select"`.
5. يفتح اتصالاً جديداً من `ConnectionFactory`.
6. يحاول `QueryMultipleAsync` مع `CommandType.StoredProcedure` ويقرأ كل result sets إلى dictionaries.
7. عند فشل قراءة multiple sets ينتقل إلى `QueryAsync` fallback.
8. يعيد `SmartResponse` مع success/data/datasets/total/duration أو error.

**مثبت:** `ConnectionFactory` يقرأ `ConnectionStrings:Default` عند إنشائه ويعيد `SqlConnection` جديداً، ولا يعرض المستند قيمته.

## CrudController وعقد المعاملات

**مثبت:** Routes الأساسية هي:

- `POST /crud/insert`.
- `POST /crud/update`.
- `POST /crud/delete`.
- توجد endpoints مشتركة إضافية لـ DDL وextra data load وrender form، لكنها ليست محور مسار CRUD الأساسي.

### حقول السياق

العقد المتكرر يحافظ على الأسماء والحالة التالية:

- `pageName_`
- `ActionType`
- `idaraID`
- `entrydata`
- `hostname`
- `redirectAction`
- `redirectController`
- `redirectUrl` عند توفره

### التحويل الموضعي

لكل index من 01 إلى 50:

`p01 -> parameter_01`, `p02 -> parameter_02`, ... , `p50 -> parameter_50`.

القيم الفارغة تحول عادة إلى `DBNull.Value`. `ActionType` يحول إلى uppercase. `MastersServies` يبقي الأسماء الأساسية كما يتوقعها gateway procedure.

**مثبت:** `CrudController` يدعم أيضاً file fields المسماة `pNN`، ويحفظ الملفات ثم يضع JSON لمساراتها في `parameter_NN`. تفاصيل سلامة رفع الملفات تؤجل لمهمة الأمان.

**قاعدة معمارية:** ترتيب `pNN` يحمل معنى business positional يحدده كل ActionType/downstream procedure؛ لا يجوز إعادة تسميته أو إعادة ترتيبه دون تغيير متزامن للعقد عبر UI وController وSQL.

## SmartFoundation.UI وSmartRenderer

`SmartFoundation.UI` Razor Class Library تجمع نماذج ومكونات العرض المشتركة. `SmartPageViewModel` هو container يمكن أن يحمل:

- `FormConfig`.
- جدولاً عاماً أو `TableDS` حتى `TableDS5`.
- `DatepickerViewModel`.
- `SmartChartsConfig`.
- `SmartPrintConfig`.
- panel metadata وalerts.

**مثبت:** `SmartRendererViewComponent` نفسه بسيط ويعيد View مع النموذج. منطق composition في `Views/Shared/Components/SmartRenderer/Default.cshtml`: يفحص الخصائص غير الفارغة ويستدعي ViewComponents المناسبة، ويمكنه عرض أكثر من جدول داخل الصفحة.

**مثبت:** View المرجعية `WaitingListByResident.cshtml` لا تعيد بناء البيانات؛ تضبط العنوان وتستدعي `SmartRenderer`. Controller هو الذي يقرر الحقول والجداول والأزرار والـ guards وإظهار الإجراءات بحسب permission flags.

**النتيجة المعمارية:** UI هنا server-configured component composition: business/page orchestration في MVC Controller، rendering reusable في UI، وتنفيذ البيانات في Application/DataEngine.

## مسارات التنفيذ المثبتة

| المسار | درجة الإثبات | نقطة البداية | بوابة SQL |
| --- | --- | --- | --- |
| تحميل صفحة Housing | مثبت حتى gateway، downstream مؤيد بالـ snapshot | `HousingController.WaitingListByResident` | `dbo.Masters_DataLoad` |
| CRUD لصفحة Housing | مثبت حتى gateway، downstream مؤيد بالـ snapshot | `/crud/insert|update|delete` | `dbo.Masters_CRUD` |
| تسجيل الدخول | مثبت حتى entry procedure mapping | `LoginController.CheckLogin` | `dbo.GetSessionInfoForMVC` |
| تغيير كلمة المرور | مثبت حتى entry procedure mapping | `LoginController.ChangePassword` | `dbo.ReSetUserPassword` |
| Render الصفحة | مثبت | Razor View | `SmartRenderer` ثم nested ViewComponents |

## نقاط غير متحقق منها ومؤجلة

1. Configuration الفعلي في بيئة Production والقيم التي تتغلب على appsettings.
2. إعداد IIS/reverse proxy وforwarded headers وTLS termination.
3. فعالية authentication handler أو claims identity؛ لا يظهر تسجيل scheme في نقطة التشغيل.
4. اكتمال حماية endpoints بالـ Session checks وauthorization؛ يحتاج Coverage أمني منفصل.
5. سبب وجود `SessionGuardMiddleware` دون تسجيل، وهل يسجل في فرع أو نسخة نشر خارج المستودع.
6. حالة gateway/downstream stored procedures في قاعدة البيانات الحية وتطابقها مع snapshot.
7. سلوك التطبيق عند scale-out بالنسبة لـ Session وData Protection.
8. global error page/handler في بيئة الاستضافة؛ لا يظهر middleware مخصص في الكود.
9. أثر ترتيب Session بعد authentication/authorization إذا أضيف مستقبلاً handler يعتمد على Session.
10. جميع المسارات البديلة غير Housing والخدمات التجريبية؛ ستوثق ضمن مهام البرامج اللاحقة.

## الأدلة الأساسية

- `SmartFoundation.Mvc/Program.cs`
- ملفات `.csproj` للمشاريع الأربع
- `SmartFoundation.Application/Extensions/ServiceCollectionExtensions.cs`
- `SmartFoundation.Application/Services/MastersServies.cs`
- `SmartFoundation.Application/Services/BaseService.cs`
- `SmartFoundation.Application/Mapping/ProcedureMapper.cs`
- `SmartFoundation.DataEngine/Core/Services/SmartComponentService.cs`
- `SmartFoundation.DataEngine/Core/Utilities/ConnectionFactory.cs`
- `SmartFoundation.Mvc/Controllers/CrudController.cs`
- `SmartFoundation.Mvc/Controllers/Login/LoginController.cs`
- `SmartFoundation.Mvc/Controllers/Housing/HousingController.Base.cs`
- `SmartFoundation.Mvc/Controllers/Housing/WaitingList/HousingController.WaitingListByResident.cs`
- `SmartFoundation.Mvc/Views/Housing/WaitingList/WaitingListByResident.cshtml`
- `SmartFoundation.UI/ViewModels/SmartPage/SmartPageViewModel.cs`
- `SmartFoundation.UI/ViewComponents/SmartRenderer/SmartRendererViewComponent.cs`
- `SmartFoundation.UI/Views/Shared/Components/SmartRenderer/Default.cshtml`
- `SmartFoundation.Mvc/appsettings*.json` و`Properties/launchSettings.json`، دون نسخ أسرار

## نتيجة المهمة

اكتمل تحليل المعمارية والمكونات المشتركة. أصبحت الطبقات والمراجع ونقطة التشغيل وpipeline وDI وSession والمسارات المشتركة موثقة، مع فصل واضح بين ما يثبته الكود وما يحتاج إلى تحقق تشغيلي أو تحليل أمني لاحق.

## تحديث المطابقة الحية 2026-08-22

تحقق مسارا `Masters_DataLoad` و`Masters_CRUD` وتعريفات downstream للمحادثات 1–7 من DATACORE الحية. النتيجة 51 إجراءً: 40 مطابقاً و11 مختلفاً، بلا كائن مطلوب مفقود. يستبدل هذا التحديث فجوة «حالة الإجراءات الحية» لهذا النطاق فقط؛ راجع `07A-Live-Database-Reconciliation.md`.
