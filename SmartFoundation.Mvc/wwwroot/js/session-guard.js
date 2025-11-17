(function () {
    // --- CONFIG ---
    const INACTIVITY_LIMIT_MS   = 3 * 60 * 1000;  // total inactivity (e.g., 3 minutes)
    const WARNING_THRESHOLD_MS  = 2 * 60 * 1000;  // warn after 2 minutes of inactivity
    const KEEPALIVE_INTERVAL_MS = 1 * 60 * 1000;  // keep-alive at most every 1 minute
    const ACTIVITY_EVENTS       = ["mousemove","mousedown","keydown","scroll","touchstart","touchmove","click"];
    const ACTIVITY_KEY          = "sf_activity_ping";

    // --- STATE ---
    let lastActivity       = Date.now();
    let lastKeepAliveSent  = 0;
    let warningShown       = false;
    let loggedOut          = false;
    let toastrReady        = false;
    let waitAttempts       = 0;
    let currentWarningToast = null; // track the specific inactivity toast

    // timers
    let warnTimerId = null;
    let logoutTimerId = null;

    // --- TOASTR INIT (robust) ---
    function initToastr() {
        if (!window.toastr) return false;
        if (!toastrReady) {
            toastr.options = {
                closeButton: true,
                progressBar: true,
                positionClass: "toast-top-center",
                timeOut: 6000,
                rtl: true
            };
            toastrReady = true;
            console.debug("[session-guard] Toastr initialized.");
        }
        return true;
    }

    function waitForToastr(maxAttempts = 40, intervalMs = 300) {
        if (initToastr()) return;
        if (waitAttempts >= maxAttempts) {
            console.warn("[session-guard] Toastr not found after waiting. Will fallback to alert.");
            return;
        }
        waitAttempts++;
        setTimeout(() => waitForToastr(maxAttempts, intervalMs), intervalMs);
    }

    waitForToastr();

    // --- TIMERS ---
    function clearTimers() {
        if (warnTimerId) { clearTimeout(warnTimerId); warnTimerId = null; }
        if (logoutTimerId) { clearTimeout(logoutTimerId); logoutTimerId = null; }
    }

    function scheduleTimers() {
        clearTimers();
        const now = Date.now();
        const msSinceActivity = now - lastActivity;

        const msToWarn = Math.max(0, WARNING_THRESHOLD_MS - msSinceActivity);
        const msToLogout = Math.max(0, INACTIVITY_LIMIT_MS - msSinceActivity);

        warnTimerId = setTimeout(() => {
            // Only warn if we still haven't exceeded logout at this moment
            if (!loggedOut) showWarning();
        }, msToWarn);

        logoutTimerId = setTimeout(() => {
            if (!loggedOut) forceLogout();
        }, msToLogout);
    }

    // --- ACTIVITY MARKER ---
    function markActivity() {
        const now = Date.now();
        lastActivity = now;

        // Hide the inactivity warning toast on any user action
        if (warningShown && currentWarningToast && window.toastr) {
            toastr.clear(currentWarningToast);
            currentWarningToast = null;
        }
        warningShown = false; // allow future warning

        localStorage.setItem(ACTIVITY_KEY, now.toString());
        maybeKeepAlive(now);
        scheduleTimers();
    }

    // --- KEEPALIVE ---
    function maybeKeepAlive(now) {
        if (now - lastKeepAliveSent < KEEPALIVE_INTERVAL_MS) return;
        lastKeepAliveSent = now;

        fetch("/session/keepalive", {
            method: "POST",
            headers: { "Accept": "application/json" },
            cache: "no-store"
        }).then(r => {
            if (r.status === 401 && !loggedOut) {
                forceLogout();
            }
        }).catch(() => {
            // Silent; network glitch will retry on next activity.
        });
    }

    // --- WARNING / LOGOUT ---
    function showWarning() {
        if (warningShown || loggedOut) return;
        // If we already passed logout threshold somehow, skip warning
        if (Date.now() - lastActivity >= INACTIVITY_LIMIT_MS) {
            forceLogout();
            return;
        }

        warningShown = true;

        if (toastrReady && window.toastr) {
            // Scoped container + custom class so CSS applies only here
            currentWarningToast = toastr.warning(
                "áÃãÇä ÍÓÇÈß æáÚÏã æÌæÏ äÔÇØ Úáì ÇáäÙÇã ÓíÊã ÇäåÇÁ ÇáÌáÓÉ ",
                "ÊÍÐíÑ",
                {
                    timeOut: 0,
                    extendedTimeOut: 0,
                    tapToDismiss: false,
                    closeButton: true,
                    progressBar: true,
                    positionClass: "toast-top-center",
                    containerId: "sf-session-toast",
                    toastClass: "toast toast-session-warning",
                    rtl: true
                }
            );
        } else {
            alert("áÃãÇä ÍÓÇÈß æáÚÏã æÌæÏ äÔÇØ Úáì ÇáäÙÇã ÓíÊã ÇäåÇÁ ÇáÌáÓÉ ");
        }
    }

    function forceLogout() {
        if (loggedOut) return;
        loggedOut = true;
        clearTimers();
        fetch("/session/logout", { method: "POST" })
            .finally(() => window.location.href = "/Login");
    }

    // --- EVENT LISTENERS ---
    ACTIVITY_EVENTS.forEach(ev =>
        window.addEventListener(ev, markActivity, { passive: true })
    );

    window.addEventListener("storage", e => {
        if (e.key === ACTIVITY_KEY && e.newValue) {
            const val = parseInt(e.newValue, 10);
            if (!isNaN(val)) {
                lastActivity = val;
                if (warningShown && currentWarningToast && window.toastr) {
                    toastr.clear(currentWarningToast);
                    currentWarningToast = null;
                }
                warningShown = false;
                scheduleTimers();
            }
        }
    });

    // If tab becomes visible after long background, re-evaluate and schedule
    document.addEventListener("visibilitychange", () => {
        if (document.visibilityState === "visible") scheduleTimers();
    });

    // --- INITIALIZE ---
    markActivity(); // sets lastActivity + schedules timers
    console.debug("[session-guard] Loaded.");
})();