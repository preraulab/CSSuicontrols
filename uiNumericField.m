classdef uiNumericField < CSSBase
%UINUMERICFIELD  CSS-styled numeric edit field with optional step buttons.
%
%   USAGE
%     nf = uiNumericField(parent, 'Value',50, 'Min',0, 'Max',100)
%     nf = uiNumericField(parent, 'Value',0, 'Step',1, 'Style','shadow')
%     nf.ValueChangedFcn = @(s,e) fprintf('%.2f\n', e.Value);
%
%   PROPERTIES
%     Value             Numeric value                           default: 0
%     Min               Minimum allowed                         default: -Inf
%     Max               Maximum allowed                         default:  Inf
%     Step              Step for +/- buttons (0 = hidden)       default: 0
%     DecimalPlaces     Display precision                       default: 4
%     Format            printf format ('' = auto)               default: ''
%     Placeholder       Hint text when empty                    default: ''
%     Label             Adjacent text label                     default: ''
%     LabelSide         'left' | 'right'                        default: 'left'
%     ValueChangedFcn   @(src,evt) on Enter / blur              default: []
%     ValueChangingFcn  @(src,evt) on every keystroke           default: []

    properties (Access = public)
        Min              = -Inf
        Max              =  Inf
        Step             = 0
        DecimalPlaces    = 4
        Format           = ''
        Placeholder      = ''
        Label            = ''
        LabelSide        = 'left'
        ValueChangedFcn  = []
        ValueChangingFcn = []
    end

    properties (Dependent)
        Value
    end

    properties (Access = protected)
        Value_     = 0
        CommitVal_ = 0
    end

    % =====================================================================
    methods
        function obj = uiNumericField(parent, options)
            arguments
                parent = []
                options.Position         (1,4) double  = [10 10 200 36]
                options.Enabled          (1,1) logical = true
                options.TempDir          (1,:) char    = tempdir()
                options.Style                          = ''
                options.CSS              (1,:) char    = ''
                options.CSSFile          (1,:) char    = ''
                options.Value            (1,1) double  = 0
                options.Min              (1,1) double  = -Inf
                options.Max              (1,1) double  =  Inf
                options.Step             (1,1) double  = 0
                options.DecimalPlaces    (1,1) double  = 4
                options.Format           (1,:) char    = ''
                options.Placeholder      (1,:) char    = ''
                options.Label            (1,:) char    = ''
                options.LabelSide        (1,:) char    = 'left'
                options.ValueChangedFcn                = []
                options.ValueChangingFcn               = []
            end

            if isempty(parent), parent = uifigure('Name','uiNumericField'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.Min              = options.Min;
            obj.Max              = options.Max;
            obj.Step             = options.Step;
            obj.DecimalPlaces    = options.DecimalPlaces;
            obj.Format           = options.Format;
            obj.Placeholder      = options.Placeholder;
            obj.Label            = options.Label;
            obj.LabelSide        = options.LabelSide;
            obj.ValueChangedFcn  = options.ValueChangedFcn;
            obj.ValueChangingFcn = options.ValueChangingFcn;
            obj.Value_           = obj.clamp(options.Value);
            obj.CommitVal_       = obj.Value_;

            obj.endInit();
        end

        % --- Value (patchable) -------------------------------------------
        function val = get.Value(obj), val = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_     = obj.clamp(val);
            obj.CommitVal_ = obj.Value_;
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue', ...
                    'value',obj.formatNum(obj.Value_)));
            end
        end

        % --- Structural properties ---------------------------------------
        function set.Min(obj, val)
            obj.Min    = val;
            obj.Value_ = obj.clamp(obj.Value_);
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.Max(obj, val)
            obj.Max    = val;
            obj.Value_ = obj.clamp(obj.Value_);
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.Step(obj, val)
            obj.Step = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.DecimalPlaces(obj, val)
            obj.DecimalPlaces = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
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
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            labelHTML = '';
            if ~isempty(strtrim(obj.Label))
                labelHTML = sprintf('<div class="nf-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end
            if strcmp(obj.LabelSide,'right'), labelAlign='left';
            else,                            labelAlign='right'; end

            showStep = obj.Step > 0;
            stepCSS  = '';
            stepHTML  = '';
            if showStep
                stepCSS = [ ...
                    '.nf-btn{width:28px;flex-shrink:0;align-self:stretch;' ...
                    'border:none;margin:0;padding:0;' ...
                    'appearance:none;-webkit-appearance:none;' ...
                    'background:var(--bg-color,#e0e0e0);color:var(--color,inherit);' ...
                    'box-shadow:var(--box-shadow,none);' ...
                    'border-radius:var(--border-radius,0);' ...
                    'cursor:pointer;font-size:14px;' ...
                    'display:flex;align-items:center;justify-content:center;' ...
                    'user-select:none;}' ...
                    '.nf-btn:hover{opacity:0.7;}' ...
                ];
            end

            % Global reset is provided by CSSBase infraCSS.
            % overflow:visible is needed so focus rings aren't clipped.
            css = [ ...
                'html,body{overflow:visible;display:flex;align-items:center;' ...
                'gap:8px;padding:4px 6px;font-family:var(--font-family,inherit);}' ...
                '#uihb{display:contents;}' ...
                '.nf-label{color:var(--color,inherit);font-size:12px;font-weight:600;' ...
                'white-space:nowrap;flex-shrink:0;text-align:' labelAlign ';user-select:none;}' ...
                '.nf-wrap{display:flex;flex:1 1 0;min-width:0;overflow:hidden;' ...
                'align-self:stretch;' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'background-color:var(--bg-color,#e0e0e0);}' ...
                'input{flex:1;min-width:0;padding:7px 12px;border:none;outline:none;' ...
                'color:var(--color,#5f7080);' ...
                'background:transparent;' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,normal);' ...
                'cursor:var(--cursor,text);}' ...
                stepCSS ...
                '.uihb-disabled input,.uihb-disabled .nf-btn{' ...
                'opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
            ];

            if showStep
                stepHTML = [ ...
                    '<button class="nf-btn" id="nf-dec">&minus;</button>' ...
                    '%INPUT%' ...
                    '<button class="nf-btn" id="nf-inc">+</button>' ...
                ];
            else
                stepHTML = '%INPUT%';
            end

            inputTag = sprintf( ...
                '<input id="inp" type="text" value="%s" placeholder="%s">', ...
                CSSBase.attrEscape(obj.formatNum(obj.Value_)), ...
                CSSBase.attrEscape(obj.Placeholder));
            stepHTML = strrep(stepHTML, '%INPUT%', inputTag);

            % JS: min/max/step passed as literals
            jsMin  = obj.numToJS(obj.Min);
            jsMax  = obj.numToJS(obj.Max);
            jsStep = sprintf('%.10g', obj.Step);

            compJS = [ ...
                '<script>' ...
                'var _min=' jsMin ',_max=' jsMax ',_step=' jsStep ';' ...
                'function clampJS(v){' ...
                'if(isNaN(v))return v;' ...
                'if(_min!==null&&isFinite(_min))v=Math.max(v,_min);' ...
                'if(_max!==null&&isFinite(_max))v=Math.min(v,_max);' ...
                'return v;}' ...
                'window.componentSetup=function(hc){' ...
                'var inp=document.getElementById("inp");' ...
                'inp.addEventListener("input",function(){' ...
                'var v=parseFloat(inp.value);' ...
                'if(!isNaN(v))window.sendEvent({event:"input",value:v});});' ...
                'inp.addEventListener("change",function(){' ...
                'var v=clampJS(parseFloat(inp.value));' ...
                'if(!isNaN(v))inp.value=v;' ...
                'window.sendEvent({event:"commit",value:v});});' ...
                'inp.addEventListener("keydown",function(e){' ...
                'if(e.key==="Enter"){var v=clampJS(parseFloat(inp.value));' ...
                'if(!isNaN(v))inp.value=v;' ...
                'window.sendEvent({event:"commit",value:v});}});' ...
            ];

            if showStep
                compJS = [compJS ...
                    'var dec=document.getElementById("nf-dec");' ...
                    'var inc=document.getElementById("nf-inc");' ...
                    'dec.addEventListener("click",function(){' ...
                    'var v=clampJS((parseFloat(inp.value)||0)-_step);' ...
                    'inp.value=v;window.sendEvent({event:"commit",value:v});});' ...
                    'inc.addEventListener("click",function(){' ...
                    'var v=clampJS((parseFloat(inp.value)||0)+_step);' ...
                    'inp.value=v;window.sendEvent({event:"commit",value:v});});' ...
                ];
            end

            compJS = [compJS ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue"){' ...
                'document.getElementById("inp").value=cmd.value;}' ...
                '};' ...
                '</script>' ...
            ];

            wrapHTML = ['<div class="nf-wrap css-surface">' stepHTML '</div>'];
            if strcmp(obj.LabelSide,'right')
                body = [wrapHTML labelHTML];
            else
                body = [labelHTML wrapHTML];
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
                    obj.pushCmd(struct('cmd','setValue', ...
                        'value',obj.formatNum(obj.Value_)));
                case 'input'
                    if obj.Enabled_
                        val = data.value;
                        if ~isnan(val), obj.Value_ = obj.clamp(val); end
                        if ~isempty(obj.ValueChangingFcn)
                            evt = struct('Source',obj,'Value',val);
                            try, obj.ValueChangingFcn(obj,evt);
                            catch ME, warning('uiNumericField:changingError','%s',ME.message); end
                        end
                    end
                case 'commit'
                    if obj.Enabled_
                        oldVal         = obj.CommitVal_;
                        newVal         = obj.clamp(data.value);
                        obj.Value_     = newVal;
                        obj.CommitVal_ = newVal;
                        if ~isempty(obj.ValueChangedFcn)
                            evt = struct('Source',obj,'Value',newVal,'PreviousValue',oldVal);
                            try, obj.ValueChangedFcn(obj,evt);
                            catch ME, warning('uiNumericField:changedError','%s',ME.message); end
                        end
                    end
            end
        end

        function v = clamp(obj, v)
            if isnan(v), return; end
            if ~isinf(obj.Min), v = max(v, obj.Min); end
            if ~isinf(obj.Max), v = min(v, obj.Max); end
        end

        function s = formatNum(obj, v)
            if isnan(v)
                s = '';
            elseif ~isempty(obj.Format)
                s = sprintf(obj.Format, v);
            else
                s = sprintf('%.*g', max(1, obj.DecimalPlaces + 1), v);
                if contains(s, '.'), s = regexprep(s, '\.?0+$', ''); end
            end
        end

        function s = numToJS(~, v)
            if isinf(v) && v > 0,     s = 'Infinity';
            elseif isinf(v) && v < 0, s = '-Infinity';
            else,                      s = sprintf('%.10g', v);
            end
        end

    end

end
