classdef CSSuiSearchBar < CSSBase
    %CSSUISEARCHBAR  Pill-shaped search input with embedded submit button
    %
    %   Usage:
    %       sb = CSSuiSearchBar(parent, 'Placeholder', 'Filter…')
    %       sb.SearchSubmittedFcn = @(s,e) disp(e.Value);
    %
    %   Name-Value Pairs:
    %       'Value'              : char  - initial query (default '')
    %       'Placeholder'        : char  - hint text (default '')
    %       'AccentColor'        : char  - button colour (default '#296ec7')
    %       'SearchSubmittedFcn' : @(s,e) on Enter or button click (e.Value, e.PreviousValue)
    %       'SearchChangingFcn'  : @(s,e) on each keystroke (optional)
    %
    %   Standard CSS variables (--color, --bg-color, --font-size, --border-radius,
    %   --inset-shadow, etc.) are honored. Style preset 'shadow_light' is the
    %   recommended default.
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿

    properties (Access = public)
        Placeholder        = ''
        AccentColor        = '#296ec7'
        SearchSubmittedFcn = []
        SearchChangingFcn  = []
    end

    properties (Dependent)
        Value
    end

    properties (Access = protected)
        Value_     = ''
        CommitVal_ = ''
    end

    methods
        function obj = CSSuiSearchBar(parent, options)
            arguments
                parent = []
                options.Position           (1,4) double  = [10 10 280 40]
                options.Enabled            (1,1) logical = true
                options.TempDir            (1,:) char    = tempdir()
                options.Style                            = ''
                options.CSS                (1,:) char    = ''
                options.CSSFile            (1,:) char    = ''
                options.Value                    char    = ''
                options.Placeholder        (1,:) char    = ''
                options.AccentColor        (1,:) char    = '#296ec7'
                options.SearchSubmittedFcn               = []
                options.SearchChangingFcn                = []
                % --- forwarded CSS conveniences --------------------------
                options.Color               (1,:) char = ''
                options.BackgroundColor     (1,:) char = ''
                options.FontSize            (1,:) char = ''
                options.FontFamily          (1,:) char = ''
                options.FontWeight          (1,:) char = ''
                options.BorderRadius        (1,:) char = ''
                options.BoxShadow           (1,:) char = ''
                options.InsetShadow         (1,:) char = ''
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

            if isempty(parent), parent = uifigure('Name','CSSuiSearchBar'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.Value_             = options.Value;
            obj.CommitVal_         = options.Value;
            obj.Placeholder        = options.Placeholder;
            obj.AccentColor        = options.AccentColor;
            obj.SearchSubmittedFcn = options.SearchSubmittedFcn;
            obj.SearchChangingFcn  = options.SearchChangingFcn;

            obj.endInit();
        end

        function v = get.Value(obj), v = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_     = val;
            obj.CommitVal_ = val;
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue','value',val));
            end
        end

        function set.Placeholder(obj, val)
            obj.Placeholder = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.AccentColor(obj, val)
            obj.AccentColor = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    methods (Access = protected)

        function html = buildHTML(obj)
            css = [ ...
                '#css-root{display:flex;align-items:center;justify-content:center;' ...
                'padding:4px 6px;font-family:var(--font-family,"Segoe UI",system-ui,sans-serif);}' ...
                '.search{position:relative;width:100%;height:calc(100% - 8px);max-height:48px;min-height:28px;' ...
                'padding-left:1.1rem;border-radius:var(--border-radius,1.2rem);' ...
                'background:var(--bg-color,#ffffff);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'transition:transform 180ms ease-in-out,box-shadow 180ms ease-in-out;box-sizing:border-box;}' ...
                '.search input{all:unset;height:100%;width:calc(100% - 3rem);' ...
                'color:var(--color,#5f7080);font-size:var(--font-size,12px);font-family:inherit;' ...
                'font-weight:var(--font-weight,normal);}' ...
                '.search input::placeholder{color:inherit;opacity:0.45;}' ...
                '.search button{all:unset;position:absolute;right:0;top:0;height:100%;width:2.6rem;' ...
                'border-radius:var(--border-radius,1.2rem);background:var(--accent-color,#296ec7);' ...
                'cursor:pointer;display:flex;align-items:center;justify-content:center;' ...
                'transition:filter 180ms ease-in-out;}' ...
                '.search button:hover{filter:brightness(1.10);}' ...
                '.search button:active{filter:brightness(0.92);}' ...
                '.search .search-icon{position:relative;height:0.75rem;width:0.75rem;' ...
                'border:0.125rem solid white;border-radius:50%;box-sizing:border-box;' ...
                'transform:rotate(-45deg) translateY(-0.05rem);}' ...
                '.search .search-icon::after{content:"";position:absolute;height:0.45rem;' ...
                'width:0.125rem;background:white;left:calc(50% - 0.0625rem);bottom:-0.5rem;}' ...
                '.search:has(input:focus){transform:translateY(-1px);}' ...
                '.css-disabled .search{opacity:0.5;pointer-events:none;}' ...
            ];

            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var inp=document.getElementById("inp");' ...
                'var btn=document.getElementById("go");' ...
                'function commit(){window.sendEvent({event:"commit",value:inp.value});}' ...
                'inp.addEventListener("input",function(){' ...
                'window.sendEvent({event:"input",value:inp.value});});' ...
                'inp.addEventListener("keydown",function(e){' ...
                'if(e.key==="Enter"){e.preventDefault();commit();}' ...
                'if(e.key==="Escape"){inp.value="";commit();}});' ...
                'btn.addEventListener("click",commit);' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setValue"){document.getElementById("inp").value=cmd.value;}' ...
                '};' ...
                '</script>'];

            extraVars = sprintf('<style>:root{--accent-color:%s;}</style>', ...
                CSSBase.attrEscape(obj.AccentColor));

            body = sprintf( ...
                ['<div class="search css-control css-surface">' ...
                 '<input id="inp" type="text" value="%s" placeholder="%s">' ...
                 '<button id="go" type="button" aria-label="Search">' ...
                 '<span class="search-icon"></span></button></div>'], ...
                CSSBase.attrEscape(obj.Value_), ...
                CSSBase.attrEscape(obj.Placeholder));

            html = [ ...
                '<!DOCTYPE html><html><head>' extraVars '<style>' css '</style></head><body>' ...
                '<div id="css-root" class="cssui-search">' body '</div>' ...
                compJS '</body></html>'];
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
                        obj.fireCallback(obj.SearchChangingFcn, data.value);
                    end
                case 'commit'
                    if obj.Enabled_
                        oldVal         = obj.CommitVal_;
                        obj.Value_     = data.value;
                        obj.CommitVal_ = data.value;
                        obj.fireCallback(obj.SearchSubmittedFcn, data.value, oldVal);
                    end
            end
        end

        function fireCallback(obj, fn, val, oldVal)
            if isempty(fn), return, end
            if nargin < 4, oldVal = ''; end
            evt = struct('Source',obj,'Value',val,'PreviousValue',oldVal);
            try
                if iscell(fn)
                    f = fn{1}; f(obj, evt, fn{2:end});
                else
                    fn(obj, evt);
                end
            catch ME
                warning('CSSuiSearchBar:callback','%s', ME.message);
            end
        end
    end
end
