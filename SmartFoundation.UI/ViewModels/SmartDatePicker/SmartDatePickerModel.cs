using System;

namespace SmartFoundation.UI.ViewModels.SmartDatePicker
{
    public class DatepickerViewModel
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public string Value { get; set; } = string.Empty;
        public string Col { get; set; } = "12";
        private string _format = "yyyy-mm-dd";
        public string Format
        {
            get => _format;
            set => _format = string.IsNullOrWhiteSpace(value)
                ? "yyyy-mm-dd"
                : value.ToLower();
        }
        public string Orientation { get; set; } = "auto";
        public bool ShowTodayButton { get; set; }
        public bool ShowClearButton { get; set; }
        public bool IsReadOnly { get; set; }
        public string HelpText { get; set; } = string.Empty;
        public bool TodayHighlight { get; set; } = true;
        public string PlaceHolder { get; set; } = string.Empty;
        public string Culture { get; set; } = "ar-SA";
        public bool IsRightToLeft => true;
        public bool Hijri { get; set; } = false;
        public bool ShowDay { get; set; } = false;

        public string GetEffectiveFormat() => Format;

        public DatepickerViewModel()
        {
            _format = "yyyy-mm-dd";
            PlaceHolder = _format;
            Culture = "ar-SA";
            Orientation = "auto";
        }
    }
}

