// wwwroot/js/sf-select.js
(function () {
    const register = () => {
        Alpine.data('sfSelect', (cfg) => ({
            name: cfg.name,
            placeholder: cfg.placeholder || 'اختر...',
            multiple: !!cfg.multiple,
            disabled: !!cfg.disabled,
            readonly: !!cfg.readonly,
            open: false,
            q: '',
            options: [],
            selected: [],
            panelStyle: '',
            listStyle: '',
            _repositionBound: null,

            init() {
                // تجهيز الخيارات
                this.options = (cfg.options || []).map(o => ({
                    value: String(o.Value ?? o.value ?? ''),
                    text: String(o.Text ?? o.text ?? ''),
                    disabled: !!(o.Disabled ?? o.disabled),
                    selected: !!(o.Selected ?? o.selected)
                }));

                // اختيار ابتدائي
                const initial = (cfg.initial || '').trim();
                if (initial) {
                    const vals = this.multiple ? initial.split(',') : [initial];
                    this.selected = this.options.filter(o => vals.includes(o.value));
                } else {
                    this.selected = this.options.filter(o => o.selected);
                }
                this.syncHidden();

                // نسخة مربوطة من reposition حتى لا نفقد this داخل event listeners
                this._repositionBound = this.reposition.bind(this);

                // تنظيف تلقائي عند تدمير المكوّن
                this.$el.addEventListener('alpine:destroy', () => this._detachListeners());
            },

            // فتح/إغلاق مع إدارة المستمعات
            togglePanel() {
                if (this.disabled || this.readonly) return;
                this.open = !this.open;
                if (this.open) {
                    this.$nextTick(() => {
                        this._repositionBound();
                        this._attachListeners();
                    });
                } else {
                    this._detachListeners();
                }
            },

            _attachListeners() {
                window.addEventListener('resize', this._repositionBound, { passive: true });
                // useCapture=true لالتقاط scroll من الحاويات الداخلية أيضًا
                window.addEventListener('scroll', this._repositionBound, true);
            },
            _detachListeners() {
                window.removeEventListener('resize', this._repositionBound, { passive: true });
                window.removeEventListener('scroll', this._repositionBound, true);
            },

            // حساب مكان/حجم اللوحة (position:fixed) + قلبها لأعلى عند الحاجة
            reposition() {
                const a = this.$refs.anchor;
                const p = this.$refs.panel;
                if (!a) return;

                const r = a.getBoundingClientRect();
                const vw = window.innerWidth || document.documentElement.clientWidth;
                const vh = window.innerHeight || document.documentElement.clientHeight;

                const width = r.width;
                const left = Math.min(Math.max(8, r.left), vw - width - 8); // إبقاء اللوحة داخل الشاشة

                // المساحات المتاحة
                const spaceBelow = vh - r.bottom - 8;
                const spaceAbove = r.top - 8;

                // ارتفاع القائمة المرغوب
                const desiredMax = 320; // px
                let maxH = Math.min(desiredMax, Math.max(180, spaceBelow));

                // الوضع الافتراضي: أسفل الزر
                let top = r.bottom + 8;

                // إذا المساحة أسفل قليلة وأعلى أوسع، اقلب لأعلى
                if (spaceBelow < 180 && spaceAbove > spaceBelow) {
                    maxH = Math.min(desiredMax, Math.max(180, spaceAbove));
                    const panelH = (p ? p.offsetHeight : Math.min(desiredMax, spaceAbove));
                    top = Math.max(8, r.top - panelH - 8);
                }

                this.panelStyle = `position:fixed;top:${top}px;left:${left}px;width:${width}px;`;
                this.listStyle = `max-height:${maxH}px;`;
            },

            filtered() {
                if (!this.q) return this.options;
                const q = this.q.toLowerCase();
                return this.options.filter(o => (o.text || '').toLowerCase().includes(q));
            },

            isSelected(opt) { return this.selected.some(s => s.value === opt.value); },

            toggle(opt) {
                if (opt.disabled || this.disabled || this.readonly) return;
                if (this.multiple) {
                    this.isSelected(opt)
                        ? this.selected = this.selected.filter(s => s.value !== opt.value)
                        : this.selected.push({ value: opt.value, text: opt.text });
                } else {
                    this.selected = [{ value: opt.value, text: opt.text }];
                    this.open = false;
                    this._detachListeners();
                }
                this.syncHidden();
                this.emitChange();
            },

            clear() {
                if (this.disabled || this.readonly) return;
                this.selected = [];
                this.syncHidden();
                this.emitChange();
            },

            displayText() {
                return this.selected.length ? this.selected.map(s => s.text).join('، ') : this.placeholder;
            },

            serialize() {
                return this.multiple
                    ? this.selected.map(s => s.value).join(',')
                    : (this.selected[0]?.value || '');
            },

            syncHidden() { if (this.$refs.hidden) this.$refs.hidden.value = this.serialize(); },

            emitChange() { this.$dispatch('change', { name: this.name, value: this.serialize() }); }
        }));
    };
    if (window.Alpine) register();
    else document.addEventListener('alpine:init', register);
})();
