﻿/** @type {import('tailwindcss').Config} */
const plugin = require('tailwindcss/plugin');

module.exports = {
    darkMode: 'class',

    content: [
        './Views/**/*.{cshtml,js,html}',
        './Pages/**/*.{cshtml,js,html}',
        './wwwroot/**/*.{html,js}',
        '../SmartFoundation.UI/Views/**/*.{cshtml,js,html}',
        '../SmartFoundation.UI/**/*.{cshtml,js,html}',
        './src/**/*.{js,ts}',
        './tools/**/*.{js,ts}',
        './node_modules/flowbite/**/*.js',
    ],

    safelist: [

        'animate-fade-in',

        'bg-gradient-to-b', 'border', 'rounded-md', 'transition', 'text-sm', 'font-semibold',
        'h-10', 'px-5', 'md:px-6', 'gap-2', 'gap-2.5', 'gap-3', 'active:shadow-inner',
        'from-emerald-50', 'via-emerald-50', 'to-emerald-200',
        'hover:from-emerald-100', 'hover:via-emerald-100', 'hover:to-emerald-100',
        'border-emerald-200', 'text-emerald-900',

        'from-blue-50', 'via-blue-50', 'to-blue-200',
        'hover:from-blue-100', 'hover:via-blue-100', 'hover:to-blue-100',
        'border-blue-200', 'text-blue-900',

        'from-rose-50', 'via-rose-50', 'to-rose-200',
        'hover:from-rose-100', 'hover:via-rose-100', 'hover:to-rose-100',
        'border-rose-200', 'text-rose-900',

        'from-amber-50', 'via-amber-50', 'to-amber-200',
        'hover:from-amber-100', 'hover:via-amber-100', 'hover:to-amber-100',
        'border-amber-200', 'text-amber-900',

        'from-gray-50', 'via-gray-50', 'to-gray-200',
        'hover:from-gray-100', 'hover:via-gray-100', 'hover:to-gray-100',
        'border-gray-200', 'text-gray-900',

        'from-slate-50', 'via-slate-50', 'to-slate-200',
        'hover:from-slate-100', 'hover:via-slate-100', 'hover:to-slate-100',
        'border-slate-200', 'text-slate-900',

        'group-active:[transform:translate3d(0,1px,0)]',
        'fa', 'fa-save', 'fa-eraser', 'text-[14px]',
    ],

    theme: {
        container: {
            center: true,
            padding: {
                DEFAULT: '1rem',
                sm: '1rem',
                md: '2rem',
                lg: '2rem',
                xl: '3rem',
                '2xl': '4rem',
            },
        },
        extend: {
            // شاشة إضافية
            screens: { xs: '475px' },

            // خط عربي افتراضي (مع fallback)
            fontFamily: {
                arabic: ['"Tajawal"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
            },

            // ألوان قابلة للتخصيص
            colors: {
                primary: {
                    DEFAULT: 'rgb(var(--color-primary, 16 185 129) / <alpha-value>)', // Emerald 500
                },
                secondary: {
                    DEFAULT: 'rgb(var(--color-secondary, 59 130 246) / <alpha-value>)', // Blue 500
                },
                muted: {
                    DEFAULT: 'rgb(var(--color-muted, 107 114 128) / <alpha-value>)', // Gray 500
                },
            },

            borderRadius: {
                '2xl': '1rem',
            },
            boxShadow: {
                soft: '0 1px 2px 0 rgb(0 0 0 / 0.04), 0 1px 3px 0 rgb(0 0 0 / 0.10)',
            },

            // الحركات (Animations)
            keyframes: {
                'fade-in': {
                    '0%': { opacity: '0' },
                    '100%': { opacity: '1' },
                },
                'scale-in': {
                    '0%': { transform: 'scale(.98)' },
                    '100%': { transform: 'scale(1)' },
                },
                'slide-up': {
                    '0%': { transform: 'translateY(6px)', opacity: 0 },
                    '100%': { transform: 'translateY(0)', opacity: 1 },
                },
            },
            animation: {
                'fade-in': 'fade-in .2s ease-out both',
                'scale-in': 'scale-in .15s ease-out both',
                'slide-up': 'slide-up .2s ease-out both',
            },
        },
    },

    plugins: [
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography'),
        require('flowbite/plugin'),

        plugin(function ({ addVariant, addUtilities, theme }) {
            // دعم RTL/LTR
            addVariant('rtl', ':is([dir="rtl"] &)');
            addVariant('ltr', ':is([dir="ltr"] &)');
            addVariant('supports-backdrop', '@supports (backdrop-filter: blur(2px)) &');

            // كلاس card جاهز
            addUtilities(
                {
                    '.card': {
                        borderRadius: theme('borderRadius.2xl'),
                        backgroundColor: '#fff',
                        boxShadow: theme('boxShadow.soft'),
                        padding: '1rem',
                    },
                    '.card-lg': {
                        borderRadius: theme('borderRadius.2xl'),
                        backgroundColor: '#fff',
                        boxShadow: theme('boxShadow.soft'),
                        padding: '1.5rem',
                    },
                },
                { variants: ['responsive'] }
            );
        }),
    ],
};