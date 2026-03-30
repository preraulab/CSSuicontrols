classdef CSSuiButton < CSSBase
    %UIBUTTON  CSS-styled push-button component.
    %
    %   USAGE
    %     btn = uiButton(parent)
    %     btn = uiButton(parent, 'Text','Save', 'Icon','icon.svg', 'IconPosition','left')
    %     btn.IconPosition = 'bottom';   % live update
    %
    %   PROPERTIES
    %     Text              Button label string                     default: 'Button'
    %     Icon              SVG inner-markup or .svg filepath       default: ''
    %     IconPosition      'top','bottom','left','right'           default: 'top'
    %     ButtonPushedFcn   @(src, evt) callback                   default: []

    properties (Access = public)
        Text            = 'Button'
        Icon            = ''
        IconPosition    = 'top'      % New
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
                options.IconPosition    (1,:) char    = 'top'      % New
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
            obj.IconPosition    = options.IconPosition;   % New

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
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            iconHTML = '';
            if ~isempty(obj.Icon)
                iconHTML = sprintf( ...
                    ['<svg viewBox="0 0 24 24" style="width:1.2em;' ...
                    'height:1.2em;fill:currentColor;flex-shrink:0;">%s</svg>'], ...
                    obj.Icon);
            end

            % Determine flex direction
            switch obj.IconPosition
                case 'left',  flexDir = 'row';
                case 'right', flexDir = 'row-reverse';
                case 'top',   flexDir = 'column';
                case 'bottom',flexDir = 'column-reverse';
            end

            css = [ ...
                '#btn{' ...
                'flex:1; min-width:0; border:none; outline:none;' ...
                'display:inline-flex; justify-content:center; align-items:center; gap:8px;' ...
                'flex-direction:' flexDir ';' ...
                'color:var(--color,inherit);' ...
                'background-color:var(--bg-color,transparent);' ...
                'font-size:var(--font-size,13px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'border-radius:var(--border-radius,4px);' ...
                'box-shadow:var(--box-shadow,none);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,pointer);' ...
                'padding:var(--padding,8px 16px);' ...
                'transition: box-shadow 0.15s ease, transform 0.15s ease;' ...   % <-- important
                '}' ...
                ...
                '#btn.css-clickable:hover{' ...
                'transform:translateY(-2px);' ...
                'box-shadow:4px 4px 8px rgba(0,0,0,0.18),-4px -4px 8px rgba(255,255,255,0.9);' ...
                '}' ...
                '#btn.css-clickable:active{' ...
                'transform:translateY(1px);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.18),inset -2px -2px 4px rgba(255,255,255,0.9);' ...
                '}' ...
                ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'document.getElementById("btn").addEventListener("click",function(){' ...
                'if(!document.getElementById("uihb").classList.contains("uihb-disabled"))' ...
                'window.sendEvent({event:"click"});' ...
                '});' ...
                '};' ...
                '</script>' ...
                ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="uihb">' ...
                '<button id="btn" class="css-surface css-clickable">' ...
                iconHTML ...
                '<span id="cssbase-text">' CSSBase.htmlEscape(obj.Text) '</span>' ...
                '</button>' ...
                '</div>' ...
                compJS '</body></html>' ...
                ];
        end
        function onMessage(obj, data)
            if strcmp(data.event, 'click') && obj.Enabled_
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