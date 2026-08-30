# برومبتات توثيق SmartFoundation

يحتوي هذا المجلد على برومبت مستقل لكل مرحلة من مشروع التوثيق. المراحل 1–8 و7A مكتملة وقت إنشاء هذا الفهرس، والمرحلة التالية هي 9.

## نقطة الاستكمال

- آخر مرحلة مكتملة: `08 - توثيق IncomeSystem`.
- المرحلة التالية: `09 - توثيق ElectronicBillSystem`.
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
- `09` إلى `15`: مراحل متبقية.

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
