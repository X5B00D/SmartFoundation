# توثيق Home وLogin

> تحديث قاعدة البيانات 2026-08-23: أُدرجت إجراءات Home/Login الستة ضمن الجرد النهائي للبوابات والمشترك، ولم يظهر drift جديد. راجع [تحليل DATACORE](11-Live-Database-and-ERD.md).

## النطاق ومصادر الحقيقة

- تاريخ التحقق: 2026-08-23.
- يشمل: `LoginController` وصفحة الدخول وتغيير كلمة المرور والخروج، و`HomeController.Index` و`Privacy`، والقائمة والتنقل والجلسة والمكونات المشتركة.
- الكود النشط هو مصدر سلوك التطبيق، وتعريفات DATACORE الحية هي مصدر SQL النهائي. استُخدم Snapshot للمقارنة فقط.
- تمت قراءة `sys.procedures` و`sys.sql_modules` و`sys.parameters` و`sys.sql_expression_dependencies` عبر PowerShell و`System.Data.SqlClient` داخل `try/catch`.
- لم يُنفذ دخول بحساب فعلي، ولم تُقرأ بيانات مستخدمين، ولم تُغير كلمة مرور، ولم يُنفذ Business Stored Procedure أو أي كتابة/DDL، ولم تُعرض قيمة اتصال أو كلمة مرور افتراضية.

## ملخص تنفيذي

المصادقة Session-based وليست ASP.NET Core Identity: صفحة الدخول ترسل الهوية وكلمة المرور إلى `GetSessionInfoForMVC`، ثم ينشئ Controller مفاتيح Session عند نجاح النتيجة وينتقل إلى `/Home/Index`. لا توجد Claims أو authentication cookie فعالة. الخروج يمسح Session.

Home محمية محلياً عبر `InitPageContext`. قبل تحميلها ينفذ الكود النشط `Housing.GenerateMonthlyRentBills` للشهر السابق؛ هذا أثر كتابة داخل GET ولم يُنفذ في التوثيق. بعده يقرأ `Masters_DataLoad` لصفحة `Home`; البوابة الحية تعيد صلاحيات الصفحة ثم توجه إلى `ChartsDL`، لا إلى `HomeDL`. `HomeDL` موجود حي ومطابق للـSnapshot لكنه ليس المسار النشط الظاهر.

## Login

### عرض صفحة الدخول

`GET /Login/Index` يحمل `[AllowAnonymous]` و`ResponseCache(NoStore=true)`، يمسح Session دائماً، يقرأ آخر هوية من query `u` ورسالة من `mt/msg`، ويحوّل `logout=1` إلى رسالة انتهاء بالخمول و`logout=2` إلى رسالة نجاح. يضيف كذلك headers تمنع التخزين المؤقت.

صفحة `Views/Login/Index.cshtml` مستقلة بلا Layout وتعرض حقل هوية بطول أقصى 10 وحقل كلمة مرور وزر إظهارها وcheckbox «تذكرني». النموذج يولد antiforgery token ويرسل POST إلى `CheckLogin`. `login-page.js` يقصر الهوية في المتصفح على الأرقام، ويحفظ الهوية فقط في `localStorage` عند اختيار «تذكرني»؛ لا يحفظ كلمة المرور.

### التحقق والانتقال

1. `POST /Login/CheckLogin` يحمل `[AllowAnonymous]` و`[ValidateAntiForgeryToken]`.
2. يرفض الحقول الفارغة ثم يرسل الهوية بعد trim وكلمة المرور و`Request.Host.Value` إلى `MastersServies.GetLoginsDataSetAsync`.
3. `ProcedureMapper` يحل `auth:sessions_` إلى `dbo.GetSessionInfoForMVC`، وينفذ DataEngine الإجراء كـ stored procedure.
4. `ExtractAuth` يحول أول صف إلى `AuthInfo`. النجاح يتطلب `usersId` غير فارغ و`usersActive != 0`.
5. بعد إنشاء Session يضع Controller الرسالة في `TempData[Success|Warning|Info]` حسب `usersActive`، ثم ينتقل إلى `Home/Index`.

الفشل يعيد التوجيه إلى Login مع نوع الرسالة ونصها والهوية السابقة. فشل الاتصال ومعالجة النتيجة يضمّنان `ex.Message` في query، وهي مخاطرة كشف تفاصيل داخلية. لا يوجد `CancellationToken` موصول صراحة بتنفيذ الخدمة رغم استقباله في Action.

### `GetSessionInfoForMVC` الحي

الحالة: **Live verified and matching Snapshot**. التوقيع الحي: `@NationalID nvarchar(20)`, `@Password nvarchar(200)`, `@hostName nvarchar(200)`؛ الأطوال هنا بوحدات الأحرف بعد تفسير `max_length` الخاص بـnvarchar.

السلوك المثبت من التعريف الحي:

- يختار أحدث مستخدم فعال ضمن تاريخ البداية والنهاية.
- يختار أحدث سجل كلمة مرور فعال ويقارن `SHA2_256(salt + password bytes)` بالقيمة المخزنة.
- يتطلب تفاصيل مستخدم فعالة وهيكلاً إدارياً يحوي Idara وDepartment.
- يعيد الهوية والسياق التنظيمي والإداري وبيانات العرض والشعارات وحالة `ChangedPassword` ورسالة عربية.
- يميز حالات عدم وجود ملف/حساب نشط، خطأ كلمة المرور، عدم وجود كلمة مرور، وخلل الهيكل الإداري.

`@hostName` موجود في العقد لكنه غير مستخدم في جسم التعريف الحي.

### مفاتيح Session

| الفئة | المفاتيح المكتوبة عند النجاح |
| --- | --- |
| الهوية | `usersID`, `nationalID`, `GeneralNo` |
| المستخدم | `fullName`, `usersActive`, `ChangedPassword` |
| التنظيم | `OrganizationID/Name`, `IdaraID/Name`, `DepartmentID/Name`, `SectionID/Name`, `DivisonID/Name`, `DeptCode` |
| الإدارة | `AdminTypeID`, `AdminTypeName` |
| العرض | `photoBase64`, `ThameName`, `OrganaiztionLogo`, `IdaraLogo` |
| التشغيل | `HostName`, `LastActivityUtc` |

القائمة تضيف `MENU_TREE` لاحقاً، ومحاولة Home لحفظ خريطة AI تستخدم `Ai.UserPermissionMap`. الإعداد العام: memory-backed session، مهلة خمول 10 دقائق، cookie بـHttpOnly وSecure Always وEssential. أسماء القراءة غير متسقة في بعض المواضع (`usersActive/useractive`, `usersID/UserId`).

### تغيير كلمة المرور

`POST /Login/ChangePassword` يستمد `usersID` من Session، لكنه لا يحمل antiforgery attribute. يرفض الجلسة المفقودة والحقول الفارغة والطول دون 8، ثم تستدعي الخدمة `dbo.ReSetUserPassword` بفعل `CHANGEUSERPASSWORD` وبثلاث قيم فعلية: المستخدم، القديمة، والجديدة؛ بقية معاملات السياق في الخدمة تصبح null.

التعريف الحي لـ`ReSetUserPassword` **مطابق للـSnapshot** وله ثمانية معاملات. فرع التغيير:

- يتحقق أن المستخدم فعال وضمن فترة الصلاحية.
- يتحقق من القديمة باستخدام salt وSHA2-256.
- يفرض على الخادم: 8 خانات على الأقل، ورقماً واحداً، وحرفاً إنجليزياً واحداً على الأقل.
- يمنع أن تكون الجديدة مساوية للحالية، ثم يعطل كلمات المرور الفعالة القديمة.
- ينشئ salt عشوائياً بطول 32 بايت عبر `CRYPT_GEN_RANDOM` ويضيف hash جديداً ويضبط `ChangedPassword=1`.

JavaScript يفرض فوق ذلك حرفاً كبيراً وحرفاً صغيراً ورقماً وتطابق التأكيد. إذن الكبير/الصغير سياسة UI فقط ويمكن تجاوزها بطلب مباشر؛ السياسة المثبتة server-side هي 8 + رقم + حرف إنجليزي، ولا يوجد special-character أو history أو expiry أو breached-password check مثبت.

عند النجاح تحدث Session إلى `ChangedPassword=1`. الواجهة تسجل خروج المستخدم بعد النجاح ليعيد الدخول. إذا كانت القيمة أولاً `0`، تعرض Home والـSidebar نموذج تغيير إجباري وتعطل روابط التنقل بالـJavaScript؛ هذا ليس حاجز server-side عاماً.

فرع `RESETUSERPASSWORD` الإداري في التعريف الحي ما زال يولد كلمة مرور افتراضية ثابتة داخل الإجراء، يعطل السابقة، وينشئ salt/hash جديداً ويضبط `ChangedPassword=0`. لم تُذكر القيمة. هذا يغلق فجوة «هل اختلف الحي؟» بالنفي ويؤكد بقاء الخطر.

### Logout والخمول

- `GET /Login/Logout`: يمسح Session ويعيد Login مع `logout=2`. لا يوجد `SignOutAsync` فعال.
- `POST /session/logout`: يمسح Session ويعيد JSON success؛ بلا antiforgery.
- `session-guard.js`: يعد نشاط المتصفح، يحذر بعد 8 دقائق، ويخرج بعد 10، ويرسل keepalive كل دقيقة عند النشاط.
- `POST /session/keepalive`: يحدث `LastActivityUtc` حتى دون التحقق من هوية Session.

`SessionGuardMiddleware` موجود لكنه غير مسجل في `Program.cs`. الحماية الفعلية تعتمد على فحوص موزعة داخل Controllers؛ ولا يوجد إثبات لتدوير Session ID بعد الدخول أو الخروج.

## Home

### `Index`

`GET /Home/Index` يمنع cache ويستدعي `InitPageContext`; غياب `usersID` يعيد Login مع `logout=1`. بعد ذلك:

1. ينفذ `GenerateMonthlyRentBillsAsync` الإجراء `[Housing].[GenerateMonthlyRentBills]` للشهر السابق باستخدام سياق Session. الاستثناء يسجل ويُبتلع، فتستمر الصفحة. تنفيذ كتابة من GET يزيد زمن/مخاطر الطلب ويخالف مبدأ عدم وجود أثر جانبي؛ لم ينفذ أثناء التوثيق.
2. يثبت `ControllerName=Home` و`PageName=Home`.
3. يرسل `Home, IdaraId, usersId, HostName, usersId` إلى `Masters_DataLoad`.
4. يقسم النتائج: table 0 صلاحيات Home، table 1 أسماء charts، table 2 إحصاءات المساكن.
5. يبني `SmartPageViewModel` بعنوان «لوحة التحكم» ويعرض `SmartRenderer`. إعداد Charts الفعلي معلق، لذلك لا يربط النتائج ببطاقات Charts حالياً.

هناك خطأ موثق: `UserPermissionSessionHelper.SaveFromDataTable(HttpContext, dt2)` يطلب table 3، بينما المسار الحي يعيد ثلاث جداول فقط (0..2)، فتكون `dt2` null وتُحذف `Ai.UserPermissionMap`. سجلات فحص صلاحيات AI التالية تكون بلا خريطة من هذا المسار.

### `Privacy`

`GET /Home/Privacy` يعيد View ثابتة إنجليزية placeholder بلا `InitPageContext`, `[Authorize]` أو بيانات. لذلك هي متاحة وفق routing حتى دون Session ما دام لا يوجد guard عام.

### SQL Home الحي

| الكائن | الحالة الحية | الدور الفعلي |
| --- | --- | --- |
| `dbo.Masters_DataLoad` | مطابق للـSnapshot | يعيد `ft_UserPagePermissions` أولاً، وفرع Home ينفذ `ChartsDL`. |
| `dbo.ChartsDL` | مطابق للـSnapshot | يعيد أسماء charts المخصصة للمستخدم ثم توزيع/نسب حالات مساكن Idara. |
| `dbo.HomeDL` | مطابق للـSnapshot | يعيد أسماء charts المخصصة فقط؛ موجود حي لكنه غير مستدعى من مسار Home النشط المكتشف. |

شرط end-date في `HomeDL/ChartsDL` يستخدم `< GETDATE()` مع `OR end IS NULL`، أي يقبل السجل المنتهي في الماضي ويرفض تاريخ انتهاء مستقبلي؛ هذا معكوس عن النمط المعتاد ويحتاج مراجعة أعمال.

### القائمة والتنقل و`GetUserMenuTree`

`_Layout` يستدعي `MenuItemsViewComponent` في كل صفحة تستخدم Layout. المكون يقرأ `usersID` من Session، يستدعي `MastersServies.GetUserMenuTree`, يحول JSON إلى `MenuItem`, يبني hierarchy، يحفظها في `MENU_TREE`، ثم يعرض `_SidebarNavbar`.

`GetUserMenuTree` الحي **مطابق للـSnapshot** وتوقيعه `@UsersID int`. يحدد القوائم التي عليها صلاحية فعالة مباشرة للمستخدم أو عبر Role أو DSD أو Distributor أو المنحة العامة، مع تواريخ النشاط، ثم يضم جميع العقد الآباء ويولد عقدة مستوى أول لكل Program. النتيجة مرتبة بـ`SortKey/LevelNo` وبها `HasPermissionForUser` لتمييز العقدة الممنوحة من العقدة الأب.

الـViewComponent يرتب بـ`MPSerial` ويبني الأطفال بحسب `parents/ParentMenuID_FK`. `_SidebarNavbar` يستخدم الشجرة للرسم وBreadcrumb، ويطبعها كذلك كـJSON في الصفحة. البرامج لا تظهر إلا إن وصلت من الإجراء عبر فرع صلاحية أو كانت أباً ضرورياً لمسار مصرح.

مخاطرة خصوصية مثبتة: `MastersServies.GetUserMenuTree` يكتب JSON الكامل للقائمة إلى console وInformation log، ثم يسجل أول صف أيضاً. لا يحتوي هذا بالضرورة أسراراً لكنه يكشف بنية البرامج والصلاحيات المتاحة للمستخدم في السجلات.

### المكونات المشتركة والعلاقة مع Dashboard

- `_Layout`: القائمة، Breadcrumb، Toastr، Session guard، Notification، AI widget، وأصول الجداول/forms/charts.
- `MenuItemsViewComponent` و`_SidebarNavbar`: التنقل، بيانات المستخدم، تغيير كلمة المرور والخروج.
- `SmartRenderer`: يستقبل صفحة Home، لكن النموذج الحالي لا يحتوي Charts/Form/Table فعلية.
- `UserPermissionSessionHelper`: مقصود لحفظ خريطة صلاحيات AI، لكن binding الحالي إلى `dt2` لا يجد result set.

يوجد رابط ثابت `/Dashboard` في شعار Sidebar، كما أن View المستبعدة `Dashboard/Index` تشبه Home في عرض تغيير كلمة المرور و`SmartRenderer`. لم تُوثق وحدة Dashboard نفسها، ولا يثبت الرابط أن Home تعيد التوجيه إليها؛ المسار بعد الدخول هو Home حصراً.

## الأمان: ما تأكد وما بقي

### نتائج حية أغلقت فجوات تحقق

- hashing حي: salt عشوائي 32 بايت + SHA2-256، مطابق للـSnapshot.
- reset الإداري: القيمة الافتراضية الثابتة ما زالت موجودة حياً؛ لم تُغلق المخاطرة.
- صلاحية الدخول: المستخدم والتفاصيل وفترة النشاط والهيكل وكلمة المرور مطلوبة حياً.
- Session: مفاتيحها وإعدادها مثبتة من الكود؛ لا تعتمد SQL Session server-side خارج نتيجة الدخول.
- `ft_UserPagePermissions` سبق التحقق منه حياً ومطابق، و`Masters_DataLoad` الحي يستدعيه قبل Home.
- `GetUserMenuTree` يطبق شبكة المنح الفعلية ويعيد الآباء والبرامج فقط لمسارات لها منح.

### المخاطر المؤكدة

1. قيمة reset إداري ثابتة ومشتركة، حتى مع تخزينها salted/hashed بعد reset.
2. لا authentication scheme/claims/Authorize ولا Session guard عام مسجل.
3. CSRF: ChangePassword وSession logout/keepalive بلا antiforgery، وLogout الرئيسي GET.
4. رسائل خطأ الدخول قد تكشف `ex.Message` عبر query وواجهة المستخدم.
5. لا rate limit أو lockout أو MFA مثبتة.
6. لا تدوير Session ID مثبت، والمخزن in-memory فقط.
7. تغيير كلمة المرور الإجباري يعتمد على UI ولا يفرضه guard server-side عام.
8. `GetUserMenuTree` يسجل JSON خاصاً بالمستخدم كاملاً.
9. Home GET ينفذ Business SP كتابياً، وPrivacy بلا فحص Session محلي.
10. شروط انتهاء Chart مقلوبة ظاهرياً، وخريطة صلاحيات AI لا تُحمّل بسبب فهرسة result set.

## الفروق عن Snapshot

لا يوجد drift في تعريفات الإجراءات الستة المقروءة لهذه المرحلة. الفروق المهمة ليست Live-vs-Snapshot بل **usage/code-vs-schema**:

- Home النشط يوجه إلى `ChartsDL` لا `HomeDL`.
- Controller يتوقع `dt2` لخريطة الصلاحيات رغم أن نتائج Home تنتهي عند table 2.
- سياسة الكبير/الصغير في JavaScript أشد من SQL الحي.
- `@hostName` في إجراء الدخول غير مستخدم.

## Coverage

| البند | مكتشف | موثق | النسبة |
| --- | ---: | ---: | ---: |
| ملفات Controllers لـHome/Login | 3 | 3 | 100% |
| Controllers منطقية | 2 | 2 | 100% |
| Actions المطلوبة | 6 | 6 | 100% |
| Views | 3 | 3 | 100% |
| المكونات/الحراس المشتركة المباشرة | 5 | 5 | 100% |
| إجراءات SQL المقروءة حياً | 6 | 6 | 100% |
| SQL function للصلاحيات | 1 | 1 | 100% مع الاستناد للتحقق الحي السابق |
| Business SPs المنفذة أثناء التوثيق | 0 | 0 | التزام كامل |

التغطية تعني تتبع الأسطح المكتشفة وتعريفات catalog، لا اختبار دخول أو UI/E2E أو تنفيذ SQL أو إثبات بيانات صلاحيات فعلية.

## الرسومات والدليل

- [تدفق المصادقة والجلسة](../Diagrams/Security-Authentication-and-Session-Flow.md)
- [تدفق الصلاحيات والقائمة](../Diagrams/Security-Authorization-and-Permission-Flow.md)
- [دليل مستخدم Home وLogin](../UserManual/Home-and-Login.md)
