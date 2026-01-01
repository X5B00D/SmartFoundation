/**
 * Print dynamic report using DB template + data SP
 * Team-friendly single entry point
 */
async function printDynamicReport({
    reportID,
    dataSp,
    params = {},
    printOptions = {}
}) {
    try {
        const res = await fetch('/ReportGen/Print', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                reportID,
                dataSp,
                parameters: params
            })
        });

        const payload = JSON.parse((await res.json()).d);
        if (payload?.error) {
            alert(payload.error);
            return;
        }

        const report = payload?.report;
        if (!report || !report.reportDesign) {
            alert('محتوى التقرير فارغ');
            return;
        }

        let html = report.reportDesign;
        const data = payload?.data || {};

        // 🔁 Inject {{placeholders}}
        if (data && typeof data === 'object') {
            Object.keys(data).forEach(key => {
                html = html.replace(
                    new RegExp(`{{${key}}}`, 'gi'),
                    data[key] ?? ''
                );
            });
        }

        // 🧹 Normalize hidden templates
        html = html.replace(/display\s*:\s*none;?/gi, '');

        const $container = $('<div>').html(html).appendTo('body').show();

        $container.printThis({
            pageTitle: report.reportNam_A || 'Report',
            printDelay: 800,
            afterPrint: () => $container.remove(),
            ...printOptions
        });

    } catch (err) {
        console.error('printDynamicReport error:', err);
        alert('Error while printing report');
    }
}
