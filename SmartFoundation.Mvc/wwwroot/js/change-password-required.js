"use strict";

document.addEventListener("DOMContentLoaded", () => {
    const form = document.getElementById("change-password-required-form");
    const error = document.getElementById("password-error");
    if (!form || !error) return;

    const showError = message => {
        error.textContent = message;
        error.classList.remove("hidden");
    };

    form.addEventListener("submit", async event => {
        event.preventDefault();
        error.classList.add("hidden");

        const currentPassword = form.currentPassword.value.trim();
        const newPassword = form.newPassword.value.trim();
        const confirmPassword = form.confirmPassword.value.trim();

        if (!currentPassword || !newPassword || !confirmPassword) {
            showError("جميع الحقول مطلوبة.");
            return;
        }
        if (newPassword !== confirmPassword) {
            showError("كلمة المرور الجديدة وتأكيدها غير متطابقين.");
            return;
        }
        if (newPassword.length < 8 || !/[A-Z]/.test(newPassword) || !/[a-z]/.test(newPassword) || !/[0-9]/.test(newPassword)) {
            showError("كلمة المرور الجديدة لا تحقق المتطلبات.");
            return;
        }
        if (currentPassword === newPassword) {
            showError("كلمة المرور الجديدة يجب أن تختلف عن الحالية.");
            return;
        }

        const submitButton = form.querySelector('button[type="submit"]');
        if (submitButton) submitButton.disabled = true;

        try {
            const response = await fetch("/Login/ChangePassword", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Requested-With": "XMLHttpRequest"
                },
                body: JSON.stringify({ oldPassword: currentPassword, newPassword })
            });
            const result = await response.json();
            if (!response.ok || !result.success) {
                showError(result.message || "تعذر تغيير كلمة المرور.");
                return;
            }

            window.location.replace(result.redirectUrl || "/Login?logout=2");
        } catch {
            showError("تعذر الاتصال بالخادم.");
        } finally {
            if (submitButton) submitButton.disabled = false;
        }
    });
});
