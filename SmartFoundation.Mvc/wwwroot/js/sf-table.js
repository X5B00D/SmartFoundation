// wwwroot/js/sf-table.js
(function () {
    const register = () => {
        Alpine.data("sfTable", (cfg) => ({
            
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
            allRows: [],
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

            
            loadStoredPreferences() {
                if (!this.storageKey) return;
                try {
                    const stored = localStorage.getItem(this.storageKey);
                    if (stored) {
                        const prefs = JSON.parse(stored);
                        this.pageSize = prefs.pageSize || this.pageSize;
                        this.sort = prefs.sort || this.sort;
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

            
            setupEventListeners() {
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.modal.open) {
                        this.closeModal();
                    }
                });
            },


            // ===== تحميل البيانات (مرة واحدة + فلترة ) =====
            async load() {
                this.loading = true;
                this.error = null;

                try {
                    // أول مرة فقط حمّل كل البيانات من السيرفر
                    if (this.allRows.length === 0) {
                        const body = {
                            Component: "Table",
                            SpName: this.spName,
                            Operation: this.operation,
                            Paging: { Page: 1, Size: 1000000 } 
                        };

                        const json = await this.postJson(this.endpoint, body);
                        this.allRows = json?.data || [];
                    }

                    
                    let filtered = [...this.allRows];
                    if (this.q) {
                        const qLower = this.q.toLowerCase();
                        filtered = filtered.filter(r =>
                            this.quickSearchFields.some(f =>
                                String(r[f] || "").toLowerCase().includes(qLower)
                            )
                        );
                    }

                    // ترقيم محلي
                    this.total = filtered.length;
                    this.pages = Math.max(1, Math.ceil(this.total / this.pageSize));
                    this.rows = filtered.slice((this.page - 1) * this.pageSize, this.page * this.pageSize);

                    this.savePreferences();
                } catch (e) {
                    console.error("sfTable.load error", e);
                    this.error = e.message || "⚠️ خطأ غير معروف في تحميل البيانات";
                } finally {
                    this.loading = false;
                }
            },
        


            // ===== البحث المؤجل (Debounced Search) =====
debouncedSearch() {
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => {
        this.page = 1;
        this.load();
    }, this.searchDelay);
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
                        Params: { ids: Array.from(this.selectedKeys) }
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

            async executeSp(sp, op, params) {
                try {
                    const body = {
                        Component: "Table",
                        SpName: sp,
                        Operation: op,
                        Params: params || {}
                    };

                    const json = await this.postJson(this.endpoint, body);

                    if (json?.message) this.showToast(json.message, 'success');
                    return true;
                } catch (e) {
                    console.error("Execute SP error", e);
                    this.showToast("⚠️ " + (e.message || "فشل العملية"), 'error');

                    
                    if (e?.server?.errors) this.applyServerErrors(e.server.errors);
                    return false;
                }
            },


            // ===== المودال =====
    //        async openModal(action, row) {
    //            this.modal.open = true;
    //            this.modal.title = action.modalTitle || action.label || "";
    //            this.modal.action = action;
    //            this.modal.loading = true;
    //            this.modal.error = null;
    //            this.modal.html = "";

    //            try {
    //                if (action.formUrl) {
    //                    const url = this.fillUrl(action.formUrl, row);
    //                    const resp = await fetch(url);
    //                    if (!resp.ok) throw new Error(`Failed to load form: ${resp.status}`);
    //                    this.modal.html = await resp.text();
    //                    this.$nextTick(() => {
    //                        this.initModalScripts();
    //                    });
    //                } else if (action.openForm) {
    //                    this.modal.html = this.generateFormHtml(action.openForm, row);
    //                    this.$nextTick(() => {
    //                        const formEl = this.$el.querySelector('.sf-modal form');
    //                        if (formEl) {
    //                            formEl.addEventListener('submit', (e) => {
    //                                e.preventDefault();
    //                                this.saveModalChanges();
    //                            });
    //                        }
    //                        this.initModalScripts();
    //                    });
    //                } else if (action.modalSp) {
    //                    const body = {
    //                        Component: "Table",
    //                        SpName: action.modalSp,
    //                        Operation: action.modalOp || "detail",
    //                        Params: row || {}
    //                    };
    //                    const resp = await fetch(this.endpoint, {
    //                        method: "POST",
    //                        headers: { "Content-Type": "application/json" },
    //                        body: JSON.stringify(body)
    //                    });
    //                    const json = await resp.json();
    //                    if (!json.success) throw new Error(json.error || "خطأ");
    //                    this.modal.html = this.formatDetailView(json.data, action.modalColumns);
    //                }
    //            } catch (e) {
    //                console.error("Modal open error", e);
    //                this.modal.error = e.message;
    //            } finally {
    //                this.modal.loading = false;
    //            }
    //        },

    //        initModalScripts() {
    //            const scripts = this.$el.querySelectorAll('.sf-modal script');
    //            scripts.forEach(script => {
    //                const newScript = document.createElement('script');
    //                newScript.textContent = script.textContent;
    //                document.body.appendChild(newScript).remove();
    //            });
    //        },

    //        // ===== توليد الفورم =====
    //        generateFormHtml(formConfig, rowData) {
    //            const formId = formConfig?.formId || "smartModalForm";
    //            const method = (formConfig?.method || "POST").toUpperCase();
    //            const action = formConfig?.actionUrl || "#";

    //            let html = `<form id="${formId}" method="${method}" action="${action}">
    //                <div class="grid grid-cols-12 gap-4">`;

    //            (formConfig?.fields || []).forEach(field => {
    //                if (field?.isHidden || field?.type === "hidden") {
    //                    const v = rowData ? (rowData[field?.name] ?? field?.value ?? "") : (field?.value ?? "");
    //                    html += `<input type="hidden" name="${field?.name}" value="${v}">`;
    //                } else {
    //                    html += this.generateFieldHtml(field, rowData);
    //                }
    //            });

    //            html += `</div></form>`;
    //            return html;
    //        },

    //        // ===== توليد الحقول =====
    //        generateFieldHtml(field, rowData) {
    //            const type = (field?.type || "text").toLowerCase();
    //            const name = field?.name || "";
    //            const label = field?.label || "";
    //            const required = !!field?.required;
    //            const placeholder = field?.placeholder || "";
    //            const helpText = field?.helpText || "";
    //            const options = Array.isArray(field?.options) ? field.options : [];
    //            const value = rowData ? (rowData[name] ?? field?.value ?? "") : (field?.value ?? "");

    //            let colCss = field?.colCss || field?.ColCss || "col-span-12 md:col-span-6";
    //            if (/^\d{1,2}$/.test(colCss)) {
    //                const n = Math.max(1, Math.min(12, parseInt(colCss, 10)));
    //                colCss = `col-span-12 md:col-span-${n}`;
    //            }


    //            const wrap = (inner) => `
    //<div class="form-group ${colCss}">
    //    <label class="sf-label">${label}${required ? " *" : ""}</label>
    //    ${inner}
    //    ${helpText ? `<div class="form-help">${helpText}</div>` : ""}
    //</div>`;


    //            if (type === "checkbox") {
    //                return `
    //                <div class="${colCss} flex items-center gap-2">
    //                    <input type="checkbox" class="sf-checkbox" id="${name}" name="${name}" ${value ? "checked" : ""}>
    //                    <label for="${name}">${label}${required ? " *" : ""}</label>
    //                </div>`;
    //            }

    //            if (type === "textarea") {
    //                return wrap(`<textarea class="sf-textarea" name="${name}" placeholder="${placeholder}" ${required ? "required" : ""}>${value ?? ""}</textarea>`);
    //            }

    //            if (type === "select") {
    //                const opts = options.map(o => {
    //                    const sel = o?.selected || (value != null && String(value) === String(o?.value));
    //                    return `<option value="${o?.value ?? ""}" ${sel ? "selected" : ""} ${o?.disabled ? "disabled" : ""}>${o?.text ?? ""}</option>`;
    //                }).join("");
    //                return wrap(`<select class="sf-select" name="${name}" ${required ? "required" : ""}>${opts}</select>`);
    //            }



    //            const mapType = (t) => {
    //                if (["text", "number", "password", "email", "datetime-local", "url", "tel"].includes(t)) return t;
    //                if (t === "phone") return "tel";
    //                return "text";
    //            };

    //            //  حقل التاريخ
    //            if (type === "date") {
    //                return wrap(`
    //    <input type="text"
    //           name="${name}"
    //           value="${value ?? ""}"
    //           placeholder="YYYY-MM-DD"
    //           class="sf-date"
    //           autocomplete="off"
    //           data-role="sf-date"
    //           data-date-format="yyyy-mm-dd"
    //           data-calendar="gregory"
    //           data-display-lang="ar"
    //           ${required ? "required" : ""} />
    //`);
    //            }

    //            // باقي الحقول العادية
    //            return wrap(`<input class="input" type="${mapType(type)}" name="${name}" value="${(value ?? "").toString().replace(/"/g, '&quot;')}" placeholder="${placeholder}" ${required ? "required" : ""} />`);
    //        },

    //        formatDetailView(data, columns) {
    //            if (!data) return "<p>لا توجد بيانات</p>";
    //            let html = '<div class="detail-view">';
    //            const fields = columns || Object.keys(data);
    //            fields.forEach(field => {
    //                if (data[field] != null) {
    //                    html += `<div class="detail-row"><strong>${field}:</strong> <span>${data[field]}</span></div>`;
    //                }
    //            });
    //            html += '</div>';
    //            return html;
    //        },

    //        closeModal() {
    //            this.modal.open = false;
    //            this.modal.html = "";
    //            this.modal.action = null;
    //            this.modal.error = null;
    //                },





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
                        this.$nextTick(() => {
                            const formEl = this.$el.querySelector('.sf-modal form');
                            if (formEl) {
                                formEl.addEventListener('submit', (e) => {
                                    e.preventDefault();
                                    this.saveModalChanges();
                                });
                            }
                            this.initModalScripts();
                        });
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
                // تنفيذ <script> داخل محتوى المودال
                const scripts = this.$el.querySelectorAll('.sf-modal script');
                scripts.forEach(script => {
                    const newScript = document.createElement('script');
                    if (script.src) newScript.src = script.src;
                    else newScript.textContent = script.textContent;
                    document.body.appendChild(newScript).remove();
                });

                // تهيئة عناصر خاصّة عند الحاجة
                // autosize textarea
                this.$el.querySelectorAll('.sf-textarea[data-auto-resize="1"]').forEach(t => {
                    t.style.height = "auto";
                    t.style.height = t.scrollHeight + "px";
                    t.addEventListener('input', () => {
                        t.style.height = "auto";
                        t.style.height = t.scrollHeight + "px";
                    });
                });

                // معاينة الصور لحقول الملف
                this.$el.querySelectorAll('input[type="file"][data-preview="1"]').forEach(inp => {
                    inp.addEventListener('change', () => {
                        const preview = inp.closest('.form-group')?.querySelector('[data-image-preview]');
                        if (!preview) return;
                        preview.innerHTML = '';
                        const file = inp.files?.[0];
                        if (file && file.type.startsWith('image/')) {
                            const url = URL.createObjectURL(file);
                            const img = document.createElement('img');
                            img.src = url;
                            img.className = 'max-h-40 rounded-md';
                            preview.appendChild(img);
                        }
                    });
                });

                // نجوم التقييم
                this.$el.querySelectorAll('[data-role="sf-rating"]').forEach(el => {
                    const input = el.querySelector('input[type="hidden"]');
                    const stars = el.querySelectorAll('button[data-star]');
                    const setVal = (v) => {
                        input.value = v;
                        stars.forEach(s => {
                            s.setAttribute('aria-pressed', Number(s.dataset.star) <= v ? 'true' : 'false');
                        });
                    };
                    stars.forEach(s => {
                        s.addEventListener('click', () => setVal(Number(s.dataset.star)));
                        s.addEventListener('mouseenter', () => {
                            const v = Number(s.dataset.star);
                            stars.forEach(ss => ss.classList.toggle('opacity-30', Number(ss.dataset.star) > v));
                        });
                        el.addEventListener('mouseleave', () => stars.forEach(ss => ss.classList.remove('opacity-30')));
                    });
                });

                // أقنعة مبسطة للعملات والنسب
                this.$el.querySelectorAll('input[data-mask="currency"]').forEach(inp => {
                    const sym = inp.dataset.symbol || '﷼';
                    inp.addEventListener('input', () => {
                        let v = inp.value.replace(/[^\d.]/g, '');
                        if (v) v = parseFloat(v).toFixed(2);
                        inp.value = v ? `${sym} ${v}` : '';
                    });
                });
                this.$el.querySelectorAll('input[data-mask="percent"]').forEach(inp => {
                    inp.addEventListener('input', () => {
                        let v = inp.value.replace(/[^\d.]/g, '');
                        if (v) v = Math.min(100, parseFloat(v));
                        inp.value = v === '' ? '' : `${v}%`;
                    });
                });

                // وسوم tags بسيطة
                this.$el.querySelectorAll('[data-role="sf-tags"]').forEach(wrap => {
                    const input = wrap.querySelector('input[type="hidden"]');
                    const ed = wrap.querySelector('input[type="text"]');
                    const list = wrap.querySelector('[data-tags-list]');
                    const sep = wrap.dataset.separator || ',';
                    const render = () => {
                        list.innerHTML = '';
                        (input.value ? input.value.split(sep).filter(x => x) : []).forEach(tag => {
                            const chip = document.createElement('button');
                            chip.type = 'button';
                            chip.className = 'px-2 py-1 rounded-full border text-sm hover:bg-gray-50';
                            chip.innerHTML = `${tag} <span class="ml-1">×</span>`;
                            chip.addEventListener('click', () => {
                                const arr = input.value.split(sep).filter(x => x && x !== tag);
                                input.value = arr.join(sep);
                                render();
                            });
                            list.appendChild(chip);
                        });
                    };
                    ed.addEventListener('keydown', (e) => {
                        if (e.key === 'Enter' || e.key === sep) {
                            e.preventDefault();
                            const t = ed.value.trim();
                            if (!t) return;
                            const arr = input.value ? input.value.split(sep).filter(x => x) : [];
                            if (!arr.includes(t)) {
                                arr.push(t);
                                input.value = arr.join(sep);
                                render();
                            }
                            ed.value = '';
                        }
                    });
                    render();
                });

                // autocomplete بسيط باستخدام datalist او fetch
                this.$el.querySelectorAll('input[data-role="sf-autocomplete"][data-source]').forEach(inp => {
                    const src = inp.dataset.source;
                    const listId = inp.getAttribute('list');
                    const dl = listId ? this.$el.querySelector(`#${listId}`) : null;
                    let controller;
                    const load = async (q) => {
                        try {
                            controller?.abort?.();
                            controller = new AbortController();
                            const resp = await fetch(this.fillUrl(src, { q }), { signal: controller.signal });
                            const json = await resp.json();
                            if (dl) {
                                dl.innerHTML = '';
                                (json?.items || []).forEach(x => {
                                    const opt = document.createElement('option');
                                    opt.value = x?.value ?? x;
                                    opt.label = x?.text ?? x?.label ?? x?.value ?? x;
                                    dl.appendChild(opt);
                                });
                            }
                        } catch { }
                    };
                    inp.addEventListener('input', e => {
                        const q = e.target.value;
                        if (q && q.length >= Number(inp.dataset.minlen || 2)) load(q);
                    });
                });
            },

            // ===== توليد الفورم =====
            generateFormHtml(formConfig, rowData) {
                const formId = formConfig?.formId || "smartModalForm";
                const method = (formConfig?.method || "POST").toUpperCase();
                const action = formConfig?.actionUrl || "#";

                let html = `<form id="${formId}" method="${method}" action="${action}">
        <div class="grid grid-cols-12 gap-4">`;

                (formConfig?.fields || []).forEach(field => {
                    if (field?.isHidden || field?.type === "hidden") {
                        const v = rowData ? (rowData[field?.name] ?? field?.value ?? "") : (field?.value ?? "");
                        html += `<input type="hidden" name="${field?.name}" value="${v}">`;
                    } else {
                        html += this.generateFieldHtml(field, rowData);
                    }
                });

                // احذف الافتراضي لو عندك Buttons من السيرفر
                if (!formConfig?.buttons?.length && formConfig?.showButtons !== false) {
                    html += `
        <div class="col-span-12 flex justify-end gap-2 mt-2">
            <button type="button" class="btn btn-secondary" @click="closeModal()">إلغاء</button>
            <button type="submit" class="btn btn-primary">حفظ</button>
        </div>`;
                }

                html += `</div></form>`;
                return html;
            },

            // ===== توليد الحقول =====
            generateFieldHtml(field, rowData) {
                // ---- مساعدات عامة ----
                const get = (k, alt) => field?.[k] ?? field?.[k?.charAt(0).toUpperCase() + k.slice(1)] ?? alt;
                const esc = (s) => String(s ?? "").replace(/"/g, '&quot;');
                const yes = (b, k) => b ? k : "";
                const num = (v, d = null) => (v === 0 || v) ? v : d;

                // colCss: يقبل رقم أو سلاسل جاهزة. يدعم صيغ بسيطة مثل "3" أو "col-span-6 md:col-span-3"
                const resolveColCss = (raw) => {
                    let colCss = (raw || "col-span-12 md:col-span-6").trim();
                    if (/^\d{1,2}$/.test(colCss)) {
                        const n = Math.max(1, Math.min(12, parseInt(colCss, 10)));
                        return `col-span-12 md:col-span-${n}`;
                    }
                    // لو لم يحتوي أساس للموبايل، أضف col-span-12
                    if (!/\bcol-span-\d{1,2}\b/.test(colCss)) colCss = `col-span-12 ${colCss}`.trim();
                    return colCss;
                };

                const type = String(get("type", "text")).toLowerCase();
                const name = String(get("name", ""));
                const label = String(get("label", ""));
                const required = !!get("required", false);
                const placeholder = get("placeholder", "") || "";
                const helpText = get("helpText", "") || "";
                const options = Array.isArray(get("options", [])) ? get("options", []) : [];
                const extraCss = get("extraCss", "") || "";
                const iconCls = get("icon", "") || "";
                const onChangeJs = get("onChangeJs", "") || "";
                const dependsOn = get("dependsOn", "") || "";
                const dependsUrl = get("dependsUrl", "") || "";
                const multiple = !!get("multiple", false);
                const readonly = !!get("readonly", false);
                const disabled = !!get("disabled", false);
                const isHidden = !!get("isHidden", false);

                // قيود عامة
                const min = get("min", null);
                const max = get("max", null);
                const maxLength = get("maxLength", null);
                const pattern = get("pattern", null);
                const inputPattern = get("inputPattern", null);
                const inputLang = get("inputLang", null);
                const isNumericOnly = !!get("isNumericOnly", false);
                const isIban = !!get("isIban", false);

                // خصائص المتصفح
                const autocomplete = get("autocomplete", "off");
                const spellcheck = get("spellcheck", null);
                const autocapitalize = get("autocapitalize", null);
                const autocorrect = get("autocorrect", null);

                // التاريخ المتقدم
                const calendar = get("calendar", "gregorian");          // gregorian | hijri | both
                const dateInputCalendar = get("dateInputCalendar", "gregorian");
                const mirrorName = get("mirrorName", null);
                const mirrorCalendar = get("mirrorCalendar", "hijri");
                const dateDisplayLang = get("dateDisplayLang", "ar");
                const dateNumerals = get("dateNumerals", "latn");
                const showDayName = !!get("showDayName", true);
                const defaultToday = !!get("defaultToday", false);
                const minDateStr = get("minDateStr", null);
                const maxDateStr = get("maxDateStr", null);
                const displayFormat = get("displayFormat", null);
                const colCssFrom = get("colCssFrom", null);
                const colCssTo = get("colCssTo", null);

                // القيمة
                const rawValue = rowData ? (rowData[name] ?? get("value", "")) : get("value", "");
                const value = rawValue ?? "";

                // colCss النهائي
                const colCss = resolveColCss(get("colCss", get("ColCss", "")));

                // بناء سلاسل صفات شائعة
                const baseReq = yes(required, "required");
                const basePh = placeholder ? `placeholder="${esc(placeholder)}"` : "";
                const baseMaxLen = maxLength ? `maxlength="${maxLength}"` : "";
                const baseMin = (min ?? null) !== null ? `min="${min}"` : "";
                const baseMax = (max ?? null) !== null ? `max="${max}"` : "";
                const basePat = pattern ? `pattern="${esc(pattern)}"` : "";
                const baseReadOnly = yes(readonly, "readonly");
                const baseDisabled = yes(disabled, "disabled");
                const baseMulti = yes(multiple, "multiple");
                const baseAuto = autocomplete ? `autocomplete="${esc(autocomplete)}"` : "";
                const baseSpell = (spellcheck !== null) ? `spellcheck="${spellcheck ? "true" : "false"}"` : "";
                const baseCap = autocapitalize ? `autocapitalize="${esc(autocapitalize)}"` : "";
                const baseCorr = autocorrect ? `autocorrect="${esc(autocorrect)}"` : "";
                const baseDir = inputLang === "number" ? `inputmode="numeric"` : "";
                const baseOnChange = onChangeJs ? `onchange="${esc(onChangeJs)}"` : "";
                const baseDependsOn = dependsOn ? `data-depends-on="${esc(dependsOn)}"` : "";
                const baseDependsUrl = dependsUrl ? `data-depends-url="${esc(dependsUrl)}"` : "";
                const baseIban = isIban ? `data-iban="1"` : "";
                const baseNumOnly = isNumericOnly ? `data-numeric-only="1"` : "";
                const baseInPat = inputPattern ? `pattern="${esc(inputPattern)}"` : "";

                // إضافة أيقونة داخل الحقل عند الطلب
                const iconHtml = iconCls ? `<i class="${esc(iconCls)} mr-1"></i>` : "";

                // تغليف مع التسمية والمساعدة + دعم SectionTitle
                const wrap = (inner, overrideLabel = true) => `
${get("sectionTitle", null) ? `
<div class="section-box col-span-12">
  <span class="section-legend">${esc(get("sectionTitle", ""))}</span>
  <div class="form-row">
` : ""}

<div class="form-group ${colCss}">
  ${overrideLabel !== false ? `<label class="sf-label">${esc(label)}${required ? " <span class='req'>*</span>" : ""}</label>` : ""}
  ${iconCls ? `<div class="flex items-center gap-2">${iconHtml}<div class="flex-1">${inner}</div></div>` : inner}
  ${helpText ? `<div class="form-help">${esc(helpText)}</div>` : ""}
</div>

${get("sectionTitle", null) ? `
  </div>
</div>` : ""}`;

                // توليد <option> و <optgroup>
                const buildOptions = (opts, val) => {
                    return opts.map(o => {
                        const hasChildren = Array.isArray(o?.options) && o.options.length;
                        if (hasChildren) {
                            const children = buildOptions(o.options, val);
                            return `<optgroup label="${esc(o?.label ?? o?.Text ?? "")}">${children}</optgroup>`;
                        }
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? "";
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const sel = !!(o?.selected ?? o?.Selected) || (val != null && String(val) === String(v));
                        return `<option value="${esc(v)}" ${sel ? "selected" : ""} ${dis ? "disabled" : ""}>${esc(t)}</option>`;
                    }).join("");
                };

                // عناصر input النوعية
                const mapType = (t) => {
                    if (["text", "number", "password", "email", "datetime-local", "url", "tel", "search"].includes(t)) return t;
                    if (t === "phone") return "tel";
                    if (t === "iban") return "text";
                    return "text";
                };

                // مخفي
                if (isHidden || type === "hidden") {
                    return `<input type="hidden" name="${esc(name)}" value="${esc(value)}">`;
                }

                // ===== أنواع خاصة =====

                // Checkbox مفرد
                if (type === "checkbox") {
                    const checked = !!value;
                    return `
<div class="${colCss} flex items-center gap-2">
  <input type="checkbox" class="sf-checkbox ${extraCss}" id="${esc(name)}" name="${esc(name)}"
         ${checked ? "checked" : ""} ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} ${baseIban} ${baseNumOnly}>
  <label for="${esc(name)}">${esc(label)}${required ? " <span class='req'>*</span>" : ""}</label>
  ${helpText ? `<div class="form-help">${esc(helpText)}</div>` : ""}
</div>`;
                }

                // مجموعة checkboxes
                if (type === "checkbox-group") {
                    const sel = new Set(
                        Array.isArray(value) ? value.map(String)
                            : typeof value === 'string' ? value.split(',').map(s => s.trim()).filter(Boolean)
                                : []
                    );
                    const items = options.map((o, i) => {
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? v;
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const ckd = sel.has(String(v));
                        return `
<label class="inline-flex items-center gap-2 mr-4">
  <input type="checkbox" name="${esc(name)}" value="${esc(v)}" ${ckd ? "checked" : ""} ${dis ? "disabled" : ""}
         ${baseReadOnly} ${baseReq} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} class="${extraCss}">
  <span>${esc(t)}</span>
</label>`;
                    }).join("");
                    return wrap(`<div class="flex flex-wrap items-center">${items}</div>`);
                }

                // مجموعة radio
                if (type === "radio") {
                    const items = options.map((o, i) => {
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? v;
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const ckd = String(value) === String(v);
                        return `
<label class="inline-flex items-center gap-2 mr-4">
  <input type="radio" name="${esc(name)}" value="${esc(v)}" ${ckd ? "checked" : ""} ${dis ? "disabled" : ""}
         ${baseReadOnly} ${baseReq} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} class="${extraCss}">
  <span>${esc(t)}</span>
</label>`;
                    }).join("");
                    return wrap(`<div class="flex flex-wrap items-center">${items}</div>`);
                }

                // textarea
                if (type === "textarea") {
                    const rows = num(get("rows", null), 3);
                    return wrap(
                        `<textarea class="sf-textarea ${extraCss}" name="${esc(name)}" rows="${rows}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange}>${esc(value)}</textarea>`
                    );
                }

                // select
                if (type === "select") {
                    const asyncSrc = dependsUrl ? `data-source="${esc(dependsUrl)}"` : "";
                    // multiple
                    let selectedSet = new Set();
                    if (multiple) {
                        selectedSet = new Set(
                            Array.isArray(value) ? value.map(String) :
                                typeof value === "string" ? value.split(",").map(s => s.trim()).filter(Boolean) : []
                        );
                    }
                    const optsHtml = multiple
                        ? options.map(o => {
                            const v = o?.value ?? o?.Value ?? "";
                            const t = o?.text ?? o?.Text ?? o?.label ?? v;
                            const dis = !!(o?.disabled ?? o?.Disabled);
                            const sel = selectedSet.has(String(v)) || !!(o?.selected ?? o?.Selected);
                            return `<option value="${esc(v)}" ${sel ? "selected" : ""} ${dis ? "disabled" : ""}>${esc(t)}</option>`;
                        }).join("")
                        : buildOptions(options, value);

                    return wrap(
                        `<select class="sf-select ${extraCss}" name="${esc(name)}" ${baseMulti}
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${asyncSrc}
    ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange}>
  ${optsHtml}
</select>`
                    );
                }

                // autocomplete (datalist + مصدر اختياري)
                if (type === "autocomplete") {
                    const listId = `${name}_list`;
                    const src = dependsUrl ? `data-source="${esc(dependsUrl)}"` : "";
                    const minlen = num(get("minLength", null), 2);
                    return wrap(
                        `<input class="input ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
    ${basePh} ${baseReq} list="${esc(listId)}" data-role="sf-autocomplete" ${src}
    data-minlen="${minlen}" ${baseReadOnly} ${baseDisabled}
    ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
<datalist id="${esc(listId)}"></datalist>`
                    );
                }

                // date / time / datetime
                if (type === "date") {
                    // ملاحظات: data-... تشمل كل مفاتيح التقويم المتقدمة
                    const theVal = value || (defaultToday ? new Date().toISOString().slice(0, 10) : "");
                    return wrap(
                        `<input type="text" name="${esc(name)}" value="${esc(theVal)}" ${basePh || `placeholder="${esc(displayFormat || 'YYYY-MM-DD')}"`}
    class="sf-date ${extraCss}" autocomplete="off" data-role="sf-date"
    data-date-format="${esc(displayFormat || 'yyyy-mm-dd')}"
    data-calendar="${esc(calendar)}" data-input-calendar="${esc(dateInputCalendar)}"
    data-display-lang="${esc(dateDisplayLang)}" data-numerals="${esc(dateNumerals)}"
    data-show-dayname="${showDayName ? "1" : "0"}"
    ${minDateStr ? `data-min="${esc(minDateStr)}"` : ""} ${maxDateStr ? `data-max="${esc(maxDateStr)}"` : ""}
    ${mirrorName ? `data-mirror="${esc(mirrorName)}"` : ""} ${mirrorCalendar ? `data-mirror-cal="${esc(mirrorCalendar)}"` : ""}
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }
                if (type === "time") {
                    return wrap(
                        `<input class="input ${extraCss}" type="time" name="${esc(name)}" value="${esc(value)}"
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }
                if (type === "datetime" || type === "datetime-local") {
                    return wrap(
                        `<input class="input ${extraCss}" type="datetime-local" name="${esc(name)}" value="${esc(value)}"
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }

                // date-range: حقلا "من" و"إلى" مع خصائص التقويم المتقدم
                if (type === "date-range") {
                    const fromName = `${name}_from`;
                    const toName = `${name}_to`;
                    const vv = (typeof value === "string" && value.includes("|")) ? value.split("|") : [];
                    const vFrom = vv[0] || "";
                    const vTo = vv[1] || "";
                    const colFrom = resolveColCss(colCssFrom || "col-span-12 md:col-span-6");
                    const colTo = resolveColCss(colCssTo || "col-span-12 md:col-span-6");

                    const inputTpl = (n, v, place) => `
<div class="form-group ${n === fromName ? colFrom : colTo}">
  <label class="sf-label">${n === fromName ? "من" : "إلى"}${required ? " <span class='req'>*</span>" : ""}</label>
  <input type="text" name="${esc(n)}" value="${esc(v)}" ${place ? `placeholder="${esc(place)}"` : ""}
         class="sf-date ${extraCss}" autocomplete="off" data-role="sf-date-range"
         data-date-format="${esc(displayFormat || 'yyyy-mm-dd')}"
         data-calendar="${esc(calendar)}" data-input-calendar="${esc(dateInputCalendar)}"
         data-display-lang="${esc(dateDisplayLang)}" data-numerals="${esc(dateNumerals)}"
         data-range="${esc(name)}" ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${minDateStr ? `data-min="${esc(minDateStr)}"` : ""} ${maxDateStr ? `data-max="${esc(maxDateStr)}"` : ""}
         ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
</div>`;

                    return `
${get("sectionTitle", null) ? `
<div class="section-box col-span-12">
  <span class="section-legend">${esc(get("sectionTitle", ""))}</span>
  <div class="form-row">
` : ""}

${inputTpl(fromName, vFrom, displayFormat || "YYYY-MM-DD")}
${inputTpl(toName, vTo, displayFormat || "YYYY-MM-DD")}
${helpText ? `<div class="col-span-12"><div class="form-help">${esc(helpText)}</div></div>` : ""}

${get("sectionTitle", null) ? `
  </div>
</div>` : ""}`;
                }

                // range / slider
                if (type === "range" || type === "slider") {
                    const vmin = num(min, 0), vmax = num(max, 100), vstep = num(get("step", null), 1);
                    return wrap(
                        `<input class="sf-range w-full ${extraCss}" type="range" name="${esc(name)}" value="${esc(value ?? vmin)}"
    min="${vmin}" max="${vmax}" step="${vstep}" ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange}>
<div class="text-xs text-gray-500 mt-1"><span>${vmin}</span> - <span>${vmax}</span></div>`
                    );
                }

                // color
                if (type === "color") {
                    return wrap(
                        `<input class="input ${extraCss}" type="color" name="${esc(name)}" value="${esc(value || '#000000')}"
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }

                // file
                if (type === "file") {
                    const accept = get("accept", null);
                    const preview = !!get("preview", false);
                    const previewBox = preview ? `<div class="mt-2" data-image-preview></div>` : "";
                    return wrap(
                        `<input class="sf-file ${extraCss}" type="file" name="${esc(name)}" ${baseMulti}
    ${accept ? `accept="${esc(accept)}"` : ""} ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} ${yes(preview, 'data-preview="1"')} />
${previewBox}`
                    );
                }

                // rating
                if (type === "rating") {
                    const rmax = Number(get("max", 5) || 5);
                    const cur = Number(value || 0);
                    const stars = Array.from({ length: rmax }, (_, i) => i + 1).map(i => `
<button type="button" data-star="${i}" class="text-2xl leading-none ${i <= cur ? '' : 'opacity-30'}" aria-pressed="${i <= cur ? 'true' : 'false'}">★</button>
`).join("");
                    return wrap(
                        `<div class="inline-flex items-center gap-1 select-none" data-role="sf-rating" ${baseDependsOn} ${baseDependsUrl}>
  ${stars}
  <input type="hidden" name="${esc(name)}" value="${cur}">
</div>`
                    );
                }

                // currency
                if (type === "currency") {
                    const symbol = get("symbol", "﷼");
                    return wrap(
                        `<div class="flex items-stretch">
  <span class="inline-flex items-center px-2 border border-r-0 rounded-l-md">${esc(symbol)}</span>
  <input class="input rounded-l-none ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
         data-mask="currency" data-symbol="${esc(symbol)}"
         ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseNumOnly} ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
</div>`
                    );
                }

                // percent
                if (type === "percent") {
                    return wrap(
                        `<div class="flex items-stretch">
  <input class="input rounded-r-none ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
         data-mask="percent" ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseNumOnly} ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
  <span class="inline-flex items-center px-2 border border-l-0 rounded-r-md">%</span>
</div>`
                    );
                }

                // tags
                if (type === "tags") {
                    const sep = get("separator", ",");
                    const display = Array.isArray(value) ? value.join(sep) : (value ?? "");
                    return wrap(
                        `<div data-role="sf-tags" data-separator="${esc(sep)}">
  <div class="flex flex-wrap gap-2 mb-2" data-tags-list></div>
  <input type="hidden" name="${esc(name)}" value="${esc(display)}">
  <input type="text" class="input ${extraCss}" ${basePh} ${baseReadOnly} ${baseDisabled}
         ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
</div>`
                    );
                }

                // switch/toggle
                if (type === "switch" || type === "toggle") {
                    return wrap(
                        `<label class="inline-flex items-center cursor-pointer">
  <input type="checkbox" name="${esc(name)}" ${value ? "checked" : ""} class="sr-only peer"
         ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange}>
  <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:right-[22px] peer-checked:after:right-0.5 after:bg-white after:border after:rounded-full after:h-5 after:w-5 after:transition-all"></div>
  <span class="ms-2 text-sm">${esc(label)}</span>
</label>`, false);
                }

                // code
                if (type === "code") {
                    const lang = get("language", "javascript");
                    const rows = num(get("rows", null), 8);
                    return wrap(
                        `<textarea class="sf-textarea font-mono ${extraCss}" name="${esc(name)}" rows="${rows}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange}>${esc(value)}</textarea>
<div class="text-xs text-gray-500 mt-1">اللغة: ${esc(lang)}</div>`
                    );
                }

                // mask
                if (type === "mask") {
                    // يعتمد على pattern أو inputPattern
                    const pat = pattern || inputPattern;
                    return wrap(
                        `<input class="input ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
    ${pat ? `pattern="${esc(pat)}"` : ""} ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }

                // table (حقل خاص يعرض جدولاً داخليًا لو تم تمرير TableConfig)
                if (type === "table" && field?.table) {
                    // هنا مجرد Placeholder. يفترض أنك تولّد مكوّن الجدول بـ Alpine من config.
                    return wrap(
                        `<div x-data="sfTable(${JSON.stringify(field.table)})" class="${extraCss}">
  <!-- توليد الجدول يتم خارج هذه الدالة حسب sf-table.js -->
  <div class="label-sm text-gray-500">مكوّن جدول مضمّن</div>
</div>`
                    );
                }

                // number
                if (type === "number") {
                    const step = get("step", null);
                    return wrap(
                        `<input class="input ${extraCss}" type="number" name="${esc(name)}" value="${esc(value)}"
    ${baseMin} ${baseMax} ${step != null ? `step="${step}"` : ""} ${basePh} ${baseReq}
    ${baseReadOnly} ${baseDisabled} ${baseMaxLen}
    ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseDir} ${baseInPat}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                    );
                }

                // الافتراضي (text/password/email/…)
                return wrap(
                    `<input class="input ${extraCss}" type="${mapType(type)}" name="${esc(name)}" value="${esc(value)}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled}
    ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseDir} ${baseInPat} ${basePat} ${baseIban} ${baseNumOnly}
    ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />`
                );
            },




            formatDetailView(data, columns) {
                if (!data) return "<p>لا توجد بيانات</p>";
                let html = '<div class="detail-view space-y-2">';
                const fields = columns?.length ? columns.map(c => c.Field || c.field || c) : Object.keys(data);
                fields.forEach(field => {
                    const key = typeof field === 'string' ? field : (field.Field || field.field);
                    const label = typeof field === 'string' ? field : (field.Label || field.label || key);
                    if (data[key] != null) {
                        html += `<div class="detail-row flex gap-2">
                        <strong class="min-w-32">${label}:</strong>
                        <span class="flex-1 break-words">${data[key]}</span>
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
                const form = this.$el.querySelector(".sf-modal form");
                if (!form) return;

                try {
                    this.modal.loading = true;
                    this.modal.error = null;

                    
                    const payload = this.serializeForm(form);

                    const success = await this.executeSp(
                        this.modal.action.saveSp,
                        this.modal.action.saveOp || (this.modal.action.isEdit ? "update" : "insert"),
                        payload
                    );

                    if (success) {
                        this.closeModal();
                        if (this.autoRefresh) {
                            this.clearSelection();
                            this.load();
                        }
                    }
                } catch (e) {
                    console.error("Save modal changes error", e);
                    this.modal.error = e.message || "⚠️ فشل في الحفظ";
                } finally {
                    this.modal.loading = false;
                }
            },


            
            getCsrfToken() {
                
                const meta = document.querySelector('meta[name="request-verification-token"]');
                if (meta?.content) return meta.content;
                const input = document.querySelector('input[name="__RequestVerificationToken"]');
                return input?.value || null;
            },

            async postJson(url, body) {
                const headers = { "Content-Type": "application/json" };
                const csrf = this.getCsrfToken();
                if (csrf) headers["RequestVerificationToken"] = csrf;

                const resp = await fetch(url, {
                    method: "POST",
                    headers,
                    body: JSON.stringify(body)
                });

                let json = null;
                try { json = await resp.json(); } catch {}

                if (!resp.ok) {
                    const msg = json?.error || `HTTP ${resp.status}`;
                    throw new Error(msg);
                }

                
                if (json && json.success === false) {
                    const err = new Error(json.error || "فشل العملية");
                    err.server = json;     
                    throw err;
                }
                return json;
            },

            serializeForm(formEl) {
                
                const fd = new FormData(formEl);
                const obj = {};

                
                for (const [k, v] of fd.entries()) {
                    if (obj[k] !== undefined) {
                        if (Array.isArray(obj[k])) obj[k].push(v);
                        else obj[k] = [obj[k], v];
                    } else {
                        obj[k] = v;
                    }
                }

                
                formEl.querySelectorAll('input[type="checkbox"][name]').forEach(inp => {
                    if (!fd.has(inp.name)) obj[inp.name] = false;
                    else obj[inp.name] = !!inp.checked;
                });

               
                Object.keys(obj).forEach(k => {
                    let val = obj[k];
                    if (typeof val === "string") {
                        let s = val.trim();

                        
                        if (s === "") { obj[k] = null; return; }

                        
                        if (/^-?\d+$/.test(s) && !/^0\d+/.test(s)) { obj[k] = Number(s); return; }

                       
                        if (/^-?\d+\.\d+$/.test(s)) { obj[k] = Number(s); return; }

                        
                        if (/^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2})?)?$/.test(s)) { obj[k] = s; return; }

                        obj[k] = s;
                    }
                });

                return obj;
            },

            applyServerErrors(errors) {
                
                const form = this.$el.querySelector('.sf-modal form');
                if (!form || !errors) return;

                
                form.querySelectorAll('[data-error-msg]').forEach(el => el.remove());
                form.querySelectorAll('.ring-red-500').forEach(el => el.classList.remove('ring-red-500'));

                
                Object.entries(errors).forEach(([name, msg]) => {
                    const field = form.querySelector(`[name="${name}"]`);
                    if (!field) return;
                    field.classList.add('ring-1', 'ring-red-500');

                    const holder = field.closest('div') || field.parentElement || form;
                    const hint = document.createElement('div');
                    hint.dataset.errorMsg = '1';
                    hint.className = 'text-red-600 text-sm mt-1';
                    hint.textContent = Array.isArray(msg) ? msg.join('، ') : String(msg);
                    holder.appendChild(hint);
                });
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
                    case "date": return new Date(val).toLocaleDateString('ar-SA');
                    case "datetime": return new Date(val).toLocaleString('ar-SA');
                    case "bool": return val ? '<span class="text-green-600">✔</span>' : '<span class="text-red-600">✘</span>';
                    case "money": return new Intl.NumberFormat('ar-SA', { style: 'currency', currency: 'SAR' }).format(val);
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





            groupedRows() {
                if (!this.groupBy) {
                    return [{ key: null, label: null, items: this.rows }];
                }

                const groups = {};
                this.rows.forEach(row => {
                    const key = row[this.groupBy] ?? "غير محدد";
                    if (!groups[key]) groups[key] = [];
                    groups[key].push(row);
                });

                return Object.entries(groups).map(([key, items]) => ({
                    key,
                    label: `${this.groupBy}: ${key}`,
                    count: items.length,
                    items
                }));
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
            nextPage() { if (this.page < this.pages) { this.page++; this.load(); } },
            prevPage() { if (this.page > 1) { this.page--; this.load(); } },
            firstPage() { this.goToPage(1); },
            lastPage() { this.goToPage(this.pages); },

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
                    element.requestFullscreen?.().catch(err => console.error('Error attempting fullscreen:', err));
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


