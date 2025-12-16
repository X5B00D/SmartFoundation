// Global form field visibility handler
(function() {
    'use strict';
    
    document.addEventListener('DOMContentLoaded', function() {
        // Hide all fields with 'hidden-field' or 'search-field' class on page load
        var hiddenSelectors = ['.hidden-field', '.search-field'];
        
        hiddenSelectors.forEach(function(selector) {
            document.querySelectorAll(selector).forEach(function(field) {
                var container = field.closest('.form-group');
                if (container) {
                    container.style.display = 'none';
                }
            });
        });
    });
})();