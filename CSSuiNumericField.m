classdef CSSuiNumericField < CSSBase
    %CSSuiNumericField  CSS-styled numeric edit field with optional step buttons, backed by uihtml.
    %
    %   USAGE
    %     nf = CSSuiNumericField(parent, 'Value',50, 'Min',0, 'Max',100)
    %     nf = CSSuiNumericField(parent, 'Value',0, 'Step',1, 'Style','shadow')
    %     nf.ValueChangedFcn = @(s,e) fprintf('%.2f\n', e.Value);
    %
    %   PROPERTIES
    %     Value             Numeric value                           default: 0
    %     Limits            [Min Max] convenience alias             default: [-Inf Inf]
    %     Min               Minimum allowed                         default: -Inf
    %     Max               Maximum allowed                         default:  Inf
    %     Step              Step for +/- buttons (0 = hidden)       default: 0
    %     DecimalPlaces     Display precision                       default: 4
    %     Format            printf format string ('' = auto)        default: ''
    %     Placeholder       Hint text when empty                    default: ''
    %     Label             Adjacent text label                     default: ''
    %     LabelSide         'left' | 'right'                        default: 'left'
    %     ValueChangedFcn   @(src,evt) on Enter / blur              default: []
    %     ValueChangingFcn  @(src,evt) on every keystroke           default: []
    %
    %   CSS ELEMENT SCHEMA
    %     #css-root               Outer sizing container (CSSBase-managed)
    %       .css-label            Adjacent text label div (when Label is set)
    %       .css-control          Input surface wrapper (has bg / shadow)
    %         button#nf-dec       Decrement button (when Step > 0)
    %         input#inp           The <input type="text"> element
    %         button#nf-inc       Increment button (when Step > 0)
    %     .css-disabled           On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     nf.CSS = '.css-control { border: 2px solid #1976D2; }';
    %     nf.CSS = '.css-label   { font-style: italic; }';
    %     nf.CSS = 'input        { text-align: right; }';

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
        Limits      % [Min Max] — convenience alias matching native uinumericeditfield
    end

    properties (Access = protected)
        Value_     = 0
        CommitVal_ = 0
    end

    % =====================================================================
    methods
        function obj = CSSuiNumericField(parent, options)
            arguments
                parent = []
                options.Position         (1,4) double  = [10 10 200 36]
                options.Enabled          (1,1) logical = true
                options.TempDir          (1,:) char    = tempdir()
                options.Style                          = ''
                options.CSS              (1,:) char    = ''
                options.CSSFile          (1,:) char    = ''
                options.Value                  double  = []
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

            if isempty(parent), parent = uifigure('Name','CSSuiNumericField'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
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

        % --- Limits (alias for [Min Max]) ------------------------------------
        function val = get.Limits(obj), val = [obj.Min obj.Max]; end
        function set.Limits(obj, val)
            obj.Min = val(1);
            obj.Max = val(2);
        end

        % --- Value (patchable) -------------------------------------------
        function val = get.Value(obj), val = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_     = obj.clamp(val);
            obj.CommitVal_ = obj.Value_;
            if ~obj.Updating_ && obj.Loaded_
                bCmd.cmd      = 'batch';
                bCmd.commands = { struct('cmd','setValue','value',obj.formatNum(obj.Value_)), ...
                                  struct('cmd','setError','value',obj.IsError_) };
                obj.pushCmd(bCmd);
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
        %************************************************************
        %                      BUILD HTML (PATCHED HEIGHT)
        %************************************************************
        function html = buildHTML(obj)

            labelHTML = '';
            if ~isempty(strtrim(obj.Label))
                labelHTML = sprintf('<div class="css-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end
            if strcmp(obj.LabelSide,'right'), labelAlign='left';
            else,                            labelAlign='right'; end

            showStep = obj.Step > 0;
            stepCSS  = '';

            if showStep
                stepCSS = [ ...
                    '.nf-btn{width:28px;flex-shrink:0;' ...
                    'border:none;margin:0;padding:0;' ...
                    'appearance:none;-webkit-appearance:none;' ...
                    'background:var(--bg-color,#e0e0e0);color:var(--color,inherit);' ...
                    'box-shadow:var(--box-shadow,none);' ...
                    'border-radius:var(--border-radius,0);' ...
                    'cursor:pointer;font-size:14px;' ...
                    'display:flex;align-items:center;justify-content:center;' ...
                    'user-select:none;' ...
                    'align-self:center;}' ...  
                    '.nf-btn:hover{opacity:0.7;}' ...
                    ];
            end

            css = [ ...
                '#css-root{display:flex;align-items:center;' ...
                'gap:8px;padding:0 6px;font-family:var(--font-family,inherit);}' ...  
                '.css-label{color:var(--color,inherit);font-size:var(--font-size,12px);font-weight:var(--font-weight,500);' ...
                'white-space:nowrap;flex-shrink:0;text-align:' labelAlign ';user-select:none;}' ...
                '.css-control{display:flex;flex:1 1 0;min-width:0;' ...
                'align-items:center;' ... 
                'overflow:hidden;' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'background-color:var(--bg-color,#e0e0e0);}' ...
                'input{flex:1;min-width:0;padding:7px 12px;border:none;outline:none;' ...
                'color:var(--color,#5f7080);' ...
                'background:transparent;' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,normal);' ...
                'cursor:var(--cursor,text);' ...
                'text-align:var(--text-align,left);' ...
                'box-sizing:border-box;}' ... 
                stepCSS ...
                '.css-disabled input,.css-disabled .nf-btn{' ...
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
                'var _lastGoodVal=inp.value;' ...
                'function _commitVal(v){' ...
                'var root=document.getElementById("css-root");' ...
                'if(isNaN(v)){' ...
                'inp.value=_lastGoodVal;' ...
                'root.classList.toggle("css-error",_lastGoodVal==="");' ...
                '}else{' ...
                '_lastGoodVal=inp.value;' ...
                'root.classList.remove("css-error");' ...
                '}' ...
                'window.sendEvent({event:"commit",value:v});}' ...
                'inp.addEventListener("change",function(){' ...
                'var v=clampJS(parseFloat(inp.value));' ...
                'if(!isNaN(v))inp.value=v;' ...
                '_commitVal(v);});' ...
                'inp.addEventListener("keydown",function(e){' ...
                'if(e.key==="Enter"){var v=clampJS(parseFloat(inp.value));' ...
                'if(!isNaN(v))inp.value=v;' ...
                '_commitVal(v);}});' ...
                ];

            if showStep
                compJS = [compJS ...
                    'var dec=document.getElementById("nf-dec");' ...
                    'var inc=document.getElementById("nf-inc");' ...
                    'dec.addEventListener("click",function(){' ...
                    'var v=clampJS((parseFloat(inp.value)||0)-_step);' ...
                    'inp.value=v;_commitVal(v);});' ...
                    'inc.addEventListener("click",function(){' ...
                    'var v=clampJS((parseFloat(inp.value)||0)+_step);' ...
                    'inp.value=v;_commitVal(v);});' ...
                    ];
            end

            compJS = [compJS ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue"){' ...
                'var inp2=document.getElementById("inp");' ...
                'inp2.value=cmd.value;_lastGoodVal=cmd.value;}' ...
                '};' ...
                '</script>' ...
                ];

            wrapHTML = ['<div class="css-control css-surface">' stepHTML '</div>'];

            if strcmp(obj.LabelSide,'right')
                body = [wrapHTML labelHTML];
            else
                body = [labelHTML wrapHTML];
            end

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root">' body '</div>' ...
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
                        oldVal = obj.CommitVal_;
                        newVal = obj.clamp(data.value);
                        if ~isnan(newVal)
                            % Valid input: accept and clear any prior error
                            obj.Value_     = newVal;
                            obj.CommitVal_ = newVal;
                            obj.IsError_   = false;
                            if ~isempty(obj.ValueChangedFcn)
                                evt = struct('Source',obj,'Value',newVal,'PreviousValue',oldVal);
                                try, obj.ValueChangedFcn(obj,evt);
                                catch ME, warning('uiNumericField:changedError','%s',ME.message); end
                            end
                        else
                            % Invalid (non-numeric) input: revert display, keep last valid value
                            obj.pushCmd(struct('cmd','setValue','value',obj.formatNum(obj.CommitVal_)));
                            obj.IsError_ = isempty(obj.CommitVal_) || any(isnan(obj.CommitVal_(:)));
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
