function CSSProgressBarDemo()
%CSSProgressBarDemo  Demo and functional test for CSSUIProgressBar.
%
%   Run with:   CSSProgressBarDemo()
%
%   Tests:
%     - TextPosition 'none', 'above', 'below', 'on'
%     - BarHeight at thin / medium / tall / full
%     - BarBorderRadius: square → rounded → pill
%     - ShowTicks, custom color/shadow, SmoothProgressBar
%     - Live Value, Text, Color, BarHeight, and BarBorderRadius updates

%% ── Figure & layout ───────────────────────────────────────────────────────
fig = uifigure('Name', 'CSSUIProgressBar Demo', ...
               'Position', [100 80 900 780]);

gl = uigridlayout(fig, [13 3], ...
    'ColumnWidth',   {'1x', '1x', 170}, ...
    'RowHeight',     {28, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 28, 36}, ...
    'Padding',       [14 14 14 14], ...
    'RowSpacing',    8, ...
    'ColumnSpacing', 14, ...
    'BackgroundColor', [0.93 0.93 0.93]);

%% ── Header ────────────────────────────────────────────────────────────────
hdr = uilabel(gl, 'Text', 'CSSUIProgressBar Demo', ...
    'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
hdr.Layout.Row = 1; hdr.Layout.Column = [1 3];

%% ── 1. Square corners (BarBorderRadius = '0px') ───────────────────────────
pb1 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Square — 0px radius');
pb1.Layout.Row = 2; pb1.Layout.Column = 1;
lbl1 = uilabel(gl, 'Text', "BarBorderRadius='0px'  (square)", 'FontSize', 11);
lbl1.Layout.Row = 2; lbl1.Layout.Column = 2;

%% ── 2. Slightly rounded (BarBorderRadius = '4px') ─────────────────────────
pb2 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Slightly rounded — 4px', ...
    'BarBorderRadius', '4px');
pb2.Layout.Row = 3; pb2.Layout.Column = 1;
lbl2 = uilabel(gl, 'Text', "BarBorderRadius='4px'", 'FontSize', 11);
lbl2.Layout.Row = 3; lbl2.Layout.Column = 2;

%% ── 3. Medium rounded (BarBorderRadius = '8px') ───────────────────────────
pb3 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Medium rounded — 8px', ...
    'BarBorderRadius', '8px');
pb3.Layout.Row = 4; pb3.Layout.Column = 1;
lbl3 = uilabel(gl, 'Text', "BarBorderRadius='8px'", 'FontSize', 11);
lbl3.Layout.Row = 4; lbl3.Layout.Column = 2;

%% ── 4. Pill shape (BarBorderRadius = '999px') ─────────────────────────────
pb4 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Pill shape — 999px', ...
    'BarBorderRadius', '999px');
pb4.Layout.Row = 5; pb4.Layout.Column = 1;
lbl4 = uilabel(gl, 'Text', "BarBorderRadius='999px'  (pill)", 'FontSize', 11);
lbl4.Layout.Row = 5; lbl4.Layout.Column = 2;

%% ── 5. Pill + thin bar ────────────────────────────────────────────────────
pb5 = CSSUIProgressBar(gl, 'Value', 0.5, ...
    'BarHeight', 0.2, 'TextPosition', 'above', 'Text', 'Thin pill', ...
    'BarBorderRadius', '999px', 'Color', '#43a047');
pb5.Layout.Row = 6; pb5.Layout.Column = 1;
lbl5 = uilabel(gl, 'Text', "BarBorderRadius='999px'  BarHeight=0.20", 'FontSize', 11);
lbl5.Layout.Row = 6; lbl5.Layout.Column = 2;

%% ── 6. Pill + ticks ───────────────────────────────────────────────────────
pb6 = CSSUIProgressBar(gl, 'Value', 0.6, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Pill + ticks', ...
    'BarBorderRadius', '999px', 'ShowTicks', true, 'NumTicks', 10);
pb6.Layout.Row = 7; pb6.Layout.Column = 1;
lbl6 = uilabel(gl, 'Text', "BarBorderRadius='999px'  ShowTicks=true", 'FontSize', 11);
lbl6.Layout.Row = 7; lbl6.Layout.Column = 2;

%% ── 7. Custom color + pill ────────────────────────────────────────────────
pb7 = CSSUIProgressBar(gl, 'Value', 0.35, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Custom color + pill', ...
    'BarBorderRadius', '999px', 'Color', '#e53935', 'BackgroundColor', '#fce4e4');
pb7.Layout.Row = 8; pb7.Layout.Column = 1;
lbl7 = uilabel(gl, 'Text', "Custom color  BarBorderRadius='999px'", 'FontSize', 11);
lbl7.Layout.Row = 8; lbl7.Layout.Column = 2;

%% ── 8. SmoothProgressBar with pill shape ─────────────────────────────────
spb = SmoothProgressBar(gl, 'N', 20, ...
    'BarHeight', 0.4, 'BarBorderRadius', '999px', ...
    'ShowPercentage', true, 'ShowTimeRemaining', true);
spb.Layout.Row = 9; spb.Layout.Column = 1;
lbl8 = uilabel(gl, 'Text', "SmoothProgressBar  BarBorderRadius='999px'", 'FontSize', 11);
lbl8.Layout.Row = 9; lbl8.Layout.Column = 2;

%% ── 9. Live BarBorderRadius test ──────────────────────────────────────────
pb9 = CSSUIProgressBar(gl, 'Value', 0.65, ...
    'BarHeight', 0.45, 'TextPosition', 'above', 'Text', 'Live radius test', ...
    'BarBorderRadius', '0px');
pb9.Layout.Row = 10; pb9.Layout.Column = 1;
lbl9 = uilabel(gl, 'Text', "BarBorderRadius='0px'  (live, use button →)", 'FontSize', 11);
lbl9.Layout.Row = 10; lbl9.Layout.Column = 2;

%% ── Control panel ─────────────────────────────────────────────────────────
allBars = {pb1, pb2, pb3, pb4, pb5, pb6, pb7};
v = 0.5;

% Sweep 0→1
sweepBtn = uibutton(gl, 'Text', 'Sweep 0 → 1', ...
    'ButtonPushedFcn', @(~,~) sweepAll());
sweepBtn.Layout.Row = 2; sweepBtn.Layout.Column = 3;

    function sweepAll()
        for val = 0:0.05:1
            for k = 1:numel(allBars), allBars{k}.Value = val; end
            pb9.Value = val;
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
        pb9.Value = v;
        updateLabels();
    end

% Reset
resetBtn = uibutton(gl, 'Text', 'Reset to 0', ...
    'ButtonPushedFcn', @(~,~) resetAll());
resetBtn.Layout.Row = 4; resetBtn.Layout.Column = 3;

    function resetAll()
        v = 0;
        for k = 1:numel(allBars), allBars{k}.Value = v; end
        pb9.Value = v;
        updateLabels();
    end

% Cycle BarBorderRadius live
radiusBtn = uibutton(gl, 'Text', "Radius: 0px →", ...
    'ButtonPushedFcn', @cycleRadius);
radiusBtn.Layout.Row = 5; radiusBtn.Layout.Column = 3;
radiusIdx = 1;
radii     = {'0px','4px','8px','16px','999px'};

    function cycleRadius(~, ~)
        radiusIdx = mod(radiusIdx, numel(radii)) + 1;
        r = radii{radiusIdx};
        for k = 1:numel(allBars), allBars{k}.BarBorderRadius = r; end
        pb9.BarBorderRadius = r;
        spb.BarBorderRadius = r;
        radiusBtn.Text = sprintf('Radius: %s →', r);
        lbl9.Text = sprintf("BarBorderRadius='%s'  (live)", r);
    end

% Cycle BarHeight
heightBtn = uibutton(gl, 'Text', 'BarHeight: 0.45 →', ...
    'ButtonPushedFcn', @cycleHeight);
heightBtn.Layout.Row = 6; heightBtn.Layout.Column = 3;
heightIdx = 0;
heights   = [0.15, 0.3, 0.45, 0.65, 1.0];

    function cycleHeight(~, ~)
        heightIdx = mod(heightIdx, numel(heights)) + 1;
        h = heights(heightIdx);
        for k = 1:numel(allBars), allBars{k}.BarHeight = h; end
        pb9.BarHeight = h;
        spb.BarHeight = h;
        heightBtn.Text = sprintf('BarHeight: %.2f →', h);
    end

% Cycle color
colorBtn = uibutton(gl, 'Text', 'Cycle Color', ...
    'ButtonPushedFcn', @cycleColor);
colorBtn.Layout.Row = 7; colorBtn.Layout.Column = 3;
colorIdx = 0;
colors   = {'#0072ff','#e53935','#43a047','#fb8c00','#8e24aa'};

    function cycleColor(~, ~)
        colorIdx = mod(colorIdx, numel(colors)) + 1;
        for k = 1:numel(allBars), allBars{k}.Color = colors{colorIdx}; end
        pb9.Color = colors{colorIdx};
        spb.Color = colors{colorIdx};
    end

% Run SmoothProgressBar
runBtn = uibutton(gl, 'Text', 'Run SmoothProgressBar', ...
    'ButtonPushedFcn', @(~,~) runSmooth());
runBtn.Layout.Row = 8; runBtn.Layout.Column = 3;

    function runSmooth()
        spb.N = 10;
        spb.start();
        for k = 1:spb.N
            pause(0.8 + 0.4*rand);
            spb.updateIteration(k);
        end
    end

%% ── Footer ────────────────────────────────────────────────────────────────
footerLbl = uilabel(gl, ...
    'Text', 'BarBorderRadius controls both track and fill corners (0px → pill via 999px)', ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontColor', [0.45 0.45 0.45]);
footerLbl.Layout.Row = 12; footerLbl.Layout.Column = [1 3];

    function updateLabels()
        lbl1.Text = sprintf("BarBorderRadius='0px'   Value=%.2f", v);
        lbl2.Text = sprintf("BarBorderRadius='4px'   Value=%.2f", v);
        lbl3.Text = sprintf("BarBorderRadius='8px'   Value=%.2f", v);
        lbl4.Text = sprintf("BarBorderRadius='999px' Value=%.2f", v);
        lbl5.Text = sprintf("Thin pill               Value=%.2f", v);
        lbl6.Text = sprintf("Pill + ticks            Value=%.2f", v);
        lbl7.Text = sprintf("Custom color + pill     Value=%.2f", v);
    end

end
