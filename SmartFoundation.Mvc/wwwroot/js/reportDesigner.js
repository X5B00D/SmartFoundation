/**
 * Smart Report Designer (design-only)
 * =====================================
 * Features:
 * - Left: HTML/CSS code editor (CodeMirror)
 * - Center: Live A4 preview (Portrait/Landscape)
 * - Right: Smart helper panel (placeholders, presets, validation)
 *
 * Security:
 * - DOMPurify sanitization applies ONLY to preview rendering
 * - Editor content and copied output remain RAW
 * - Printing pipeline is untouched
 */
(function () {
    'use strict';

    // ─────────────────────────────────────────────────────────────────────────
    // STATE
    // ─────────────────────────────────────────────────────────────────────────
    let codeMirrorEditor = null;
    let currentOrientation = 'portrait'; // 'portrait' | 'landscape'

    // SECURITY: Sanitization must be enabled for preview rendering.
    const sanitizeHtml = true;

    // Available placeholders (can be dynamically loaded from SP metadata)
    // Using 'let' to allow dynamic updates when loading from stored procedures
    let availablePlaceholders = [
        'fullName', 'generalNo', 'Department', 'Rank', 'HireDate',
        'NationalID', 'Phone', 'Email', 'Manager', 'Position',
        'Salary', 'Branch', 'Section', 'DateOfBirth', 'Address',
        'EmployeeNo', 'JobTitle', 'StartDate', 'EndDate', 'Notes'
    ];

    // Track last loaded SP for display purposes
    let lastLoadedSpName = null;

    // Database-loaded template presets (populated on init)
    let dbPresets = [];
    let dbPresetsLoaded = false;

    // Configurable sample data for preview
    let sampleData = {
        fullName: 'أحمد محمد العلي',
        generalNo: '60014016',
        Department: 'إدارة تقنية المعلومات',
        Rank: 'مدير',
        HireDate: '2020-01-15',
        NationalID: '1064184763',
        Phone: '0501234567',
        Email: 'ahmad@example.com',
        Manager: 'سعيد الغامدي',
        Position: 'مهندس برمجيات',
        Salary: '15,000',
        Branch: 'الفرع الرئيسي',
        Section: 'قسم التطوير',
        DateOfBirth: '1985-03-20',
        Address: 'الرياض - حي الملقا',
        EmployeeNo: 'EMP-2024-001',
        JobTitle: 'مهندس أول',
        StartDate: '2024-01-01',
        EndDate: '2024-12-31',
        Notes: 'ملاحظات إضافية'
    };

    // ─────────────────────────────────────────────────────────────────────────
    // TEMPLATE PRESETS
    // ─────────────────────────────────────────────────────────────────────────
    const presets = {
        employeeCard: `<style>
  .emp-card {
    border: 2px solid #1a365d;
    border-radius: 12px;
    padding: 24px;
    font-family: 'Arial', sans-serif;
    max-width: 400px;
    margin: 0 auto;
    direction: rtl;
  }
  .emp-header {
    text-align: center;
    border-bottom: 2px solid #1a365d;
    padding-bottom: 16px;
    margin-bottom: 16px;
  }
  .emp-header h1 {
    font-size: 24px;
    color: #1a365d;
    margin: 0 0 8px 0;
  }
  .emp-row {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid #e2e8f0;
  }
  .emp-label {
    font-weight: 600;
    color: #4a5568;
  }
  .emp-value {
    color: #1a202c;
  }
</style>

<div class="emp-card">
  <div class="emp-header">
    <h1>بطاقة الموظف</h1>
  </div>
  <div class="emp-row"><span class="emp-label">الاسم:</span><span class="emp-value">{{fullName}}</span></div>
  <div class="emp-row"><span class="emp-label">الرقم العام:</span><span class="emp-value">{{generalNo}}</span></div>
  <div class="emp-row"><span class="emp-label">الإدارة:</span><span class="emp-value">{{Department}}</span></div>
  <div class="emp-row"><span class="emp-label">الرتبة:</span><span class="emp-value">{{Rank}}</span></div>
  <div class="emp-row"><span class="emp-label">تاريخ التعيين:</span><span class="emp-value">{{HireDate}}</span></div>
</div>`,

        tableReport: `<style>
  .report-container {
    font-family: 'Arial', sans-serif;
    direction: rtl;
  }
  .report-header {
    text-align: center;
    margin-bottom: 24px;
  }
  .report-header h1 {
    font-size: 26px;
    color: #1a365d;
    margin: 0 0 8px 0;
  }
  .report-header p {
    color: #718096;
    margin: 0;
  }
  .data-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 16px;
  }
  .data-table th,
  .data-table td {
    border: 1px solid #cbd5e0;
    padding: 12px;
    text-align: right;
  }
  .data-table th {
    background: #2d3748;
    color: white;
    font-weight: 600;
  }
  .data-table tr:nth-child(even) {
    background: #f7fafc;
  }
</style>

<div class="report-container">
  <div class="report-header">
    <h1>تقرير بيانات الموظف</h1>
    <p>تاريخ التقرير: {{StartDate}}</p>
  </div>
  
  <table class="data-table">
    <thead>
      <tr>
        <th>البيان</th>
        <th>القيمة</th>
      </tr>
    </thead>
    <tbody>
      <tr><td>الاسم الكامل</td><td>{{fullName}}</td></tr>
      <tr><td>الرقم العام</td><td>{{generalNo}}</td></tr>
      <tr><td>الإدارة</td><td>{{Department}}</td></tr>
      <tr><td>القسم</td><td>{{Section}}</td></tr>
      <tr><td>المسمى الوظيفي</td><td>{{JobTitle}}</td></tr>
      <tr><td>الهاتف</td><td>{{Phone}}</td></tr>
    </tbody>
  </table>
</div>`,

        officialLetter: `<style>
  .letter {
    font-family: 'Arial', sans-serif;
    direction: rtl;
    line-height: 1.8;
  }
  .letter-header {
    text-align: center;
    border-bottom: 3px double #1a365d;
    padding-bottom: 20px;
    margin-bottom: 30px;
  }
  .letter-header h1 {
    font-size: 28px;
    color: #1a365d;
    margin: 0;
  }
  .letter-date {
    text-align: left;
    margin-bottom: 20px;
    color: #4a5568;
  }
  .letter-body {
    font-size: 16px;
    text-align: justify;
  }
  .letter-body p {
    margin-bottom: 16px;
  }
  .letter-signature {
    margin-top: 50px;
    text-align: left;
  }
  .letter-signature .name {
    font-weight: bold;
    font-size: 18px;
  }
</style>

<div class="letter">
  <div class="letter-header">
    <h1>خطاب رسمي</h1>
  </div>
  
  <div class="letter-date">
    التاريخ: {{StartDate}}
  </div>
  
  <div class="letter-body">
    <p>السيد / {{fullName}} &nbsp;&nbsp; المحترم</p>
    <p>الرقم العام: {{generalNo}}</p>
    <p>الإدارة: {{Department}}</p>
    <p>
      نفيدكم بأنه قد تم الموافقة على طلبكم المقدم بتاريخ {{HireDate}}،
      ونأمل منكم مراجعة الإدارة المختصة لاستكمال الإجراءات اللازمة.
    </p>
    <p>مع خالص التحية والتقدير،</p>
  </div>
  
  <div class="letter-signature">
    <div class="name">{{Manager}}</div>
    <div>{{Position}}</div>
  </div>
</div>`,

        certificate: `<style>
  .certificate {
    font-family: 'Arial', sans-serif;
    text-align: center;
    padding: 40px;
    border: 8px double #c9a227;
    background: linear-gradient(135deg, #fefefe 0%, #f5f5dc 100%);
    direction: rtl;
  }
  .certificate-header {
    margin-bottom: 30px;
  }
  .certificate-header h1 {
    font-size: 36px;
    color: #8b7355;
    margin: 0;
    letter-spacing: 4px;
  }
  .certificate-body {
    font-size: 20px;
    line-height: 2;
    margin: 40px 0;
  }
  .certificate-name {
    font-size: 32px;
    font-weight: bold;
    color: #1a365d;
    margin: 20px 0;
    padding: 10px;
    border-bottom: 2px solid #c9a227;
    display: inline-block;
  }
  .certificate-footer {
    margin-top: 50px;
    display: flex;
    justify-content: space-around;
  }
  .certificate-footer div {
    text-align: center;
  }
  .signature-line {
    width: 150px;
    border-top: 1px solid #333;
    margin: 10px auto 5px;
  }
</style>

<div class="certificate">
  <div class="certificate-header">
    <h1>شهادة تقدير</h1>
  </div>
  
  <div class="certificate-body">
    <p>تشهد إدارة {{Department}} بأن</p>
    <div class="certificate-name">{{fullName}}</div>
    <p>الرقم العام: {{generalNo}}</p>
    <p>قد أتم بنجاح متطلبات البرنامج التدريبي</p>
    <p>بتاريخ: {{EndDate}}</p>
  </div>
  
  <div class="certificate-footer">
    <div>
      <div class="signature-line"></div>
      <div>{{Manager}}</div>
      <div>المدير العام</div>
    </div>
    <div>
      <div class="signature-line"></div>
      <div>التاريخ: {{StartDate}}</div>
    </div>
  </div>
</div>`
    };

    // A4 Boilerplate template
    const a4Boilerplate = `<style>
  /* A4 Base Styles - Print Safe */
  .a4-page {
    font-family: 'Arial', 'Tahoma', sans-serif;
    font-size: 14px;
    line-height: 1.6;
    color: #1a202c;
    direction: rtl;
    text-align: right;
  }
  .a4-page * {
    box-sizing: border-box;
  }
  .page-header {
    text-align: center;
    padding-bottom: 16px;
    margin-bottom: 20px;
    border-bottom: 2px solid #2d3748;
  }
  .page-header h1 {
    font-size: 24px;
    margin: 0 0 8px 0;
    color: #1a365d;
  }
  .page-content {
    /* Main content area */
  }
  .page-footer {
    margin-top: 40px;
    padding-top: 16px;
    border-top: 1px solid #e2e8f0;
    text-align: center;
    font-size: 12px;
    color: #718096;
  }
</style>

<div class="a4-page">
  <div class="page-header">
    <h1>عنوان التقرير</h1>
    <p>وصف مختصر أو تاريخ</p>
  </div>
  
  <div class="page-content">
    <!-- Add your content here -->
    <p>محتوى التقرير يبدأ هنا...</p>
    <p>استخدم {{placeholders}} للبيانات الديناميكية</p>
  </div>
  
  <div class="page-footer">
    <p>جميع الحقوق محفوظة © 2026</p>
  </div>
</div>`;

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER FUNCTIONS
    // ─────────────────────────────────────────────────────────────────────────

    function getRawTemplate(editorEl) {
        if (codeMirrorEditor) return codeMirrorEditor.getValue() || '';
        return editorEl?.value || '';
    }

    function setRawTemplate(content) {
        if (codeMirrorEditor) {
            codeMirrorEditor.setValue(content);
        } else {
            const editor = document.getElementById('reportDesignerEditor');
            if (editor) editor.value = content;
        }
    }

    function applySampleData(html) {
        return html.replace(/{{\s*([A-Za-z0-9_]+)\s*}}/g, (match, key) => {
            if (Object.prototype.hasOwnProperty.call(sampleData, key)) {
                return String(sampleData[key]);
            }
            return match; // unknown placeholder: keep visible for debugging
        });
    }

    function getOrientationDimensions() {
        if (currentOrientation === 'landscape') {
            return { width: '297mm', height: '210mm' };
        }
        return { width: '210mm', height: '297mm' };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PREVIEW BUILDER (with DOMPurify sanitization)
    // ─────────────────────────────────────────────────────────────────────────

    function buildSrcDoc(userHtml) {
        const replaced = applySampleData(userHtml);
        const replacedJson = JSON.stringify(replaced).replace(/<\/script/gi, '<\\/script');
        const dims = getOrientationDimensions();

        return `<!doctype html>
<html dir="ltr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html, body { margin: 0; padding: 0; }
    html { direction: ltr; }
    body {
      width: ${dims.width};
      height: ${dims.height};
      background: white;
      padding: 15mm;
      box-sizing: border-box;
      direction: ltr;
    }
  </style>
</head>
<body>
  <div id="__previewRoot"></div>

  <script src="/js/lib/dompurify/purify.min.js"><\/script>
  <script>
    (function () {
      try {
        var root = document.getElementById('__previewRoot');
        if (!root) return;

        // 1) Get editor content (with sample data already replaced)
        var rawHtml = ${replacedJson};

        // 2) Sanitize ONLY for preview rendering (security)
        var htmlToRender = rawHtml;
        if (${sanitizeHtml ? 'true' : 'false'} && window.DOMPurify) {
          htmlToRender = window.DOMPurify.sanitize(rawHtml, {
            ALLOWED_TAGS: [
              'div', 'span', 'table', 'thead', 'tbody', 'tfoot', 'tr', 'th', 'td',
              'img', 'style', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'br', 'hr',
              'ul', 'ol', 'li', 'strong', 'b', 'em', 'i', 'u', 'small', 'sub', 'sup'
            ],
            ALLOWED_ATTR: [
              'id', 'class', 'style', 'src', 'width', 'height', 'colspan', 'rowspan',
              'alt', 'title', 'dir'
            ]
          });
        }

        // 3) Inject sanitized HTML
        root.innerHTML = htmlToRender;

        // 4) Preview-only: unhide common template wrappers
        var wrappers = root.querySelectorAll('[id*="Template"], [id*="template"]');
        wrappers.forEach(function (el) {
          var styleAttr = el.getAttribute('style');
          if (styleAttr && /display\\s*:\\s*none/i.test(styleAttr)) {
            var nextStyle = styleAttr
              .replace(/display\\s*:\\s*none\\s*;?/ig, '')
              .replace(/;;+/g, ';')
              .trim();
            if (nextStyle) el.setAttribute('style', nextStyle);
            else el.removeAttribute('style');
          }
          if (el.style && el.style.display === 'none') {
            el.style.display = '';
          }
        });
      } catch (e) {
        // Swallow errors: preview must never break
      }
    })();
  <\/script>
</body>
</html>`;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATION
    // ─────────────────────────────────────────────────────────────────────────

    function validateTemplate(html) {
        const results = [];

        // Check for forbidden tags
        const forbiddenTags = ['script', 'iframe', 'object', 'embed', 'form', 'input', 'button', 'link'];
        forbiddenTags.forEach(tag => {
            const regex = new RegExp(`<${tag}[\\s>]`, 'gi');
            if (regex.test(html)) {
                results.push({ type: 'error', message: `Forbidden tag detected: <${tag}>` });
            }
        });

        // Check for forbidden attributes
        const forbiddenAttrs = ['onclick', 'onerror', 'onload', 'onmouseover', 'onfocus', 'onblur'];
        forbiddenAttrs.forEach(attr => {
            const regex = new RegExp(`\\s${attr}\\s*=`, 'gi');
            if (regex.test(html)) {
                results.push({ type: 'error', message: `Forbidden attribute: ${attr}` });
            }
        });

        // Check for unknown placeholders
        const placeholderRegex = /{{\s*([A-Za-z0-9_]+)\s*}}/g;
        let match;
        while ((match = placeholderRegex.exec(html)) !== null) {
            if (!availablePlaceholders.includes(match[1])) {
                results.push({ type: 'warning', message: `Unknown placeholder: {{${match[1]}}}` });
            }
        }

        // Check for basic structure
        if (!html.includes('<style')) {
            results.push({ type: 'warning', message: 'No <style> block found. Consider adding CSS.' });
        }

        if (html.trim().length < 50) {
            results.push({ type: 'warning', message: 'Template seems too short.' });
        }

        if (results.length === 0) {
            results.push({ type: 'success', message: 'Template is valid! ✓' });
        }

        return results;
    }

    function renderValidationResults(results) {
        const container = document.getElementById('validationResults');
        if (!container) return;

        container.innerHTML = results.map(r => {
            const cls = `validation-msg ${r.type}`;
            const icon = r.type === 'error' ? 'fa-times-circle' :
                r.type === 'warning' ? 'fa-exclamation-triangle' :
                    'fa-check-circle';
            return `<div class="${cls}"><i class="fa-solid ${icon}"></i> ${r.message}</div>`;
        }).join('');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PLACEHOLDER PANEL
    // ─────────────────────────────────────────────────────────────────────────

    function renderPlaceholderPanel() {
        const container = document.getElementById('placeholderList');
        if (!container) return;

        container.innerHTML = availablePlaceholders.map(p =>
            `<span class="placeholder-chip" data-placeholder="${p}">{{${p}}}</span>`
        ).join('');

        // Click to insert at cursor
        container.querySelectorAll('.placeholder-chip').forEach(chip => {
            chip.addEventListener('click', () => {
                const placeholder = `{{${chip.dataset.placeholder}}}`;
                insertAtCursor(placeholder);
            });
        });
    }

    function insertAtCursor(text) {
        if (codeMirrorEditor) {
            const doc = codeMirrorEditor.getDoc();
            const cursor = doc.getCursor();
            doc.replaceRange(text, cursor);
            codeMirrorEditor.focus();
        } else {
            const editor = document.getElementById('reportDesignerEditor');
            if (!editor) return;
            const start = editor.selectionStart;
            const end = editor.selectionEnd;
            const value = editor.value;
            editor.value = value.substring(0, start) + text + value.substring(end);
            editor.selectionStart = editor.selectionEnd = start + text.length;
            editor.focus();
            editor.dispatchEvent(new Event('input'));
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SP FIELD LOADER (Design-time assistance only)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Loads column names from a stored procedure using metadata inspection.
     * This is design-time assistance ONLY - does NOT execute real data queries.
     * Uses sys.dm_exec_describe_first_result_set_for_object for safe metadata extraction.
     * @param {string} spName - The stored procedure name (e.g., "dbo.EmpInfoNew")
     */
    async function loadSpColumns(spName) {
        const statusEl = document.getElementById('spLoadStatus');
        const loadBtn = document.getElementById('loadSpFieldsBtn');

        if (!spName || typeof spName !== 'string' || !spName.trim()) {
            if (statusEl) {
                statusEl.innerHTML = '<span class="text-red-600"><i class="fa-solid fa-times-circle"></i> Please enter a stored procedure name</span>';
            }
            return;
        }

        spName = spName.trim();

        // UI: Show loading state
        if (statusEl) {
            statusEl.innerHTML = '<span class="text-blue-600"><i class="fa-solid fa-spinner fa-spin"></i> Loading columns...</span>';
        }
        if (loadBtn) {
            loadBtn.disabled = true;
        }

        try {
            const response = await fetch('/ReportGen/GetSpColumns', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ spName })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();

            if (!result.success) {
                throw new Error(result.error || 'Failed to load columns');
            }

            const columns = result.columns || [];

            if (columns.length === 0) {
                if (statusEl) {
                    statusEl.innerHTML = '<span class="text-yellow-600"><i class="fa-solid fa-exclamation-triangle"></i> No columns found</span>';
                }
                return;
            }

            // SUCCESS: Update available placeholders
            availablePlaceholders = columns;
            lastLoadedSpName = spName;

            // Also update sample data with empty values for new columns
            columns.forEach(col => {
                if (!Object.prototype.hasOwnProperty.call(sampleData, col)) {
                    sampleData[col] = `[${col}]`; // Placeholder preview value
                }
            });

            // Re-render placeholder panel
            renderPlaceholderPanel();

            // Show success message
            if (statusEl) {
                statusEl.innerHTML = `<span class="text-green-600"><i class="fa-solid fa-check-circle"></i> Loaded ${columns.length} fields from <code>${spName}</code></span>`;
            }

            console.log('[ReportDesigner] Loaded columns from SP:', spName, columns);

        } catch (err) {
            console.error('[ReportDesigner] loadSpColumns error:', err);
            if (statusEl) {
                statusEl.innerHTML = `<span class="text-red-600"><i class="fa-solid fa-times-circle"></i> ${err.message || 'Error loading columns'}</span>`;
            }
        } finally {
            if (loadBtn) {
                loadBtn.disabled = false;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DATABASE TEMPLATE PRESETS
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Loads available report templates from the database for use as presets.
     * Templates are loaded from GetReportsList via the API.
     * Implements professional error handling with user feedback.
     */
    async function loadDatabasePresets() {
        const statusEl = document.getElementById('dbPresetStatus');
        const sectionEl = document.getElementById('dbPresetsSection');

        try {
            console.log('[ReportDesigner] Loading database presets...');

            // Show loading state
            if (sectionEl) {
                sectionEl.innerHTML = '<p class="text-xs text-slate-500"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</p>';
            }

            const response = await fetch('/ReportGen/GetReportTemplates', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                }
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error('[ReportDesigner] Failed to load database presets:', response.status, errorText);
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            console.log('[ReportDesigner] GetReportTemplates response:', result);

            if (!result.success) {
                const errorMsg = result.error || result.message || 'Failed to load templates';
                console.warn('[ReportDesigner] GetReportTemplates unsuccessful:', errorMsg);
                throw new Error(errorMsg);
            }

            if (!Array.isArray(result.templates)) {
                console.warn('[ReportDesigner] Templates is not an array:', result);
                throw new Error('Invalid response format: templates array missing');
            }

            dbPresets = result.templates;
            dbPresetsLoaded = true;

            console.log('[ReportDesigner] Successfully loaded', dbPresets.length, 'database presets');

            // Render the database presets section
            renderDatabasePresets();

            // Show success feedback briefly
            if (statusEl && dbPresets.length > 0) {
                statusEl.innerHTML = `<span class="text-green-600 text-xs"><i class="fa-solid fa-check-circle"></i> تم تحميل ${dbPresets.length} قالب</span>`;
                setTimeout(() => { statusEl.innerHTML = ''; }, 3000);
            }

        } catch (err) {
            console.error('[ReportDesigner] Error loading database presets:', err);

            // Show user-friendly error message
            if (sectionEl) {
                sectionEl.innerHTML = `
                    <p class="text-xs text-slate-500 mb-2">لم يتم العثور على قوالب محفوظة</p>
                    <button type="button" onclick="location.reload()" class="text-xs text-blue-600 hover:underline">
                        <i class="fa-solid fa-rotate"></i> إعادة المحاولة
                    </button>
                `;
            }

            if (statusEl) {
                statusEl.innerHTML = `<span class="text-red-600 text-xs"><i class="fa-solid fa-times-circle"></i> ${err.message}</span>`;
            }
        }
    }

    /**
     * Renders the database presets section in the helper panel.
     * Displays preset buttons with Arabic/English names.
     */
    function renderDatabasePresets() {
        const presetsSection = document.getElementById('dbPresetsSection');

        if (!presetsSection) {
            console.warn('[ReportDesigner] dbPresetsSection element not found');
            return;
        }
        if (!presetsSection) return;

        if (!dbPresetsLoaded || dbPresets.length === 0) {
            presetsSection.innerHTML = '<p class="text-xs text-slate-500">لا توجد قوالب محفوظة</p>';
            return;
        }

        presetsSection.innerHTML = dbPresets.map(preset =>
            `<button type="button" class="preset-btn db-preset-btn" data-report-id="${preset.reportID}">
                <i class="fa-solid fa-file-lines"></i> ${preset.reportName || 'قالب #' + preset.reportID}
            </button>`
        ).join('');

        // Attach click handlers
        presetsSection.querySelectorAll('.db-preset-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const reportId = parseInt(btn.dataset.reportId, 10);
                if (reportId > 0) {
                    loadDatabaseTemplate(reportId);
                }
            });
        });
    }

    /**
     * Loads a specific template from the database and inserts it into the editor.
     * @param {number} reportID - The report ID to load
     */
    async function loadDatabaseTemplate(reportID) {
        const statusEl = document.getElementById('dbPresetStatus');

        try {
            // Show loading state
            if (statusEl) {
                statusEl.innerHTML = '<span class="text-blue-600"><i class="fa-solid fa-spinner fa-spin"></i> جاري التحميل...</span>';
            }

            const response = await fetch(`/ReportGen/GetReportTemplate/${reportID}`, {
                method: 'GET',
                headers: { 'Content-Type': 'application/json' }
            });

            if (!response.ok) {
                throw new Error('فشل تحميل القالب');
            }

            const result = await response.json();

            if (!result.success) {
                throw new Error(result.error || 'فشل تحميل القالب');
            }

            if (!result.reportDesign) {
                throw new Error('القالب لا يحتوي على محتوى');
            }

            // Confirm before replacing
            if (!confirm(`سيتم استبدال المحتوى الحالي بالقالب "${result.reportName || 'القالب'}". هل تريد المتابعة؟`)) {
                if (statusEl) statusEl.innerHTML = '';
                return;
            }

            // Insert the template into the editor (raw, with {{placeholders}} intact)
            setRawTemplate(result.reportDesign);

            // Trigger re-render
            const previewFrame = document.getElementById('reportDesignerPreview');
            const editor = document.getElementById('reportDesignerEditor');
            if (previewFrame) {
                previewFrame.srcdoc = buildSrcDoc(getRawTemplate(editor));
            }

            if (statusEl) {
                statusEl.innerHTML = `<span class="text-green-600"><i class="fa-solid fa-check-circle"></i> تم تحميل "${result.reportName || 'القالب'}"</span>`;
                setTimeout(() => { statusEl.innerHTML = ''; }, 3000);
            }

            console.log('[ReportDesigner] Loaded template:', result.reportName, 'ID:', reportID);

        } catch (err) {
            console.error('[ReportDesigner] Error loading template:', err);
            if (statusEl) {
                statusEl.innerHTML = `<span class="text-red-600"><i class="fa-solid fa-times-circle"></i> ${err.message}</span>`;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ORIENTATION TOGGLE
    // ─────────────────────────────────────────────────────────────────────────

    function updateOrientation(orientation) {
        currentOrientation = orientation;

        const container = document.getElementById('a4Container');
        const frame = document.getElementById('reportDesignerPreview');
        const label = document.getElementById('currentOrientation');
        const btnPortrait = document.getElementById('orientPortrait');
        const btnLandscape = document.getElementById('orientLandscape');

        if (container) {
            container.classList.remove('portrait', 'landscape');
            container.classList.add(orientation);
        }
        if (frame) {
            frame.classList.remove('portrait', 'landscape');
            frame.classList.add(orientation);
        }
        if (label) {
            label.textContent = orientation === 'landscape' ? 'Landscape' : 'Portrait';
        }
        if (btnPortrait && btnLandscape) {
            btnPortrait.classList.toggle('active', orientation === 'portrait');
            btnLandscape.classList.toggle('active', orientation === 'landscape');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SAMPLE DATA MODAL
    // ─────────────────────────────────────────────────────────────────────────

    function openSampleDataModal() {
        const modal = document.getElementById('sampleDataModal');
        const editor = document.getElementById('sampleDataEditor');
        if (modal && editor) {
            editor.value = JSON.stringify(sampleData, null, 2);
            modal.style.display = 'flex';
            modal.classList.remove('hidden');
        }
    }

    function closeSampleDataModal() {
        const modal = document.getElementById('sampleDataModal');
        if (modal) {
            modal.style.display = 'none';
            modal.classList.add('hidden');
        }
    }

    function saveSampleData() {
        const editor = document.getElementById('sampleDataEditor');
        if (!editor) return;

        try {
            const parsed = JSON.parse(editor.value);
            if (typeof parsed === 'object' && parsed !== null) {
                sampleData = parsed;
                closeSampleDataModal();
                // Trigger re-render
                const editorEl = document.getElementById('reportDesignerEditor');
                const previewFrame = document.getElementById('reportDesignerPreview');
                if (previewFrame) {
                    previewFrame.srcdoc = buildSrcDoc(getRawTemplate(editorEl));
                }
            }
        } catch (e) {
            alert('Invalid JSON format. Please check your syntax.');
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────

    function init() {
        const editor = document.getElementById('reportDesignerEditor');
        const previewFrame = document.getElementById('reportDesignerPreview');
        const copyBtn = document.getElementById('copyReportDesignBtn');
        const copyStatus = document.getElementById('copyReportDesignStatus');
        const validateBtn = document.getElementById('validateTemplateBtn');
        const boilerplateBtn = document.getElementById('insertBoilerplateBtn');
        const orientPortraitBtn = document.getElementById('orientPortrait');
        const orientLandscapeBtn = document.getElementById('orientLandscape');
        const editSampleDataBtn = document.getElementById('editSampleDataBtn');
        const cancelSampleDataBtn = document.getElementById('cancelSampleDataBtn');
        const saveSampleDataBtn = document.getElementById('saveSampleDataBtn');
        const loadSpFieldsBtn = document.getElementById('loadSpFieldsBtn');
        const spNameInput = document.getElementById('spNameInput');

        if (!editor || !previewFrame) return;

        // Initialize CodeMirror
        if (window.CodeMirror && !codeMirrorEditor) {
            codeMirrorEditor = window.CodeMirror.fromTextArea(editor, {
                mode: 'htmlmixed',
                lineNumbers: true,
                lineWrapping: true,
                theme: 'default'
            });
        }

        // Render placeholder panel
        renderPlaceholderPanel();

        // Live preview rendering
        let rafId = 0;
        const render = () => {
            rafId = 0;
            previewFrame.srcdoc = buildSrcDoc(getRawTemplate(editor));
        };

        const scheduleRender = () => {
            if (rafId) return;
            rafId = window.requestAnimationFrame(render);
        };

        if (codeMirrorEditor) {
            codeMirrorEditor.on('change', scheduleRender);
        } else {
            editor.addEventListener('input', scheduleRender);
        }

        // Orientation toggle
        if (orientPortraitBtn) {
            orientPortraitBtn.addEventListener('click', () => {
                updateOrientation('portrait');
                scheduleRender();
            });
        }
        if (orientLandscapeBtn) {
            orientLandscapeBtn.addEventListener('click', () => {
                updateOrientation('landscape');
                scheduleRender();
            });
        }

        // Boilerplate button
        if (boilerplateBtn) {
            boilerplateBtn.addEventListener('click', () => {
                if (confirm('This will replace the current content. Continue?')) {
                    setRawTemplate(a4Boilerplate);
                    scheduleRender();
                }
            });
        }

        // Preset buttons
        document.querySelectorAll('.preset-btn[data-preset]').forEach(btn => {
            btn.addEventListener('click', () => {
                const presetKey = btn.dataset.preset;
                if (presets[presetKey]) {
                    if (confirm('This will replace the current content. Continue?')) {
                        setRawTemplate(presets[presetKey]);
                        scheduleRender();
                    }
                }
            });
        });

        // Validate button
        if (validateBtn) {
            validateBtn.addEventListener('click', () => {
                const html = getRawTemplate(editor);
                const results = validateTemplate(html);
                renderValidationResults(results);
            });
        }

        // Copy ReportDesign button
        if (copyBtn) {
            copyBtn.addEventListener('click', async () => {
                try {
                    const raw = getRawTemplate(editor);

                    if (!navigator.clipboard || !navigator.clipboard.writeText) {
                        throw new Error('Clipboard API not available');
                    }

                    await navigator.clipboard.writeText(raw);

                    if (copyStatus) {
                        copyStatus.textContent = '✓ Copied!';
                        copyStatus.style.color = '#16a34a';
                        window.setTimeout(() => {
                            copyStatus.textContent = '';
                        }, 2000);
                    }
                } catch (err) {
                    console.error('Copy ReportDesign error:', err);
                    if (copyStatus) {
                        copyStatus.textContent = '✗ Copy failed';
                        copyStatus.style.color = '#dc2626';
                        window.setTimeout(() => {
                            copyStatus.textContent = '';
                        }, 2000);
                    }
                }
            });
        }

        // Sample data modal
        if (editSampleDataBtn) {
            editSampleDataBtn.addEventListener('click', openSampleDataModal);
        }
        if (cancelSampleDataBtn) {
            cancelSampleDataBtn.addEventListener('click', closeSampleDataModal);
        }
        if (saveSampleDataBtn) {
            saveSampleDataBtn.addEventListener('click', saveSampleData);
        }

        // Close modal on backdrop click
        const modal = document.getElementById('sampleDataModal');
        if (modal) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) closeSampleDataModal();
            });
        }

        // SP Field Loader
        if (loadSpFieldsBtn && spNameInput) {
            loadSpFieldsBtn.addEventListener('click', () => {
                loadSpColumns(spNameInput.value);
            });

            // Allow Enter key to trigger load
            spNameInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    loadSpColumns(spNameInput.value);
                }
            });
        }

        // Load database presets (async, non-blocking)
        loadDatabasePresets();

        // Initial render
        render();
    }

    // Run on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
