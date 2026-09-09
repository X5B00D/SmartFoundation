# برومبتات توثيق SmartFoundation

يحتوي هذا المجلد على برومبت مستقل لكل مرحلة من مشروع التوثيق. اكتمل التوثيق وإغلاق إزالة المكون المستبعد بتاريخ 2026-08-30، والمرحلة التالية هي Final Security Assessment.

## مصدر الحقيقة الحالي

مصدر الحقيقة لأي إعادة توليد مستقبلية هو: Current Source Code + Current SQL Project + Current verified Live DATACORE state. المكونات المحذوفة لا تُعرض كمعمارية أو ميزة حالية، ولا يجوز ذكرها إلا ضمن Historical Changes مصنفة بوضوح.

## نقطة الاستكمال

- آخر مرحلة مكتملة: `documentation_closure_after_component_removal`.
- **ملاحظة تاريخية:** كانت المرحلة التالية عند إغلاق التوثيق السابق هي `Final Security Assessment` بالترتيب: SAST، SCA، SBOM، ZAP DAST، Manual Security Tests، OWASP Compliance Matrix. اكتملت هذه الأنشطة لاحقًا ضمن نطاقاتها للإصدار 1.0.0، بينما لم ينفذ IAST ضمن نطاق فريق التطوير.
- ملف الحالة المعتمد: `Documentation/Documentation-Progress.json`.
- مصدر حالة الفجوات المعتمد: `Documentation/security-gap-register.md` و`Documentation/security-gap-status.md`.
- الحالة الرسمية بتاريخ 2026-08-24: جميع الفجوات 01–24 مغلقة؛ TOTAL 24، CLOSED 24، OPEN 0، DEFERRED 0، IN PROGRESS 0.
- نتائج العمل: `Documentation/Work/`.
- الرسومات: `Documentation/Diagrams/`.
- أدلة المستخدم: `Documentation/UserManual/`.

## قواعد التسليم للزميل

1. يفتح الزميل المستودع نفسه ويقرأ `AGENTS.md` و`Documentation/Documentation-Progress.json` أولاً.
   ويقرأ ملفي سجل الفجوات المعتمدين قبل إنشاء أو تحديث أي توثيق أمني أو تشغيلي.
2. ينفذ ملف المرحلة التالية فقط في محادثة مستقلة.
3. الكود النشط هو مصدر سلوك التطبيق.
4. قاعدة `DATACORE` الحية هي مصدر SQL النهائي، و`SmartFoundation.Database` Snapshot للمقارنة فقط.
5. جميع استعلامات القاعدة قراءة فقط، ولا تنفذ Business Stored Procedures.
6. لا تعدل أي ملف خارج `Documentation/` أثناء التوثيق.
7. لا تشغل مرحلتين بالتوازي لأنهما تحدثان ملف التقدم نفسه.

## ترتيب الملفات

- `01` إلى `08`: مراحل مكتملة.
- `07A`: مصالحة تعريفات SQL السابقة مع القاعدة الحية، وهي مكتملة.
- `09` إلى `15`: مراحل مكتملة ومحفوظة لإعادة التوليد وفق مصدر الحقيقة الحالي.

## الرفع إلى GitHub

ارفع مجلد `Documentation/` فقط إذا أردت فصل التوثيق عن تغييرات النظام الحالية. توجد تغييرات أخرى في Worktree لا تخص هذه المهمة، لذلك لا تستخدم `git add .`.

الأوامر المقترحة بعد المراجعة:

```powershell
git add -- Documentation
git status --short
git commit -m "docs: add SmartFoundation documentation through stage 8"
git push
```

لا تحفظ Connection Strings أوPasswords أوTokens أوبيانات مستخدمين في المستودع.
