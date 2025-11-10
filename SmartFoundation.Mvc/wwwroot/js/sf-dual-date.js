/**
 * SmartFoundation - Dual Date Picker (Gregorian + Hijri)
 * 
 * Provides bidirectional synchronization between Gregorian and Hijri calendars.
 * Requires: Flowbite Datepicker, moment.js, moment-hijri.js
 * 
 * Usage:
 * 
 * HTML:
 * <div class="dual-date-picker" data-dual-date>
 *   <input id="date-g" data-gregorian />
 *   <input id="date-h" data-hijri />
 * </div>
 * 
 * JavaScript:
 * const dualDate = new DualDatePicker('#date-g', '#date-h', {
 *   language: 'ar',
 *   orientation: 'bottom right',
 *   todayBtn: true,
 *   clearBtn: true
 * });
 * 
 * API:
 * dualDate.setGregorian(new Date()) - Set Gregorian date
 * dualDate.setHijri('1446/09/01')   - Set Hijri date
 * dualDate.getGregorian()           - Get Gregorian value
 * dualDate.getHijri()               - Get Hijri value
 */

class DualDatePicker {
    constructor(gregorianSelector, hijriSelector, options = {}) {
        this.gInput = document.querySelector(gregorianSelector);
        this.hInput = document.querySelector(hijriSelector);

        if (!this.gInput || !this.hInput) {
            console.error('DualDatePicker: Input elements not found');
            return;
        }

        // Default options for Flowbite Datepicker
        this.options = {
            autohide: true,
            format: 'yyyy-mm-dd',
            language: 'ar',
            orientation: 'bottom right',
            todayBtn: true,
            clearBtn: true,
            ...options
        };

        this.init();
    }

    init() {
        // Initialize Flowbite Datepicker for Gregorian input
        this.gPicker = new Datepicker(this.gInput, this.options);

        // Set up event listeners
        this.setupEventListeners();

        // Initial sync
        this.initialSync();
    }

    /**
     * Check if date is valid
     */
    isValidDate(d) {
        return d instanceof Date && !isNaN(d.valueOf());
    }

    /**
     * Sync Hijri from Gregorian date
     */
    syncFromGregorian(dateObj) {
        if (!this.isValidDate(dateObj)) return;

        // Convert to Hijri using moment-hijri
        const hijriDate = moment(dateObj).format('iYYYY/iMM/iDD');
        this.hInput.value = hijriDate;

        // Trigger custom event
        this.dispatchSyncEvent('gregorian', dateObj, hijriDate);
    }

    /**
     * Sync Gregorian from Hijri date string
     */
    syncFromHijri(hijriStr) {
        // Parse Hijri date strictly
        const m = moment(hijriStr, 'iYYYY/iMM/iDD', true);

        if (!m.isValid()) return;

        const gregorianDate = m.toDate();

        // Update Flowbite picker
        this.gPicker.setDate(gregorianDate);

        // Ensure input value is synced
        const formattedDate = moment(gregorianDate).format('YYYY-MM-DD');
        if (this.gInput.value !== formattedDate) {
            this.gInput.value = formattedDate;
        }

        // Trigger custom event
        this.dispatchSyncEvent('hijri', gregorianDate, hijriStr);
    }

    /**
     * Set up all event listeners
     */
    setupEventListeners() {
        // Listen to Flowbite's changeDate event
        this.gInput.addEventListener('changeDate', (e) => {
            const date = e.detail?.date ?? new Date(this.gInput.value);
            this.syncFromGregorian(date);
        });

        // Fallback: plain change event
        this.gInput.addEventListener('change', () => {
            const date = new Date(this.gInput.value);
            this.syncFromGregorian(date);
        });

        // Hijri input events
        this.hInput.addEventListener('blur', () => {
            this.syncFromHijri(this.hInput.value.trim());
        });

        this.hInput.addEventListener('change', () => {
            this.syncFromHijri(this.hInput.value.trim());
        });

        // Optional: live sync when full pattern is typed
        this.hInput.addEventListener('input', () => {
            const value = this.hInput.value.trim();
            // Match pattern: YYYY/MM/DD or YYYY/M/D
            if (/^\d{4}\/\d{1,2}\/\d{1,2}$/.test(value)) {
                this.syncFromHijri(value);
            }
        });
    }

    /**
     * Initial synchronization based on existing values
     */
    initialSync() {
        const gValue = this.gInput.value;
        const hValue = this.hInput.value;

        if (!gValue && !hValue) {
            // Both empty - set to today
            const today = new Date();
            this.gPicker.setDate(today);
            this.syncFromGregorian(today);
        } else if (gValue) {
            // Gregorian has value - sync to Hijri
            const date = new Date(gValue);
            if (this.isValidDate(date)) {
                this.syncFromGregorian(date);
            }
        } else if (hValue) {
            // Hijri has value - sync to Gregorian
            this.syncFromHijri(hValue);
        }
    }

    /**
     * Dispatch custom sync event for external listeners
     */
    dispatchSyncEvent(source, gregorianDate, hijriStr) {
        const event = new CustomEvent('dualdatesync', {
            detail: {
                source: source,
                gregorian: gregorianDate,
                hijri: hijriStr,
                gregorianFormatted: moment(gregorianDate).format('YYYY-MM-DD'),
                hijriFormatted: hijriStr
            },
            bubbles: true
        });

        this.gInput.dispatchEvent(event);
    }

    // Public API methods

    /**
     * Set Gregorian date programmatically
     * @param {Date} date - JavaScript Date object
     */
    setGregorian(date) {
        if (!this.isValidDate(date)) {
            console.error('DualDatePicker: Invalid date provided to setGregorian');
            return;
        }
        this.gPicker.setDate(date);
        this.syncFromGregorian(date);
    }

    /**
     * Set Hijri date programmatically
     * @param {string} hijriStr - Hijri date string in format: iYYYY/iMM/iDD
     */
    setHijri(hijriStr) {
        this.syncFromHijri(hijriStr);
    }

    /**
     * Get current Gregorian value
     * @returns {string} Gregorian date in YYYY-MM-DD format
     */
    getGregorian() {
        return this.gInput.value;
    }

    /**
     * Get current Hijri value
     * @returns {string} Hijri date in iYYYY/iMM/iDD format
     */
    getHijri() {
        return this.hInput.value;
    }

    /**
     * Get both values as object
     * @returns {object} Object with gregorian and hijri properties
     */
    getValues() {
        return {
            gregorian: this.getGregorian(),
            hijri: this.getHijri()
        };
    }

    /**
     * Clear both inputs
     */
    clear() {
        this.gPicker.setDate({ clear: true });
        this.hInput.value = '';

        this.dispatchSyncEvent('clear', null, '');
    }

    /**
     * Destroy the instance and remove event listeners
     */
    destroy() {
        if (this.gPicker && this.gPicker.destroy) {
            this.gPicker.destroy();
        }
        // Note: Event listeners are automatically cleaned up when elements are removed
    }
}

// Auto-initialize all dual date pickers on page load
document.addEventListener('DOMContentLoaded', () => {
    const dualDateContainers = document.querySelectorAll('[data-dual-date]');

    dualDateContainers.forEach(container => {
        const gInput = container.querySelector('[data-gregorian]');
        const hInput = container.querySelector('[data-hijri]');

        if (gInput && hInput) {
            const instance = new DualDatePicker(
                `#${gInput.id}`,
                `#${hInput.id}`
            );

            // Store instance on container for external access
            container.dualDatePicker = instance;
        }
    });
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DualDatePicker;
}
