classdef uiDropdown < CSSBase
%UIDROPDOWN  CSS-styled dropdown/select component.
%
%   USAGE
%     dd = uiDropdown(parent, 'Items',{'A','B','C'})
%     dd = uiDropdown(parent, 'Items',{'X','Y'}, 'Style','shadow')
%     dd.ValueChangedFcn = @(s,e) disp(e.Value);
%     dd.Value = 'B';               % live-patches without rebuild
%
%   PROPERTIES
%     Items             Cell array of option strings            default: {'Option 1','Option 2'}
%     Value             Currently selected string               default: Items{1}
%     Label             Adjacent text label                     default: ''
%     LabelSide         'left' | 'right'                        default: 'left'
%     ValueChangedFcn   @(src, evt) callback                    default: []

    properties (Access = public)
        ValueChangedFcn = []
        Label           = ''
        LabelSide       = 'left'
    end

    properties (Dependent)
        Items
        Value
    end

    properties (Access = protected)
        Items_ = {'Option 1', 'Option 2'}
        Value_ = ''
    end

    % =====================================================================
    methods
        function obj = uiDropdown(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 200 36]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Items           (1,:) cell    = {'Option 1','Option 2'}
                options.Value           (1,:) char    = ''
                options.Label           (1,:) char    = ''
                options.LabelSide       (1,:) char    = 'left'
                options.ValueChangedFcn               = []
            end

            if isempty(parent), parent = uifigure('Name','uiDropdown'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.ValueChangedFcn = options.ValueChangedFcn;
            obj.Label           = options.Label;
            obj.LabelSide       = options.LabelSide;
            obj.Items_          = options.Items;

            if isempty(options.Value) && ~isempty(options.Items)
                obj.Value_ = options.Items{1};
            else
                obj.Value_ = options.Value;
            end

            obj.endInit();
        end

        % --- Items (structural — rebuild) --------------------------------
        function set.Items(obj, val)
            obj.Items_ = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function val = get.Items(obj), val = obj.Items_; end

        % --- Value (patchable) -------------------------------------------
        function set.Value(obj, val)
            obj.Value_ = val;
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue','value',val));
            end
        end
        function val = get.Value(obj), val = obj.Value_; end

        % --- Label / LabelSide (structural) ------------------------------
        function set.Label(obj, val)
            obj.Label = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.LabelSide(obj, val)
            obj.LabelSide = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            % Build <option> elements
            optsHTML = '';
            for i = 1:numel(obj.Items_)
                it  = char(obj.Items_{i});
                sel = '';
                if strcmp(it, char(obj.Value_)), sel = ' selected'; end
                optsHTML = [optsHTML sprintf('<option value="%s"%s>%s</option>', ...
                    CSSBase.attrEscape(it), sel, CSSBase.htmlEscape(it))]; %#ok<AGROW>
            end

            % Label HTML
            labelHTML = '';
            if ~isempty(strtrim(obj.Label))
                labelHTML = sprintf('<div class="dd-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end
            if strcmp(obj.LabelSide, 'right')
                labelAlign = 'left';
            else
                labelAlign = 'right';
            end

            % Global reset is provided by CSSBase infraCSS.
            % overflow:visible is needed so the native select menu can escape the uihtml bounds.
            css = [ ...
                'html,body{overflow:visible;display:flex;align-items:center;' ...
                'gap:8px;padding:4px 6px;font-family:var(--font-family,inherit);}' ...
                '#uihb{display:contents;}' ...
                '.dd-label{color:var(--color,inherit);font-size:12px;font-weight:600;' ...
                'white-space:nowrap;flex-shrink:0;text-align:' labelAlign ';user-select:none;}' ...
                '.dd-wrap{position:relative;flex:1 1 0;min-width:0;}' ...
                'select{width:100%;padding:7px 28px 7px 12px;border:none;outline:none;' ...
                'color:var(--color,#5f7080);' ...
                'background-color:var(--bg-color,#e0e0e0);' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,500);' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,pointer);' ...
                'appearance:none;-webkit-appearance:none;}' ...
                '.dd-wrap::after{content:"\25BC";position:absolute;right:10px;' ...
                'top:50%;transform:translateY(-50%);font-size:9px;' ...
                'color:var(--color,#5f7080);pointer-events:none;}' ...
                '.uihb-disabled select{opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
            ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var sel=document.getElementById("sel");' ...
                'sel.addEventListener("change",function(){' ...
                'window.sendEvent({event:"change",value:sel.value});});' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue"){' ...
                'document.getElementById("sel").value=cmd.value;}' ...
                '};' ...
                '</script>' ...
            ];

            dropHTML = sprintf( ...
                '<div class="dd-wrap css-surface"><select id="sel">%s</select></div>', optsHTML);

            if strcmp(obj.LabelSide, 'right')
                body = [dropHTML labelHTML];
            else
                body = [labelHTML dropHTML];
            end

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="uihb">' body '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            switch data.event
                case 'ready'
                    % Push initial value after component JS is wired
                    obj.pushCmd(struct('cmd','setValue','value',obj.Value_));
                case 'change'
                    if obj.Enabled_
                        oldVal     = obj.Value_;
                        obj.Value_ = data.value;
                        if ~isempty(obj.ValueChangedFcn)
                            evt = struct('Source',obj, ...
                                'Value',data.value, 'PreviousValue',oldVal);
                            try
                                obj.ValueChangedFcn(obj, evt);
                            catch ME
                                warning('uiDropdown:callbackError','%s',ME.message);
                            end
                        end
                    end
            end
        end

    end

end
