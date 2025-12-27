(function () {
    function clamp(n, min, max) { return Math.max(min, Math.min(max, n)); }

    function clip(text, maxChars) {
        const s = (text ?? "").toString();
        if (!maxChars || maxChars <= 0) return s;
        return s.length <= maxChars ? s : s.slice(0, maxChars - 1) + "…";
    }

    function fmtNumber(value, pattern) {
        if (!pattern) return String(value);
        const dot = pattern.indexOf(".");
        if (dot === -1) return String(Math.round(value));
        const decimals = pattern.length - dot - 1;
        const hasHash = pattern.includes("#");
        const fixed = Number(value).toFixed(decimals);
        return hasHash ? fixed.replace(/\.?0+$/, "") : fixed;
    }

    function ensureTooltip(host) {
        let tip = host.querySelector(".smart-barh__tooltip");
        if (tip) return tip;
        tip = document.createElement("div");
        tip.className = "smart-barh__tooltip";
        tip.innerHTML = `<div class="smart-barh__tt-title"></div>
                     <div class="smart-barh__tt-val"></div>`;
        host.appendChild(tip);
        return tip;
    }

    function renderOne(host) {
        const cfgId = host.getAttribute("data-config-id");
        const cfgNode = cfgId ? document.getElementById(cfgId) : null;
        if (!cfgNode) return;

        let cfg;
        try { cfg = JSON.parse(cfgNode.textContent || "{}"); } catch { return; }

        const labels = Array.isArray(cfg.labels) ? cfg.labels : [];
        const values = Array.isArray(cfg.values) ? cfg.values : [];
        const dir = (cfg.dir || "rtl").toLowerCase();
        const tone = (cfg.tone || "neutral").toLowerCase();
        const showValues = !!cfg.showValues;
        const valueFormat = cfg.valueFormat || "0";
        const labelMaxChars = clamp(Number(cfg.labelMaxChars ?? 22), 8, 60);

        host.innerHTML = "";
        host.setAttribute("dir", dir);
        host.setAttribute("data-tone", tone);

        const n = Math.min(labels.length, values.length);
        if (n <= 0) {
            const empty = document.createElement("div");
            empty.className = "smart-barh__empty";
            empty.textContent = "لا توجد بيانات";
            host.appendChild(empty);
            return;
        }

        const max = Math.max(...values.slice(0, n).map(v => Number(v) || 0));
        const tip = ensureTooltip(host);

        const list = document.createElement("div");
        list.className = "smart-barh__list";
        host.appendChild(list);

        for (let i = 0; i < n; i++) {
            const labelFull = (labels[i] ?? "").toString();
            const label = clip(labelFull, labelMaxChars);
            const v = Number(values[i]) || 0;
            const pct = max > 0 ? (v / max) * 100 : 0;

            const row = document.createElement("div");
            row.className = "smart-barh__row";

            const lab = document.createElement("div");
            lab.className = "smart-barh__label";
            lab.textContent = label;

            const track = document.createElement("div");
            track.className = "smart-barh__track";

            const bar = document.createElement("div");
            bar.className = "smart-barh__bar";
            // نخليها 0 ثم نحط النسبة عشان animation
            bar.style.width = "0%";
            track.appendChild(bar);

            const val = document.createElement("div");
            val.className = "smart-barh__value";
            if (showValues) val.textContent = fmtNumber(v, valueFormat);
            else val.textContent = "";

            // tooltip
            track.addEventListener("mousemove", (e) => {
                tip.querySelector(".smart-barh__tt-title").textContent = labelFull;
                tip.querySelector(".smart-barh__tt-val").textContent = fmtNumber(v, valueFormat);

                const rect = host.getBoundingClientRect();
                tip.style.transform = `translate(${(e.clientX - rect.left) + 10}px, ${(e.clientY - rect.top) + 10}px)`;
                tip.classList.add("is-show");
            });
            track.addEventListener("mouseleave", () => tip.classList.remove("is-show"));

            row.appendChild(lab);
            row.appendChild(track);
            row.appendChild(val);

            list.appendChild(row);

            // trigger animation بعد الإضافة
            requestAnimationFrame(() => {
                bar.style.width = `${pct.toFixed(2)}%`;
            });
        }
    }

    function renderAll() {
        document.querySelectorAll(".smart-barh[data-config-id]").forEach(renderOne);
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", renderAll);
    } else {
        renderAll();
    }

    window.SmartCharts = window.SmartCharts || {};
    window.SmartCharts.renderBarH = renderAll;
})();
