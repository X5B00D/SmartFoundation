(function () {
    function applyToastrOptions() {
        if (!window.toastr) return;
        window.toastr.options.positionClass = "toast-top-center";
    }

    function initializeThemeToggle() {
        const btn = document.getElementById("theme-toggle");
        const darkIcon = document.getElementById("theme-toggle-dark-icon");
        const lightIcon = document.getElementById("theme-toggle-light-icon");

        if (!btn || !darkIcon || !lightIcon) return;

        const prefersDark =
            localStorage.getItem("color-theme") === "dark" ||
            (!("color-theme" in localStorage) &&
                window.matchMedia("(prefers-color-scheme: dark)").matches);

        if (prefersDark) {
            document.documentElement.classList.add("dark");
            lightIcon.classList.remove("hidden");
            darkIcon.classList.add("hidden");
        } else {
            document.documentElement.classList.remove("dark");
            darkIcon.classList.remove("hidden");
            lightIcon.classList.add("hidden");
        }

        btn.addEventListener("click", () => {
            darkIcon.classList.toggle("hidden");
            lightIcon.classList.toggle("hidden");

            if (localStorage.getItem("color-theme")) {
                if (localStorage.getItem("color-theme") === "light") {
                    document.documentElement.classList.add("dark");
                    localStorage.setItem("color-theme", "dark");
                } else {
                    document.documentElement.classList.remove("dark");
                    localStorage.setItem("color-theme", "light");
                }
            } else if (document.documentElement.classList.contains("dark")) {
                document.documentElement.classList.remove("dark");
                localStorage.setItem("color-theme", "light");
            } else {
                document.documentElement.classList.add("dark");
                localStorage.setItem("color-theme", "dark");
            }
        });
    }

    function removeQueryStringFromAddress() {
        if (window.location.search.length <= 0) return;

        const cleanUrl = window.location.origin + window.location.pathname;
        window.history.replaceState({}, document.title, cleanUrl);
    }

    window.showMainLoading = function () {
        const el = document.getElementById("main-loading");
        if (!el) return;

        el.style.display = "flex";
    };

    window.hideMainLoading = function () {
        const el = document.getElementById("main-loading");
        if (el) {
            el.style.display = "none";
        }

        document.body.style.pointerEvents = "";
    };

    document.addEventListener("DOMContentLoaded", function () {
        applyToastrOptions();
        initializeThemeToggle();
        removeQueryStringFromAddress();
    });
})();
