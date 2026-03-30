classdef uiButton < CSSBase
%UIBUTTON  CSS-styled push-button component.
%
%   USAGE
%     btn = uiButton(parent)
%     btn = uiButton(parent, 'Text','Save', 'Style','shadow')
%     btn.ButtonPushedFcn = @(s,e) disp('clicked');
%     btn.Text = 'Cancel';          % live-patches without full rebuild
%
%   PROPERTIES
%     Text              Button label string                     default: 'Button'
%     Icon              SVG inner-markup or .svg filepath       default: ''
%     ButtonPushedFcn   @(src, evt) callback                   default: []

    properties (Access = public)
        Text            = 'Button'
        Icon            = ''
        ButtonPushedFcn = []
    end

    % =====================================================================
    methods
        function obj = uiButton(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 150 40]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Text            (1,:) char    = 'Button'
                options.Icon            (1,:) char    = ''
                options.ButtonPushedFcn               = []
            end

            if isempty(parent), parent = uifigure('Name','uiButton'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.ButtonPushedFcn = options.ButtonPushedFcn;

            % Resolve icon: filepath --> SVG inner markup
            ic = options.Icon;
            if ~isempty(ic) && isfile(ic)
                raw = fileread(ic);
                ic  = regexprep(raw, '(?si)^.*?<svg[^>]*>(.*)</svg>.*$', '$1');
                ic  = strtrim(ic);
            end
            obj.Icon = ic;
            obj.Text = options.Text;

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

            % #uihb is the sizing container (owned by CSSBase infra CSS).
            % #btn  is the actual interactive button that fills #uihb.
            css = [ ...
                '#btn{' ...
                'flex:1;min-width:0;' ...
                'border:none;outline:none;' ...
                'display:inline-flex;justify-content:center;align-items:center;gap:6px;' ...
                'color:var(--color,inherit);' ...
                'background-color:var(--bg-color,transparent);' ...
                'font-size:var(--font-size,13px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'border-radius:var(--border-radius,4px);' ...
                'box-shadow:var(--box-shadow,none);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,pointer);' ...
                'padding:var(--padding,6px 16px);}' ...
            ];
            % Note: global CSS reset and html/body base styles are injected
            % by CSSBase.assembleHTML (infraCSS) — no need to repeat them here.

            % setText is handled by the CSSBase bridge targeting id="cssbase-text".
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
