classdef CSSuiButton < CSSBase
    %CSSuiButton  CSS-styled push-button backed by uihtml.
    %
    %   USAGE
    %     btn = CSSuiButton(parent)
    %     btn = CSSuiButton(parent, 'Text','Save', 'Icon','icon.svg', 'Style','flat')
    %     btn = CSSuiButton(parent, 'Text','Go',   'Icon','anim.gif')
    %     btn = CSSuiButton(parent, 'Text','Next', 'Icon','M5 12h14M12 5l7 7-7 7')
    %     btn.Text = 'Updated';          % live patch — no page reload
    %     btn.BackgroundColor = '#e8f5e9';
    %
    %   PROPERTIES
    %     Text              Button label string                     default: 'Button'
    %     Icon              One of:
    %                         • SVG inner-markup string  e.g. '<path d="M5 12h14"/>'
    %                         • SVG path data string     e.g. 'M5 12h14M12 5l7 7-7 7'
    %                         • Path to .svg file        (inlined as markup)
    %                         • Path to raster file      (.png .jpg .jpeg .gif .webp .bmp .ico)
    %                         • Base64 data URI          'data:image/...;base64,...'
    %                       default: ''
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
    %       .css-icon         SVG or <img> icon element (when Icon is set)
    %     .css-disabled       On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     btn.CSS = '.css-control { text-transform: uppercase; letter-spacing: 0.1em; }';
    %     btn.CSS = '.css-icon   { fill: #E53935; }';   % only affects inline SVG icons
    %     btn.CSS = '.css-control.css-clickable:hover { transform: none !important; }';

    properties (Access = public)
        Text            = 'Button'
        Icon            = ''
        IconPosition    = 'top'       % 'top' | 'bottom' | 'left' | 'right'
        IconSize        = '1.2em'     % CSS size string, e.g. '18px', '1.5em', '24px'
        Shape           = 'rectangle' % 'rectangle' | 'square' | 'circle'
        IconOnlyWidth   = ''          % CSS width threshold — below this only icon shown
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
                options.Shape           (1,:) char    = 'rectangle'
                options.IconOnlyWidth   (1,:) char    = ''
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
            obj.Icon            = CSSuiButton.resolveIcon(options.Icon);

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
            obj.Icon = CSSuiButton.resolveIcon(val);
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
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
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
            iconHTML = obj.buildIconHTML();

            % Determine flex direction
            switch obj.IconPosition
                case 'left',   flexDir = 'row';
                case 'right',  flexDir = 'row-reverse';
                case 'top',    flexDir = 'column';
                case 'bottom', flexDir = 'column-reverse';
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

        % -----------------------------------------------------------------
        function html = buildIconHTML(obj)
            %buildIconHTML  Emit the correct HTML element for whatever Icon holds.
            %
            %   Icon storage format (set by resolveIcon):
            %     ''                  — no icon
            %     'data:...'          — raster base64 data URI  → <img>
            %     '<...'  or contains '<'  — raw SVG inner markup  → <svg>
            %     anything else       — treated as SVG path data  → <svg><path>

            html = '';
            ic   = obj.Icon;
            if isempty(ic), return; end

            sz = obj.IconSize;
            if isempty(sz), sz = '1.2em'; end

            baseImgStyle = ['width:' sz ';height:' sz ';flex-shrink:0;object-fit:contain;'];
            baseSvgStyle = ['width:' sz ';height:' sz ';fill:currentColor;flex-shrink:0;'];

            if strncmp(ic, 'data:', 5)
                % ── Raster / animated image embedded as base64 data URI ──
                html = sprintf( ...
                    '<img src="%s" class="css-icon" style="%s" alt="">', ...
                    ic, baseImgStyle);

            elseif contains(ic, '<')
                % ── Raw SVG inner markup (may include <path>, <circle>, etc.) ──
                html = sprintf( ...
                    '<svg viewBox="0 0 24 24" class="css-icon" style="%s">%s</svg>', ...
                    baseSvgStyle, ic);

            else
                % ── Plain SVG path-data string, e.g. 'M5 12h14M12 5l7 7-7 7' ──
                html = sprintf( ...
                    '<svg viewBox="0 0 24 24" class="css-icon" style="%s"><path d="%s"/></svg>', ...
                    baseSvgStyle, ic);
            end
        end

        % -----------------------------------------------------------------
        function s = iconOnlyCSS(obj)
            %iconOnlyCSS  @media block that hides text below IconOnlyWidth.
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

        % -----------------------------------------------------------------
        function onMessage(obj, data)
            if strcmp(data.event, 'click') & obj.Enabled_
                if ~isempty(obj.ButtonPushedFcn)
                    try
                        obj.ButtonPushedFcn(obj, ...
                            struct('Source', obj, 'EventName', 'ButtonPushed'));
                    catch ME
                        warning('CSSuiButton:callbackError', '%s', ME.message);
                    end
                end
            end
        end

    end

    % =====================================================================
    methods (Static, Access = private)

        function ic = resolveIcon(raw)
            %resolveIcon  Normalise any icon input to a canonical storage string.
            %
            %   Input                         Stored as
            %   ──────────────────────────    ──────────────────────────────────
            %   ''                            ''
            %   'data:...'  (already a URI)   unchanged
            %   path to .svg file             SVG inner markup (tags stripped)
            %   path to raster file           'data:<mime>;base64,<b64>'
            %   string containing '<'         treated as raw SVG markup, unchanged
            %   any other string              treated as SVG path data, unchanged

            ic = raw;
            if isempty(ic), return; end

            % Already a data URI — nothing to do.
            if strncmp(ic, 'data:', 5), return; end

            % File path?
            if isfile(ic)
                [~, ~, ext] = fileparts(ic);
                ext = lower(ext);

                if strcmp(ext, '.svg')
                    % Inline the SVG: strip outer <svg>…</svg> wrapper,
                    % keep only the inner markup so we control viewBox/size.
                    raw_text = fileread(ic);
                    ic = regexprep(raw_text, ...
                        '(?si)^.*?<svg[^>]*>(.*)</svg>.*$', '$1');
                    ic = strtrim(ic);
                    return;
                end

                % Raster / animated formats → base64 data URI.
                mime = CSSuiButton.extToMime(ext);
                fid  = fopen(ic, 'rb');
                if fid == -1
                    warning('CSSuiButton:iconReadError', ...
                        'Cannot open icon file: %s', ic);
                    ic = '';
                    return;
                end
                bytes = fread(fid, '*uint8');
                fclose(fid);
                b64 = matlab.net.base64encode(bytes);
                ic  = ['data:' mime ';base64,' b64];
                return;
            end

            % Not a file path — treat as inline SVG markup or path data;
            % leave unchanged (buildIconHTML distinguishes via '<').
        end

        % -----------------------------------------------------------------
        function mime = extToMime(ext)
            %extToMime  Map a lowercase file extension to a MIME type string.
            switch ext
                case '.gif',             mime = 'image/gif';
                case {'.jpg','.jpeg'},   mime = 'image/jpeg';
                case '.png',             mime = 'image/png';
                case '.webp',            mime = 'image/webp';
                case '.bmp',             mime = 'image/bmp';
                case '.ico',             mime = 'image/x-icon';
                case '.tiff',            mime = 'image/tiff';
                case '.avif',            mime = 'image/avif';
                case '.svg',             mime = 'image/svg+xml';  % fallback only
                otherwise
                    warning('CSSuiButton:unknownMime', ...
                        'Unknown icon extension "%s", using application/octet-stream', ext);
                    mime = 'application/octet-stream';
            end
        end

    end
end