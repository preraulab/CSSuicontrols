function CSSDemo()
%CSSDEMO  Interactive demo and functional test for the CSS component library.
%
%   Run with:   CSSDemo()
%
%   The demo creates a uifigure with all seven components laid out in a grid.
%   Each component fires callbacks that update a status label so you can
%   verify bidirectional communication.  A row of native MATLAB controls lets
%   you toggle enabled-state, switch presets on-the-fly, and trigger
%   programmatic value changes.
%
%   Components demonstrated
%   -----------------------
%     uiButton       — click, programmatic text change
%     uiLabel        — static text, programmatic update
%     uiDropdown     — ValueChangedFcn, Items change, programmatic Value
%     uiEditField    — ValueChangedFcn, ValueChangingFcn, Editable toggle
%     uiNumericField — Min/Max/Step, ValueChangedFcn, ValueChangingFcn
%     uiSwitch       — ValueChangedFcn, programmatic toggle
%     uiTextArea     — ValueChangedFcn, ValueChangingFcn, Placeholder

%% ── Figure & layout ───────────────────────────────────────────────────────
fig = uifigure('Name','CSS Component Demo', ...
               'Position',[100 60 900 780], ...
               'Color',[0.93 0.93 0.93]);

gl = uigridlayout(fig, [10 3], ...
    'ColumnWidth', {'1x','1x','1x'}, ...
    'RowHeight',   {28, 50, 50, 50, 50, 50, 80, 130, 28, 44}, ...
    'Padding',     [14 14 14 14], ...
    'RowSpacing',  10, ...
    'ColumnSpacing',14, ...
    'BackgroundColor',[0.93 0.93 0.93]);

presetNames = {'shadow','flat','glass','neon'};
presetIdx   = 1;
preset      = presetNames{presetIdx};

%% ── Section header ────────────────────────────────────────────────────────
hdr = uilabel(gl, 'Text','CSS Component Demo', ...
    'FontSize',17, 'FontWeight','bold', ...
    'HorizontalAlignment','center');
hdr.Layout.Row = 1; hdr.Layout.Column = [1 3];

%% ── Status label ──────────────────────────────────────────────────────────
statusLbl = uiLabel(gl, 'Text','Status: ready', 'Style', preset);
statusLbl.Layout.Row = 2; statusLbl.Layout.Column = 3;

    function setStatus(msg)
        statusLbl.Text = ['Status: ' msg];
    end

%% ── 1. uiButton ───────────────────────────────────────────────────────────
btn = uiButton(gl, ...
    'Text',            'Click Me', ...
    'Style',           preset, ...
    'ButtonPushedFcn', @(s,e) setStatus('Button clicked!'));
btn.Layout.Row = 2; btn.Layout.Column = 1;

lbl_btn = uilabel(gl,'Text','uiButton','FontWeight','bold');
lbl_btn.Layout.Row = 2; lbl_btn.Layout.Column = 2;

%% ── 2. uiLabel ────────────────────────────────────────────────────────────
lbl = uiLabel(gl, 'Text','Hello, CSS!', 'Style', preset);
lbl.Layout.Row = 3; lbl.Layout.Column = 1;

lbl_lbl = uilabel(gl,'Text','uiLabel','FontWeight','bold');
lbl_lbl.Layout.Row = 3; lbl_lbl.Layout.Column = 2;

%% ── 3. uiDropdown ─────────────────────────────────────────────────────────
dd = uiDropdown(gl, ...
    'Items',           {'Alpha','Beta','Gamma','Delta'}, ...
    'Label',           'Pick:', ...
    'Style',           preset, ...
    'ValueChangedFcn', @(s,e) setStatus(['Dropdown → ' e.Value]));
dd.Layout.Row = 4; dd.Layout.Column = 1;

lbl_dd = uilabel(gl,'Text','uiDropdown','FontWeight','bold');
lbl_dd.Layout.Row = 4; lbl_dd.Layout.Column = 2;

%% ── 4. uiEditField ────────────────────────────────────────────────────────
ef = uiEditField(gl, ...
    'Placeholder',     'Type something...', ...
    'Label',           'Name:', ...
    'Style',           preset, ...
    'ValueChangingFcn',@(s,e) setStatus(['Typing: ' e.Value]), ...
    'ValueChangedFcn', @(s,e) setStatus(['Edit committed: ' e.Value]));
ef.Layout.Row = 5; ef.Layout.Column = 1;

lbl_ef = uilabel(gl,'Text','uiEditField','FontWeight','bold');
lbl_ef.Layout.Row = 5; lbl_ef.Layout.Column = 2;

%% ── 5. uiNumericField ─────────────────────────────────────────────────────
nf = uiNumericField(gl, ...
    'Value',           0, ...
    'Min',            -100, ...
    'Max',             100, ...
    'Step',            1, ...
    'Label',           'Value:', ...
    'Style',           preset, ...
    'ValueChangingFcn',@(s,e) setStatus(sprintf('Numeric changing: %.4g', e.Value)), ...
    'ValueChangedFcn', @(s,e) setStatus(sprintf('Numeric → %.4g  (was %.4g)', e.Value, e.PreviousValue)));
nf.Layout.Row = 6; nf.Layout.Column = 1;

lbl_nf = uilabel(gl,'Text','uiNumericField','FontWeight','bold');
lbl_nf.Layout.Row = 6; lbl_nf.Layout.Column = 2;

%% ── 6. uiSwitch ───────────────────────────────────────────────────────────
sw = uiSwitch(gl, ...
    'Text',            'Notifications', ...
    'Value',           false, ...
    'Style',           preset, ...
    'ValueChangedFcn', @(s,e) setStatus(sprintf('Switch → %d', e.Value)));
sw.Layout.Row = 7; sw.Layout.Column = 1;

lbl_sw = uilabel(gl,'Text','uiSwitch','FontWeight','bold');
lbl_sw.Layout.Row = 7; lbl_sw.Layout.Column = 2;

%% ── 7. uiTextArea ─────────────────────────────────────────────────────────
ta = uiTextArea(gl, ...
    'Placeholder',     'Enter notes here...', ...
    'Label',           'Notes', ...
    'Style',           preset, ...
    'ValueChangingFcn',@(s,e) setStatus(sprintf('Typing (%d chars)', numel(e.Value))), ...
    'ValueChangedFcn', @(s,e) setStatus(sprintf('TextArea committed (%d chars)', numel(e.Value))));
ta.Layout.Row = 8; ta.Layout.Column = 1;

lbl_ta = uilabel(gl,'Text','uiTextArea','FontWeight','bold');
lbl_ta.Layout.Row = 8; lbl_ta.Layout.Column = 2;

%% ── Control panel (column 3) ──────────────────────────────────────────────
allCSSComps = {btn, lbl, dd, ef, nf, sw, ta, statusLbl};

% ── Cycle Preset ──────────────────────────────────────────────────────────
presetBtn = uibutton(gl, 'Text', sprintf('Preset: %s  →', preset), ...
    'ButtonPushedFcn', @cyclePreset);
presetBtn.Layout.Row = 3; presetBtn.Layout.Column = 3;

    function cyclePreset(src, ~)
        presetIdx = mod(presetIdx, numel(presetNames)) + 1;
        preset    = presetNames{presetIdx};
        for k = 1:numel(allCSSComps)
            allCSSComps{k}.setStyle(preset);
        end
        src.Text = sprintf('Preset: %s  →', preset);
        footerLbl.Text = sprintf('Preset: %s   |   All components backed by uihtml', preset);
        setStatus(['Preset switched to: ' preset]);
    end

% ── Enable / Disable all ──────────────────────────────────────────────────
enableBtn = uibutton(gl, 'Text','Disable All', 'ButtonPushedFcn', @toggleAll);
enableBtn.Layout.Row = 4; enableBtn.Layout.Column = 3;
isEnabled = true;

    function toggleAll(src, ~)
        isEnabled = ~isEnabled;
        for k = 1:numel(allCSSComps)
            allCSSComps{k}.Enabled = isEnabled;
        end
        if isEnabled
            src.Text = 'Disable All';  setStatus('All components enabled');
        else
            src.Text = 'Enable All';   setStatus('All components disabled');
        end
    end

% ── Set values programmatically ───────────────────────────────────────────
progBtn = uibutton(gl, 'Text','Set Values Programmatically', ...
    'ButtonPushedFcn', @setProgrammatic);
progBtn.Layout.Row = 5; progBtn.Layout.Column = 3;

    function setProgrammatic(~, ~)
        btn.Text = 'Updated!';
        lbl.Text = char("Label @ " + string(datetime('now','Format','HH:mm:ss')));
        dd.Value = 'Gamma';
        ef.Value = 'Programmatic text';
        nf.Value = 42;
        sw.Value = ~sw.Value;
        ta.Value = sprintf('Programmatic content.\nLine 2 here.');
        setStatus('All values set programmatically');
    end

% ── Reset all values ──────────────────────────────────────────────────────
resetBtn = uibutton(gl, 'Text','Reset All Values', 'ButtonPushedFcn', @resetAll);
resetBtn.Layout.Row = 6; resetBtn.Layout.Column = 3;

    function resetAll(~, ~)
        btn.Text = 'Click Me';
        lbl.Text = 'Hello, CSS!';
        dd.Value = 'Alpha';
        ef.Value = '';
        nf.Value = 0;
        sw.Value = false;
        ta.Value = '';
        setStatus('All values reset');
    end

% ── Lock / unlock editable fields ─────────────────────────────────────────
editableBtn = uibutton(gl, 'Text','Lock Edit Fields', 'ButtonPushedFcn', @toggleEditable);
editableBtn.Layout.Row = 7; editableBtn.Layout.Column = 3;
isEditable = true;

    function toggleEditable(src, ~)
        isEditable = ~isEditable;
        ef.Editable = isEditable;
        ta.Editable = isEditable;
        if isEditable
            src.Text = 'Lock Edit Fields';  setStatus('Edit fields unlocked');
        else
            src.Text = 'Unlock Edit Fields'; setStatus('Edit fields locked (read-only)');
        end
    end

% ── Cycle dropdown items ───────────────────────────────────────────────────
itemsBtn = uibutton(gl, 'Text','Change Dropdown Items', 'ButtonPushedFcn', @changeItems);
itemsBtn.Layout.Row = 8; itemsBtn.Layout.Column = 3;
itemSet = 1;

    function changeItems(~, ~)
        sets = { ...
            {'Alpha','Beta','Gamma','Delta'}, ...
            {'Red','Green','Blue'}, ...
            {'Small','Medium','Large','X-Large'} ...
        };
        itemSet = mod(itemSet, numel(sets)) + 1;
        dd.Items = sets{itemSet};
        setStatus(sprintf('Dropdown → %d items', numel(sets{itemSet})));
    end

%% ── Footer ────────────────────────────────────────────────────────────────
divLbl = uilabel(gl, 'Text','── Programmatic controls (native MATLAB) ──', ...
    'HorizontalAlignment','center','FontAngle','italic');
divLbl.Layout.Row = 9; divLbl.Layout.Column = [1 3];

footerLbl = uilabel(gl, ...
    'Text', sprintf('Preset: %s   |   All components backed by uihtml', preset), ...
    'HorizontalAlignment','center','FontSize',11,'FontColor',[0.4 0.4 0.4]);
footerLbl.Layout.Row = 10; footerLbl.Layout.Column = [1 3];

end
