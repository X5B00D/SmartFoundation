// wwwroot/js/sf-table.js
(function () {
    const register = () => {
        Alpine.data("sfTable", (cfg) => ({
            // ===== الخصائص القادمة من الـ Razor =====
            endpoint: cfg.endpoint || "/smart/execute",
            spName: cfg.spName || "",
            operation: cfg.operation || "select",

            page: 1,
            pageSize: cfg.pageSize || 10,
            pageSizes: cfg.pageSizes || [10, 25, 50, 100],

            searchable: !!cfg.searchable,
            searchPlaceholder: cfg.searchPlaceholder || "بحث…",
            quickSearchFields: cfg.quickSearchFields || [],

            allowExport: !!cfg.allowExport,

            showHeader: !!cfg.showHeader,
            showFooter: !!cfg.showFooter,

            autoRefresh: !!cfg.autoRefresh,

            columns: cfg.columns || [],
            actions: cfg.actions || [],

            selectable: !!cfg.selectable,
            rowIdField: cfg.rowIdField || "Id",
            groupBy: cfg.groupBy || null,
            storageKey: cfg.storageKey || null,

            toolbar: cfg.toolbar || {},

            // ===== الحالة الداخلية =====
            q: "",
            rows: [],
            total: 0,
            pages: 0,
            sort: { field: null, dir: "asc" },
            loading: false,
            error: null,

            selectedKeys: new Set(),
            selectAll: false,

            modal: {
                open: false,
                title: "",
                html: "",
                action: null,
                loading: false,
                error: null
            },

            // ===== تهيئة =====
            init() {
                this.load();
            },

            // ===== تحميل البيانات من السيرفر =====
            async load() {
                this.loading = true;
                this.error = null;
                try {
                    const body = {
                        Component: "Table",
                        SpName: this.spName,
                        Operation: this.operation,
                        Paging: { Page: this.page, Size: this.pageSize },
                        Sort: this.sort.field
                            ? { Field: this.sort.field, Dir: this.sort.dir }
                            : null,
                        Filters: this.q
                            ? this.quickSearchFields.map((f) => ({
                                Field: f,
                                Op: "contains",
                                Value: this.q
                            }))
                            : []
                    };

                    const resp = await fetch(this.endpoint, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify(body)
                    });

                    const json = await resp.json();
                    if (!json.success) throw new Error(json.error || "خطأ");

                    this.rows = json.data || [];
                    this.total = json.total || this.rows.length;
                    this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));
                } catch (e) {
                    console.error("sfTable.load error", e);
                    this.error = e.message || "⚠️ خطأ غير معروف";
                } finally {
                    this.loading = false;
                }
            },

            refresh() {
                this.page = 1;
                this.load();
            },

            // ===== الأعمدة =====
            visibleColumns() {
                return this.columns.filter((c) => c.visible !== false);
            },

            toggleSort(col) {
                if (!col.sortable) return;
                if (this.sort.field === col.field) {
                    this.sort.dir = this.sort.dir === "asc" ? "desc" : "asc";
                } else {
                    this.sort.field = col.field;
                    this.sort.dir = "asc";
                }
                this.load();
            },

            // ===== اختيار الصفوف =====
            toggleRow(row) {
                const key = row[this.rowIdField];
                if (this.selectedKeys.has(key)) {
                    this.selectedKeys.delete(key);
                } else {
                    this.selectedKeys.add(key);
                }
                this.selectAll =
                    this.rows.length > 0 &&
                    this.rows.every((r) => this.selectedKeys.has(r[this.rowIdField]));
            },

            toggleSelectAll() {
                if (this.selectAll) {
                    this.rows.forEach((r) => this.selectedKeys.add(r[this.rowIdField]));
                } else {
                    this.rows.forEach((r) => this.selectedKeys.delete(r[this.rowIdField]));
                }
            },

            isSelected(row) {
                return this.selectedKeys.has(row[this.rowIdField]);
            },

            getSingleSelection() {
                if (this.selectedKeys.size === 1) {
                    const id = Array.from(this.selectedKeys)[0];
                    return this.rows.find((r) => r[this.rowIdField] === id);
                }
                return null;
            },

            // ===== التصدير =====
            exportData(type) {
                if (!this.allowExport) return;
                let csv = "";
                const headers = this.visibleColumns().map((c) => c.label).join(",");
                csv += headers + "\n";
                this.rows.forEach((r) => {
                    csv += this.visibleColumns()
                        .map((c) => r[c.field] ?? "")
                        .join(",") + "\n";
                });

                const blob = new Blob([csv], {
                    type:
                        type === "excel"
                            ? "application/vnd.ms-excel"
                            : "text/csv;charset=utf-8;"
                });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = `export.${type === "excel" ? "xls" : "csv"}`;
                a.click();
                URL.revokeObjectURL(url);
            },

            // ===== عرض/تنفيذ الإجراءات =====
            async doAction(action, row) {
                if (!action) return;

                // تأكيد
                if (action.confirmText) {
                    if (!confirm(action.confirmText)) return;
                }

                // فتح مودال (تفاصيل أو فورم)
                if (action.openModal) {
                    this.openModal(action, row);
                    return;
                }

                // تنفيذ SP مباشر
                if (action.saveSp) {
                    await this.executeSp(action.saveSp, action.saveOp || "execute", row);
                    if (this.autoRefresh) this.load();
                }

                // لو في JS مخصص
                if (action.onClickJs) {
                    eval(action.onClickJs);
                }
            },

            async executeSp(sp, op, row) {
                try {
                    const body = {
                        Component: "Table",
                        SpName: sp,
                        Operation: op,
                        Params: row || {}
                    };
                    const resp = await fetch(this.endpoint, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify(body)
                    });
                    const json = await resp.json();
                    if (!json.success) throw new Error(json.error || "فشل العملية");
                    return true;
                } catch (e) {
                    alert("⚠️ " + e.message);
                    return false;
                }
            },

            // ===== المودال =====
            async openModal(action, row) {
                this.modal.open = true;
                this.modal.title = action.modalTitle || action.label || "";
                this.modal.action = action;
                this.modal.loading = true;
                this.modal.error = null;
                this.modal.html = "";

                try {
                    // تحميل فورم أو بيانات تفاصيل
                    if (action.formUrl) {
                        const url = this.fillUrl(action.formUrl, row);
                        const resp = await fetch(url);
                        this.modal.html = await resp.text();
                    } else if (action.openForm) {
                        // TODO: توليد HTML من openForm (ممكن بالـ server-side)
                        this.modal.html = "<div>📋 فورم مخصص</div>";
                    } else if (action.modalSp) {
                        const body = {
                            Component: "Table",
                            SpName: action.modalSp,
                            Operation: action.modalOp || "detail",
                            Params: row || {}
                        };
                        const resp = await fetch(this.endpoint, {
                            method: "POST",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify(body)
                        });
                        const json = await resp.json();
                        if (!json.success) throw new Error(json.error || "خطأ");
                        this.modal.html = `<pre>${JSON.stringify(
                            json.data,
                            null,
                            2
                        )}</pre>`;
                    }
                } catch (e) {
                    this.modal.error = e.message;
                } finally {
                    this.modal.loading = false;
                }
            },

            closeModal() {
                this.modal.open = false;
                this.modal.html = "";
                this.modal.action = null;
            },

            async saveModalChanges() {
                if (!this.modal.action) return;
                if (this.modal.action.isEdit || this.modal.action.openForm) {
                    // إرسال النموذج الموجود داخل المودال
                    const form = document.querySelector(".sf-modal form");
                    if (form) {
                        const formData = new FormData(form);
                        const body = Object.fromEntries(formData.entries());
                        await this.executeSp(
                            this.modal.action.saveSp,
                            this.modal.action.saveOp || "update",
                            body
                        );
                        if (this.autoRefresh) this.load();
                        this.closeModal();
                    }
                }
            },

            // ===== أدوات =====
            formatCell(row, col) {
                let val = row[col.field];
                if (val == null) return "";
                switch (col.type) {
                    case "date":
                        return new Date(val).toLocaleDateString();
                    case "datetime":
                        return new Date(val).toLocaleString();
                    case "bool":
                        return val
                            ? '<span class="text-green-600">✔</span>'
                            : '<span class="text-red-600">✘</span>';
                    case "money":
                        return new Intl.NumberFormat().format(val);
                    case "badge":
                        return `<span class="${col.badge?.map?.[val] || col.badge?.defaultClass || "bg-gray-100 text-gray-700"}">${val}</span>`;
                    default:
                        return val;
                }
            },

            fillUrl(url, row) {
                if (!row) return url;
                return url.replace(/\{(\w+)\}/g, (_, k) => row[k] ?? "");
            },

            // ===== الترقيم =====
            nextPage() {
                if (this.page < this.pages) {
                    this.page++;
                    this.load();
                }
            },
            prevPage() {
                if (this.page > 1) {
                    this.page--;
                    this.load();
                }
            },
            firstPage() {
                this.page = 1;
                this.load();
            },
            lastPage() {
                this.page = this.pages;
                this.load();
            },
            rangeText() {
                if (this.total === 0) return "0 من 0";
                const start = (this.page - 1) * this.pageSize + 1;
                const end = Math.min(this.page * this.pageSize, this.total);
                return `${start} - ${end} من ${this.total}`;
            }
        }));
    };
    if (window.Alpine) register();
    else document.addEventListener("alpine:init", register);
})();
