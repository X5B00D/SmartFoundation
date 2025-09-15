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

            showHeader: cfg.showHeader !== false,
            showFooter: cfg.showFooter !== false,

            autoRefresh: !!cfg.autoRefresh,

            columns: Array.isArray(cfg.columns) ? cfg.columns : [],
            actions: Array.isArray(cfg.actions) ? cfg.actions : [],

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
                this.loadStoredPreferences();
                this.load();
                this.setupEventListeners();
            },

            // ===== تحميل التفضيلات المحفوظة =====
            loadStoredPreferences() {
                if (!this.storageKey) return;

                try {
                    const stored = localStorage.getItem(this.storageKey);
                    if (stored) {
                        const prefs = JSON.parse(stored);
                        this.pageSize = prefs.pageSize || this.pageSize;
                        this.sort = prefs.sort || this.sort;

                        // حفظ حالة الأعمدة المخفية
                        if (prefs.columns) {
                            this.columns = this.columns.map(col => {
                                const storedCol = prefs.columns.find(c => c.field === col.field);
                                return storedCol ? { ...col, visible: storedCol.visible } : col;
                            });
                        }
                    }
                } catch (e) {
                    console.warn("Failed to load stored preferences", e);
                }
            },

            // ===== حفظ التفضيلات =====
            savePreferences() {
                if (!this.storageKey) return;

                const prefs = {
                    pageSize: this.pageSize,
                    sort: this.sort,
                    columns: this.columns.map(col => ({
                        field: col.field,
                        visible: col.visible !== false
                    }))
                };

                localStorage.setItem(this.storageKey, JSON.stringify(prefs));
            },

            // ===== إعداد مستمعي الأحداث =====
            setupEventListeners() {
                // إغلاق المودال عند الضغط على ESC
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.modal.open) {
                        this.closeModal();
                    }
                });
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
                            ? [{ Field: "QuickSearch", Op: "contains", Value: this.q }]
                            : []
                    };

                    const resp = await fetch(this.endpoint, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify(body)
                    });

                    if (!resp.ok) throw new Error(`HTTP error! status: ${resp.status}`);

                    const json = await resp.json();
                    if (!json.success) throw new Error(json.error || "خطأ في تحميل البيانات");

                    this.rows = json.data || [];
                    this.total = json.total || this.rows.length;
                    this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));

                    // حفظ التفضيلات بعد التحميل الناجح
                    this.savePreferences();

                } catch (e) {
                    console.error("sfTable.load error", e);
                    this.error = e.message || "⚠️ خطأ غير معروف في تحميل البيانات";
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

            toggleColumnVisibility(col) {
                col.visible = !col.visible;
                this.savePreferences();
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
                this.updateSelectAllState();
            },

            toggleSelectAll() {
                if (this.selectAll) {
                    this.rows.forEach((r) => this.selectedKeys.add(r[this.rowIdField]));
                } else {
                    this.selectedKeys.clear();
                }
                this.updateSelectAllState();
            },

            updateSelectAllState() {
                this.selectAll = this.rows.length > 0 &&
                    this.rows.every((r) => this.selectedKeys.has(r[this.rowIdField]));
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

            clearSelection() {
                this.selectedKeys.clear();
                this.selectAll = false;
            },

            // ===== التصدير =====
            exportData(type) {
                if (!this.allowExport) return;

                try {
                    let content = "";
                    const headers = this.visibleColumns().map((c) => `"${c.label}"`).join(",");
                    content += headers + "\n";

                    this.rows.forEach((r) => {
                        const rowData = this.visibleColumns()
                            .map((c) => {
                                let value = r[c.field] ?? "";
                                if (typeof value === 'string' && value.includes(',')) {
                                    value = `"${value}"`;
                                }
                                return value;
                            })
                            .join(",");
                        content += rowData + "\n";
                    });

                    const mimeType = type === "excel"
                        ? "application/vnd.ms-excel"
                        : "text/csv;charset=utf-8;";

                    const blob = new Blob(["\uFEFF" + content], { type: mimeType });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement("a");
                    a.href = url;
                    a.download = `export_${new Date().toISOString().split('T')[0]}.${type === "excel" ? "xls" : "csv"}`;
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    URL.revokeObjectURL(url);

                } catch (e) {
                    console.error("Export error", e);
                    alert("⚠️ فشل في التصدير: " + e.message);
                }
            },

            // ===== عرض/تنفيذ الإجراءات =====
            async doAction(action, row) {
                if (!action) return;

                try {
                    if (action.requireSelection) {
                        const selectedCount = this.selectedKeys.size;
                        if (selectedCount < action.minSelection ||
                            (action.maxSelection > 0 && selectedCount > action.maxSelection)) {
                            alert(`يجب اختيار بين ${action.minSelection} و ${action.maxSelection} عنصر`);
                            return;
                        }
                    }

                    if (action.confirmText) {
                        if (!confirm(action.confirmText)) return;
                    }

                    if (action.openModal) {
                        await this.openModal(action, row);
                        return;
                    }

                    if (action.saveSp) {
                        const success = await this.executeSp(action.saveSp, action.saveOp || "execute", row);
                        if (success && this.autoRefresh) {
                            this.clearSelection();
                            this.load();
                        }
                        return;
                    }

                    if (action.onClickJs) {
                        try {
                            const func = new Function('table', 'row', 'selectedKeys', action.onClickJs);
                            func(this, row, this.selectedKeys);
                        } catch (e) {
                            console.error("Error executing custom JS", e);
                        }
                    }

                } catch (e) {
                    console.error("Action execution error", e);
                    alert("⚠️ فشل في تنفيذ الإجراء: " + e.message);
                }
            },

            async doBulkDelete() {
                if (this.selectedKeys.size === 0) {
                    alert("⚠️ لم يتم اختيار أي عناصر للحذف");
                    return;
                }

                if (!confirm(`هل تريد حقاً حذف ${this.selectedKeys.size} عنصر؟`)) {
                    return;
                }

                try {
                    const body = {
                        Component: "Table",
                        SpName: this.spName,
                        Operation: "bulk_delete",
                        Params: {
                            ids: Array.from(this.selectedKeys)
                        }
                    };

                    const resp = await fetch(this.endpoint, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify(body)
                    });

                    const json = await resp.json();
                    if (!json.success) throw new Error(json.error || "فشل في الحذف");

                    alert(`✓ تم حذف ${this.selectedKeys.size} عنصر بنجاح`);
                    this.clearSelection();
                    this.load();

                } catch (e) {
                    console.error("Bulk delete error", e);
                    alert("⚠️ فشل في الحذف: " + e.message);
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

                    if (json.message) {
                        this.showToast(json.message, 'success');
                    }

                    return true;
                } catch (e) {
                    console.error("Execute SP error", e);
                    this.showToast("⚠️ " + e.message, 'error');
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
                    if (action.formUrl) {
                        const url = this.fillUrl(action.formUrl, row);
                        const resp = await fetch(url);
                        if (!resp.ok) throw new Error(`Failed to load form: ${resp.status}`);
                        this.modal.html = await resp.text();

                        this.$nextTick(() => {
                            this.initModalScripts();
                        });

                    } else if (action.openForm) {
                        this.modal.html = this.generateFormHtml(action.openForm, row);

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
                        this.modal.html = this.formatDetailView(json.data, action.modalColumns);
                    }
                } catch (e) {
                    console.error("Modal open error", e);
                    this.modal.error = e.message;
                } finally {
                    this.modal.loading = false;
                }
            },

            initModalScripts() {
                const scripts = this.$el.querySelectorAll('.sf-modal script');
                scripts.forEach(script => {
                    const newScript = document.createElement('script');
                    newScript.textContent = script.textContent;
                    document.body.appendChild(newScript).remove();
                });
            },

            generateFormHtml(formConfig, rowData) {
                let html = `<form id="${formConfig.formId}" method="${formConfig.method}" action="${formConfig.actionUrl}">
        <div class="grid grid-cols-12 gap-4">`;

                (formConfig.fields || []).forEach(field => {
                    if (!field.isHidden) {
                        html += this.generateFieldHtml(field, rowData);
                    }
                });

                html += `</div>
        <div class="form-actions mt-4 flex justify-end space-x-2">
            <button type="submit" class="btn btn-success">${formConfig.submitText || "حفظ"}</button>
            <button type="button" class="btn btn-secondary" onclick="this.closest('.sf-modal').__x.$data.closeModal()">
                ${formConfig.cancelText || "إلغاء"}
            </button>
        </div>
    </form>`;

                return html;
            },



            generateFieldHtml(field, rowData) {
                const value = rowData ? rowData[field.name] : field.value || "";
                const colCss = field.colCss || field.ColCss || "col-span-12 md:col-span-6";

                if (field.type === "checkbox") {
                    return `
        <div class="${colCss} flex items-center space-x-2">
            <input type="checkbox" name="${field.name}" id="${field.name}"
                   ${value ? "checked" : ""} 
                   class="sf-input sf-checkbox">
            <label for="${field.name}" class="ml-2">${field.label}</label>
        </div>`;
                }

                return `
    <div class="${colCss}">
    <label class="block text-sm font-medium text-gray-700 mb-1">
        ${field.label}${field.required ? " *" : ""}
    </label>
    <input type="${field.type}" 
           name="${field.name}" 
           value="${value}" 
           placeholder="${field.placeholder || ""}" 
           ${field.required ? "required" : ""} 
           class="w-full px-3 py-2 border rounded-lg shadow-sm focus:ring focus:ring-blue-300 focus:border-blue-500" />
</div>`;
            },




            formatDetailView(data, columns) {
                if (!data) return "<p>لا توجد بيانات</p>";

                let html = '<div class="detail-view">';
                const fields = columns || Object.keys(data);

                fields.forEach(field => {
                    if (data[field] != null) {
                        html += `
                        <div class="detail-row">
                            <strong>${field}:</strong> 
                            <span>${data[field]}</span>
                        </div>`;
                    }
                });

                html += '</div>';
                return html;
            },

            closeModal() {
                this.modal.open = false;
                this.modal.html = "";
                this.modal.action = null;
                this.modal.error = null;
            },

            async saveModalChanges() {
                if (!this.modal.action) return;

                try {
                    if (this.modal.action.isEdit || this.modal.action.openForm) {
                        const form = this.$el.querySelector(".sf-modal form");
                        if (form) {
                            const formData = new FormData(form);
                            const body = Object.fromEntries(formData.entries());

                            const success = await this.executeSp(
                                this.modal.action.saveSp,
                                this.modal.action.saveOp || "update",
                                body
                            );

                            if (success) {
                                this.closeModal();
                                if (this.autoRefresh) {
                                    this.clearSelection();
                                    this.load();
                                }
                            }
                        }
                    }
                } catch (e) {
                    console.error("Save modal changes error", e);
                    this.showToast("⚠️ فشل في الحفظ: " + e.message, 'error');
                }
            },

            // ===== أدوات مساعدة =====
            showToast(message, type = 'info') {
                const toast = document.createElement('div');
                toast.className = `toast toast-${type}`;
                toast.textContent = message;
                toast.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    padding: 12px 20px;
                    border-radius: 4px;
                    color: white;
                    z-index: 10000;
                    background: ${type === 'error' ? '#dc3545' : type === 'success' ? '#28a745' : '#17a2b8'};
                `;

                document.body.appendChild(toast);
                setTimeout(() => toast.remove(), 3000);
            },

            formatCell(row, col) {
                let val = row[col.field];
                if (val == null) return "";

                switch (col.type) {
                    case "date":
                        return new Date(val).toLocaleDateString('ar-SA');
                    case "datetime":
                        return new Date(val).toLocaleString('ar-SA');
                    case "bool":
                        return val
                            ? '<span class="text-green-600">✔</span>'
                            : '<span class="text-red-600">✘</span>';
                    case "money":
                        return new Intl.NumberFormat('ar-SA', {
                            style: 'currency',
                            currency: 'SAR'
                        }).format(val);
                    case "badge":
                        const badgeClass = col.badge?.map?.[val] || col.badge?.defaultClass || "bg-gray-100 text-gray-700";
                        return `<span class="badge ${badgeClass}">${val}</span>`;
                    case "link":
                        const linkTemplate = col.linkTemplate || "#";
                        const href = this.fillUrl(linkTemplate, row);
                        return `<a href="${href}" class="text-blue-600 hover:underline">${val}</a>`;
                    case "image":
                        const imgTemplate = col.imageTemplate || "";
                        const src = this.fillUrl(imgTemplate, row);
                        return `<img src="${src}" alt="${val}" class="table-image" style="max-height: 50px;">`;
                    default:
                        if (col.formatterJs && typeof eval(col.formatterJs) === 'function') {
                            try {
                                return eval(col.formatterJs)(row, col, this);
                            } catch (e) {
                                console.error("Formatter error", e);
                                return val;
                            }
                        }
                        return val;
                }
            },

            fillUrl(url, row) {
                if (!row || !url) return url;
                return url.replace(/\{(\w+)\}/g, (_, k) => row[k] ?? "");
            },

            // ===== الترقيم =====
            goToPage(page) {
                const newPage = Math.max(1, Math.min(page, this.pages));
                if (newPage !== this.page) {
                    this.page = newPage;
                    this.load();
                }
            },

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
                this.goToPage(1);
            },

            lastPage() {
                this.goToPage(this.pages);
            },

            rangeText() {
                if (this.total === 0) return "0 من 0";
                const start = (this.page - 1) * this.pageSize + 1;
                const end = Math.min(this.page * this.pageSize, this.total);
                return `${start} - ${end} من ${this.total}`;
            },

            // ===== أدوات متقدمة =====
            toggleFullscreen() {
                const element = this.$el;
                if (!document.fullscreenElement) {
                    element.requestFullscreen?.().catch(err => {
                        console.error('Error attempting to enable fullscreen:', err);
                    });
                } else {
                    document.exitFullscreen?.();
                }
            },

            changeDensity(density) {
                this.$el.setAttribute('data-density', density);
            }
        }));
    };

    if (window.Alpine) {
        register();
    } else {
        document.addEventListener("alpine:init", register);
    }
})();
