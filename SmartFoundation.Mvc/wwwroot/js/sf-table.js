// wwwroot/js/sf-table.js - Complete Rewrite

window.__sfTableGlobalBound = window.__sfTableGlobalBound || false;

(function () {
    const register = () => {
        Alpine.data("sfTable", (cfg) => ({
            // ===== Configuration Properties =====
            endpoint: cfg.endpoint || "/smart/execute",
            spName: cfg.spName || "",
            operation: cfg.operation || "select",

            // Pagination
            pageSize: cfg.pageSize || 10,
            pageSizes: cfg.pageSizes || [10, 25, 50, 100],
            // NEW: Server paging (fast mode) - off by default
            serverPaging: !!cfg.serverPaging,



            // Search
            searchable: !!cfg.searchable,
            searchPlaceholder: cfg.searchPlaceholder || "بحث…",
            quickSearchFields: cfg.quickSearchFields || [],
            searchDelay: 300,
            searchTimer: null,

            // Display Options
            showHeader: cfg.showHeader !== false,
            showFooter: cfg.showFooter !== false,
            allowExport: !!cfg.allowExport,
            //autoRefresh: !!cfg.autoRefreshOnSubmit,
            autoRefresh: !!(cfg.autoRefresh || cfg.autoRefreshOnSubmit),


            // Cell copy
            enableCellCopy: !!cfg.enableCellCopy,


            // Structure
            columns: Array.isArray(cfg.columns) ? cfg.columns : [],
            actions: Array.isArray(cfg.actions) ? cfg.actions : [],


            // Client-side mode support (new)
            clientSideMode: !!cfg.clientSideMode,
            initialRows: Array.isArray(cfg.rows) ? cfg.rows : [],

            // Selection
            selectable: !!cfg.selectable,
            rowIdField: cfg.rowIdField || "Id",
            singleSelect: !!cfg.singleSelect, // NEW: read from config

            stripHtml(html) {
                const div = document.createElement('div');
                div.innerHTML = html ?? '';
                return (div.textContent || div.innerText || '').trim();
            },


            // ===== Cell Copy Tooltip (fixed over the clicked cell) =====
            showCellCopied(cellEl, msg = "تم النسخ") {
                if (!cellEl) return;

                // add styles once
                if (!window.__sfCellToastStyleAdded) {
                    window.__sfCellToastStyleAdded = true;
                    const st = document.createElement("style");
                    st.textContent = `
            .sf-cell-copied {
                position: fixed;
                padding: 6px 10px;
                border-radius: 4px;
                background: rgba(0,0,0,.9);
                color: #fff;
                font-size: 12px;
                line-height: 1;
                white-space: nowrap;
                overflow: hidden;
                text-overflow: ellipsis;
                max-width: 320px;
                z-index: 999999;
                pointer-events: none;
            }
        `;
                    document.head.appendChild(st);
                }

                // remove any old tooltip
                document.querySelectorAll(".sf-cell-copied").forEach(x => x.remove());

                const rect = cellEl.getBoundingClientRect();

                const tip = document.createElement("div");
                tip.className = "sf-cell-copied";
                tip.textContent = msg;
                document.body.appendChild(tip);

                // center tooltip over cell
                const tipRect = tip.getBoundingClientRect();
                const left = rect.left + (rect.width / 2) - (tipRect.width / 2);
                const gap = 2;
                const top = rect.top - tipRect.height - gap;


                // keep inside viewport
                const safeLeft = Math.max(8, Math.min(left, window.innerWidth - tipRect.width - 8));
                const safeTop = Math.max(8, top);

                tip.style.left = safeLeft + "px";
                tip.style.top = safeTop + "px";

                setTimeout(() => tip.remove(), 900);
            },

            // ===== Modern Copy (NO execCommand) =====
            async copyCell(row, col, e) {
                if (!this.enableCellCopy) return;

                const cellEl = e?.currentTarget || e?.target?.closest("td,th");

                try {
                    const html = this.formatCell(row, col);
                    const text = this.stripHtml(html);
                    if (!text) return;

                    // 1) Secure context + Clipboard API
                    if (navigator.clipboard?.writeText && window.isSecureContext) {
                        await navigator.clipboard.writeText(text);
                        this.showCellCopied(cellEl, "تم النسخ");
                        return;
                    }

                    // 2) Fallback: ClipboardItem (قد يعمل في بعض المتصفحات حتى لو غير secure)
                    if (navigator.clipboard?.write && typeof ClipboardItem !== "undefined") {
                        const blob = new Blob([text], { type: "text/plain" });
                        const item = new ClipboardItem({ "text/plain": blob });
                        await navigator.clipboard.write([item]);
                        this.showCellCopied(cellEl, "تم النسخ");
                        return;
                    }

                    // 3) No supported method
                    this.showCellCopied(cellEl, "المتصفح يمنع النسخ");
                } catch (err) {
                    console.error("Copy cell failed:", err);
                    this.showCellCopied(cellEl, "فشل النسخ");
                }
            },


            // Grouping & Storage
            groupBy: cfg.groupBy || null,
            storageKey: cfg.storageKey || null,

            // Toolbar
            toolbar: cfg.toolbar || {},

            // ===== Internal State =====
            q: "",
            page: 1,
            pages: 0,
            total: 0,
            rows: [],
            allRows: [],
            filteredRows: [],
            sort: { field: null, dir: "asc" },
            loading: false,
            error: null,
            activeIndex: -1,  //  Keyboard row navigation

            // Selection State
            selectedKeys: new Set(),
            selectAll: false,

            // Modal State
            //modal: {
            //    open: false,
            //    title: "",
            //    html: "",
            //    action: null,
            //    loading: false,
            //    error: null
            //},
            // Modal State
            modal: {
                open: false,
                title: "",
                message: "",   // جديد
                messageClass: "",   // NEW
                messageIcon: "",    // NEW
                messageIsHtml: false, // NEW
                html: "",
                action: null,
                loading: false,
                error: null
            },


            //  Step 3: style rules from server
            styleRules: Array.isArray(cfg.styleRules) ? cfg.styleRules : [],

            applyStyleRules(row, col, target /* 'row' | 'cell' | 'column' */) {
                const normTarget = String(target || 'cell').toLowerCase();

                const rules = (this.styleRules || [])
                    .filter(r => {
                        const rt = String(r.target || 'cell').toLowerCase();

                        // ✅ لو target=cell شغّل معه قواعد column أيضًا
                        if (normTarget === 'cell') return rt === 'cell' || rt === 'column';

                        return rt === normTarget;
                    })
                    .filter(r => {
                        const rt = String(r.target || 'cell').toLowerCase();

                        // cell/column لازم Field يطابق العمود الحالي
                        if ((rt === "cell" || rt === "column") && r.field) return r.field === col?.field;

                        // row: لو فيه Field نطبّق حسبه، ولو ما فيه Field نطبّق دائمًا
                        if (rt === "row") return true;

                        return false;
                    })
                    .sort((a, b) => (a.priority || 0) - (b.priority || 0));

                const isMatch = (r) => {
                    const op = String(r.op || "eq").toLowerCase();
                    const val = r.value;

                    let left; // ✅ مهم

                    const rt = String(r.target || 'cell').toLowerCase();
                    if (rt === "row") {
                        // rule صف عام بدون field = يطبق دائمًا
                        if (!r.field) return true;
                        left = row?.[r.field];
                    } else {
                        left = row?.[col?.field];
                    }

                    const l = left ?? "";
                    const v = val ?? "";

                    const ln = Number(l);
                    const vn = Number(v);
                    const bothNum = !Number.isNaN(ln) && !Number.isNaN(vn);

                    switch (op) {
                        case "eq": return String(l) === String(v);
                        case "neq": return String(l) !== String(v);
                        case "gt": return bothNum ? ln > vn : String(l) > String(v);
                        case "gte": return bothNum ? ln >= vn : String(l) >= String(v);
                        case "lt": return bothNum ? ln < vn : String(l) < String(v);
                        case "lte": return bothNum ? ln <= vn : String(l) <= String(v);
                        case "contains": return String(l).includes(String(v));
                        case "startswith": return String(l).startsWith(String(v));
                        case "endswith": return String(l).endsWith(String(v));
                        case "in":
                            if (Array.isArray(val)) return val.map(String).includes(String(l));
                            return String(v).split(",").map(s => s.trim()).includes(String(l));
                        default:
                            return false;
                    }
                };

                let classes = [];
                for (const r of rules) {
                    if (r && r.cssClass && isMatch(r)) {
                        classes.push(r.cssClass);
                        if (r.stopOnMatch) break;
                    }
                }
                return classes.join(" ");
            },




            // ===== Initialization =====
            init() {
                this.loadStoredPreferences();
                this.load();
                this.setupEventListeners();

            },

            loadStoredPreferences() {
                if (!this.storageKey) return;
                try {
                    const stored = localStorage.getItem(this.storageKey);
                    if (stored) {
                        const prefs = JSON.parse(stored);
                        if (prefs.pageSize) this.pageSize = prefs.pageSize;
                        if (prefs.sort) this.sort = prefs.sort;
                        if (prefs.columns && Array.isArray(this.columns)) {
                            this.columns.forEach(col => {
                                const storedCol = prefs.columns.find(c => c.field === col.field);
                                if (storedCol && storedCol.visible !== undefined) {
                                    col.visible = storedCol.visible;
                                }
                            });
                        }
                    }
                } catch (e) {
                    console.warn("Failed to load preferences:", e);
                }
            },

            savePreferences() {
                if (!this.storageKey) return;
                try {
                    const prefs = {
                        pageSize: this.pageSize,
                        sort: this.sort,
                        columns: this.columns.map(col => ({
                            field: col.field,
                            visible: col.visible !== false
                        }))
                    };
                    localStorage.setItem(this.storageKey, JSON.stringify(prefs));
                } catch (e) {
                    console.warn("Failed to save preferences:", e);
                }
            },

            initSelect2InModal(modalEl) {
                if (!window.jQuery || !jQuery.fn || !jQuery.fn.select2) return;

                const $modal = jQuery(modalEl);

                // 1) destroy أي تهيئة قديمة
                $modal.find("select.js-select2").each(function () {
                    const $sel = jQuery(this);
                    if ($sel.hasClass("select2-hidden-accessible")) {
                        $sel.select2("destroy");
                    }
                });

                // 2) init
                $modal.find("select.js-select2").each(function () {
                    const $sel = jQuery(this);

                    const minResults = $sel.data("s2-min-results"); // ممكن undefined
                    const ph =
                        $sel.data("s2-placeholder") ||
                        $sel.find('option[value=""]').text() ||
                        "الرجاء الاختيار";

                    $sel.select2({
                        width: "100%",
                        dir: "rtl",
                        dropdownParent: jQuery(document.body), //  يرسم dropdown فوق المودال
                        placeholder: ph,
                        allowClear: false,
                        minimumResultsForSearch:
                            (minResults === undefined || minResults === null) ? 0 : Number(minResults)
                    });

                });
            },









            setupEventListeners() {
                //  يمنع تكرار ربط الأحداث (لأنه Alpine يسوي instance لكل جدول)
                if (window.__sfTableGlobalBound) return;
                window.__sfTableGlobalBound = true;

                document.addEventListener('keydown', (e) => {
                    if (e.key !== 'Escape') return;
                    const root = document.querySelector('[x-data*="sfTable"]');
                    if (root && root.__x?.$data?.modal?.open) root.__x.$data.closeModal();
                });

                
                document.addEventListener('click', (e) => {
                    const api = window.__sfTableActive;
                    if (!api || !api.modal?.open) return;

                    //  زر X أو زر إلغاء أو أي زر إغلاق
                    if (e.target.closest('.sf-modal-close,[data-modal-close],.sf-modal-cancel,.sf-modal-btn-cancel')) {
                        e.preventDefault();
                        api.closeModal();
                        return;
                    }

                    //  الضغط على الخلفية (خارج الصندوق) يغلق المودال
                    const backdrop = e.target.closest('.sf-modal-backdrop');
                    if (backdrop) {
                        const inside = e.target.closest('.sf-modal');
                        if (!inside) {
                            e.preventDefault();
                            api.closeModal();
                        }
                    }
                });


                // depends dropdowns (listener واحد فقط)
                document.addEventListener('change', async (e) => {
                    const parentSelect = e.target.closest('select');
                    if (!parentSelect) return;

                    const parentName = parentSelect.name;
                    if (!parentName) return;

                    const form = parentSelect.closest('form');
                    if (!form) return;

                    const dependentSelects = form.querySelectorAll(`select[data-depends-on="${parentName}"]`);

                    for (const dependentSelect of dependentSelects) {
                        const dependsUrl = dependentSelect.getAttribute('data-depends-url');
                        if (!dependsUrl) continue;

                        const parentValue = parentSelect.value;

                        // ❗ مهم: لا تستخدم return هنا
                        if (!parentValue || parentValue === '-1') {
                            dependentSelect.innerHTML = '<option value="-1">الرجاء الاختيار</option>';
                            continue;
                        }

                        const originalHtml = dependentSelect.innerHTML;
                        dependentSelect.innerHTML = '<option value="-1">جاري التحميل...</option>';
                        dependentSelect.disabled = true;

                        try {
                            const url = `${dependsUrl}${dependsUrl.includes('?') ? '&' : '?'}DDLValues=${encodeURIComponent(parentValue)}`;
                            const response = await fetch(url, { credentials: 'same-origin' });
                            if (!response.ok) throw new Error(`HTTP ${response.status}`);

                            const data = await response.json();

                            dependentSelect.innerHTML = '';
                            if (Array.isArray(data) && data.length > 0) {
                                for (const item of data) {
                                    const option = document.createElement('option');
                                    option.value = item.value;
                                    option.textContent = item.text;
                                    dependentSelect.appendChild(option);
                                }
                            } else {
                                dependentSelect.innerHTML = '<option value="-1">لا توجد خيارات متاحة</option>';
                            }

                            if (dependentSelect.classList.contains('js-select2')) {
                                const modalEl = dependentSelect.closest('.sf-modal') || document.body;

                                // ✅ إذا كان متفعل select2 على العنصر: أعد تهيئته بعد تغيير الخيارات
                                if (window.jQuery && jQuery.fn.select2) {
                                    const $sel = $(dependentSelect);

                                    if ($sel.hasClass('select2-hidden-accessible')) {
                                        $sel.select2('destroy');
                                    }

                                    // استخدم نفس إعداداتك (ومنها minResults/placeholder من data-attrs)
                                    this.initSelect2InModal(modalEl);
                                }
                            }


                        } catch (error) {
                            console.error('Error loading dependent options:', error);
                            dependentSelect.innerHTML = originalHtml;
                        } finally {
                            dependentSelect.disabled = false;
                        }
                    }
                });
            },


            async load() {
                this.loading = true;
                this.error = null;

                try {
                    // ===== FAST MODE: server-side paging (only if enabled) =====
                    if (this.serverPaging) {
                        const body = {
                            Component: "Table",
                            SpName: this.spName,
                            Operation: this.operation,
                            Paging: { Page: this.page, Size: this.pageSize },
                            Params: {
                                q: this.q || null,
                                sortField: this.sort.field || null,
                                sortDir: this.sort.dir || "asc"
                            }
                        };

                        const json = await this.postJson(this.endpoint, body);

                        // بيانات الصفحة الحالية فقط
                        this.rows = Array.isArray(json?.data) ? json.data : [];

                        // إجمالي السجلات (إذا السيرفر يرجعه)
                        const total = json?.total ?? json?.count ?? json?.Total ?? json?.Count ?? null;

                        // إذا ما رجع total، نخليها صفحة واحدة عشان ما ينكسر شيء
                        if (total == null) {
                            this.total = this.rows.length;
                            this.pages = 1;
                            this.page = 1;
                        } else {
                            this.total = Number(total) || 0;
                            this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));
                            this.page = Math.min(this.page, this.pages);
                        }

                        // في وضع السيرفر ما نحتاج allRows/filteredRows
                        this.allRows = [];
                        this.filteredRows = [];

                        this.savePreferences();
                        this.updateSelectAllState();
                        return;
                    }

                    // ===== OLD MODE (unchanged): client-side =====
                    if (this.allRows.length === 0) {
                        if (this.clientSideMode && Array.isArray(this.initialRows) && this.initialRows.length > 0) {
                            this.allRows = this.initialRows;
                        } else {
                            // نفس كودك القديم كما هو
                            const body = {
                                Component: "Table",
                                SpName: this.spName,
                                Operation: this.operation,
                                Paging: { Page: 1, Size: 1000000 }
                            };

                            const json = await this.postJson(this.endpoint, body);
                            this.allRows = Array.isArray(json?.data) ? json.data : [];
                        }
                    }

                    this.applyFiltersAndSort();

                } catch (e) {
                    console.error("Load error:", e);
                    this.error = e.message || "خطأ في تحميل البيانات";
                } finally {
                    this.loading = false;
                }
            },










            applyFiltersAndSort() {
                let filtered = [...this.allRows];

                if (this.q) {
                    const tokens = String(this.q)
                        .toLowerCase()
                        .trim()
                        .split(/\s+/)
                        .filter(Boolean);

                    //const fields = (this.quickSearchFields && this.quickSearchFields.length)
                    //    ? this.quickSearchFields
                    //    : this.visibleColumns().map(c => c.field);


                    const fields = this.columns
                        .filter(c => c.visible !== false && c.field)
                        .map(c => c.field);

                    //const fields = this.columns
                    //    .filter(c => c.field)
                    //    .map(c => c.field);



                    if (tokens.length) {
                        filtered = filtered.filter(row => {
                            // نجمع كل القيم القابلة للبحث في نص واحد
                            const haystack = fields
                                .map(f => String(row?.[f] ?? "").toLowerCase())
                                .join(" ");

                            // لازم كل كلمات البحث موجودة (AND)
                            return tokens.every(t => haystack.includes(t));
                        });
                    }
                }


                // Apply sorting
                if (this.sort.field) {
                    filtered.sort((a, b) => {
                        let valA = a[this.sort.field];
                        let valB = b[this.sort.field];

                        // Handle nulls
                        if (valA == null && valB == null) return 0;
                        if (valA == null) return 1;
                        if (valB == null) return -1;

                        // Handle numbers
                        if (typeof valA === 'number' && typeof valB === 'number') {
                            return this.sort.dir === 'asc' ? valA - valB : valB - valA;
                        }

                        // Handle dates
                        const dateA = new Date(valA);
                        const dateB = new Date(valB);
                        if (!isNaN(dateA) && !isNaN(dateB)) {
                            return this.sort.dir === 'asc' ? dateA - dateB : dateB - dateA;
                        }

                        // Handle strings
                        valA = String(valA).toLowerCase();
                        valB = String(valB).toLowerCase();

                        if (this.sort.dir === 'asc') {
                            return valA < valB ? -1 : valA > valB ? 1 : 0;
                        } else {
                            return valA > valB ? -1 : valA < valB ? 1 : 0;
                        }
                    });
                }

                this.filteredRows = filtered;
                this.total = filtered.length;
                this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));
                this.page = Math.min(this.page, this.pages);

                // Apply pagination
                const startIdx = (this.page - 1) * this.pageSize;
                this.rows = filtered.slice(startIdx, startIdx + this.pageSize);

                this.savePreferences();
                this.updateSelectAllState();

                //  كل مرة تتغير البيانات/الصفحة/البحث
                //this.$nextTick(() => this.enhanceTableUI());
            },

           

            debouncedSearch() {
                clearTimeout(this.searchTimer);
                this.searchTimer = setTimeout(() => {
                    this.page = 1;
                    if (this.serverPaging) {
                        this.load();            // ✅ سيرفر سايد
                    } else {
                        this.applyFiltersAndSort();
                    }
                }, this.searchDelay);
            },


            refresh() {
                this.allRows = [];
                this.load();
            },

            // ===== Columns Management =====
            visibleColumns() {
                return this.columns.filter(col => col.visible !== false);
            },

            toggleColumnVisibility(col) {
                col.visible = col.visible === false;
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

                this.page = 1;
                if (this.serverPaging) {
                    this.load();                //  سيرفر سايد
                } else {
                    this.applyFiltersAndSort();
                }
            },


            // ===== Selection Management =====
            toggleRow(row) {
                const key = row?.[this.rowIdField];
                if (key == null) return;

                if (this.singleSelect) {
                    // clicking selected row → clear all; else select only this row
                    if (this.selectedKeys.has(key)) {
                        this.selectedKeys.clear();
                    } else {
                        this.selectedKeys.clear();
                        this.selectedKeys.add(key);
                    }
                } else {
                    // original multi-select
                    if (this.selectedKeys.has(key)) {
                        this.selectedKeys.delete(key);
                    } else {
                        this.selectedKeys.add(key);
                    }
                }
                this.updateSelectAllState();
                
            },

            toggleSelectAll() {
                if (this.singleSelect) {
                    // In single-select mode, select first visible row or clear
                    if (this.selectAll && this.rows.length > 0) {
                        this.selectedKeys.clear();
                        this.selectedKeys.add(this.rows[0][this.rowIdField]);
                    } else {
                        this.selectedKeys.clear();
                    }
                } else {
                    if (this.selectAll) {
                        this.rows.forEach(row => this.selectedKeys.add(row[this.rowIdField]));
                    } else {
                        this.selectedKeys.clear();
                    }
                }
                this.updateSelectAllState();
            },

            updateSelectAllState() {
                if (this.singleSelect) {
                    // selectAll reflects whether one selected exists on current page
                    const pageKeys = new Set(this.rows.map(r => r[this.rowIdField]));
                    const hasOnPage = Array.from(this.selectedKeys).some(k => pageKeys.has(k));
                    this.selectAll = hasOnPage && this.selectedKeys.size === 1;
                    return;
                }
                this.selectAll = this.rows.length > 0 &&
                    this.rows.every(row => this.selectedKeys.has(row[this.rowIdField]));
            },

            isSelected(row) {
                return this.selectedKeys.has(row[this.rowIdField]);
            },

            getSingleSelection() {
                if (this.selectedKeys.size === 1) {
                    const id = Array.from(this.selectedKeys)[0];
                    return this.allRows.find(row => row[this.rowIdField] === id);
                }
                return null;
            },

            clearSelection() {
                this.selectedKeys.clear();
                this.selectAll = false;
            },

           
            // ===== Export Functions =====
            exportData(type, scope = 'page') {
                if (!this.allowExport) return;

                try {
                    const dataToExport = scope === 'filtered' ? this.filteredRows : this.rows;
                    const visibleCols = this.visibleColumns().filter(col => col.showInExport !== false);

                    let content = "\uFEFF"; // UTF-8 BOM

                    // Headers
                    const headers = visibleCols.map(col => `"${col.label || col.field}"`).join(",");
                    content += headers + "\r\n";

                    // Rows
                    dataToExport.forEach(row => {
                        const rowData = visibleCols.map(col => {
                            let value = this.formatCellForExport(row, col);
                            // Escape quotes and wrap in quotes if contains comma
                            if (typeof value === 'string') {
                                value = value.replace(/"/g, '""');
                                if (value.includes(',') || value.includes('\n') || value.includes('\r')) {
                                    value = `"${value}"`;
                                }
                            }
                            return value;
                        }).join(",");
                        content += rowData + "\r\n";
                    });

                    const mimeType = type === "excel" ? "application/vnd.ms-excel" : "text/csv;charset=utf-8";
                    const extension = type === "excel" ? "xls" : "csv";

                    this.downloadFile(content, `export_${new Date().toISOString().slice(0, 10)}.${extension}`, mimeType);

                } catch (e) {
                    console.error("Export error:", e);
                    this.showToast("فشل في التصدير: " + e.message, 'error');
                }
            },

            formatCellForExport(row, col) {
                let value = row[col.field];
                if (value == null) return "";

                switch (col.type) {
                    case "date":
                        return new Date(value).toLocaleDateString('ar-SA');
                    case "datetime":
                        return new Date(value).toLocaleString('ar-SA');
                    case "bool":
                        return value ? "نعم" : "لا";
                    case "money":
                        try {
                            return new Intl.NumberFormat('ar-SA', {
                                style: 'currency',
                                currency: 'SAR'
                            }).format(value);
                        } catch {
                            return value;
                        }
                    default:
                        return String(value);
                }
            },

            downloadFile(content, filename, mimeType) {
                const blob = new Blob([content], { type: mimeType });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = filename;
                a.style.display = 'none';
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            },

            // ===== Actions Management =====
            async doAction(action, row) {
                if (!action) return;

                try {
                    // Check selection requirements
                    if (action.requireSelection) {
                        const selectedCount = this.selectedKeys.size;
                        if (selectedCount < (action.minSelection || 1)) {
                            this.showToast(`يجب اختيار ${action.minSelection || 1} عنصر على الأقل`, 'error');
                            return;
                        }
                        if (action.maxSelection > 0 && selectedCount > action.maxSelection) {
                            this.showToast(`لا يمكن اختيار أكثر من ${action.maxSelection} عنصر`, 'error');
                            return;
                        }
                    }

                    // Confirm if needed
                    if (action.confirmText && !confirm(action.confirmText)) {
                        return;
                    }

                    // Open modal
                    if (action.openModal) {
                        await this.openModal(action, row);
                        return;
                    }

                    // Execute stored procedure
                    if (action.saveSp) {
                        const success = await this.executeSp(action.saveSp, action.saveOp || "execute", row);
                        if (success && this.autoRefresh) {
                            this.clearSelection();
                            await this.refresh();
                        }
                        return;
                    }

                } catch (e) {
                    console.error("Action error:", e);
                    this.showToast("فشل في تنفيذ الإجراء: " + e.message, 'error');
                }
            },

            async doBulkDelete() {
                if (this.selectedKeys.size === 0) {
                    this.showToast("لم يتم اختيار أي عناصر للحذف", 'error');
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
                        Params: { ids: Array.from(this.selectedKeys) }
                    };

                    await this.postJson(this.endpoint, body);
                    this.showToast(`تم حذف ${this.selectedKeys.size} عنصر بنجاح`, 'success');
                    this.clearSelection();
                    await this.refresh();

                } catch (e) {
                    console.error("Bulk delete error:", e);
                    this.showToast("فشل في الحذف: " + e.message, 'error');
                }
            },

            // ===== Modal Management =====
            async openModal(action, row) {
                this.modal.open = true;
                window.__sfTableActive = this; //جديد
                this.modal.title = action.modalTitle || action.label || "";
                this.modal.message = action.modalMessage || ""; //  جديد
                this.modal.messageClass = action.modalMessageClass || "";
                this.modal.messageIcon = action.modalMessageIcon || "";
                this.modal.messageIsHtml = !!action.modalMessageIsHtml;
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

                    } else if (action.openForm) {
                        this.modal.html = this.generateFormHtml(action.openForm, row);

                    } else if (action.modalSp) {
                        const body = {
                            Component: "Table",
                            SpName: action.modalSp,
                            Operation: action.modalOp || "detail",
                            Params: row || {}
                        };
                        const json = await this.postJson(this.endpoint, body);
                        this.modal.html = this.formatDetailView(json.data, action.modalColumns);
                    }


                    //this.$nextTick(() => {
                    //    this.initModalScripts();

                    //    const modalEl = this.$el.querySelector('.sf-modal'); // الأفضل من document
                    //    this.initDatePickers(modalEl);



                    //    (function () {
                    //        const modal = document.querySelector('.sf-modal');
                    //        const header = document.querySelector('.sf-modal-header');

                    //        if (!modal || !header) return;

                    //        let isDragging = false;
                    //        let startX = 0;
                    //        let startY = 0;
                    //        let startLeft = 0;
                    //        let startTop = 0;

                    //        header.addEventListener('mousedown', function (e) {
                    //            e.preventDefault();

                    //            isDragging = true;

                    //            const rect = modal.getBoundingClientRect();

                    //            startX = e.clientX;
                    //            startY = e.clientY;

                    //            startLeft = rect.left;
                    //            startTop = rect.top;

                    //            // أول سحب: فك transform
                    //            modal.style.transform = 'none';
                    //            modal.style.left = startLeft + 'px';
                    //            modal.style.top = startTop + 'px';

                    //            document.addEventListener('mousemove', onMouseMove);
                    //            document.addEventListener('mouseup', onMouseUp);
                    //        });

                    //        function onMouseMove(e) {
                    //            if (!isDragging) return;

                    //            const dx = e.clientX - startX;
                    //            const dy = e.clientY - startY;

                    //            modal.style.left = startLeft + dx + 'px';
                    //            modal.style.top = startTop + dy + 'px';
                    //        }

                    //        function onMouseUp() {
                    //            isDragging = false;

                    //            document.removeEventListener('mousemove', onMouseMove);
                    //            document.removeEventListener('mouseup', onMouseUp);
                    //        }
                    //    })();




                    //    /*initModalSelect2(modalEl);*/
                    //    this.initSelect2InModal(modalEl);
                    //});


                    this.$nextTick(() => {
                        this.initModalScripts();

                        // ✅ الصح: المودال غالباً يُحقن خارج this.$el (Root الجدول)، لذلك خذه من document
                        // ومع ذلك نخلي fallback لـ this.$el لو كان داخلها
                        const modalEl =
                            document.querySelector('.sf-modal') ||
                            this.$el.querySelector('.sf-modal');

                        // لو ما انوجد المودال، لا تكمل (حتى ما يصير null errors)
                        if (!modalEl) return;

                        // ✅ datepickers داخل المودال
                        this.initDatePickers(modalEl);

                        // ✅ drag (خله يشتغل على نفس modalEl بدل document.querySelector)
                        (function () {
                            const modal = modalEl;
                            const header = modal.querySelector('.sf-modal-header');

                            if (!modal || !header) return;

                            // ✅ منع تكرار الربط إذا فتح المودال أكثر من مرة
                            if (modal.__dragBound) return;
                            modal.__dragBound = true;

                            let isDragging = false;
                            let startX = 0;
                            let startY = 0;
                            let startLeft = 0;
                            let startTop = 0;

                            header.addEventListener('mousedown', function (e) {
                                // لا تسحب إذا ضغطت على زر/حقل داخل الهيدر
                                if (e.target.closest('.sf-modal-close,[data-modal-close],button,a,input,select,textarea')) return;

                                e.preventDefault();
                                isDragging = true;

                                const rect = modal.getBoundingClientRect();
                                startX = e.clientX;
                                startY = e.clientY;
                                startLeft = rect.left;
                                startTop = rect.top;

                                // أول سحب: فك transform
                                modal.style.transform = 'none';
                                modal.style.left = startLeft + 'px';
                                modal.style.top = startTop + 'px';

                                document.addEventListener('mousemove', onMouseMove);
                                document.addEventListener('mouseup', onMouseUp);
                            });

                            function onMouseMove(e) {
                                if (!isDragging) return;

                                const dx = e.clientX - startX;
                                const dy = e.clientY - startY;

                                modal.style.left = (startLeft + dx) + 'px';
                                modal.style.top = (startTop + dy) + 'px';
                            }

                            function onMouseUp() {
                                isDragging = false;
                                document.removeEventListener('mousemove', onMouseMove);
                                document.removeEventListener('mouseup', onMouseUp);
                            }
                        })();

                        // ✅ select2 داخل المودال
                        this.initSelect2InModal(modalEl);
                    });







                } catch (e) {
                    console.error("Modal error:", e);
                    this.modal.error = e.message;
                } finally {
                    this.modal.loading = false;
                }
            },

            closeModal() {
                this.modal.open = false;
                this.modal.html = "";
                this.modal.action = null;
                this.modal.error = null;
                this.modal.message = ""; //  جديد
                this.modal.messageClass = "";
                this.modal.messageIcon = "";
                this.modal.messageIsHtml = false;
                if (window.__sfTableActive === this) window.__sfTableActive = null;//جديد
            },



            // ===== Form Generation =====
            generateFormHtml(formConfig, rowData) {
                if (!formConfig) return "";

                const formId = formConfig.formId || "modalForm";
                const method = formConfig.method || "POST";
                const action = formConfig.actionUrl || "#";

                let html = `<form id="${formId}" method="${method}" action="${action}" class="sf-modal-form">`;

                //const formId = formConfig.formId || "modalForm";
                //const method = formConfig.method || "POST";

                //// ✅ امنع أي submit طبيعي يسبب Reload كامل
                //let html = `<form id="${formId}" method="${method}" action="#" onsubmit="return false;" class="sf-modal-form">`;

                

                html += `<div class="grid grid-cols-12 gap-4">`;

                // Generate fields
                (formConfig.fields || []).forEach(field => {
                    if (field.isHidden || field.type === "hidden") {
                        const value = rowData ? (rowData[field.name] || field.value || "") : (field.value || "");
                        html += `<input type="hidden" name="${this.escapeHtml(field.name)}" value="${this.escapeHtml(value)}">`;
                    } else {
                        html += this.generateFieldHtml(field, rowData);
                    }
                });



                // Generate buttons
                if (formConfig.buttons && formConfig.buttons.length > 0) {
                    html += `<div class="col-span-12 flex justify-end gap-2 mt-4">`;
                    formConfig.buttons.forEach(btn => {
                        if (btn.show !== false) {
                            const btnType = btn.type || "button";

                            // تحديد هل هو زر إلغاء
                            const isCancel =
                                btn.isCancel === true ||
                                btn.role === 'cancel' ||
                                (btn.text && (
                                    btn.text === 'إلغاء' ||
                                    btn.text === 'الغاء' ||
                                    btn.text.toLowerCase() === 'cancel'
                                ));

                            // نضيف كلاس sf-modal-cancel لزر الإلغاء
                            const extraClasses = isCancel ? ' sf-modal-cancel' : '';
                            const btnClass = `btn btn-${btn.color || 'secondary'}${extraClasses}`;
                            const icon = btn.icon ? `<i class="${btn.icon}"></i> ` : "";

                            // لا نضع onclick لزر الإلغاء (الـ listener العام يتولى الإغلاق)
                            const onClick = (!isCancel && btn.type !== 'submit') ? (btn.onClickJs || "") : "";

                            html += `<button type="${btnType}" class="${btnClass}" ${onClick ? `onclick="${onClick}"` : ""}>${icon}${btn.text}</button>`;
                        }
                    });
                    html += `</div>`;
                } else {
                    // Default buttons
                    html += `<div class="col-span-12 flex justify-end gap-2 mt-4 sf-modal-actions">`;

                    // زر حفظ
                    html += `<button type="submit" class="btn btn-success sf-modal-btn-save">حفظ</button>`;

                    // زر إلغاء
                    html += `<button type="button" class="btn btn-secondary sf-modal-btn-cancel sf-modal-cancel">إلغاء</button>`;

                    html += `</div>`;


                }



                html += `</div></form>`;
                return html;
            },




            //initDatePickers(rootEl) {
            //    if (typeof flatpickr === "undefined") return;

            //    (rootEl || document)
            //        .querySelectorAll("input.js-date")
            //        .forEach(el => {
            //            if (el._flatpickr) return;

            //            flatpickr(el, {
            //                locale: flatpickr.l10ns.ar,
            //                dateFormat: el.dataset.dateFormat || "Y-m-d",
            //                defaultDate: null,
            //                allowInput: true,
            //                disableMobile: true
            //            });
            //        });
            //},




            enableModalDrag(modalEl) {
                if (!modalEl) return;

                const header = modalEl.querySelector('.sf-modal-header');
                if (!header) return;

                // ✅ منع تكرار الربط لو فتحته أكثر من مرة
                if (modalEl.__dragBound) return;
                modalEl.__dragBound = true;

                let isDragging = false;
                let startX = 0, startY = 0;
                let startLeft = 0, startTop = 0;

                const onMouseMove = (e) => {
                    if (!isDragging) return;

                    const dx = e.clientX - startX;
                    const dy = e.clientY - startY;

                    modalEl.style.left = (startLeft + dx) + 'px';
                    modalEl.style.top = (startTop + dy) + 'px';
                };

                const onMouseUp = () => {
                    isDragging = false;
                    document.removeEventListener('mousemove', onMouseMove);
                    document.removeEventListener('mouseup', onMouseUp);
                };

                header.addEventListener('mousedown', (e) => {
                    // لا تسحب إذا ضغطت على زر الإغلاق
                    if (e.target.closest('.sf-modal-close,[data-modal-close],button,a,input,select,textarea')) return;

                    e.preventDefault();
                    isDragging = true;

                    const rect = modalEl.getBoundingClientRect();
                    startX = e.clientX;
                    startY = e.clientY;
                    startLeft = rect.left;
                    startTop = rect.top;

                    // أول سحب: فك التمركز translate
                    modalEl.style.transform = 'none';
                    modalEl.style.left = startLeft + 'px';
                    modalEl.style.top = startTop + 'px';

                    document.addEventListener('mousemove', onMouseMove);
                    document.addEventListener('mouseup', onMouseUp);
                });
            },





            initDatePickers(rootEl) {
                if (typeof flatpickr === "undefined") return;

                (rootEl || document)
                    .querySelectorAll("input.js-date")
                    .forEach(el => {
                        if (el._flatpickr) return;

                        flatpickr(el, {
                            locale: flatpickr.l10ns.ar,
                            dateFormat: "Y-m-d",
                            altInput: false,       // ← هذا يمنع الصيغة الطويلة
                            defaultDate: null,
                            allowInput: true,
                            disableMobile: true
                        });
                    });
            },

            generateFieldHtml(field, rowData) {
                if (!field || !field.name) return "";

                const value = rowData
                    ? (rowData[field.name] || field.value || "")
                    : (field.value || "");

                const colCss = this.resolveColCss(field.colCss || "6");

                //const required = field.required ? "required" : "";
                //const disabled = field.disabled ? "disabled" : "";
                //const readonly = field.readonly ? "readonly" : "";
                const required = (field.required ?? field.Required) ? "required" : "";
                const disabled = (field.disabled ?? field.Disabled) ? "disabled" : "";
                const readonly = (field.readonly ?? field.Readonly) ? "readonly" : "";


                const placeholder = field.placeholder
                    ? `placeholder="${this.escapeHtml(field.placeholder)}"`
                    : "";

                const maxLength = field.maxLength
                    ? `maxlength="${field.maxLength}"`
                    : "";

                const autocomplete = field.autocomplete
                    ? `autocomplete="${this.escapeHtml(field.autocomplete)}"`
                    : "";

                const spellcheck =
                    (field.spellcheck !== undefined && field.spellcheck !== null)
                        ? `spellcheck="${field.spellcheck ? "true" : "false"}"`
                        : "";

                const autocapitalize = field.autocapitalize
                    ? `autocapitalize="${this.escapeHtml(field.autocapitalize)}"`
                    : "";

                const autocorrect = field.autocorrect
                    ? `autocorrect="${this.escapeHtml(field.autocorrect)}"`
                    : "";

                const textMode = (field.textMode || "").toLowerCase();
                let oninput = "";
                let pattern = "";

                switch (textMode) {
                    case "arabic":
                        oninput = `oninput="this.value=this.value.replace(/[^\\u0600-\\u06FF\\s]/g,'')"`;
                        pattern = 'pattern="[\\u0600-\\u06FF\\s]+"';
                        break;

                    case "english":
                        oninput = `oninput="this.value=this.value.replace(/[^A-Za-z\\s]/g,'')"`;
                        pattern = 'pattern="[A-Za-z\\s]+"';
                        break;

                    case "numeric":
                        oninput = `oninput="this.value=this.value.replace(/[^0-9]/g,'')"`;
                        pattern = 'pattern="[0-9]+"';
                        break;

                    case "alphanumeric":
                        oninput = `oninput="this.value=this.value.replace(/[^A-Za-z0-9\\s]/g,'')"`;
                        pattern = 'pattern="[A-Za-z0-9\\s]+"';
                        break;

                    case "arabicnum":
                        oninput = `oninput="this.value=this.value.replace(/[^\\u0600-\\u06FF0-9\\s]/g,'')"`;
                        pattern = 'pattern="[\\u0600-\\u06FF0-9\\s]+"';
                        break;

                    case "engsentence":
                        oninput = `oninput="this.value=this.value.replace(/[^A-Za-z0-9\\s.,!?'"()-]/g,'')"`;
                        pattern = 'pattern="[A-Za-z0-9\\s.,!?\'\\"()-]+"';
                        break;

                    case "arsentence":
                        oninput = `oninput="this.value=this.value.replace(/[^\\u0600-\\u06FF0-9\\s.,!?،؟'"()-]/g,'')"`;
                        pattern = 'pattern="[\\u0600-\\u06FF0-9\\s.,!?،؟\'\\"()-]+"';
                        break;

                    case "email":
                        oninput = `oninput="this.value=this.value.replace(/[^A-Za-z0-9@._-]/g,'')"`;
                        pattern = 'pattern="[A-Za-z0-9@._-]+"';
                        break;

                    case "url":
                        oninput = `oninput="this.value=this.value.replace(/[^A-Za-z0-9/:.?&=#_-]/g,'')"`;
                        pattern = 'pattern="[A-Za-z0-9/:.?&=#_-]+"';
                        break;

                    case "custom":
                        pattern = field.pattern ? `pattern="${field.pattern}"` : "";
                        oninput = "";
                        break;

                }

                let inputType = (field.type || "text").toLowerCase();

                if (textMode === "email") inputType = "email";
                if (textMode === "url") inputType = "url";


                let fieldHtml = "";


                const hasIcon = field.icon && field.icon.trim() !== "";
                const iconHtml = hasIcon
                    ? `<i class="${this.escapeHtml(field.icon)} absolute right-3 top-3 text-gray-400 pointer-events-none"></i>`
                    : "";


                switch ((field.type || "text").toLowerCase()) {
                    case "text":
                    case "email":
                    case "url":
                    case "search":

                        fieldHtml = `
            <div class="form-group ${colCss}">
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    ${this.escapeHtml(field.label)}
                    ${field.required ? '<span class="text-red-500">*</span>' : ''}
                </label>

                <input
                    
                    type="${inputType}"
                    name="${this.escapeHtml(field.name)}"
                    value="${this.escapeHtml(value)}"
                    class="sf-modal-input"
                    ${placeholder}
                    ${required}
                    ${disabled}
                    ${readonly}
                    ${maxLength}
                    ${autocomplete}
                    ${spellcheck}
                    ${autocapitalize}
                    ${autocorrect}
                    ${pattern}
                    ${oninput}

                />

                ${field.helpText
                                ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>`
                                : ''}
                    </div>`;
                        break;




                    case "textarea":
                        const rows = field.rows || 3;
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}

                            </label>
                            <textarea name="${this.escapeHtml(field.name)}" rows="${rows}"
                                     class="sf-modal-input"
                                     ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>${this.escapeHtml(value)}</textarea>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;




                   
                    case "select": {
                        let options = "";

                        // =========================
                        // 1) Placeholder
                        // =========================
                        options += `<option value="" disabled ${!value ? "selected" : ""}>${this.escapeHtml(field.placeholder || "الرجاء الاختيار")}</option>`;

                        (field.options || []).forEach(opt => {
                            const optValue = opt.value ?? opt.Value ?? "";
                            const optText = opt.text ?? opt.Text ?? "";
                            const selected = String(value) === String(optValue) ? "selected" : "";
                            options += `<option value="${this.escapeHtml(optValue)}" ${selected}>${this.escapeHtml(optText)}</option>`;
                        });

                        // =========================
                        // 2) onchange / depends
                        // =========================
                        let onChangeHandler = field.onChangeJs || "";

                        // إذا يعتمد على قائمة أخرى: لا تضف onchange (لأن listener العام يتولى)
                        if (!(field.dependsUrl && field.dependsOn) && onChangeHandler && !field.dependsUrl) {
                            onChangeHandler = `${onChangeHandler}`;
                        }

                        const onChangeAttr = onChangeHandler ? `onchange="${this.escapeHtml(onChangeHandler)}"` : "";
                        const dependsOnAttr = field.dependsOn ? `data-depends-on="${this.escapeHtml(field.dependsOn)}"` : "";
                        const dependsUrlAttr = field.dependsUrl ? `data-depends-url="${this.escapeHtml(field.dependsUrl)}"` : "";

                        // =========================
                        // 3) ✅ Select2 switch (من الكنترول)
                        // =========================
                        // يدعم camelCase و PascalCase
                        const useSelect2 = !!(field.select2 ?? field.Select2);

                        // اختياري (لو ما تبيها احذفها من هنا ومن FieldConfig)
                        const minResults = field.select2MinResultsForSearch ?? field.Select2MinResultsForSearch;
                        const s2Placeholder = field.select2Placeholder ?? field.Select2Placeholder;

                        // إذا Select2=true ضف الكلاس + data attributes
                        const select2Class = useSelect2 ? "js-select2" : "";
                        const s2MinAttr = (useSelect2 && minResults !== undefined && minResults !== null)
                            ? `data-s2-min-results="${this.escapeHtml(minResults)}"`
                            : "";
                        const s2PhAttr = (useSelect2 && s2Placeholder)
                            ? `data-s2-placeholder="${this.escapeHtml(s2Placeholder)}"`
                            : "";

                        // =========================
                        // 4) HTML
                        // =========================
                        fieldHtml = `
<div class="form-group ${colCss}">
    <label class="block text-sm font-medium text-gray-700 mb-1">
        ${this.escapeHtml(field.label)} ${(field.required ?? field.Required) ? '<span class="text-red-500">*</span>' : ''}
    </label>

    <div class="sf-select-wrap">
        <select
            name="${this.escapeHtml(field.name)}"
            class="sf-modal-input sf-modal-select ${select2Class}"
            ${required}
            ${disabled}
            ${onChangeAttr}
            ${dependsOnAttr}
            ${dependsUrlAttr}
            ${s2MinAttr}
            ${s2PhAttr}
        >
            ${options}
        </select>
    </div>

    ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
</div>`;
                        break;
                    }



                    




                    case "checkbox":
                        const checked = value === true || value === "true" || value === "1" || value === 1 ? "checked" : "";
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="inline-flex items-center">
                                <input type="checkbox" name="${this.escapeHtml(field.name)}" value="1" 
                                       ${checked} ${required} ${disabled}
                                       class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50">
                                <span class="ml-2 text-sm text-gray-700">
                                    ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                                </span>
                            </label>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;


                    case "date":
                        fieldHtml = `
                          <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                            ${this.escapeHtml(field.label)}
                             ${field.required ? '<span class="text-red-500">*</span>' : ''}
                             </label>
                        <div class="relative">
                       ${iconHtml}
                       <input
                       type="text"
                       name="${this.escapeHtml(field.name)}"
                       value="${this.escapeHtml(value)}"
                       class="sf-modal-input js-date ${hasIcon ? "pr-10" : ""}"
                       data-default-date=""
                       data-alt-input="true"
                       data-date-format="Y-m-d"
                       autocomplete="off"
                       ${required} ${disabled} ${readonly}
                       />

                       </div>
                       ${field.helpText
                                ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>`
                                : ''}
                       </div>`;
                        break;


                    case "number":
                        // رقم >= 0 فقط (بدون سالب)
                        const min0 = `min="0"`;
                        const numStep = field.step !== undefined ? `step="${field.step}"` : `step="1"`;
                        const numMax = field.max !== undefined ? `max="${field.max}"` : "";

                        // يمنع إدخال السالب و e و + ويقص أي شيء غير رقم (ويسمح بنقطة لو step فيه كسور)
                        const allowDecimal = String(field.step ?? "").includes('.') || (typeof field.step === 'number' && !Number.isInteger(field.step));
                        const numberOnInput = allowDecimal
                            ? `oninput="this.value=this.value.replace(/[^0-9.]/g,''); if(this.value.startsWith('.')) this.value='0'+this.value; if(this.value.includes('.')){const p=this.value.split('.'); this.value=p[0]+'.'+p.slice(1).join('');}"`
                            : `oninput="this.value=this.value.replace(/\\D/g,'')"`;

                        const numberOnKeyDown =
                            `onkeydown="if(['-','e','E','+'].includes(event.key)) event.preventDefault()"`;

                        fieldHtml = `
                            <div class="form-group ${colCss}">
                                <label class="block text-sm font-medium text-gray-700 mb-1">
                                    ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                                </label>
                                <input
                                    type="number"
                                    inputmode="numeric"
                                    name="${this.escapeHtml(field.name)}"
                                    value="${this.escapeHtml(value)}"
                                    class="sf-modal-input"
                                    ${placeholder}
                                    ${min0}
                                    ${numMax}
                                    ${numStep}
                                    ${required}
                                    ${disabled}
                                    ${readonly}
                                    ${numberOnKeyDown}
                                    ${numberOnInput}
                                    

                                >
                                ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                            </div>`;
                        break;


                            case "nationalid":
                            case "nid":
                            case "identity": {

                                // أرقام فقط + أقصى 10 أرقام
                                const nidOnInput =
                                    `oninput="` +
                                    `this.value=this.value.replace(/\\D/g,'');` +
                                    `if(this.value.length>10)this.value=this.value.slice(0,10);` +
                                    `"`; // ملاحظة: هذا سيشتغل حتى لو readonly (لا يضر)

                                const nidOnKeyDown =
                                    `onkeydown="if(['-','e','E','+','.'].includes(event.key)) event.preventDefault()"`;

                                fieldHtml = `
                                <div class="form-group ${colCss}">
                                    <label class="block text-sm font-medium text-gray-700 mb-1">
                                        ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                                    </label>

                                    <input
                                        type="text"
                                        inputmode="numeric"
                                        name="${this.escapeHtml(field.name)}"
                                        value="${this.escapeHtml(value)}"
                                        class="sf-modal-input"
                                        ${placeholder}
                                        ${required}
                                        ${disabled}
                                        ${readonly}

                                        autocomplete="new-password"
                                        autocorrect="off"
                                        autocapitalize="off"
                                        spellcheck="false"

                                        maxlength="10"
                                        pattern="^[0-9]{1,10}$"
                                        title="الهوية الوطنية يجب أن تكون أرقام فقط وبحد أقصى 10 رقم"

                                        ${nidOnKeyDown}
                                        ${nidOnInput}
                                    />
                                    ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                                </div>`;
                            break;
                           }



                    
                    case "phone":
                    case "tel": {

                        const normalizeFn = `
                                (function(el){
                                    let v = (el.value || '');

                                    // digits to ascii
                                    v = v.replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d));
                                    v = v.replace(/[۰-۹]/g, d => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d));

                                    // keep digits only
                                    v = v.replace(/\\s+/g,'');
                                    v = v.replace(/^\\+/, '');      // +966... -> 966...
                                    v = v.replace(/\\D/g,'');

                                    // Saudi normalize to 05XXXXXXXX
                                    if (v.startsWith('966') ) v = '0' + v.slice(3);     // 9665xxxxxxxx -> 05xxxxxxxx
                                    if (v.startsWith('00966')) v = '0' + v.slice(5);    // 009665xxxxxxxx -> 05xxxxxxxx
                                    if (v.startsWith('5') && v.length === 9) v = '0' + v; // 5xxxxxxxx -> 05xxxxxxxx

                                    // force prefix 05 if user started typing mobile
                                    if (v.length >= 2 && !v.startsWith('05')) {
                                        if (v.startsWith('0')) v = '05' + v.slice(2);
                                        else v = '05' + v.replace(/^05/, '').slice(0); // fallback
                                    }

                                    if (v.length > 10) v = v.slice(0,10);
                                    el.value = v;
                                })(this);
                            `;

                                                const validateFn = `
                                (function(el){
                                    // normalize first
                                    ${normalizeFn.replace(/this/g, 'el')}

                                    const v = (el.value || '');
                                    if (${field.required ? 'true' : 'false'} && !v) {
                                        el.setCustomValidity('رقم الجوال مطلوب');
                                        return;
                                    }
                                    if (!v) { el.setCustomValidity(''); return; }

                                    if (!/^05\\d{8}$/.test(v)) {
                                        el.setCustomValidity('رقم الجوال يجب أن يبدأ بـ 05 ثم 8 أرقام');
                                    } else {
                                        el.setCustomValidity('');
                                    }
                                })(this);
                            `;

                        // initial normalize (server value)
                        const initial = (() => {
                            let v = (value ?? '').toString();
                            v = v.replace(/[٠-٩]/g, d => '٠١٢٣٤٥٦٧٨٩'.indexOf(d));
                            v = v.replace(/[۰-۹]/g, d => '۰۱۲۳۴۵۶۷۸۹'.indexOf(d));
                            v = v.replace(/\s+/g, '').replace(/^\+/, '').replace(/\D/g, '');

                            if (v.startsWith('00966')) v = '0' + v.slice(5);
                            if (v.startsWith('966')) v = '0' + v.slice(3);
                            if (v.startsWith('5') && v.length === 9) v = '0' + v;
                            if (v.length > 10) v = v.slice(0, 10);
                            return v;
                        })();

                        // IMPORTANT: oninput لا يعرض رسالة، فقط يطبّع
                        const onInput = `oninput="${normalizeFn} this.setCustomValidity('');"`;
                        // التحقق فقط عند blur/invalid
                        const onBlur = `onblur="${validateFn}"`;
                        const onInvalid = `oninvalid="${validateFn}"`;

                        // الأهم: قبل الإرسال مباشرة (يغطي أي validator عام)
                        // نستخدم onsubmit على الفورم عبر formaction؟ لا. لذلك نضيف onchange + blur كافي عادة
                        // لكن لضمان 100% أضف onkeyup أيضًا (اختياري)
                        const onChange = `onchange="${normalizeFn}"`;

                        const onKeyDown =
                            `onkeydown="if(['-','e','E','+','.'].includes(event.key)) event.preventDefault()"`;

                        fieldHtml = `
                                <div class="form-group ${colCss}">
                                    <label class="block text-sm font-medium text-gray-700 mb-1">
                                        ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                                    </label>

                                    <input
                                        type="text"
                                        inputmode="numeric"
                                        name="${this.escapeHtml(field.name)}"
                                        value="${this.escapeHtml(initial)}"
                                        class="sf-modal-input"
                                        ${placeholder}
                                        ${required}
                                        ${disabled}
                                        ${readonly}

                                        data-sa-mobile="1"
                                        autocomplete="new-password"
                                        autocorrect="off"
                                        autocapitalize="off"
                                        spellcheck="false"

                                        maxlength="10"
                                        title="مثال: 05XXXXXXXX"

                                        ${onKeyDown}
                                        ${onChange}
                                        ${onInvalid}
                                        ${onBlur}
                                        ${onInput}
                                    />

                                    ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                                </div>`;
                                                        break;
                                                    }







                    case "iban":
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}

                            </label>
                            <input type="text" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
                                   ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;

                    default:
                        // Fallback to text input
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}

                            </label>
                            <input type="text" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="sf-modal-input"
                                   ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                }

                return fieldHtml;
            },

            resolveColCss(colCss) {
                if (!colCss) return "col-span-12 md:col-span-6";

                if (/^\d{1,2}$/.test(colCss)) {
                    const n = Math.max(1, Math.min(12, parseInt(colCss, 10)));
                    return `col-span-12 md:col-span-${n}`;
                }

                return colCss.includes('col-span') ? colCss : `col-span-12 ${colCss}`;
            },

            //initModalScripts() {
            //    // Set up form submission
            //    const form = this.$el.querySelector('.sf-modal form');
            //    if (form) {
            //        form.addEventListener('submit', (e) => {
            //            e.preventDefault();
            //            this.saveModalChanges();
            //        });

            //        // Set up dependent dropdowns
            //        this.setupDependentDropdowns(form);
            //    }
            //},

            initModalScripts() {
                const form = this.$el.querySelector('.sf-modal form');
                if (form) {

                    // ===== تخصيص رسالة required =====
                    form.querySelectorAll("[required]").forEach(input => {

                        // منع رسالة المتصفح الافتراضية
                        input.addEventListener("invalid", function (e) {
                            e.preventDefault();
                            this.setCustomValidity("حقل إجباري");
                        });

                        // عند تعديل المدخلات، أعد التحقق
                        input.addEventListener("input", function () {
                            this.setCustomValidity("");
                        });
                    });
                    // ===== نهاية تعديل required =====

                    form.addEventListener('submit', (e) => {
                        e.preventDefault();
                        this.saveModalChanges();
                    });

                    /*this.setupDependentDropdowns(form);*/
                }
            },
        

            setupDependentDropdowns(form) {
                // Find all selects with data-depends-on attribute
                const dependentSelects = form.querySelectorAll('select[data-depends-on]');
                
                dependentSelects.forEach(dependentSelect => {
                    const parentFieldName = dependentSelect.getAttribute('data-depends-on');
                    const dependsUrl = dependentSelect.getAttribute('data-depends-url');
                    
                    if (!parentFieldName || !dependsUrl) return;
                    
                    // Find the parent select
                    const parentSelect = form.querySelector(`select[name="${parentFieldName}"]`);
                    if (!parentSelect) {
                        console.warn(`Parent select not found: ${parentFieldName}`);
                        return;
                    }
                    
                    // Attach change handler to parent
                    parentSelect.addEventListener('change', async (e) => {
                        const parentValue = e.target.value;
                        
                        // Show loading state
                        const originalHtml = dependentSelect.innerHTML;
                        dependentSelect.innerHTML = '<option value="-1">جاري التحميل...</option>';
                        dependentSelect.disabled = true;
                        
                        try {
                            // Build URL with parent value
                            const url = `${dependsUrl}?${parentFieldName}=${encodeURIComponent(parentValue)}`;
                            
                            // Fetch new options
                            const response = await fetch(url);
                            if (!response.ok) {
                                throw new Error(`HTTP ${response.status}`);
                            }
                            
                            const data = await response.json();
                            
                            // Rebuild options
                            dependentSelect.innerHTML = '';
                            
                            if (Array.isArray(data) && data.length > 0) {
                                data.forEach(item => {
                                    const option = document.createElement('option');
                                    option.value = item.value;
                                    option.textContent = item.text;
                                    dependentSelect.appendChild(option);
                                });
                            } else {
                                dependentSelect.innerHTML = '<option value="-1">لا توجد خيارات متاحة</option>';
                            }


                            // ✅ تحديث select2 بعد تغيير الخيارات
                            if (window.jQuery && jQuery.fn.select2 && dependentSelect.classList.contains('js-select2')) {
                                const parentModal = dependentSelect.closest('.sf-modal') || document.body;

                                $(dependentSelect).select2('destroy');
                                $(dependentSelect).select2({
                                    width: '100%',
                                    dir: 'rtl',
                                    dropdownParent: $(parentModal)
                                });
                            }

                            
                        } catch (error) {
                            console.error('Error loading dependent options:', error);
                            dependentSelect.innerHTML = originalHtml;
                            this.showToast('فشل تحميل الخيارات: ' + error.message, 'error');
                        } finally {
                            dependentSelect.disabled = false;
                        }
                    });
                    
                    // Trigger initial load if parent has value
                    if (parentSelect.value && parentSelect.value !== '' && parentSelect.value !== '-1') {
                        parentSelect.dispatchEvent(new Event('change'));
                    }
                });
            },

            async saveModalChanges() {
                if (!this.modal.action) return;

                const form = this.$el.querySelector('.sf-modal form');
                if (!form) return;

                try {
                    this.modal.loading = true;
                    this.modal.error = null;

                    const formData = this.serializeForm(form);

                    //const success = await this.executeSp(
                    //    this.modal.action.saveSp,
                    //    this.modal.action.saveOp || (this.modal.action.isEdit ? "update" : "insert"),
                    //    formData
                    //);

                    const result = await this.executeSp(
                        this.modal.action.saveSp,
                        this.modal.action.saveOp || (this.modal.action.isEdit ? "update" : "insert"),
                        formData
                    );

                    if (result) {
                        // ✅ تحديث سريع بدون refresh ثقيل
                        if (this.serverPaging) {
                            await this.load(); // يرجّع نفس الصفحة فقط
                        } else {
                            const saved = result.data || result.row || result.item || null;
                            const id = (saved && saved[this.rowIdField]) ?? formData[this.rowIdField];

                            if (saved) {
                                const idx = this.allRows.findIndex(r => r[this.rowIdField] == id);
                                if (idx >= 0) this.allRows[idx] = { ...this.allRows[idx], ...saved };
                                else this.allRows.unshift(saved);
                            }

                            this.applyFiltersAndSort();
                        }

                        this.closeModal();
                        this.clearSelection();
                    }


                    if (success) {
                        this.closeModal();
                        if (this.autoRefresh) {
                            this.clearSelection();
                            await this.refresh();
                        }
                    }

                } catch (e) {
                    console.error("Save error:", e);
                    this.modal.error = e.message || "فشل في الحفظ";
                } finally {
                    this.modal.loading = false;
                }
            },


            


            formatDetailView(data, columns) {
                if (!data) return "<p>لا توجد بيانات</p>";
                
                let html = '<div class="detail-view space-y-2">';
                const fields = columns?.length ? columns : Object.keys(data);
                
                fields.forEach(field => {
                    const key = typeof field === 'string' ? field : (field.field || field.Field);
                    const label = typeof field === 'string' ? key : (field.label || field.Label || key);
                    
                    if (data[key] != null) {
                        html += `
                        <div class="detail-row flex">
                            <strong class="min-w-32 text-gray-600">${this.escapeHtml(label)}:</strong>
                            <span class="flex-1 mr-2">${this.escapeHtml(data[key])}</span>
                        </div>`;
                    }
                });
                
                html += '</div>';
                return html;
            },

            // ===== Form Serialization =====
            serializeForm(form) {
                const formData = new FormData(form);
                const data = {};
                
                // Handle regular form fields
                for (const [key, value] of formData.entries()) {
                    if (data[key]) {
                        // Multiple values - convert to array
                        if (Array.isArray(data[key])) {
                            data[key].push(value);
                        } else {
                            data[key] = [data[key], value];
                        }
                    } else {
                        data[key] = value;
                    }
                }
                
                // Handle unchecked checkboxes
                form.querySelectorAll('input[type="checkbox"][name]').forEach(checkbox => {
                    if (!formData.has(checkbox.name)) {
                        data[checkbox.name] = false;
                    } else {
                        data[checkbox.name] = true;
                    }
                });
                
                // Clean up data types
                Object.keys(data).forEach(key => {
                    let value = data[key];
                    if (typeof value === 'string') {
                        const trimmed = value.trim();
                        if (trimmed === '') {
                            data[key] = null;
                        } else if (/^\d+$/.test(trimmed) && !trimmed.startsWith('0')) {
                            data[key] = parseInt(trimmed, 10);
                        } else if (/^\d+\.\d+$/.test(trimmed)) {
                            data[key] = parseFloat(trimmed);
                        } else {
                            data[key] = trimmed;
                        }
                    }
                });
                
                return data;
            },

            // ===== Server Communication =====
            //async executeSp(spName, operation, params) {
            //    try {
            //        const body = {
            //            Component: "Form",
            //            SpName: spName,
            //            Operation: operation,
            //            Params: params || {}
            //        };

            //        const result = await this.postJson(this.endpoint, body);

            //        if (result?.message) {
            //            this.showToast(result.message, 'success');
            //        }

            //        return true;

            //    } catch (e) {
            //        console.error("Execute SP error:", e);
            //        this.showToast("⚠️ " + (e.message || "فشل العملية"), 'error');

            //        if (e.server?.errors) {
            //            this.applyServerErrors(e.server.errors);
            //        }

            //        return false;
            //    }
            //},

            async executeSp(spName, operation, params) {
                try {
                    const body = {
                        Component: "Form",
                        SpName: spName,
                        Operation: operation,
                        Params: params || {}
                    };

                    const result = await this.postJson(this.endpoint, body);

                    if (result?.message) this.showToast(result.message, 'success');

                    return result; // ✅ بدل true
                } catch (e) {
                    console.error("Execute SP error:", e);
                    this.showToast("⚠️ " + (e.message || "فشل العملية"), 'error');

                    if (e.server?.errors) this.applyServerErrors(e.server.errors);

                    return null;
                }
            },


            async postJson(url, body) {
                const headers = { "Content-Type": "application/json" };
                
                // Add CSRF token if available
                const csrfToken = this.getCsrfToken();
                if (csrfToken) {
                    headers["RequestVerificationToken"] = csrfToken;
                }
                
                const response = await fetch(url, {
                    method: "POST",
                    headers,
                    body: JSON.stringify(body)
                });
                
                let json = null;
                try {
                    json = await response.json();
                } catch (e) {
                    // Response is not JSON
                }
                
                if (!response.ok) {
                    const message = json?.error || `HTTP ${response.status}`;
                    throw new Error(message);
                }
                
                if (json && json.success === false) {
                    const error = new Error(json.error || "العملية فشلت");
                    error.server = json;
                    throw error;
                }
                
                return json;
            },

            getCsrfToken() {
                const meta = document.querySelector('meta[name="request-verification-token"]');
                if (meta?.content) return meta.content;
                
                const input = document.querySelector('input[name="__RequestVerificationToken"]');
                return input?.value || null;
            },

            applyServerErrors(errors) {
                const form = this.$el.querySelector('.sf-modal form');
                if (!form || !errors) return;
                
                // Clear existing errors
                form.querySelectorAll('[data-error-msg]').forEach(el => el.remove());
                form.querySelectorAll('.ring-red-500, .border-red-500').forEach(el => {
                    el.classList.remove('ring-red-500', 'border-red-500', 'ring-1');
                });
                
                // Apply new errors
                Object.entries(errors).forEach(([fieldName, message]) => {
                    const field = form.querySelector(`[name="${fieldName}"]`);
                    if (field) {
                        field.classList.add('border-red-500', 'ring-1', 'ring-red-500');
                        
                        const errorDiv = document.createElement('div');
                        errorDiv.className = 'text-red-600 text-sm mt-1';
                        errorDiv.setAttribute('data-error-msg', '1');
                        errorDiv.textContent = Array.isArray(message) ? message.join(', ') : String(message);
                        
                        field.parentElement.appendChild(errorDiv);
                    }
                });
            },

            // ===== Cell Formatting =====
            //formatCell(row, col) {
            //    let value = row[col.field];
            //    if (value == null) return "";

            //    switch (col.type) {
            //        case "date":
            //            try {
            //                return new Date(value).toLocaleDateString('ar-SA');
            //            } catch {
            //                return value;
            //            }
            //        case "datetime":
            //            try {
            //                return new Date(value).toLocaleString('ar-SA');
            //            } catch {
            //                return value;
            //            }
            //        case "bool":
            //            return value ? '<span class="text-green-600">✓</span>' : '<span class="text-red-600">✗</span>';
            //        case "money":
            //            try {
            //                return new Intl.NumberFormat('ar-SA', {
            //                    style: 'currency',
            //                    currency: 'SAR'
            //                }).format(value);
            //            } catch {
            //                return value;
            //            }
            //        case "badge":
            //            const badgeClass = col.badge?.map?.[value] || col.badge?.defaultClass || "bg-gray-100 text-gray-800";
            //            return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badgeClass}">${this.escapeHtml(value)}</span>`;
            //        case "link":
            //            if (col.linkTemplate) {
            //                const href = this.fillUrl(col.linkTemplate, row);
            //                return `<a href="${this.escapeHtml(href)}" class="text-blue-600 hover:text-blue-800 hover:underline">${this.escapeHtml(value)}</a>`;
            //            }
            //            return this.escapeHtml(value);
            //        case "image":
            //            if (col.imageTemplate) {
            //                const src = this.fillUrl(col.imageTemplate, row);
            //                return `<img src="${this.escapeHtml(src)}" alt="${this.escapeHtml(value)}" class="h-8 w-8 rounded object-cover">`;
            //            }
            //            return this.escapeHtml(value);
            //        default:
            //            return this.escapeHtml(String(value));
            //    }
            //},


            formatCell(row, col) {
                let value = row[col.field];
                if (value == null) return "";

                // هل العمود مطلوب له truncate؟
                const shouldTruncate = !!(col.truncate ?? col.Truncate);

                // مساعد: يلف الناتج داخل span مع title (بعد تنظيف المسافات) لعرض النص الكامل
                const wrapTruncate = (htmlOrText, titleText) => {
                    if (!shouldTruncate) return htmlOrText;

                    const raw = (titleText ?? "");
                    const clean = String(raw).replace(/\s+/g, " ").trim(); // ✅ يشيل المسافات الزائدة ويطبعها
                    const t = this.escapeHtml(clean);

                    return `<span class="sf-truncate" title="${t}">${htmlOrText}</span>`;
                };

                switch (col.type) {
                    case "date":
                        try {
                            const txt = new Date(value).toLocaleDateString('ar-SA');
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        } catch {
                            const txt = String(value);
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        }

                    case "datetime":
                        try {
                            const txt = new Date(value).toLocaleString('ar-SA');
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        } catch {
                            const txt = String(value);
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        }

                    case "bool":
                        // tooltip للـ bool غير مهم عادة
                        return value
                            ? '<span class="text-green-600">✓</span>'
                            : '<span class="text-red-600">✗</span>';

                    case "money":
                        try {
                            const txt = new Intl.NumberFormat('ar-SA', {
                                style: 'currency',
                                currency: 'SAR'
                            }).format(value);
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        } catch {
                            const txt = String(value);
                            return wrapTruncate(this.escapeHtml(txt), txt);
                        }

                    case "badge": {
                        const badgeClass =
                            col.badge?.map?.[value] ||
                            col.badge?.defaultClass ||
                            "bg-gray-100 text-gray-800";

                        const txt = String(value);
                        const html =
                            `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badgeClass}">${this.escapeHtml(txt)}</span>`;

                        return wrapTruncate(html, txt);
                    }

                    case "link": {
                        const txt = String(value);
                        if (col.linkTemplate) {
                            const href = this.fillUrl(col.linkTemplate, row);
                            const html =
                                `<a href="${this.escapeHtml(href)}" class="text-blue-600 hover:text-blue-800 hover:underline">${this.escapeHtml(txt)}</a>`;
                            return wrapTruncate(html, txt);
                        }
                        return wrapTruncate(this.escapeHtml(txt), txt);
                    }

                    case "image":
                        if (col.imageTemplate) {
                            const src = this.fillUrl(col.imageTemplate, row);
                            return `<img src="${this.escapeHtml(src)}" alt="${this.escapeHtml(String(value))}" class="h-8 w-8 rounded object-cover">`;
                        }
                        return "";

                    default: {
                        const txt = String(value);
                        return wrapTruncate(this.escapeHtml(txt), txt);
                    }
                }
            },





            // ===== Grouping =====
            groupedRows() {
                if (!this.groupBy) {
                    return [{ key: null, label: null, items: this.rows }];
                }
                
                const groups = {};
                this.rows.forEach(row => {
                    const key = row[this.groupBy] ?? "غير محدد";
                    if (!groups[key]) {
                        groups[key] = [];
                    }
                    groups[key].push(row);
                });
                
                return Object.entries(groups).map(([key, items]) => ({
                    key,
                    label: `${this.groupBy}: ${key}`,
                    count: items.length,
                    items
                }));
            },

            // ===== Pagination =====
            //goToPage(page) {
            //    const newPage = Math.max(1, Math.min(page, this.pages));
            //    if (newPage !== this.page) {
            //        this.page = newPage;
            //        this.applyFiltersAndSort();
            //    }
            //},

            goToPage(page) {
                const newPage = Math.max(1, Math.min(page, this.pages || 1));
                if (newPage !== this.page) {
                    this.page = newPage;
                    if (this.serverPaging) this.load();
                    else this.applyFiltersAndSort();
                }
            },


            //nextPage() {
            //    if (this.page < this.pages) {
            //        this.page++;
            //        this.applyFiltersAndSort();
            //    }
            //},

            nextPage() {
                if (this.page < (this.pages || 1)) {
                    this.page++;
                    if (this.serverPaging) this.load();
                    else this.applyFiltersAndSort();
                }
            },


            //prevPage() {
            //    if (this.page > 1) {
            //        this.page--;
            //        this.applyFiltersAndSort();
            //    }
            //},

            prevPage() {
                if (this.page > 1) {
                    this.page--;
                    if (this.serverPaging) this.load();
                    else this.applyFiltersAndSort();
                }
            },


            //firstPage() {
            //    this.goToPage(1);
            //},

            //lastPage() {
            //    this.goToPage(this.pages);
            //},

            firstPage() {
                this.goToPage(1);
            },
            lastPage() {
                this.goToPage(this.pages || 1);
            },


            rangeText() {
                if (this.total === 0) return "0 من 0";
                const start = (this.page - 1) * this.pageSize + 1;
                const end = Math.min(this.page * this.pageSize, this.total);
                return `${start} - ${end} من ${this.total}`;
            },

            // ===== Utility Functions =====
            fillUrl(template, data) {
                if (!template || !data) return template || "";
                return template.replace(/\{(\w+)\}/g, (match, key) => data[key] || "");
            },

            escapeHtml(unsafe) {
                return String(unsafe || "")
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;");
            },

            showToast(message, type = 'info') {
                const toast = document.createElement('div');
                toast.className = `fixed top-4 right-4 px-4 py-2 rounded-md text-white z-50 ${
                    type === 'error' ? 'bg-red-600' : 
                    type === 'success' ? 'bg-green-600' : 'bg-blue-600'
                }`;
                toast.textContent = message;
                toast.style.zIndex = '10000';
                
                document.body.appendChild(toast);
                
                setTimeout(() => {
                    if (toast.parentElement) {
                        toast.parentElement.removeChild(toast);
                    }
                }, 3000);
            },

            // ===== Advanced Features =====
            toggleFullscreen() {
                const element = this.$el;
                if (!document.fullscreenElement) {
                    element.requestFullscreen?.().catch(err => 
                        console.error('Fullscreen error:', err)
                    );
                } else {
                    document.exitFullscreen?.();
                }
            },

            changeDensity(density) {
                this.$el.setAttribute('data-density', density);
                this.savePreferences();
            }



        }));
    };

    if (window.Alpine) {
        register();
    } else {
        document.addEventListener("alpine:init", register);
    }
})();


document.addEventListener("DOMContentLoaded", () => {

    document.body.addEventListener("invalid", function (e) {
        e.target.setCustomValidity("يرجى ملء هذا الحقل");
    }, true);

    document.body.addEventListener("input", function (e) {
        e.target.setCustomValidity("");
    }, true);

});
