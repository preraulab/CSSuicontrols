classdef CSSuiSwitch < CSSBase
    %CSSuiSwitch  CSS-styled toggle switch backed by uihtml.
    %
    %   USAGE
    %     sw = CSSuiSwitch(parent, 'Text','Notifications', 'Value',true)
    %     sw = CSSuiSwitch(parent, 'Style','shadow')
    %     sw.ValueChangedFcn = @(s,e) fprintf('State: %d\n', e.Value);
    %
    %   PROPERTIES
    %     Value             Logical (true = on)                     default: false
    %     Text              Label string beside the toggle          default: 'Toggle'
    %     SwitchOnColor     Track colour when on (CSS colour str)   default: '#A2D2FF'
    %     ValueChangedFcn   @(src, evt) callback                   default: []
    %
    %   CSS ELEMENT SCHEMA
    %     #css-root               Outer sizing container (CSSBase-managed)
    %       label.css-control     Toggle track wrapper (contains the checkbox)
    %         input#chk           Hidden <input type="checkbox">
    %         span.slider         Animated thumb / track fill
    %       span.css-label#cssbase-text  Text label beside the toggle (live-patchable)
    %     .css-disabled           On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     sw.CSS = '.slider { border-radius: 4px; }';      % square toggle
    %     sw.CSS = '.css-label { font-weight: 700; }';

    properties (Access = public)
        Text            = 'Toggle'
        SwitchOnColor   = '#A2D2FF'   % --switch-on  (track colour when ON)
        ValueChangedFcn = []
    end

    properties (Dependent)
        Value
    end

    properties (Access = protected)
        Value_ = false
    end

    % =====================================================================
    methods
        function obj = CSSuiSwitch(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 160 36]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Value           (1,1) logical = false
                options.Text            (1,:) char    = 'Toggle'
                options.SwitchOnColor   (1,:) char    = '#A2D2FF'
                options.ValueChangedFcn               = []
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
                options.AspectRatio         (1,:) char = ''
            end

            if isempty(parent), parent = uifigure('Name','CSSuiSwitch'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.Value_          = options.Value;
            obj.Text            = options.Text;
            obj.SwitchOnColor   = options.SwitchOnColor;
            obj.ValueChangedFcn = options.ValueChangedFcn;

            obj.endInit();
        end

        % --- Value (patchable) -------------------------------------------
        function val = get.Value(obj), val = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_ = logical(val);
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue','value',obj.Value_));
            end
        end

        % --- Text (structural) -------------------------------------------
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

        % --- SwitchOnColor (structural) ----------------------------------
        function set.SwitchOnColor(obj, val)
            obj.SwitchOnColor = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            checkedStr = '';
            if obj.Value_, checkedStr = ' checked'; end

            % Global reset and html/body base are provided by CSSBase infraCSS.
            % The switch uses --switch-on for the ON-state track colour.
            % setText is handled by the CSSBase bridge targeting id="cssbase-text".
            css = [ ...
                ':root{--switch-on:' obj.SwitchOnColor ';}' ...
                '#css-root{display:flex;overflow:visible;' ...
                'justify-content:var(--text-align,flex-start);' ...
                'align-items:var(--align-items,center);' ...
                'gap:12px;padding:0 5px;cursor:var(--cursor,pointer);}' ...
                '.css-control{position:relative;display:inline-block;' ...
                'width:44px;height:22px;flex-shrink:0;}' ...
                '.css-control input{opacity:0;width:0;height:0;}' ...
                '.slider{position:absolute;cursor:pointer;inset:0;' ...
                'background:var(--bg-color,#e0e0e0);border-radius:22px;' ...
                'transition:0.3s;' ...
                'box-shadow:inset 2px 2px 4px #bcbcbc,inset -2px -2px 4px #fff;}' ...
                '.slider::before{position:absolute;content:"";width:16px;height:16px;' ...
                'left:3px;bottom:3px;background:#fff;border-radius:50%;' ...
                'transition:0.25s;box-shadow:1px 1px 3px rgba(0,0,0,0.2);}' ...
                'input:checked+.slider{background:var(--switch-on,#A2D2FF);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.1);}' ...
                'input:checked+.slider::before{transform:translateX(22px);}' ...
                '.css-label{color:var(--color,inherit);' ...
                'font-size:var(--font-size,inherit);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'white-space:nowrap;overflow:visible;flex-shrink:0;}' ...
            ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var chk=document.getElementById("chk");' ...
                'chk.addEventListener("change",function(){' ...
                'window.sendEvent({event:"toggle",value:chk.checked});});' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue")document.getElementById("chk").checked=cmd.value;' ...
                '};' ...
                '</script>' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root" class="css-surface">' ...
                '<label class="css-control">' ...
                '<input type="checkbox" id="chk"' checkedStr '>' ...
                '<span class="slider"></span>' ...
                '</label>' ...
                '<span class="css-label" id="cssbase-text">' CSSBase.htmlEscape(obj.Text) '</span>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            if strcmp(data.event, 'toggle') && obj.Enabled_
                obj.Value_ = logical(data.value);
                if ~isempty(obj.ValueChangedFcn)
                    evt = struct('Source',obj,'Value',obj.Value_);
                    try
                        obj.ValueChangedFcn(obj, evt);
                    catch ME
                        warning('uiSwitch:callbackError','%s',ME.message);
                    end
                end
            end
        end

    end

end
