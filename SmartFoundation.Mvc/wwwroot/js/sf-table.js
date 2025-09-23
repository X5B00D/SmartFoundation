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
                // ====== أدوات مساعدة محلية ======
                const get = (k, alt) => {
                    // جرب الحصول على القيمة بالأسماء المختلفة للخاصية
                    return field?.[k] ?? 
                           field?.[k?.charAt(0).toUpperCase() + k.slice(1)] ?? 
                           alt;
                };
                
                const esc = (s) => String(s ?? "").replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                const yes = (b, k) => b ? k : "";
                const num = (v, d = null) => (v === 0 || v) ? v : d;

                // حل CSS للأعمدة بشكل متقدم
                const resolveColCss = (raw) => {
                    if (!raw) return "col-span-12 md:col-span-6";
                    let colCss = raw.trim();
                    
                    // إذا كان رقماً فقط (1-12)
                    if (/^\d{1,2}$/.test(colCss)) {
                        const n = Math.max(1, Math.min(12, parseInt(colCss, 10)));
                        return `col-span-12 md:col-span-${n}`;
                    }
                    
                    // إذا لم يحتوي على col-span أساسي، أضفه
                    if (!/\bcol-span-\d{1,2}\b/.test(colCss)) {
                        colCss = `col-span-12 ${colCss}`.trim();
                    }
                    return colCss;
                };

                // بناء خيارات Select/Radio/Checkbox
                const buildOptions = (opts, val, multiple = false) => {
                    const selectedSet = new Set(
                        multiple
                            ? Array.isArray(val) ? val.map(String)
                                : typeof val === "string" ? val.split(",").map(s => s.trim()).filter(Boolean)
                                    : []
                            : []
                    );

                    const render = (list) => list.map(o => {
                        const hasChildren = Array.isArray(o?.options) && o.options.length;
                        if (hasChildren) {
                            return `<optgroup label="${esc(o?.label ?? o?.Text ?? o?.text ?? "")}">${render(o.options)}</optgroup>`;
                        }
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? o?.Label ?? v;
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const sel = multiple
                            ? selectedSet.has(String(v)) || !!(o?.selected ?? o?.Selected)
                            : !!(o?.selected ?? o?.Selected) || (val != null && String(val) === String(v));
                        const icon = o?.icon ?? o?.Icon ?? "";
                        const iconHtml = icon ? `<i class="${esc(icon)} mr-1"></i>` : "";
                        
                        return `<option value="${esc(v)}" ${sel ? "selected" : ""} ${dis ? "disabled" : ""} data-icon="${esc(icon)}">${iconHtml}${esc(t)}</option>`;
                    }).join("");

                    return render(opts || []);
                };

                // تحديد نوع Input للمتصفح
                const mapType = (t) => {
                    const std = ["text", "number", "password", "email", "datetime-local", "url", "tel", "search", "date", "time", "month", "week"];
                    if (std.includes(t)) return t;
                    if (t === "phone") return "tel";
                    if (t === "iban") return "text";
                    return "text";
                };

                // التعامل مع TextMode
                const getTextModeAttributes = (textMode) => {
                    const patterns = {
                        arabic: '[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF\\s]*',
                        english: '[a-zA-Z\\s]*',
                        numeric: '[0-9]*',
                        alphanumeric: '[a-zA-Z0-9]*',
                        arabicnum: '[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF0-9\\s]*',
                        engsentence: '[a-zA-Z0-9\\s\\.,;:!?\\-]*',
                        arsentence: '[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF0-9\\s\\.,;:!?\\-]*',
                        email: '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}',
                        url: 'https?://[\\w\\-]+(\\.[\\w\\-]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?'
                    };
                    
                    if (!textMode || textMode === 'custom') return '';
                    const pattern = patterns[textMode];
                    return pattern ? `data-text-mode="${esc(textMode)}" pattern="${esc(pattern)}"` : '';
                };

                // أقسام الحقول
                const wrapSectionStart = (title) => title ? `
<div class="section-box col-span-12">
  <span class="section-legend">${esc(title)}</span>
  <div class="form-row grid grid-cols-12 gap-4">` : "";

                const wrapSectionEnd = (title) => title ? `
  </div>
</div>` : "";

                // تغليف الحقل
                const wrapField = ({ inner, label, required, helpText, colCss, withLabel = true, iconCls = "" }) => {
                    const iconHtml = iconCls ? `<i class="${esc(iconCls)} mr-1"></i>` : "";
                    const innerWithIcon = iconCls ? `<div class="flex items-center gap-2">${iconHtml}<div class="flex-1">${inner}</div></div>` : inner;
                    return `
<div class="form-group ${colCss}">
  ${withLabel ? `<label class="sf-label">${esc(label)}${required ? " <span class='req'>*</span>" : ""}</label>` : ""}
  ${innerWithIcon}
  ${helpText ? `<div class="form-help">${esc(helpText)}</div>` : ""}
</div>`;
                };

                // ====== قراءة جميع خصائص FieldConfig ======
                
                // الخصائص الأساسية
                const name = String(get("name", ""));
                const label = String(get("label", ""));
                const type = String(get("type", "text")).toLowerCase();
                const placeholder = get("placeholder", "") || "";
                const helpText = get("helpText", "") || "";
                const required = !!get("required", false);
                const readonly = !!get("readonly", false);
                const disabled = !!get("disabled", false);
                const multiple = !!get("multiple", false);
                const isHidden = !!get("isHidden", false);

                // القيود العامة
                const min = get("min", null);
                const max = get("max", null);
                const maxLength = get("maxLength", null);
                const pattern = get("pattern", null);
                const inputPattern = get("inputPattern", null);
                const inputLang = get("inputLang", null);

                // تنسيق وواجهة
                const colCss = resolveColCss(get("colCss", ""));
                const extraCss = get("extraCss", "") || "";
                const iconCls = get("icon", "") || "";
                const onChangeJs = get("onChangeJs", "") || "";
                const dependsOn = get("dependsOn", "") || "";
                const dependsUrl = get("dependsUrl", "") || "";
                const sectionTitle = get("sectionTitle", null);
                const options = Array.isArray(get("options", [])) ? get("options", []) : [];

                // أنواع خاصة
                const isNumericOnly = !!get("isNumericOnly", false);
                const isIban = !!get("isIban", false);
                const textMode = get("textMode", null);

                // خصائص المتصفح
                const autocomplete = get("autocomplete", "off");
                const spellcheck = get("spellcheck", null);
                const autocapitalize = get("autocapitalize", null);
                const autocorrect = get("autocorrect", null);

                // التاريخ المتقدم
                const calendar = get("calendar", "gregorian");
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

                // جدول مضمن
                const tableConfig = get("table", null);

                // القيمة
                const rawValue = rowData ? (rowData[name] ?? get("value", "")) : get("value", "");
                const value = rawValue ?? "";

                // سمات HTML عامة مشتركة
                const baseReq = yes(required, "required");
                const basePh = placeholder ? `placeholder="${esc(placeholder)}"` : "";
                const baseMaxLen = maxLength ? `maxlength="${maxLength}"` : "";
                const baseMin = (min ?? null) !== null ? `min="${min}"` : "";
                const baseMax = (max ?? null) !== null ? `max="${max}"` : "";
                const basePat = pattern ? `pattern="${esc(pattern)}"` : "";
                const baseInputPat = inputPattern ? `data-input-pattern="${esc(inputPattern)}"` : "";
                const baseReadOnly = yes(readonly, "readonly");
                const baseDisabled = yes(disabled, "disabled");
                const baseMulti = yes(multiple, "multiple");
                const baseAuto = autocomplete ? `autocomplete="${esc(autocomplete)}"` : "";
                const baseSpell = (spellcheck !== null) ? `spellcheck="${spellcheck ? "true" : "false"}"` : "";
                const baseCap = autocapitalize ? `autocapitalize="${esc(autocapitalize)}"` : "";
                const baseCorr = autocorrect ? `autocorrect="${esc(autocorrect)}"` : "";
                const baseDir = inputLang === "number" ? `inputmode="numeric"` : inputLang ? `inputmode="${esc(inputLang)}"` : "";
                const baseOnChange = onChangeJs ? `onchange="${esc(onChangeJs)}"` : "";
                const baseDependsOn = dependsOn ? `data-depends-on="${esc(dependsOn)}"` : "";
                const baseDependsUrl = dependsUrl ? `data-depends-url="${esc(dependsUrl)}"` : "";
                const baseIban = isIban ? `data-iban="1"` : "";
                const baseNumOnly = isNumericOnly ? `data-numeric-only="1"` : "";
                const baseTextMode = getTextModeAttributes(textMode);

                // بداية ونهاية الأقسام
                const sectionStart = wrapSectionStart(sectionTitle);
                const sectionEnd = wrapSectionEnd(sectionTitle);

                // ====== توليد أنواع الحقول المختلفة ======

                // حقل مخفي
                if (isHidden || type === "hidden") {
                    return `${sectionStart}<input type="hidden" name="${esc(name)}" value="${esc(value)}" ${baseDependsOn} ${baseDependsUrl}>${sectionEnd}`;
                }

                // checkbox مفرد
                if (type === "checkbox") {
                    const checked = !!value || value === "true" || value === "1" || value === 1;
                    const inner = `
<label class="inline-flex items-center gap-2 cursor-pointer">
  <input type="checkbox" class="sf-checkbox ${extraCss}" id="${esc(name)}" name="${esc(name)}" value="1"
         ${checked ? "checked" : ""} ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
         ${baseDependsOn} ${baseDependsUrl} ${baseIban} ${baseNumOnly}>
  <span class="checkbox-label">${esc(label)}${required ? " <span class='req'>*</span>" : ""}</span>
</label>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, withLabel: false, iconCls })}${sectionEnd}`;
                }

                // checkbox-group
                if (type === "checkbox-group") {
                    const sel = new Set(
                        Array.isArray(value) ? value.map(String)
                            : typeof value === 'string' ? value.split(',').map(s => s.trim()).filter(Boolean)
                                : []
                    );
                    const items = (options || []).map(o => {
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? o?.Label ?? v;
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const ckd = sel.has(String(v));
                        const icon = o?.icon ?? o?.Icon ?? "";
                        const iconHtml = icon ? `<i class="${esc(icon)} mr-1"></i>` : "";
                        
                        return `
<label class="inline-flex items-center gap-2 mr-4 cursor-pointer">
  <input type="checkbox" name="${esc(name)}" value="${esc(v)}" ${ckd ? "checked" : ""} ${dis ? "disabled" : ""}
         ${baseReadOnly} ${baseReq} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} class="sf-checkbox ${extraCss}">
  <span class="checkbox-label">${iconHtml}${esc(t)}</span>
</label>`;
                    }).join("");
                    const inner = `<div class="flex flex-wrap items-center gap-2">${items}</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // radio buttons
                if (type === "radio") {
                    const items = (options || []).map(o => {
                        const v = o?.value ?? o?.Value ?? "";
                        const t = o?.text ?? o?.Text ?? o?.label ?? o?.Label ?? v;
                        const dis = !!(o?.disabled ?? o?.Disabled);
                        const ckd = String(value) === String(v);
                        const icon = o?.icon ?? o?.Icon ?? "";
                        const iconHtml = icon ? `<i class="${esc(icon)} mr-1"></i>` : "";
                        
                        return `
<label class="inline-flex items-center gap-2 mr-4 cursor-pointer">
  <input type="radio" name="${esc(name)}" value="${esc(v)}" ${ckd ? "checked" : ""} ${dis ? "disabled" : ""}
         ${baseReadOnly} ${baseReq} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr}
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} class="sf-radio ${extraCss}">
  <span class="radio-label">${iconHtml}${esc(t)}</span>
</label>`;
                    }).join("");
                    const inner = `<div class="flex flex-wrap items-center gap-2">${items}</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // textarea
                if (type === "textarea") {
                    const rows = num(get("rows", null), 3);
                    const autoResize = !!get("autoResize", false);
                    const inner = `<textarea class="sf-textarea ${extraCss}" name="${esc(name)}" rows="${rows}"
      ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode}
      ${autoResize ? 'data-auto-resize="1"' : ""}>${esc(value)}</textarea>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // select dropdown
                if (type === "select") {
                    const asyncSrc = dependsUrl ? `data-source="${esc(dependsUrl)}"` : "";
                    const optsHtml = buildOptions(options, value, multiple);
                    const emptyOption = !multiple && !required ? `<option value="">${esc(placeholder || "اختر...")}</option>` : "";
                    
                    const inner = `<select class="sf-select ${extraCss}" name="${esc(name)}" ${baseMulti}
      ${baseReq} ${baseReadOnly} ${baseDisabled} ${asyncSrc}
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl}>
      ${emptyOption}${optsHtml}
    </select>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // autocomplete (input + datalist + optional remote)
                if (type === "autocomplete") {
                    const listId = `${name}_list_${Date.now()}`;
                    const src = dependsUrl ? `data-source="${esc(dependsUrl)}"` : "";
                    const minlen = num(get("minLength", null), 2);
                    const inner = `
<input class="sf-input ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
  ${basePh} ${baseReq} list="${listId}" data-role="sf-autocomplete" ${src}
  data-minlen="${minlen}" ${baseReadOnly} ${baseDisabled} ${baseMaxLen}
  ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
  ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />
<datalist id="${listId}">
  ${buildOptions(options, value, false)}
</datalist>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // date field
                if (type === "date") {
                    const theVal = value || (defaultToday ? new Date().toISOString().slice(0, 10) : "");
                    const inner = `
<input type="text" name="${esc(name)}" value="${esc(theVal)}" 
  ${basePh || `placeholder="${esc(displayFormat || 'YYYY-MM-DD')}"`}
  class="sf-date ${extraCss}" autocomplete="off" data-role="sf-date"
  data-date-format="${esc(displayFormat || 'yyyy-mm-dd')}"
  data-calendar="${esc(calendar)}" data-input-calendar="${esc(dateInputCalendar)}"
  data-display-lang="${esc(dateDisplayLang)}" data-numerals="${esc(dateNumerals)}"
  data-show-dayname="${showDayName ? "1" : "0"}"
  ${minDateStr ? `data-min="${esc(minDateStr)}"` : ""} 
  ${maxDateStr ? `data-max="${esc(maxDateStr)}"` : ""}
  ${mirrorName ? `data-mirror="${esc(mirrorName)}"` : ""} 
  ${mirrorCalendar ? `data-mirror-cal="${esc(mirrorCalendar)}"` : ""}
  ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} 
  ${baseCap} ${baseCorr} ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // time field
                if (type === "time") {
                    const inner = `<input class="sf-input ${extraCss}" type="time" name="${esc(name)}" value="${esc(value)}"
      ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} 
      ${baseCap} ${baseCorr} ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // datetime-local field
                if (type === "datetime" || type === "datetime-local") {
                    const inner = `<input class="sf-input ${extraCss}" type="datetime-local" name="${esc(name)}" value="${esc(value)}"
      ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseAuto} ${baseSpell} 
      ${baseCap} ${baseCorr} ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // date-range field
                if (type === "date-range") {
                    const fromName = `${name}_from`;
                    const toName = `${name}_to`;
                    const vv = (typeof value === "string" && value.includes("|")) ? value.split("|") : [];
                    const vFrom = vv[0] || "";
                    const vTo = vv[1] || "";
                    const colFrom = resolveColCss(colCssFrom || "col-span-12 md:col-span-6");
                    const colTo = resolveColCss(colCssTo || "col-span-12 md:col-span-6");

                    const inputTpl = (n, v, labelText, sideCss) => `
<div class="form-group ${sideCss}">
  <label class="sf-label">${labelText}${required ? " <span class='req'>*</span>" : ""}</label>
  <input type="text" name="${esc(n)}" value="${esc(v)}" 
         ${basePh || `placeholder="${esc(displayFormat || 'YYYY-MM-DD')}"`}
         class="sf-date ${extraCss}" autocomplete="off" data-role="sf-date-range"
         data-date-format="${esc(displayFormat || 'yyyy-mm-dd')}"
         data-calendar="${esc(calendar)}" data-input-calendar="${esc(dateInputCalendar)}"
         data-display-lang="${esc(dateDisplayLang)}" data-numerals="${esc(dateNumerals)}"
         data-range="${esc(name)}" ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${minDateStr ? `data-min="${esc(minDateStr)}"` : ""} 
         ${maxDateStr ? `data-max="${esc(maxDateStr)}"` : ""}
         ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} 
         ${baseDependsOn} ${baseDependsUrl} ${baseOnChange} />
</div>`;

                    return `
${sectionStart}
${inputTpl(fromName, vFrom, "من", colFrom)}
${inputTpl(toName, vTo, "إلى", colTo)}
${helpText ? `<div class="col-span-12"><div class="form-help">${esc(helpText)}</div></div>` : ""}
${sectionEnd}`;
                }

                // range / slider
                if (type === "range" || type === "slider") {
                    const vmin = num(min, 0);
                    const vmax = num(max, 100);
                    const vstep = num(get("step", null), 1);
                    const showValue = !!get("showValue", true);
                    const inner = `
<div class="range-container">
  <input class="sf-range w-full ${extraCss}" type="range" name="${esc(name)}" 
    value="${esc(value ?? vmin)}" min="${vmin}" max="${vmax}" step="${vstep}" 
    ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseOnChange}
    ${baseDependsOn} ${baseDependsUrl}>
  ${showValue ? `<div class="range-value text-xs text-gray-500 mt-1 text-center">
    <span class="current-value">${esc(value ?? vmin)}</span>
    <span class="range-limits"> (${vmin} - ${vmax})</span>
  </div>` : ""}
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // color picker
                if (type === "color") {
                    const inner = `<input class="sf-input ${extraCss}" type="color" name="${esc(name)}" 
      value="${esc(value || '#000000')}" ${baseReq} ${baseReadOnly} ${baseDisabled} 
      ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // file upload
                if (type === "file") {
                    const accept = get("accept", null);
                    const preview = !!get("preview", false);
                    const maxSize = get("maxSize", null);
                    const inner = `
<input class="sf-file ${extraCss}" type="file" name="${esc(name)}" ${baseMulti}
  ${accept ? `accept="${esc(accept)}"` : ""} ${baseReq} ${baseReadOnly} ${baseDisabled}
  ${maxSize ? `data-max-size="${maxSize}"` : ""} ${yes(preview, 'data-preview="1"')}
  ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />
${preview ? `<div class="mt-2 image-preview" data-image-preview></div>` : ""}`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // rating stars
                if (type === "rating") {
                    const rmax = Number(get("max", 5) || 5);
                    const cur = Number(value || 0);
                    const stars = Array.from({ length: rmax }, (_, i) => i + 1).map(i => `
<button type="button" data-star="${i}" class="rating-star text-2xl leading-none ${i <= cur ? 'text-yellow-400' : 'text-gray-300'}" 
  aria-pressed="${i <= cur ? 'true' : 'false'}" ${baseDisabled ? 'disabled' : ''}>★</button>`).join("");
                    
                    const inner = `
<div class="rating-container inline-flex items-center gap-1 select-none" 
     data-role="sf-rating" ${baseDependsOn} ${baseDependsUrl}>
  ${stars}
  <input type="hidden" name="${esc(name)}" value="${cur}">
  <span class="rating-value ml-2 text-sm text-gray-600">(${cur}/${rmax})</span>
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // currency input
                if (type === "currency") {
                    const symbol = get("symbol", "﷼");
                    const precision = num(get("precision", null), 2);
                    const inner = `
<div class="currency-input flex items-stretch">
  <span class="currency-symbol inline-flex items-center px-3 border border-r-0 bg-gray-50 text-gray-700 rounded-l-md">${esc(symbol)}</span>
  <input class="sf-input rounded-l-none ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
         data-mask="currency" data-symbol="${esc(symbol)}" data-precision="${precision}"
         ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen}
         ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseNumOnly} 
         ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // percentage input
                if (type === "percent") {
                    const inner = `
<div class="percent-input flex items-stretch">
  <input class="sf-input rounded-r-none ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
         data-mask="percent" ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} 
         ${baseMaxLen} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseNumOnly}
         ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />
  <span class="percent-symbol inline-flex items-center px-3 border border-l-0 bg-gray-50 text-gray-700 rounded-r-md">%</span>
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // tags input
                if (type === "tags") {
                    const sep = get("separator", ",");
                    const display = Array.isArray(value) ? value.join(sep) : (value ?? "");
                    const maxTags = get("maxTags", null);
                    const inner = `
<div class="tags-input" data-role="sf-tags" data-separator="${esc(sep)}" ${maxTags ? `data-max-tags="${maxTags}"` : ""}>
  <div class="tags-list flex flex-wrap gap-2 mb-2 p-2 border rounded-md min-h-[2.5rem]" data-tags-list></div>
  <input type="hidden" name="${esc(name)}" value="${esc(display)}">
  <input type="text" class="sf-input ${extraCss}" ${basePh || 'placeholder="اكتب وأضغط Enter"'} 
         ${baseReadOnly} ${baseDisabled} ${baseMaxLen} ${baseAuto} ${baseSpell} 
         ${baseCap} ${baseCorr} ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} />
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // switch/toggle
                if (type === "switch" || type === "toggle") {
                    const checked = !!value || value === "true" || value === "1" || value === 1;
                    const inner = `
<label class="switch-container inline-flex items-center cursor-pointer">
  <input type="checkbox" name="${esc(name)}" value="1" ${checked ? "checked" : ""} 
         class="switch-input sr-only peer" ${baseReq} ${baseReadOnly} ${baseDisabled}
         ${baseOnChange} ${baseDependsOn} ${baseDependsUrl}>
  <div class="switch-slider relative w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
  <span class="switch-label ms-3 text-sm font-medium text-gray-900">${esc(label)}</span>
</label>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, withLabel: false, iconCls })}${sectionEnd}`;
                }

                // code editor
                if (type === "code") {
                    const lang = get("language", "javascript");
                    const rows = num(get("rows", null), 8);
                    const theme = get("theme", "light");
                    const inner = `
<div class="code-editor">
  <div class="code-header flex justify-between items-center p-2 bg-gray-100 border-b text-xs">
    <span class="language-label">لغة: ${esc(lang)}</span>
    <span class="theme-label">المظهر: ${esc(theme)}</span>
  </div>
  <textarea class="sf-textarea code-textarea font-mono ${extraCss}" name="${esc(name)}" rows="${rows}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
    ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
    ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} 
    data-language="${esc(lang)}" data-theme="${esc(theme)}">${esc(value)}</textarea>
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // mask input (based on pattern or inputPattern)
                if (type === "mask") {
                    const maskPattern = pattern || inputPattern;
                    const maskPlaceholder = get("maskPlaceholder", "");
                    const inner = `<input class="sf-input ${extraCss}" type="text" name="${esc(name)}" value="${esc(value)}"
      ${maskPattern ? `data-mask="${esc(maskPattern)}"` : ""} 
      ${maskPlaceholder ? `data-mask-placeholder="${esc(maskPlaceholder)}"` : ""}
      ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // embedded table
                if (type === "table" && tableConfig) {
                    const tableJson = JSON.stringify(tableConfig);
                    const inner = `
<div class="embedded-table-container ${extraCss}" x-data="sfTable(${tableJson})">
  <div class="table-label text-sm text-gray-500 mb-2">جدول مضمّن: ${esc(label)}</div>
  <!-- هنا سيتم عرض الجدول المضمّن -->
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // number input
                if (type === "number") {
                    const step = get("step", null);
                    const precision = get("precision", null);
                    const inner = `<input class="sf-input ${extraCss}" type="number" name="${esc(name)}" value="${esc(value)}"
      ${baseMin} ${baseMax} ${step != null ? `step="${step}"` : ""} 
      ${precision != null ? `data-precision="${precision}"` : ""} ${basePh} ${baseReq}
      ${baseReadOnly} ${baseDisabled} ${baseMaxLen} ${baseAuto} ${baseSpell} 
      ${baseCap} ${baseCorr} ${baseDir} ${baseOnChange} ${baseDependsOn} 
      ${baseDependsUrl} ${baseInputPat} ${baseNumOnly} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // email input
                if (type === "email") {
                    const inner = `<input class="sf-input ${extraCss}" type="email" name="${esc(name)}" value="${esc(value)}"
      ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // password input
                if (type === "password") {
                    const showToggle = !!get("showToggle", false);
                    const inner = `
<div class="password-container relative">
  <input class="sf-input ${extraCss} ${showToggle ? 'pr-10' : ''}" type="password" name="${esc(name)}" value="${esc(value)}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
    ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
    ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />
  ${showToggle ? `<button type="button" class="password-toggle absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500" onclick="this.previousElementSibling.type = this.previousElementSibling.type === 'password' ? 'text' : 'password'">👁</button>` : ""}
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // phone/tel input  
                if (type === "phone" || type === "tel") {
                    const countryCode = get("countryCode", "+966");
                    const inner = `
<div class="phone-container flex">
  ${countryCode ? `<span class="country-code inline-flex items-center px-3 border border-r-0 bg-gray-50 text-gray-700 rounded-l-md">${esc(countryCode)}</span>` : ""}
  <input class="sf-input ${countryCode ? 'rounded-l-none' : ''} ${extraCss}" type="tel" name="${esc(name)}" value="${esc(value)}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
    ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
    ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />
</div>`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // url input
                if (type === "url") {
                    const inner = `<input class="sf-input ${extraCss}" type="url" name="${esc(name)}" value="${esc(value)}"
      ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // search input
                if (type === "search") {
                    const inner = `<input class="sf-input ${extraCss}" type="search" name="${esc(name)}" value="${esc(value)}"
      ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
      ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} ${baseOnChange}
      ${baseDependsOn} ${baseDependsUrl} ${baseInputPat} ${baseTextMode} />`;
                    return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
                }

                // default text input (fallback for any unhandled type)
                const inputType = mapType(type);
                const inner = `<input class="sf-input ${extraCss}" type="${inputType}" name="${esc(name)}" value="${esc(value)}"
    ${basePh} ${baseReq} ${baseReadOnly} ${baseDisabled} ${baseMaxLen} 
    ${baseMin} ${baseMax} ${basePat} ${baseAuto} ${baseSpell} ${baseCap} ${baseCorr} 
    ${baseDir} ${baseOnChange} ${baseDependsOn} ${baseDependsUrl} 
    ${baseInputPat} ${baseIban} ${baseNumOnly} ${baseTextMode} />`;
                
                return `${sectionStart}${wrapField({ inner, label, required, helpText, colCss, iconCls })}${sectionEnd}`;
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



