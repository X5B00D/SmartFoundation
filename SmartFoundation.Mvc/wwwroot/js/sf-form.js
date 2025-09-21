//  تسجيل مكون Alpine للنموذج
(function () {
    const register = () => {
        Alpine.data('smartForm', () => ({
            loading: false,
            message: '',
            success: true,
            show: false,

            //  دالة إرسال النموذج (ترسل JSON)
            async submitForm(actionUrl = "/smart/execute", method = "POST", event) {
                if (event) event.preventDefault();

                this.loading = true;
                this.show = false;

                try {
                    const form = event?.target || document.querySelector('form');
                    if (!form) throw new Error("⚠️ لم يتم العثور على النموذج");

                    if (!form.reportValidity()) {
                        this.showMessage("⚠️ يرجى تعبئة جميع الحقول بشكل صحيح", false);
                        return;
                    }

                    const formData = new FormData(form);
                    const params = Object.fromEntries(formData.entries());

                    const smartRequest = {
                        Component: "Form",
                        SpName: form.getAttribute('data-sp') || 'sp_SmartFormDemo',
                        Operation: form.getAttribute('data-operation') || 'insert',
                        Params: params,
                        Meta: {}
                    };

                    const response = await fetch(actionUrl, {
                        method,
                        headers: {
                            'Content-Type': 'application/json',
                            'Accept': 'application/json'
                        },
                        body: JSON.stringify(smartRequest)
                    });

                    const result = await response.json();

                    
                    if (result.success) {
                        this.showMessage(result.message || "✅ تم حفظ البيانات بنجاح!", true);
                        document.dispatchEvent(new CustomEvent("form-saved", { detail: result }));
                    } else {
                        this.showMessage(result.error || result.message || "⚠️ حدث خطأ أثناء الحفظ", false);
                    }
                } catch (error) {
                    console.error("submitForm error:", error);
                    this.showMessage("⚠️ حدث خطأ في الاتصال بالسيرفر", false);
                } finally {
                    this.loading = false;
                }
            },

            //دالة عرض الرسائل (نجاح/خطأ)
            showMessage(message, isSuccess = true) {
                this.message = message;
                this.success = isSuccess;
                this.show = true;
                setTimeout(() => { this.show = false; }, 5000);
            }
        }));
    };

    if (window.Alpine) register();
    else document.addEventListener("alpine:init", register);
})();

//  دالة عامة للتوستر
function toast(message, success = true) {
    const elements = document.querySelectorAll('[x-data]');
    let found = false;
    for (const el of elements) {
        const alpineData = el._x_dataStack?.[0];
        if (alpineData && typeof alpineData.showMessage === 'function') {
            alpineData.showMessage(message, success);
            found = true;
            break;
        }
    }
    if (!found) alert(message);
}

//  دالة إرسال النموذج العامة (خارج Alpine) – JSON
async function submitForm(actionUrl = "/smart/execute", method = "POST", formId = null) {
    try {
        let form = formId ? document.getElementById(formId) : document.querySelector("form");
        if (!form) throw new Error("⚠️ لم يتم العثور على أي فورم");

        if (!form.reportValidity()) {
            return { success: false, error: "⚠️ يرجى تعبئة جميع الحقول بشكل صحيح" };
        }

        const formData = new FormData(form);
        const params = Object.fromEntries(formData.entries());

        const body = {
            Component: "Form",
            SpName: form.getAttribute("data-sp") || "sp_SmartFormDemo",
            Operation: form.getAttribute("data-operation") || "insert",
            Params: params,
            Meta: {}
        };

        const resp = await fetch(actionUrl, {
            method,
            headers: { "Content-Type": "application/json", "Accept": "application/json" },
            body: JSON.stringify(body)
        });

        const json = await resp.json();

        if (json.success ?? resp.ok) {
            //  هنا برضه نعرض رسالة السيرفر لو موجودة
            toast(json.message || "✅ تم حفظ البيانات بنجاح!", true);
            document.dispatchEvent(new CustomEvent("form-saved", { detail: json }));
        } else {
            toast(json.error || json.message || "⚠️ حدث خطأ أثناء الحفظ", false);
        }

        return { success: json.success ?? resp.ok, error: json.error, meta: json.meta };
    } catch (e) {
        console.error("submitForm error:", e);
        toast("⚠️ حدث خطأ في الاتصال بالسيرفر", false);
        return { success: false, error: "⚠️ حدث خطأ في الاتصال بالسيرفر" };
    }
}

//  دوال إضافية
function cancelForm() { if (window.history.length > 1) history.back(); }
function editForm() { console.log("editForm: افتح وضع التعديل"); }
function deleteForm() { console.log("deleteForm: نفّذ تأكيد ثم submitForm('/smart/execute', 'POST', 'myFormId')"); }
