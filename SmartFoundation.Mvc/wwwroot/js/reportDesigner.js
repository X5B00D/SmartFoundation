/*
 * Report Designer (design-only)
 * - Left: HTML/CSS editor
 * - Right: live A4 preview
 * - Replaces {{placeholders}} with SAMPLE data only
 */

(function () {
    let codeMirrorEditor = null;

    const sampleData = {
        fullName: 'John Doe',
        generalNo: '60014016',
        Department: 'IT'
    };

    function getRawTemplate(editorEl) {
        if (codeMirrorEditor) return codeMirrorEditor.getValue() || '';
        return editorEl?.value || '';
    }

    function applySampleData(html) {
        return html.replace(/{{\s*([A-Za-z0-9_]+)\s*}}/g, (match, key) => {
            if (Object.prototype.hasOwnProperty.call(sampleData, key)) {
                return String(sampleData[key]);
            }
            return match; // unknown placeholder: keep visible
        });
    }

    function buildSrcDoc(userHtml) {
        const replaced = applySampleData(userHtml);

        // Keep preview canvas strictly A4 with print-like margins.
        // User HTML is rendered as-is (supports inline <style> blocks).
        return `<!doctype html>
<html dir="ltr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html, body { margin: 0; padding: 0; }
        html { direction: ltr; }
        body { width: 210mm; height: 297mm; background: white; padding: 15mm; box-sizing: border-box; direction: ltr; }
  </style>
</head>
<body>
    <div id="__previewRoot">${replaced}</div>
    <script>
        // Preview-only normalization:
        // - Do NOT mutate the source template (editor/copy output)
        // - Some stored templates intentionally wrap content in hidden containers
        // - In preview, we unhide known wrappers *within this preview DOM only*
        (function () {
            try {
                var root = document.getElementById('__previewRoot');
                if (!root) return;

                // Known legacy wrapper ids
                var wrappers = root.querySelectorAll('#EmpCardTemplate, #empCardTemplate');
                wrappers.forEach(function (el) {
                    // Only override inline display:none; don't touch other styles.
                    var display = '';
                    if (el.style && el.style.display) display = String(el.style.display).toLowerCase().trim();
                    if (display === 'none') {
                        el.style.display = '';
                    }

                    // If it is still hidden due to inline style attribute, remove display only.
                    // (Covers cases like style="display:none; ...")
                    var styleAttr = el.getAttribute('style');
                    if (styleAttr && /display\s*:\s*none\s*;?/i.test(styleAttr)) {
                        var nextStyle = styleAttr
                            .replace(/display\s*:\s*none\s*;?/ig, '')
                            .replace(/;;+/g, ';')
                            .trim();
                        if (nextStyle) el.setAttribute('style', nextStyle);
                        else el.removeAttribute('style');
                    }
                });
            } catch (e) {
                // Swallow errors: preview must never break the page.
            }
        })();
    </script>
</body>
</html>`;
    }

    function init() {
        const editor = document.getElementById('reportDesignerEditor');
        const previewFrame = document.getElementById('reportDesignerPreview');
        const copyBtn = document.getElementById('copyReportDesignBtn');
        const copyStatus = document.getElementById('copyReportDesignStatus');
        if (!editor || !previewFrame) return;

        // Syntax highlighting (CodeMirror) - keep editing raw HTML/CSS
        if (window.CodeMirror && !codeMirrorEditor) {
            codeMirrorEditor = window.CodeMirror.fromTextArea(editor, {
                mode: 'htmlmixed',
                lineNumbers: true,
                lineWrapping: true
            });
        }

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

        // Copy ReportDesign (raw template only: includes <style> + placeholders, no sample replacement)
        if (copyBtn) {
            copyBtn.addEventListener('click', async () => {
                try {
                    const raw = getRawTemplate(editor);

                    if (!navigator.clipboard || !navigator.clipboard.writeText) {
                        throw new Error('Clipboard API not available');
                    }

                    await navigator.clipboard.writeText(raw);

                    if (copyStatus) {
                        copyStatus.textContent = 'Copied!';
                        window.setTimeout(() => {
                            copyStatus.textContent = '';
                        }, 1200);
                    }
                } catch (err) {
                    console.error('Copy ReportDesign error:', err);
                    if (copyStatus) {
                        copyStatus.textContent = 'Copy failed';
                        window.setTimeout(() => {
                            copyStatus.textContent = '';
                        }, 1500);
                    } else {
                        alert('Copy failed');
                    }
                }
            });
        }

        // Initial render
        render();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
