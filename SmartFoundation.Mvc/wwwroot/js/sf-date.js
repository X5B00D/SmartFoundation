(function () {
    "use strict";

    // ===== Helpers =====
    const MS_DAY = 86400000;
    const qs = (s, r = document) => r.querySelector(s);
    const qsa = (s, r = document) => Array.from(r.querySelectorAll(s));
    const pad2 = n => String(n).padStart(2, "0");
    const isISO = v => /^\d{4}-\d{2}-\d{2}$/.test(v || "");

    const ARAB = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
    const toLatnDigits = s => (s || "").replace(/[٠-٩]/g, ch => String(ARAB.indexOf(ch)));
    const digitsOnly = s => (toLatnDigits(s).match(/\d/g) || []).join("");
    const countDigits = s => (toLatnDigits(s).match(/\d/g) || []).length;

    const toISO = (date) => {
        if (!(date instanceof Date) || Number.isNaN(+date)) return "";
        return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
    };
    const fromISO = (v) => {
        if (!isISO(v)) return null;
        const [y, m, d] = v.split("-").map(Number);
        const dt = new Date(y, m - 1, d);
        return (dt.getFullYear() === y && dt.getMonth() === m - 1 && dt.getDate() === d) ? dt : null;
    };
    const clampDate = (dt, min, max) => {
        let t = +dt;
        if (min instanceof Date && !Number.isNaN(+min)) t = Math.max(t, +min);
        if (max instanceof Date && !Number.isNaN(+max)) t = Math.min(t, +max);
        return new Date(t);
    };

    // ===== Formatting (info) =====
    function fullText(date, { calendar = "gregory", lang = "ar", numerals = "latn", showDay = true } = {}) {
        if (!(date instanceof Date) || Number.isNaN(+date)) return "—";
        const opts = {
            calendar,
            weekday: showDay ? "long" : undefined,
            year: "numeric", month: "long", day: "numeric",
            numberingSystem: numerals === "arab" ? "arab" : "latn",
        };
        try { return new Intl.DateTimeFormat(`${lang}-u-ca-${calendar}`, opts).format(date); }
        catch { return toISO(date); }
    }
    function hijriISO(date) {
        try {
            const p = new Intl.DateTimeFormat("ar-SA-u-ca-islamic", { year: "numeric", month: "2-digit", day: "2-digit", numberingSystem: "latn" }).formatToParts(date);
            const y = p.find(x => x.type === "year")?.value;
            const m = p.find(x => x.type === "month")?.value;
            const d = p.find(x => x.type === "day")?.value;
            return (y && m && d) ? `${y}-${m}-${d}` : "";
        } catch { return ""; }
    }

    // ===== Config =====
    function cfgOf(input) {
        return {
            fmt: (input.getAttribute("data-date-format") || "yyyy-mm-dd").toLowerCase(),
            calendar: (input.dataset.calendar || "gregorian").toLowerCase(),   // gregorian | hijri | both
            mirrorName: (input.dataset.mirrorName || "").trim(),
            mirrorCalendar: (input.dataset.mirrorCalendar || "hijri").toLowerCase(),
            lang: (input.dataset.displayLang || "ar").toLowerCase(),
            numerals: (input.dataset.numerals || "latn").toLowerCase(),
            showDayName: (input.dataset.showDayName || "true") === "true",
            defaultToday: (input.dataset.defaultToday || "false") === "true",
            minDate: fromISO((input.dataset.minDate || "").trim()) || null,
            maxDate: fromISO((input.dataset.maxDate || "").trim()) || null,
            group: input.dataset.rangeGroup || null,
            role: input.dataset.rangeRole || null, // start | end
            daysTarget: (input.dataset.daysTarget || "").trim()
        };
    }

    // ===== Mask (stable caret) =====
    const maskedFromDigits = (d) => {
        if (d.length <= 4) return d;
        if (d.length <= 6) return `${d.slice(0, 4)}-${d.slice(4)}`;
        return `${d.slice(0, 4)}-${d.slice(4, 6)}-${d.slice(6)}`;
    };
    const indexAfterNthDigit = (masked, n) => {
        if (n <= 0) return 0;
        let c = 0;
        for (let i = 0; i < masked.length; i++) {
            if (/\d/.test(masked[i])) c++;
            if (c === n) return i + 1;
        }
        return masked.length;
    };
    function applyMaskKeepCaret(input) {
        const sel = input.selectionStart || 0;
        const preDigits = countDigits(input.value.slice(0, sel));
        const d = digitsOnly(input.value).slice(0, 8);
        const masked = maskedFromDigits(d);
        input.value = masked;
        const newCaret = indexAfterNthDigit(masked, preDigits);
        input.setSelectionRange(newCaret, newCaret);
        return masked;
    }

    // ===== Info & mirror =====
    function updateInfoBox(input, date, cfg) {
        const box = qs(`#${input.id}__info`); if (!box) return;
        const gEl = qs("[data-greg-full]", box);
        const hEl = qs("[data-hijri-full]", box);
        const wantG = cfg.calendar === "gregorian" || cfg.calendar === "both";
        const wantH = cfg.calendar === "hijri" || cfg.calendar === "both";
        const put = (el, txt) => { if (el) el.textContent = txt; };

        if (!date) { put(gEl, "—"); put(hEl, "—"); return; }
        if (gEl) put(gEl, wantG ? fullText(date, { calendar: "gregory", lang: cfg.lang, numerals: cfg.numerals, showDay: cfg.showDayName }) : "—");
        if (hEl) put(hEl, wantH ? fullText(date, { calendar: "islamic", lang: cfg.lang, numerals: cfg.numerals, showDay: cfg.showDayName }) : "—");
    }
    function updateMirror(input, date, cfg) {
        if (!cfg.mirrorName) return;
        const h = qs(`#${input.id}__mirror`); if (!h) return;
        h.value = date ? (cfg.mirrorCalendar === "hijri" ? hijriISO(date) : toISO(date)) : "";
    }

    // ===== Range days =====
    const daysBoxFor = (cfg) => {
        let id = cfg.daysTarget || (cfg.group ? `${cfg.group}__days` : "");
        return id ? qs(`#${id}`) : null;
    };
    function updateDays(cfg) {
        const box = daysBoxFor(cfg); if (!box || !cfg.group) return;
        const from = qs(`input[data-role="sf-date"][data-range-group="${cfg.group}"][data-range-role="start"]`);
        const to = qs(`input[data-role="sf-date"][data-range-group="${cfg.group}"][data-range-role="end"]`);
        const vEl = qs("[data-days-value]", box);
        const eEl = qs("[data-days-error]", box);

        const d1 = fromISO(from?.value || ""); const d2 = fromISO(to?.value || "");
        if (d1 && d2) {
            const diff = Math.floor((+d2 - +d1) / MS_DAY);
            if (diff >= 0) {
                if (vEl) vEl.textContent = String(diff);
                if (eEl) eEl.classList.add("hidden");
            } else {
                if (vEl) vEl.textContent = "—";
                if (eEl) { eEl.textContent = "⚠️ التاريخ النهائي قبل الابتدائي"; eEl.classList.remove("hidden"); }
            }
        } else {
            if (vEl) vEl.textContent = "—";
            if (eEl) eEl.classList.add("hidden");
        }
    }

    // ===== NO datepicker at all =====

    const hidePicker = () => { };


    function neuterPickerAttributes(input) {
        delete input.dataset.toggle;
        delete input.dataset.datepicker;
        delete input.dataset.datepickerAutohide;
        delete input.dataset.datepickerButtons;
        delete input.dataset.datepickerFormat;
        delete input.dataset.language;
        input.removeAttribute("data-toggle");
        input.removeAttribute("data-datepicker");
        input.removeAttribute("data-date-format");
    }

    // ===== Commit logic =====
    function commitIfComplete(input, cfg, { blur = true, focusPartner = true } = {}) {
        const v = toLatnDigits(input.value);
        if (!isISO(v)) {
            updateInfoBox(input, null, cfg); updateMirror(input, null, cfg); updateDays(cfg);
            if (blur) setTimeout(() => input.blur(), 0);
            return false;
        }

        let dt = fromISO(v);
        if (!dt) {
            updateInfoBox(input, null, cfg); updateMirror(input, null, cfg); updateDays(cfg);
            return false;
        }

        dt = clampDate(dt, cfg.minDate, cfg.maxDate);
        input.value = toISO(dt);
        updateInfoBox(input, dt, cfg);
        updateMirror(input, dt, cfg);
        updateDays(cfg);

        // notify listeners
        input.dispatchEvent(new Event("change", { bubbles: true }));

        // focus partner for ranges
        if (focusPartner && cfg.group && cfg.role === "start") {
            const to = qs(`input[data-role="sf-date"][data-range-group="${cfg.group}"][data-range-role="end"]`);
            if (to && !to.value) setTimeout(() => to.focus(), 0);
        }

        if (blur) setTimeout(() => input.blur(), 0);
        return true;
    }

    // ===== Per-input setup =====
    function setup(input) {
        // Guard: prevent double initialization
        if (input.dataset.sfDateInitialized === "true") return;
        input.dataset.sfDateInitialized = "true";

        const cfg = cfgOf(input);


        neuterPickerAttributes(input);

        // Note: Removed stopPropagation to allow Flowbite datepicker to work
        // The datepicker needs to receive focus/click events to show the calendar
        input.addEventListener("mousedown", (e) => {
            // Allow event to propagate for datepicker
        }, false);
        input.addEventListener("focus", (e) => {
            // Allow event to propagate for datepicker  
        }, false);


        if (cfg.defaultToday && !input.value) {
            const today = clampDate(new Date(), cfg.minDate, cfg.maxDate);
            input.value = toISO(today);
        }

        // Normalize initial value
        if (input.value) {
            input.value = toLatnDigits(input.value);
            if (isISO(input.value)) {
                const dt = fromISO(input.value);
                updateInfoBox(input, dt, cfg); updateMirror(input, dt, cfg);
            } else {
                const masked = maskedFromDigits(digitsOnly(input.value).slice(0, 8));
                input.value = masked;
                if (masked.length === 10) commitIfComplete(input, cfg, { blur: false, focusPartner: false });
                else { updateInfoBox(input, null, cfg); updateMirror(input, null, cfg); }
            }
        } else { updateInfoBox(input, null, cfg); updateMirror(input, null, cfg); }

        // Input: mask + auto finalize on 10 chars
        input.addEventListener("input", () => {
            const masked = applyMaskKeepCaret(input);
            if (masked.length === 10) {
                commitIfComplete(input, cfg, { blur: true, focusPartner: true });
            } else {
                updateInfoBox(input, null, cfg); updateMirror(input, null, cfg); updateDays(cfg);
            }
        });

        // Paste
        input.addEventListener("paste", (e) => {
            e.preventDefault();
            const txt = (e.clipboardData || window.clipboardData).getData("text");
            const masked = maskedFromDigits(digitsOnly(txt).slice(0, 8));
            input.value = masked;
            if (masked.length === 10) commitIfComplete(input, cfg);
            else applyMaskKeepCaret(input);
        });


        input.addEventListener("blur", () => {
            commitIfComplete(input, cfg, { blur: false, focusPartner: false });
        });

        // Enter commits too
        input.addEventListener("keydown", (e) => {
            if (e.key === "Enter") {
                if (commitIfComplete(input, cfg)) e.preventDefault();
            }
        });

        // ===== Flowbite Datepicker Integration =====
        if (typeof Datepicker !== 'undefined') {
            const dpOptions = {
                format: 'yyyy-mm-dd',
                autohide: true,
                orientation: 'bottom',
                buttons: false,
                autoSelectToday: 0,
                todayHighlight: false
            };

            // Add min/max dates if specified
            if (cfg.minDate) dpOptions.minDate = cfg.minDate;
            if (cfg.maxDate) dpOptions.maxDate = cfg.maxDate;

            // Initialize Flowbite datepicker
            try {
                const datepickerInstance = new Datepicker(input, dpOptions);
                // Store instance on the element for later access
                input._flowbiteDatepicker = datepickerInstance;

                // Listen to 'changeDate' event from vanillajs-datepicker (not native 'change')
                // This fires immediately when a date is selected from the calendar
                input.addEventListener('changeDate', (e) => {
                    // When datepicker changes the value, update info boxes immediately
                    if (input.value && isISO(input.value)) {
                        commitIfComplete(input, cfg, { blur: false, focusPartner: false });
                    }
                });
            } catch (error) {
                console.warn('Failed to initialize Flowbite datepicker:', error);
            }
        }

        // Initial days calc for ranges
        updateDays(cfg);
    }

    // ===== Boot =====
    function boot() { qsa('input[data-role="sf-date"]').forEach(setup); }

    // Initialize on DOMContentLoaded (for non-Alpine pages)
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
    else boot();

    // Initialize after Alpine.js completes (for Alpine-based pages like AllComponentsDemo)
    document.addEventListener("alpine:initialized", boot);

})();
