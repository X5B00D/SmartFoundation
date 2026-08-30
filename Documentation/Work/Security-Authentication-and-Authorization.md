# أمان SmartFoundation: المصادقة والترخيص والجلسات

> تحديث قاعدة البيانات 2026-08-23: يثبت [ERD ControlPanel والصلاحيات](../Diagrams/18-ControlPanel-Permissions-ERD.md) FKs الحية، ويصحح الافتراضات المبنية على أسماء `_FK`: روابط Idara في `Permission` وبعض روابط `DeptSecDiv` علاقات مستنتجة وليست قيوداً فعلية.

## الحالة والحدود

- المهمة: تحليل الأمان فقط، بتاريخ 2026-08-21.
- شمل التحليل Login/Logout وAuthentication/Authorization وRoles/Permissions وClaims وSession وحماية endpoints و`permissionTypeName_E` و`ft_UserPagePermissions` وإدارة كلمات المرور والسجلات والإشعارات وAntiforgery/Cookies/HSTS والتدفقات والمخاطر.
- لم تُنفذ كتابة أو Stored Procedure تجاري، ولم تُقرأ صفوف مستخدمين أو سجلات فعلية، ولم تُعرض أسرار أو هويات حقيقية.
- الكود النشط هو المصدر الأول. ملفات `SmartFoundation.Database` snapshot مرجعي فقط.
- **ملاحظة تاريخية مستبدلة:** عند إعداد هذا المستند في 2026-08-21 ثبتت الأسماء فقط وتعذر `sys.sql_modules` بسبب TLS، لذلك بُني التفصيل حينها على Snapshot. في 2026-08-22 أُنجزت القراءة الحية؛ نتائجها في قسم التحديث و07A وهي المرجع النهائي.

## الخلاصة التنفيذية

المصادقة الفعلية ليست ASP.NET Core Identity ولا Cookie Authentication. POST الدخول يستدعي `dbo.GetSessionInfoForMVC`، وتحدد النتيجة نجاح الدخول، ثم يخزن التطبيق هوية المستخدم وسياقه التنظيمي في Session server-side.

لا ينشئ التطبيق `ClaimsIdentity/ClaimsPrincipal`، ولا يستدعي `SignInAsync`، ولا يسجل Authentication Scheme أو Authorization Policies. وجود `UseAuthentication()` و`UseAuthorization()` وحده لا يوفر حماية. الحماية الفعلية موزعة بين فحص Session داخل بعض Actions، وإظهار UI حسب `permissionTypeName_E`، وفحص SQL في بوابة CRUD.

لا يوجد guard عام فعال: `SessionGuardMiddleware` موجود لكنه غير مسجل، ولا توجد `[Authorize]` في Controllers النشطة المفحوصة.

## Authentication وLogin/Logout

المسار المثبت:

`POST /Login/CheckLogin -> MastersServies.GetLoginsDataSetAsync -> ProcedureMapper(auth:sessions_) -> dbo.GetSessionInfoForMVC -> ExtractAuth -> Session -> /Home/Index`

- GET Login وPOST CheckLogin يحملان `[AllowAnonymous]`، وPOST يحمل `[ValidateAntiForgeryToken]`.
- تمرر National ID وكلمة المرور وhost كـ Dapper parameters.
- يتطلب النجاح `usersId` غير فارغ و`usersActive != 0`.
- GET Login يمسح Session ويمنع cache.
- لا توجد MFA أو lockout أو rate limiting أو CAPTCHA مثبتة.

`GetSessionInfoForMVC` مثبت حياً بالاسم ومؤيد تعريفه بالـ snapshot. التعريف المرجعي يبحث عن مستخدم نشط ضمن فترة الصلاحية، ويقرأ أحدث `UsersPassword` نشط، ويقارن `HASHBYTES('SHA2_256', Salt + password-bytes)` مع `PasswordHash`، ثم يتحقق من تفاصيل المستخدم والهيكل الإداري ويعيد سياق الجلسة.

Logout الفعلي هو `Session.Clear()` عبر `GET /Login/Logout` أو `POST /session/logout`. لا يوجد `SignOutAsync` فعال، ولا دليل على تدوير Session ID.

الرسم: [Security-Authentication-and-Session-Flow.md](../Diagrams/Security-Authentication-and-Session-Flow.md).

## Claims وRoles

- لا يوجد تسجيل نشط لـ `AddAuthentication`, `AddCookie`, `AddIdentity` أو policies.
- لا يوجد `SignInAsync` أو إنشاء Claims أو اعتماد أمني على `HttpContext.User`.
- لا يوجد `[Authorize]` أو `[Authorize(Roles=...)]` في النطاق المفحوص.
- Role في النظام كيان قاعدة بيانات ضمن شبكة الصلاحيات، وليس role claim في ASP.NET Core.

## Session

الإعداد المثبت: `DistributedMemoryCache` داخل instance واحدة، مهلة خمول 10 دقائق، وSession cookie بقيم `HttpOnly=true`, `IsEssential=true`, `Secure=Always`. اسم cookie وSameSite وسياسة Data Protection keys غير مخصصة في الكود.

المفاتيح التي يكتبها Login:

| الفئة | المفاتيح |
| --- | --- |
| الهوية | `usersID`, `nationalID`, `GeneralNo` |
| الاسم والحالة | `fullName`, `usersActive`, `ChangedPassword` |
| التنظيم | `OrganizationID/Name`, `IdaraID/Name`, `DepartmentID/Name`, `SectionID/Name`, `DivisonID/Name`, `DeptCode` |
| الإدارة | `AdminTypeID`, `AdminTypeName` |
| العرض | `photoBase64`, `ThameName`, `OrganaiztionLogo`, `IdaraLogo` |
| التشغيل | `HostName`, `LastActivityUtc` |

تستخدم الواجهة أيضاً `MENU_TREE`. توجد أسماء غير متسقة مثل `usersActive/useractive` و`usersID/UserId`. `POST /session/keepalive` يحدث activity دون فحص هوية. Session in-memory ليست موزعة بين instances ولا تستمر بعد restart.

## حماية Controllers وActions

Actions الرئيسية في Home وControlPanel وHousing وIncomeSystem وElectronicBillSystem تستدعي غالباً `InitPageContext` الذي يفحص `Session[usersID]`. Notifications APIs تفحص المفتاح محلياً. لكن التغطية ليست عامة:

- Base `Index` في عدة Controllers يعيد View دون `InitPageContext`.
- `CrudController` بلا `[Authorize]` أو فحص Session عام على insert/update/delete والـ endpoints المساعدة.
- `GetDDLValues2`, `extradataload`, و`renderform` تقبل JSON بلا إثبات هوية داخل Action.
- SessionController endpoints بلا guard عام.
- سمات antiforgery موجودة على Login وبعض uploads فقط.
- حماية GET الصفحة لا تحمي تلقائياً POST المشترك.

## Authorization وPermissions

### نموذج البيانات

العلاقات التالية مؤيدة بالـ snapshot:

- `Users`, `UsersDetails`, `UsersPassword`, `UsersAuthType`.
- `Role`.
- `Distributor` المرتبط اختيارياً بـ Role، و`UserDistributor` لإسناد المستخدم بفترة نشاط.
- `Menu` و`MenuDistributor`.
- `PermissionType` الذي يحمل `permissionTypeName_E`.
- `DistributorPermissionType` الذي يربط الموزع بأنواع الصلاحيات.
- `Permission` الذي يمكن أن يستهدف User أو Role أو DSD أو Distributor مع فترة نشاط.
- Views مساندة: `V_GetListUserPermission`, `V_GetListUsersInDSD`, `V_GetFullStructureForDSD`.

الصلاحية قد تكون مباشرة للمستخدم أو عبر Role/Distributor أو DSD أو منحة عامة.

### `ft_UserPagePermissions` و`permissionTypeName_E`

الدالة المرجعية ترجع أسماء الصلاحيات الإنجليزية المميزة لمستخدم وصفحة. تطابق `menuName_E = PageName`، وتجمع المنح المباشرة ومنح Role وDSD وDistributor والمنح العامة، مع فلاتر النشاط والتاريخ.

`Masters_DataLoad` يعيدها في result set الأول. Controllers تحول `permissionTypeName_E` إلى flags لإظهار INSERT/UPDATE/DELETE والأفعال المتخصصة. هذا UI gating وليس حاجزاً أمنياً.

`Masters_CRUD` المرجعي يقارن الصفحة والفعل والمستخدم بالصلاحيات قبل فروع كتابة كثيرة، ثم يوجه إلى feature SP. الرسم: [Security-Authorization-and-Permission-Flow.md](../Diagrams/Security-Authorization-and-Permission-Flow.md).

### حد الثقة الحرج في CRUD

**مخاطرة حرجة مثبتة من الكود:** `/crud/insert|update|delete` تقرأ `pageName_`, `ActionType`, `idaraID`, `entrydata`, و`hostname` من form. `extradataload` يقرأها من JSON. لا يستبدل Controller `entrydata` بـ Session user ولا `idaraID` بـ Session Idara.

لأن SQL يستخدم `entrydata` عند فحص الصلاحية والتدقيق، يستطيع العميل تغيير سياق الهوية قبل وصوله للقاعدة. لم يُجر اختبار استغلال أو كتابة. القيم الرقمية الافتراضية الثابتة في update/delete تزيد أثر غياب الحقول.

## إدارة المستخدمين وكلمات المرور

- صفحة ControlPanel Users محمية بفحص Session وتستخدم DataLoad/CRUD وصلاحيات الصفحة؛ لم يُعاد توثيق البرنامج تفصيلياً.
- `POST /Login/ChangePassword` يأخذ user ID من Session، ويتحقق من وجود القديم والجديد ومن طول 8، ثم يستدعي `ReSetUserPassword` بفعل `CHANGEUSERPASSWORD`.
- التعريف المرجعي يتحقق من القديمة بالـ salt/hash، ينشئ salt عشوائياً، يعطل القديمة، وينشئ سجلاً جديداً ويضبط `ChangedPassword=1`.
- JavaScript يفرض حرفاً كبيراً وصغيراً ورقماً، وController يثبت الطول فقط. تعريف SQL الحي يفرض 8 خانات على الأقل مع رقم وحرف إنجليزي واحد ويمنع مساواة الجديدة بالحالية؛ لا يفرض التفريق بين الكبير والصغير، ولذلك يبقى هذا الشرط UI-only.
- فرع reset الإداري في snapshot يستخدم كلمة مرور افتراضية ثابتة معروفة داخل الإجراء ويضبط `ChangedPassword=0`. لم تُذكر قيمتها هنا. هذا خطر حرج حتى يثبت اختلاف التعريف الحي أو وجود ضوابط تعويضية.
- لا توجد أدلة على history أو expiry enforcement أو lockout أو breached-password checking.

## AuditLog وErrorLog

`AuditLog` المرجعي يحمل TableName وActionType وRecordID وPerformedBy وNotes وPerformedAt. إجراءات كثيرة تكتب إليه. لأن `entrydata` غالباً يصبح PerformedBy، فإن السياق القابل للتعديل يضعف نسبة الفعل إلى منفذه. لا يوجد دليل على immutability أو retention أو حماية القراءة.

`ErrorLog` المرجعي يحمل رسالة الخطأ وشدته وحالته واسم SP ووقت/مستخدم/host. `Masters_CRUD` المرجعي يعيد أخطاء الأعمال 50001..50999 دون تسجيل، ويسجل الأخطاء غير المتوقعة ويرجع رمزاً عاماً. في MVC توجد مواضع ترجع `ex.Message` للعميل، منها Login وبعض CRUD/extra-data paths، وقد تكشف تفاصيل داخلية.

لم تُقرأ صفوف AuditLog أو ErrorLog فعلية.

## Notifications المرتبطة بالصلاحيات

`Notifications_Create` المرجعي ينشئ Notification ثم يحدد المستلمين حسب User أو Distributor أو Role، ومع Idara عند بعض الأنماط، أو DSD أو Menu + Idara أو PermissionType(s) + Idara أو جميع المستخدمين النشطين. يستخدم حالة المستخدم وفترات نشاط علاقات الصلاحيات، ثم ينشئ `UserNotifications` مع منع التكرار.

هذا توزيع مستلمين قائم على الصلاحية وليس منح صلاحية. صحة منع IDOR عند تحديث إشعار تعتمد على الإجراءات الحية التي لم تُقرأ تعريفاتها تفصيلياً.

## Antiforgery وCookies وHSTS

- Antiforgery مسجل، وcookie الخاصة به HttpOnly/Secure.
- Login وبعض upload POSTs فقط تحمل `[ValidateAntiForgeryToken]`; لا توجد `AutoValidateAntiforgeryToken` عامة.
- CRUD وChangePassword وNotifications وSession POSTs بلا validation مثبتة، وLogout الرئيسي GET.
- Cookie Policy يفرض Secure فقط. Session cookie HttpOnly/Secure/Essential. SameSite والاسم/domain/path غير مخصصة.
- `UseHttpsRedirection` فعال.
- HSTS سنة مع IncludeSubDomains ويطبق دون شرط Production ظاهر، ويضاف header نفسه يدوياً أيضاً.
- لا يوجد تحقق مستودع من TLS termination أو Forwarded Headers أو ملاءمة IncludeSubDomains.
- توجد CSP وX-Frame-Options وnosniff وCOOP/COEP/CORP وPermissions-Policy. CSP الداخلية تسمح `unsafe-inline`, `unsafe-eval` ومصادر `https:` عامة، فتقل فعاليتها ضد XSS.

## المخاطر الأمنية المثبتة

| الشدة | الخطر | الدليل/الأثر |
| --- | --- | --- |
| حرج | سياق هوية وصلاحية CRUD قابل للتعديل | `entrydata/idaraID/pageName_/ActionType` من العميل بينما SQL يستخدمها للفحص والتدقيق. |
| حرج | reset مرجعي بكلمة مرور افتراضية ثابتة | snapshot لـ `ReSetUserPassword`; يلزم إثبات حي. |
| عالٍ | لا scheme/claims/guard عام | لا AddAuthentication/AddCookie/SignInAsync/Authorize، وSessionGuard غير مسجل. |
| عالٍ | تغطية CSRF جزئية | POSTs حساسة بلا سياسة antiforgery عامة وLogout عبر GET. |
| عالٍ | كشف تفاصيل استثناء | بعض المسارات تعيد `ex.Message` للمستخدم. |
| متوسط | لا rate limit/lockout/MFA مثبت | يزيد خطر التخمين؛ لم ينفذ اختبار. |
| متوسط | لا تدوير Session ID مثبت | `Session.Clear` فقط. |
| متوسط | Session in-memory | مشكلات scale-out/restart دون مخزن موزع أو sticky sessions. |
| متوسط | بيانات شخصية وصور في Session/DOM | National ID والاسم والصورة والسياق التنظيمي؛ بعض الهوية في hidden inputs. |
| متوسط | الثقة في X-Forwarded-For | لا ForwardedHeaders middleware؛ host المسجل قابل للتزييف وDNS cache غير محدود. |
| متوسط | CSP داخلية ضعيفة نسبياً | unsafe-inline/unsafe-eval ومصادر https عامة. |
| منخفض/متوسط | أسماء Session غير متسقة | قد تنتج سياقاً أو فحوصاً ناقصة. |
| منخفض/متوسط | KeepAlive بلا هوية | ينشئ/يمدد Session غير مصادق عليها؛ لا يمنح دخولاً بذاته. |

## غير متحقق منه

1. اختبار المصادقة وتغيير كلمة المرور والخروج end-to-end بحسابات اختبار؛ لم يُنفذ في التوثيق.
2. IIS/reverse proxy وTLS وForwarded Headers الفعلية.
3. SameSite وData Protection keys وتدوير Session ID.
4. صلاحيات حساب اتصال التطبيق وقيود حماية جداول الأمان والسجلات.
5. retention/monitoring ومنع العبث في AuditLog/ErrorLog.
6. منع IDOR في إجراءات Notifications الحية.
7. WAF/rate limiting/MFA خارج المستودع.

## الكائنات المرتبطة

| المجال | الكائنات |
| --- | --- |
| الدخول | `Users`, `UsersDetails`, `UsersPassword`, `UsersAuthType`, `GetSessionInfoForMVC`, `ReSetUserPassword` |
| الصلاحيات | `Role`, `Distributor`, `UserDistributor`, `Menu`, `MenuDistributor`, `PermissionType`, `DistributorPermissionType`, `Permission`, `ft_UserPagePermissions`, `V_GetListUserPermission` |
| البوابات | `Masters_DataLoad`, `Masters_CRUD` |
| السجلات | `AuditLog`, `ErrorLog` |
| الإشعارات | `Notifications`, `UserNotifications`, `Notifications_Create` |
| المساندة | `V_GetListUsersInDSD`, `V_GetFullStructureForDSD` |

## النتيجة

اكتملت مهمة الأمان ضمن النطاق، دون بدء توثيق برنامج أو مهمة تالية.

## تحديث المطابقة الحية 2026-08-22

تحققت تعريفات `GetSessionInfoForMVC`, `ReSetUserPassword`, `SetUserPassword`, `ft_UserPagePermissions`, `V_GetListUserPermission`, و`Notifications_Create` حياً وهي مطابقة للـ Snapshot. `Masters_CRUD` مختلف حياً في routing لكنه ما زال يثق بـ `entrydata/pageName_/ActionType/idaraID` الواصلة من التطبيق؛ لذلك لا تزال مخاطرة سياق العميل قائمة. فرع `HousingHandover` الحي ما زال لا يطابق ActionType بدقة. حُسم أن collation الحية غير حساسة لحالة الأحرف، لكن بيانات permissions لم تُقرأ.

## تحديث Home وLogin الحي 2026-08-23

- أعيدت قراءة `GetSessionInfoForMVC`, `ReSetUserPassword`, `GetUserMenuTree`, `HomeDL`, `ChartsDL`, و`Masters_DataLoad` عبر SELECT-only catalog access؛ كلها مطابقة للـSnapshot.
- تأكد حياً أن reset الإداري ما زال يستخدم قيمة افتراضية ثابتة (غير معروضة)، وأن التخزين يستخدم salt عشوائياً وSHA2-256.
- تأكد أن سياسة SQL لتغيير كلمة المرور هي 8 خانات + رقم + حرف إنجليزي + اختلافها عن الحالية؛ شرطا uppercase/lowercase في الواجهة فقط.
- `GetSessionInfoForMVC` يفرض الحساب والتفاصيل وفترة النشاط والهيكل وكلمة المرور، لكنه لا يستخدم معامل `hostName` داخل جسمه.
- `GetUserMenuTree` يطبق المنح المباشرة وRole وDSD وDistributor والعامة مع فترات النشاط، ويعيد الآباء وعقد البرامج.
- بقيت المخاطر: لا guard عام/claims، CSRF جزئي، كشف `ex.Message` في الدخول، reset ثابت، لا rate limiting/lockout/MFA، تغيير إجباري UI-only، وتسجيل JSON القائمة الكامل.
- Home يضيف مخاطرتين خارج التحليل السابق: GET ينفذ Business SP للفوترة، وPrivacy لا تستدعي فحص Session. لم يُنفذ الإجراء أثناء التوثيق.
