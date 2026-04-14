classdef CSSUIProgressBar < CSSBase
    %CSSUIProgressBar  CSS-styled horizontal progress bar backed by uihtml.
    %
    %   A standalone, fully styleable progress bar. Supports an optional text
    %   label (above, below, or overlaid on the bar) and optional tick marks.
    %   Designed to pair with SmoothProgressBar for timer-driven animation,
    %   but fully usable on its own for deterministic 0→1 progress display.
    %
    % USAGE:
    %   pb = CSSUIProgressBar(parent)
    %   pb = CSSUIProgressBar(parent, 'Value', 0.5, 'Style', 'shadow')
    %   pb = CSSUIProgressBar(parent, 'TextPosition', 'above', 'ShowTicks', true)
    %   pb.Value = 0.75;          % live-updates, no rebuild
    %   pb.Text  = '75% — 3s';   % live-updates, no rebuild
    %
    % CSS ELEMENT SCHEMA:
    %   #css-root           Outer flex column container
    %   .css-control        Bar track (uses --bg-color for background)
    %     .css-bar          Fill element (uses --color for fill)
    %     .css-ticks        Tick mark container (when ShowTicks=true)
    %       .css-tick       Individual tick marks
    %   .css-label          Text label (when TextPosition != 'none')
    %     #cssbase-text     Span targeted by the setText bridge command
    %
    % KEY CSS CUSTOM PROPERTIES:
    %   --color             Bar fill color           (via Color property)
    %   --bg-color          Track background color   (via BackgroundColor property)
    %   --bar-height        Bar height fraction 0-1  (via BarHeight property)
    %   --bar-radius        Bar fill border-radius   (via BarBorderRadius property)
    %   --tick-color        Tick mark color          (via TickColor property)
    %   --tick-height       Tick mark height         (via TickHeight property)
    %   --label-color       Text label color         (via LabelColor property)
    %   --progress-pct      Progress fraction 0-1    (via Value property)
    %
    % CUSTOM CSS EXAMPLES:
    %   pb.Color           = '#0072ff';
    %   pb.BackgroundColor = '#d8d8d8';
    %   pb.BorderRadius    = '8px';
    %   pb.BoxShadow       = 'inset 0 2px 4px rgba(0,0,0,0.15)';
    %   pb.CSS = '.css-bar { background: linear-gradient(90deg,#00c6ff,#0072ff); }';
    %   pb.CSS = '.css-label { font-weight: bold; letter-spacing: 0.04em; }';
    %   pb.CSS = '.css-tick { width: 2px; }';
    %
    % =========================================================================
    %                  CSSuicontrols  |  Prerau Laboratory
    % =========================================================================

    % =====================================================================
    properties (Access = public)

        % --- Progress -------------------------------------------------------
        Value (1,1) double {mustBeGreaterThanOrEqual(Value,0), ...
                            mustBeLessThanOrEqual(Value,1)} = 0

        % --- Text label -----------------------------------------------------
        %   Text         Display string shown at TextPosition.
        %   TextPosition Where the label appears:
        %                  'none'  — no label (default)
        %                  'above' — label above the bar track
        %                  'below' — label below the bar track
        %                  'on'    — label overlaid on the bar (centered)
        %   LabelColor   CSS color for the text label.  Defaults to #333.
        %                Use this instead of Color so bar fill stays independent.
        Text         (1,:) char = ''
        TextPosition (1,:) char = 'none'
        LabelColor   (1,:) char = ''

        % --- Tick marks -----------------------------------------------------
        ShowTicks  (1,1) logical = false
        NumTicks   (1,1) double  {mustBePositive, mustBeInteger} = 10
        TickColor  (1,:) char    = 'rgba(255,255,255,0.6)'
        TickHeight (1,1) double  {mustBeGreaterThan(TickHeight,0), ...
                                  mustBeLessThanOrEqual(TickHeight,1)} = 0.3

        % --- Bar geometry ---------------------------------------------------
        BarHeight       (1,1) double {mustBeGreaterThan(BarHeight,0), ...
                                      mustBeLessThanOrEqual(BarHeight,1)} = 0.5
        BarBorderRadius (1,:) char   = '4px'
    end

    % =====================================================================
    methods

        function obj = CSSUIProgressBar(parent, options)
            arguments
                parent = []
                options.Position         (1,4) double  = [10 10 300 40]
                options.Enabled          (1,1) logical = true
                options.TempDir          (1,:) char    = tempdir()
                options.Style                          = ''
                options.CSS              (1,:) char    = ''
                options.CSSFile          (1,:) char    = ''
                % --- Progress / label --------------------------------------
                options.Value            (1,1) double  = 0
                options.Text             (1,:) char    = ''
                options.TextPosition     (1,:) char    = 'none'
                options.LabelColor       (1,:) char    = ''
                % --- Ticks -------------------------------------------------
                options.ShowTicks        (1,1) logical = false
                options.NumTicks         (1,1) double  = 10
                options.TickColor        (1,:) char    = 'rgba(255,255,255,0.6)'
                options.TickHeight       (1,1) double  = 0.3
                % --- Bar geometry -----------------------------------------
                options.BarHeight        (1,1) double  = 0.5
                options.BarBorderRadius  (1,:) char    = '4px'
                % --- CSS convenience properties ----------------------------
                options.Color               (1,:) char = ''
                options.BackgroundColor     (1,:) char = ''
                options.FontSize            (1,:) char = ''
                options.FontFamily          (1,:) char = ''
                options.FontWeight          (1,:) char = ''
                options.FontStyle           (1,:) char = ''
                options.LetterSpacing       (1,:) char = ''
                options.LineHeight          (1,:) char = ''
                options.TextTransform       (1,:) char = ''
                options.TextDecoration      (1,:) char = ''
                options.HorizontalAlignment (1,:) char = ''
                options.VerticalAlignment   (1,:) char = ''
                options.BorderRadius        (1,:) char = ''
                options.BoxShadow           (1,:) char = ''
                options.InsetShadow         (1,:) char = ''
                options.Opacity             (1,:) char = ''
                options.Cursor              (1,:) char = ''
                options.Padding             (1,:) char = ''
                options.MinWidth            (1,:) char = ''
                options.MinHeight           (1,:) char = ''
                options.MaxWidth            (1,:) char = ''
                options.MaxHeight           (1,:) char = ''
                options.Width               (1,:) char = ''
                options.Height              (1,:) char = ''
                options.OuterPadding        (1,:) char = ''
                options.Border              (1,:) char = ''
                options.AspectRatio         (1,:) char = ''
            end

            if isempty(parent), parent = uifigure('Name','CSSUIProgressBar'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);

            % Structural properties first (no rebuild while Updating_=true)
            obj.TextPosition    = options.TextPosition;
            obj.ShowTicks       = options.ShowTicks;
            obj.NumTicks        = options.NumTicks;

            % Patchable properties
            obj.Value           = options.Value;
            obj.Text            = options.Text;
            obj.LabelColor      = options.LabelColor;
            obj.TickColor       = options.TickColor;
            obj.TickHeight      = options.TickHeight;
            obj.BarHeight       = options.BarHeight;
            obj.BarBorderRadius = options.BarBorderRadius;

            obj.endInit();
        end

        % ------------------------------------------------------------------
        %  Patchable setters — live-update without a page rebuild
        % ------------------------------------------------------------------

        function set.Value(obj, val)
            obj.Value = val;
            if ~obj.Updating_
                obj.pushVar('--progress-pct', sprintf('%.6f', val));
            end
        end

        function set.Text(obj, val)
            obj.Text = val;
            if ~obj.Updating_
                if obj.Loaded_
                    obj.pushCmd(struct('cmd','setText','value',val));
                elseif obj.isReady()
                    obj.refresh();
                end
            end
        end

        function set.LabelColor(obj, val)
            obj.LabelColor = val;
            if ~obj.Updating_
                if isempty(val)
                    obj.pushVar('--label-color', '#333333');
                else
                    obj.pushVar('--label-color', val);
                end
            end
        end

        function set.BarHeight(obj, val)
            obj.BarHeight = val;
            if ~obj.Updating_
                obj.pushVar('--bar-height', sprintf('%.6f', val));
            end
        end

        function set.BarBorderRadius(obj, val)
            obj.BarBorderRadius = val;
            if ~obj.Updating_
                obj.pushVar('--bar-radius', val);
            end
        end

        function set.TickColor(obj, val)
            obj.TickColor = val;
            if ~obj.Updating_
                obj.pushVar('--tick-color', val);
            end
        end

        function set.TickHeight(obj, val)
            obj.TickHeight = val;
            if ~obj.Updating_
                obj.pushVar('--tick-height', sprintf('%.1f%%', val * 100));
            end
        end

        % ------------------------------------------------------------------
        %  Structural setters — require a full page rebuild
        % ------------------------------------------------------------------

        function set.TextPosition(obj, val)
            valid = {'none','above','below','on'};
            if ~ismember(val, valid)
                error('CSSUIProgressBar:invalidTextPosition', ...
                    'TextPosition must be one of: %s', strjoin(valid, ', '));
            end
            obj.TextPosition = val;
            if ~obj.Updating_ && obj.isReady()
                obj.refresh();
            end
        end

        function set.ShowTicks(obj, val)
            obj.ShowTicks = val;
            if ~obj.Updating_ && obj.isReady()
                obj.refresh();
            end
        end

        function set.NumTicks(obj, val)
            obj.NumTicks = val;
            if ~obj.Updating_ && obj.isReady()
                obj.refresh();
            end
        end

    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)

            % ---- Component CSS -------------------------------------------
            css = [ ...
                '#css-root{' ...
                  'display:flex;flex-direction:column;' ...
                  'align-items:stretch;justify-content:center;' ...
                  'width:100%;height:100%;' ...
                  'gap:var(--label-gap,4px);' ...
                '}' ...
                '.css-control{' ...
                  'position:relative;' ...
                  'flex:1;' ...
                  'min-height:4px;' ...
                  'background-color:var(--bg-color,#e0e0e0);' ...
                  'border-radius:var(--border-radius,4px);' ...
                  'overflow:hidden;' ...
                '}' ...
                '.css-bar{' ...
                  'position:absolute;' ...
                  'left:0;top:50%;' ...
                  'transform:translateY(-50%);' ...
                  'width:calc(var(--progress-pct,0)*100%);' ...
                  'height:calc(var(--bar-height,0.5)*100%);' ...
                  'background:var(--color,#0072ff);' ...
                  'border-radius:var(--bar-radius,4px);' ...
                  'transition:width 0.05s linear;' ...
                '}' ...
                '.css-ticks{' ...
                  'position:absolute;' ...
                  'top:0;left:0;right:0;bottom:0;' ...
                  'pointer-events:none;' ...
                '}' ...
                '.css-tick{' ...
                  'position:absolute;top:50%;' ...
                  'transform:translate(-50%,-50%);' ...
                  'width:1px;' ...
                  'height:var(--tick-height,30%);' ...
                  'background:var(--tick-color,rgba(255,255,255,0.6));' ...
                '}' ...
                '.css-label{' ...
                  'text-align:var(--text-align,center);' ...
                  'color:var(--label-color,#333);' ...
                  'font-size:var(--font-size,inherit);' ...
                  'font-family:var(--font-family,inherit);' ...
                  'font-weight:var(--font-weight,inherit);' ...
                  'white-space:nowrap;overflow:hidden;' ...
                  'text-overflow:ellipsis;' ...
                  'pointer-events:none;flex-shrink:0;' ...
                '}' ...
                '.css-label-on{' ...
                  'position:absolute;' ...
                  'top:50%;left:0;right:0;' ...
                  'transform:translateY(-50%);' ...
                  'text-align:center;z-index:1;' ...
                  'pointer-events:none;' ...
                  'text-shadow:0 1px 3px rgba(0,0,0,0.35);' ...
                '}' ...
                ];

            % ---- Label span (reused at most once in the output) ----------
            labelSpan = ['<span id="cssbase-text">' ...
                CSSBase.htmlEscape(obj.Text) '</span>'];

            % ---- Tick marks HTML -----------------------------------------
            ticksHTML = '';
            if obj.ShowTicks
                tHTML = '<div class="css-ticks">';
                for i = 1 : obj.NumTicks + 1
                    pctTick = (i - 1) / obj.NumTicks * 100;
                    tHTML = [tHTML '<div class="css-tick" style="left:' ...
                        sprintf('%.2f', pctTick) '%"></div>']; %#ok<AGROW>
                end
                ticksHTML = [tHTML '</div>'];
            end

            % ---- Bar track + fill ----------------------------------------
            barFill = '<div class="css-bar"></div>';
            if strcmp(obj.TextPosition, 'on')
                onLabel = ['<div class="css-label css-label-on">' ...
                    labelSpan '</div>'];
                trackHTML = ['<div class="css-control">' ...
                    barFill onLabel ticksHTML '</div>'];
            else
                trackHTML = ['<div class="css-control">' ...
                    barFill ticksHTML '</div>'];
            end

            % ---- Full layout based on TextPosition -----------------------
            externalLabel = ['<div class="css-label">' labelSpan '</div>'];
            switch obj.TextPosition
                case 'above'
                    body = [externalLabel trackHTML];
                case 'below'
                    body = [trackHTML externalLabel];
                otherwise  % 'none' or 'on'
                    body = trackHTML;
            end

            html = [ ...
                '<!DOCTYPE html><html><head>' ...
                '<style>' css '</style>' ...
                '</head><body>' ...
                '<div id="css-root">' body '</div>' ...
                '</body></html>' ...
                ];
        end

    end
end
