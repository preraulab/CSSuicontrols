classdef CSSuiEditField < CSSBase
    %CSSUIEDITFIELD  CSS-styled single-line text edit field backed by uihtml
    %
    %   Usage:
    %       ef = CSSuiEditField(parent, 'Placeholder', 'Enter name...')
    %       ef = CSSuiEditField(parent, 'Value', 'hello', 'Style', 'shadow')
    %       ef.ValueChangedFcn = @(s,e) disp(e.Value);
    %
    %   Inputs:
    %       parent : ui container - parent (default: new uifigure)
    %
    %   Name-Value Pairs:
    %       'Position'         : 1x4 double - [x y w h] (default: [10 10 200 36])
    %       'Enabled'          : logical - enable interaction (default: true)
    %       'TempDir'          : char - scratch dir (default: tempdir())
    %       'Style'            : char - CSSBase style preset (default: '')
    %       'CSS'              : char - extra CSS (default: '')
    %       'CSSFile'          : char - extra CSS file (default: '')
    %       'Value'            : char - initial text content (default: '')
    %       'Placeholder'      : char - hint text when empty (default: '')
    %       'Label'            : char - adjacent text label (default: '')
    %       'LabelSide'        : char - 'left' or 'right' (default: 'left')
    %       'Editable'         : logical - false = read-only (default: true)
    %       'ValueChangedFcn'  : @(src, evt) on Enter / focus-out (default: [])
    %       'ValueChangingFcn' : @(src, evt) on every keystroke (default: [])
    %       Additional CSS convenience properties are forwarded to CSSBase
    %       (Color, BackgroundColor, FontSize, Padding, BorderRadius, etc.).
    %
    %   Outputs:
    %       ef : CSSuiEditField handle
    %
    %   Notes:
    %       CSS element schema:
    %           #css-root                Outer sizing container (CSSBase-managed)
    %             .css-label             Adjacent text label div (when Label is set)
    %             .css-control           Input surface wrapper (bg / shadow)
    %               input#inp            The <input> element (transparent bg)
    %           .css-disabled            On #css-root when Enabled=false
    %
    %   Example:
    %       ef.CSS = '.css-control { border: 2px solid #1976D2; }';
    %       ef.CSS = '.css-label   { font-style: italic; }';
    %       ef.CSS = 'input        { text-align: right; }';
    %
    %   See also: CSSBase, CSSuiListBox, CSSuiTable
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿

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
        function obj = CSSuiEditField(parent, options)
            arguments
                parent = []
                options.Position         (1,4) double  = [10 10 200 36]
                options.Enabled          (1,1) logical = true
                options.TempDir          (1,:) char    = tempdir()
                options.Style                          = ''
                options.CSS              (1,:) char    = ''
                options.CSSFile          (1,:) char    = ''
                options.Value                  char    = ''
                options.Placeholder      (1,:) char    = ''
                options.Label            (1,:) char    = ''
                options.LabelSide        (1,:) char    = 'left'
                options.Editable         (1,1) logical = true
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
                options.AspectRatio         (1,:) char = ''
            end

            if isempty(parent), parent = uifigure('Name','CSSuiEditField'); end
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
                % Batch setValue + setError in one Data assignment to avoid the
                % uihtml rapid-write race: two successive HTMLComponent.Data
                % writes both fire DataChanged but JS reads only the last value.
                bCmd.cmd      = 'batch';
                bCmd.commands = { struct('cmd','setValue','value',val), ...
                                  struct('cmd','setError','value',obj.IsError_) };
                obj.pushCmd(bCmd);
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
                labelHTML = sprintf('<div class="css-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end
            if strcmp(obj.LabelSide,'right'), labelAlign='left';
            else,                            labelAlign='right'; end

            % Global reset is provided by CSSBase infraCSS.
            % overflow:visible so focus rings aren't clipped.
            % #css-root is the CSSBase sizing container; flex layout lives on it directly.
            css = [ ...
                '#css-root{display:flex;align-items:var(--align-items,center);' ...
                'gap:8px;padding:4px 6px;font-family:var(--font-family,inherit);}' ...
                '.css-label{color:var(--color,inherit);font-size:var(--font-size,12px);font-weight:var(--font-weight,500);' ...
                'white-space:nowrap;flex-shrink:0;text-align:' labelAlign ';user-select:none;}' ...
                '.css-control{flex:1 1 0;min-width:0;}' ...
                'input{width:100%;padding:7px 12px;border:none;outline:none;' ...
                'color:var(--color,#5f7080);' ...
                'background-color:var(--bg-color,#e0e0e0);' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,normal);' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,text);' ...
                'text-align:var(--text-align,left);}' ...
                'input:read-only{cursor:default;opacity:0.7;}' ...
                '.css-disabled input{opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
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
                '<div class="css-control css-surface"><input id="inp" type="text" value="%s" placeholder="%s"%s></div>', ...
                CSSBase.attrEscape(obj.Value_), ...
                CSSBase.attrEscape(obj.Placeholder), roAttr);

            if strcmp(obj.LabelSide,'right')
                body = [inputHTML labelHTML];
            else
                body = [labelHTML inputHTML];
            end

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root" class="cssui-edit">' body '</div>' ...
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
                        % Guard against stale blur-commits that arrive after a
                        % programmatic set.Value() call.  Value_ tracks the JS
                        % content via 'input' events and set.Value; if data.value
                        % no longer matches we discard the commit.
                        if ~isequal(data.value, obj.Value_)
                            return
                        end
                        oldVal         = obj.CommitVal_;
                        obj.CommitVal_ = data.value;
                        if ~isempty(obj.ValueChangedFcn)
                            evt = struct('Source',obj,'Value',data.value,'PreviousValue',oldVal);
                            try
                                if iscell(obj.ValueChangedFcn)
                                    fn = obj.ValueChangedFcn{1};
                                    fn(obj, evt, obj.ValueChangedFcn{2:end});
                                else
                                    obj.ValueChangedFcn(obj, evt);
                                end
                            catch ME, warning('uiEditField:changedError','%s',ME.message); end
                        end
                    end
            end
        end

    end

end
