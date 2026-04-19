classdef CSSuiTextArea < CSSBase
    %CSSUITEXTAREA  CSS-styled multiline text area backed by uihtml
    %
    %   Usage:
    %       ta = CSSuiTextArea(parent, 'Placeholder', 'Enter notes...')
    %       ta.ValueChangedFcn  = @(s,e) disp(e.Value);
    %       ta.ValueChangingFcn = @(s,e) disp(e.Value);
    %       ta.add('line');   ta.addnl('another line');
    %
    %   Inputs:
    %       parent : graphics container -- required
    %
    %   Name-Value Pairs:
    %       'Value'            : char - text content (default: '')
    %       'Placeholder'      : char - hint text when empty (default: '')
    %       'Label'            : char - header label above the text area (default: '')
    %       'Editable'         : logical - false = read-only (default: true)
    %       'Scroll'           : logical - show scrollbar on overflow (default: false)
    %       'WordWrap'         : logical - wrap long lines (default: true)
    %       'MaxLines'         : integer - max lines kept in buffer, 0 = unlimited (default: 5000)
    %       'ValueChangedFcn'  : function handle - @(src, evt) on blur (default: [])
    %       'ValueChangingFcn' : function handle - @(src, evt) on each keystroke (default: [])
    %       (plus all CSSBase name-value pairs)
    %
    %   Outputs:
    %       ta : CSSuiTextArea handle
    %
    %   Notes:
    %       Convenience methods: ta.add(str) (append), ta.addnl(str) (newline + append).
    %       Use sprintf or newline() to embed line breaks in Value.
    %
    %       CSS element schema:
    %           #css-root      Outer sizing container
    %             .css-label   Header label div (when Label is set)
    %             textarea#ta.css-control  The <textarea> element
    %           .css-disabled  On #css-root when Enabled=false
    %
    %   See also: CSSBase, CSSPreset, CSSuiEditField
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿

    properties (Access = public)
        Placeholder      = ''
        Label            = ''
        Editable         = true
        Scroll           = false
        WordWrap         = true   % false = no line wrapping (enables horizontal scroll)
        MaxLines         = 5000   % max lines kept in buffer (0 = unlimited)
        ValueChangedFcn  = []
        ValueChangingFcn = []
    end

    properties (Dependent)
        Value
    end

    properties (Access = protected)
        Value_      = ''
        CommitVal_  = ''
        LineCount_  = 0    % running newline count; avoids splitting on every add()
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
                options.Scroll          (1,1) logical = false
                options.WordWrap        (1,1) logical = true
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
                options.AspectRatio         (1,:) char = ''
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
            obj.Scroll           = options.Scroll;
            obj.WordWrap         = options.WordWrap;
            obj.ValueChangedFcn  = options.ValueChangedFcn;
            obj.ValueChangingFcn = options.ValueChangingFcn;

            obj.endInit();
        end

        % --- Value (patchable) -------------------------------------------
        function val = get.Value(obj), val = obj.Value_; end
        function set.Value(obj, val)
            obj.Value_     = val;
            obj.CommitVal_ = val;
            obj.LineCount_ = 0;   % reset line counter on full replace
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setValue','value', CSSuiTextArea.encodeNewlines(val)));
            end
        end

        % --- Convenience append methods ----------------------------------
        function add(obj, val)
            %ADD  Append val to the current Value with no separator.
            %   Sends only the new text across the bridge (appendText command)
            %   rather than the full accumulated string, keeping bridge
            %   payload O(1) per call regardless of log length.
            %   When MaxLines > 0, trims oldest lines once the buffer is full
            %   and does a one-time full resync to the JS textarea.
            obj.Value_     = [obj.Value_ val];
            obj.LineCount_ = obj.LineCount_ + sum(val == newline);

            if obj.MaxLines > 0 && obj.LineCount_ > obj.MaxLines
                % Trim to last MaxLines lines and resync JS with full setValue.
                lines          = strsplit(obj.Value_, newline, 'CollapseDelimiters', false);
                lines          = lines(end - obj.MaxLines + 1 : end);
                obj.Value_     = strjoin(lines, newline);
                obj.LineCount_ = obj.MaxLines;
                if ~obj.Updating_ && obj.Loaded_
                    obj.pushCmd(struct('cmd','setValue', ...
                        'value', CSSuiTextArea.encodeNewlines(obj.Value_)));
                end
            elseif ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','appendText', ...
                    'value', CSSuiTextArea.encodeNewlines(val)));
            end
        end

        function addnl(obj, val)
            %ADDNL  Append a newline then val to the current Value.
            obj.add([newline val]);
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
        function set.Scroll(obj, val)
            obj.Scroll = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.WordWrap(obj, val)
            obj.WordWrap = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        function scrollToBottom(obj)
            %SCROLLTOBOTTOM  Programmatically scroll the text area to the end.
            if obj.Loaded_
                obj.pushCmd(struct('cmd','scrollBottom'));
            end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            roAttr = '';
            if ~obj.Editable, roAttr = ' readonly'; end

            % overflow-y: auto shows a scrollbar only when content overflows;
            % hidden (default) clips silently and lets the textarea grow via
            % the user's own typing (native behaviour).
            if obj.Scroll
                overflowCSS = 'overflow-y:auto;';
                scrollbarCSS = '#ta::-webkit-scrollbar{display:block;width:6px;}#ta::-webkit-scrollbar-thumb{background:rgba(0,0,0,0.25);border-radius:3px;}';
            else
                overflowCSS  = 'overflow-y:hidden;';
                scrollbarCSS = '';
            end
            if ~obj.WordWrap
                wrapCSS = 'white-space:pre;overflow-x:auto;';
            else
                wrapCSS = '';
            end

            labelHTML = '';
            if ~isempty(strtrim(obj.Label))
                labelHTML = sprintf( ...
                    '<div class="css-label">%s</div>', ...
                    CSSBase.htmlEscape(obj.Label));
            end

            css = [ ...
                'html,body{display:flex;flex-direction:column;}' ...
                '#css-root{display:flex;flex-direction:column;width:100%;height:100%;' ...
                'gap:4px;padding:4px 6px;}' ...
                '.css-label{color:var(--color,inherit);font-size:var(--font-size,12px);' ...
                'font-weight:var(--font-weight,500);white-space:nowrap;user-select:none;' ...
                'flex-shrink:0;font-family:var(--font-family,inherit);}' ...
                '.css-control{flex:1;width:100%;resize:none;border:none;outline:none;' ...
                overflowCSS ...
                wrapCSS ...
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
                scrollbarCSS ...
            ];

            % NOTE on newline encoding:
            %   The uihtml Data bridge serialises MATLAB structs to JSON.
            %   A real newline (char 10) becomes the JSON token \n, which JS
            %   receives as the two-char literal backslash-n — NOT a newline.
            %   encodeNewlines() pre-converts real newlines to the two-char
            %   literal '\n' so they arrive in JS as backslash-n, and the JS
            %   split('\n').join('\n') then restores them to real newlines.
            %   The reverse path (JS→MATLAB) needs no treatment: textarea
            %   values come through the JSON bridge already correctly decoded.
            autoScrollFlag = 'false';
            if obj.Scroll, autoScrollFlag = 'true'; end

            compJS = [ ...
                '<script>' ...
                'var _autoScroll=' autoScrollFlag ';' ...
                'window.componentSetup=function(hc){' ...
                'var ta=document.getElementById("ta");' ...
                'ta.addEventListener("input",function(){' ...
                'window.sendEvent({event:"input",value:ta.value});});' ...
                'ta.addEventListener("blur",function(){' ...
                'window.sendEvent({event:"commit",value:ta.value});});' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'var ta=document.getElementById("ta");' ...
                'if(cmd.cmd==="setValue"){' ...
                '  ta.value=cmd.value.split("\\n").join("\n");' ...
                '  if(_autoScroll)ta.scrollTop=ta.scrollHeight;' ...
                '}' ...
                'if(cmd.cmd==="appendText"){' ...
                '  ta.value+=cmd.value.split("\\n").join("\n");' ...
                '  if(_autoScroll)ta.scrollTop=ta.scrollHeight;' ...
                '}' ...
                'if(cmd.cmd==="scrollBottom"){' ...
                '  ta.scrollTop=ta.scrollHeight;' ...
                '}' ...
                '};' ...
                '</script>' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root">' ...
                labelHTML ...
                '<textarea id="ta" class="css-surface css-control"' ...
                ' placeholder="' CSSBase.attrEscape(obj.Placeholder) '"' ...
                roAttr '>' CSSuiTextArea.htmlEscapeTA(obj.Value_) '</textarea>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            switch data.event
                case 'ready'
                    if ~isempty(obj.Value_)
                        obj.pushCmd(struct('cmd','setValue','value', ...
                            CSSuiTextArea.encodeNewlines(obj.Value_)));
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

    % =====================================================================
    methods (Static, Access = private)

        function s = htmlEscapeTA(s)
            %HTMLESCAPETA  Like CSSBase.htmlEscape but also encodes CR/LF as
            %   &#10; so the CEF browser cannot drop or collapse them when
            %   parsing the textarea's initial HTML content.
            s = strrep(s, '&',           '&amp;');
            s = strrep(s, '<',           '&lt;');
            s = strrep(s, '>',           '&gt;');
            s = strrep(s, sprintf('\r\n'),'&#10;');
            s = strrep(s, sprintf('\r'),  '&#10;');
            s = strrep(s, newline,        '&#10;');
        end

        function s = encodeNewlines(s)
            %ENCODENEWLINES  Replace real newlines with the two-character
            %   literal sentinel '\n' (backslash + n) so they survive the
            %   MATLAB struct → JSON → JS bridge.
            %
            %   The uihtml JSON bridge encodes a real newline (char 10) as the
            %   JSON token \n, which JS receives as backslash-n — not a newline.
            %   Pre-encoding to the literal two chars '\n' makes them arrive as
            %   backslash-n in JS, where split('\n').join('\n') converts them
            %   back to real newlines.  Order: CRLF first to avoid double-encoding.
            s = strrep(s, sprintf('\r\n'), '\n');
            s = strrep(s, sprintf('\r'),   '\n');
            s = strrep(s, newline,         '\n');
        end

    end

end