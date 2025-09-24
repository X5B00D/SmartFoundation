﻿// wwwroot/js/sf-table.js - Complete Rewrite
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
            autoRefresh: !!cfg.autoRefreshOnSubmit,
            
            // Structure
            columns: Array.isArray(cfg.columns) ? cfg.columns : [],
            actions: Array.isArray(cfg.actions) ? cfg.actions : [],
            
            // Selection
            selectable: !!cfg.selectable,
            rowIdField: cfg.rowIdField || "Id",
            
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
            
            // Selection State
            selectedKeys: new Set(),
            selectAll: false,
            
            // Modal State
            modal: {
                open: false,
                title: "",
                html: "",
                action: null,
                loading: false,
                error: null
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

            setupEventListeners() {
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' && this.modal.open) {
                        this.closeModal();
                    }
                });
            },

            // ===== Data Loading & Filtering =====
            async load() {
                this.loading = true;
                this.error = null;
                
                try {
                    // Load all data once from server
                    if (this.allRows.length === 0) {
                        const body = {
                            Component: "Table",
                            SpName: this.spName,
                            Operation: this.operation,
                            Paging: { Page: 1, Size: 1000000 }
                        };
                        
                        const json = await this.postJson(this.endpoint, body);
                        this.allRows = Array.isArray(json?.data) ? json.data : [];
                    }
                    
                    // Apply local filtering and sorting
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
                
                // Apply search filter
                if (this.q && this.quickSearchFields.length > 0) {
                    const qLower = this.q.toLowerCase();
                    filtered = filtered.filter(row => 
                        this.quickSearchFields.some(field => 
                            String(row[field] || "").toLowerCase().includes(qLower)
                        )
                    );
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
            },

            // ===== Debounced Search =====
            debouncedSearch() {
                clearTimeout(this.searchTimer);
                this.searchTimer = setTimeout(() => {
                    this.page = 1;
                    this.applyFiltersAndSort();
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
                
                this.applyFiltersAndSort();
            },

            // ===== Selection Management =====
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
                    this.rows.forEach(row => this.selectedKeys.add(row[this.rowIdField]));
                } else {
                    this.selectedKeys.clear();
                }
                this.updateSelectAllState();
            },

            updateSelectAllState() {
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
                    
                    this.$nextTick(() => {
                        this.initModalScripts();
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
            },

            // ===== Form Generation =====
            generateFormHtml(formConfig, rowData) {
                if (!formConfig) return "";
                
                const formId = formConfig.formId || "modalForm";
                const method = formConfig.method || "POST";
                const action = formConfig.actionUrl || "#";
                
                let html = `<form id="${formId}" method="${method}" action="${action}" class="sf-modal-form">`;
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
                            const btnClass = `btn btn-${btn.color || 'secondary'}`;
                            const icon = btn.icon ? `<i class="${btn.icon}"></i> ` : "";
                            const onClick = btn.type === 'submit' ? "" : (btn.onClickJs || "");
                            html += `<button type="${btnType}" class="${btnClass}" ${onClick ? `onclick="${onClick}"` : ""}>${icon}${btn.text}</button>`;
                        }
                    });
                    html += `</div>`;
                } else {
                    // Default buttons
                    html += `<div class="col-span-12 flex justify-end gap-2 mt-4">`;
                    html += `<button type="button" class="btn btn-secondary" onclick="this.closest('.sf-modal').__x.$data.closeModal()">إلغاء</button>`;
                    html += `<button type="submit" class="btn btn-success">حفظ</button>`;
                    html += `</div>`;
                }
                
                html += `</div></form>`;
                return html;
            },

            generateFieldHtml(field, rowData) {
                if (!field || !field.name) return "";
                
                const value = rowData ? (rowData[field.name] || field.value || "") : (field.value || "");
                const colCss = this.resolveColCss(field.colCss || "6");
                const required = field.required ? "required" : "";
                const disabled = field.disabled ? "disabled" : "";
                const readonly = field.readonly ? "readonly" : "";
                const placeholder = field.placeholder ? `placeholder="${this.escapeHtml(field.placeholder)}"` : "";
                const maxLength = field.maxLength ? `maxlength="${field.maxLength}"` : "";
                
                let fieldHtml = "";
                
                switch ((field.type || "text").toLowerCase()) {
                    case "text":
                    case "email":
                    case "url":
                    case "search":
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                            </label>
                            <input type="${field.type || 'text'}" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
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
                                     class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                     ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>${this.escapeHtml(value)}</textarea>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                        
                    case "select":
                        let options = "";
                        if (!field.required) {
                            options += `<option value="">${field.placeholder || 'اختر...'}</option>`;
                        }
                        (field.options || []).forEach(opt => {
                            const selected = String(value) === String(opt.value) ? "selected" : "";
                            const optDisabled = opt.disabled ? "disabled" : "";
                            options += `<option value="${this.escapeHtml(opt.value)}" ${selected} ${optDisabled}>${this.escapeHtml(opt.text)}</option>`;
                        });
                        
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                            </label>
                            <select name="${this.escapeHtml(field.name)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   ${required} ${disabled}>
                                ${options}
                            </select>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                        
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
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                            </label>
                            <input type="date" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   ${required} ${disabled} ${readonly}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                        
                    case "number":
                        const min = field.min !== undefined ? `min="${field.min}"` : "";
                        const max = field.max !== undefined ? `max="${field.max}"` : "";
                        const step = field.step !== undefined ? `step="${field.step}"` : "";
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                            </label>
                            <input type="number" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   ${placeholder} ${min} ${max} ${step} ${required} ${disabled} ${readonly}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                        
                    case "phone":
                    case "tel":
                        fieldHtml = `
                        <div class="form-group ${colCss}">
                            <label class="block text-sm font-medium text-gray-700 mb-1">
                                ${this.escapeHtml(field.label)} ${field.required ? '<span class="text-red-500">*</span>' : ''}
                            </label>
                            <input type="tel" name="${this.escapeHtml(field.name)}" 
                                   value="${this.escapeHtml(value)}" 
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   ${placeholder} ${required} ${disabled} ${readonly} ${maxLength}>
                            ${field.helpText ? `<p class="mt-1 text-xs text-gray-500">${this.escapeHtml(field.helpText)}</p>` : ''}
                        </div>`;
                        break;
                        
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
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
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

            initModalScripts() {
                // Set up form submission
                const form = this.$el.querySelector('.sf-modal form');
                if (form) {
                    form.addEventListener('submit', (e) => {
                        e.preventDefault();
                        this.saveModalChanges();
                    });
                }
            },

            async saveModalChanges() {
                if (!this.modal.action) return;
                
                const form = this.$el.querySelector('.sf-modal form');
                if (!form) return;
                
                try {
                    this.modal.loading = true;
                    this.modal.error = null;
                    
                    const formData = this.serializeForm(form);
                    
                    const success = await this.executeSp(
                        this.modal.action.saveSp,
                        this.modal.action.saveOp || (this.modal.action.isEdit ? "update" : "insert"),
                        formData
                    );
                    
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
            async executeSp(spName, operation, params) {
                try {
                    const body = {
                        Component: "Form",
                        SpName: spName,
                        Operation: operation,
                        Params: params || {}
                    };
                    
                    const result = await this.postJson(this.endpoint, body);
                    
                    if (result?.message) {
                        this.showToast(result.message, 'success');
                    }
                    
                    return true;
                    
                } catch (e) {
                    console.error("Execute SP error:", e);
                    this.showToast("⚠️ " + (e.message || "فشل العملية"), 'error');
                    
                    if (e.server?.errors) {
                        this.applyServerErrors(e.server.errors);
                    }
                    
                    return false;
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
            formatCell(row, col) {
                let value = row[col.field];
                if (value == null) return "";
                
                switch (col.type) {
                    case "date":
                        try {
                            return new Date(value).toLocaleDateString('ar-SA');
                        } catch {
                            return value;
                        }
                    case "datetime":
                        try {
                            return new Date(value).toLocaleString('ar-SA');
                        } catch {
                            return value;
                        }
                    case "bool":
                        return value ? '<span class="text-green-600">✓</span>' : '<span class="text-red-600">✗</span>';
                    case "money":
                        try {
                            return new Intl.NumberFormat('ar-SA', { 
                                style: 'currency', 
                                currency: 'SAR' 
                            }).format(value);
                        } catch {
                            return value;
                        }
                    case "badge":
                        const badgeClass = col.badge?.map?.[value] || col.badge?.defaultClass || "bg-gray-100 text-gray-800";
                        return `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${badgeClass}">${this.escapeHtml(value)}</span>`;
                    case "link":
                        if (col.linkTemplate) {
                            const href = this.fillUrl(col.linkTemplate, row);
                            return `<a href="${this.escapeHtml(href)}" class="text-blue-600 hover:text-blue-800 hover:underline">${this.escapeHtml(value)}</a>`;
                        }
                        return this.escapeHtml(value);
                    case "image":
                        if (col.imageTemplate) {
                            const src = this.fillUrl(col.imageTemplate, row);
                            return `<img src="${this.escapeHtml(src)}" alt="${this.escapeHtml(value)}" class="h-8 w-8 rounded object-cover">`;
                        }
                        return this.escapeHtml(value);
                    default:
                        return this.escapeHtml(String(value));
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
            goToPage(page) {
                const newPage = Math.max(1, Math.min(page, this.pages));
                if (newPage !== this.page) {
                    this.page = newPage;
                    this.applyFiltersAndSort();
                }
            },

            nextPage() {
                if (this.page < this.pages) {
                    this.page++;
                    this.applyFiltersAndSort();
                }
            },

            prevPage() {
                if (this.page > 1) {
                    this.page--;
                    this.applyFiltersAndSort();
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



