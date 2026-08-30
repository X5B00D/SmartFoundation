(function () {
    "use strict";

    const unsafeMethods = new Set(["POST", "PUT", "PATCH", "DELETE"]);

    function getRequestVerificationToken() {
        return document.querySelector('meta[name="request-verification-token"]')
            ?.getAttribute("content") || "";
    }

    function isSameOrigin(url) {
        try {
            return new URL(url, window.location.href).origin === window.location.origin;
        } catch {
            return false;
        }
    }

    window.getRequestVerificationToken = getRequestVerificationToken;

    const nativeFetch = window.fetch.bind(window);
    window.fetch = function (input, init) {
        const request = input instanceof Request ? input : null;
        const method = String(init?.method || request?.method || "GET").toUpperCase();
        const url = request?.url || input;
        if (!unsafeMethods.has(method) || !isSameOrigin(url)) return nativeFetch(input, init);

        const token = getRequestVerificationToken();
        const headers = new Headers(init?.headers || request?.headers || undefined);
        if (token && !headers.has("RequestVerificationToken")) headers.set("RequestVerificationToken", token);
        return nativeFetch(input, { ...init, method, headers });
    };

    const nativeOpen = XMLHttpRequest.prototype.open;
    const nativeSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function (method, url) {
        this.__sfUnsafeRequest = unsafeMethods.has(String(method || "GET").toUpperCase()) && isSameOrigin(url);
        return nativeOpen.apply(this, arguments);
    };
    XMLHttpRequest.prototype.send = function () {
        const token = getRequestVerificationToken();
        if (this.__sfUnsafeRequest && token) this.setRequestHeader("RequestVerificationToken", token);
        return nativeSend.apply(this, arguments);
    };

    document.addEventListener("click", async function (event) {
        const logoutLink = event.target.closest('a[href="/Login/Logout"]');
        if (!logoutLink) return;

        event.preventDefault();
        const response = await window.fetch("/Login/Logout", { method: "POST", credentials: "same-origin" });
        if (response.ok || response.redirected) window.location.assign(response.url || "/Login?logout=2");
    });
})();
