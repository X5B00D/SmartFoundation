# دليل مطور SmartFoundation النهائي

## 1. الغرض ومصادر الحقيقة

يوثق هذا الدليل الأسلوب الجاري في التطبيق، وبخاصة نمط Housing الحالي. ترتيب الثقة هو: الكود الفعلي، ثم تعريفات وMetadata قاعدة `DATACORE` الحية المقروءة باستعلامات `SELECT` فقط، ثم ملفات `SmartFoundation.Database` بوصفها Snapshot مرجعياً غير مضمون الحداثة. عند اختلاف Snapshot مع القاعدة الحية، يعتمد التعريف الحي وتوثق الفجوة.

نقطة التشغيل هي `SmartFoundation.Mvc/Program.cs`. لا تستخدم `Program.cs` الجذري أو `Views/` و`wwwroot/` الجذريين مرجعاً للتطبيق.

## 2. خريطة الحل والمسار التنفيذي

- `SmartFoundation.Mvc`: نقطة التركيب، Controllers، Views، Session وHTTP.
- `SmartFoundation.Application`: الخدمات وربط أسماء إجراءات الدخول.
- `SmartFoundation.DataEngine`: تنفيذ Dapper وإرجاع `SmartResponse` و`DataSet`.
- `SmartFoundation.UI`: نماذج الصفحة ومكونات العرض المشتركة.
- `SmartFoundation.Application.Tests`: مشروع الاختبارات الآلي الحالي.
- `SmartFoundation.Database`: Snapshot للفهم والمقارنة فقط.

مسار القراءة القياسي:

`Controller -> MastersServies -> Masters_DataLoad -> feature DL -> DataSet -> SmartPageViewModel -> SmartRenderer`

مسار الكتابة القياسي:

`Form/SmartTable -> CrudController -> MastersServies -> Masters_CRUD -> feature SP -> IsSuccessful/Message_`

## 3. إضافة Module أو صفحة

1. افحص صفحة Housing مماثلة، وابدأ من `WaitingListByResident` إن لم يوجد نمط محلي أوضح.
2. عرّف البرنامج والقائمة والصفحة وعملياتها من إدارة الصفحات؛ حافظ على تطابق اسم الصفحة و`ActionType` حرفياً عبر الواجهة والبوابة الحية.
3. أضف Controller أو partial Controller وView ونماذج UI المطلوبة.
4. أضف فرع القراءة إلى `Masters_DataLoad` وفرع الكتابة إلى `Masters_CRUD`، ثم downstream DL/SP عند الحاجة.
5. اجعل أول result set للقراءة هو الصلاحيات، ثم result sets الميزة بترتيب ثابت موثق.
6. اختبر التحميل، كل عملية كتابة، حالات الرفض، وإخفاء الأزرار، ثم طابق المسار مع تعريف القاعدة الحية.

لا تضف downstream feature procedure إلى `ProcedureMapper` إذا كانت بوابة موجودة تتولى التوجيه.

## 4. Controller وpartial Controller

في الوحدات الكبيرة استخدم class جزئية باسم Controller واحد، وملفاً لكل صفحة أو مجموعة مترابطة. حافظ على namespace والـconstructor الموجودين في الملف الأساسي.

في Action بأسلوب Housing:

1. استدعِ `InitPageContext(out redirectResult)` مبكراً وأعد redirect عند الفشل.
2. اقرأ `usersId` و`IdaraId` و`HostName` من Session بالطريقة المشتركة.
3. اضبط `ControllerName` و`PageName` بالقيم المطابقة لمسار الصفحة والبوابة.
4. اقرأ query parameters الموثقة فقط، وابنِ parameter array بالترتيب الذي يتوقعه `MastersServies`.
5. استدعِ `GetDataLoadDataSetAsync` ثم `SplitDataSet`.
6. اعتبر Table 0 جدول الصلاحيات، ولا تغير ترتيب الجداول التالية دون تعديل جميع المستهلكين.
7. ابنِ الأعمدة والصفوف و`FormConfig` و`SmartTableDsModel` في Controller، ثم مرر `SmartPageViewModel` إلى View رقيقة.

لا تثق بحقول الهوية والنطاق القادمة من العميل كبديل عن Session. العقد الحالي يمرر بعضها من النموذج، وهذه مخاطرة موثقة لا ينبغي توسيعها.

## 5. View وSmartRenderer

تظل View رقيقة: تضبط العنوان عند الحاجة وتستدعي `SmartRenderer` بالنموذج المركب. لا تنقل منطق الأعمال أو تفسير `DataSet` أو فحص الصلاحيات إلى Razor.

`SmartRendererViewComponent` يوزع `SmartPageViewModel` على المكونات الفرعية. لذلك يجب أن يكون تكوين الصفحة كاملاً ومتسقاً في Controller: الجداول، النماذج، أدوات الشريط، الفلاتر، الرسائل وبيانات الـDDL.

## 6. FormConfig وSmartTableDsModel

استخدم `FormConfig` و`FieldConfig` لكل عملية إضافة/تعديل/إلغاء، وحدد:

- endpoint المشترك (`/crud/insert` أو `/crud/update` أو `/crud/delete`).
- حقول السياق المخفية المطلوبة.
- `ActionType` الصحيح.
- أسماء الحقول الموضعية `p01..p50`.
- Required وreadonly ونوع الإدخال ومصدر DDL.

استخدم `SmartTableDsModel` لبيانات الجدول وأعمدته وصفوفه ومفتاحه وإجراءاته وشريط الأدوات. عند وجود عدة result sets، أنشئ مجموعات مستقلة مثل `dynamicColumns_*` و`rowsList_*`. أضف aliases موضعية للصفوف عندما تحتاج النوافذ إلى تعبئة `p01..`.

لا تفترض أن index جدول DDL اسم مستقر؛ هو عقد موضعي يجب توثيقه واختباره.

## 7. Models وViewModels

- استخدم model typed عندما يكون العقد ثابتاً، و`Dictionary<string, object?>` للصفوف الديناميكية.
- حافظ على nullable semantics ولا تحول `DBNull` إلى قيمة مضللة.
- اجعل ViewModels خاصة بالعرض والتكوين، لا بإنفاذ قواعد الأعمال.
- استخدم PascalCase للأنواع والخصائص العامة، camelCase للمتغيرات والمعاملات والحقول الخاصة.
- أضف XML documentation للأعضاء العامة الجديدة أو المتغيرة جوهرياً.

## 8. MastersServies وDataSet

`MastersServies` بوابة نشطة، وليس legacy مطلوباً إزالته. حافظ عليه في الصفحات الحالية التي تعتمد result sets متعددة.

- القراءة عبر `GetDataLoadDataSetAsync` إلى `Masters_DataLoad`.
- الكتابة العامة عبر `GetCrudDataSetAsync` إلى `Masters_CRUD`.
- البيانات الإضافية الديناميكية عبر بوابة Extra Data عند استعمال النمط محلياً.
- Table 0 في تحميل صفحات Housing هو الصلاحيات؛ وما بعده بيانات الميزة وDDL حسب ترتيب downstream DL.

تحقق من عدد الجداول والأعمدة قبل الوصول إليها، وتعامل مع DataSet فارغ برسالة قابلة للتشخيص بدلاً من index exception.

## 9. SmartComponentService

يستقبل `SmartRequest` الذي يحوي `Operation` و`SpName` و`Params`. يضيف `@` داخلياً إلى أسماء المعاملات؛ لذلك لا ترسل `@` من التطبيق. ينفذ `QueryMultipleAsync` أولاً مع fallback إلى `QueryAsync`. ميزات paging/sort/filter لا تطبق إلا عندما تكون `Operation == "select"`، بينما معظم بوابات الصفحات تستخدم `"sp"`.

احفظ async I/O، ولا تنشئ connection يدوية داخل Controller. راقب أخطاء تحويل القيم وترتيب result sets لأنها أكثر أسباب الانحراف صعوبة في هذا النمط.

## 10. ProcedureMapper للبوابات فقط

يسجل `ProcedureMapper` إجراءات الدخول التي يصل إليها التطبيق مثل البوابات المشتركة أو خدمة ضيقة جديدة. لا تسجل كل `Housing.*DL/SP` إذا كانت `Masters_DataLoad` أو `Masters_CRUD` توجه إليها. المقصود الحفاظ على فصل التطبيق عن تفاصيل الإجراءات التابعة.

## 11. Masters_DataLoad وMasters_CRUD

`Masters_DataLoad`:

- يقبل السياق ثم `parameter_01..parameter_50`.
- يعيد صلاحيات الصفحة أولاً.
- يوجه حسب `pageName_` إلى DL الخاص بالميزة.
- يعيد DL بيانات الصفحة أولاً ثم مصادر القوائم.

`Masters_CRUD`:

- يوجه حسب `pageName_` و`ActionType`.
- يفحص العملية قبل استدعاء SP التابع.
- يلتزم بعقد `IsSuccessful` و`Message_`.
- يمرر أخطاء الأعمال للمستخدم، ويسجل الأخطاء غير المتوقعة في `ErrorLog`.

حافظ على أسماء العقد وحالتها وتهجئتها كما هي: `pageName_`, `ActionType`, `idaraID`, `entrydata`, `hostname`.

## 12. عقد p01..p50 وparameter_01..parameter_50

حقول Forms تسمى `p01` إلى `p50`. يحولها `CrudController` إلى `parameter_01` إلى `parameter_50`. هذا عقد موضعي؛ معنى `p03` قد يختلف بين عملية وأخرى.

عند التغيير:

1. أنشئ جدول mapping للعملية: حقل الواجهة، `pNN`، `parameter_NN`، parameter الإجراء التابع.
2. راجع تعبئة alias في صف الجدول وحقول Form معاً.
3. لا تحشر حقلاً جديداً في المنتصف؛ استعمل موضعاً متاحاً أو حدّث جميع الطبقات مع اختبار regression.
4. تحقق من type/length/nullability مقابل المعامل الحي، لا Snapshot.

## 13. إضافة صلاحية

أضف عملية الصفحة في إدارة الصفحات باسم إنجليزي يطابق `ActionType`. اربطها بالصفحة والجهات المطلوبة. في Controller اقرأ `permissionTypeName_E` من أول جدول واستخدمه لإظهار الإجراء. في `Masters_CRUD` أضف/تحقق من branch وفحص العملية قبل الكتابة. لا تعتمد على إخفاء الزر وحده.

اختبر: مستخدم مخول يرى وينفذ؛ مستخدم غير مخول لا يرى ويُرفض طلبه المباشر؛ صلاحية منتهية أو معطلة لا تعمل. لا توثق اسم صلاحية كـlive verified ما لم تتحقق بياناتها الفعلية، لأن تعريف الإجراء وحده لا يثبت منحها.

## 14. Validation وBusiness Rules

نفذ validation سريعاً في UI لتحسين التجربة، وكرره في الخادم. ضع قواعد الأعمال الحاسمة في feature SP داخل transaction لأنها نقطة الاتساق النهائية.

النمط الحي الشائع:

- `SET NOCOUNT ON`, `SET XACT_ABORT ON`.
- transaction محروسة بـ`@@TRANCOUNT` و`TRY/CATCH`.
- `THROW 50001` لأخطاء الأعمال المتوقعة و`50002` للفشل البرمجي.
- منع التكرار، التحقق من active/current state، والمفاتيح والنطاق الإداري.
- soft delete بدلاً من الحذف الفيزيائي حيث يتبع النمط المحلي.
- نجاح موحد: `SELECT 1 AS IsSuccessful, N'...' AS Message_`.

لا تجعل UI المصدر الوحيد لقواعد الحالة أو المبالغ أو الفترات.

## 15. Error Handling وLogging

- تعرض نتائج الأعمال عبر `TempData`: `Success`, `Warning`, `Error`, `Info`.
- أخطاء `50001..50999` رسائل أعمال قابلة للعرض.
- الأخطاء غير المتوقعة تسجل في `dbo.ErrorLog` وتتحول إلى رسالة عامة.
- العمليات المهمة تسجل `dbo.AuditLog`، وقد تنشئ إشعاراً عبر البوابة.
- لا تسجل كلمات مرور أو connection strings أو ملفات مرفوعة أو بيانات شخصية/مالية كاملة.
- أضف context تشخيصياً آمناً: الصفحة، العملية، correlation/time، ومعرف تقني غير حساس.

## 16. Dependency Injection والخدمات

التسجيل الفعلي في `SmartFoundation.Mvc/Program.cs` وامتدادات Application. `ConnectionFactory` singleton، و`ISmartComponentService` يقابل `SmartComponentService`، ومعظم خدمات التطبيق scoped. `CrudController` مسجل أيضاً كخدمة لأن Controllers تستعمل مساعداته.

للخدمة الضيقة الجديدة استخدم `BaseService`، اربط entry procedure فقط عبر `ProcedureMapper`، وسجل الخدمة في `ServiceCollectionExtensions`. لا ترحل صفحة Housing قائمة من `MastersServies + DataSet` دون طلب صريح.

## 17. الاختبارات

نفذ الاختبار بقدر الخطر:

- Unit tests للخدمات والتحويل والـvalidation.
- Integration tests لعقد المعاملات وترتيب result sets في بيئة اختبار مأمونة.
- Controller tests للجلسة، redirect، DataSet الفارغ، والصلاحيات.
- اختبارات رفض لكل Business Rule واختبارات authorization سلبية.
- اختبار mapping كامل بين `pNN` ومعاملات الإجراء.
- اختبار Views/SmartRenderer للجدول والنموذج والأزرار.

الأوامر المرجعية:

```powershell
dotnet build SmartFoundation.Mvc/SmartFoundation.Mvc.csproj
dotnet test SmartFoundation.Application.Tests/SmartFoundation.Application.Tests.csproj
dotnet test SmartFoundation.Application.Tests/SmartFoundation.Application.Tests.csproj --filter "FullyQualifiedName~EmployeeServiceTests"
```

قد يتطلب build الحل الكامل أدوات SQL project. لا تستخدم Business SP أو بيانات الإنتاج للاختبار.

## 18. Naming conventions

- Controllers/Actions/Models/Properties: PascalCase.
- locals/parameters/private fields: camelCase.
- partial file: `Controller.Feature.cs` وفق النمط المحلي.
- أسماء الصفحة و`ActionType` وعقد DB لا يعاد تحسينها لغوياً؛ التطابق أهم من الجمال.
- احتفظ بالتهجئات التاريخية المستخدمة في المسارات الحية، ووثقها بدلاً من تغييرها جزئياً.
- usings في أعلى الملف، واحذف غير المستخدم، وحافظ على تنسيق الملف الذي تعدله.

## 19. مطابقة الكود مع الإجراء الحي

1. حدد entry procedure من الخدمة و`ProcedureMapper`.
2. اقرأ تعريف البوابة الحية من `sys.procedures` و`sys.sql_modules` وحدد branch الصفحة/العملية.
3. اقرأ `sys.parameters` للإجراء التابع، ثم dependencies من `sys.sql_expression_dependencies`.
4. قارن الاسم، الترتيب، النوع، الطول، nullability المتوقع، result sets والجداول المتأثرة.
5. صنف النتيجة: Live verified matching، Live verified with differences، أو غير متحقق.
6. حدّث الكود/التوثيق اعتماداً على الحي، ولا تنقل سراً أو بيانات أعمال إلى الوثائق.

الاستعلامات تكون `SELECT` على metadata/definitions فقط داخل `try/catch`. لا تنفذ Business SP ولا أوامر كتابة أو DDL. إذا فشل الاستعلام، سجل فجوة واحدة وتابع دون loop أو helper executable.

## 20. Checklist التسليم

- [ ] الصفحة والعملية متطابقتان عبر UI والبوابات والإجراء الحي.
- [ ] Session context وpermission table وserver-side authorization محفوظة.
- [ ] ترتيب DataSet وDDL موثق ومختبر.
- [ ] جميع `pNN` مطابقة للمعاملات الحية.
- [ ] View رقيقة وSmartRenderer يستقبل تكويناً كاملاً.
- [ ] Business Rules داخل transaction ورسائل النجاح/الفشل موحدة.
- [ ] Audit/Error logging لا يسرب بيانات حساسة.
- [ ] DI والخدمة مسجلان بالنمط الحالي.
- [ ] اختبارات النجاح والرفض والصلاحيات نفذت.
- [ ] Snapshot لم يستخدم لإثبات سلوك حي.

## 21. فجوات يجب إبقاؤها ظاهرة

لا تزال الاختبارات end-to-end، بيانات منح الصلاحيات الفعلية، تنفيذ الاستيراد، والتحقق البصري لبعض تقارير PDF خارج نطاق التحقق المنجز. توجد أيضاً فجوات موثقة في عقد UploadExcel، ربط `DeductListReport` الحي، بعض أسماء/حالات العمليات، وحقول modal. لا تحول أياً منها إلى حقيقة مؤكدة دون اختبار مناسب.
