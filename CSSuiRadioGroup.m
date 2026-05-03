classdef CSSuiRadioGroup < CSSBase
    %CSSUIRADIOGROUP  CSS-styled radio/checkbox group backed by uihtml
    %
    %   Usage:
    %       rg = CSSuiRadioGroup(parent, 'Items', {'Low','Med','High'}, ...
    %                            'Value', 'Med');
    %       rg.ValueChangedFcn = @(s,e) disp(e.Value);
    %
    %       % Multi-select (acts as a row/column of checkboxes):
    %       cg = CSSuiRadioGroup(parent, 'Items', {'A','B','C'}, ...
    %                            'MultiSelect', true, 'Value', {'A','C'});
    %
    %   Inputs:
    %       parent : graphics container -- required
    %
    %   Name-Value Pairs:
    %       'Items'           : cell of char - labels (default: {'Option 1','Option 2'})
    %       'Value'           : char (single-select) or cell (multi-select) -
    %                           currently selected label(s) (default: Items{1})
    %       'Orientation'     : 'horizontal' | 'vertical' (default: 'vertical')
    %       'MultiSelect'     : logical - if true, render checkboxes; if
    %                           false, render single-select radios (default: false)
    %       'CheckOnColor'    : char - CSS color when selected (default: '#A2D2FF')
    %       'BoxSize'         : char - CSS size of the box/dot (default: '18px')
    %       'ItemSpacing'     : char - CSS gap between items (default: '12px')
    %       'ValueChangedFcn' : function handle - @(src, evt) callback (default: [])
    %                           evt fields: Source, Value, PreviousValue,
    %                           Index (single-select) or Indices (multi-select).
    %       (plus all CSSBase name-value pairs)
    %
    %   Outputs:
    %       rg : CSSuiRadioGroup handle
    %
    %   Notes:
    %       Visual style is adapted from the W3Schools custom-checkbox /
    %       custom-radio pattern. In single-select mode all native inputs
    %       share a name attribute; in multi-select mode they are independent
    %       checkboxes.
    %
    %       CSS element schema:
    %           #css-root                  Outer sizing container
    %             .cssui-radio             Widget-type class on #css-root
    %             .rg-container            Flex container (items)
    %               label.css-control      Each option row (clickable)
    %                 input                Hidden native input
    %                 span.checkmark       Custom box / dot
    %                 span.rg-label        Item text
    %           .css-disabled              On #css-root when Enabled=false
    %
    %   See also: CSSBase, CSSPreset, CSSuiCheckbox, CSSuiSwitch, CSSuiListBox
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿

    properties (Access = public)
        Orientation     = 'vertical'    % 'vertical' | 'horizontal'
        MultiSelect     = false
        CheckOnColor    = '#A2D2FF'
        BoxSize         = '18px'
        ItemSpacing     = '12px'
        ValueChangedFcn = []
    end

    properties (Dependent)
        Items
        Value
    end

    properties (Access = protected)
        Items_   = {'Option 1','Option 2'}
        % Always stored as a logical vector, one per item, for uniformity.
        Sel_     = logical([])
        % Group name for radio inputs (kept stable across rebuilds for any
        % external CSS targeting, but unique per instance).
        GroupName_ = ''
    end

    % =====================================================================
    methods
        function obj = CSSuiRadioGroup(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 200 120]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = ''
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Items           (1,:) cell    = {'Option 1','Option 2'}
                options.Value                         = []
                options.Orientation     (1,:) char    = 'vertical'
                options.MultiSelect     (1,1) logical = false
                options.CheckOnColor    (1,:) char    = '#A2D2FF'
                options.BoxSize         (1,:) char    = '18px'
                options.ItemSpacing     (1,:) char    = '12px'
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

            if isempty(parent), parent = uifigure('Name','CSSuiRadioGroup'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.GroupName_      = ['rg_' CSSBase.randomTag()];
            obj.Orientation     = options.Orientation;
            obj.MultiSelect     = options.MultiSelect;
            obj.CheckOnColor    = options.CheckOnColor;
            obj.BoxSize         = options.BoxSize;
            obj.ItemSpacing     = options.ItemSpacing;
            obj.ValueChangedFcn = options.ValueChangedFcn;
            obj.Items_          = options.Items;
            obj.Sel_            = false(1, numel(obj.Items_));

            % Resolve initial Value
            obj.applyValue(options.Value, false);

            obj.endInit();
        end

        % --- Items (structural — rebuild) --------------------------------
        function set.Items(obj, val)
            obj.Items_ = val;
            % Drop selection bits beyond new length; pad with false.
            n = numel(val);
            sel = false(1, n);
            keep = min(numel(obj.Sel_), n);
            if keep > 0, sel(1:keep) = obj.Sel_(1:keep); end
            obj.Sel_ = sel;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function val = get.Items(obj), val = obj.Items_; end

        % --- Value (patchable) -------------------------------------------
        function set.Value(obj, val)
            obj.applyValue(val, true);
        end
        function val = get.Value(obj)
            if obj.MultiSelect
                val = obj.Items_(obj.Sel_);
                val = val(:)'; % row cell
            else
                idx = find(obj.Sel_, 1, 'first');
                if isempty(idx)
                    val = '';
                else
                    val = obj.Items_{idx};
                end
            end
        end

        % --- Orientation / MultiSelect / CheckOnColor / BoxSize / ItemSpacing
        function set.Orientation(obj, val)
            val = lower(char(val));
            if ~ismember(val, {'horizontal','vertical'})
                error('CSSuiRadioGroup:badOrientation', ...
                    'Orientation must be ''horizontal'' or ''vertical''.');
            end
            obj.Orientation = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.MultiSelect(obj, val)
            obj.MultiSelect = logical(val);
            % Collapse selection to single if switching to single-select
            if ~obj.MultiSelect && nnz(obj.Sel_) > 1
                idx = find(obj.Sel_, 1, 'first');
                obj.Sel_(:) = false;
                obj.Sel_(idx) = true;
            end
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.CheckOnColor(obj, val)
            obj.CheckOnColor = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.BoxSize(obj, val)
            obj.BoxSize = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function set.ItemSpacing(obj, val)
            obj.ItemSpacing = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            n = numel(obj.Items_);
            if obj.MultiSelect
                inputType = 'checkbox';
                radius    = '4px';
                isRadio   = false;
            else
                inputType = 'radio';
                radius    = '50%';
                isRadio   = true;
            end

            if strcmp(obj.Orientation, 'horizontal')
                flexDir = 'row';
                flexWrap = 'wrap';
            else
                flexDir = 'column';
                flexWrap = 'nowrap';
            end

            % Build items
            itemsHTML = '';
            for i = 1:n
                it  = char(obj.Items_{i});
                chk = '';
                if i <= numel(obj.Sel_) && obj.Sel_(i), chk = ' checked'; end
                nameAttr = '';
                if isRadio
                    nameAttr = sprintf(' name="%s"', obj.GroupName_);
                end
                itemsHTML = [itemsHTML sprintf( ...
                    ['<label class="css-control rg-item">' ...
                     '<input type="%s"%s data-idx="%d"%s>' ...
                     '<span class="checkmark"></span>' ...
                     '<span class="rg-label">%s</span>' ...
                     '</label>'], ...
                    inputType, nameAttr, i-1, chk, ...
                    CSSBase.htmlEscape(it))]; %#ok<AGROW>
            end

            % Tick (for checkboxes) vs dot (for radios) indicator CSS
            if isRadio
                indicatorCSS = [ ...
                    '.checkmark::after{content:"";position:absolute;display:none;' ...
                    'top:50%;left:50%;width:45%;height:45%;' ...
                    'border-radius:50%;background:#fff;' ...
                    'transform:translate(-50%,-50%);}' ...
                    '.css-control input:checked ~ .checkmark::after{display:block;}' ...
                ];
            else
                indicatorCSS = [ ...
                    '.checkmark::after{content:"";position:absolute;display:none;' ...
                    'left:35%;top:15%;width:25%;height:55%;' ...
                    'border:solid #fff;border-width:0 2px 2px 0;' ...
                    'transform:rotate(45deg);' ...
                    '-webkit-transform:rotate(45deg);}' ...
                    '.css-control input:checked ~ .checkmark::after{display:block;}' ...
                ];
            end

            css = [ ...
                ':root{--check-on:' obj.CheckOnColor ';' ...
                '--box-size:' obj.BoxSize ';' ...
                '--rg-gap:' obj.ItemSpacing ';' ...
                '--rg-radius:' radius ';}' ...
                '#css-root{display:flex;overflow:visible;' ...
                'justify-content:var(--text-align,flex-start);' ...
                'align-items:var(--align-items,flex-start);' ...
                'padding:0 5px;}' ...
                '.rg-container{display:flex;' ...
                'flex-direction:' flexDir ';' ...
                'flex-wrap:' flexWrap ';' ...
                'gap:var(--rg-gap,12px);' ...
                'width:100%;}' ...
                '.css-control{position:relative;display:inline-flex;' ...
                'align-items:center;gap:8px;cursor:pointer;' ...
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
                'border-radius:var(--rg-radius,4px);' ...
                'flex-shrink:0;transition:0.2s;' ...
                'box-shadow:inset 2px 2px 4px #bcbcbc,inset -2px -2px 4px #fff;}' ...
                '.css-control:hover input ~ .checkmark{' ...
                'background:var(--bg-hover,#ccc);}' ...
                '.css-control input:checked ~ .checkmark{' ...
                'background:var(--check-on,#A2D2FF);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.1);}' ...
                indicatorCSS ...
                '.rg-label{color:var(--color,inherit);' ...
                'font-size:var(--font-size,inherit);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'white-space:nowrap;overflow:visible;}' ...
            ];

            % JS: forward change events with the item index, accept setSel
            % commands carrying a boolean array.
            compJS = [ ...
                '<script>' ...
                'window.componentSetup=function(hc){' ...
                'var inputs=document.querySelectorAll("#css-root input");' ...
                'for(var i=0;i<inputs.length;i++){(function(inp){' ...
                'inp.addEventListener("change",function(){' ...
                'var idx=parseInt(inp.getAttribute("data-idx"),10);' ...
                'window.sendEvent({event:"change",index:idx,value:inp.checked});' ...
                '});})(inputs[i]);}' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setSel"){' ...
                'var inputs=document.querySelectorAll("#css-root input");' ...
                'var v=cmd.value||[];' ...
                'for(var i=0;i<inputs.length;i++){' ...
                'inputs[i].checked=!!v[i];}}' ...
                '};' ...
                '</script>' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root" class="css-surface cssui-radio">' ...
                '<div class="rg-container">' itemsHTML '</div>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            switch data.event
                case 'change'
                    if ~obj.Enabled_, return; end
                    idx1 = double(data.index) + 1;  % JS 0-based -> MATLAB 1-based
                    if idx1 < 1 || idx1 > numel(obj.Sel_), return; end

                    oldVal = obj.Value;
                    if obj.MultiSelect
                        obj.Sel_(idx1) = logical(data.value);
                    else
                        % Single-select: only one selected at a time.
                        obj.Sel_(:) = false;
                        obj.Sel_(idx1) = true;
                    end

                    if ~isempty(obj.ValueChangedFcn)
                        % Build the event struct field-by-field, NOT via
                        % struct(name, value, ...). In multi-select mode
                        % obj.Value is a cell array, and the multi-input
                        % struct() call would expand it into a struct array
                        % instead of storing it as a single field value.
                        evt = struct();
                        evt.Source        = obj;
                        evt.Value         = obj.Value;
                        evt.PreviousValue = oldVal;
                        evt.Index         = idx1;
                        if obj.MultiSelect
                            evt.Indices = find(obj.Sel_);
                        end
                        try
                            if iscell(obj.ValueChangedFcn)
                                fn = obj.ValueChangedFcn{1};
                                fn(obj, evt, obj.ValueChangedFcn{2:end});
                            else
                                obj.ValueChangedFcn(obj, evt);
                            end
                        catch ME
                            warning('uiRadioGroup:callbackError','%s',ME.message);
                        end
                    end
            end
        end

    end

    % =====================================================================
    methods (Access = private)

        function applyValue(obj, val, pushIfReady)
            % Resolve a user-supplied Value into obj.Sel_, then optionally
            % push to JS.
            n = numel(obj.Items_);
            sel = false(1, n);

            if isempty(val)
                if ~obj.MultiSelect && n >= 1
                    sel(1) = true;  % default to first item
                end
            elseif obj.MultiSelect
                % Expect cell array of strings (or single string)
                if ischar(val) || isstring(val)
                    val = {char(val)};
                end
                if ~iscell(val)
                    error('CSSuiRadioGroup:badValue', ...
                        'Value must be a cell of strings in MultiSelect mode.');
                end
                for k = 1:numel(val)
                    idx = find(strcmp(obj.Items_, char(val{k})), 1, 'first');
                    if ~isempty(idx), sel(idx) = true; end
                end
            else
                % Single-select: char/string
                if iscell(val)
                    if isempty(val), val = '';
                    else,            val = char(val{1});
                    end
                end
                idx = find(strcmp(obj.Items_, char(val)), 1, 'first');
                if isempty(idx)
                    if n >= 1, sel(1) = true; end
                else
                    sel(idx) = true;
                end
            end

            obj.Sel_ = sel;

            if pushIfReady && ~obj.Updating_ && obj.Loaded_
                % Wrap the logical vector in a cell so struct() doesn't
                % expand it into a 1xN struct array.
                cmd = struct('cmd','setSel');
                cmd.value = obj.Sel_;
                obj.pushCmd(cmd);
            end
        end

    end

end
