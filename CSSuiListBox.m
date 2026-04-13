classdef CSSuiListBox < CSSBase
    %CSSuiListBox  CSS-styled list box backed by uihtml.
    %
    %   USAGE
    %     lb = CSSuiListBox(parent, 'Items',{'Alpha','Beta','Gamma'})
    %     lb = CSSuiListBox(parent, 'Items',myList, 'Multiselect',true, 'Style','shadow')
    %     lb.ValueChangedFcn = @(s,e) disp(e.Value);
    %     lb.Value = 'Beta';           % single-select: set by string
    %     lb.Value = {'Alpha','Gamma'};% multi-select:  set by cell array
    %
    %   PROPERTIES
    %     Items             Cell array of option strings                default: {'Option 1','Option 2'}
    %     Value             Selected item string (single) or cell (multi) default: Items{1}
    %     Multiselect       logical — allow multiple selection          default: false
    %     ValueChangedFcn   @(src, evt) callback                       default: []
    %
    %   EVENT STRUCT (ValueChangedFcn)
    %     .Source           this CSSuiListBox object
    %     .Value            new selection (char if single, cell if multi)
    %     .PreviousValue    previous selection
    %
    %   CSS ELEMENT SCHEMA
    %     #css-root               Outer sizing container (CSSBase-managed)
    %       .css-control          Scrollable list container
    %         .lb-item            Each list row
    %         .lb-item.selected   Highlighted selected row(s)
    %     .css-disabled           On #css-root when Enabled=false
    %
    %   CUSTOM CSS EXAMPLES
    %     lb.CSS = '.lb-item { font-size: 13px; }';
    %     lb.CSS = '.lb-item.selected { background: #1976D2; color: #fff; }';
    %     lb.CSS = '.css-control { border-radius: 4px; }';

    properties (Access = public)
        ValueChangedFcn = []
        DoubleClickFcn  = []
        Multiselect     = false
        RowStriping     = false   % Alternate even rows with a subtle tint
        StripeColor     = 'rgba(0,0,0,0.045)'  % CSS color for even-row stripe
    end

    properties (Dependent)
        Items
        Value
    end

    properties (Access = protected)
        Items_ = {}
        Value_ = {}      % always stored internally as cell for uniformity
    end

    % =====================================================================
    methods
        function obj = CSSuiListBox(parent, options)
            arguments
                parent = []
                options.Position        (1,4) double  = [10 10 200 150]
                options.Enabled         (1,1) logical = true
                options.TempDir         (1,:) char    = tempdir()
                options.Style                         = 'shadow'
                options.CSS             (1,:) char    = ''
                options.CSSFile         (1,:) char    = ''
                options.Items           (1,:) cell    = {}
                options.Value                         = ''
                options.Multiselect     (1,1) logical = false
                options.RowStriping     (1,1) logical = false
                options.StripeColor     (1,:) char    = 'rgba(0,0,0,0.045)'
                options.ValueChangedFcn               = []
                options.DoubleClickFcn                = []
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

            if isempty(parent), parent = uifigure('Name','CSSuiListBox'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.ValueChangedFcn = options.ValueChangedFcn;
            obj.DoubleClickFcn  = options.DoubleClickFcn;
            obj.Multiselect     = options.Multiselect;
            obj.RowStriping     = options.RowStriping;
            obj.StripeColor     = options.StripeColor;
            obj.Items_          = options.Items;
            obj.Value_          = obj.normaliseValue(options.Value, options.Items);

            obj.endInit();
        end

        % --- Items (structural — full rebuild) ---------------------------
        function set.Items(obj, val)
            if ~iscell(val), val = {val}; end
            obj.Items_ = val;
            % Prune selection to items that still exist
            obj.Value_ = obj.Value_(ismember(obj.Value_, val));
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end
        function val = get.Items(obj), val = obj.Items_; end

        % --- Value (patchable) -------------------------------------------
        function set.Value(obj, val)
            obj.Value_ = obj.normaliseValue(val, obj.Items_);
            if ~obj.Updating_ && obj.Loaded_
                obj.pushCmd(struct('cmd','setSelection','value',{{obj.Value_{:}}}));
            end
        end
        function val = get.Value(obj)
            if obj.Multiselect
                val = obj.Value_;
            elseif isempty(obj.Value_)
                val = '';
            else
                val = obj.Value_{1};
            end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            % Build list item elements
            itemsHTML = '';
            for i = 1:numel(obj.Items_)
                it  = char(obj.Items_{i});
                sel = '';
                if ismember(it, obj.Value_), sel = ' selected'; end
                itemsHTML = [itemsHTML sprintf( ...
                    '<div class="lb-item%s" data-value="%s">%s</div>', ...
                    sel, CSSBase.attrEscape(it), CSSBase.htmlEscape(it))]; %#ok<AGROW>
            end

            multiFlag = 'false';
            if obj.Multiselect, multiFlag = 'true'; end

            css = [ ...
                '#css-root{display:flex;flex-direction:column;padding:var(--outer-padding,4px);}' ...
                '.css-control{' ...
                'flex:1;overflow-y:auto;overflow-x:hidden;' ...
                'background-color:var(--bg-color,#e0e0e0);' ...
                'border-radius:var(--border-radius,8px);' ...
                'box-shadow:var(--inset-shadow,inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff);' ...
                'opacity:var(--opacity,1);' ...
                'border:var(--border,none);' ...
                'padding:4px 0;' ...
                '}' ...
                '.lb-item{' ...
                'padding:6px 12px;' ...
                'cursor:var(--cursor,pointer);' ...
                'font-size:var(--font-size,12px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,500);' ...
                'color:var(--color,#5f7080);' ...
                'user-select:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;' ...
                'border-radius:4px;margin:1px 4px;' ...
                'transition:background 0.1s ease;' ...
                '}' ...
                '.lb-item:hover:not(.selected){background:rgba(0,0,0,0.06);}' ...
                '.lb-item.selected{' ...
                'background:var(--selected-bg,rgba(100,140,200,0.25));' ...
                'color:var(--selected-color,#2a4a80);' ...
                'font-weight:600;' ...
                '}' ...
                '.css-disabled .lb-item{opacity:0.5;cursor:not-allowed;pointer-events:none;}' ...
                obj.buildStripeCSS() ...
            ];

            compJS = [ ...
                '<script>' ...
                'var _multi=' multiFlag ';' ...
                'var _anchor=null;' ...
                'function _getSel(){' ...
                'var s=[];document.querySelectorAll(".lb-item.selected").forEach(function(x){s.push(x.getAttribute("data-value"));});return s;}' ...
                'function _itemIndex(el){' ...
                'return Array.from(el.parentElement.querySelectorAll(".lb-item")).indexOf(el);}' ...
                'function _attachListeners(c){' ...
                'c.querySelectorAll(".lb-item").forEach(function(el){' ...
                'el.addEventListener("click",function(e){' ...
                'if(e.detail>1)return;' ...
                'if(document.getElementById("css-root").classList.contains("css-disabled"))return;' ...
                'if(_multi&&(e.ctrlKey||e.metaKey)){' ...
                'el.classList.toggle("selected");' ...
                '_anchor=el;' ...
                '}else if(_multi&&e.shiftKey&&_anchor){' ...
                'var items=Array.from(c.querySelectorAll(".lb-item"));' ...
                'var a=items.indexOf(_anchor),b=items.indexOf(el);' ...
                'var lo=Math.min(a,b),hi=Math.max(a,b);' ...
                'items.forEach(function(x,i){if(i>=lo&&i<=hi)x.classList.add("selected");});' ...
                '}else{' ...
                'c.querySelectorAll(".lb-item").forEach(function(x){x.classList.remove("selected");});' ...
                'el.classList.add("selected");' ...
                '_anchor=el;' ...
                '}' ...
                'window.sendEvent({event:"change",value:_getSel()});' ...
                '});' ...
                'el.addEventListener("dblclick",function(){' ...
                'if(document.getElementById("css-root").classList.contains("css-disabled"))return;' ...
                'c.querySelectorAll(".lb-item").forEach(function(x){x.classList.remove("selected");});' ...
                'el.classList.add("selected");' ...
                '_anchor=el;' ...
                'window.sendEvent({event:"dblclick",value:el.getAttribute("data-value")});' ...
                '});' ...
                '});' ...
                '}' ...
                'window.componentSetup=function(hc){' ...
                'var c=document.querySelector(".css-control");if(c)_attachListeners(c);' ...
                '};' ...
                'window.onCommand=function(cmd){' ...
                'if(cmd.cmd==="setSelection"){' ...
                'var vals=cmd.value;' ...
                'document.querySelectorAll(".lb-item").forEach(function(el){' ...
                'if(vals.indexOf(el.getAttribute("data-value"))>=0){el.classList.add("selected");}' ...
                'else{el.classList.remove("selected");}' ...
                '});' ...
                '}' ...
                'if(cmd.cmd==="setItems"){' ...
                'var list=document.querySelector(".css-control");' ...
                'list.innerHTML="";' ...
                'cmd.items.forEach(function(it){' ...
                'var d=document.createElement("div");' ...
                'd.className="lb-item";d.setAttribute("data-value",it);d.textContent=it;' ...
                'if(cmd.selected.indexOf(it)>=0)d.classList.add("selected");' ...
                'list.appendChild(d);' ...
                '});' ...
                '_attachListeners(list);' ...
                '}' ...
                '};' ...
                '</script>' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="css-root">' ...
                '<div class="css-control css-surface">' itemsHTML '</div>' ...
                '</div>' ...
                compJS '</body></html>' ...
            ];
        end

        function onMessage(obj, data)
            switch data.event
                case 'ready'
                    % Push current selection after JS is wired
                    obj.pushCmd(struct('cmd','setSelection','value',{{obj.Value_{:}}}));
                case 'change'
                    if obj.Enabled_
                        oldVal  = obj.Value_;
                        newCell = data.value;
                        if ischar(newCell), newCell = {newCell}; end
                        if isstruct(newCell)
                            newCell = struct2cell(newCell)';
                        end
                        obj.Value_ = newCell;
                        if ~isempty(obj.ValueChangedFcn)
                            if obj.Multiselect
                                newVal = newCell;
                                prevVal = oldVal;
                            else
                                newVal  = CSSuiListBox.cellFirst(newCell, '');
                                prevVal = CSSuiListBox.cellFirst(oldVal,  '');
                            end
                            evt = struct('Source',obj, ...
                                'Value',newVal, 'PreviousValue',prevVal);
                            try
                                obj.ValueChangedFcn(obj, evt);
                            catch ME
                                warning('CSSuiListBox:callbackError','%s',ME.message);
                            end
                        end
                    end
                case 'dblclick'
                    if obj.Enabled_
                        % dblclick always sets a single item as the selection
                        newCell    = {char(data.value)};
                        obj.Value_ = newCell;
                        if ~isempty(obj.DoubleClickFcn)
                            evt = struct('Source',obj, 'Value',data.value);
                            try
                                obj.DoubleClickFcn(obj, evt);
                            catch ME
                                warning('CSSuiListBox:dblclickError','%s',ME.message);
                            end
                        end
                    end
            end
        end

    end

    % =====================================================================
    methods (Access = private)

        function s = buildStripeCSS(obj)
            if obj.RowStriping
                s = ['.lb-item:nth-child(even):not(.selected){background:' obj.StripeColor ';}'];
            else
                s = '';
            end
        end

        function c = normaliseValue(obj, val, items) %#ok<INUSL>
            % Always returns a cell of strings, pruned to items that exist.
            if isempty(val)
                c = {};
            elseif ischar(val) || isstring(val)
                c = {char(val)};
            elseif iscell(val)
                c = val;
            else
                c = {};
            end
            if ~isempty(items)
                c = c(ismember(c, items));
            end
        end

    end

    methods (Static, Access = private)
        function v = cellFirst(c, default)
            if isempty(c), v = default; else, v = c{1}; end
        end
    end

end
