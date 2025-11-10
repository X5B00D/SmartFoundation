# Dual Date Picker - Quick Reference

Fast lookup guide for common date picker configurations and patterns.

---

## Quick Setup Checklist

```
✅ jQuery 3.7.1+ loaded
✅ Flowbite 2.5.2+ loaded
✅ sf-date.js loaded
✅ moment-hijri.js loaded (optional, for extended Hijri support)
✅ FieldConfig.Type = "date"
✅ data-role="sf-date" attribute on input
```

---

## Common Configurations

### 1. Simple Gregorian Date

```csharp
new FieldConfig {
    Name = "EventDate",
    Type = "date",
    Calendar = "gregorian",
    MinDateStr = "2024-01-01",
    MaxDateStr = "2024-12-31"
}
```

---

### 2. Dual Calendar (Gregorian + Hijri)

```csharp
new FieldConfig {
    Name = "BirthDate",
    Type = "date",
    Calendar = "both",
    MirrorName = "BirthDateHijri",
    MirrorCalendar = "hijri",
    ShowDayName = true,
    MinDateStr = "1950-01-01"
}
```

---

### 3. Date Range with Days Counter

```csharp
// Start Date
new FieldConfig {
    Name = "StartDate",
    Type = "date",
    RangeGroup = "vacation",
    RangeRole = "start",
    DaysTarget = "vacation__days"
},

// End Date
new FieldConfig {
    Name = "EndDate",
    Type = "date",
    RangeGroup = "vacation",
    RangeRole = "end",
    DaysTarget = "vacation__days"
}
```

```html
<!-- Days Counter -->
<div id="vacation__days">
    <span data-days-value>—</span> أيام
    <span data-days-error class="hidden"></span>
</div>
```

---

### 4. Hijri Only

```csharp
new FieldConfig {
    Name = "IslamicDate",
    Type = "date",
    Calendar = "hijri",
    DateNumerals = "arab",  // Arabic numerals ٠-٩
    ShowDayName = true
}
```

---

### 5. Auto-Select Today

```csharp
new FieldConfig {
    Name = "RegistrationDate",
    Type = "date",
    DefaultToday = true,
    Calendar = "gregorian"
}
```

---

## Configuration Properties

| Property | Values | Default | Description |
|----------|--------|---------|-------------|
| `Type` | `"date"` | - | **Required** to enable datepicker |
| `Calendar` | `"gregorian"`, `"hijri"`, `"both"` | `"gregorian"` | Calendar mode |
| `MirrorName` | Field name | `null` | Paired field for sync |
| `ShowDayName` | `true`, `false` | `true` | Show weekday name |
| `MinDateStr` | `"YYYY-MM-DD"` | `null` | Min selectable date |
| `MaxDateStr` | `"YYYY-MM-DD"` | `null` | Max selectable date |
| `DefaultToday` | `true`, `false` | `false` | Auto-select today |
| `DateNumerals` | `"latn"`, `"arab"` | `"latn"` | Numeral system |
| `RangeGroup` | String | `null` | Group for range pairs |
| `RangeRole` | `"start"`, `"end"` | `null` | Range position |
| `DaysTarget` | Element ID | `null` | Days counter element |

---

## Required HTML Structure

### Basic Input

```html
<input 
    id="FieldName"
    name="FieldName"
    type="text"
    data-role="sf-date"
    data-calendar="gregorian"
    placeholder="YYYY-MM-DD"
/>
```

---

### With Info Box

```html
<input id="BirthDate" data-role="sf-date" data-calendar="gregorian" />

<div id="BirthDate__info">
    <span data-greg-full>—</span>
</div>
```

---

### Dual Calendar

```html
<input 
    id="BirthDate"
    data-role="sf-date"
    data-calendar="both"
    data-mirror-name="BirthDateHijri"
/>

<input type="hidden" id="BirthDate__mirror" name="BirthDateHijri" />

<div id="BirthDate__info">
    <div><span data-greg-full>—</span></div>
    <div><span data-hijri-full>—</span></div>
</div>
```

---

### Date Range

```html
<!-- Start -->
<input 
    id="StartDate"
    data-role="sf-date"
    data-range-group="myRange"
    data-range-role="start"
    data-days-target="myRange__days"
/>

<!-- End -->
<input 
    id="EndDate"
    data-role="sf-date"
    data-range-group="myRange"
    data-range-role="end"
    data-days-target="myRange__days"
/>

<!-- Counter -->
<div id="myRange__days">
    <span data-days-value>—</span> أيام
    <span data-days-error class="hidden"></span>
</div>
```

---

## Data Attributes Reference

```html
<input 
    data-role="sf-date"                      <!-- Required -->
    data-calendar="gregorian|hijri|both"     <!-- Calendar mode -->
    data-date-format="yyyy-mm-dd"            <!-- Format -->
    data-mirror-name="FieldName"             <!-- Paired field -->
    data-mirror-calendar="hijri|gregorian"   <!-- Mirror type -->
    data-display-lang="ar|en"                <!-- Language -->
    data-numerals="latn|arab"                <!-- Numerals -->
    data-show-day-name="true|false"          <!-- Weekday -->
    data-default-today="true|false"          <!-- Auto today -->
    data-min-date="YYYY-MM-DD"               <!-- Min date -->
    data-max-date="YYYY-MM-DD"               <!-- Max date -->
    data-range-group="groupName"             <!-- Range group -->
    data-range-role="start|end"              <!-- Range role -->
    data-days-target="elementId"             <!-- Days target -->
/>
```

---

## Flowbite Options

Default Flowbite options (can't be changed without modifying sf-date.js):

```javascript
{
    format: 'yyyy-mm-dd',
    autohide: true,
    orientation: 'bottom',
    buttons: false,
    autoSelectToday: 0,
    todayHighlight: false,
    minDate: cfg.minDate,  // From FieldConfig
    maxDate: cfg.maxDate   // From FieldConfig
}
```

---

## Event Handling

### changeDate Event (Correct)

```javascript
input.addEventListener('changeDate', (e) => {
    console.log('Date selected:', input.value);
    // Fires immediately when user selects from calendar
});
```

### change Event (Wrong for instant updates)

```javascript
input.addEventListener('change', (e) => {
    console.log('Input changed:', input.value);
    // Only fires on blur (when input loses focus)
});
```

---

## JavaScript API

### Access Datepicker Instance

```javascript
const input = document.getElementById('BirthDate');
const datepicker = input._flowbiteDatepicker;

// Methods
datepicker.show();           // Open calendar
datepicker.hide();           // Close calendar
datepicker.setDate('2024-05-15');  // Set date programmatically
datepicker.getDate();        // Get selected date
```

### Get Underlying vanillajs-datepicker

```javascript
const vanillaInstance = datepicker.getDatepickerInstance();
```

---

## Common Patterns

### 1. Birthday Field (Past Dates Only)

```csharp
new FieldConfig {
    Name = "BirthDate",
    Type = "date",
    Calendar = "both",
    MaxDateStr = DateTime.Today.ToString("yyyy-MM-dd"),
    MinDateStr = "1900-01-01",
    ShowDayName = true
}
```

---

### 2. Future Event Date

```csharp
new FieldConfig {
    Name = "EventDate",
    Type = "date",
    MinDateStr = DateTime.Today.ToString("yyyy-MM-dd"),
    MaxDateStr = DateTime.Today.AddYears(2).ToString("yyyy-MM-dd")
}
```

---

### 3. Vacation Request (7-30 days)

```csharp
new FieldConfig {
    Name = "VacationStart",
    Type = "date",
    RangeGroup = "vacation",
    RangeRole = "start",
    MinDateStr = DateTime.Today.AddDays(7).ToString("yyyy-MM-dd")
},
new FieldConfig {
    Name = "VacationEnd",
    Type = "date",
    RangeGroup = "vacation",
    RangeRole = "end",
    MinDateStr = DateTime.Today.AddDays(7).ToString("yyyy-MM-dd"),
    MaxDateStr = DateTime.Today.AddDays(30).ToString("yyyy-MM-dd")
}
```

---

### 4. Contract Dates (1 year minimum)

```csharp
new FieldConfig {
    Name = "ContractStart",
    Type = "date",
    RangeGroup = "contract",
    RangeRole = "start"
},
new FieldConfig {
    Name = "ContractEnd",
    Type = "date",
    RangeGroup = "contract",
    RangeRole = "end",
    HelpText = "يجب أن تكون سنة على الأقل من تاريخ البداية"
}
```

Validate server-side: `EndDate >= StartDate.AddYears(1)`

---

## Troubleshooting Quick Fixes

### Calendar Not Showing

```html
<!-- Add to _Layout.cshtml if missing -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/flowbite@2.5.2/dist/flowbite.min.js"></script>
```

Hard refresh: `Ctrl+Shift+R`

---

### Hijri Not Converting

```csharp
// Must set Calendar to "both" or "hijri"
Calendar = "both",
```

```html
<!-- Info box must have data-hijri-full -->
<div id="BirthDate__info">
    <span data-hijri-full>—</span>
</div>
```

---

### Updates Only on Blur

Check sf-date.js uses `changeDate` event (line 293):

```javascript
// ✅ Should be this
input.addEventListener('changeDate', (e) => { ... });

// ❌ Not this
input.addEventListener('change', () => { ... });
```

---

### Mirror Not Syncing

```csharp
// Names must match exactly
Name = "BirthDate",
MirrorName = "BirthDateHijri",
```

```html
<!-- ID must be exact -->
<input id="BirthDate__mirror" name="BirthDateHijri" />
```

---

### Alpine.js Components

```javascript
// sf-date.js should have this (line 313)
document.addEventListener("alpine:initialized", boot);
```

Hard refresh after changes.

---

## Date Format Examples

### Input Format

Always use ISO format: `YYYY-MM-DD`

```
✅ Correct: "2024-05-15"
❌ Wrong: "05/15/2024"
❌ Wrong: "15-05-2024"
❌ Wrong: "2024-5-15"
```

---

### Display Format (Info Box)

Automatically formatted based on language:

**Arabic (ar)**:

- Gregorian: `السبت, 15 يناير, 2000`
- Hijri: `السبت, 8 شوال, 1420`

**English (en)**:

- Gregorian: `Saturday, January 15, 2000`
- Hijri: `Saturday, Shawwal 8, 1420`

---

## Validation Rules

### Client-Side (Automatic)

- Min/max date enforcement
- ISO format validation
- Date range order (start < end)
- Auto-clamping to constraints

### Server-Side (Required)

```csharp
// Always validate on server
if (!DateTime.TryParseExact(birthDate, "yyyy-MM-dd", 
    CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime date))
{
    ModelState.AddModelError("BirthDate", "Invalid date format");
}

if (date < minDate || date > maxDate)
{
    ModelState.AddModelError("BirthDate", "Date out of range");
}
```

---

## Performance Tips

1. **Lazy Load**: Init datepicker on first focus if many inputs
2. **Shared Instance**: One Flowbite library for all datepickers
3. **Debounce**: Use for real-time validation in range inputs
4. **Async Validation**: Move complex checks to server

---

## Browser Support

| Feature | Chrome 24+ | Firefox 29+ | Safari 10+ | Edge 79+ |
|---------|------------|-------------|------------|----------|
| Datepicker | ✅ | ✅ | ✅ | ✅ |
| Hijri Conversion | ✅ | ✅ | ✅ | ✅ |
| Arabic Numerals | ✅ | ✅ | ✅ | ✅ |
| RTL Layout | ✅ | ✅ | ✅ | ✅ |

IE11: ❌ Not supported

---

## Testing Checklist

```
✅ Calendar opens on click
✅ Date selection updates input
✅ Info box updates instantly
✅ Hijri conversion accurate
✅ Mirror field syncs
✅ Min/max dates enforced
✅ Range validation works
✅ Days counter calculates
✅ Keyboard input formats
✅ Works with Alpine.js
✅ RTL layout correct
✅ Dark mode compatible
```

---

## Migration from Old Implementation

### Before (Wrong Library)

```javascript
// ❌ OLD: bootstrap-datepicker
$('#BirthDate').datepicker({
    format: 'yyyy-mm-dd'
});
```

### After (Correct Library)

```csharp
// ✅ NEW: FieldConfig in controller
new FieldConfig {
    Name = "BirthDate",
    Type = "date",
    Calendar = "gregorian"
}
```

No JavaScript required - automatic initialization!

---

## Resources

- [Full Documentation](dual-date-picker.md)
- [Flowbite Docs](https://flowbite.com/docs/plugins/datepicker/)
- [SmartForm Guide](../SmartFoundation.UI/README.md)
- [GitHub Copilot Instructions](../.github/copilot-instructions.md)

---

## Common Questions

**Q: Can I use DD/MM/YYYY format?**  
A: Not currently. Input must be YYYY-MM-DD (ISO format). Display format is automatic based on language.

**Q: How accurate is Hijri conversion?**  
A: Generally ±0-1 day depending on browser and Islamic calendar conventions.

**Q: Can I disable keyboard input?**  
A: Not recommended. Keyboard input with auto-formatting provides better UX.

**Q: Does it work with Blazor/React?**  
A: Designed for ASP.NET MVC with Alpine.js. May need adaptation for other frameworks.

**Q: Can I style the calendar popup?**  
A: Limited. Calendar uses Flowbite's default styles. Customize via Flowbite themes.

**Q: Does it support time selection?**  
A: Not yet. Feature planned for future release.

---

**Quick Start**: Copy a config from above → Test → Customize

**Last Updated**: November 10, 2025  
**Version**: 1.0
