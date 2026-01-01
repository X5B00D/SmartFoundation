/**
 * Print report from database - Global reusable function
 * @param {number} reportId - Report ID to print
 * @param {string} webMethodUrl - Optional: Custom WebMethod URL (default: 'GetReportData')
 * @param {object} options - Optional: Custom printThis options
 * 
 * @example
 * // Basic usage on current page
 * printReport(1);
 * 
 * @example
 * // Different WebMethod on current page
 * printReport(8, 'getVacationbyUserId');
 * 
 * @example
 * // Different page and method
 * printReport(5, 'AnotherPage.aspx/GetReport');
 * 
 * @example
 * // With custom print options
 * printReport(3, 'GetReportData', { debug: true, importCSS: true });
 */
/**
 * Print report from database with dynamic data injection
 * @param {number} reportId - Report ID to print
 * @param {object} dataToInject - Data to inject into report template (e.g., {fullName: 'Ahmad', generalNo: '123'})
 * @param {string} webMethodUrl - Optional: Custom WebMethod URL (default: 'GetReportData')
 * @param {object} options - Optional: Custom printThis options
 */
async function printReport(reportId, dataToInject = {}, webMethodUrl = 'GetReportData', options = {}) {
    try {
        // Ensure webMethodUrl is a string before using includes
        let url = '';
        if (typeof webMethodUrl === 'string' && webMethodUrl.includes('/')) {
            url = webMethodUrl;
        } else {
            url = `${window.location.pathname.split('/').pop()}/${webMethodUrl || 'GetReportData'}`;
        }
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ reportId })
        });

        if (!response.ok) throw new Error(`HTTP ${response.status}`);

        const data = JSON.parse((await response.json()).d);
        if (!data?.length) return alert('لم يتم العثور على بيانات للتقرير');

        const report = JSON.parse(data[0].JsonResult);
        console.log('Fetched report object:', report);
        if (!report?.reportDesign) return alert('محتوى التقرير فارغ');

        // If dataToInject is a function, call it to get the data (for async SP calls)
        let injectData = dataToInject;
        if (typeof dataToInject === 'function') {
            injectData = await dataToInject();
        }

        // Replace placeholders in reportDesign with actual data
        let htmlContent = report.reportDesign;
        console.log('Report design before injection:', htmlContent);
        if (injectData && typeof injectData === 'object') {
            Object.keys(injectData).forEach(key => {
                const placeholder = new RegExp(`{{${key}}}`, 'gi');
                htmlContent = htmlContent.replace(placeholder, injectData[key] || '');
            });
        }

        // Templates stored with a hidden wrapper (e.g. id="empCardTemplate" style="display: none;")
        // remove hiding so the content is visible in the print preview
        try {
            // remove id="empCardTemplate"
            htmlContent = htmlContent.replace(/\sid=("|')?empCardTemplate\1?/i, '');
            // remove any style attribute that only contains display:none (keep other styles)
            htmlContent = htmlContent.replace(/style=("|')\s*display\s*:\s*none;?\1/gi, '');
            // remove inline display:none occurrences
            htmlContent = htmlContent.replace(/display\s*:\s*none;?/gi, '');
        } catch (e) {
            console.warn('Could not normalize template hiding attributes', e);
        }

        const $container = $('<div>').html(htmlContent).appendTo('body');
        // Ensure any inline 'display:none' left in template is removed so content is visible
        try {
            $container.find('[style]').each(function () {
                const s = $(this).attr('style');
                if (s && /display\s*:\s*none/i.test(s)) {
                    const newStyle = s.replace(/display\s*:\s*none;?/ig, '');
                    $(this).attr('style', newStyle);
                }
            });
            $container.show();
        } catch (e) {
            console.warn('Error normalizing inline styles', e);
        }
        console.log('Final htmlContent appended to DOM length:', $container.html().length);
        console.log('Preview snippet:', $container.html().substring(0, 800));

        $container.printThis({
            importCSS: false,
            importStyle: false,
            printContainer: true,
            pageTitle: report.reportNam_A || 'Report',
            removeInline: false,
            printDelay: 1500,
            afterPrint: () => $container.remove(),
            ...options
        });
    } catch (error) {
        console.error('Print error:', error);
        alert('حدث خطأ أثناء طباعة التقرير');
    }
}
