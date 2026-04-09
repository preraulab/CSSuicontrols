classdef CSSuiTextArea < CSSBase
    %CSSuiTextArea  CSS-styled multiline text area backed by uihtml.
    %
    %   USAGE
    %     ta = CSSuiTextArea(parent, 'Placeholder','Enter notes...')
    %     ta = CSSuiTextArea(parent, 'Value','hello', 'Style','shadow')
    %     ta.ValueChangedFcn  = @(s,e) disp(e.Value);
    %     ta.ValueChangingFcn = @(s,e) disp(e.Value);
    %
    %   PROPERTIES
    %     Value             Text content                            default: ''
    %     Placeholder       Hint text when empty                    default: ''
    %     Label             Header label (above the text area)      default: ''
    %     Editable          false = read-only                       default: true
    %     ValueChangedFcn   @(src,evt) on blur                      default: []
    %     ValueChangingFcn  @(src,evt) on every keystroke           default: []
    %
    %   CSS ELEMENT SCHEMA
    %     #css-root               Outer sizing container (CSSBase-managed)
    %       .css-label            Header label div (when Label is set)
    %       textarea#ta.css-control  The <textarea> element (IS the surface)
    %     .css-disabled           On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     ta.CSS = '.css-control { line-height: 1.6; font-family: monospace; }';
    %     ta.CSS = '.css-label   { font-weight: 700; color: #333; }';

    properties (Access = public)
        Placeholder     = ''
        Label           = ''
        Editable        = true
        ValueChangedFcn = []
        ValueChangingFcn = []
    end

    properties (Dependent)
        Value
    end

    properties (Access = protected)
        Value_     = ''
        CommitVal_ = ''
    end

    % =====================================================================
    methods
        function obj = CSSuiTextArea(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 250 120]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Value                 char    = ''
                options.Placeholder     (1,:) char    = ''
                options.Label           (1,:) char    = ''
                options.Editable        (1,1) logical = true
                options.ValueChangedFcn               = []
                options.ValueChangingFcn              = []
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

            if isempty(parent), parent = uifigure('Name','CSSuiTextArea'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.Value_           = options.Value;
            obj.CommitVal_       = options.Value;
            obj.Placeholder      = options.Placeholder;
            obj.Label            = options.Label;
            obj.Editable         = options.Editable;
            obj.ValueChangedFcn  = options.ValueChangedFcn;
            obj.ValueChangingFcn = options.ValueChangingFcn;

            obj.endInit();
        end

        % --- Value (patchable) -------------------------------------------
        function val = get.Value(obj), val = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_     = val;
            obj.CommitVal_ = val;
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue','value',val));
            end
        end

        % --- Structural properties ---------------------------------------
        function set.Placeholder(obj, val)
            obj.Placeholder = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.Label(obj, val)
            obj.Label = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.Editable(obj, val)
            obj.Editable = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            roAttr = '';
            if ~obj.Editable, roAttr = ' readonly'; end

            labelHTML = '';
            if ~isempty(strtrim(obj.Label))
                labelHTML = sprintf( ...
                    '<div class="css-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end

            % Global reset and html/body base are provided by CSSBase infraCSS.
            css = [ ...
                'html,body{display:flex;flex-direction:column;}' ...
                '#css-root{display:flex;flex-direction:column;width:100%;height:100%;' ...
                'gap:4px;padding:4px 6px;}' ...
                '.css-label{color:var(--color,inherit);font-size:var(--font-size,12px);font-weight:var(--font-weight,500);' ...
                'white-space:nowrap;user-select:none;flex-shrink:0;' ...
                'font-family:var(--font-family,inherit);}' ...
                '.css-control{flex:1;width:100%;resize:none;border:none;outline:none;' ...
                'color:var(--color,inherit);' ...
                'background-color:var(--bg-color,#e0e0e0);' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,normal);' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,text);' ...
                'padding:var(--padding,8px 12px);' ...
                'text-align:var(--text-align,left);}' ...
                '.css-control:read-only{cursor:default;opacity:0.7;}' ...
                '.css-disabled .css-control{opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
            ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var ta=document.getElementById("ta");' ...
                'ta.addEventListener("input",function(){' ...
                'window.sendEvent({event:"input",value:ta.value});});' ...
                'ta.addEventListener("blur",function(){' ...
                'window.sendEvent({event:"commit",value:ta.value});});' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue")document.getElementById("ta").value=cmd.value;' ...
                '};' ...
                '</script>' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root">' ...
                labelHTML ...
                '<textarea id="ta" class="css-surface css-control" placeholder="' CSSBase.attrEscape(obj.Placeholder) '"' ...
                roAttr '>' CSSBase.htmlEscape(obj.Value_) '</textarea>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            switch data.event
                case 'ready'
                    if ~isempty(obj.Value_)
                        obj.pushCmd(struct('cmd','setValue','value',obj.Value_));
                    end
                case 'input'
                    if obj.Enabled_
                        obj.Value_ = data.value;
                        if ~isempty(obj.ValueChangingFcn)
                            evt = struct('Source',obj,'Value',data.value);
                            try, obj.ValueChangingFcn(obj,evt);
                            catch ME, warning('uiTextArea:changingError','%s',ME.message); end
                        end
                    end
                case 'commit'
                    if obj.Enabled_
                        oldVal         = obj.CommitVal_;
                        obj.Value_     = data.value;
                        obj.CommitVal_ = data.value;
                        if ~isempty(obj.ValueChangedFcn)
                            evt = struct('Source',obj,'Value',data.value,'PreviousValue',oldVal);
                            try, obj.ValueChangedFcn(obj,evt);
                            catch ME, warning('uiTextArea:changedError','%s',ME.message); end
                        end
                    end
            end
        end

    end

end
