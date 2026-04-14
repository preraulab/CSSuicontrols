function CSSProgressBarDemo()
%CSSProgressBarDemo  Demo and functional test for CSSUIProgressBar.
%
%   Run with:   CSSProgressBarDemo()
%
%   Tests:
%     - TextPosition 'none', 'above', 'below', 'on'
%     - BarHeight at thin / medium / tall / full
%     - ShowTicks, custom color/shadow, SmoothProgressBar
%     - Live Value, Text, Color, and BarHeight updates

%% ── Figure & layout ───────────────────────────────────────────────────────
fig = uifigure('Name', 'CSSUIProgressBar Demo', ...
               'Position', [100 80 860 720]);

gl = uigridlayout(fig, [12 3], ...
    'ColumnWidth',   {'1x', '1x', 160}, ...
    'RowHeight',     {28, 50, 50, 50, 50, 50, 50, 50, 50, 50, 28, 36}, ...
    'Padding',       [14 14 14 14], ...
    'RowSpacing',    8, ...
    'ColumnSpacing', 14, ...
    'BackgroundColor', [0.93 0.93 0.93]);

%% ── Header ────────────────────────────────────────────────────────────────
hdr = uilabel(gl, 'Text', 'CSSUIProgressBar Demo', ...
    'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
hdr.Layout.Row = 1; hdr.Layout.Column = [1 3];

%% ── 1. BarHeight = 0.15 (thin), no label ─────────────────────────────────
pb1 = CSSUIProgressBar(gl, 'Value', 0.4, 'BarHeight', 0.15);
pb1.Layout.Row = 2; pb1.Layout.Column = 1;
lbl1 = uilabel(gl, 'Text', "BarHeight=0.15  (thin, no label)", 'FontSize', 11);
lbl1.Layout.Row = 2; lbl1.Layout.Column = 2;

%% ── 2. BarHeight = 0.35, label above ─────────────────────────────────────
pb2 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.35, 'TextPosition', 'above', 'Text', 'Processing... 50%');
pb2.Layout.Row = 3; pb2.Layout.Column = 1;
lbl2 = uilabel(gl, 'Text', "BarHeight=0.35  TextPosition='above'", 'FontSize', 11);
lbl2.Layout.Row = 3; lbl2.Layout.Column = 2;

%% ── 3. BarHeight = 0.35, label below ─────────────────────────────────────
pb3 = CSSUIProgressBar(gl, 'Value', 0.7, ...
    'BarHeight', 0.35, 'TextPosition', 'below', 'Text', 'Step 7 of 10');
pb3.Layout.Row = 4; pb3.Layout.Column = 1;
lbl3 = uilabel(gl, 'Text', "BarHeight=0.35  TextPosition='below'", 'FontSize', 11);
lbl3.Layout.Row = 4; lbl3.Layout.Column = 2;

%% ── 4. BarHeight = 0.6, label on ─────────────────────────────────────────
pb4 = CSSUIProgressBar(gl, 'Value', 0.45, ...
    'BarHeight', 0.6, 'TextPosition', 'on', 'Text', '45%', ...
    'LabelColor', '#ffffff');
pb4.Layout.Row = 5; pb4.Layout.Column = 1;
lbl4 = uilabel(gl, 'Text', "BarHeight=0.60  TextPosition='on'", 'FontSize', 11);
lbl4.Layout.Row = 5; lbl4.Layout.Column = 2;

%% ── 5. BarHeight = 1.0 (full height), ticks ──────────────────────────────
pb5 = CSSUIProgressBar(gl, 'Value', 0.6, ...
    'BarHeight', 1.0, 'TextPosition', 'above', 'Text', 'Full height + ticks — 60%', ...
    'ShowTicks', true, 'NumTicks', 10, 'Color', '#0072ff');
pb5.Layout.Row = 6; pb5.Layout.Column = 1;
lbl5 = uilabel(gl, 'Text', "BarHeight=1.00  ShowTicks=true", 'FontSize', 11);
lbl5.Layout.Row = 6; lbl5.Layout.Column = 2;

%% ── 6. Custom color / radius / shadow ────────────────────────────────────
pb6 = CSSUIProgressBar(gl, 'Value', 0.25, ...
    'BarHeight', 0.4, 'TextPosition', 'above', 'Text', 'Custom style — 25%', ...
    'Color', '#e53935', 'BackgroundColor', '#fce4e4', ...
    'BarBorderRadius', '12px', ...
    'BoxShadow', '0 2px 6px rgba(229,57,53,0.4)');
pb6.Layout.Row = 7; pb6.Layout.Column = 1;
lbl6 = uilabel(gl, 'Text', "BarHeight=0.40  custom color/radius/shadow", 'FontSize', 11);
lbl6.Layout.Row = 7; lbl6.Layout.Column = 2;

%% ── 7. SmoothProgressBar ─────────────────────────────────────────────────
spb = SmoothProgressBar(gl, 'N', 20, ...
    'BarHeight', 0.35, 'ShowPercentage', true, 'ShowTimeRemaining', true);
spb.Layout.Row = 8; spb.Layout.Column = 1;
lbl7 = uilabel(gl, 'Text', "SmoothProgressBar  BarHeight=0.35", 'FontSize', 11);
lbl7.Layout.Row = 8; lbl7.Layout.Column = 2;

%% ── 8. Live BarHeight test (starts at 0.2, button cycles through heights) ─
pb8 = CSSUIProgressBar(gl, 'Value', 0.65, ...
    'BarHeight', 0.2, 'TextPosition', 'above', 'Text', 'BarHeight live test');
pb8.Layout.Row = 9; pb8.Layout.Column = 1;
lbl8 = uilabel(gl, 'Text', "BarHeight=0.20  (live, use button →)", 'FontSize', 11);
lbl8.Layout.Row = 9; lbl8.Layout.Column = 2;

%% ── Control panel ─────────────────────────────────────────────────────────
allBars = {pb1, pb2, pb3, pb4, pb5, pb6};
v = 0;

% Sweep 0→1
sweepBtn = uibutton(gl, 'Text', 'Sweep 0 → 1', ...
    'ButtonPushedFcn', @(~,~) sweepAll());
sweepBtn.Layout.Row = 2; sweepBtn.Layout.Column = 3;

    function sweepAll()
        for val = 0:0.05:1
            for k = 1:numel(allBars), allBars{k}.Value = val; end
            pb8.Value = val;
            drawnow limitrate
            pause(0.04)
        end
        v = 1;
        updateLabels();
    end

% Step +0.1
stepBtn = uibutton(gl, 'Text', 'Step +0.1', ...
    'ButtonPushedFcn', @(~,~) stepAll());
stepBtn.Layout.Row = 3; stepBtn.Layout.Column = 3;

    function stepAll()
        v = min(v + 0.1, 1);
        for k = 1:numel(allBars), allBars{k}.Value = v; end
        pb8.Value = v;
        updateLabels();
    end

% Reset
resetBtn = uibutton(gl, 'Text', 'Reset to 0', ...
    'ButtonPushedFcn', @(~,~) resetAll());
resetBtn.Layout.Row = 4; resetBtn.Layout.Column = 3;

    function resetAll()
        v = 0;
        for k = 1:numel(allBars), allBars{k}.Value = v; end
        pb8.Value = v;
        updateLabels();
    end

% Cycle BarHeight on all bars
heightBtn = uibutton(gl, 'Text', 'Cycle BarHeight', ...
    'ButtonPushedFcn', @cycleHeight);
heightBtn.Layout.Row = 5; heightBtn.Layout.Column = 3;
heightIdx = 0;
heights   = [0.15, 0.35, 0.5, 0.7, 1.0];

    function cycleHeight(~, ~)
        heightIdx = mod(heightIdx, numel(heights)) + 1;
        h = heights(heightIdx);
        for k = 1:numel(allBars), allBars{k}.BarHeight = h; end
        pb8.BarHeight = h;
        lbl8.Text = sprintf("BarHeight=%.2f  (live)", h);
        heightBtn.Text = sprintf('BarHeight: %.2f →', h);
    end

% Cycle color
colorBtn = uibutton(gl, 'Text', 'Cycle Color', ...
    'ButtonPushedFcn', @cycleColor);
colorBtn.Layout.Row = 6; colorBtn.Layout.Column = 3;
colorIdx = 0;
colors   = {'#0072ff','#e53935','#43a047','#fb8c00','#8e24aa'};

    function cycleColor(~, ~)
        colorIdx = mod(colorIdx, numel(colors)) + 1;
        for k = 1:numel(allBars), allBars{k}.Color = colors{colorIdx}; end
        pb8.Color = colors{colorIdx};
    end

% Update text
textBtn = uibutton(gl, 'Text', 'Update Text', ...
    'ButtonPushedFcn', @(~,~) updateTexts());
textBtn.Layout.Row = 7; textBtn.Layout.Column = 3;

    function updateTexts()
        stamp = char(datetime('now','Format','HH:mm:ss'));
        pb2.Text = sprintf('Updated @ %s', stamp);
        pb3.Text = sprintf('%.0f%% complete', v * 100);
        pb4.Text = sprintf('%.0f%%', v * 100);
        pb5.Text = sprintf('Full height — %.0f%%', v * 100);
        pb6.Text = sprintf('Custom — %.0f%%', v * 100);
        pb8.Text = sprintf('Live BarHeight test @ %s', stamp);
    end

% Run SmoothProgressBar
runBtn = uibutton(gl, 'Text', 'Run SmoothProgressBar', ...
    'ButtonPushedFcn', @(~,~) runSmooth());
runBtn.Layout.Row = 8; runBtn.Layout.Column = 3;

    function runSmooth()
        spb.N = 20;
        spb.start();
        for k = 1:20
            pause(0.15 + 0.1*rand);
            spb.updateIteration(k);
        end
    end

%% ── Footer ────────────────────────────────────────────────────────────────
footerLbl = uilabel(gl, ...
    'Text', 'BarHeight controls track height as fraction of cell (0–1)', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontColor', [0.45 0.45 0.45]);
footerLbl.Layout.Row = 11; footerLbl.Layout.Column = [1 3];

    function updateLabels()
        lbl1.Text = sprintf("BarHeight=0.15  Value=%.2f", v);
        lbl2.Text = sprintf("BarHeight=0.35  above  Value=%.2f", v);
        lbl3.Text = sprintf("BarHeight=0.35  below  Value=%.2f", v);
        lbl4.Text = sprintf("BarHeight=0.60  on     Value=%.2f", v);
        lbl5.Text = sprintf("BarHeight=1.00  ticks  Value=%.2f", v);
        lbl6.Text = sprintf("BarHeight=0.40  custom Value=%.2f", v);
    end

end
