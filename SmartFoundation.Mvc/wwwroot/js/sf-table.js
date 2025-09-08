/* sf-Table.js */
/* global Alpine */
(function () {
    // متاح عالمياً للاستخدام داخل: x-data='sfTable({...})'
    window.sfTable = function sfTable(userOptions) {
        // الإعدادات الافتراضية
        const defaults = {
            endpoint: "/Smart/Execute",
            spName: "",
            operation: "select",

            // Pagination
            pageSize: 10,
            pageSizes: [5, 10, 25, 50, 100],

            // Search
            searchable: true,
            searchPlaceholder: "بحث...",
            quickSearchFields: [],

            // Export
            allowExport: false,

            // Header/Footer
            showHeader: true,
            showFooter: true,

            // After save, reload
            autoRefresh: true,

            // Columns / Row actions
            columns: [],
            actions: [],

            // Selection & grouping
            selectable: false,
            rowIdField: "Id",
            groupBy: "",

            // Persistence
            storageKey: "sf_table",

            // Toolbar config (عرض فقط – لا يبني إجراءات)
            toolbar: {
                showRefresh: true,
                showExportExcel: false,
                showExportCsv: false,
                showAdd: false,
                showEdit: false,
                showAdvancedFilter: false,
                showBulkDelete: false,
                add: null,
                edit: null,
                bulkDeleteOp: "delete_bulk"
            }
        };

        const cfg = Object.assign({}, defaults, userOptions || {});
        cfg.toolbar = Object.assign({}, defaults.toolbar, cfg.toolbar || {});

        // أدوات مساعدة
        const debounce = (fn, ms) => {
            let t;
            return function (...args) {
                clearTimeout(t);
                t = setTimeout(() => fn.apply(this, args), ms);
            };
        };

        const downloadBlob = (blob, filename) => {
            const url = URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = filename || "download";
            document.body.appendChild(a);
            a.click();
            a.remove();
            URL.revokeObjectURL(url);
        };

        const numberFormat = (v, decimals = 0) => {
            if (v === null || v === undefined || v === "") return "";
            const n = Number(v);
            if (Number.isNaN(n)) return String(v);
            return n.toLocaleString(undefined, {
                minimumFractionDigits: decimals,
                maximumFractionDigits: decimals
            });
        };

        const parseJSONSafely = async (resp) => {
            const ct = (resp.headers.get("Content-Type") || "").toLowerCase();
            if (ct.includes("application/json")) {
                return await resp.json();
            }
            const text = await resp.text();
            try {
                return JSON.parse(text);
            } catch {
                return { __raw: text };
            }
        };

        // --- دعم Anti-forgery (CSRF) إن وجد ---
        const readAntiForgery = () => {
            // 1) من input مخفي في الصفحة
            const input = document.querySelector('input[name="__RequestVerificationToken"]');
            if (input && input.value) {
                return { header: "RequestVerificationToken", value: input.value };
            }
            // 2) من الكوكي (أسماء شائعة)
            const cookieMatch = document.cookie.match(/(?:^|;\s*)(XSRF-TOKEN|.AspNetCore.Antiforgery\.[^=]+)=([^;]+)/);
            if (cookieMatch) {
                return { header: "X-XSRF-TOKEN", value: decodeURIComponent(cookieMatch[2]) };
            }
            return null;
        };

        const anti = readAntiForgery();

        // تركيبة العنصر لـ Alpine
        return {
            // ---- الحالة ----
            endpoint: cfg.endpoint,
            spName: cfg.spName,
            operation: cfg.operation,

            pageSize: cfg.pageSize,
            pageSizes: cfg.pageSizes.slice(),

            searchable: cfg.searchable,
            searchPlaceholder: cfg.searchPlaceholder,
            quickSearchFields: cfg.quickSearchFields.slice(),

            allowExport: cfg.allowExport,

            showHeader: cfg.showHeader,
            showFooter: cfg.showFooter,

            autoRefresh: cfg.autoRefresh,

            columns: (cfg.columns || []).map((c) =>
                Object.assign(
                    { sortable: false, align: "", width: "", visible: c?.visible !== false, format: c?.format || null, decimals: c?.decimals },
                    c
                )
            ),
            actions: (cfg.actions || []).map((a) =>
                Object.assign({ show: true, color: "secondary", icon: a?.icon || "" }, a)
            ),

            selectable: cfg.selectable,
            rowIdField: cfg.rowIdField,
            groupBy: cfg.groupBy,

            storageKey: cfg.storageKey,

            toolbar: cfg.toolbar,

            // بيانات الجدول
            rows: [],
            total: 0,
            page: 1,
            pages: 1,
            sort: { field: null, dir: "asc" },
            q: "",

            // حالة الواجهة
            loading: false,
            error: "",
            selectAll: false,
            selectedKeys: new Set(),
            filters: [],

            // المودال
            modal: {
                open: false,
                title: "",
                html: "",
                rows: [],
                loading: false,
                error: "",
                action: null
            },

            // ---- الدورات ----
            init() {
                this._loadState();

                this.$watch(
                    "q",
                    debounce(() => {
                        if (!this.searchable) return;
                        this.page = 1;
                        this._saveState();
                        this.load();
                    }, 300)
                );

                this.$watch("pageSize", () => {
                    if (!Number.isFinite(this.pageSize) || this.pageSize <= 0) this.pageSize = 10;
                    this.page = 1;
                    this._saveState();
                    this.load();
                });

                this.$watch("sort", () => this._saveState());

                this.$el.addEventListener("sf:refresh", () => this.refresh());
                this.$el.addEventListener("sf:saved", () => {
                    if (this.autoRefresh) this.refresh();
                });

                this.load();
            },

            // ---- عمليات الخادم ----
            async _fetchJson(payload, init = {}) {
                const headers = Object.assign(
                    {
                        "Content-Type": "application/json",
                        "Accept": "application/json, text/html, */*",
                        "X-Requested-With": "XMLHttpRequest"
                    },
                    init.headers || {}
                );
                if (anti) headers[anti.header] = anti.value; // << إضافة التوكن إن وجد

                const resp = await fetch(this.endpoint, {
                    method: init.method || "POST",
                    headers,
                    body: JSON.stringify(payload),
                    cache: "no-store",
                    redirect: "follow",
                    credentials: "same-origin"
                });
                if (!resp.ok) {
                    const txt = await resp.text().catch(() => "");
                    throw new Error(`HTTP ${resp.status} ${resp.statusText}${txt ? " - " + txt : ""}`);
                }
                return parseJSONSafely(resp);
            },

            async _fetchText(url, init = {}) {
                const headers = Object.assign({}, init.headers || {});
                if (anti) headers[anti.header] = anti.value;
                const resp = await fetch(url, Object.assign({ method: "GET", credentials: "same-origin", headers }, init));
                if (!resp.ok) throw new Error(`HTTP ${resp.status} ${resp.statusText}`);
                return resp.text();
            },

            async _fetchBlob(payload, filename, contentTypeHint) {
                const headers = {
                    "Content-Type": "application/json",
                    "Accept": contentTypeHint || "*/*",
                    "X-Requested-With": "XMLHttpRequest"
                };
                if (anti) headers[anti.header] = anti.value;

                const resp = await fetch(this.endpoint, {
                    method: "POST",
                    headers,
                    body: JSON.stringify(payload),
                    credentials: "same-origin"
                });
                if (!resp.ok) throw new Error(`HTTP ${resp.status} ${resp.statusText}`);
                const blob = await resp.blob();
                downloadBlob(blob, filename);
            },

            // ---- تحميل البيانات ----
            async load() {
                try {
                    this.loading = true;
                    this.error = "";

                    const payload = {
                        spName: this.spName,
                        operation: this.operation,
                        page: this.page,
                        pageSize: this.pageSize,
                        sort: this.sort && this.sort.field ? this.sort : null,
                        q: this.searchable ? this.q : "",
                        quickSearchFields: this.quickSearchFields,
                        filters: this.filters
                    };

                    const data = await this._fetchJson(payload);

                    const rows = data.rows || data.data || data.Data || data.Result || [];
                    const total = data.total ?? data.count ?? data.Total ?? rows.length;

                    this.rows = Array.isArray(rows) ? rows : [];
                    this.total = Number.isFinite(total) ? Number(total) : this.rows.length;

                    this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));
                    if (this.page > this.pages) this.page = this.pages;

                    this._syncSelectAll();

                    this.$el.dispatchEvent(new CustomEvent("sf:datatable:loaded", { detail: { total: this.total } }));
                } catch (err) {
                    console.error(err);
                    this.error = err.message || "خطأ غير معروف.";
                } finally {
                    this.loading = false;
                }
            },

            refresh() { this.load(); },

            // ---- الأعمدة والخلايا ----
            visibleColumns() {
                return (this.columns || []).filter((c) => c.visible !== false);
            },

            formatCell(row, col) {
                if (col && typeof col.html === "string") {
                    return col.html.replace(/\{([\w.]+)\}/g, (_, p) => this._escape(String(this._get(row, p) ?? "")));
                }

                let v = this._get(row, col.field);
                if (v === null || v === undefined) v = "";

                if (col.format === "number") {
                    const d = Number.isFinite(col.decimals) ? col.decimals : 0;
                    return numberFormat(v, d);
                }
                if (col.format === "bool") {
                    return v ? `<i class="fa fa-check text-success"></i>` : `<i class="fa fa-times text-danger"></i>`;
                }
                if (col.format === "date" || col.format === "datetime") {
                    const d = v ? new Date(v) : null;
                    if (!d || isNaN(d)) return this._escape(String(v));
                    if (col.format === "date") return d.toLocaleDateString();
                    return `${d.toLocaleDateString()} ${d.toLocaleTimeString()}`;
                }

                return this._escape(String(v));
            },

            // ---- الفرز ----
            toggleSort(col) {
                if (!col || col.sortable !== true || !col.field) return;
                if (this.sort.field === col.field) {
                    this.sort.dir = this.sort.dir === "asc" ? "desc" : "asc";
                } else {
                    this.sort = { field: col.field, dir: "asc" };
                }
                this.page = 1;
                this.load();
            },

            // ---- الاختيار ----
            isSelected(row) {
                const id = this._rowId(row);
                return id != null && this.selectedKeys.has(id);
            },

            toggleRow(row) {
                if (!this.selectable) return;
                const id = this._rowId(row);
                if (id == null) return;
                if (this.selectedKeys.has(id)) this.selectedKeys.delete(id);
                else this.selectedKeys.add(id);
                this._syncSelectAll();
            },

            toggleSelectAll() {
                if (!this.selectable) return;
                const ids = this._pageRowIds();
                if (!ids.length) {
                    this.selectAll = false;
                    return;
                }
                if (this.selectAll) {
                    ids.forEach((id) => this.selectedKeys.delete(id));
                    this.selectAll = false;
                } else {
                    ids.forEach((id) => this.selectedKeys.add(id));
                    this.selectAll = true;
                }
            },

            getSingleSelection() {
                if (this.selectedKeys.size !== 1) return null;
                const id = Array.from(this.selectedKeys)[0];
                return this.rows.find((r) => this._rowId(r) === id) || null;
            },

            // ---- الإجراءات ----
            async doAction(action, row) {
                try {
                    if (!action || action.show === false) return;

                    if (action.confirm) {
                        const msg = typeof action.confirm === "string" ? action.confirm : "تأكيد العملية؟";
                        if (!window.confirm(msg)) return;
                    }

                    const id = row ? this._rowId(row) : null;

                    if (action.openModal) {
                        await this._openModal(action, row, id);
                        return;
                    }

                    if (action.spOp || action.op) {
                        const payload = { spName: this.spName, operation: action.spOp || action.op, id, row, args: action.args || {} };
                        const res = await this._fetchJson(payload);
                        if (res && res.success === false) throw new Error(res.message || "فشلت العملية.");
                        if (this.autoRefresh || action.refresh) this.refresh();
                        return;
                    }

                    if (action.href) {
                        const url = this._fillUrl(action.href, row, id, action.rowIdParamName || "id");
                        if (action.target === "_blank") window.open(url, "_blank");
                        else window.location.href = url;
                        return;
                    }
                } catch (err) {
                    console.error(err);
                    alert(err.message || "فشل تنفيذ الإجراء.");
                }
            },

            async _openModal(action, row, id) {
                this.modal.open = true;
                this.modal.loading = true;
                this.modal.error = "";
                this.modal.title = action.modalTitle || action.label || "نموذج";
                this.modal.html = "";
                this.modal.rows = [];
                this.modal.action = action;

                try {
                    if (action.formUrl) {
                        const url = this._fillUrl(action.formUrl, row, id, action.rowIdParamName || "id");
                        const html = await this._fetchText(url, { method: action.formMethod || "GET" });
                        this.modal.html = html;
                        this.$nextTick(() => this._wireModalForm());
                    } else if (action.openForm) {
                        this.modal.html = this._renderForm(action.openForm);
                        this.$nextTick(() => this._wireModalForm());
                    } else if (action.modalSp || action.spModal) {
                        const payload = { spName: this.spName, operation: action.modalSp || action.spModal, id, row, args: action.args || {} };
                        const res = await this._fetchJson(payload);
                        const rows = res.rows || res.data || res.Result || [];
                        this.modal.rows = Array.isArray(rows) ? rows : [];
                    } else {
                        this.modal.error = "لا يوجد مصدر للمودال (formUrl أو modalSp أو openForm).";
                    }
                } catch (err) {
                    console.error(err);
                    this.modal.error = err.message || "تعذر فتح النافذة.";
                } finally {
                    this.modal.loading = false;
                }
            },

            _renderForm(formCfg) {
                let html = `<form id="${formCfg.formId || "form"}" method="${formCfg.method || "POST"}" action="${formCfg.actionUrl || ""}">`;
                const fields = Array.isArray(formCfg.fields) ? formCfg.fields : [];
                fields.forEach(f => {
                    const name = f.name || "";
                    const val = f.value ?? "";
                    const label = f.label || name;
                    const col = f.colCss || "12";
                    const required = f.required ? "required" : "";
                    const disabled = f.disabled ? "disabled" : "";
                    const placeholder = f.placeholder ? `placeholder="${f.placeholder}"` : "";
                    const pattern = f.pattern ? `pattern="${f.pattern}"` : "";

                    if (f.isHidden || f.type === "hidden") {
                        html += `<input type="hidden" name="${name}" value="${String(val)}" />`;
                        return;
                    }

                    html += `<div class="form-group col-${col}">
                                <label>${label}</label>`;

                    if (["text", "email", "phone", "date", "number", "iban"].includes(f.type)) {
                        const type = f.type === "iban" ? "text" : f.type;
                        html += `<input type="${type}" name="${name}" value="${String(val)}" class="form-control" ${placeholder} ${pattern} ${required} ${disabled} />`;
                    } else if (f.type === "checkbox") {
                        html += `<input type="checkbox" name="${name}" ${val ? "checked" : ""} ${disabled} />`;
                    } else if (f.type === "textarea") {
                        html += `<textarea name="${name}" class="form-control" ${placeholder} ${required} ${disabled}>${String(val)}</textarea>`;
                    } else if (f.type === "select" && Array.isArray(f.options)) {
                        html += `<select name="${name}" class="form-control" ${required} ${disabled}>`;
                        f.options.forEach(opt => {
                            const ov = opt.value ?? opt.id ?? opt.key ?? "";
                            const ot = opt.text ?? opt.label ?? String(ov);
                            const sel = String(ov) === String(val) ? "selected" : "";
                            html += `<option value="${String(ov)}" ${sel}>${String(ot)}</option>`;
                        });
                        html += `</select>`;
                    } else {
                        html += `<input type="text" name="${name}" value="${String(val)}" class="form-control" ${placeholder} ${required} ${disabled} />`;
                    }

                    html += `</div>`;
                });
                html += `<button type="submit" class="btn btn-success">${formCfg.submitText || "حفظ"}</button></form>`;
                return html;
            },

            closeModal() {
                this.modal.open = false;
                this.modal.html = "";
                this.modal.rows = [];
                this.modal.action = null;
                this.modal.error = "";
            },

            async saveModalChanges() {
                const act = this.modal.action || {};
                try {
                    const form = this._modalFormEl();
                    if (form) {
                        const method = (act.formMethod || form.getAttribute("method") || "POST").toUpperCase();
                        const actionUrl = act.saveUrl || form.getAttribute("action");
                        if (!actionUrl && !act.saveOp) {
                            const fd = new FormData(form);
                            const payload = { spName: this.spName, operation: act.isEdit ? "update" : "insert", data: Object.fromEntries(fd.entries()) };
                            const res = await this._fetchJson(payload);
                            if (res && res.success === false) throw new Error(res.message || "فشل الحفظ.");
                        } else if (actionUrl) {
                            const fd = new FormData(form);
                            const headers = {};
                            if (anti) headers[anti.header] = anti.value;
                            const resp = await fetch(actionUrl, { method, body: fd, credentials: "same-origin", headers });
                            if (!resp.ok) throw new Error(`HTTP ${resp.status} ${resp.statusText}`);
                        } else if (act.saveOp) {
                            const fd = new FormData(form);
                            const payload = { spName: this.spName, operation: act.saveOp, data: Object.fromEntries(fd.entries()) };
                            const res = await this._fetchJson(payload);
                            if (res && res.success === false) throw new Error(res.message || "فشل الحفظ.");
                        }
                    } else {
                        if (!act.saveOp) throw new Error("لا يوجد form ولا saveOp للحفظ.");
                        const payload = { spName: this.spName, operation: act.saveOp, data: this.modal.rows?.[0] || {} };
                        const res = await this._fetchJson(payload);
                        if (res && res.success === false) throw new Error(res.message || "فشل الحفظ.");
                    }

                    this.$el.dispatchEvent(new CustomEvent("sf:saved"));
                    if (this.autoRefresh || act.refresh) this.refresh();
                    this.closeModal();
                } catch (err) {
                    console.error(err);
                    this.modal.error = err.message || "فشل الحفظ.";
                }
            },

            async doBulkDelete() {
                if (!this.selectable) return;
                const ids = Array.from(this.selectedKeys);
                if (!ids.length) {
                    alert("اختر صفوفًا أولاً.");
                    return;
                }
                if (!window.confirm(`سيتم حذف ${ids.length} سجل. متابعة؟`)) return;
                try {
                    const payload = { spName: this.spName, operation: this.toolbar.bulkDeleteOp || "delete_bulk", ids };
                    const res = await this._fetchJson(payload);
                    if (res && res.success === false) throw new Error(res.message || "فشل الحذف.");
                    ids.forEach((id) => this.selectedKeys.delete(id));
                    if (this.autoRefresh || this.toolbar.refresh) this.refresh();
                    this.$el.dispatchEvent(new CustomEvent("sf:bulk:deleted", { detail: { ids } }));
                } catch (err) {
                    console.error(err);
                    alert(err.message || "تعذر تنفيذ الحذف.");
                }
            },

            // ---- تصدير ----
            async exportData(kind) {
                if (!this.allowExport) return;
                const k = (kind || "").toLowerCase();
                if (k !== "csv" && k !== "excel") return;

                const opName = k === "csv" ? "export_csv" : "export_excel";
                const payload = {
                    spName: this.spName,
                    operation: opName,
                    page: this.page,
                    pageSize: this.pageSize,
                    sort: this.sort && this.sort.field ? this.sort : null,
                    q: this.searchable ? this.q : "",
                    quickSearchFields: this.quickSearchFields,
                    filters: this.filters
                };
                const filename = k === "csv" ? "export.csv" : "export.xlsx";
                const accept = k === "csv" ? "text/csv" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                try {
                    await this._fetchBlob(payload, filename, accept);
                } catch (err) {
                    console.error(err);
                    alert(err.message || "تعذر التصدير.");
                }
            },

            // ---- فلترة متقدمة ----
            toggleAdvancedFilter() { this.$el.dispatchEvent(new CustomEvent("sf:advancedFilter:toggle")); },

            // ---- ترقيم ----
            rangeText() {
                if (!this.total) return "0 من 0";
                const start = (this.page - 1) * this.pageSize + 1;
                const end = Math.min(this.page * this.pageSize, this.total);
                return `${start}–${end} من ${this.total}`;
            },
            firstPage() { if (this.page > 1) { this.page = 1; this.load(); } },
            prevPage() { if (this.page > 1) { this.page -= 1; this.load(); } },
            nextPage() { if (this.page < this.pages) { this.page += 1; this.load(); } },
            lastPage() { if (this.page < this.pages) { this.page = this.pages; this.load(); } },

            // ---- داخلية ----
            _get(obj, path) {
                if (!path) return undefined;
                return path.split(".").reduce((o, k) => (o ? o[k] : undefined), obj);
            },
            _escape(s) {
                return s
                    .replaceAll("&", "&amp;")
                    .replaceAll("<", "&lt;")
                    .replaceAll(">", "&gt;")
                    .replaceAll('"', "&quot;")
                    .replaceAll("'", "&#039;");
            },
            _rowId(row) { return row?.[this.rowIdField] ?? row?.Id ?? row?.id ?? null; },
            _pageRowIds() { return this.rows.map((r) => this._rowId(r)).filter((id) => id != null); },
            _syncSelectAll() {
                const ids = this._pageRowIds();
                this.selectAll = ids.length > 0 && ids.every((id) => this.selectedKeys.has(id));
            },
            _fillUrl(url, row, id, idParamName) {
                let final = url;
                if (row && typeof final === "string") {
                    final = final.replace(/\{([\w.]+)\}/g, (_, p) => encodeURIComponent(this._get(row, p) ?? ""));
                }
                if (id && typeof final === "string" && final.indexOf(`${idParamName}=`) === -1) {
                    final += (final.includes("?") ? "&" : "?") + `${encodeURIComponent(idParamName)}=${encodeURIComponent(id)}`;
                }
                return final;
            },
            _modalRootEl() { return this.$el.querySelector(".sf-modal"); },
            _modalFormEl() {
                const root = this._modalRootEl();
                return root ? root.querySelector(".sf-modal-body form") : null;
            },
            _wireModalForm() {
                const form = this._modalFormEl();
                if (!form) return;
                // FIX: منع الإرسال دائمًا (بدون once)
                const handler = (e) => e.preventDefault();
                // نظّف مستمع قديم لتجنّب التكرار
                form.removeEventListener("submit", handler);
                form.addEventListener("submit", handler);
            },
            _loadState() {
                if (!this.storageKey) return;
                try {
                    const raw = localStorage.getItem(this.storageKey);
                    if (!raw) return;
                    const st = JSON.parse(raw);
                    if (st) {
                        if (Number.isFinite(st.pageSize) && st.pageSize > 0) this.pageSize = st.pageSize;
                        if (st.sort && st.sort.field) this.sort = st.sort;
                        if (typeof st.q === "string") this.q = st.q;
                    }
                } catch { /* تجاهل */ }
            },
            _saveState() {
                if (!this.storageKey) return;
                try {
                    const st = {
                        pageSize: this.pageSize,
                        sort: this.sort && this.sort.field ? this.sort : null,
                        q: this.q
                    };
                    localStorage.setItem(this.storageKey, JSON.stringify(st));
                } catch { /* تجاهل */ }
            }
        };
    };
})();
