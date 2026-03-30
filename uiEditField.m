classdef uiEditField < CSSBase
%UIEDITFIELD  CSS-styled single-line text edit field.
%
%   USAGE
%     ef = uiEditField(parent, 'Placeholder','Enter name...')
%     ef = uiEditField(parent, 'Value','hello', 'Style','shadow')
%     ef.ValueChangedFcn = @(s,e) disp(e.Value);
%
%   PROPERTIES
%     Value             Text content                            default: ''
%     Placeholder       Hint text when empty                    default: ''
%     Label             Adjacent text label                     default: ''
%     LabelSide         'left' | 'right'                        default: 'left'
%     Editable          false = read-only                       default: true
%     ValueChangedFcn   @(src,evt) on Enter / focus-out         default: []
%     ValueChangingFcn  @(src,evt) on every keystroke           default: []

    properties (Access = public)
        Placeholder      = ''
        Label            = ''
        LabelSide        = 'left'
        Editable         = true
        ValueChangedFcn  = []
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
        function obj = uiEditField(parent, options)
            arguments
                parent = []
                options.Position         (1,4) double  = [10 10 200 36]
                options.Enabled          (1,1) logical = true
                options.TempDir          (1,:) char    = tempdir()
                options.Style                          = ''
                options.CSS              (1,:) char    = ''
                options.CSSFile          (1,:) char    = ''
                options.Value            (1,:) char    = ''
                options.Placeholder      (1,:) char    = ''
                options.Label            (1,:) char    = ''
                options.LabelSide        (1,:) char    = 'left'
                options.Editable         (1,1) logical = true
                options.ValueChangedFcn                = []
                options.ValueChangingFcn               = []
            end

            if isempty(parent), parent = uifigure('Name','uiEditField'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.Value_           = options.Value;
            obj.CommitVal_       = options.Value;
            obj.Placeholder      = options.Placeholder;
            obj.Label            = options.Label;
            obj.LabelSide        = options.LabelSide;
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
        function set.LabelSide(obj, val)
            obj.LabelSide = val;
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
                labelHTML = sprintf('<div class="ef-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end
            if strcmp(obj.LabelSide,'right'), labelAlign='left';
            else,                            labelAlign='right'; end

            % Global reset is provided by CSSBase infraCSS.
            % overflow:visible is needed so focus rings aren't clipped.
            css = [ ...
                'html,body{overflow:visible;display:flex;align-items:center;' ...
                'gap:8px;padding:4px 6px;font-family:var(--font-family,inherit);}' ...
                '#uihb{display:contents;}' ...
                '.ef-label{color:var(--color,inherit);font-size:12px;font-weight:600;' ...
                'white-space:nowrap;flex-shrink:0;text-align:' labelAlign ';user-select:none;}' ...
                '.ef-wrap{flex:1 1 0;min-width:0;}' ...
                'input{width:100%;padding:7px 12px;border:none;outline:none;' ...
                'color:var(--color,#5f7080);' ...
                'background-color:var(--bg-color,#e0e0e0);' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,normal);' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,text);}' ...
                'input:read-only{cursor:default;opacity:0.7;}' ...
                '.uihb-disabled input{opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
            ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var inp=document.getElementById("inp");' ...
                'inp.addEventListener("input",function(){' ...
                'window.sendEvent({event:"input",value:inp.value});});' ...
                'inp.addEventListener("change",function(){' ...
                'window.sendEvent({event:"commit",value:inp.value});});' ...
                'inp.addEventListener("keydown",function(e){' ...
                'if(e.key==="Enter")window.sendEvent({event:"commit",value:inp.value});});' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue"){' ...
                'document.getElementById("inp").value=cmd.value;}' ...
                '};' ...
                '</script>' ...
            ];

            inputHTML = sprintf( ...
                '<div class="ef-wrap css-surface"><input id="inp" type="text" value="%s" placeholder="%s"%s></div>', ...
                CSSBase.attrEscape(obj.Value_), ...
                CSSBase.attrEscape(obj.Placeholder), roAttr);

            if strcmp(obj.LabelSide,'right')
                body = [inputHTML labelHTML];
            else
                body = [labelHTML inputHTML];
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
                    if ~isempty(obj.Value_)
                        obj.pushCmd(struct('cmd','setValue','value',obj.Value_));
                    end
                case 'input'
                    if obj.Enabled_
                        obj.Value_ = data.value;
                        if ~isempty(obj.ValueChangingFcn)
                            evt = struct('Source',obj,'Value',data.value);
                            try, obj.ValueChangingFcn(obj,evt);
                            catch ME, warning('uiEditField:changingError','%s',ME.message); end
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
                            catch ME, warning('uiEditField:changedError','%s',ME.message); end
                        end
                    end
            end
        end

    end

end
