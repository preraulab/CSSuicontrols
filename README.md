# CSSuicontrols

CSS-styled HTML-backed UI controls for MATLAB `uifigure` apps. Each component is a `uihtml` element whose content is a self-contained HTML+CSS+JS document — this gets you modern, themeable, animated controls that look native-web without shelling out to JavaScript yourself.

All components share a common base class (`CSSBase`), a consistent name-value-pair constructor surface, live property patching (no page reload on property assignment), and a small set of reusable styling presets.

## Components

| Class | What it is |
|---|---|
| `CSSuiButton` | Push button with optional SVG icon, configurable icon position, shape (rectangle/square/circle), and text-hide-below-width |
| `CSSuiLabel` | Static text label with selectable alignment and rich styling |
| `CSSuiDropdown` | Select/dropdown list |
| `CSSuiEditField` | Single-line text input |
| `CSSuiNumericField` | Numeric input with min/max/step |
| `CSSuiSwitch` | Toggle switch |
| `CSSuiCheckbox` | Single boolean checkbox with custom-CSS tick |
| `CSSuiRadioGroup` | Radio group (single-select) or checkbox group (multi-select), horizontal or vertical |
| `CSSuiTextArea` | Multi-line text input |
| `CSSuiListBox` | Scrollable multi-select list |
| `CSSuiSearchBar` | Pill-shaped search input with embedded submit button |
| `CSSuiTree` | Filterable hierarchical tree, fast on 10k+ nodes |
| `CSSuiTable` | Tabular display with optional inline cell editing (`ColumnEditable`, `CellEditCallback`) |
| `CSSUIProgressBar` | Horizontal progress bar with optional text label (above/below/on) and tick marks |
| `SmoothProgressBar` | Animated progress bar driven by `requestAnimationFrame` inside the uihtml Chromium — 60 FPS with zero per-tick MATLAB IPC |

Plus two supporting classes:

| Class | Purpose |
|---|---|
| `CSSBase` | Abstract parent — handles lifecycle: temp-file writing, JS bridge injection, Enabled-state queuing, CSS variable compilation, live CSS patching |
| `CSSPreset` | Pure-data container holding a set of style variables (Color, BackgroundColor, etc.) plus a CSS string. Static factory methods build named presets |

And two demo entry points:

| Script | Shows |
|---|---|
| `CSSDemo` | Core components in a grid, with preset switching, enable-toggle, and callback wiring |
| `CSSProgressBarDemo` | Progress bar variations including `CSSUIProgressBar` and `SmoothProgressBar` |

## How it works

Each component writes a self-contained HTML file to a temp directory, points a `uihtml` element at it, and then communicates bidirectionally:

- **MATLAB → HTML**: property setters send tiny JSON messages through the `uihtml.Data` bridge. The HTML side has a small JS handler that patches the relevant DOM nodes (text, attributes, classes, CSS variables) — never a full reload.
- **HTML → MATLAB**: user interactions (click, change, hover) fire `uihtml.DataChangedFcn` with a JSON payload. `CSSBase` routes that to the subclass's appropriate MATLAB callback (e.g., `ButtonPushedFcn`, `ValueChangedFcn`).

This architecture is what makes live property patching cheap — the round trip for a text update is a single JSON event, no rebuild.

## CSS schema

Every component's HTML follows the same selector convention so one preset can style all of them. Two layers of class:

### Role classes (shared across components)

These describe the *role* an element plays inside the widget. They're identical across every CSSui* component, so a rule like `.css-clickable:hover { ... }` covers buttons, dropdowns, and any other clickable surface in one go.

| Selector | Role |
|---|---|
| `#css-root` | Outer sizing container |
| `.css-surface` | Primary rendered surface |
| `.css-control` | Main interactive surface |
| `.css-clickable` | Interactive surfaces with hover/active animations |
| `.css-label` | Adjacent text label |
| `.css-icon` | SVG icon element (`CSSuiButton` only) |
| `#cssbase-text` | Live-patchable text span |
| `.css-disabled` | Applied to `#css-root` when `Enabled = false` |

### Widget-type classes (one per component)

Every widget also tags its `#css-root` with a kebab-case widget-type class. Pick one when you want a rule to apply to *one kind of widget only* — e.g. tint button backgrounds without touching inputs.

| Class | Component |
|---|---|
| `.cssui-button` | `CSSuiButton` |
| `.cssui-label` | `CSSuiLabel` |
| `.cssui-edit` | `CSSuiEditField` |
| `.cssui-numeric` | `CSSuiNumericField` |
| `.cssui-textarea` | `CSSuiTextArea` |
| `.cssui-dropdown` | `CSSuiDropdown` |
| `.cssui-listbox` | `CSSuiListBox` |
| `.cssui-checkbox` | `CSSuiCheckbox` |
| `.cssui-switch` | `CSSuiSwitch` |
| `.cssui-radio` | `CSSuiRadioGroup` |
| `.cssui-search` | `CSSuiSearchBar` |
| `.cssui-table` | `CSSuiTable` |
| `.cssui-tree` | `CSSuiTree` |
| `.cssui-progressbar` | `CSSUIProgressBar` (and `SmoothProgressBar`) |

Choose the smallest selector that does the job: role classes for behavior shared across kinds (hover lift, disabled fade), widget-type classes for kind-specific tweaks (button background vs input background).

## Presets

`CSSPreset` is a set of named style bundles you can drop into any component via the `'Style'` name-value pair:

```matlab
btn = CSSuiButton(parent, 'Style', 'shadow');              % by name
btn = CSSuiButton(parent, 'Style', CSSPreset.shadow());    % by object
btn.setStyle('neon');                                      % switch at runtime
```

Available presets (static factories on `CSSPreset`):

| Preset | Look |
|---|---|
| `shadow` | Neumorphic raised-shadow (default) |
| `shadow_light` | Same shadow language on a near-white base |
| `flat` | Clean flat modern |
| `glass` | Frosted-glass / glassmorphism |
| `neon` | Cyberpunk dark with glowing cyan borders |
| `pill` | Rounded pill with solid purple accent |
| `dark` | Dark-mode flat (VS Code style) |

Call `CSSPreset.list()` for the authoritative enumerated list. Presets set convenience properties (Color, BackgroundColor, BorderRadius, FontSize, …) and append a CSS string targeting the schema selectors above.

### One preset, multiple widget types

Because each widget tags its root with a `.cssui-<kebab>` class (see schema above), a single `CSSPreset` can style buttons one way and inputs another from the same `.CSS` string:

```matlab
p = CSSPreset.shadow_light();
p.CSS = [p.CSS ...
    '.cssui-button .css-surface { background-color: #ececec; }' ...
    '.cssui-edit   .css-surface,'  ...
    '.cssui-numeric .css-surface,' ...
    '.cssui-textarea .css-surface { background-color: #ffffff; }'];
```

Apply that one preset to every widget in your app and they share a unified text color, font, and shadow language while still having kind-specific backgrounds. This is the pattern an app should reach for when it wants a single source of truth for its visual identity.

### Customizing a preset

Build a custom preset by copying one and tweaking convenience properties or appending CSS rules:

```matlab
p = CSSPreset.flat();
p.Color = '#2a7a2a';
p.BorderRadius = '12px';
btn = CSSuiButton(parent, 'Style', p);
```

## Common constructor surface

Every component accepts these via `CSSBase`:

| Name | Meaning |
|---|---|
| `Position` | `[x y w h]` in pixels (default `[10 10 120 36]`) |
| `Enabled` | logical — greyed/disabled state (default `true`) |
| `Style` | preset name or `CSSPreset` object |
| `CSS` | raw CSS string appended to the compiled document |
| `CSSFile` | path to a `.css` file whose contents are appended |
| `TempDir` | where the generated HTML gets written (default: `tempdir()`) |

Plus component-specific options (`Text`, `Value`, `Icon`, `Items`, etc.) — see each class's docstring for the full list.

## CSS cascade order

CSS rules land in this order inside every widget's `<style>` block (later rules win at equal specificity):

1. External `.css` file (`CSSFile` property, if set).
2. Schema CSS — `#css-root` sizing, `.css-disabled` defaults.
3. `:root { --color, --bg-color, ... }` — convenience-property variables.
4. The component's own internal `<style>` (its baseline appearance).
5. `<style id="cssbase-override">` — preset CSS first, then `obj.CSS` (user CSS).

Practical consequence: the component's defaults are easy to override with a preset, and a user's `obj.CSS` always wins over the preset at equal specificity. No `!important` needed for most overrides.

## Usage example

```matlab
fig = uifigure('Position', [100 100 400 200]);
gl = uigridlayout(fig, [3, 2]);

% Pick a preset once — applies consistently across components
preset = CSSPreset.dark();

lbl = CSSuiLabel(gl, 'Text', 'Volume:', 'Style', preset);
sld = CSSuiNumericField(gl, 'Value', 50, 'Min', 0, 'Max', 100, 'Style', preset, ...
    'ValueChangedFcn', @(s,e) fprintf('Volume = %d\n', s.Value));
btn = CSSuiButton(gl, 'Text', 'Apply', 'Icon', 'check.svg', 'Style', preset, ...
    'ButtonPushedFcn', @(s,e) disp('Applied'));

% Live update — no page reload
btn.Text = 'Updated';
btn.setStyle('neon');
```

For a full demo: run `CSSDemo` or `CSSProgressBarDemo` at the MATLAB prompt.

## Files in this directory

- Component classes (`.m` files): `CSSuiButton`, `CSSuiLabel`, `CSSuiDropdown`, `CSSuiEditField`, `CSSuiNumericField`, `CSSuiSwitch`, `CSSuiCheckbox`, `CSSuiRadioGroup`, `CSSuiTextArea`, `CSSuiListBox`, `CSSuiSearchBar`, `CSSuiTree`, `CSSuiTable`, `CSSUIProgressBar`, `SmoothProgressBar`
- `CSSBase.m` — abstract lifecycle manager
- `CSSPreset.m` — style preset factory
- `CSSDemo.m`, `CSSProgressBarDemo.m` — runnable demos
- `README.md` — this file

## Dependencies

Base MATLAB `uifigure` support (R2020b+ recommended — `uihtml` exists in R2019b, but `DataChangedFcn` routing is more reliable in R2020b and later). No toolboxes required. No external libraries — every component is a standalone HTML+CSS+JS document.
