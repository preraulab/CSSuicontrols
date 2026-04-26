classdef CSSuiCheckbox < CSSBase
    %CSSUICHECKBOX  CSS-styled custom checkbox backed by uihtml
    %
    %   Usage:
    %       cb = CSSuiCheckbox(parent, 'Text', 'Enable feature', 'Value', true)
    %       cb.ValueChangedFcn = @(s,e) fprintf('State: %d\n', e.Value);
    %
    %   Inputs:
    %       parent : graphics container -- required
    %
    %   Name-Value Pairs:
    %       'Value'           : logical - true = checked (default: false)
    %       'Text'            : char - label beside the checkbox (default: 'Checkbox')
    %       'CheckOnColor'    : char - CSS color when checked (default: '#A2D2FF')
    %       'BoxSize'         : char - CSS size of the box (default: '18px')
    %       'ValueChangedFcn' : function handle - @(src, evt) callback (default: [])
    %       (plus all CSSBase name-value pairs)
    %
    %   Outputs:
    %       cb : CSSuiCheckbox handle
    %
    %   Notes:
    %       Visual style is adapted from the W3Schools custom-checkbox pattern
    %       (https://www.w3schools.com/howto/howto_css_custom_checkbox.asp).
    %
    %       CSS element schema:
    %           #css-root                  Outer sizing container
    %             label.css-control        Wrapping label (clickable area)
    %               input#chk              Hidden <input type="checkbox">
    %               span.checkmark         Custom-styled box with tick
    %               span.css-label#cssbase-text  Text label
    %           .css-disabled              On #css-root when Enabled=false
    %
    %   See also: CSSBase, CSSPreset, CSSuiSwitch, CSSuiRadioGroup
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿

    properties (Access = public)
        Text            = 'Checkbox'
        CheckOnColor    = '#A2D2FF'
        BoxSize         = '18px'
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
        function obj = CSSuiCheckbox(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 160 28]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Value           (1,1) logical = false
                options.Text            (1,:) char    = 'Checkbox'
                options.CheckOnColor    (1,:) char    = '#A2D2FF'
                options.BoxSize         (1,:) char    = '18px'
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

            if isempty(parent), parent = uifigure('Name','CSSuiCheckbox'); end
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
            obj.CheckOnColor    = options.CheckOnColor;
            obj.BoxSize         = options.BoxSize;
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

        % --- CheckOnColor (structural) -----------------------------------
        function set.CheckOnColor(obj, val)
            obj.CheckOnColor = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        % --- BoxSize (structural) ----------------------------------------
        function set.BoxSize(obj, val)
            obj.BoxSize = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            checkedStr = '';
            if obj.Value_, checkedStr = ' checked'; end

            % Visual style adapted from W3Schools custom-checkbox.
            % Sized via --box-size; on-color via --check-on. Hidden native
            % input + .checkmark span pattern with a rotated-border tick.
            css = [ ...
                ':root{--check-on:' obj.CheckOnColor ';--box-size:' obj.BoxSize ';}' ...
                '#css-root{display:flex;overflow:visible;' ...
                'justify-content:var(--text-align,flex-start);' ...
                'align-items:var(--align-items,center);' ...
                'gap:10px;padding:0 5px;cursor:var(--cursor,pointer);}' ...
                '.css-control{position:relative;display:inline-flex;' ...
                'align-items:center;gap:10px;cursor:pointer;' ...
                '-webkit-user-select:none;user-select:none;' ...
                'color:var(--color,inherit);' ...
                'font-size:var(--font-size,inherit);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);}' ...
                '.css-control input{position:absolute;opacity:0;' ...
                'width:0;height:0;cursor:pointer;}' ...
                '.checkmark{position:relative;display:inline-block;' ...
                'width:var(--box-size,18px);height:var(--box-size,18px);' ...
                'background:var(--bg-color,#e0e0e0);' ...
                'border-radius:var(--border-radius,4px);' ...
                'flex-shrink:0;transition:0.2s;' ...
                'box-shadow:inset 2px 2px 4px #bcbcbc,inset -2px -2px 4px #fff;}' ...
                '.css-control:hover input ~ .checkmark{' ...
                'background:var(--bg-hover,#ccc);}' ...
                '.css-control input:checked ~ .checkmark{' ...
                'background:var(--check-on,#A2D2FF);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.1);}' ...
                '.checkmark::after{content:"";position:absolute;display:none;' ...
                'left:35%;top:15%;width:25%;height:55%;' ...
                'border:solid #fff;border-width:0 2px 2px 0;' ...
                'transform:rotate(45deg);' ...
                '-webkit-transform:rotate(45deg);}' ...
                '.css-control input:checked ~ .checkmark::after{display:block;}' ...
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
                '<span class="checkmark"></span>' ...
                '<span class="css-label" id="cssbase-text">' CSSBase.htmlEscape(obj.Text) '</span>' ...
                '</label>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            if strcmp(data.event, 'toggle') && obj.Enabled_
                oldVal = obj.Value_;
                obj.Value_ = logical(data.value);
                if ~isempty(obj.ValueChangedFcn)
                    evt = struct('Source',obj, ...
                        'Value',obj.Value_,'PreviousValue',oldVal);
                    try
                        if iscell(obj.ValueChangedFcn)
                            fn = obj.ValueChangedFcn{1};
                            fn(obj, evt, obj.ValueChangedFcn{2:end});
                        else
                            obj.ValueChangedFcn(obj, evt);
                        end
                    catch ME
                        warning('uiCheckbox:callbackError','%s',ME.message);
                    end
                end
            end
        end

    end

end
