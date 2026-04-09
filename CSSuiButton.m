classdef CSSuiButton < CSSBase
    %CSSuiButton  CSS-styled push-button backed by uihtml.
    %
    %   USAGE
    %     btn = CSSuiButton(parent)
    %     btn = CSSuiButton(parent, 'Text','Save', 'Icon','icon.svg', 'Style','flat')
    %     btn.Text = 'Updated';          % live patch — no page reload
    %     btn.BackgroundColor = '#e8f5e9';
    %
    %   PROPERTIES
    %     Text              Button label string                     default: 'Button'
    %     Icon              SVG inner-markup string or .svg path    default: ''
    %     IconPosition      'top'|'bottom'|'left'|'right'          default: 'top'
    %     IconSize          CSS size, e.g. '18px' or '1.5em'       default: '1.2em'
    %     Shape             'rectangle'|'square'|'circle'          default: 'rectangle'
    %                       square/circle fill the component as the largest square that fits
    %     IconOnlyWidth     CSS width string, e.g. '60px'          default: ''
    %                       when set and an Icon is present, text is hidden below this width
    %     ButtonPushedFcn   @(src, evt) callback                   default: []
    %
    %   CSS ELEMENT SCHEMA
    %     #css-root           Outer sizing container (CSSBase-managed)
    %     .css-control        The <button> element
    %       #cssbase-text     Span holding the button text (live-patchable)
    %       .css-icon         SVG icon element (when Icon is set)
    %     .css-disabled       On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     btn.CSS = '.css-control { text-transform: uppercase; letter-spacing: 0.1em; }';
    %     btn.CSS = '.css-icon   { fill: #E53935; }';
    %     btn.CSS = '.css-control.css-clickable:hover { transform: none !important; }';

    properties (Access = public)
        Text            = 'Button'
        Icon            = ''
        IconPosition    = 'top'      % 'top' | 'bottom' | 'left' | 'right'
        IconSize        = '1.2em'    % CSS size string, e.g. '18px', '1.5em', '24px'
        Shape           = 'rectangle' % 'rectangle' | 'square' | 'circle'
        IconOnlyWidth   = ''         % CSS width threshold, e.g. '60px' — below this only icon shown
        ButtonPushedFcn = []
    end

    % =====================================================================
    methods
        function obj = CSSuiButton(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 150 40]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = 'shadow'
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Text            (1,:) char    = 'Button'
                options.Icon            (1,:) char    = ''
                options.IconPosition    (1,:) char    = 'top'
                options.IconSize        (1,:) char    = '1.2em'
                options.Shape          (1,:) char    = 'rectangle'
                options.IconOnlyWidth  (1,:) char    = ''
                options.ButtonPushedFcn               = []
                % --- CSS convenience properties (forwarded to CSSBase) ----
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
            end

            if isempty(parent), parent = uifigure('Name','CSSuiButton'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.ButtonPushedFcn = options.ButtonPushedFcn;
            obj.Text            = options.Text;
            obj.IconPosition    = options.IconPosition;
            obj.IconSize        = options.IconSize;
            obj.Shape           = options.Shape;
            obj.IconOnlyWidth   = options.IconOnlyWidth;

            % Resolve icon: filepath --> SVG inner markup
            ic = options.Icon;
            if ~isempty(ic) && isfile(ic)
                raw = fileread(ic);
                ic  = regexprep(raw, '(?si)^.*?<svg[^>]*>(.*)</svg>.*$', '$1');
                ic  = strtrim(ic);
            end
            obj.Icon = ic;

            obj.endInit();
        end

        % --- Patchable: Text ---------------------------------------------
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

        % --- Structural: Icon --------------------------------------------
        function set.Icon(obj, val)
            obj.Icon = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        % --- Structural: IconPosition ------------------------------------
        function set.IconPosition(obj, val)
            validPositions = {'top','bottom','left','right'};
            if ~ismember(val, validPositions)
                error('CSSuiButton:InvalidIconPosition', ...
                    'IconPosition must be one of: top, bottom, left, right');
            end
            obj.IconPosition = val;
            if ~obj.Updating_ && obj.isReady()
                obj.refresh();
            end
        end

        % --- Structural: IconSize ----------------------------------------
        function set.IconSize(obj, val)
            obj.IconSize = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        % --- Structural: IconOnlyWidth -----------------------------------
        function set.IconOnlyWidth(obj, val)
            obj.IconOnlyWidth = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        % --- Structural: Shape -------------------------------------------
        function set.Shape(obj, val)
            valid = {'rectangle','square','circle'};
            if ~ismember(val, valid)
                error('CSSuiButton:InvalidShape', ...
                    'Shape must be one of: rectangle, square, circle');
            end
            obj.Shape = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            iconHTML = '';
            if ~isempty(obj.Icon)
                sz = obj.IconSize;
                if isempty(sz), sz = '1.2em'; end
                iconHTML = sprintf( ...
                    ['<svg viewBox="0 0 24 24" class="css-icon" style="width:%s;' ...
                    'height:%s;fill:currentColor;flex-shrink:0;">%s</svg>'], ...
                    sz, sz, obj.Icon);
            end

            % Determine flex direction
            switch obj.IconPosition
                case 'left',  flexDir = 'row';
                case 'right', flexDir = 'row-reverse';
                case 'top',   flexDir = 'column';
                case 'bottom',flexDir = 'column-reverse';
            end

            % Shape-specific CSS:
            %   rectangle — flex:1 stretches to fill the component (default)
            %   square    — JS sizes button to min(containerW, containerH)
            %   circle    — same as square plus border-radius:50%
            switch obj.Shape
                case 'rectangle'
                    controlSize    = 'flex:1;';
                    rootAlignCSS   = '';
                    shapeRadiusCSS = '';
                    shapeJS        = '';
                case {'square','circle'}
                    % flex:none lets JS control both dimensions freely.
                    % _fit() runs once on load (inside componentSetup, after
                    % layout is settled) and again on every window resize.
                    controlSize  = 'flex:none;';
                    rootAlignCSS = '#css-root{align-items:center;justify-content:center;}';
                    if strcmp(obj.Shape, 'circle')
                        shapeRadiusCSS = '.css-control{border-radius:50%!important;}';
                    else
                        shapeRadiusCSS = '';
                    end
                    shapeJS = [ ...
                        'function _fit(){' ...
                        'var r=document.getElementById("css-root");' ...
                        'var b=document.getElementById("btn");' ...
                        'var s=Math.min(r.clientWidth,r.clientHeight);' ...
                        'if(s>0){b.style.width=s+"px";b.style.height=s+"px";}' ...
                        '}' ...
                        '_fit();' ...
                        'window.addEventListener("resize",_fit);' ...
                        ];
            end

            % For rectangle shape, lock #css-root to always stretch so the
            % button fills its cell height regardless of VerticalAlignment.
            % VerticalAlignment/HorizontalAlignment then control content
            % placement *within* the button via align-items/justify-content
            % on .css-control.
            %   --text-align  stores 'left'|'center'|'right' — valid for
            %                 both CSS text-align AND flex justify-content.
            %   --align-items stores 'flex-start'|'center'|'flex-end'
            %                 (already translated by the VerticalAlignment setter).
            if strcmp(obj.Shape, 'rectangle')
                rootAlignCSS = '#css-root{align-items:stretch;}';
            end

            css = [ ...
                rootAlignCSS ...
                '.css-control{' ...
                controlSize ' min-width:0; border:none; outline:none;' ...
                'display:inline-flex;' ...
                'justify-content:var(--text-align,center);' ...
                'align-items:var(--align-items,center);' ...
                'gap:8px;' ...
                'flex-direction:' flexDir ';' ...
                'color:var(--color,inherit);' ...
                'background-color:var(--bg-color,transparent);' ...
                'font-size:var(--font-size,inherit);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'border-radius:var(--border-radius,4px);' ...
                'box-shadow:var(--box-shadow,none);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,pointer);' ...
                'padding:var(--padding,8px 16px);' ...
                'transition: box-shadow 0.15s ease, transform 0.15s ease;' ...
                '}' ...
                shapeRadiusCSS ...
                '.css-control.css-clickable:hover{' ...
                'transform:translateY(-2px);' ...
                'box-shadow:4px 4px 8px rgba(0,0,0,0.18),-4px -4px 8px rgba(255,255,255,0.9);' ...
                '}' ...
                '.css-control.css-clickable:active{' ...
                'transform:translateY(1px);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.18),inset -2px -2px 4px rgba(255,255,255,0.9);' ...
                '}' ...
                obj.iconOnlyCSS() ...
                ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'document.getElementById("btn").addEventListener("click",function(){' ...
                'if(!document.getElementById("css-root").classList.contains("css-disabled"))' ...
                'window.sendEvent({event:"click"});' ...
                '});' ...
                shapeJS ...
                '};' ...
                '</script>' ...
                ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root">' ...
                '<button id="btn" class="css-surface css-clickable css-control">' ...
                iconHTML ...
                '<span id="cssbase-text">' CSSBase.htmlEscape(obj.Text) '</span>' ...
                '</button>' ...
                '</div>' ...
                compJS '</body></html>' ...
                ];
        end
        function s = iconOnlyCSS(obj)
            % Returns a @media block that hides text below IconOnlyWidth.
            % Only emitted when both IconOnlyWidth and Icon are non-empty.
            if isempty(obj.IconOnlyWidth) || isempty(obj.Icon)
                s = '';
                return;
            end
            s = [ ...
                '@media(max-width:' obj.IconOnlyWidth '){' ...
                '#cssbase-text{display:none;}' ...
                '.css-control{padding:var(--padding,8px);}' ...
                '}' ...
                ];
        end

        function onMessage(obj, data)
            if strcmp(data.event, 'click') & obj.Enabled_
                if ~isempty(obj.ButtonPushedFcn)
                    try
                        obj.ButtonPushedFcn(obj, ...
                            struct('Source', obj, 'EventName', 'ButtonPushed'));
                    catch ME
                        warning('uiButton:callbackError', '%s', ME.message);
                    end
                end
            end
        end

    end
end