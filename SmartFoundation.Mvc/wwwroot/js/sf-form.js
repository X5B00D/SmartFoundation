// wwwroot/js/sf-form.js

// ✅ دالة عامة للتوستر (تظهر رسالة نجاح/خطأ)
function toast(message, success = true) {
    const t = document.querySelector('[x-data]');
    if (!t || !t.__x || !t.__x.$data) {
        alert(message); // fallback لو Alpine غير محمّل
        return;
    }
    t.__x.$data.msg = message;
    t.__x.$data.success = success;
    t.__x.$data.show = true;
    setTimeout(() => { t.__x.$data.show = false }, 3000);
}

// ✅ دالة إرسال النموذج
async function submitForm(actionUrl, method = "POST", formId = null) {
    try {
        // 🔍 جلب الفورم: إما بالـ id أو أقرب فورم للزر أو أول فورم بالصفحة
        let form = null;
        if (formId) {
            form = document.getElementById(formId);
        }
        if (!form) {
            const el = document.activeElement;
            form = el && el.closest ? el.closest("form") : null;
        }
        if (!form) form = document.querySelector("form");
        if (!form) throw new Error("⚠️ لم يتم العثور على أي فورم");

        // ✅ تحقق من صحة الحقول (required/pattern/…)
        if (!form.reportValidity()) {
            return {
                success: false,
                error: "⚠️ يرجى تعبئة جميع الحقول بشكل صحيح"
            };
        }

        // 🔧 تحديث action/method
        if (actionUrl) form.action = actionUrl;
        form.method = (method || "POST").toUpperCase();

        // 📝 جمع البيانات
        const formData = new FormData(form);

        // 🚀 إرسال البيانات
        const resp = await fetch(form.action, {
            method: form.method,
            body: formData
        });

        // 📦 قراءة الاستجابة
        const contentType = resp.headers.get("content-type") || "";
        if (contentType.includes("application/json")) {
            const json = await resp.json();

            // 🔔 لو العملية ناجحة → نطلق الحدث form-saved
            if (json.success ?? resp.ok) {
                document.dispatchEvent(new CustomEvent("form-saved", { detail: json }));
            }

            return {
                success: json.success ?? resp.ok,
                error: json.error,
                meta: json.meta
            };
        } else {
            // لو رجع HTML أو نص عادي
            const text = await resp.text();
            if (resp.ok) {
                // 🔔 إطلاق الحدث في حالة نجاح غير JSON
                document.dispatchEvent(new CustomEvent("form-saved", { detail: { raw: text } }));
            }
            return {
                success: resp.ok,
                error: resp.ok ? null : text,
                meta: { raw: text }
            };
        }
    } catch (e) {
        console.error("submitForm error:", e);
        return {
            success: false,
            error: "⚠️ حدث خطأ في الاتصال بالسيرفر"
        };
    }
}

// ✅ دالة إلغاء الفورم (اختيارية)
function cancelForm() {
    if (window.history.length > 1) history.back();
}

// ✅ دوال إضافية (مكانها للتوسع لاحقًا)
function editForm() {
    console.log("editForm: افتح وضع التعديل");
}
function deleteForm() {
    console.log("deleteForm: نفّذ تأكيد ثم submitForm(null, 'POST', true, 'sp_Delete')");
}
