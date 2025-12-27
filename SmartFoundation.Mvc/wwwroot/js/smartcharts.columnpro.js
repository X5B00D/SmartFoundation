(function () {
    const NS = "http://www.w3.org/2000/svg";

    function clamp(n, min, max) { return Math.max(min, Math.min(max, n)); }

    function fmtNumber(value, pattern) {
        if (!pattern) return String(value);
        const dot = pattern.indexOf(".");
        if (dot === -1) return String(Math.round(value));
        const decimals = pattern.length - dot - 1;
        const hasHash = pattern.includes("#");
        const fixed = Number(value).toFixed(decimals);
        return hasHash ? fixed.replace(/\.?0+$/, "") : fixed;
    }

    function toneColor(tone) {
        switch ((tone || "").toLowerCase()) {
            case "success": return "#22c55e";
            case "warning": return "#f59e0b";
            case "danger": return "#ef4444";
            case "info": return "#0ea5e9";
            default: return "#334155";
        }
    }

    function makeSvg(tag, attrs) {
        const el = document.createElementNS(NS, tag);
        if (attrs) for (const k in attrs) el.setAttribute(k, attrs[k]);
        return el;
    }

    function ensureTooltip(host) {
        let tip = host.querySelector(".smart-colpro__tooltip");
        if (tip) return tip;
        tip = document.createElement("div");
        tip.className = "smart-colpro__tooltip";
        tip.innerHTML = `<div class="smart-colpro__tt-title"></div>
                     <div class="smart-colpro__tt-val"></div>`;
        host.appendChild(tip);
        return tip;
    }

    function niceTicks(max) {
        if (max <= 0) return { max: 1, step: 1, ticks: [0, 1, 2, 3, 4].map(x => x * 0.25) };
        const pow = Math.pow(10, Math.floor(Math.log10(max)));
        const n = max / pow;
        const step = (n <= 2) ? 0.5 * pow : (n <= 5) ? 1 * pow : 2 * pow;
        const niceMax = Math.ceil(max / step) * step;
        const ticks = [];
        for (let v = 0; v <= niceMax; v += niceMax / 4) ticks.push(v);
        return { max: niceMax, step, ticks };
    }

    function renderOne(host) {
        const cfgId = host.getAttribute("data-config-id");
        const cfgNode = cfgId ? document.getElementById(cfgId) : null;
        if (!cfgNode) return;

        let cfg;
        try { cfg = JSON.parse(cfgNode.textContent || "{}"); } catch { return; }

        const dir = (cfg.dir || "rtl").toLowerCase();
        const labels = Array.isArray(cfg.labels) ? cfg.labels : [];
        const values = Array.isArray(cfg.values) ? cfg.values : [];
        const hrefs = Array.isArray(cfg.hrefs) ? cfg.hrefs : [];
        const valueFormat = cfg.valueFormat || "0";
        const minBarWidth = clamp(Number(cfg.minBarWidth ?? 44), 28, 80);
        const H = clamp(Number(cfg.height ?? 260), 160, 420);
        const showValues = !!cfg.showValues;
        const tone = cfg.tone || "neutral";
        const barColor = toneColor(tone);

        host.innerHTML = "";
        host.setAttribute("dir", dir);

        const n = Math.min(labels.length, values.length);
        if (n <= 0) {
            const empty = document.createElement("div");
            empty.className = "smart-colpro__empty";
            empty.textContent = "لا توجد بيانات";
            host.appendChild(empty);
            return;
        }

        const vals = values.slice(0, n).map(v => Number(v) || 0);
        const rawMax = Math.max(...vals, 0);
        const tick = niceTicks(rawMax);

        // Layout sizes (SVG coords)
        const W = Math.max(520, n * minBarWidth + 120);
        const padL = 48, padR = 18, padT = 14, padB = 42;
        const plotW = W - padL - padR;
        const plotH = H - padT - padB;

        const scroller = document.createElement("div");
        scroller.className = "smart-colpro__scroller";
        host.appendChild(scroller);

        const canvas = document.createElement("div");
        canvas.className = "smart-colpro__canvas";
        canvas.style.width = `${W}px`;
        scroller.appendChild(canvas);

        const svg = makeSvg("svg", { class: "smart-colpro__svg", viewBox: `0 0 ${W} ${H}` });
        canvas.appendChild(svg);

        const tipEl = ensureTooltip(host);

        // grid + y labels (4 خطوط)
        for (let k = 0; k <= 4; k++) {
            const y = padT + (k / 4) * plotH;
            svg.appendChild(makeSvg("line", { x1: padL, x2: W - padR, y1: y, y2: y, stroke: "#e2e8f0", "stroke-width": "1" }));
            const val = tick.max - (k / 4) * tick.max;
            const t = makeSvg("text", {
                x: padL - 10,
                y: y + 4,
                "text-anchor": "end",
                fill: "#64748b",
                "font-size": "11"
            });
            t.textContent = fmtNumber(val, valueFormat);
            svg.appendChild(t);
        }

        // bars
        const gap = 10;
        const barW = Math.max(18, (plotW - gap * (n - 1)) / n);

        function xAt(i) { return padL + i * (barW + gap); }
        function yAt(v) {
            const t = tick.max > 0 ? (v / tick.max) : 0;
            return padT + (1 - clamp(t, 0, 1)) * plotH;
        }

        for (let i = 0; i < n; i++) {
            const v = vals[i];
            const x = xAt(i);
            const y = yAt(v);
            const h = (padT + plotH) - y;

            // group per bar
            const g = makeSvg("g", {});
            svg.appendChild(g);

            // bar rect (animated)
            const rect = makeSvg("rect", {
                x: x,
                y: padT + plotH,
                width: barW,
                height: 0,
                rx: 10,
                fill: barColor,
                opacity: "0.95"
            });
            g.appendChild(rect);

            // top value (on hover or always)
            const valText = makeSvg("text", {
                x: x + barW / 2,
                y: y - 8,
                "text-anchor": "middle",
                fill: "#0f172a",
                "font-size": "11",
                "font-weight": "800",
                opacity: showValues ? "1" : "0"
            });
            valText.textContent = fmtNumber(v, valueFormat);
            g.appendChild(valText);

            // x label
            const lab = makeSvg("text", {
                x: x + barW / 2,
                y: H - 16,
                "text-anchor": "middle",
                fill: "#475569",
                "font-size": "11"
            });
            lab.textContent = String(labels[i] ?? "");
            g.appendChild(lab);

            // hit area
            const hit = makeSvg("rect", {
                x: x,
                y: padT,
                width: barW,
                height: plotH,
                fill: "transparent",
                cursor: (hrefs[i] ? "pointer" : "default")
            });
            g.appendChild(hit);

            // hover effects
            hit.addEventListener("mousemove", (e) => {
                rect.setAttribute("opacity", "1");
                rect.setAttribute("filter", "url(#shadow)");
                valText.setAttribute("opacity", "1");

                tipEl.querySelector(".smart-colpro__tt-title").textContent = String(labels[i] ?? "");
                tipEl.querySelector(".smart-colpro__tt-val").textContent = fmtNumber(v, valueFormat);

                const rectHost = host.getBoundingClientRect();
                tipEl.style.transform = `translate(${(e.clientX - rectHost.left) + 10}px, ${(e.clientY - rectHost.top) + 10}px)`;
                tipEl.classList.add("is-show");
            });
            hit.addEventListener("mouseleave", () => {
                rect.setAttribute("opacity", "0.95");
                rect.removeAttribute("filter");
                if (!showValues) valText.setAttribute("opacity", "0");
                tipEl.classList.remove("is-show");
            });

            if (hrefs[i]) {
                hit.addEventListener("click", () => window.location.href = hrefs[i]);
            }

            // animate
            requestAnimationFrame(() => {
                rect.style.transition = "y 850ms cubic-bezier(.2,.8,.2,1), height 850ms cubic-bezier(.2,.8,.2,1)";
                rect.setAttribute("y", String(y));
                rect.setAttribute("height", String(h));
            });
        }
    }

    function renderAll() {
        document.querySelectorAll(".smart-colpro[data-config-id]").forEach(renderOne);
    }

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", renderAll);
    else renderAll();

    window.SmartCharts = window.SmartCharts || {};
    window.SmartCharts.renderColumnPro = renderAll;
})();
