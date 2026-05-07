(function () {
    function getElement(id) {
        return document.getElementById(id);
    }

    function resetLoginButton() {
        const btn = getElement("btnLogin");
        const txt = getElement("btnText");
        const spn = getElement("btnSpinner");

        if (btn) btn.disabled = false;
        if (txt) txt.style.display = "inline-flex";
        if (spn) spn.style.display = "none";
    }

    function initLoginPage() {
        const nationalId = getElement("txtNationalID");
        const rememberMe = getElement("remember-me");
        const password = getElement("txtPassword");
        const toggle = getElement("togglePassword");
        const eye = getElement("eyeIcon");
        const form = getElement("loginForm");
        const btnLogin = getElement("btnLogin");
        const btnText = getElement("btnText");
        const spinner = btnLogin ? btnLogin.querySelector(".spinner-border") : null;
        const config = getElement("login-page-config");
        const currentYear = getElement("currentYear");

        if (currentYear) {
            currentYear.textContent = new Date().getFullYear().toString();
        }

        if (window.toastr) {
            window.toastr.options = {
                closeButton: true,
                progressBar: true,
                positionClass: "toast-top-center",
                timeOut: 7500,
                rtl: true
            };

            const messageType = (config?.dataset.messageType || "").trim();
            const message = (config?.dataset.message || "").trim();
            if (messageType && message && typeof window.toastr[messageType] === "function") {
                window.toastr[messageType](message);
            }
        }

        if (nationalId) {
            nationalId.addEventListener("input", function () {
                this.value = this.value.replace(/[^0-9]/g, "");
            });
        }

        if (toggle && password && eye) {
            toggle.addEventListener("click", function () {
                const isPwd = password.type === "password";
                password.type = isPwd ? "text" : "password";
                eye.classList.toggle("fa-eye");
                eye.classList.toggle("fa-eye-slash");
            });
        }

        const savedNationalId = localStorage.getItem("rememberedNationalID");
        if (savedNationalId && nationalId && rememberMe) {
            nationalId.value = savedNationalId;
            rememberMe.checked = true;

            if (password) password.focus();
        }

        if (form && btnLogin) {
            form.addEventListener("submit", function () {
                if (rememberMe && rememberMe.checked && nationalId) {
                    localStorage.setItem("rememberedNationalID", nationalId.value);
                } else {
                    localStorage.removeItem("rememberedNationalID");
                }

                if (btnText) btnText.style.display = "none";
                if (spinner) spinner.style.display = "inline-flex";
                btnLogin.disabled = true;
            });
        }

        resetLoginButton();
    }

    document.addEventListener("DOMContentLoaded", initLoginPage);
    window.addEventListener("pageshow", resetLoginButton);
})();
