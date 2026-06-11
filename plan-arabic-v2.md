# خطة نظام تذاكر ITIL 4 — النسخة الثانية

## 1. حالة المستند

- الحالة: مسودة معاد تخطيطها V2 لمراجعة المستخدم
- الإصدار: V2 (يوسّع V1 بأنواع تشغيلية، سلاسل موافقات، تحكيم هرمي، أبناء دمج-و (AND-join)، وتوضيح بين الفنيّين)
- اللغة: الإنجليزية
- النمط المرجعي: `SmartFoundation.Mvc/Controllers/Housing/WaitingList/HousingController.WaitingListByResident.cs`
- عقد التشغيل: `MastersServies` -> `Masters_DataLoad` / `Masters_CRUD` -> `[Tickets].[...DL]` / `[Tickets].[...SP]`
- الأساس البياني: كائنات المؤسسات، المستخدمين، الصلاحيات، المقيمين، المراجعة، الإشعارات، والبوابات الموجودة فعلاً في لقطة المستودع
- ملاحظة النطاق: يحدّد هذا المستند تصميم V2؛ وليس بذاته سكريبت النشر
- علاقة V1: V2 متوافق رجعياً مع جداول وإجراءات V1. الجداول الجديدة (`OperationalType`، `ApprovalStep`، `TicketApproval`، `ApprovalStepHistory`) تمدّد المخطط دون كسر عقود V1 القائمة.

## 2. الملخص التنفيذي

توسّع هذه الخطة تصميم التذاكر بأسلوب Housing في V1 بقدرات حدّدها العمل منذ تجميد النطاق الأولي. V2 تحافظ على كل ما بنته V1: مخطط `[Tickets]`، نموذج الطالب المزدوج، توجيه إجراءات البوابة، خط أنابيب تجميع الصفحات عبر `MastersServies` / `DataSet` / `SplitDataSet`، وأسلوب العرض الرقيق عبر Razor / `SmartRenderer`.

V2 تضيف خمس قدرات جديدة فوق أساس V1.

**أنواع التذاكر التشغيلية.** تحمل التذاكر الآن `operationalTypeID_FK` يصنّفها كأحد أربعة أنواع: طلب خدمة، طلب صرف، طلب تنفيذ، أو طلب معاينة. لكل نوع قواعد توجيه ومتطلبات موافقة وسلوك سير عمل مختلف. يُحدَّد النوع عند الاستقبال ويؤثّر في كل قرار لاحق.

**سلاسل موافقات متعددة المستويات.** الموافقة لم تعد بوابة ثنائية واحدة. تُخزَّن خطوات الموافقة في `[Tickets].[ApprovalStep]` بسلسلة مرتّبة: فنّي، مشرف، مدير فرع، مدير قسم، مدير إدارة. تتغيّر السلسلة حسب النوع التشغيلي والخدمة. يتم تتبّع التقدّم صفاً بصف في `[Tickets].[TicketApproval]`. لا يمكن للتذكرة تجاوز خطوة موافقة حتى يتصرّف المعتمد المطلوب. الموافقة تُوقف اتفاقية مستوى الخدمة (SLA) أثناء انتظار الخطوة.

**التحكيم الهرمي.** عندما يتنازع وحدان تنظيميان حول الملكية، يحلّ النظام النزاع عند المستوى الهرمي الصحيح. الأقسام تصعّد إلى محكّم على مستوى الفرع. الفروع تصعّد إلى مستوى الإدارة. الإدارات تصعّد إلى مستوى إدارة عامة (Idara). المحكّم هو نوع `Distributor` جديد مرتبط بـ DSDID الوحدة الأصل. هذا يحلّ محل نموذج التحكيم المسطّح في V1 بنموذج يعكس سلسلة السلطة الفعلية.

**أبناء متوازيون مع دمج-و (AND-join).** يمكن للتذكرة الأب أن تُنتج عدّة أبناء في آن واحد. يدخل الأب حالة `BLOCKED` ويبقى فيها حتى يصل كل ابن إلى حالة نهائية (تمّت التسوية، أُغلقت، أو أُلغيت). هذا دمج-و (AND-join): يجب أن تكتمل كل الأبناء قبل أن يستأنف الأب. نموذج أب-فرعي كان موجوداً في V1، لكن V2 تجعل دلالات الحظر صريحة وتضيف سبب الإيقاف `WAITING_CHILD` كمفهوم من الدرجة الأولى.

**التوضيح بين الفنيّين.** التوضيح لم يعد مقتصراً على "الطالب يفتقر إلى معلومات." V2 تدعم التنسيق بين الفنّيين في وحدات تنظيمية مختلفة. نموذج التوضيح يحمل الآن كلاً من `RequestedFromDSDID_FK` و `RequestedFromUsersID_FK`، مما يسمح لفنّي بسؤال فنّي في وحدة أخرى عن مدخلات دون المرور بالتحكيم. هذا يحافظ على مسار المراجعة نظيفاً ويتجنّب التصعيد غير الضروري.

كل صفحات الواجهة تتبع النمط المرجعي لـ Housing: المتحكمات تبني `SmartPageViewModel` و `FormConfig` و `SmartTableDsModel` و `FieldConfig` من جانب الخادم. طرق العرض تستدعي `SmartRenderer`. عمليات القراءة تعيد مجموعة نتائج الصلاحيات أولاً. عمليات الكتابة تمر عبر `CrudController` باستخدام التعيين من `p01..p50` إلى `parameter_01..parameter_50`. إجراءات `[Tickets].[...SP]` اللاحقة تملك التحقق التجاري ومسار المراجعة وكتابات قاعدة البيانات. عقد البوابة لم يتغيّر.

## 3. المشكلة التشغيلية

يحتاج العمل إلى نظام تذاكر يستطيع:

1. قبول الطلبات من المستخدمين الداخليين والمقيمين على حدٍّ سواء.
2. توجيه الخدمات المعروفة إلى الطابور التنظيمي الصحيح باستخدام الحقيقة التنظيمية القائمة.
3. توجيه الطلبات غير المعروفة أو غير الواضحة إلى محكّم دون كسر مسار المراجعة.
4. الفصل بين التوجيه الخاطئ ونقص المعلومات والتأخير الناتج عن التبعيات.
5. دعم معالجة الحوادث ومعالجة طلبات الخدمة وعلاقات المشاكل/السبب الجذري في نموذج مُنسّق واحد.
6. تتبّع مستويات الخدمة بعدل، بما في ذلك وقت الإيقاف الناتج عن التحكيم والتوضيح والموافقات وعمل الأبناء التابعين.
7. دعم إغلاق بمراجعة الجودة بدلاً من السماح لكل تذكرة تمّت تسويتها بأن تُغلق نهائياً فوراً.
8. تحسين دليل الخدمات مع الوقت بناءً على تذاكر "أخرى" المتكررة.
9. إنتاج لوحات معلومات وتقارير إدارية دون تجاوز بنية التطبيق والصلاحيات القائمة.
10. الحفاظ على معايير المراجعة المركزية وتسجيل الأخطاء المستخدمة فعلاً في Housing.
11. **التمييز بين أربعة أنواع تذاكر تشغيلية** (طلب خدمة، طلب صرف، طلب تنفيذ، طلب معاينة) لأن كل نوع يتبع مسارات توجيه وسلاسل موافقات وسير عمل تسوية مختلفة.
12. **فرض سلاسل موافقات متعددة المستويات** حيث قد يحتاج طلب صرف إلى موافقة الفنّي والمشرف ومدير الإدارة قبل بدء التنفيذ، بينما قد تحتاج معاينة بسيطة فقط إلى توقيع الفنّي والمشرف.
13. **معالجة أوامر عمل الصيانة** التي تمتد عبر وحدات تنظيمية متعددة، حيث يُنتج طلب أب واحد (مثلاً صيانة مبنى) تذاكر أبناء متوازية للأعمال الكهربائية وأعمال السباكة والدهان، ولا يمكن إغلاق الأب حتى تكتمل كل الأبناء.
14. **دعم التنسيق بين الفنيّين** عبر الحدود التنظيمية دون إجبار كل سؤال بين الوحدات على الدخول في عملية التحكيم الرسمية.
15. **حلّ النزاعات التنظيمية عند المستوى الهرمي الصحيح**، بحيث تُعالج خلافات مستوى القسم على مستوى الفرع، وخلافات مستوى الفرع على مستوى الإدارة، وخلافات مستوى الإدارة على مستوى إدارة عامة (Idara).

## 4. النطاق

### 4.1 ضمن نطاق V2

كل ما في V1، بالإضافة إلى:

- `[Tickets].[OperationalType]` جدول مرجعي و `operationalTypeID_FK` على `[Tickets].[Ticket]`
- `[Tickets].[ApprovalStep]` جدول رئيسي يحدّد سلاسل موافقات مرتّبة حسب النوع التشغيلي والخدمة
- `[Tickets].[TicketApproval]` جدول معاملات يتتبّع قرارات الموافقة الفردية
- `[Tickets].[ApprovalStepHistory]` جدول تاريخي لتغييرات سلسلة الموافقات
- حالة تذكرة `WAITING_APPROVAL` وسبب إيقاف `WAITING_APPROVAL`
- توجيه التحكيم الهرمي: نزاعات الأقسام إلى محكّم الفرع، نزاعات الفروع إلى محكّم الإدارة، نزاعات الإدارات إلى محكّم إدارة عامة (Idara)
- المحكّم كنوع `Distributor` جديد مرتبط بـ DSDID الوحدة الأصل
- دلالات أب-فرعي مع دمج-و (AND-join): يدخل الأب حالة `BLOCKED`، ويستأنف فقط عندما يصل كل الأبناء إلى حالة نهائية
- التوضيح بين الفنيّين: طلبات التوضيح يمكن أن تستهدف DSD ومستخدماً محدداً في وحدة تنظيمية أخرى
- مدخلات مصفوفة الصلاحيات لكل صفحات وإجراءات التذاكر
- صفحات واجهة ديناميكية بأسلوب Housing باستخدام `SmartRenderer` و `SmartPageViewModel` و `FormConfig` و `SmartTableDsModel`
- صفحة ضبط سلسلة الموافقات (`ApprovalStepConfig`) كـ `pageName_` جديد
- صفحة سير عمل موافقات التذكرة (`TicketApprovals`) كـ `pageName_` جديد

نطاق V1 الكامل المنقول:

- مخطط بيانات `[Tickets]`
- جداول مرجعية، رئيسية، معاملات، وتاريخية
- فروع البوابة داخل `[dbo].[Masters_DataLoad]` و `[dbo].[Masters_CRUD]`
- إجراءات `[Tickets].[TicketDL]`، `[Tickets].[TicketSP]`، `[Tickets].[ServiceCatalogDL]`، `[Tickets].[ServiceCatalogSP]`، و `[Tickets].[TicketReportDL]` اللاحقة
- صفحات MVC بأسلوب Housing مدعومة بـ `MastersServies` و `DataSet` و `SplitDataSet`
- إدارة دليل الخدمات وقواعد التوجيه
- إنشاء التذاكر من كلا نوعي الطالبين
- تعيين الطوابير وتعيين المستخدمين
- سير عمل التحكيم
- سير عمل التوضيح
- تذاكر أب-فرعي لتتبع التبعيات والمشاكل
- تتبّع اتفاقية مستوى الخدمة (SLA) مع الإيقاف/الاستئناف
- مراجعة الجودة قبل الإغلاق النهائي
- اقتراحات الدليل من تذاكر "أخرى" المتكررة
- لوحات المعلومات ونماذج التقارير للقراءة

### 4.2 خارج نطاق V2

- نقاط نهاية REST أو JSON مستقلة
- استبدال `[dbo].[CrudController]` أو عقد `p01..p50`
- استبدال `[dbo].[Notifications_Create]`
- نظام المرفقات
- إعادة تصميم البوابة العامة
- التصعيد التلقائي عبر SQL Agent أو مهام خلفية
- CMDB / سجل الأصول
- دمج مخطط `[support]` المنفصل في هذا النظام
- أبناء متوازيون بدلالات OR-join (فقط دمج-و (AND-join) ضمن النطاق)
- تخطي أو تفويض سلسلة الموافقات جزئياً (كل خطوة يجب أن يتصرف فيها المعتمد المحدّد)

## 5. مبادئ التصميم الرئيسية

1. **توجيه البوابة إلزامي.** كل صفحة يجب أن تمر عبر `[dbo].[Masters_DataLoad]` أو `[dbo].[Masters_CRUD]` باستخدام فروع `@pageName_`.
2. **اصطلاحات Housing تتقدّم على أفكار إعادة التصميم العامة.** يتم الحفاظ على نمط المتحكم و `DataSet` و `SplitDataSet` و Razor الرقيق.
3. **`DSDID_FK` هو حقيقة التوجيه.** أي مستوى عرض هو وصفي فقط.
4. **`IdaraID_FK` موجود على كل جدول في `[Tickets]`.**
5. **`UsersID_FK` يحافظ على اصطلاح المستودع القائم مع حرف `s` الزائد.**
6. **هوية الطالب ذات مصدر مزدوج.** يمكن للتذكرة أن تشير إمّا إلى `[dbo].[Users]` أو `[Housing].[ResidentInfo]`، لكن لا يمكنها أبداً ألّا تشير إلى أيّ منهما.
7. **حالة التذكرة والتحكيم والتوضيح والموافقة والإيقاف والتسوية وقرارات الجودة يجب أن تبقى مفاهيم أعمال متمايزة.** الموافقة ليست مراجعة الجودة. الانتظار من أجل الموافقة ليس الانتظار من أجل التوضيح.
8. **محاذاة ITIL 4 يجب أن تكون مرئية في المخطط والإجراءات وتصميم الصفحات، لا في النص السردي فقط.**
9. **كل عملية كتابة يجب أن تنتج صفوف تاريخ محلية ومدخلات في `[dbo].[AuditLog]` المركزي.**
10. **أخطاء التحقق التجاري يجب أن تستخدم `THROW 50001`؛ الأعطال غير المتوقعة يجب أن تُسجَّل في `[dbo].[ErrorLog]` وتُعاد رميها.**
11. **جداول المعاملات والتاريخ تستخدم `BIGINT IDENTITY`؛ الجداول المرجعية تستخدم `INT IDENTITY`.**
12. **جداول التاريخ للإلحاق فقط ولا تستخدم حذف ناعم.**
13. **النوع التشغيلي يقود سير العمل، وليس العكس.** النوع التشغيلي (طلب خدمة، طلب صرف، طلب تنفيذ، طلب معاينة) يحدّد أي سلسلة موافقات تنطبق، وكيف يعمل التوجيه، وما شكل التسوية. ليس تسمية تجميلية.
14. **خطوات الموافقة مرتّبة ومخزّنة كبيانات، وليست منطقاً مشفّراً.** السلسلة (فنّي، مشرف، مدير فرع، مدير قسم، مدير إدارة) تعيش في `[Tickets].[ApprovalStep]` مع `stepOrder` صريح. هذا يعني أن السلسلة يمكن أن تختلف حسب النوع التشغيلي والخدمة دون تغيير كود الإجراء المخزّن.
15. **التحكيم الهرمي يعكس الهيكل التنظيمي الفعلي.** النزاعات تصعّد مستوى واحداً: الأقسام إلى الفروع، الفروع إلى الإدارات، الإدارات إلى إدارة عامة (Idara). يُحدَّد المحكّم بالهيكل التنظيمي، لا بالإعدادات.
16. **دمج-و (AND-join) هو نموذج حظر أب-فرعي الوحيد.** عندما يُنتج الأب أبناءً متوازيين، يكون الأب محجوباً حتى يكتمل كل ابن. لا يوجد سلوك جزئي أو OR-join.
17. **التوضيح بين الفنيّين سير عمل من الدرجة الأولى، وليس دردشة غير رسمية.** ينشئ صفاً قابلاً للتتبّع في `[Tickets].[TicketClarification]`، ويُوقف اتفاقية مستوى الخدمة (SLA) عند ضبطه لذلك، ويتطلّب استجابة رسمية قبل أن تتقدّم التذكرة.

## 6. محاذاة ممارسات ITIL 4

### 6.1 إدارة الحوادث
- دورة الحياة: استقبال -> فرز -> تعيين -> قيد التنفيذ -> تمّت التسوية -> مراجعة الجودة -> مُغلقة.
- الجداول الأساسية: `[Tickets].[Ticket]`، `[Tickets].[TicketHistory]`، `[Tickets].[TicketQualityReview]`.
- الحقول الأساسية: `ticketStatusID_FK`، `impactID_FK`، `urgencyID_FK`، `ticketPriorityID_FK`، `resolutionTypeID_FK`، `resolutionNotes`، `isMajorIncident`.

### 6.2 إدارة دليل الخدمات
- ملكية الدليل في `[Tickets].[ServiceCategory]`، `[Tickets].[Service]`، `[Tickets].[ServiceRoutingRule]`، `[Tickets].[ServiceSLAPolicy]`.
- الخدمات المعروفة تُوجَّه مباشرة من قاعدة الدليل؛ "أخرى" تُوجَّه إلى التحكيم.
- تحمل الخدمات الآن `operationalTypeID_FK` لتصنيفها حسب النوع التشغيلي.

### 6.3 إدارة مستوى الخدمة
- الأولوية مشتقّة عبر `[Tickets].[PriorityMatrix]` من التأثير × الاستعجال.
- مواعيد تسوية التذكرة والساعات المتراكمة في `[Tickets].[TicketSLA]`.
- فترات الإيقاف في `[Tickets].[TicketPauseSession]`.
- كل تحوّل في حالة اتفاقية مستوى الخدمة (SLA) يُنسخ إلى `[Tickets].[TicketSLAHistory]`.
- اتفاقية مستوى الخدمة (SLA) تتوقف أثناء خطوات الموافقة عندما يكون سبب الإيقاف `WAITING_APPROVAL` مضبوطاً كموقف لـ SLA.

### 6.4 إدارة المشاكل
- `[Tickets].[Ticket]` يحمل `ParentTicketID_FK` و `RootTicketID_FK`.
- `ticketClassID_FK` يميّز بين سجلات الحوادث وطلبات الخدمة والمشاكل.
- سلاسل أب-فرعي تُستخدم للحظر وتتبّع السبب الجذري، وليس فقط تجميعاً غير رسمي.
- V2 تضيف حظر دمج-و (AND-join): الأب يكون `BLOCKED` حتى يصل كل الأبناء إلى حالة نهائية.

### 6.5 التحسين المستمر
- تذاكر "أخرى" يمكن أن تنتج صفوفاً منظمة في `[Tickets].[ServiceCatalogSuggestion]`.
- الاقتراحات قابلة للمراجعة ويمكن تحويلها إلى مدخلات في الدليل عبر `[Tickets].[ServiceCatalogSP]`.

### 6.6 المراقبة وإدارة الأحداث
- تقارير V1 مدفوعة بالعرض/الإجراء عبر `[Tickets].[TicketReportDL]` وبوابة `TicketReports`.
- لوحات المعلومات تغطي backlog ومخاطر تجاوز اتفاقية مستوى الخدمة (SLA) وطابور مراجعة الجودة وأخطاء التوجيه وتقادم التوضيح والحوادث الكبرى وحالة خط أنابيب الموافقات والأبناء المحجوبين.

### 6.7 تمكين التغيير
- التغييرات في قواعد التوجيه وسياسات اتفاقية مستوى الخدمة (SLA) تتم فقط عبر `[Tickets].[ServiceCatalogSP]`.
- كل تغيير يكتب مراجعة مركزية بالإضافة إلى `[Tickets].[ServiceRoutingRuleHistory]` المحلي.

### 6.8 ممارسة موافقة سير العمل
- سلاسل الموافقات مُعرَّفة في `[Tickets].[ApprovalStep]` بخطوات مرتّبة حسب组合 النوع التشغيلي والخدمة.
- تقدّم الموافقة مُتتبَّع في `[Tickets].[TicketApproval]` مع قرارات المعتمدين الفرديين.
- سلسلة الموافقات بوابة إلزامية بين الاستقبال والتنفيذ للأنواع التشغيلية التي تتطلب ذلك.
- الموافقة تُوقف اتفاقية مستوى الخدمة (SLA) عندما يكون `WAITING_APPROVAL` سبب إيقاف لـ SLA.
- الرفض في أي خطوة يعيد التذكرة إلى المرحلة السابقة مع سبب مُسجَّل.
- تاريخ الموافقة يكتب في كل من `[Tickets].[ApprovalStepHistory]` و `[dbo].[AuditLog]`.

## 7. النموذج الوظيفي

### 7.1 مصادر الطلبات
- طالب داخلي: يُعرَّف `requesterTypeID_FK` كمستخدم داخلي ويُملأ `UsersID_FK`.
- طالب مقيم: يُعرَّف `requesterTypeID_FK` كمقيم ويُملأ `residentInfoID_FK`.
- إجراء إنشاء التذكرة يرفض الصفوف حيث يكون كلاهما فارغاً أو كلاهما مملوءاً.

### 7.2 اختيار الدليل
- خدمة معروفة: يُملأ `serviceID_FK` ويُشتق التوجيه/اتفاقية مستوى الخدمة (SLA) الافتراضية من ضبط الدليل.
- خدمة أخرى: `serviceID_FK` فارغ و `otherServiceText` مطلوب.
- تحمل الخدمات `operationalTypeID_FK`، لذا اختيار خدمة معروفة يضبط النوع التشغيلي أيضاً.

### 7.3 نموذج التوجيه
- هدف التوجيه هو `CurrentDSDID_FK` الحالي على `[Tickets].[Ticket]`.
- `CurrentDistributorID_FK` الاختياري يحدّد دور الطابور إذا أرادت المؤسسة صندوق وارد قائم على المنصب.
- `AssignedToUsersID_FK` هو المنفذ المعيَّن الحالي وقد يبقى فارغاً بينما التذكرة في الطابور فقط.
- قواعد التوجيه يمكن أن تختلف حسب النوع التشغيلي، مما يسمح بتوجيه تذاكر طلب صرف إلى المالية وتذاكر طلب معاينة إلى العمليات الميدانية حتى لنفس الخدمة.

### 7.4 نموذج التعيين
- مالك الطابور أو مشرف مخوّل يُعيّن العمل لمستخدم فعلي.
- يتم التحقق من الأهلية مقابل البيانات النشطة في `[dbo].[V_GetListUsersInDSD]` ونطاق DSD الحالي.
- إعادة التعيين تحافظ على التذكرة داخل النطاق المخوَّل وتكتب صفاً تاريخياً جديداً.

### 7.5 نموذج التحكيم
- التحكيم لنزاعات المسؤولية أو توجيه الخدمات غير المعروفة.
- التوضيح ليس تحكيماً.
- حالة التحكيم المفتوح يمثّلها حالة التذكرة مع صف نشط في `[Tickets].[TicketArbitration]`.
- التوجيه الهرمي: نزاعات مستوى القسم تصعّد إلى محكّم على مستوى الفرع؛ نزاعات مستوى الفرع تصعّد إلى مستوى الإدارة؛ نزاعات مستوى الإدارة تصعّد إلى مستوى إدارة عامة (Idara).
- يُحدَّد المحكّم كسجل `Distributor` مرتبط بـ DSDID الوحدة الأصل.
- `[Tickets].[TicketArbitration]` يحمل `ArbitratorDSDID_FK` مشيراً إلى المستوى الهرمي المناسب.

### 7.6 نموذج التوضيح
- التوضيح للمعلومات المفقودة أو الغامضة.
- V2 توسّع التوضيح إلى ما بعد الطلبات الموجّهة للطالب: يمكن للفنيّين الآن طلب توضيح من فنيّين في وحدات تنظيمية أخرى.
- يمكن أن يستهدف التوضيح الطالب أو الطابور الحالي أو مالك الأب أو وحدة داخلية محددة حسب المستخدم أو DSD.
- التوضيح يُوقف اتفاقية مستوى الخدمة (SLA) فقط عندما يكون سبب الإيقاف مضبوطاً كموقف لـ SLA.
- صفوف التوضيح بين الفنيّين في `[Tickets].[TicketClarification]` تحمل كلاً من `RequestedFromDSDID_FK` و `RequestedFromUsersID_FK`، مما يجعل التنسيق بين الوحدات قابلاً للتتبّع.

### 7.7 نموذج أب-فرعي والمشاكل
- التذكرة الابن لها `ParentTicketID_FK` واحد وتستورد `RootTicketID_FK` من العقدة العليا.
- تذكرة المشكلة يمثّلها `ticketClassID_FK` وقد تعمل كسجل أب/جذر للحوادث المرتبطة.
- V2 تضيف حظر دمج-و (AND-join): عندما يُنتج الأب عدّة أبناء في آن واحد، يدخل الأب حالة `BLOCKED`.
- يبقى الأب `BLOCKED` حتى يصل كل ابن إلى حالة نهائية (تمّت التسوية، أُغلقت، أو أُلغيت).
- سبب الإيقاف `WAITING_CHILD` يتتبّع فترة الحظر في `[Tickets].[TicketPauseSession]`.
- حالة استخدام نموذجية: أمر صيانة يُنتج تذاكر أبناء متوازية للكهرباء والسباكة والدهان. لا يمكن إغلاق الأب حتى تكتمل التذاكر الثلاث.

### 7.8 نموذج اتفاقية مستوى الخدمة (SLA)
- الأولوية تُحدَّد عند الإنشاء ويمكن إعادة حسابها فقط بإجراء مخوَّل.
- مواعيد الاستجابة والتسوية مخزّنة في `[Tickets].[TicketSLA]`.
- الإيقافات تنشئ صفوفاً في `[Tickets].[TicketPauseSession]` بطوابع زمنية دقيقة للبدء والانتهاء.
- V2 تضيف `WAITING_APPROVAL` كسبب إيقاف صالح، لذا ساعات اتفاقية مستوى الخدمة (SLA) تتوقف أثناء خطوات الموافقة عند ضبطها.

### 7.9 نموذج مراجعة الجودة
- المنفذ يُسوّي التذكرة.
- المراجع في `TicketQualityReview` يقبلها أو يرفضها أو يعيدها.
- الإغلاق النهائي يحدث فقط بعد مراجعة جودة ناجحة أو بإجراء تجاوز مخوَّل صراحةً.
- مراجعة الجودة منفصلة عن الموافقة: بوابات الموافقة تحدث قبل أو أثناء التنفيذ، مراجعة الجودة تحدث بعد التسوية.

### 7.10 نموذج التقارير
- عرض الطابور: `TicketInbox`
- عرض الطالب: `TicketMyTickets`
- عرض المشرف: `TicketList`
- عرض المنفذ: `TicketWorkbench`
- عرض المراجع: `TicketQualityReview`
- عرض الموافقات: `TicketApprovals`
- لوحة معلومات الإدارة: `TicketReports`
- تقارير V2 تتضمن مقاييس خط أنابيب الموافقات: متوسط وقت الموافقة حسب الخطوة، معدلات الرفض، وتحديد الاختناقات.

### 7.11 نموذج النوع التشغيلي

يدعم النظام أربعة أنواع تذاكر تشغيلية، كل منها بسلوك متمايز:

| الرمز | الاسم بالعربية | الاسم بالإنجليزية | التوجيه النموذجي | سلسلة الموافقات النموذجية |
|---|---|---|---|---|
| `SERVICE_REQUEST` | طلب خدمة | Service Request | طابور الخدمة حسب قاعدة الدليل | فنّي -> مشرف |
| `DISBURSEMENT` | طلب صرف | Disbursement | قسم المالية | فنّي -> مشرف -> مدير فرع -> مدير قسم -> مدير إدارة |


| `EXECUTION` | طلب تنفيذ | Execution | العمليات/طابور الميداني حسب الخدمة | فني ← مشرف ← مدير فرع |
| `INSPECTION` | طلب معاينة | Inspection | طابور المعاينة الميدانية | فني ← مشرف |

يُحدَّد النوع التشغيلي عند إنشاء التذكرة بناءً على `operationalTypeID_FK` الخاص بالخدمة المختارة. ويؤثر النوع على:
- سلسلة الموافقات المطبّقة (عبر إعدادات `[Tickets].[ApprovalStep]`)
- هدف التوجيه الافتراضي حين لا تحدّد قاعدة توجيه الخدمة هدفاً بعينه
- اختيار سياسة اتفاقية مستوى الخدمة (SLA) (إذ يمكن أن تختلف الأنواع التشغيلية في توقعاتها للاتفاقية)
- سير العمل الإنجازي (طلب الصرف يتطلب تأكيداً مالياً، وطلب المعاينة يتطلب تقريراً ميدانياً)

جدول `OperationalType` هو جدول مرجعي يُزرع بأربعة صفوف بالضبط. ويحمل جدول `[Tickets].[Ticket]` العمود `operationalTypeID_FK` كمفتاح أجنبي مطلوب.

### 7.12 نموذج سلسلة الموافقات

تُخزَّن سلاسل الموافقات كبيانات وليس كمنطق مشفّر برمجياً. هذا يسمح بسلاسل مختلفة لأنواع تشغيلية وخدمات مختلفة من دون تغيير كود الإجراءات المخزّنة.

البنية:
- `[Tickets].[ApprovalStep]` يعرّف الخطوات المرتّبة في سلسلة موافقات. كل صف يحدّد `stepOrder`، و`approverRoleTypeID_FK` (فني، مشرف، مدير فرع، مدير قسم، مدير إدارة)، واختيارياً `ApproverDSDID_FK` أو `ApproverUsersID_FK` محدد.
- تُعرَّف السلسلة بمزيج من `operationalTypeID_FK` و`serviceID_FK`. حين يكون `serviceID_FK` فارغاً، تعمل السلسلة كخيار افتراضي لهذا النوع التشغيلي.
- `[Tickets].[TicketApproval]` يتتبّع التقدم. كل صف يسجّل أي خطوة، ومن وافق أو رفض، ومتى، وما الملاحظات.

سير العمل:
1. تُنشأ التذكرة. إن كان النوع التشغيلي يتطلب موافقة، يحمّل النظام السلسلة المطابقة من `[Tickets].[ApprovalStep]`.
2. يُبلَّغ المعتمد في الخطوة الأولى. تدخل التذكرة حالة `WAITING_APPROVAL`. تتوقف اتفاقية مستوى الخدمة (SLA) إن كان ذلك مضبوطاً.
3. يتخذ المعتمد إجراءً: موافقة، أو رفض، أو إرجاع.
4. عند الموافقة، ينتقل النظام إلى الخطوة التالية. إن كانت هذه آخر خطوة، تخرج التذكرة من سلسلة الموافقات وتنتقل إلى المرحلة التالية في دورة حياتها.
5. عند الرفض، تعود التذكرة إلى المرحلة السابقة مع تسجيل سبب الرفض. يمكن إعادة تشغيل سلسلة الموافقات لاحقاً إن سُمح بذلك.
6. كل إجراء موافقة يكتب في `[Tickets].[ApprovalStepHistory]` و`[dbo].[AuditLog]`.

تختلف السلسلة بحسب النوع التشغيلي والخدمة. فقد تحتاج طلبات الخدمة البسيطة إلى موافقة الفني والمشرف فقط. أما طلب الصرف لعنصر مرتفع القيمة فقد يحتاج سلسلة كاملة من خمس خطوات. تتيح صفحة الإعدادات `ApprovalStepConfig` للمسؤولين تعديل السلاسل وتعريفها من دون تدخّل المطورين.

### 7.13 نموذج التحكيم الهرمي

حين يتنازع وحدتان تنظيميتان حول ملكية تذكرة، يحلّ النظام النزاع على المستوى الهرمي الصحيح بدلاً من التوجيه إلى محكّم ثابت.

قواعد التصعيد:
- **قسم يتنازع مع قسم:** يجلس المحكّم على مستوى الفرع. معرّف الوحدة التنظيمية للمحكّم هو `DSDID` الفرع الأب.
- **فرع يتنازع مع فرع:** يجلس المحكّم على مستوى الإدارة. معرّف الوحدة التنظيمية للمحكّم هو `DSDID` الإدارة الأب.
- **إدارة تتنازع مع إدارة:** يجلس المحكّم على مستوى الإدارة العليا (الإدارة العامة). معرّف الوحدة التنظيمية للمحكّم هو `DSDID` الإدارة العليا نفسها.

التنفيذ:
- المحكّم هو سجلّ `Distributor` بنوع موزّع جديد مرتبط بـ `DSDID` للوحدة التنظيمية الأب. هذا أمر يتعلق بإعدادات تنظيمية وليس بتغيير في المخطط.
- حين يُطلَب التحكيم، يحدّد `[Tickets].[TicketSP]` مستوى التحكيم الصحيح بالبحث في الهيكل التنظيمي عن كل من الوحدة الطالبة والوحدة المستهدفة، ثم يختار الأب المشترك الأدنى.
- `[Tickets].[TicketArbitration]` يحمل بالفعل العمود `ArbitratorDSDID_FK`. في النسخة الثانية، يُملأ هذا الحقل بمعرّف الوحدة التنظيمية للمحكّم الهرمي بدلاً من قيمة ثابتة.
- قرار المحكّم يمكن أن يعيد تخصيص التذكرة لأي من الوحدتين المتنازعتين أو لوحدة ثالثة مختلفة تماماً.

يحلّ هذا النموذج محلّ نهج التحكيم المسطّح في النسخة الأولى حيث كان معرّف وحدة المحكّم يُؤخذ دائماً من قاعدة توجيه الخدمة. تعود النسخة الثانية إلى محكّم قاعدة التوجيه حين لا يكون هناك نزاع (مثلاً: توجيه خدمة غير معروف)، لكنها تستخدم الحل الهرمي حين يكون سبب التحكيم نزاعاً بين وحدات.

### 7.14 نموذج التوضيح بين الفنيين

التوضيح في النسخة الثانية لا يقتصر على "مقدم الطلب ينقصه بعض المعلومات". فالفنيون في وحدات تنظيمية مختلفة يمكنهم طلب المشورة من بعضهم عبر سير عمل رسمي قابل للتتبّع.

آلية العمل:
- فني يعمل على تذكرة في الوحدة التنظيمية (أ) يحتاج معلومات من فني في الوحدة التنظيمية (ب).
- ينشئ الفني طلب توضيح موجّه إلى `RequestedFromDSDID_FK = الوحدة-ب` واختيارياً `RequestedFromUsersID_FK = مستخدم-محدد`.
- تدخل التذكرة حالة `WAITING_CLARIFICATION`. تتوقف اتفاقية مستوى الخدمة (SLA) إن كان ذلك مضبوطاً.
- يعرض طابور الوحدة المستهدفة طلب التوضيح. يجيب الفني المستهدف.
- تُسجَّل الإجابة في `[Tickets].[TicketClarification` مع `respondedAt` و`responseText`.
- تستأنف التذكرة الأصلية مسارها.

الفروقات الجوهرية عن النسخة الأولى:
- توضيح النسخة الأولى كان موجّهاً لمقدم الطلب: يُسأل مقدم الطلب نفسه عن معلومات إضافية.
- توضيح النسخة الثانية متعدد الاتجاهات: يمكن أن يستهدف مقدم الطلب، أو وحدة أخرى، أو مستخدماً محدداً، أو صاحب التذكرة الأب.
- قيم `clarificationReasonID_FK` مُ扩展ة لتشمل أسباباً بين الوحدات مثل `CROSS_UNIT_QUERY` و`TECHNICAL_CONSULTATION` و`RESOURCE_AVAILABILITY_CHECK`.

يحافظ هذا النموذج على التواصل بين الوحدات داخل سجل المراجعة بدلاً من الاعتماد على مكالمات هاتفية أو تطبيقات مراسلة لا تترك أي سجلّ.

### 7.15 نموذج الأبناء المتوازيين

تُقدّم النسخة الثانية إنشاء أبناء متوازيين بشكل صريح مع دلالات دمج-و (AND-join).

آلية العمل:
1. تذكرة أب (مثلاً: أمر صيانة) تحتاج إلى مهام متعددة تُنجز بالتوازي.
2. ينشئ النظام عدة تذاكر أبناء في الوقت نفسه، كل منها يحمل `ParentTicketID_FK` يشير إلى التذكرة الأب.
3. كل ابن يحصل على توجيه وحدة تنظيمية خاص به، وتعيين، واتفاقية مستوى الخدمة (SLA)، ودورة حياة مستقلة.
4. تدخل التذكرة الأب حالة `BLOCKED` مع جلسة إيقاف `WAITING_CHILD`.
5. كلما وصل ابن إلى حالة نهائية (تمّ الحل، مُغلقة، ملغاة)، يتحقق النظام مما إذا كان جميع الأبناء قد وصلوا إلى حالة نهائية.
6. حين يصل آخر ابن إلى حالة نهائية، تُزال حالة `BLOCKED` من الأب، وتنتهي جلسة إيقاف `WAITING_CHILD`، ويستأنف الأب دورة حياته الطبيعية.

قيود التنفيذ:
- يدعم دمج-و (AND-join) فقط. الأب ينتظر جميع الأبناء، وليس أيّاً منهم.
- لا يمكن للأبناء إنشاء أبناء حاجزين في النسخة الثانية (لا حجب متكرّر). يمكن للابن أن يكون له أبناء فرعيون لأغراض التتبع، لكن الأب يحجب فقط على أبنائه المباشرين.
- الابن الملغى يُحسب "مُنجَزاً" لأغراض دمج-و (AND-join). لا يبقى الأب محجوباً لأن ابنًا أُلغي.
- اتفاقية مستوى الخدمة (SLA) الخاصة بالأب تتراكم فيها أوقات الإيقاف أثناء فترة الحجب، فلا تُستهلك اتفاقية مستوى الخدمة (SLA) بشكل غير عادل أثناء تنفيذ الأبناء.

حالات الاستخدام:
- صيانة المبنى: الأب هو أمر العمل، والأبناء هم: كهرباء، سباكة، دهان، تكييف.
- تحضير الفعاليات: الأب هو طلب الفعالية، والأبناء هم: تجهيز الموقع، التموين، الأمن، تجهيز تقنية المعلومات.
- معاينة متعددة المواقع: الأب هو حملة المعاينة، والأبناء هم المعاينات الفردية لكل موقع.

## 8. قرارات هندسة البيانات

### 8.1 قرار المخطط
جميع كائنات الأعمال الجديدة لهذا النظام تُنشأ تحت `[Tickets]` فقط.

### 8.2 هوية المستخدمين والهيكل التنظيمي الحالي
- هوية المستخدم: `[dbo].[Users]` و`[dbo].[UsersDetails]`
- هوية الساكن: `[Housing].[ResidentInfo]` و`[Housing].[ResidentDetails]`
- الحقيقة التنظيمية: `[dbo].[DeptSecDiv]`
- حقيقة التكليف التنظيمي: `[dbo].[Distributor]` و`[dbo].[UserDistributor]`

### 8.3 اصطلاحات المفاتيح الأجنبية
- مفتاح المستخدم الأجنبي: `UsersID_FK`
- مفتاح الإدارة الأجنبية: `IdaraID_FK`
- مفتاح الوحدة التنظيمية الأجنبي: `DSDID_FK`
- مفتاح التذكرة الأب الأجنبي: `ParentTicketID_FK`
- مفتاح التذكرة الجذر الأجنبي: `RootTicketID_FK`
- مفتاح النوع التشغيلي الأجنبي: `operationalTypeID_FK`
- مفتاح خطوة الموافقة الأجنبي: `approvalStepID_FK`

### 8.4 أعمدة المراجعة
كل جدول تحت `[Tickets]` يتضمن بالضبط:

```sql
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```

### 8.5 قرار حقيقة التوجيه
- `CurrentDSDID_FK` في `[Tickets].[Ticket]` هو العقدة التنظيمية المسؤولة الحالية.
- `TargetDSDID_FK` في `[Tickets].[ServiceRoutingRule]` هو عقدة التوجيه الافتراضية لاستقبال الكتالوج.
- أي مستوى توجيه نصي هو غرض وصفي فقط ولا يحلّ أبداً محلّ مفاتيح الوحدة التنظيمية.

### 8.6 حقيقة الصفحات والإجراءات
- طبقة التطبيق لا تزال تربط فقط إدخالات البوابات في `ProcedureMapper`.
- `MastersServies.GetDataLoadDataSetAsync(...)` و`GetCrudDataSetAsync(...)` يبقيان مسار الوصول إلى البيانات الوحيد في طبقة التطبيق لصفحات واجهة المستخدم في هذا التصميم.

### 8.7 قرار الحذف الناعم
- جداول مرجعية، وجداول رئيسية، وجداول معاملات طويلة العمر تستخدم أعلام التفعيل حيثما يكون ذلك مناسباً.
- جداول تاريخية هي للإلحاق فقط ولا تُحذف أبداً حذفاً ناعماً.

### 8.8 فصل مخطط الدعم
`[support].[Ticket]` والكائنات المرتبطة تحت `[support]` تبقى حلاً منفصلاً لتتبّع أعطال الموقع الداخلي لفريق التطوير. هي ليست جزءاً من تصميم تذاكر ITIL 4 ولا تُعاد استخدامها هنا.

### 8.9 قرار OperationalType
- `[Tickets].[OperationalType]` هو جدول مرجعي بأربعة صفوف مزروعة بالضبط: `SERVICE_REQUEST`، `DISBURSEMENT`، `EXECUTION`، `INSPECTION`.
- `[Tickets].[Ticket]` يضيف العمود `operationalTypeID_FK INT NOT NULL` يشير إلى هذا الجدول.
- `[Tickets].[Service]` يضيف العمود `operationalTypeID_FK INT NOT NULL` بحيث أن اختيار خدمة يحدّد النوع التشغيلي تلقائياً.
- النوع التشغيلي غير قابل للتغيير بعد إنشاء التذكرة. لا يمكن تغييره لاحقاً.
- كل نوع تشغيلي يمكن أن يكون له سلاسل موافقات افتراضية مختلفة، وقواعد توجيه مختلفة، وسياسات اتفاقية مستوى الخدمة (SLA) مختلفة.

### 8.10 قرار ApprovalStep
- `[Tickets].[ApprovalStep]` هو جدول رئيسي يخزّن سلاسل الموافقات المرتّبة.
- تُعرَّف السلسلة بـ `operationalTypeID_FK` واختيارياً `serviceID_FK`. حين يكون `serviceID_FK` فارغاً، تكون السلسلة هي الخيار الافتراضي لهذا النوع التشغيلي.
- كل صف يحمل `stepOrder INT NOT NULL` يحدّد الترتيب.
- كل صف يحمل `approverRoleTypeID_FK INT NOT NULL` يحدّد الدور (فني، مشرف، مدير فرع، مدير قسم، مدير إدارة).
- كل صف يحمل اختيارياً `ApproverDSDID_FK BIGINT NULL` أو `ApproverUsersID_FK BIGINT NULL` لربط الخطوة بوحدة تنظيمية محددة أو شخص محدد.
- التغييرات في خطوات الموافقة تُكتب في `[Tickets].[ApprovalStepHistory]`.

### 8.11 قرار TicketApproval
- `[Tickets].[TicketApproval]` هو جدول معاملات بصف واحد لكل إجراء موافقة لكل خطوة لكل تذكرة.
- كل صف يحمل `approvalStepID_FK`، و`TicketID_FK`، و`ApproverUsersID_FK`، و`approvalDecision` (موافقة، رفض، إرجاع)، و`approvalNotes`، وطوابع زمنية.
- التذكرة في حالة `WAITING_APPROVAL` لها خطوة معلقة واحدة بالضبط في كل مرة. الخطوات السابقة مُسجّلة كصفوف موافقة.
- الرفض في أي خطوة يُسجَّل مع سبب الرفض. تعود التذكرة إلى المرحلة السابقة في دورة حياتها.
- إجراءات الموافقة تكتب في السجلّ المحلي و`[dbo].[AuditLog]` المركزي.

### 8.12 قرار بيانات التحكيم الهرمي
- لا حاجة لجدول جديد للتحكيم الهرمي. جدول `[Tickets].[TicketArbitration]` يحمل بالفعل العمود `ArbitratorDSDID_FK`.
- في النسخة الثانية، تُحسب قيمة `ArbitratorDSDID_FK` أثناء التشغيل بحلّ الأب المشترك الأدنى في الهيكل التنظيمي بين الوحدتين المتنازعتين.
- نوع المحكّم `Distributor` هو تصنيف موزّع جديد مرتبط بـ `DSDID` للوحدة التنظيمية الأب. هذا تغيير إعدادات بيانات في `[dbo].[Distributor]`، وليس تغييراً في المخطط.

### 8.13 قرار بيانات أبناء دمج-و (AND-join)
- لا حاجة لجدول جديد لنموذج دمج-و (AND-join). العمود `ParentTicketID_FK` الموجود في `[Tickets].[Ticket]` يدعم بالفعل علاقات أب-فرعي.
- النسخة الثانية تضيف `BLOCKED` إلى صفوف `TicketStatus` المزروعة لتمثيل حالة انتظار الأب.
- النسخة الثانية تضيف `WAITING_CHILD` إلى صفوف `PauseReason` المزروعة مع `pausesSLA = 1`.
- فحص دمج-و (AND-join) يُفرض في `[Tickets].[TicketSP]`: حين يصل ابن إلى حالة نهائية، يحسب الإجراء عدد الأبناء النشطين المتبقين. إن كان صفراً، يُزال الحجب عن الأب.

### 8.14 قرار بيانات التوضيح بين الفنيين
- جدول `[Tickets].[TicketClarification]` الموجود يحمل بالفعل `RequestedFromDSDID_FK` و`RequestedFromUsersID_FK`، وهي بالضبط الأعمدة اللازمة للتوضيح بين الفنيين.
- النسخة الثانية توسّع صفوف `ClarificationReason` المزروعة لتشمل أسباباً بين الوحدات.
- لا حاجة لتغيير في المخطط. نموذج التوضيح يدعم بالفعل سير العمل متعدد الاتجاهات؛ النسخة الأولى ببساطة لم تملأ الحقول بين الوحدات.

## 9. الاعتماديات الخارجية

يفترض مخطط `[Tickets]` أن هذه الكائنات الموجودة قائمة وتبقى المرجع المعتمد:

| الكائن | الغرض في التذاكر |
|---|---|
| `[dbo].[Idara]` | أب `IdaraID_FK` مطلوب |
| `[dbo].[Department]` | مرجع تنظيمي للتقارير والعرض المشتق والتحكيم الهرمي |
| `[dbo].[Section]` | مرجع تنظيمي للتقارير والعرض المشتق والتحكيم الهرمي |
| `[dbo].[Divison]` | مرجع تنظيمي للتقارير والعرض المشتق |
| `[dbo].[DeptSecDiv]` | حقيقة التوجيه عبر `DSDID_FK`، الهيكل التنظيمي لحل التحكيم |
| `[dbo].[Users]` | أب مقدم الطلب الداخلي والمكلّف والمعتمد |
| `[dbo].[UsersDetails]` | اسم العرض وبيانات الموظف |
| `[dbo].[Distributor]` | مستلم الطابور/الدور، نوع المحكّم للتحكيم الهرمي |
| `[dbo].[UserDistributor]` | يتحقق من المستخدمين الذين يمكنهم العمل في نطاق طابور معين |
| `[dbo].[Permission]` | بنية الصلاحيات الموجودة |
| `[dbo].[PermissionType]` | بنية أنواع الصلاحيات الموجودة |
| `[Housing].[ResidentInfo]` | أب مقدم الطلب من السكان |
| `[Housing].[ResidentDetails]` | عرض بيانات السكان والبيانات المحددة بنطاق الإدارة العامة |
| `[dbo].[AuditLog]` | مراجعة الكتابة المركزية |
| `[dbo].[ErrorLog]` | تسجيل أخطاء SQL غير المتوقعة |
| `[dbo].[Notifications]` | سجلات الإشعارات المخزّنة |
| `[dbo].[UserNotifications]` | سجلات إشعارات المستلمين |
| `[dbo].[Notifications_Create]` | إجراء إرسال الإشعارات الموجود |
| `[dbo].[ft_UserPagePermissions]` | مجموعة نتائج صلاحيات القراءة لتحميل الصفحات |
| `[dbo].[V_GetListUserPermission]` | التحقق من صلاحيات عمليات CRUD |
| `[dbo].[V_GetListUsersInDSD]` | المستخدمون المؤهلون النشطون حسب الوحدة التنظيمية، يُستخدمون للتكليف وأهلية الموافقة |
| `[dbo].[V_GetFullStructureForDSD]` | عرض الهيكل التنظيمي، التقارير، وحل مستوى التحكيم الهرمي |


## 10. مجموعة جداول النسخة الأولى

### 10.1 جداول مرجعية
- `[Tickets].[RequesterType]`
- `[Tickets].[TicketClass]`
- `[Tickets].[TicketStatus]`
- `[Tickets].[TicketImpact]`
- `[Tickets].[TicketUrgency]`
- `[Tickets].[TicketPriority]`
- `[Tickets].[ResolutionType]`
- `[Tickets].[PauseReason]`
- `[Tickets].[ArbitrationReason]`
- `[Tickets].[ClarificationReason]`
- `[Tickets].[QualityReviewResult]`
- `[Tickets].[OperationalType]`

### 10.2 جداول رئيسية
- `[Tickets].[ServiceCategory]`
- `[Tickets].[Service]`
- `[Tickets].[ServiceRoutingRule]`
- `[Tickets].[ServiceSLAPolicy]`
- `[Tickets].[PriorityMatrix]`
- `[Tickets].[ApprovalStep]`

### 10.3 جداول معاملات
- `[Tickets].[Ticket]`
- `[Tickets].[TicketArbitration]`
- `[Tickets].[TicketClarification]`
- `[Tickets].[TicketPauseSession]`
- `[Tickets].[TicketSLA]`
- `[Tickets].[TicketQualityReview]`
- `[Tickets].[ServiceCatalogSuggestion]`
- `[Tickets].[TicketApproval]`

### 10.4 جداول تاريخية
- `[Tickets].[TicketHistory]`
- `[Tickets].[TicketSLAHistory]`
- `[Tickets].[ServiceRoutingRuleHistory]`

## 11. قرارات DDL جدولاً بجدول


### 11.1 `[Tickets].[RequesterType]`
```sql
requesterTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
requesterTypeCode NVARCHAR(50) NOT NULL
requesterTypeName_A NVARCHAR(200) NOT NULL
requesterTypeName_E NVARCHAR(200) NOT NULL
requesterTypeDescription NVARCHAR(1000) NULL
requesterTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, requesterTypeCode)`
- صفوف أولية: `INTERNAL_USER`, `RESIDENT`

### 11.2 `[Tickets].[TicketClass]`
```sql
ticketClassID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketClassCode NVARCHAR(50) NOT NULL
ticketClassName_A NVARCHAR(200) NOT NULL
ticketClassName_E NVARCHAR(200) NOT NULL
ticketClassDescription NVARCHAR(1000) NULL
ticketClassActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, ticketClassCode)`
- صفوف أولية: `INCIDENT`, `SERVICE_REQUEST`, `PROBLEM`

### 11.3 `[Tickets].[TicketStatus]`
```sql
ticketStatusID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketStatusCode NVARCHAR(50) NOT NULL
ticketStatusName_A NVARCHAR(200) NOT NULL
ticketStatusName_E NVARCHAR(200) NOT NULL
sortOrder INT NOT NULL
isClosedStatus BIT NOT NULL
isPauseStatus BIT NOT NULL
ticketStatusActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, ticketStatusCode)`
- صفوف أولية: `NEW`, `TRIAGED`, `ASSIGNED`, `IN_PROGRESS`, `WAITING_ARBITRATION`, `WAITING_CLARIFICATION`, `WAITING_CHILD`, `RESOLVED`, `QUALITY_REVIEW`, `CLOSED`, `CANCELLED`, `REJECTED_BY_QUALITY`

### 11.4 `[Tickets].[TicketImpact]`
```sql
impactID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
impactCode NVARCHAR(50) NOT NULL
impactName_A NVARCHAR(200) NOT NULL
impactName_E NVARCHAR(200) NOT NULL
impactScore INT NOT NULL
impactDescription NVARCHAR(1000) NULL
impactActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, impactCode)`
- صفوف أولية: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

### 11.5 `[Tickets].[TicketUrgency]`
```sql
urgencyID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
urgencyCode NVARCHAR(50) NOT NULL
urgencyName_A NVARCHAR(200) NOT NULL
urgencyName_E NVARCHAR(200) NOT NULL
urgencyScore INT NOT NULL
urgencyDescription NVARCHAR(1000) NULL
urgencyActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, urgencyCode)`
- صفوف أولية: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

### 11.6 `[Tickets].[TicketPriority]`
```sql
ticketPriorityID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketPriorityCode NVARCHAR(50) NOT NULL
ticketPriorityName_A NVARCHAR(200) NOT NULL
ticketPriorityName_E NVARCHAR(200) NOT NULL
sortOrder INT NOT NULL
ticketPriorityColor NVARCHAR(30) NULL
ticketPriorityActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, ticketPriorityCode)`
- صفوف أولية: `P1`, `P2`, `P3`, `P4`

### 11.7 `[Tickets].[ResolutionType]`
```sql
resolutionTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
resolutionTypeCode NVARCHAR(50) NOT NULL
resolutionTypeName_A NVARCHAR(200) NOT NULL
resolutionTypeName_E NVARCHAR(200) NOT NULL
resolutionTypeDescription NVARCHAR(1000) NULL
resolutionTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, resolutionTypeCode)`
- صفوف أولية: `FIXED`, `WORKAROUND`, `KNOWN_ERROR`, `NOT_REPRODUCIBLE`, `DUPLICATE`

### 11.8 `[Tickets].[PauseReason]`
```sql
pauseReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
pauseReasonCode NVARCHAR(50) NOT NULL
pauseReasonName_A NVARCHAR(200) NOT NULL
pauseReasonName_E NVARCHAR(200) NOT NULL
pausesSLA BIT NOT NULL
pauseReasonDescription NVARCHAR(1000) NULL
pauseReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, pauseReasonCode)`
- صفوف أولية: `ARBITRATION`, `CLARIFICATION`, `WAITING_CHILD`, `WAITING_APPROVAL`, `EXTERNAL_DEPENDENCY`

### 11.9 `[Tickets].[ArbitrationReason]`
```sql
arbitrationReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
arbitrationReasonCode NVARCHAR(50) NOT NULL
arbitrationReasonName_A NVARCHAR(200) NOT NULL
arbitrationReasonName_E NVARCHAR(200) NOT NULL
arbitrationReasonDescription NVARCHAR(1000) NULL
arbitrationReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, arbitrationReasonCode)`
- صفوف أولية: `UNKNOWN_SERVICE`, `WRONG_SCOPE`, `CROSS_DEPARTMENT`, `MANAGER_DECISION_REQUIRED`

### 11.10 `[Tickets].[ClarificationReason]`
```sql
clarificationReasonID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
clarificationReasonCode NVARCHAR(50) NOT NULL
clarificationReasonName_A NVARCHAR(200) NOT NULL
clarificationReasonName_E NVARCHAR(200) NOT NULL
clarificationReasonDescription NVARCHAR(1000) NULL
clarificationReasonActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, clarificationReasonCode)`
- صفوف أولية: `MISSING_DETAILS`, `MISSING_APPROVAL`, `MISSING_DOCUMENT`, `NEED_PARENT_INPUT`

### 11.11 `[Tickets].[QualityReviewResult]`
```sql
qualityReviewResultID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
qualityReviewResultCode NVARCHAR(50) NOT NULL
qualityReviewResultName_A NVARCHAR(200) NOT NULL
qualityReviewResultName_E NVARCHAR(200) NOT NULL
qualityReviewResultDescription NVARCHAR(1000) NULL
qualityReviewResultActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, qualityReviewResultCode)`
- صفوف أولية: `APPROVED`, `RETURNED`, `REJECTED`

### 11.12 `[Tickets].[OperationalType]`
```sql
operationalTypeID INT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
operationalTypeCode NVARCHAR(50) NOT NULL
operationalTypeName_A NVARCHAR(200) NOT NULL
operationalTypeName_E NVARCHAR(200) NOT NULL
operationalTypeDescription NVARCHAR(1000) NULL
operationalTypeActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, operationalTypeCode)`
- صفوف أولية: `SERVICE_REQUEST`, `DISBURSEMENT`, `EXECUTION`, `INSPECTION`
- يُصنّف الطبيعة التشغيلية لسير العمل المرفق بالتذكرة
- يُستخدم من قبل `[Tickets].[ApprovalStep]` لتحديد قالب سلسلة الموافقات المناسب

### 11.13 `[Tickets].[ServiceCategory]`
```sql
serviceCategoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceCategoryCode NVARCHAR(50) NOT NULL
serviceCategoryName_A NVARCHAR(200) NOT NULL
serviceCategoryName_E NVARCHAR(200) NOT NULL
serviceCategoryDescription NVARCHAR(1000) NULL
sortOrder INT NOT NULL
serviceCategoryActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, serviceCategoryCode)`

### 11.14 `[Tickets].[Service]`
```sql
serviceID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceCategoryID_FK BIGINT NOT NULL FK -> [Tickets].[ServiceCategory].[serviceCategoryID]
ticketClassID_FK INT NOT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
defaultImpactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
defaultUrgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
defaultPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
serviceCode NVARCHAR(50) NOT NULL
serviceName_A NVARCHAR(200) NOT NULL
serviceName_E NVARCHAR(200) NOT NULL
serviceDescription NVARCHAR(MAX) NULL
allowResidentRequest BIT NOT NULL
```


allowInternalRequest BIT NOT NULL
requiresQualityReview BIT NOT NULL
allowChildTickets BIT NOT NULL
isOtherPlaceholder BIT NOT NULL
serviceActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, serviceCode)`
- `isOtherPlaceholder = 0` للخدمات الفعلية؛ واجهة المستخدم تتعامل مع "أخرى" كقيمة `serviceID_FK` فارغة

### 11.15 `[Tickets].[ServiceRoutingRule]`
```sql
serviceRoutingRuleID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
requesterTypeID_FK INT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
TargetDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
TargetDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
ArbitratorDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ArbitratorDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
rulePriority INT NOT NULL
effectiveFrom DATETIME NOT NULL
effectiveTo DATETIME NULL
serviceRoutingRuleActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- تصمية فريدة مُصفّاة مستهدفة: صف فعّال واحد فقط لكل مجموعة `(IdaraID_FK, serviceID_FK, requesterTypeID_FK)` ونافذة زمنية
- `TargetDSDID_FK` هو المرجع الحقيقي للتوجيه
- `ArbitratorDSDID_FK` إلزامي حتى يكون لحالات النطاق الخاطئ والخدمات الأخرى وجهة صالحة دائماً

### 11.16 `[Tickets].[ServiceSLAPolicy]`
```sql
serviceSLAPolicyID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
responseTargetMinutes INT NOT NULL
resolutionTargetMinutes INT NOT NULL
allowPause BIT NOT NULL
requiresMajorIncidentReview BIT NOT NULL
effectiveFrom DATETIME NOT NULL
effectiveTo DATETIME NULL
serviceSLAPolicyActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- هدف السياسة الفعّالة الفريدة: `(IdaraID_FK, serviceID_FK, ticketPriorityID_FK)`

### 11.17 `[Tickets].[PriorityMatrix]`
```sql
priorityMatrixID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
impactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
urgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
isMajorIncidentDefault BIT NOT NULL
priorityMatrixActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, impactID_FK, urgencyID_FK)`
- هذا هو المصدر الإلزامي لترتيب الأولويات وفق منهجية ITIL

### 11.18 `[Tickets].[ApprovalStep]`
```sql
approvalStepID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
operationalTypeID_FK INT NOT NULL FK -> [Tickets].[OperationalType].[operationalTypeID]
serviceID_FK BIGINT NULL FK -> [Tickets].[Service].[serviceID]
stepOrder INT NOT NULL
stepName_A NVARCHAR(200) NOT NULL
stepName_E NVARCHAR(200) NOT NULL
ApproverDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ApproverDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
isRequired BIT NOT NULL DEFAULT 1
approvalStepActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)`
- عندما يكون `serviceID_FK` فارغاً، تُطبَّق الخطوة على جميع الخدمات التابعة لذلك النوع التشغيلي
- `ApproverDSDID_FK` يُحدِّد الوحدة التنظيمية المطلوب موافقتها في هذه الخطوة
- `ApproverDistributorID_FK` يُضيِّق الاختيار اختيارياً إلى دور محدد داخل تلك الوحدة
- `isRequired = 0` يُميِّز الخطوات الاستشارية أو الاختيارية التي يمكن تخطيها أثناء تنفيذ سير العمل
- مجتمعةً، تُشكِّل الصفوف المرتّبة حسب `stepOrder` لمجموعة `(operationalTypeID_FK, serviceID_FK)` معينة قالب سلسلة الموافقات الكامل

### 11.19 `[Tickets].[Ticket]`
```sql
ticketID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
ticketNo NVARCHAR(30) NOT NULL
ticketClassID_FK INT NOT NULL FK -> [Tickets].[TicketClass].[ticketClassID]
operationalTypeID_FK INT NOT NULL FK -> [Tickets].[OperationalType].[operationalTypeID]
ticketStatusID_FK INT NOT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
requesterTypeID_FK INT NOT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
serviceID_FK BIGINT NULL FK -> [Tickets].[Service].[serviceID]
UsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
residentInfoID_FK BIGINT NULL FK -> [Housing].[ResidentInfo].[residentInfoID]
OpenedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
CurrentDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
CurrentDistributorID_FK BIGINT NULL FK -> [dbo].[Distributor].[distributorID]
AssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
impactID_FK INT NOT NULL FK -> [Tickets].[TicketImpact].[impactID]
urgencyID_FK INT NOT NULL FK -> [Tickets].[TicketUrgency].[urgencyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
resolutionTypeID_FK INT NULL FK -> [Tickets].[ResolutionType].[resolutionTypeID]
ParentTicketID_FK BIGINT NULL FK -> [Tickets].[Ticket].[ticketID]
RootTicketID_FK BIGINT NULL FK -> [Tickets].[Ticket].[ticketID]
ticketTitle NVARCHAR(500) NOT NULL
ticketDescription NVARCHAR(MAX) NOT NULL
otherServiceText NVARCHAR(500) NULL
resolutionNotes NVARCHAR(MAX) NULL
isMajorIncident BIT NOT NULL
openedAt DATETIME NOT NULL
firstRespondedAt DATETIME NULL
resolvedAt DATETIME NULL
closedAt DATETIME NULL
lastStatusChangedAt DATETIME NOT NULL
ticketActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- فريد: `(IdaraID_FK, ticketNo)`
- قاعدة تحقق في الإجراء المخزن: يجب تعبئة حقل واحد بالضبط من `UsersID_FK` أو `residentInfoID_FK`
- قاعدة تحقق في الإجراء المخزن: يجب تعبئة `serviceID_FK` أو `otherServiceText`
- `RootTicketID_FK` يساوي نفس التذكرة للسجلات الجذرية بعد إتمام الإدراج
- `operationalTypeID_FK` مطلوب ويُحدِّد قالب سلسلة الموافقات الذي يتم تفعيله لهذه التذكرة

### 11.20 `[Tickets].[TicketArbitration]`
```sql
ticketArbitrationID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
arbitrationReasonID_FK INT NOT NULL FK -> [Tickets].[ArbitrationReason].[arbitrationReasonID]
RequestedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
RequestedFromDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
ArbitratorDSDID_FK BIGINT NOT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
DecisionByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
DecisionTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
decisionNotes NVARCHAR(MAX) NULL
requestedAt DATETIME NOT NULL
decidedAt DATETIME NULL
ticketArbitrationActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف تحكيم فعّال واحد فقط لكل تذكرة في الوقت الواحد
- منطق الإغلاق موجود في `[Tickets].[TicketSP]`

### 11.21 `[Tickets].[TicketClarification]`
```sql
ticketClarificationID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
clarificationReasonID_FK INT NOT NULL FK -> [Tickets].[ClarificationReason].[clarificationReasonID]
RequestedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
RequestedFromUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
RequestedFromDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
requestText NVARCHAR(MAX) NOT NULL
responseText NVARCHAR(MAX) NULL
respondedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
requestedAt DATETIME NOT NULL
respondedAt DATETIME NULL
ticketClarificationActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف توضيح فعّال واحد فقط لكل تذكرة في الوقت الواحد
- يجب تعبئة حقل واحد على الأقل من `RequestedFromUsersID_FK` أو `RequestedFromDSDID_FK`

### 11.22 `[Tickets].[TicketPauseSession]`
```sql
ticketPauseSessionID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
pauseReasonID_FK INT NOT NULL FK -> [Tickets].[PauseReason].[pauseReasonID]
StartedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
EndedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
pauseNotes NVARCHAR(MAX) NULL
startedAt DATETIME NOT NULL
endedAt DATETIME NULL
pausedMinutes INT NULL
ticketPauseSessionActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- جلسة إيقاف فعّالة واحدة فقط لكل تذكرة في الوقت الواحد
- يتم حساب `pausedMinutes` النهائي عند انتهاء الجلسة

### 11.23 `[Tickets].[TicketSLA]`
```sql
ticketSLAID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
serviceSLAPolicyID_FK BIGINT NULL FK -> [Tickets].[ServiceSLAPolicy].[serviceSLAPolicyID]
ticketPriorityID_FK INT NOT NULL FK -> [Tickets].[TicketPriority].[ticketPriorityID]
responseTargetMinutes INT NOT NULL
resolutionTargetMinutes INT NOT NULL
responseDueAt DATETIME NOT NULL
resolutionDueAt DATETIME NOT NULL
totalPausedMinutes INT NOT NULL
responseBreached BIT NOT NULL
resolutionBreached BIT NOT NULL
slaState NVARCHAR(50) NOT NULL
ticketSLAActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف اتفاقية مستوى الخدمة (SLA) فعّال واحد لكل تذكرة
- قيم `slaState` يتحكم بها منطق الإجراء المخزن: `RUNNING`، `PAUSED`، `RESOLVED`، `CLOSED`، `BREACHED`

### 11.24 `[Tickets].[TicketQualityReview]`
```sql
ticketQualityReviewID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
qualityReviewResultID_FK INT NULL FK -> [Tickets].[QualityReviewResult].[qualityReviewResultID]
ReviewerUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
reviewNotes NVARCHAR(MAX) NULL
reviewStartedAt DATETIME NOT NULL
reviewCompletedAt DATETIME NULL

ticketQualityReviewActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف مراجعة جودة نشط واحد فقط لكل تذكرة
- تبدأ المراجعة عندما تدخل التذكرة حالة `QUALITY_REVIEW`

### 11.25 `[Tickets].[ServiceCatalogSuggestion]`
```sql
serviceCatalogSuggestionID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
requesterTypeID_FK INT NOT NULL FK -> [Tickets].[RequesterType].[requesterTypeID]
proposedServiceName NVARCHAR(200) NOT NULL
proposedCategoryName NVARCHAR(200) NULL
proposedTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
reviewedByUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
reviewDecision NVARCHAR(50) NULL
reviewNotes NVARCHAR(MAX) NULL
reviewedAt DATETIME NULL
serviceCatalogSuggestionActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- يمكن للتذكرة إنشاء صفر أو اقتراح نشط واحد
- يتحكم الإجراء المخزن في قيم `reviewDecision` مثل `PENDING`، و`ACCEPTED`، و`REJECTED`، و`MERGED`

### 11.26 `[Tickets].[TicketApproval]`
```sql
ticketApprovalID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
approvalStepID_FK BIGINT NOT NULL FK -> [Tickets].[ApprovalStep].[approvalStepID]
stepOrder INT NOT NULL
ApproverUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
approvalStatus NVARCHAR(50) NOT NULL
approvalNotes NVARCHAR(MAX) NULL
requestedAt DATETIME NOT NULL
decidedAt DATETIME NULL
ticketApprovalActive BIT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- صف واحد لكل خطوة موافقة لكل تذكرة
- القيم المحددة لـ `approvalStatus`: `PENDING`، و`APPROVED`، و`REJECTED`، و`SKIPPED`
- يُملأ `ApproverUsersID_FK` عندما يتصرّف مستخدم محدد من وحدة `ApproverDSDID_FK` على الخطوة
- حالة `SKIPPED` صالحة فقط للخطوات التي يكون فيها `[Tickets].[ApprovalStep].isRequired = 0` المقابل
- تُنشأ سلسلة الموافقات من `[Tickets].[ApprovalStep]` عند إنشاء التذكرة، مع مطابقة `operationalTypeID_FK` الخاصة بالتذكرة، واختيارياً `serviceID_FK`
- يجب أن تصل جميع الخطوات إلى حالة `APPROVED` أو `SKIPPED` قبل أن تتمكن التذكرة من تجاوز مرحلة الموافقة

### 11.27 `[Tickets].[TicketHistory]`
```sql
ticketHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
historyActionCode NVARCHAR(100) NOT NULL
oldTicketStatusID_FK INT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
newTicketStatusID_FK INT NULL FK -> [Tickets].[TicketStatus].[ticketStatusID]
oldDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
oldAssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
newAssignedToUsersID_FK BIGINT NULL FK -> [dbo].[Users].[usersID]
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
historyNotes NVARCHAR(MAX) NULL
performedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إلحاقي فقط (لا تعديل ولا حذف)
- يُستخدم لعرض الخط الزمني على `TicketWorkbench`

### 11.28 `[Tickets].[TicketSLAHistory]`
```sql
ticketSLAHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
TicketID_FK BIGINT NOT NULL FK -> [Tickets].[Ticket].[ticketID]
TicketSLAID_FK BIGINT NOT NULL FK -> [Tickets].[TicketSLA].[ticketSLAID]
slaActionCode NVARCHAR(100) NOT NULL
oldSlaState NVARCHAR(50) NULL
newSlaState NVARCHAR(50) NULL
responseDueAt DATETIME NULL
resolutionDueAt DATETIME NULL
totalPausedMinutes INT NULL
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
performedAt DATETIME NOT NULL
historyNotes NVARCHAR(MAX) NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إلحاقي فقط (لا تعديل ولا حذف)

### 11.29 `[Tickets].[ServiceRoutingRuleHistory]`
```sql
serviceRoutingRuleHistoryID BIGINT IDENTITY(1,1) NOT NULL PK
IdaraID_FK BIGINT NOT NULL FK -> [dbo].[Idara].[idaraID]
serviceRoutingRuleID_FK BIGINT NOT NULL FK -> [Tickets].[ServiceRoutingRule].[serviceRoutingRuleID]
serviceID_FK BIGINT NOT NULL FK -> [Tickets].[Service].[serviceID]
historyActionCode NVARCHAR(100) NOT NULL
oldTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newTargetDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
oldArbitratorDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
newArbitratorDSDID_FK BIGINT NULL FK -> [dbo].[DeptSecDiv].[DSDID]
performedByUsersID_FK BIGINT NOT NULL FK -> [dbo].[Users].[usersID]
historyNotes NVARCHAR(MAX) NULL
performedAt DATETIME NOT NULL
entryDate DATETIME NULL
entryData NVARCHAR(20) NULL
hostName NVARCHAR(200) NULL
```
القيود والملاحظات:
- إلحاقي فقط (لا تعديل ولا حذف)
- سجل تدقيق محلي لتغييرات التوجيه


> تحل هذه الأقسام محل الأقسام 12-15 من الخطة الأساسية. العناصر الجديدة والمُعدّلة مُعلّمة بـ **[v2]**.

## 12. خريطة الإجراءات المخزنة

### 12.1 `[Tickets].[TicketDL]`

الغرض:
- تحميل بيانات الصفحات `TicketCreate`، و`TicketMyTickets`، و`TicketInbox`، و`TicketList`، و`TicketWorkbench`، و`TicketQualityReview`، و**[v2]** `TicketApprovals`

نمط التوقيع:
```sql
CREATE PROCEDURE [Tickets].[TicketDL]
    @pageName_ NVARCHAR(400)
  , @idaraID INT
  , @entrydata INT
  , @hostname NVARCHAR(400)
  , @parameter_01 NVARCHAR(400) = NULL
  , @parameter_02 NVARCHAR(400) = NULL
  , @parameter_03 NVARCHAR(400) = NULL
```

قواعد مجموعات النتائج:
- مجموعة النتائج 0 تأتي من `[dbo].[Masters_DataLoad]` عبر `[dbo].[ft_UserPagePermissions]`
- مجموعة النتائج 1 هي دائماً بيانات الصفحة الرئيسية
- مجموعة النتائج 2 فما فوق هي مجموعات بيانات البحث لنماذج وفلاتر `SmartRenderer`

**[v2]** عندما يكون `@pageName_ = 'TicketWorkbench'`، تُرجع مجموعات نتائج إضافية حالة سلسلة الموافقات للتذكرة المعروضة. راجع القسم 13.5 لخريطة مجموعات النتائج الكاملة.

### 12.2 `[Tickets].[TicketSP]`

الغرض:
- جميع عمليات الكتابة لدورة حياة التذكرة بما في ذلك **[v2]** إجراءات سير عمل الموافقة

مجموعات الإجراءات:
- `INSERTTICKET` **[v2]** مُحدّث: يتحقق من صحة `operationalTypeID_FK`، ويحمّل سلسلة الموافقات من `[Tickets].[ApprovalStep]` إذا كان النوع التشغيلي يتطلب موافقة، وينشئ صفوف `[Tickets].[TicketApproval]`، ويضبط الحالة الأولية على `WAITING_APPROVAL` عند الحاجة إلى موافقة
- `UPDATETICKETDETAILS`
- `ASSIGNTICKET`
- `REASSIGNTICKET`
- `STARTPROGRESS`
- `REQUESTARBITRATION`
- `DECIDEARBITRATION`
- `REQUESTCLARIFICATION`
- `RESPONDCLARIFICATION`
- `CREATECHILDTICKET`
- `PAUSETICKET`
- `RESUMETICKET`
- `RESOLVETICKET`
- `STARTQUALITYREVIEW`
- `COMPLETEQUALITYREVIEW`
- `CLOSETICKET`
- `REOPENTICKET`
- `MARKMAJORINCIDENT`
- **[v2]** `REQUESTAPPROVAL`: ينشئ صفوف `[Tickets].[TicketApproval]` من قالب `[Tickets].[ApprovalStep]` الخاص بالنوع التشغيلي للتذكرة. تحصل كل خطوة على صف بحالة `PENDING`. تنتقل حالة التذكرة إلى `WAITING_APPROVAL` وتبدأ جلسة إيقاف اتفاقية مستوى الخدمة (SLA) مؤقتاً.
- **[v2]** `APPROVETICKET`: يوافق المعتمد على خطوة واحدة من `[Tickets].[TicketApproval]`. تنتقل حالة الخطوة إلى `APPROVED`. إذا اكتملت جميع الخطوات الإلزامية، تنتقل التذكرة إلى `ASSIGNED` وتنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA). إذا بقيت خطوات أخرى، تصبح الخطوة `PENDING` التالية قابلة للتنفيذ وتبقى التذكرة في حالة `WAITING_APPROVAL`.
- **[v2]** `REJECTAPPROVAL`: يرفض المعتمد خطوة واحدة من `[Tickets].[TicketApproval]`. تنتقل حالة الخطوة إلى `REJECTED`. تنتقل حالة التذكرة إلى `REJECTED`. يُرسل إشعار إلى مقدم الطلب مع ملاحظات الرفض. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA).
- **[v2]** `UPDATEAPPROVALSTEP`: يُحدّث المسؤول قالب سلسلة الموافقات في `[Tickets].[ApprovalStep]`. التغييرات تؤثر على التذاكر الجديدة فقط ولا تُعدّل بأثر رجعي صفوف `[Tickets].[TicketApproval]` الموجودة.

المسؤوليات المشتركة:
- التحقق من هوية مقدم الطلب
- التحقق من صحة مسار الخدمة أو الخدمة الأخرى
- حساب الأولوية من `[Tickets].[PriorityMatrix]`
- تحميل اتفاقية مستوى الخدمة (SLA) من `[Tickets].[ServiceSLAPolicy]`
- التحقق من أهلية الوحدة/المستخدم من `[dbo].[V_getListUsersInDSD]`
- كتابة `[Tickets].[TicketHistory]`، و`[Tickets].[TicketSLAHistory]`، و`[dbo].[AuditLog]`
- تسجيل الأخطاء غير المتوقعة في `[dbo].[ErrorLog]`
- استدعاء `[dbo].[Notifications_Create]` اختيارياً

### 12.3 `[Tickets].[ServiceCatalogDL]`

الغرض:
- قراءة بيانات صفحة صيانة دليل الخدمات لصفحة `ServiceCatalog`

مجموعات النتائج الرئيسية:
- شبكة الخدمات
- شبكة قواعد التوجيه
- شبكة سياسات اتفاقية مستوى الخدمة (SLA)
- عمليات البحث عن الفئة/الحالة/الأولوية/الوحدة
- طابور مراجعة الاقتراحات
- **[v2]** شبكة قالب خطوات الموافقة

### 12.4 `[Tickets].[ServiceCatalogSP]`

الغرض:
- عمليات الكتابة للدليل، والتوجيه، واتفاقية مستوى الخدمة (SLA)، والاقتراحات، و**[v2]** قالب خطوات الموافقة

مجموعات الإجراءات:
- `INSERTSERVICECATEGORY`
- `UPDATESERVICECATEGORY`
- `DELETESERVICECATEGORY`
- `INSERTSERVICE`
- `UPDATESERVICE`
- `DELETESERVICE`
- `INSERTROUTINGRULE`
- `UPDATEROUTINGRULE`
- `DELETEROUTINGRULE`
- `INSERTSLAPOLICY`
- `UPDATESLAPOLICY`
- `DELETESLAPOLICY`
- `REVIEWCATALOGSUGGESTION`
- `CONVERTSUGGESTIONTOSERVICE`
- **[v2]** `INSERTAPPROVALSTEP`: ينشئ صفاً جديداً في قالب سلسلة الموافقات في `[Tickets].[ApprovalStep]` لنوع تشغيلي محدد. يضبط `stepOrder` و`isRequired` و`approverDSDID_FK` و`approverRole`.
- **[v2]** `UPDATEAPPROVALSTEP`: يُعدّل صفاً موجوداً في `[Tickets].[ApprovalStep]`. التغييرات تسري على التذاكر الجديدة فقط.
- **[v2]** `DELETEAPPROVALSTEP`: حذف مُنعطف (soft delete) لصف في `[Tickets].[ApprovalStep]`. صفوف `[Tickets].[TicketApproval]` الموجودة التي تشير إلى هذه الخطوة لا تتأثر.

### 12.5 `[Tickets].[TicketReportDL]`

الغرض:
- مجموعات بيانات التقارير لصفحة `TicketReports`

مجموعات النتائج الرئيسية:
- ملخص مؤشرات الأداء
- التراكم حسب الحالة
- التراكم حسب الوحدة
- ملخص تجاوزات اتفاقية مستوى الخدمة (SLA)
- ملخص الحوادث الكبرى
- تقادم طلبات التوضيح
- تقادم طلبات التحكيم
- حجم اقتراحات الدليل
- **[v2]** ملخص اختناقات الموافقة: متوسط الوقت في حالة `WAITING_APPROVAL`، ومعدلات رفض الموافقة، ومعدلات إكمال سلسلة الموافقات حسب النوع التشغيلي



## 13. خريطة العروض / تصاميم DL

### 13.1 `TicketCreate`
- فرع البوابة يستدعي `[Tickets].[TicketDL]`
- مجموعة النتائج 1: سياق مقدم الطلب وأي تحذيرات تتعلق بالتذاكر المفتوحة
- مجموعة النتائج 2: الخدمات
- مجموعة النتائج 3: فئات التذاكر
- مجموعة النتائج 4: التأثيرات
- مجموعة النتائج 5: درجات الاستعجال
- مجموعة النتائج 6: أنواع مقدمي الطلب
- **[v2]** مجموعة النتائج 7: الأنواع التشغيلية (لاختيار نوع تشغيلي)

### 13.2 `TicketMyTickets`
- مجموعة النتائج 1: قائمة تذاكر مقدم الطلب
- مجموعة النتائج 2: قائمة منسدلة لتصفية الحالة
- مجموعة النتائج 3: قائمة منسدلة لتصفية الأولوية

### 13.3 `TicketInbox`
- مجموعة النتائج 1: التذاكر المملوكة للطابور حسب `CurrentDSDID_FK`
- مجموعة النتائج 2: المكلفون المؤهلون من `[dbo].[V_getListUsersInDSD]`
- مجموعة النتائج 3: قائمة منسدلة لتصفية الحالة

### 13.4 `TicketList`
- مجموعة النتائج 1: قائمة الإدارة المحددة بالصلاحية والإدارة
- مجموعة النتائج 2: قائمة منسدلة لتصفية الحالة
- مجموعة النتائج 3: قائمة منسدلة لتصفية الفئة
- مجموعة النتائج 4: قائمة منسدلة لتصفية الأولوية
- مجموعة النتائج 5: قائمة منسدلة لتصفية الهيكل التنظيمي من `[dbo].[V_getFullStructureForDSD]`

### 13.5 `TicketWorkbench`
- مجموعة النتائج 1: عنوان تذكرة واحد
- مجموعة النتائج 2: الجدول الزمني للتاريخ
- مجموعة النتائج 3: صفوف التحكيم النشطة
- مجموعة النتائج 4: صفوف التوضيح النشطة
- مجموعة النتائج 5: التذاكر الفرعية
- مجموعة النتائج 6: صف اتفاقية مستوى الخدمة (SLA)
- مجموعة النتائج 7: عمليات البحث عن إجراءات المكلف/الـ DSD
- **[v2]** مجموعة النتائج 8: خطوات سلسلة الموافقات وحالتها الحالية (`PENDING`، `APPROVED`، `REJECTED`، `SKIPPED`). يعرض كل صف ترتيب الخطوة، وـ DSD للموافق، والمستخدم الموافق المحدد (إن وُجد)، وحالة الخطوة، والطوابع الزمنية لتنفيذ الخطوة.
- **[v2]** مجموعة النتائج 9: إجراءات الموافقة المعلقة المتاحة للمستخدم الحالي. تكون مجموعة النتائج هذه فارغة إذا لم يكن المستخدم يملك سلطة موافقة على هذه التذكرة. عند تعبئتها، تُشغّل أزرار القبول/الرفض في واجهة منصة العمل.

### 13.6 `TicketQualityReview`
- مجموعة النتائج 1: التذاكر المحلة التي تنتظر مراجعة الجودة
- مجموعة النتائج 2: جدول بحث نتائج المراجعة
- مجموعة النتائج 3: إحصائيات الأولوية/الحالة لبطاقات لوحة المراجع

### 13.7 `ServiceCatalog`
- فرع البوابة يستدعي `[Tickets].[ServiceCatalogDL]`
- مجموعة النتائج 1: الخدمات
- مجموعة النتائج 2: قواعد التوجيه
- مجموعة النتائج 3: سياسات اتفاقية مستوى الخدمة (SLA)
- مجموعة النتائج 4: فئات الخدمات
- مجموعة النتائج 5: عمليات البحث عن DSD
- مجموعة النتائج 6: اقتراحات الفهرس
- **[v2]** مجموعة النتائج 7: قوالب خطوات الموافقة، صف واحد لكل `[Tickets].[ApprovalStep]`، يعرض النوع التشغيلي، وترتيب الخطوة، وما إذا كانت الخطوة مطلوبة، وـ DSD/الدور الخاص بالموافق

### 13.8 `TicketReports`
- فرع البوابة يستدعي `[Tickets].[TicketReportDL]`
- مجموعات النتائج مخصصة للتقارير فقط ولا يجب إعادة استخدامها في صفحات CRUD

### 13.9 `TicketApprovals` **[v2]**
- فرع البوابة يستدعي `[Tickets].[TicketDL]`
- مجموعة النتائج 1: الموافقات المعلقة ضمن نطاق DSD للمستخدم الحالي. يعرض كل صف معرّف التذكرة، ورقم التذكرة، والعنوان، واسم مقدم الطلب، والنوع التشغيلي، وخطوة الموافقة المحددة التي يمكن للمستخدم تنفيذها، وتاريخ إنشاء الخطوة، ومعلومات العد التنازلي لاتفاقية مستوى الخدمة (SLA). تقتصر الصفوف على التذاكر حيث يتطابق DSD المستخدم مع `approverDSDID_FK` على خطوة `[Tickets].[TicketApproval]` المعلقة.
- مجموعة النتائج 2: سجل الموافقات. الموافقات المكتملة (سواء `APPROVED` أو `REJECTED`) التي نفّذها المستخدم الحالي، مع الطوابع الزمنية والملاحظات. تُستخدم للوحة "قراراتي الأخيرة" في صفحة الموافقات.
- مجموعة النتائج 3: قائمة منسدلة لتصفية الحالة. تسمح بتصفية قائمة المعلقات حسب حالة الموافقة (`PENDING`، `APPROVED`، `REJECTED`، `ALL`).

## 14. إضافات توجيه البوابة

### 14.1 `[dbo].[Masters_DataLoad]`
أضف فروع `@pageName_` التالية بأسلوب Housing الفعلي:

```sql
ELSE IF @pageName_ = 'TicketCreate'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
END

ELSE IF @pageName_ = 'TicketMyTickets'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketInbox'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketList'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
      , @parameter_03 = @parameter_03
END

ELSE IF @pageName_ = 'TicketWorkbench'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketQualityReview'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'ServiceCatalog'
BEGIN
    EXEC [Tickets].[ServiceCatalogDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END

ELSE IF @pageName_ = 'TicketReports'
BEGIN
    EXEC [Tickets].[TicketReportDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
      , @parameter_02 = @parameter_02
END

ELSE IF @pageName_ = 'TicketApprovals'
BEGIN
    EXEC [Tickets].[TicketDL]
        @pageName_    = @pageName_
      , @idaraID      = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @parameter_01 = @parameter_01
END
```

### 14.2 `[dbo].[Masters_CRUD]`
أضف فروع الصفحات التالية بأسلوب فحص الصلاحيات الفعلي المستخدم في `WaitingListByResident`:

```sql
ELSE IF @pageName_ = 'TicketCreate'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03;
END

ELSE IF @pageName_ = 'TicketWorkbench'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03
      , @param4       = @parameter_04
      , @param5       = @parameter_05;
END

ELSE IF @pageName_ = 'TicketQualityReview'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03;
END

ELSE IF @pageName_ = 'ServiceCatalog'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v


        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[ServiceCatalogSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03
      , @param4       = @parameter_04
      , @param5       = @parameter_05;
END

ELSE IF @pageName_ = 'TicketApprovals'
BEGIN
    IF (SELECT COUNT(*)
        FROM dbo.V_GetListUserPermission v
        WHERE v.userID = @entrydata
          AND v.menuName_E = @pageName_
          AND v.permissionTypeName_E = @ActionType) <= 0
    BEGIN
        SET @ok = 0; SET @msg = N'عفوا لاتملك صلاحية لهذه العملية'; GOTO Finish;
    END

    INSERT INTO @Result(IsSuccessful, Message_)
    EXEC [Tickets].[TicketSP]
        @Action       = @ActionType
      , @idaraID_FK   = @idaraID
      , @entryData    = @entrydata
      , @hostName     = @hostName
      , @param1       = @parameter_01
      , @param2       = @parameter_02
      , @param3       = @parameter_03;
END
```

قيم الصفحات المطلوب إضافتها بالضبط:

- `TicketCreate`
- `TicketMyTickets`
- `TicketInbox`
- `TicketList`
- `TicketWorkbench`
- `TicketQualityReview`
- `ServiceCatalog`
- `TicketReports`
- **[v2]** `TicketApprovals`

## 15. مصفوفة القواعد التجارية

| المعرف | القاعدة | موقع التنفيذ |
|---|---|---|
| BR-01 | يجب وجود مصدر طلب واحد فقط: `UsersID_FK` أو `residentInfoID_FK` (لا كلاهما) | `[Tickets].[TicketSP]` |
| BR-02 | الخدمة المعروفة تتطلب `serviceID_FK`؛ الخدمة غير المعروفة تتطلب `otherServiceText` | `[Tickets].[TicketSP]` |
| BR-03 | إنشاء التذكرة يجب أن يحسب الأولوية من `impactID_FK` ضرب `urgencyID_FK` عبر `[Tickets].[PriorityMatrix` | `[Tickets].[TicketSP]` |
| BR-04 | إنشاء التذكرة يجب أن يحمل اتفاقية مستوى الخدمة (SLA) من `[Tickets].[ServiceSLAPolicy]` عند وجود `serviceID_FK` | `[Tickets].[TicketSP]` |
| BR-05 | يجب تعبئة `CurrentDSDID_FK` دائماً في جدول `[Tickets].[Ticket` | `[Tickets].[TicketSP]` |
| BR-06 | التعيين إلى `AssignedToUsersID_FK` صالح فقط إذا كان المستخدم نشطاً ومؤهلاً في `[dbo].[V_GetListUsersInDSD]` للوحدة التنظيمية الحالية | `[Tickets].[TicketSP]` |
| BR-07 | لا يمكن أن يكون التحكيم والتوضيح نشطين معاً لنفس التذكرة في الوقت نفسه | `[Tickets].[TicketSP]` |
| BR-08 | لا يوجد سوى جلسة إيقاف واحدة نشطة لكل تذكرة | `[Tickets].[TicketSP]` مع فحص استعلام الجدول |
| BR-09 | يجب تعيين الروابط الأصلية والجذرية بشكل ذري عند إنشاء تذكرة فرعية | `[Tickets].[TicketSP]` |
| BR-10 | لا يمكن أن تنتقل التذكرة إلى `CLOSED` قبل نجاح مراجعة الجودة ما لم يُمنح إجراء تجاوز محدد | `[Tickets].[TicketSP]` وإعدادات الصلاحيات |
| BR-11 | `resolutionTypeID_FK` و `resolutionNotes` مطلوبان لإجراء `RESOLVETICKET` | `[Tickets].[TicketSP]` |
| BR-12 | `isMajorIncident = 1` يتطلب توجيهاً حرجاً وإظهاراً للمراجعين | `[Tickets].[TicketSP]` و `TicketReportDL` |
| BR-13 | كل عملية كتابة تُدرج سجلاً في السجل المحلي وفي `[dbo].[AuditLog]` المركزي | `[Tickets].[TicketSP]` و `[Tickets].[ServiceCatalogSP]` |
| BR-14 | تغييرات قواعد التوجيه يجب أن تكتب في `[Tickets].[ServiceRoutingRuleHistory]` | `[Tickets].[ServiceCatalogSP]` |
| BR-15 | جداول السجلات التاريخية للقراءة فقط (إلحاق فقط) | تصميم الإجراء المخزن بدون مسارات حذف أو تحديث |
| BR-16 | كل قراءة صفحة يجب أن تعيد مجموعة نتائج الصلاحيات أولاً عبر `[dbo].[ft_UserPagePermissions]` | `[dbo].[Masters_DataLoad]` |
| BR-17 | كل صفحة CRUD يجب أن تفحص صلاحية الصفحة عبر `[dbo].[V_GetListUserPermission]` قبل استدعاء الإجراء المخزن الفرعي | `[dbo].[Masters_CRUD]` |
| BR-18 | صندوق الوارد (`TicketInbox`) ومقعد العمل (`TicketWorkbench`) يجب أن يحدا التذاكر المرئية حسب صلاحية الصفحة والواقع التنظيمي الحالي | تصميم استعلام التحميل |
| BR-19 **[v2]** | `operationalTypeID_FK` مطلوب في كل تذكرة. إجراء `INSERTTICKET` يجب أن يرفض أي تذكرة لا تحدد نوع تشغيلي. | `[Tickets].[TicketSP]` |
| BR-20 **[v2]** | إذا وُجدت صفوف في `[Tickets].[ApprovalStep]` خاصة بالنوع التشغيلي للتذكرة، يجب على النظام إنشاء صفوف `[Tickets].[TicketApproval]` من القالب قبل أن تغادر التذكرة حالة `WAITING_APPROVAL`. إجراء `INSERTTICKET` يفحص خطوات القالب عند الإنشاء. إذا وُجدت خطوات، تبدأ التذكرة في حالة `WAITING_APPROVAL` مع جميع خطوات القالب محولة إلى صفوف موافقة معلقة وجلسة إيقاف اتفاقية مستوى الخدمة (SLA) نشطة. إذا لم توجد خطوات لهذا النوع التشغيلي، تسلك التذكرة مسار الحالات المعتاد بدون بوابة الموافقة. | `[Tickets].[TicketSP]` |
| BR-21 **[v2]** | جميع خطوات الموافقة الإلزامية (حيث `isRequired = 1` في `[Tickets].[ApprovalStep]`) يجب أن تصل إلى حالة `APPROVED` قبل أن تدخل التذكرة حالة `ASSIGNED` أو `IN_PROGRESS`. الخطوات الاختيارية (حيث `isRequired = 0`) يمكن تخطيها دون إيقاف التقدم. إجراء `APPROVETICKET` يفحص هذا الشرط بعد كل موافقة ولا يُقدم التذكرة إلا بعد تخليص جميع الخطوات الإلزامية. | `[Tickets].[TicketSP]` |
| BR-22 **[v2]** | إجراء `REJECTAPPROVAL` على أي خطوة إلزامية ينقل التذكرة إلى حالة `REJECTED` ويُعلم مقدم الطلب بملاحظات المرفق. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA). يمكن إعادة فتح التذكرة المرفوضة عبر `REOPENTICKET`، الذي يُعيدها إلى سلسلة الموافقات من البداية. | `[Tickets].[TicketSP]` |
| BR-23 **[v2]** | التذاكر الفرعية المتوازية: عندما تمتلك تذكرة أصل تذاكر فرعية مفتوحة، تكون حالة الأصل `WAITING_CHILD`. لا يمكن للأصل استئناف المعالجة المعتادة حتى تصل جميع التذاكر الفرعية إلى حالة نهائية (`RESOLVED` أو `CLOSED` أو `CANCELLED`). عندما تصل آخر تذكرة فرعية إلى حالة نهائية، تنتهي جلسة `PAUSETICKET` للأصل، وتُلغى إيقاف اتفاقية مستوى الخدمة (SLA)، وتعود حالة الأصل إلى حالتها ما قبل الانتظار. يجب أن يكون المشغل الذي يكتمل إكمال آخر تذكرة فرعية ذرياً لتجنب حالات السباق مع إكمال التذاكر الفرعية المتزامنة. | `[Tickets].[TicketSP]` |
| BR-24 **[v2]** | التوضيح بين الفنيين: عندما يطلب فني توضيحاً من وحدة تنظيمية أخرى، يجب أن يكون `RequestedFromDSDID_FK` مختلفاً عن الوحدة التنظيمية الحالية للتذكرة (`CurrentDSDID_FK`). طلب التوضيح الموجه لنفس الوحدة التنظيمية التي تملك التذكرة حالياً يُرفض كتوضيح ذاتي. | `[Tickets].[TicketSP]` |
| BR-25 **[v2]** | التحكيم الهرمي: عندما يكون التحكيم مطلوباً بسبب نزاع وحدتين تنظيميتين على المسؤولية، يتحدد مستوى التحكيم بإيجاد أقل أب مشترك `DSDID` للوحدتين المتنازعتين. يجب أن تكون الوحدة التنظيمية للمحكّم عند مستوى الأب المشترك أو أعلى منه. إذا لم تشارك الوحدتان المتنازعتان أبّاً مشتركاً ضمن نطاق `IdaraID`، يتحول التحكيم إلى الوحدة التنظيمية على مستوى الإدارة. | `[Tickets].[TicketSP]` |


يحدد هذا القسم نظام سلسلة الموافقات الفرعي لنظام التذاكر وفق معيار ITIL 4. ليست كل تذكرة تحتاج موافقة. عندما تكون الموافقة مطلوبة، يستخدم النظام نموذج قالب/نسخة بجدولين لفرض التوقيع المتتابع قبل بدء العمل.

## 16.1 آلية عمل سلاسل الموافقات

تستخدم سلسلة الموافقات نمط القالب إلى النسخة. جدولان يحركان الآلية بالكامل.

**`[Tickets].[ApprovalStep]`** يعرّف قوالب سلسلة الموافقات. كل صف يصف خطوة موافقة واحدة في السلسلة، مرتبطة بنوع تشغيلي واختيارياً بخدمة محددة. هذه الصفوف يُعدّها المسؤولون ونادراً ما تتغير يوماً بعد يوم. فكر فيها كالمخطط الأساسي.

**`[Tickets].[TicketApproval]`** يتتبع نسخ الموافقة الفعلية. عندما تدخل تذكرة مسار الموافقات، يقرأ النظام صفوف القالب ذات الصلة من `ApprovalStep` وأنشئ صف `TicketApproval` واحداً لكل خطوة. تحمل هذه النسخ القرار الفعلي، والموافق الذي تصرف، والطوابع الزمنية، والتعليقات.

هذا الفصل يعني أنك تستطيع تغيير القالب للتذاكر المستقبلية دون التأثير على التذاكر الجارية حالياً.

### ApprovalStep DDL

```sql
CREATE TABLE [Tickets].[ApprovalStep]
(
    approvalStepID        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY
  , IdaraID_FK            BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[Idara].[idaraID]
  , operationalTypeID_FK  INT NOT NULL FOREIGN KEY REFERENCES [Tickets].[OperationalType].[operationalTypeID]
  , serviceID_FK          BIGINT NULL FOREIGN KEY REFERENCES [Tickets].[Service].[serviceID]
  , stepOrder             INT NOT NULL
  , stepName_A            NVARCHAR(200) NOT NULL
  , stepName_E            NVARCHAR(200) NOT NULL
  , ApproverDSDID_FK      BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[DeptSecDiv].[DSDID]
  , ApproverDistributorID_FK BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Distributor].[distributorID]
  , isRequired            BIT NOT NULL DEFAULT 1
  , approvalStepActive    BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

الأعمدة الرئيسية:

- `operationalTypeID_FK` يربط الخطوة بنوع تشغيلي عبر مفتاح أجنبي إلى `[Tickets].[OperationalType]`.
- `serviceID_FK` يقبل القيم الفارغة. عندما يكون فارغاً، تنطبق الخطوة على جميع الخدمات تحت هذا النوع التشغيلي. عند تعيينه، تتجاوز الخطوة سلسلة الموافقات العامة لهذه الخدمة المحددة.
- `stepOrder` عدد صحيح يبدأ من 1. يجب الفصل في الخطوة 1 قبل أن يمكن التصرف على الخطوة 2.
- `ApproverDSDID_FK` يحدد الوحدة التنظيمية التي يتبع لها الموافق.
- `ApproverDistributorID_FK` يحدد دوراً محدداً داخل تلك الوحدة. عندما يكون فارغاً، يمكن لأي مستخدم نشط في الوحدة التنظيمية الموافقة.
- `isRequired` يحدد ما إذا كان يمكن تخطي الخطوة. القيمة 1 تعني إلزامية. القيمة 0 تعني أن مستخدماً مخولاً يستطيع تخطيها.

قيد التفرد: `(IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder)` مصفّى إلى الصفوف النشطة فقط.

### TicketApproval DDL

```sql
CREATE TABLE [Tickets].[TicketApproval]
(
    ticketApprovalID      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY
  , IdaraID_FK            BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[Idara].[idaraID]
  , TicketID_FK           BIGINT NOT NULL FOREIGN KEY REFERENCES [Tickets].[Ticket].[ticketID]
  , approvalStepID_FK     BIGINT NOT NULL FOREIGN KEY REFERENCES [Tickets].[ApprovalStep].[approvalStepID]
  , stepOrder             INT NOT NULL
  , ApproverDSDID_FK      BIGINT NOT NULL FOREIGN KEY REFERENCES [dbo].[DeptSecDiv].[DSDID]
  , ApproverDistributorID_FK BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Distributor].[distributorID]
  , isRequired            BIT NOT NULL DEFAULT 1
  , approvalStatus        NVARCHAR(50) NOT NULL
  , ApproverUsersID_FK    BIGINT NULL FOREIGN KEY REFERENCES [dbo].[Users].[usersID]
  , approvalNotes         NVARCHAR(MAX) NULL
  , requestedAt           DATETIME NOT NULL
  , decidedAt             DATETIME NULL
  , ticketApprovalActive  BIT NULL
  , entryDate             DATETIME NULL
  , entryData             NVARCHAR(20) NULL
  , hostName              NVARCHAR(200) NULL
);
```

الأعمدة الرئيسية:

- `approvalStatus` يتتبع القرار: `PENDING` أو `APPROVED` أو `REJECTED` أو `SKIPPED`.
- `ApproverUsersID_FK` يسجل من اتخذ القرار.
- `decidedAt` يسجل متى اتُخذ القرار.
- `approvalNotes` يحمل تعليقات اختيارية من الموافق.

قيد التفرد: صف واحد فقط لكل `(TicketID_FK, stepOrder)`.

## 16.2 ترتيب الخطوات ومنطق الإلزام والاختيارية

تُنفذ الخطوات بتسلسل `stepOrder`. يفرض النظام ذلك على مستوى الإجراء المخزن.

عندما تدخل تذكرة مسار الموافقات، يقوم `[Tickets].[TicketSP]` بما يلي:

1. يقرأ جميع صفوف `ApprovalStep` النشطة المطابقة لـ `operationalTypeID_FK` و `IdaraID_FK` الخاصة بالتذكرة، مع اعتبار التجاوزات الخاصة بالخدمة أولاً (انظر القسم 16.8).
2. ينشئ صف `TicketApproval` واحداً لكل خطوة قالب، جميعها بحالة `approvalStatus = 'PENDING'`.
3. فقط الخطوة الأولى (`stepOrder = 1`) يمكن التصرف عليها فوراً. الخطوات ذات `stepOrder > 1` تبقى بحالة `PENDING` لكن لا يمكن التصرف عليها حتى تُحل الخطوة السابقة.

تُعتبر الخطوة محسومة عندما تكون حالتها `approvalStatus` إما `APPROVED` أو `REJECTED` أو `SKIPPED`.

يعمل التمييز بين الإلزامي والاختياري كالتالي:

- **إلزامية** (`isRequired = 1`): يجب أن تتلقى الخطوة قرار `APPROVED` أو `REJECTED` صريحاً. لا يمكن تخطيها.
- **اختيارية** (`isRequired = 0`): يمكن تخطيها من قبل مستخدم مخول. عند التخطي، يعاملها النظام كمحسومة لأغراض الترتيب وينتقل إلى الخطوة التالية.

إذا كانت الخطوة 2 اختيارية والخطوة 3 إلزامية، تبقى الخطوة 3 محجوبة حتى تُحل الخطوة 2 بالموافقة أو الرفض أو التخطي.

## 16.3 مسار الموافقة (انتقالات الحالات)

يُدرج مسار الموافقات حالة مخصصة ضمن دورة حياة التذكرة الحالية.

تسلسل الحالات:

```
NEW  -->  WAITING_APPROVAL  -->  ASSIGNED  -->  IN_PROGRESS  -->  ...
```

عندما يعالج `[Tickets].[TicketSP]` إجراء `INSERTTICKET` ويجد خطوات موافقة مطابقة:

1. تُنشأ التذكرة بحيث يشير `ticketStatusID_FK` إلى `WAITING_APPROVAL` بدلاً من `NEW` أو `ASSIGNED`.
2. تُنشأ صفوف نسخ `TicketApproval` لكل خطوة قالب.
3. تبدأ جلسة إيقاف اتفاقية مستوى الخدمة (SLA) مع إشارة `pauseReasonID_FK` إلى سبب الإيقاف `WAITING_APPROVAL` (المزروع في القسم 11.8).

عندما يتصرف موافق على خطوة (عبر إجراء `APPROVETICKET` الجديد في `TicketSP`):

1. يتحقق الإجراء المخزن من أن الخطوة الحالية هي أقل خطوة غير محلومة.
2. يتحقق من أن المستخدم المتصرف مؤهل (انظر القسم 16.6).
3. يحدّث صف `TicketApproval`: يضبط `approvalStatus` و `ApproverUsersID_FK` و `decidedAt` و `approvalNotes`.
4. يكتب صف `TicketHistory` يسجل قرار الموافقة.
5. يفحص ما إذا كانت جميع الخطوات الإلزامية قد وُفق عليها. إذا نعم، تنتقل التذكرة إلى `ASSIGNED`، وتنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA)، وتدخل التذكرة في التوجيه المعتاد.
6. إذا بقيت خطوات أخرى، تبقى التذكرة في `WAITING_APPROVAL` وتصبح الخطوة التالية قابلة للتصرف.

هذا المنطق يعني أن التذكرة لا تصل إلى `ASSIGNED` حتى تُوافق على كل خطوة إلزامية في السلسلة.

## 16.4 مسار الرفض

أي خطوة إلزامية تستطيع رفض التذكرة.

عندما يضبط موافق `approvalStatus = 'REJECTED'` على خطوة إلزامية:

1. ينتقل الإجراء المخزن فوراً بالتذكرة إلى حالة الرفض. تصبح حالة التذكرة `REJECTED` (صف جديد مزروع في `[Tickets].[TicketStatus]`).
2. جميع الخطوات `PENDING` المتبقية تُضبط إلى `SKIPPED` تلقائياً. لا حاجة لأي إجراءات موافقة إضافية.
3. تنتهي جلسة إيقاف اتفاقية مستوى الخدمة (SLA).
4. يسجل صف `TicketHistory` الرفض، متضمناً أي خطوة رفضت ولماذا.
5. يُرسل إشعار إلى مقدم الطلب.

تعود التذكرة المرفوضة إلى مقدم الطلب. يستطيع مقدم الطلب حينها:

- التعديل وإعادة الإرسال، مما ينشئ تذكرة جديدة (أو يعيد فتح نفس التذكرة إذا فضّل العمل ذلك، يتحكم فيه منطق الإجراء المخزن وإجراء على غرار `REOPENTICKET` يعيد تقييم سلسلة الموافقات).
- إلغاء التذكرة.

الرفض لا يمنع مقدم الطلب بشكل دائم. إنما يعيد الطلب إليه للتصحيح.

تتصرف الخطوات الاختيارية بشكل مختلف. إذا رُفضت خطوة اختيارية، يعاملها النظام كمحسومة (مثل التخطي) وينتقل إلى الخطوة التالية. فقط رفض الخطوات الإلزامية يشغّل مسار الرفض الكامل الموضح أعلاه.

## 16.5 التفاعل مع اتفاقية مستوى الخدمة (SLA)

يتوقف وقت اتفاقية مستوى الخدمة (SLA) خلال نافذة الموافقة. هذا أمر حاسم لتتبع عادل لاتفاقية مستوى الخدمة.

عندما تدخل التذكرة حالة `WAITING_APPROVAL`:

1. ينشئ `[Tickets].[TicketSP]` صف `TicketPauseSession` مع إشارة `pauseReasonID_FK` إلى سبب إيقاف `WAITING_APPROVAL` (المزروع في القسم 11.8).
2. ينتقل `[Tickets].[TicketSLA]` إلى `slaState = 'PAUSED'`.
3. يسجل صف `TicketSLAHistory` انتقال الإيقاف.

عندما تكتمل سلسلة الموافقات (جميع الخطوات الإلزامية وُفق عليها، تنتقل التذكرة إلى `ASSIGNED`):


1. تُغلق جلسة `TicketPauseSession` المفتوحة. ويتم حساب `endedAt` و`pausedMinutes`.
2. يُزاد `totalPausedMinutes` في سجل `TicketSLA` بمدة الإيقاف.
3. تُعاد حساب تواريخ الاستجابة والحل المحددة بإضافة دقائق الإيقاف إلى المواعيد النهائية الأصلية.
4. يعود `slaState` إلى الحالة `RUNNING`.
5. يُسجّل صف `TicketSLAHistory` انتقال الاستئناف.

عند رفض تذكرة أثناء الموافقة:

1. تُغلق جلسة الإيقاف.
2. يُعلَّم سجل اتفاقية مستوى الخدمة بالحالة `slaState = 'CLOSED`' (لن تنتقل التذكرة إلى مرحلة التنفيذ).

هذا النهج يضمن أن الوقت المستغرق في انتظار موافقة الإدارة لا يُحتسب ضمن ساعة اتفاقية مستوى الخدمة الخاصة بمنفذ التذكرة.

## 16.6 من يمكنه الموافقة (الأهلية عبر V_GetListUsersInDSD)

الأهلية مبنية على الهيكل التنظيمي القائم فعلياً، وليس على جدول صلاحيات جديد.

يتحقق الإجراء المخزن من الأهلية بهذه الطريقة:

1. يجب أن يكون المُوافق مستخدماً نشطاً في `ApproverDSDID_FK`. يتحقق الإجراء المخزن من ذلك بالاستعلام عن `[dbo].[V_GetListUsersInDSD]` المُصفَّى حسب DSD.
2. إذا لم يكن `ApproverDistributorID_FK` فارغاً، فيجب أن يحمل المستخدم أيضاً دور الموزع المحدد في DSD. يتحقق الإجراء المخزن من ذلك بالربط عبر `[dbo].[UserDistributor]`.
3. لا يمكن أن يكون المُوافق هو نفس المستخدم الذي فتح التذكرة (`OpenedByUsersID_FK`). هذا يمنع الموافقة الذاتية.

نمط استعلام الأهلية:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM [dbo].[V_GetListUsersInDSD] v
    WHERE v.usersID = @actingUserID
      AND v.DSDID = @approverDSDID
      AND v.isActive = 1
      AND (@approverDistributorID IS NULL
           OR EXISTS (
               SELECT 1
               FROM [dbo].[UserDistributor] ud
               WHERE ud.usersID = @actingUserID
                 AND ud.distributorID = @approverDistributorID
           ))
      AND @actingUserID <> @openedByUserID
)
BEGIN
    THROW 50001, N'You are not authorized to approve this step.', 1;
END
```

هذا يعني أن النظام لا يُشفّر أسماء مستخدمين محددين داخل سلسلة الموافقات. بل يُحدّد المنصب التنظيمي، وأي شخص يشغل هذا المنصب حالياً يمكنه الموافقة.

## 16.7 أمثلة على البيانات الأساسية

يعرض الجدول التالي قوالب سلسلة الموافقات الافتراضية المُدمجة لكل نوع تشغيلي. هذه القوالب الأساسية. يمكن للمسؤولين إضافة خطوات أو إزالتها أو إعادة ترتيبها من خلال صفحة إدارة كتالوج الخدمات.

| Operational Type | Step 1 | Step 2 | Step 3 | Step 4 |
|---|---|---|---|---|
| SERVICE_REQUEST | المشرف (إلزامي) | مدير الفرع (إلزامي) | مدير الإدارة (إلزامي) | -- |
| DISBURSEMENT | المشرف (إلزامي) | مدير الفرع (إلزامي) | قسم المالية (إلزامي) | مدير الإدارة (إلزامي) |
| EXECUTION | مدير الفرع (إلزامي) | مدير الإدارة (إلزامي) | -- | -- |
| INSPECTION | مدير القسم (إلزامي) | -- | -- | -- |

في كل صف، يرتبط DSD الخاص بكل خطوة بوحدة التنظيمية المقابلة في `[dbo].[DeptSecDiv]`. أما الدور (المشرف، مدير الفرع، إلخ) فيرتبط بـ `DistributorID` محدد عندما ترغب المنظمة في موافقة قائمة على المنصب، أو يُترك فارغاً عندما يمكن لأي مستخدم نشط في ذلك DSD الموافقة.

نمط SQL للبيانات الأساسية:

```sql
INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'SERVICE_REQUEST', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'SERVICE_REQUEST', NULL, 3, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'DISBURSEMENT', NULL, 1, @supervisorDSDID, @supervisorDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 2, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 3, @financeDSDID, @financeDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'DISBURSEMENT', NULL, 4, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'EXECUTION', NULL, 1, @branchMgrDSDID, @branchMgrDistID, 1, 1, GETDATE(), @entryData, @hostName),
    (@idaraID, 'EXECUTION', NULL, 2, @deptMgrDSDID, @deptMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);

INSERT INTO [Tickets].[ApprovalStep]
    (IdaraID_FK, operationalTypeID_FK, serviceID_FK, stepOrder,
     ApproverDSDID_FK, ApproverDistributorID_FK, isRequired,
     approvalStepActive, entryDate, entryData, hostName)
VALUES
    (@idaraID, 'INSPECTION', NULL, 1, @sectionMgrDSDID, @sectionMgrDistID, 1, 1, GETDATE(), @entryData, @hostName);
```

تُحل مُعرِّفات DSD وDistributor الفعلية وقت الإدراج من جداول `[dbo].[DeptSecDiv]` و`[dbo].[Distributor]` الحية للإدارة العامة (Idara) المستهدفة.

## 16.8 تجاوزات خاصة بالخدمة

بعض الخدمات تحتاج إلى سلسلة موافقات مختلفة عن الافتراضية لنوعها التشغيلي. يعالج عمود `serviceID_FK` في `[Tickets].[ApprovalStep]` هذا الأمر.

منطق الحل في `[Tickets].[TicketSP]` عند بناء سلسلة الموافقات لتذكرة جديدة:

1. أولاً، البحث عن صفوف `ApprovalStep` النشطة حيث يتطابق `serviceID_FK` مع `serviceID_FK` الخاص بالتذكرة ويتطابق `operationalTypeID_FK` مع النوع التشغيلي للتذكرة.
2. إذا وُجدت صفوف خاصة بالخدمة، تُستخدم كقالب لسلسلة الموافقات. ويتم تجاهل الصفوف العامة لذلك النوع التشغيلي.
3. إذا لم توجد صفوف خاصة بالخدمة، يُعود النظام إلى الصفوف العامة حيث `serviceID_FK IS NULL`.

هذا يعني:

- قد تتطلب سلسلة `SERVICE_REQUEST` العامة المشرف ثم مدير الفرع ثم مدير الإدارة.
- خدمة محددة مثل "نقل وحدة سكنية" يمكنها تجاوز ذلك بمدير الفرع ومدير الإسكان فقط، متخطية خطوة المشرف تماماً.
- التجاوز يكون لكل خدمة، وليس لكل تذكرة. بمجرد إعداده، كل تذكرة لتلك الخدمة تتبع سلسلة الموافقات المتجاوزة.

يدير المسؤولون التجاوزات من خلال صفحة `ServiceCatalog`. يتضمن مجموعة نتائج `ServiceCatalogDL` خطوات الموافقة الحالية لكل خدمة. ويتيح إجراء `UPDATEAPPROVALSTEP` في `ServiceCatalogSP` للمسؤولين إضافة خطوات أو إزالتها أو إعادة ترتيبها.

## 16.9 الموافقة التلقائية

إذا لم توجد صفوف `ApprovalStep` للنوع التشغيلي للتذكرة (ولم يوجد تجاوز خاص بالخدمة)، تتجاوز التذكرة تدفق الموافقة بالكامل.

في `[Tickets].[TicketSP]`، يتحقق إجراء `INSERTTICKET`:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM [Tickets].[ApprovalStep]
    WHERE IdaraID_FK = @idaraID_FK
      AND operationalTypeID_FK = @operationalTypeID_FK
      AND approvalStepActive = 1
      AND (serviceID_FK IS NULL OR serviceID_FK = @serviceID_FK)
)
BEGIN
    -- No approval chain defined. Bypass WAITING_APPROVAL.
    -- Set ticket status directly to ASSIGNED (or TRIAGED, depending on routing).
    -- Do not create any TicketApproval rows.
    -- Do not start an SLA pause session.
END
```

الموافقة التلقائية تعني:

- لا تُنشأ صفوف `TicketApproval`.
- لا تبدأ جلسة إيقاف اتفاقية مستوى الخدمة.
- تتبع التذكرة مسار الإنشاء والتوجيه العادي: من `NEW` إلى `ASSIGNED` بناءً على قاعدة التوجيه.
- لا تُكتب إدخالات سجل متعلقة بالموافقة.

هذا يحافظ على بساطة النظام للأنواع التشغيلية التي لا تحتاج إلى توقيع إداري. الحالة الافتراضية هي "لا حاجة لموافقة". الموافقة طبقة اختيارية يُعدّها المسؤولون.

## 16.10 إجراء مخزن جديد: APPROVETICKET

يتطلب تدفق الموافقة إجراءً جديداً واحداً في `[Tickets].[TicketSP]`.

**الإجراء:** `APPROVETICKET`

**المُعامِلات:**
- `@param1` = مُعرِّف التذكرة
- `@param2` = ترتيب الخطوة
- `@param3` = القرار (`APPROVED`, `REJECTED`, `SKIPPED`)
- `@param4` = ملاحظات الإجراء (اختياري)

**منطق الإجراء المخزن:**

1. التحقق من وجود التذكرة وأنها في حالة `WAITING_APPROVAL`.
2. تحميل صف `TicketApproval` لترتيب الخطوة المحدد.
3. التحقق من أن جميع خطوات الترتيب الأدنى تم حلها بالفعل (ليست `PENDING`).
4. إذا كان `decision = 'SKIPPED'`، التحقق من أن `isRequired = 0` في تلك الخطوة. الخطوات الإلزامية لا يمكن تخطيها.
5. التحقق من أهلية المستخدم المُنفِّذ عبر `V_GetListUsersInDSD` (القسم 16.6).
6. تحديث صف `TicketApproval`.
7. كتابة إدخالات `TicketHistory` و`AuditLog`.
8. إذا كان `decision = 'REJECTED`' و`isRequired = 1`، رفض التذكرة (القسم 16.4).
9. إذا كانت جميع الخطوات الإلزامية موافق عليها الآن، نقل التذكرة إلى حالة `ASSIGNED`، وإنهاء إيقاف اتفاقية مستوى الخدمة، وإعادة حساب المواعيد النهائية.
10. إرجاع `SELECT 1 AS IsSuccessful, N'...' AS Message_`.

يُوجَّه هذا الإجراء عبر `[dbo].[Masters_CRUD]` تحت اسم صفحة `TicketWorkbench`، ويُتحقق من الصلاحيات بنفس طريقة جميع إجراءات التذاكر الأخرى.

## 16.11 إضافة بيانات أساسية لـ TicketStatus

صف حالة واحد جديد مطلوب:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'WAITING_APPROVAL', N'في انتظار الموافقة', 'Waiting for Approval',
     2, 0, 1, 1);
```

لاحظ أن `isPauseStatus = 1` حتى يتعرف نظام اتفاقية مستوى الخدمة على هذه الحالة كحالة إيقاف. وترتيب الفرز `sortOrder` بقيمة 2 يضعها بين `NEW` (1) و`TRIAGED` (3) في تسلسل دورة الحياة.

صف ثانٍ لحالة الرفض النهائية:

```sql
INSERT INTO [Tickets].[TicketStatus]
    (IdaraID_FK, ticketStatusCode, ticketStatusName_A, ticketStatusName_E,
     sortOrder, isClosedStatus, isPauseStatus, ticketStatusActive)
VALUES
    (@idaraID, 'REJECTED', N'مرفوض', 'Rejected',
     12, 1, 0, 1);
```

`isClosedStatus = 1` لأن التذكرة المرفوضة هي حالة نهائية. لا يمكنها مغادرة هذه الحالة إلا عبر إجراء `REOPENTICKET`.

## 16.12 الأثر على تسلسل المواصفات

سلسلة الموافقات تمس مواصفتين قائمتين وتضيف قدراً قليلاً من العمل:

| Spec | Addition |
|---|---|
| Spec 01 | إدراج `WAITING_APPROVAL` و`REJECTED` في `[Tickets].[TicketStatus]`. إدراج `WAITING_APPROVAL` في `[Tickets].[PauseReason]` (مُدرج بالفعل). |
| Spec 04 | إنشاء `[Tickets].[ApprovalStep]` و`[Tickets].[TicketApproval]` إلى جانب جداول المعاملات الأخرى. |
| Spec 05 | إضافة إجراء `APPROVETICKET` إلى `[Tickets].[TicketSP]`. تعديل `INSERTTICKET` للتحقق من سلاسل الموافقات. |
| Spec 11 | إضافة مجموعات نتائج `WAITING_APPROVAL` إلى `TicketWorkbench` DL حتى يتمكن واجهة المستخدم من عرض خطوات الموافقة المعلقة. |

لا حاجة لمواصفة جديدة. سلسلة الموافقات تتلاءم مع تسلسل المواصفات القائم.


> هذه أقسام جديدة أُضيفت في الإصدار v2. يغطي القسم 17 تصميم التحكيم الهرمي. ويُعرّف القسم 18 أربعة أنواع تشغيلية من التذاكر مع سلاسل موافقات وقواعد توجيه وتوقعات اتفاقية مستوى الخدمة وقواعد العمل.

## 17. تصميم التحكيم الهرمي

يتولى التحكيم سيناريوهين: نزاعات المسؤولية بين الوحدات التنظيمية، وتوجيه الخدمات غير المعروفة حيث لا تتطابق أي قاعدة من كتالوج الخدمات. يسير نظام التحكيم صعوداً في تسلسل `DeptSecDiv` للعثور على صانع القرار المناسب في المستوى المناسب.

### 17.1 تصعيد النزاعات عبر المستويات التنظيمية

تتبع المنظمة هيكلاً من أربعة مستويات عبر `[dbo].[DeptSecDiv]`: قسم/شعبة ← فرع ← إدارة ← إدارة عامة (Idara). عندما تختلف وحدتان حول من يملك التذكرة، يعثر النظام على أقرب سلف مشترك بينهما ويُعيّن محكِّماً على ذلك المستوى.

| مستوى النزاع | مثال | مستوى المحكِّم |
|---|---|---|
| قسمان داخل نفس الفرع | القسم أ والقسم ب كلاهما يدّعي "ليس لنا" | محكِّم على مستوى الفرع |
| فرعان داخل نفس الإدارة | الفرع س والفرع ص يتنازعان على التوجيه | محكِّم على مستوى الإدارة |
| إدارتان داخل نفس الإدارة العامة | الإدارة م والإدارة ن تختلفان | محكِّم على مستوى الإدارة العامة |
| وحدة واحدة، خدمة غير معروفة | وحدة واحدة تتلقى تذكرة لخدمة غير مُدرجة | محكِّم على مستوى الوحدة الأصل |

يستخدم انتقال التسلسل الهرمي `[dbo].[V_GetFullStructureForDSD]` للسير من أي `DSDID` صعوداً عبر سلسلة الآباء. خوارزمية أقرب سلف مشترك تعمل بجمع المسار الكامل للأسلاف لكلا DSD المتنازعين، ثم إيجاد أول عقدة مشتركة بدءاً من الأسفل.

### 17.2 هوية المحكِّم

المحكِّم هو صف في `[dbo].[Distributor]` مع `distributorType_FK = 5`. هذه قيمة جديدة أُدخلت لنظام التذاكر.


| `distributorType_FK` | المعنى | الاستخدام |
|---|---|---|
| 1 | منصب تنظيمي | حامل طابور قياسي (مدير، رئيس قسم، إلخ.) |
| 3 | رتبة | دور مبني على الرتبة |
| **5** | **محكّم التذكرة** | مُقرّر نزاعات معيّن لكل DSD |

كل سطر محكّم في جدول `Distributor` يشير إلى `DSDID_FK` محدّد يمثّل العقدة التنظيمية التي يخدمها. مثلاً، محكّم على مستوى الإدارة يكون حقل `DSDID_FK` الخاص به يشير إلى صف DSD الخاص بتلك الإدارة. يعثر النظام على المحكّم الصحيح بمطابقة `distributorType_FK = 5` مع DSD المطلوب.

تُنشأ صفوف المحكّمين أثناء التهيئة أو من خلال صفحة إدارة `ServiceCatalog`. كل مستوى تنظيمي قد يحتاج إلى حلّ نزاعات يجب أن يمتلك صف محكّم واحد على الأقل.

### 17.3 البحث عن المحكّم لنزاع معيّن

الإجراء المخزّن `[Tickets].[TicketSP]` يتولّى البحث عن المحكّم عند استدعاء `REQUESTARBITRATION`. تتبع المنطق الخطوات التالية:

1. **تحكيم طرف واحد** (خدمة غير معروفة): التذكرة موجودة في وحدة لا تمتلك قاعدة كتالوج مطابقة. يقرأ النظام حقل `CurrentDSDID_FK` للتذكرة، يصعد مستوى واحد إلى DSD الأب، ويبحث عن صف `Distributor` يحتوي `distributorType_FK = 5` عند ذلك الأب.

2. **تحكيم طرفين** (نزاع مسؤولية): وحدتان كلاهما تعامل مع التذكرة أو كلاهما رُشّح كوجهة. يقوم النظام بما يلي:
   - يجمع سلسلة الأسلاف A لـ `DSDID_1` باستخدام `V_GetFullStructureForDSD`
   - يجمع سلسلة الأسلاف B لـ `DSDID_2` باستخدام `V_GetFullStructureForDSD`
   - يجد أقرب سلف مشترك DSD
   - يبحث عن صف `Distributor` يحتوي `distributorType_FK = 5` عند ذلك السلف

3. **الحلّ الاحتياطي**: إذا لم يوجد صف `distributorType_FK = 5` عند السلف المشترك، يصعد مستوى إضافي ويحاول مجدّداً. إذا وصل إلى قمة الهرم (مستوى Idara) دون وجود محكّم، يُطلق الإجراء المخزّن خطأ أعمال (`THROW 50001`) يفيد بأن تهيئة التحكيم غير مكتملة.

مخطط SQL للبحث عن أقرب سلف مشترك:

```sql
-- Build ancestor paths for two DSDs, find lowest common ancestor
;WITH AncestorsA AS (
    SELECT DSDID, ParentDSDID, 0 AS Level_
    FROM dbo.DeptSecDiv WHERE DSDID = @DSDID_1
    UNION ALL
    SELECT d.DSDID, d.ParentDSDID, a.Level_ + 1
    FROM dbo.DeptSecDiv d
    JOIN AncestorsA a ON d.DSDID = a.ParentDSDID
),
AncestorsB AS (
    SELECT DSDID, ParentDSDID, 0 AS Level_
    FROM dbo.DeptSecDiv WHERE DSDID = @DSDID_2
    UNION ALL
    SELECT d.DSDID, d.ParentDSDID, b.Level_ + 1
    FROM dbo.DeptSecDiv d
    JOIN AncestorsB b ON d.DSDID = b.ParentDSDID
)
SELECT TOP 1 a.DSDID AS CommonAncestorDSDID
FROM AncestorsA a
INNER JOIN AncestorsB b ON a.DSDID = b.DSDID
ORDER BY a.Level_ ASC;
```

### 17.4 التصعيد

إذا لم يستطع المحكّم على المستوى الحالي حلّ النزاع، تُصعَّد التذكرة إلى الأعلى:

1. يُسجّل المحكّم قرار `ESCALATE` في صف التحكيم ويضبط `DecisionTargetDSDID_FK` على DSD الأب.
2. يُغلق الإجراء المخزّن صف `TicketArbitration` الحالي (يضبط `decidedAt` و `DecisionByUsersID_FK`).
3. يُنشأ صف `TicketArbitration` جديد على المستوى الأعلى مع `ArbitratorDSDID_FK` يشير إلى DSD محكّم المستوى الأب.
4. تبقى حالة التذكرة `WAITING_ARBITRATION`.
5. يُسجّل صف `TicketHistory` التصعيد بقيمة `historyActionCode = 'ARBITRATION_ESCALATED'`.

التصعيد محظور على مستوى Idara. إذا حاول محكّم على مستوى Idara التصعيد، يرفض الإجراء المخزّن العملية بخأ أعمال. مستوى Idara هو نقطة التصعيد النهائية.

تُحفظ سلسلة التصعيد في `[Tickets].[TicketArbitration]` كصفوف متعددة لكل تذكرة، كل صف يحتوي `ArbitratorDSDID_FK` مختلف. تعرض طريقة عرض `TicketWorkbench` تاريخ التصعيد الكامل كخط زمني.

### 17.5 مسار التحكيم

```
WAITING_ARBITRATION
        |
        v
  Arbitrator reviews ticket
        |
        +---> DECIDE: sets DecisionTargetDSDID_FK
        |         |
        |         v
        |     Ticket re-routed to decided DSD
        |     Status -> ASSIGNED or TRIAGED
        |
        +---> ESCALATE: escalate to parent level
        |         |
        |         v
        |     New TicketArbitration row at parent
        |     Status remains WAITING_ARBITRATION
        |
        +---> REQUEST_CLARIFICATION_FROM_DISPUTANT
                  |
                  v
              Clarification row created
              SLA pauses (if configured)
              Status -> WAITING_CLARIFICATION
              After response -> back to WAITING_ARBITRATION
```

حقول البيانات الأساسية في `[Tickets].[TicketArbitration]`:

| الحقل | الغرض |
|---|---|
| `ArbitratorDSDID_FK` | DSD الذي يقع فيه دور المحكّم |
| `DecisionTargetDSDID_FK` | الوجهة التي تذهب إليها التذكرة بعد القرار. فارغ أثناء الانتظار، يُملأ عند إصدار القرار |
| `decisionNotes` | المبرر المكتوب من المحكّم |
| `requestedAt` / `decidedAt` | طوابع زمنية لتتبع اتفاقية مستوى الخدمة (SLA) وتقارير التقادم |

### 17.6 تفاعل التحكيم مع اتفاقية مستوى الخدمة (SLA)

عند دخول التذكرة حالة `WAITING_ARBITRATION`:

1. يبدأ `[Tickets].[TicketSP]` جلسة `TicketPauseSession` مع `pauseReasonID_FK` يشير إلى سبب الإيقاف `ARBITRATION`.
2. يتوقف مؤقت اتفاقية مستوى الخدمة (SLA) عن التراكم.
3. عند صدور قرار التحكيم، تنتهي جلسة الإيقاف، ويُحتسب `pausedMinutes`، ويعود مؤقت اتفاقية مستوى الخدمة (SLA) للعمل.
4. إذا صُعّد التحكيم، تستمر جلسة الإيقاف ولا تُعاد من البداية.

### 17.7 تتبع تاريخ التحكيم

جدول `[Tickets].[TicketArbitration]` القائم يدعم تتبع التصعيد من خلال بنيته الطبيعية بصف واحد لكل حدث:

- كل محاولة تحكيم هي صف واحد.
- التصديد يُنشئ صفاً ثانياً لنفس `TicketID_FK` مع `ArbitratorDSDID_FK` على مستوى أعلى.
- استعلام DL لطريقة عرض `TicketWorkbench` يعيد جميع صفوف التحكيم للتذكرة مرتّبة بحسب `requestedAt`، مما يروي قصة التصعيد الكاملة.

لا حاجة لتعديلات هيكلية على `TicketArbitration` لدعم التصديد. تعريف DDL القائم يحتوي كل الأعمدة المطلوبة. الإجراء `DECIDEARBITRATION` في `[Tickets].[TicketSP]` يضيف منطق التصعيد كفرع داخلي جديد.

### 17.8 رموز أسباب التحكيم

الصفوف المهيأة في `[Tickets].[ArbitrationReason]` تغطي سيناريوهات النزاع الشائعة:

| الرمز | متى يُستخدم |
|---|---|
| `UNKNOWN_SERVICE` | لا توجد قاعدة توجيه تطابق الخدمة. هبطت التذكرة في طابور افتراضي وتحتاج توجيهاً يدوياً. |
| `WRONG_SCOPE` | وجّهت التذكرة إلى هذه الوحدة، لكن الوحدة تعتقد أن العمل يخصّ وحدة أخرى. |
| `CROSS_DEPARTMENT` | إداران كلاهما يطالب بالعمل ولا يقبل أيّهما التذكرة منفرداً. |
| `MANAGER_DECISION_REQUIRED` | التوجيه واضح تقنياً، لكن القرار الإداري يحمل أبعاداً سياسية أو مالية تتطلّب تدخّل الإدارة. |

سبب التحكيم مطلوب عند استدعاء `REQUESTARBITRATION`. يُخزّن في `TicketArbitration.arbitrationReasonID_FK` ويُعرض للمحكّم ليفهم السياق.

## 18. أنواع التذاكر التشغيلية

يدعم نظام التذاكر أربعة أنواع تشغيلية، لكل نوع طول سلسلة موافقات خاص، وسلوك توجيه مختلف، وملف اتفاقية مستوى الخدمة (SLA) خاص، وقواعد وصول مختلفة. هذه الأنواع ترتبط بـ `operationalTypeID_FK` في `[Tickets].[Ticket]`. هي ليست مجرد تصنيفات. كل نوع يُحرّك سلوكاً مختلفاً في `[Tickets].[TicketSP]` أثناء `INSERTTICKET` و `REQUESTAPPROVAL` و `RESOLVETICKET`.

تختلف الأنواع في ثلاثة أبعاد:

1. **من يستطيع إنشاءها** (مستخدمون داخليون، سكان، أو كلاهما)
2. **ما سلسلة الموافقات المطلوبة** قبل بدء العمل
3. **كيف تُضبط مؤقتات اتفاقية مستوى الخدمة (SLA)** (تركيز على الاستجابة مقابل تركيز على الإنجاز)

### 18.1 SERVICE_REQUEST (طلب خدمة)

**الوصف**

طلب خدمة هو طلب رسمي من مستخدم أو ساكن للحصول على خدمة محددة مسبقاً من الكتالوج. هذا النوع هو الأكثر شيوعاً بين أنواع التذاكر. يختار مقدم الطلب خدمة معروفة، يملأ الوصف، ويوجّهها النظام عبر سلسلة الموافقات إلى الفريق المنفّذ.

أمثلة نموذجية: "إصدار شهادة سكنية"، "تحديث بيانات تواصل الساكن"، "طلب زيارة صيانة لوحدتي."

**من يستطيع الإنشاء**

- المستخدمون الداخليون: نعم
- السكان: نعم (فقط الخدمات التي فيها `[Tickets].[Service].[allowResidentRequest] = 1`)

**سلسلة الموافقات (3 خطوات)**

| الخطوة | الدور | الإجراء | ملاحظات |
|---|---|---|---|
| 1 | المشرف المباشر لمقدم الطلب | التحقق من أن الطلب مشروع | يؤكد أن الموظف يمتلك الحق في تقديم الطلب. بالنسبة للسكان، تُوافق تلقائياً على هذه الخطوة. |
| 2 | مدير وحدة الخدمة | تأكيد قدرة وحدة الخدمة على التنفيذ | يتحقق من السعة والموظفين ومدى توافق الطلب مع تعريف الخدمة. |
| 3 | المراجع المالي (إن وجد) | الموافقة على أي تكلفة | موافقة تلقائية عندما لا تحتوي الخدمة على علامة تكلفة. موافقة حقيقية فقط للخدمات المدفوعة. |

تأتي قوالب الخطوات من `[Tickets].[ApprovalStep` حيث يطابق `serviceID_FK` الخدمة المختارة. إذا لم يوجد قالب محدد، يُطبّق القالب الاحتياطي (`serviceID_FK` فارغ).

**سلوك التوجيه**

- تُوجّه التذكرة إلى `TargetDSDID_FK` من `[Tickets].[ServiceRoutingRule]` المطابق للخدمة المختارة ونوع مقدم الطلب.
- إذا لم تُعثر الخدمة في الكتالوج (`serviceID_FK` فارغ، `otherServiceText` مملوء)، تُوجّه التذكرة إلى التحكيم بدلاً من ذلك.
- بعد إتمام جميع الموافقات، تنتقل التذكرة إلى `ASSIGNED` وتصبح طابور وحدة الخدمة هو المالك الحالي.

**توقعات اتفاقية مستوى الخدمة (SLA)**

- هدف الاستجابة: 4 ساعات عمل (الافتراضي، قابل للتهيئة لكل خدمة وأولوية في `[Tickets].[ServiceSLAPolicy]`)
- هدف الإنجاز: 5 أيام عمل (الافتراضي للأولوية P3، قابل للتهيئة)
- مؤقت اتفاقية مستوى الخدمة (SLA) يتوقف أثناء خطوات الموافقة (سبب الإيقاف `WAITING_APPROVAL`)
- مؤقت اتفاقية مستوى الخدمة (SLA) يتوقف أثناء التوضيح

**وصول السكان**

نعم. يستطيع السكان تقديم طلبات خدمة من خلال نموذج الاستقبال. يُخزّن `residentInfoID_FK` الخاص بالساكن على التذكرة. عندما ينشئ الساكن التذكرة، تُوافق تلقائياً على خطوة الموافقة الأولى (المشرف المباشر) لأنه لا توجد سلسلة مشرفين لمقدمي الطلبات الخارجيين.

**قواعد الأعمال الخاصة بالنوع**

| معرّف القاعدة | القاعدة | التنفيذ |
|---|---|---|
| SR-01 | `serviceID_FK` مطلوب لطلبات الخدمة. مسار `otherServiceText` غير متاح لهذا النوع. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| SR-02 | إذا كانت `allowResidentRequest = 0` للخدمة المختارة ومقدم الطلب ساكن، يرفض الإجراء المخزّن بخطأ أعمال. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| SR-03 | مراجعة الجودة مطلوبة قبل الإغلاق (`requiresQualityReview = 1` على الخدمة). | `[Tickets].[TicketSP]` `CLOSETICKET` |
| SR-04 | خطوة الموافقة الأولى تُوافق تلقائياً عندما يكون `requesterTypeID_FK` يشير إلى نوع الساكن. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| SR-05 | إذا كانت خطوة الموافقة المالية تحمل `isRequired = 1`، تُحلّ فوراً أثناء `REQUESTAPPROVAL` دون انتظار تدخّل بشري. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |

### 18.2 DISBURSEMENT (طلب صرف)

**الوصف**

طلب الصرف هو عملية مالية داخلية. يطلب موظف إطلاق أموال، أو معالجة دفعة، أو تنفيذ تخصيص ميزانية. هذا النوع يمتلك أطول سلسلة موافقات لأنه يتعلّق بالمساءلة المالية على مستويات متعددة.

أمثلة نموذجية: "صرف إعانة سكنية للمتقدّمين المعتمدين"، "معالجة دفعة مورّد لأعمال صيانة منجزة"، "إطلاق أموال مساعدة سكنية طارئة."

**من يستطيع الإنشاء**

- المستخدمون الداخليون: نعم
- السكان: لا

**سلسلة الموافقات (4 خطوات)**

| الخطوة | الدور | الإجراء | ملاحظات |
|---|---|---|---|
| 1 | رئيس قسم مقدم الطلب | التحقق من الحاجة العملية | يؤكد أن الطلب مبرر ضمن نطاق القسم. |
| 2 | مدير الإدارة | تصريح الإنفاق | يؤكد توفر الميزانية وانسجامها مع خطط الإدارة. |
| 3 | قسم المالية (الرقابة على الميزانية) | التحقق من تخصيص الميزانية | يتأكد من وجود أموال في بند الميزانية الصحيح وأنه لا توجد حجوزات أو تعارضات تمنع الصرف. |
| 4 | قسم المالية (الخزينة) | تنفيذ الدفعة | ينفّذ الصرف الفعلي ويسجّل مرجع العملية. |

الخطوات الأربع كلها تسلسلية. يجب إتمام كل خطوة قبل فتح التي تليها. الموافقة التلقائية غير متاحة لخطوات طلب الصرف.

**سلوك التوجيه**

- تُوجّه التذكرة إلى DSD قسم المالية بعد إتمام خطوتي الموافقة الأولى والثانية.
- الخطوتان 1 و 2 تُوجّهان عبر الهيكل التنظيمي لمقدم الطلب (قسم ثم إدارة).
- الخطوتان 3 و 4 تُوجّهان إلى الوحدة المالية المحددة في حقل `approverDSDID_FK` بقالب الموافقة.
- يجب تهيئة الوحدة المالية في `[Tickets].[ApprovalStep]` لكل خدمة صرف. إذا كان القالب يفتقر إلى DSD المالي، يفشل `REQUESTAPPROVAL` بخطأ تهيئة.

**توقعات اتفاقية مستوى الخدمة (SLA)**

- هدف الاستجابة: يوم عمل واحد (طلبات الصرف تحظى باهتمام أولي سريع)
- هدف الإنجاز: 10 أيام عمل (أطول بسبب سلسلة الموافقات ذات الخطوات الأربعة ووقت معالجة البنك)
- مؤقت اتفاقية مستوى الخدمة (SLA) يتوقف أثناء كل خطوة موافقة
- مؤقت اتفاقية مستوى الخدمة (SLA) يتوقف أثناء أي توضيح (التوضيحات المالية شائعة)
- لا يوجد إيقاف لاتفاقية مستوى الخدمة (SLA) بسبب التحكيم (النزاعات على طلبات الصرف نادرة ويجب حلّها بسرعة)

**وصول السكان**

لا. طلب الصرف عملية مالية داخلية. السكان لا ينشئون تذاكر صرف أبداً. إذا احتاج ساكن دفعة ما، يقدّم الساكن طلب خدمة، ويُنشئ موظف داخلي تذكرة صرف مرتبطة كتذكرة فرعية.

**قواعد الأعمال الخاصة بالنوع**

| معرّف القاعدة | القاعدة | التنفيذ |
|---|---|---|
| DS-01 | فقط المستخدمون الداخليون يستطيعون إنشاء تذاكر الصرف. يجب أن يشير `requesterTypeID_FK` إلى `INTERNAL_USER`. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| DS-02 | `serviceID_FK` مطلوب. نوع طلب الصرف لا يدعم الخدمات "الأخرى". | `[Tickets].[TicketSP]` `INSERTTICKET` |


| DS-03 | خطوات الموافقة الأربعة إلزامية جميعها. الموافقة التلقائية (`isRequired = 1`) مرفوضة لقوالب طلب الصرف. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| DS-04 | مراجعة الجودة مطلوبة دائمًا. يُفرض `requiresQualityReview = 1` لخدمات طلب الصرف بغض النظر عن إعداد الكتالوج. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| DS-05 | يجب أن يتضمن الحل مرجع معاملة في `resolutionNotes`. يتحقق الإجراء المخزن من أن `resolutionNotes` ليس فارغًا ويستوفي حدًا أدنى للطول. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| DS-06 | لا يمكن إلغاء تذكرة طلب الصرف بعد بدء الخطوة 4 (تنفيذ الخزينة). الإلغاء ممكن فقط قبل الخطوة الأخيرة. | `[Tickets].[TicketSP]` cancel logic |

### 18.3 EXECUTION (طلب تنفيذ)

**الوصف**

طلب التنفيذ هو أمر عمل موجّه لفريق لتنفيذ مهمة مادية أو فنية. يتميّز هذا النوع بسلسلة موافقات قصيرة لأن العمل محدد عادةً، والقدرة الاستيعابية للفريق المنفّذ هي الشاغل الرئيس.

أمثلة نموذجية: "تنفيذ إصلاح سباكة في المبنى 5، الوحدة 12"، "تركيب لوحة كهربائية جديدة في مستودع الصيانة"، "دهن وتجهيز الوحدة 8B لساكن جديد."

**من يستطيع الإنشاء**

- المستخدمون الداخليون: نعم
- السكان: لا

**سلسلة الموافقات (خطوتان)**

| الخطوة | الدور | الإجراء | ملاحظات |
|---|---|---|---|
| 1 | رئيس قسم مقدّم الطلب | الموافقة على أمر العمل | يؤكد أن المهمة مطلوبة وضمن النطاق. |
| 2 | مشرف الفريق المنفّذ | قبول العمل في قائمة انتظار الفريق | يؤكد أن الفريق يملك القدرة والمهارات المناسبة. يمكنه الرفض إذا كان الفريق مثقلًا، ما يعيد التذكرة إلى الخطوة 1 لإعادة التوجيه. |

الخطوات متسلسلة. لا يمكن أن تبدأ الخطوة 2 حتى تكتمل الخطوة 1.

**سلوك التوجيه**

- تُوجّه التذكرة إلى دائرة الدعم المباشر (DSD) التابعة للفريق المنفّذ بعد الموافقة في الخطوة 1.
- تُؤخذ دائرة الدعم المباشر للفريق المنفّذ من `[Tickets].[ServiceRoutingRule].[TargetDSDID_FK]` الخاصة بالخدمة المحددة.
- إذا رفض مشرف الفريق المنفّذ في الخطوة 2، تعود التذكرة إلى قسم مقدم الطلب لإعادة التوجيه، ويُنشَّأ صف توضيح يطلب من مقدم الطلب تحديد فريق بديل.
- تبقى التذكرة في حالة `WAITING_APPROVAL` حتى تتم clearing الخطوتين، ثم تنتقل إلى `ASSIGNED`.

**توقعات اتفاقية مستوى الخدمة (SLA)**

- هدف الاستجابة: ساعتان عملان (إقرار سريع باستلام الطلب)
- هدف الحل: 3 أيام عمل (العمل المادي يستغرق وقتًا أقل من المعالجة المالية)
- يتوقف مؤقت اتفاقية مستوى الخدمة (SLA) أثناء الموافقة
- لا يتوقف مؤقت اتفاقية مستوى الخدمة (SLA) للتوضيح إلا إذا كان سبب التوضيح `MISSING_DOCUMENT` أو `MISSING_APPROVAL` (توضيحات الزيارات الميدانية يجب ألا توقف المؤقت)

**وصول السكان**

لا. تذاكر طلب التنفيذ هي أوامر عمل داخلية. السكان الذين يحتاجون إلى عمل مادي يقدّمون طلب خدمة. تنشئ مكتب الخدمة تذكرة طلب تنفيذ كتذكرة فرعية مرتبطة بطلب الخدمة الأصلي.

**قواعد العمل الخاصة بالنوع**

| معرّف القاعدة | القاعدة | التنفيذ |
|---|---|---|
| EX-01 | المستخدمون الداخليون فقط يستطيعون إنشاء تذاكر طلب التنفيذ. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| EX-02 | `serviceID_FK` مطلوب. كل تذكرة طلب تنفيذ يجب أن تشير إلى خدمة في الكتالوج تمتلك قاعدة توجيه تشير إلى دائرة الدعم المباشر للفريق المنفّذ. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| EX-03 | إذا رفض الفريق المنفّذ في الخطوة 2، تعود التذكرة إلى حالة `WAITING_APPROVAL` في الخطوة 1 مع صف توضيح. جهة التوضيح هي دائرة الدعم المباشر لمقدّم الطلب. | `[Tickets].[TicketSP]` `REJECTAPPROVAL` |
| EX-04 | يُسمح بالتذاكر الفرعية (`allowChildTickets = 1` في خدمات طلب التنفيذ). يمكن تقسيم مهمة تنفيذ كبيرة إلى مهام فرعية. | إعداد الكتالوج |
| EX-05 | مراجعة الجودة اختيارية لتذاكر طلب التنفيذ. القيمة الافتراضية هي `requiresQualityReview = 0`، لكن كتالوج الخدمات يمكنه تجاوز ذلك لمهام التنفيذ عالية القيمة. | `[Tickets].[Service]` |

### 18.4 INSPECTION (طلب معاينة)

**الوصف**

طلب المعاينة يُرسل معاينًا للتحقق من حالة ما، أو تقييم الأضرار، أو تأكيد إتمام عمل، أو تقييم وضع الساكن. يتميّز هذا النوع بأقصر سلسلة موافقات وأسرع اتفاقية مستوى الخدمة (SLA) لأن المعاينات حساسة للوقت: التأخير يمكن أن يعطل أعمالًا أخرى (مثل طلبات الصرف أو طلبات التنفيذ) التي تعتمد على نتيجة المعاينة.

أمثلة نموذجية: "معاينة أضرار المياه في الوحدة 3A"، "التحقق من إتمام الإصلاح الكهربائي في المبنى 2"، "تقييم الحالة الإنشائية للمبنى 9 قبل التجديد"، "معاينة ما قبل الإشغال لتخصيص سكني جديد."

**من يستطيع الإنشاء**

- المستخدمون الداخليون: نعم
- السكان: نعم (فقط الخدمات التي يكون فيها `allowResidentRequest = 1`)

**سلسلة الموافقات (خطوة واحدة)**

| الخطوة | الدور | الإجراء | ملاحظات |
|---|---|---|---|
| 1 | مشرف فريق المعاينة | الإقرار وتعيين معاين | يؤكد أن المعاينة ضمن النطاق ويعيّنها لمعاين محدد. هذه الخطوة أقرب إلى التعيين منها إلى الموافقة. نادرًا ما يرفض المشرف إلا إذا كان الطلب خارج صلاحيات الفريق. |

الخطوة الوحيدة تُموافق عليها تلقائيًا إذا كان قالب الموافقة للخدمة يحتوي على `isRequired = 1`، وهذا شائع في المعاينات الروتينية. في هذه الحالة، تنتقل التذكرة مباشرة إلى حالة `ASSIGNED`.

**سلوك التوجيه**

- تُوجّه التذكرة مباشرة إلى دائرة الدعم المباشر لفريق المعاينة من قاعدة توجيه الخدمة.
- نظرًا لأن سلسلة الموافقات قصيرة، تصل التذكرة غالبًا إلى حالة `ASSIGNED` خلال ساعات.
- يعيّن مشرف فريق المعاينة معاينًا محددًا عبر `AssignedToUsersID_FK`.
- إذا كشفت المعاينة عن حاجة إلى عمل إضافي، ينشئ المعاين تذكرة طلب تنفيذ فرعية مرتبطة بتذكرة المعاينة هذه.

**توقعات اتفاقية مستوى الخدمة (SLA)**

- هدف الاستجابة: ساعة عمل واحدة (التعيين السريع ضروري)
- هدف الحل: يوم عمل واحد (المعاينة نفسها يجب أن تتم بسرعة)
- مؤقت اتفاقية مستوى الخدمة (SLA) لا يتوقف عند خطوة الموافقة الوحيدة (قصيرة جدًا لتكون ذات تأثير)
- يتوقف المؤقت فقط إذا طلب فريق المعاينة توضيحًا من مقدّم الطلب (مثلًا: الوصول إلى الوحدة محظور، الساكن غير متاح)
- إذا تطلبت المعاينة زيارة متابعة، يحل المعاين هذه التذكرة وينشئ تذكرة معاينة جديدة مرتبطة كتذكرة فرعية

**وصول السكان**

نعم. يستطيع السكان طلب المعاينات مباشرة. السيناريوهات الشائعة: يلاحظ الساكن تلفًا في وحدته، يتنازع الساكن حول تقييم حالة الوحدة، يطلب الساكن معاينة ما قبل التسليم.

حين ينشئ الساكن التذكرة، تُموافق عليها خطوة الموافقة تلقائيًا (النمط نفسه المُتّبع في طلبات الخدمة التي يقدّمها السكان).

**قواعد العمل الخاصة بالنوع**

| معرّف القاعدة | القاعدة | التنفيذ |
|---|---|---|
| IN-01 | السكان يستطيعون إنشاء تذاكر معاينة فقط للخدمات التي يكون فيها `allowResidentRequest = 1`. | `[Tickets].[TicketSP]` `INSERTTICKET` |
| IN-02 | خطوة الموافقة تُموافق عليها تلقائيًا إذا كان القالب يحتوي على `isRequired = 1`. بخلاف ذلك، يجب على مشرف المعاينة الإقرار ضمن نافذة اتفاقية مستوى الخدمة (SLA) للاستجابة. | `[Tickets].[TicketSP]` `REQUESTAPPROVAL` |
| IN-03 | عند إتمام المعاينة، يجب أن يحتوي `resolutionNotes` على نتائج المعاين. يتحقق الإجراء المخزن من أن `resolutionNotes` ليس فارغًا. | `[Tickets].[TicketSP]` `RESOLVETICKET` |
| IN-04 | مراجعة الجودة غير مطلوبة افتراضيًا للمعاينات. نتيجة المعاينة نفسها تعمل كمنتج جودة. إذا كان كتالوج الخدمات يحدد `requiresQualityReview = 1`، يمر تقرير المعاينة بمراجِع ثانٍ قبل الإغلاق النهائي. | `[Tickets].[Service]` |
| IN-05 | يمكن أن تكون تذكرة المعاينة أصلًا لتذاكر طلب التنفيذ. حين يحدد المعاين عملًا يجب تنفيذه، ينشئ تذكرة طلب تنفيذ فرعية من محطة العمل. تدخل تذكرة المعاينة الأصل حالة `WAITING_CHILD`، ما يوقف مؤقت اتفاقية مستوى الخدمة (SLA) الخاص بها حتى يكتمل طلب التنفيذ. | `[Tickets].[TicketSP]` `CREATECHILDTICKET` |

### 18.5 ملخص التفاعل بين الأنواع

الأنواع الأربعة تتفاعل فيما بينها من خلال علاقات الأصل والفرع:

| النوع الأصل | النوع الفرع | السيناريو |
|---|---|---|
| SERVICE_REQUEST | INSPECTION | طلب خدمة يستدعي معاينة قبل أن يمكن تقديم الخدمة. |
| SERVICE_REQUEST | EXECUTION | طلب خدمة يتطلب عملًا ماديًا لتنفيذ الخدمة. |
| SERVICE_REQUEST | DISBURSEMENT | طلب خدمة من ساكن يؤدي إلى دفعة مالية، لذلك تُنشأ تذكرة طلب صرف داخلية. |
| INSPECTION | EXECUTION | معاينة تكشف عن عمل يجب تنفيذه. |
| INSPECTION | SERVICE_REQUEST | يحدد المعاين أن الساكن يحتاج خدمة مختلفة عمّا طُلب أصلاً. |

حين تُنشأ تذكرة فرعية من تذكرة أصل، تدخل التذكرة الأصل حالة `WAITING_CHILD`. يتوقف مؤقت اتفاقية مستوى الخدمة (SLA) للتذكرة الأصل حتى تُحل جميع التذاكر الفرعية. ينطبق ذلك بغض النظر عن الأنواع المتورطة.

الأنواع الأربعة تشترك جميعها في الجدول `[Tickets].[Ticket]` نفسه، ويتم التمييز بينها بـ `operationalTypeID_FK`. النوع هو ما يحرّك قوالب موافقات مختلفة وسياسات اتفاقية مستوى الخدمة (SLA) وفروع التحقق في الإجراءات المخزنة، لكن نموذج البيانات الأساسي موحّد. هذا يحافظ على اتساق آليات السجل واتفاقية مستوى الخدمة (SLA) والتحكيم والتوضيح عبر جميع الأنواع.


## 19. مصفوفة إعداد الصلاحيات

نظام التذاكر يتطلب إدخالات صلاحية في البنية التحتية الحالية للصلاحيات لكل صفحة وكل إجراء. يحدد هذا القسم الإدخالات المطلوبة بالضبط.

### 19.1 مراجعة معمارية الصلاحيات

مسار الصلاحيات الحالي:
- جدول `Menu` يحدد أسماء الصفحات (`menuName_E`)
- `MenuDistributor` يربط الصفحات بأنواع الموزّع
- جدول `Permission` يربط `UsersID_FK` ← صلاحية الوصول إلى `menuName_E`
- `PermissionType` يحدد أفعال الإجراءات (select، insert، update، delete، إلخ)
- `DistributorPermissionType` يربط الموزّع بأنواع الصلاحيات المسموحة لكل صفحة
- `ft_UserPagePermissions` يُرجع مجموعة النتائج الأولى عند تحميل كل صفحة
- `V_GetListUserPermission` يتحقق من إجراءات الكتابة في `Masters_CRUD`

### 19.2 أسماء صفحات التذاكر

جميع صفحات التذاكر تستخدم قيم `menuName_E` التالية:

| menuName_E | الغرض من الصفحة |
|---|---|
| `TicketCreate` | إنشاء تذكرة جديدة |
| `TicketMyTickets` | عرض التذاكر الخاصة بالمستخدم |
| `TicketInbox` | عرض قائمة الانتظار للوحدة التنظيمية المُعيَّنة |
| `TicketList` | قائمة إدارية مع فلاتر |
| `TicketWorkbench` | تفاصيل التذكرة الواحدة والإجراءات |
| `TicketQualityReview` | قائمة انتظار مراجعة الجودة |
| `ServiceCatalog` | إدارة: الخدمات والتوجيه واتفاقية مستوى الخدمة (SLA) وخطوات الموافقة |
| `TicketApprovals` | قائمة انتظار الموافقات للموافقين |
| `TicketReports` | لوحة المعلومات وتقارير مؤشرات الأداء |

### 19.3 أنواع الصلاحيات المطلوبة

يجب أن تكون إدخالات `PermissionType` هذه موجودة أو تُنشأ:

| permissionTypeName_E | الوصف | يُستخدم في |
|---|---|---|
| `select` | عرض / قراءة بيانات الصفحة | جميع الصفحات |
| `insert` | إنشاء سجلات جديدة | TicketCreate، ServiceCatalog |
| `update` | تعديل سجلات موجودة | TicketWorkbench، ServiceCatalog، TicketApprovals، TicketQualityReview |
| `delete` | حذف مُ软 للسجلات | TicketWorkbench، ServiceCatalog |
| `ASSIGNTICKET` | تعيين تذكرة لمستخدم | TicketInbox، TicketWorkbench |
| `STARTPROGRESS` | بدء العمل على تذكرة | TicketWorkbench |
| `RESOLVETICKET` | وضع علامة تم الحل على التذكرة | TicketWorkbench |
| `CLOSETICKET` | الإغلاق النهائي بعد مراجعة الجودة | TicketQualityReview |
| `REQUESTARBITRATION` | طلب تحكيم في نزاع | TicketWorkbench |
| `DECIDEARBITRATION` | البت في نتيجة التحكيم | TicketWorkbench |
| `REQUESTCLARIFICATION` | طلب معلومات من مقدّم الطلب أو الفني | TicketWorkbench |
| `RESPONDCLARIFICATION` | الرد على طلب التوضيح | TicketWorkbench |
| `CREATECHILDTICKET` | إنشاء تذكرة فرعية / متوازية | TicketWorkbench |
| `PAUSETICKET` | إيقاف مؤقت اتفاقية مستوى الخدمة (SLA) | TicketWorkbench |
| `RESUMETICKET` | استئناف مؤقت اتفاقية مستوى الخدمة (SLA) | TicketWorkbench |
| `APPROVETICKET` | الموافقة على خطوة موافقة | TicketApprovals |
| `REJECTAPPROVAL` | رفض خطوة موافقة | TicketApprovals |
| `REVIEWQUALITY` | قبول / رفض / إعادة تذكرة تم حلها | TicketQualityReview |
| `INSERTROUTINGRULE` | إضافة قاعدة توجيه | ServiceCatalog |
| `UPDATEROUTINGRULE` | تعديل قاعدة توجيه | ServiceCatalog |
| `DELETEROUTINGRULE` | حذف قاعدة توجيه | ServiceCatalog |
| `INSERTSLAPOLICY` | إضافة سياسة اتفاقية مستوى الخدمة (SLA) | ServiceCatalog |
| `UPDATESLAPOLICY` | تعديل سياسة اتفاقية مستوى الخدمة (SLA) | ServiceCatalog |
| `DELETESLAPOLICY` | حذف سياسة اتفاقية مستوى الخدمة (SLA) | ServiceCatalog |
| `INSERTAPPROVALSTEP` | إضافة خطوة في سلسلة الموافقات | ServiceCatalog |
| `UPDATEAPPROVALSTEP` | تعديل خطوة في سلسلة الموافقات | ServiceCatalog |
| `DELETEAPPROVALSTEP` | حذف خطوة من سلسلة الموافقات | ServiceCatalog |
| `print` | طباعة تذكرة أو تقرير | TicketWorkbench، TicketReports |
| `export` | تصدير البيانات إلى Excel/PDF | TicketList، TicketReports |

### 19.4 مصفوفة الصلاحيات حسب الصفحة

#### 19.4.1 TicketCreate

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `insert` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.2 TicketMyTickets

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.3 TicketInbox

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | — | ✅ | ✅ | ✅ | ✅ |
| `ASSIGNTICKET` | — | — | ✅ | ✅ | ✅ |

#### 19.4.4 TicketList

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | — | — | ✅ | ✅ | ✅ |
| `export` | — | — | ✅ | ✅ | ✅ |

#### 19.4.5 TicketWorkbench

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | ✅ (خاصة) | ✅ (مُعيَّنة) | ✅ (الفريق) | ✅ (الكل) | ✅ |
| `update` | — | ✅ | ✅ | ✅ | ✅ |
| `ASSIGNTICKET` | — | — | ✅ | ✅ | ✅ |
| `STARTPROGRESS` | — | ✅ | ✅ | ✅ | ✅ |
| `RESOLVETICKET` | — | ✅ | ✅ | ✅ | ✅ |
| `REQUESTARBITRATION` | — | ✅ | ✅ | ✅ | ✅ |
| `DECIDEARBITRATION` | — | — | ✅ | ✅ | ✅ |
| `REQUESTCLARIFICATION` | — | ✅ | ✅ | ✅ | ✅ |
| `RESPONDCLARIFICATION` | — | ✅ | ✅ | ✅ | ✅ |
| `CREATECHILDTICKET` | — | — | ✅ | ✅ | ✅ |
| `PAUSETICKET` | — | — | ✅ | ✅ | ✅ |
| `RESUMETICKET` | — | — | ✅ | ✅ | ✅ |
| `print` | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 19.4.6 TicketQualityReview

| PermissionType | مقدّم الطلب | الفني | المشرف | المدير | المسؤول |
|---|---|---|---|---|---|
| `select` | — | — | — | ✅ | ✅ |
| `REVIEWQUALITY` | — | — | — | ✅ | ✅ |
