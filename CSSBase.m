classdef (Abstract) CSSBase < handle
    %CSSBASE  Abstract base class for CSS-styled HTML-backed MATLAB UI controls.
    %
    %   Every CSSBase component is a uihtml element whose content is a
    %   self-contained HTML document.  CSSBase handles the full lifecycle:
    %   temp-file writing, JS bridge injection, Enabled-state queuing, CSS
    %   variable compilation, and live CSS patching without page reloads.
    %
    %   -----------------------------------------------------------------------
    %   HTML / CSS ELEMENT SCHEMA
    %   -----------------------------------------------------------------------
    %   Every component produces an HTML document with this structure:
    %
    %     <body>
    %       <div id="css-root">          ← sizing container (CSSBase-managed)
    %         <div class="css-control">  ← main visual/interactive element
    %         <div class="css-label">    ← adjacent text label  (if present)
    %         <svg  class="css-icon">    ← SVG icon              (if present)
    %       </div>
    %     </body>
    %
    %   Selector reference:
    %     #css-root       Outer sizing container.  Width/Height/OuterPadding/
    %                     Border convenience properties map here.  Receives
    %                     .css-disabled when Enabled=false.
    %     .css-control    The main interactive surface — the <button>, input
    %                     wrapper, <textarea>, toggle track, dropdown wrapper,
    %                     or label div, depending on the component.
    %     .css-label      Adjacent descriptive text label (EditField, Dropdown,
    %                     NumericField, Switch, TextArea only).
    %     .css-icon       SVG icon element (CSSuiButton only).
    %     #cssbase-text   Span whose textContent is live-patched by JS without
    %                     a page reload (button text, label text, switch label).
    %     .css-disabled   Applied to #css-root when Enabled=false; sets opacity:0.5,
    %                     removes box-shadow on all children, and blocks pointer-events.
    %     .css-surface    Applied to the primary rendered surface; targeted by
    %                     CSSPreset hover/active/transition rules.
    %     .css-clickable  Applied to interactive surfaces; enables hover lift and
    %                     active press animations from CSSPreset.
    %
    %   -----------------------------------------------------------------------
    %   WRITING CUSTOM CSS  (obj.CSS property)
    %   -----------------------------------------------------------------------
    %   Use the convenience properties (Color, BackgroundColor, …) for the most
    %   common appearance changes — they compile to :root CSS variables and are
    %   always reliable.  Use obj.CSS for anything not covered:
    %
    %     % Works identically for any component — no per-component knowledge needed:
    %     obj.CSS = '.css-control { text-transform: uppercase; letter-spacing: 0.08em; }';
    %     obj.CSS = '.css-label  { font-style: italic; }';
    %     obj.CSS = '.css-icon   { fill: #E53935; }';
    %
    %     % Override disabled appearance (e.g. make it more faded):
    %     obj.CSS = '.css-disabled { opacity: 0.3; }';
    %
    %     % Suppress the default hover lift on a button:
    %     btn.CSS = '.css-control.css-clickable:hover { transform: none; }';
    %
    %   obj.CSS is injected into <style id="cssbase-override">, which is placed
    %   AFTER the component's own <style> in the document.  User CSS therefore
    %   wins at equal specificity — no !important needed for most overrides.
    %   Preset CSS (from the Style argument) is also in this block, but placed
    %   before obj.CSS so user rules always take priority over the preset.
    %
    %   -----------------------------------------------------------------------
    %   CSS VARIABLE MAP  (convenience properties → :root custom props)
    %   -----------------------------------------------------------------------
    %     Color               → --color
    %     BackgroundColor     → --bg-color
    %     FontSize            → --font-size
    %     FontFamily          → --font-family
    %     FontWeight          → --font-weight
    %     FontStyle           → --font-style
    %     LetterSpacing       → --letter-spacing
    %     LineHeight          → --line-height
    %     TextTransform       → --text-transform
    %     TextDecoration      → --text-decoration
    %     HorizontalAlignment → --text-align        ('left'|'center'|'right')
    %     VerticalAlignment   → --align-items       ('top'|'center'|'bottom')
    %     BorderRadius        → --border-radius
    %     BoxShadow           → --box-shadow
    %     InsetShadow         → --inset-shadow
    %     Opacity             → --opacity
    %     Cursor              → --cursor
    %     Padding             → --padding
    %     Width               → --width
    %     Height              → --height
    %     OuterPadding        → --outer-padding
    %     Border              → --border
    %     AspectRatio         → --aspect-ratio
    %     MinWidth            → --min-width
    %     MinHeight           → --min-height
    %     MaxWidth            → --max-width
    %     MaxHeight           → --max-height
    %
    %   -----------------------------------------------------------------------
    %   EXTERNAL THEME FILE  (obj.CSSFile property)
    %   -----------------------------------------------------------------------
    %   Point multiple components at a shared .css file for a consistent theme.
    %   The <link> is injected first (lowest cascade priority), so per-component
    %   properties and obj.CSS always override it:
    %
    %     obj.CSSFile = fullfile(pwd, 'mytheme.css');
    %
    %   -----------------------------------------------------------------------
    %   CASCADE ORDER  (lowest → highest priority)
    %   -----------------------------------------------------------------------
    %     1.  CSSFile  <link>                  (external theme)
    %     2.  infraCSS  <style>                (#css-root sizing, .css-disabled)
    %     3.  <style id="cssbase-vars">        (:root custom property variables)
    %     4.  Component  <style>               (internal component defaults)
    %     5.  <style id="cssbase-override">    (preset CSS, then obj.CSS)
    %
    %   -----------------------------------------------------------------------
    %   SUBCLASS CONTRACT
    %   -----------------------------------------------------------------------
    %   1.  Call superclass constructor first:  obj@CSSBase(parent, ...)
    %   2.  Implement   html = buildHTML(obj)   (Abstract, protected).
    %         - Return a complete HTML document.
    %         - Must include  <div id="css-root"> as the outermost body child.
    %         - Place .css-control, .css-label, .css-icon inside #css-root.
    %         - Reference appearance via var(--color), var(--bg-color), etc.
    %         - May define  window.componentSetup(hc)  for JS initialisation.
    %         - May define  window.onCommand(cmd)  for MATLAB→JS commands.
    %   3.  Call  obj.endInit()  at the END of the concrete constructor.
    %   4.  Override  onMessage(obj, data)  for custom JS→MATLAB events.
    %
    %   -----------------------------------------------------------------------
    %   BRIDGE PROTOCOL
    %   -----------------------------------------------------------------------
    %   MATLAB → JS:   obj.pushCmd(struct('cmd','...', ...))
    %     'setEnabled'   toggle .css-disabled on #css-root
    %     'setCSS'       update cssbase-vars (.vars) and cssbase-override (.override)
    %     'setVar'       set a single CSS custom property on :root
    %     'setText'      patch #cssbase-text textContent
    %     'batch'        struct with .commands cell-array, dispatched in order
    %     (other)        forwarded to  window.onCommand(cmd)
    %
    %   JS → MATLAB:   window.sendEvent({event:'...', ...})
    %     'ready'        component fully initialised (after componentSetup)
    %     'error'        JS exception  (.message field)
    %     (other)        forwarded to  obj.onMessage(data)

    % ======================================================================
    %  Public
    % ======================================================================
    properties (Dependent)
        Position                    % [x y w h] pixels
        Enabled                     % logical
        IsError                     % logical — highlights control with red border
        Layout                      % full LayoutOptions object
        Row                         % grid row  (shorthand for Layout.Row)
        Column                      % grid column (shorthand for Layout.Column)
    end

    properties (Access = public)
        CSS      = ''               % Raw CSS string (injected last)
        CSSFile  = ''               % Path to external .css file
    end

    %  --- Convenience CSS properties (compile to :root custom props) ------
    properties (Access = public)
        % --- Colour / background ------------------------------------------
        Color           = ''        % --color
        BackgroundColor = ''        % --bg-color
        % --- Typography ---------------------------------------------------
        FontSize        = ''        % --font-size
        FontFamily      = ''        % --font-family
        FontWeight      = ''        % --font-weight
        FontStyle       = ''        % --font-style       e.g. 'italic'
        LetterSpacing   = ''        % --letter-spacing   e.g. '0.05em'
        LineHeight      = ''        % --line-height      e.g. '1.4'
        TextTransform   = ''        % --text-transform   'uppercase'|'lowercase'|'capitalize'
        TextDecoration  = ''        % --text-decoration  e.g. 'underline'
        % --- Alignment (MATLAB-style values accepted) ---------------------
        HorizontalAlignment = ''    % --text-align       'left'|'center'|'right'
        VerticalAlignment   = ''    % --align-items      'top'|'center'|'bottom' (flex-start/center/flex-end)
        % --- Border / effects ---------------------------------------------
        BorderRadius    = ''        % --border-radius
        BoxShadow       = ''        % --box-shadow  (outset / raised shadow)
        InsetShadow     = ''        % --inset-shadow (inset / carved shadow for inputs)
        Opacity         = ''        % --opacity
        Cursor          = ''        % --cursor
        % --- Spacing / sizing ---------------------------------------------
        Padding         = ''        % --padding      internal padding of the control element
        MinWidth        = ''        % --min-width
        MinHeight       = ''        % --min-height
        MaxWidth        = ''        % --max-width
        MaxHeight       = ''        % --max-height
        % --- Container sizing (#css-root wrapper div) ---------------------
        Width           = ''        % --width        e.g. '80%' or '120px'
        Height          = ''        % --height       e.g. '50%' or '32px'
        OuterPadding    = ''        % --outer-padding  inset between MATLAB boundary and control
        Border          = ''        % --border
        AspectRatio      = ''       % --aspect-ratio e.g. '1/1'
    end

    properties (GetAccess = public, SetAccess = protected)
        HTMLComponent               % underlying uihtml handle
    end

    % ======================================================================
    %  Protected state (available to subclasses)
    % ======================================================================
    properties (Access = protected)
        Loaded_    = false           % true after 'ready' from JS
        Updating_  = true            % true during construction
        Enabled_   = true            % cached Enabled value
        IsError_   = false           % cached IsError value
        TempDir_   = ''
    end

    % ======================================================================
    %  Private state
    % ======================================================================
    properties (Access = private)
        TempFile_  = ''
        CmdQueue_  = {}              % pre-load command buffer
        PresetCSS_ = ''              % raw CSS string from the applied preset
    end

    % ======================================================================
    %  Abstract
    % ======================================================================
    methods (Abstract, Access = protected)
        html = buildHTML(obj)
    end

    % ======================================================================
    %  Constructor / Destructor
    % ======================================================================
    methods
        function obj = CSSBase(parent, options)
            arguments
                parent
                options.Position  (1,4) double  = [10 10 120 36]
                options.Enabled   (1,1) logical = true
                options.TempDir   (1,:) char    = tempdir()
                options.Style                   = ''
                options.CSS       (1,:) char    = ''
                options.CSSFile   (1,:) char    = ''
            end

            obj.Enabled_  = options.Enabled;
            obj.TempDir_  = options.TempDir;

            obj.validateTempDir(options.TempDir);

            obj.HTMLComponent = uihtml(parent, ...
                'Position',       options.Position, ...
                'DataChangedFcn', @(src, evt) obj.routeDataChanged(src, evt));

            % Apply preset first; explicit CSS / CSSFile override afterward
            obj.applyPreset(options.Style);
            if ~isempty(options.CSS),     obj.CSS     = options.CSS;     end
            if ~isempty(options.CSSFile), obj.CSSFile = options.CSSFile; end

            % Subclass MUST call obj.endInit() after setting its own props.
        end

        function delete(obj)
            obj.safeDeleteTempFile();
        end
    end

    % ======================================================================
    %  Dependent property accessors
    % ======================================================================
    methods
        function set.Position(obj, val), obj.HTMLComponent.Position = val; end
        function val = get.Position(obj), val = obj.HTMLComponent.Position; end

        function set.Enabled(obj, val)
            obj.Enabled_ = logical(val);
            if obj.Loaded_ && obj.isReady()
                % Send setEnabled + current CSS as one atomic batch so that
                % toggling enable/disable can never leave the CSS out of sync.
                batchCmd.cmd      = 'batch';
                batchCmd.commands = { ...
                    struct('cmd','setEnabled','value',obj.Enabled_), ...
                    struct('cmd','setCSS','vars',obj.buildVarCSS(),'override',obj.buildOverrideCSS()) ...
                    };
                obj.HTMLComponent.Data = batchCmd;
            else
                obj.CmdQueue_{end+1} = struct('cmd','setEnabled','value',obj.Enabled_);
            end
        end
        function val = get.Enabled(obj), val = obj.Enabled_; end

        function set.IsError(obj, val)
            obj.IsError_ = logical(val);
            if obj.isReady()
                obj.pushCmd(struct('cmd','setError','value',obj.IsError_));
            end
        end
        function val = get.IsError(obj), val = obj.IsError_; end

        function set.Layout(obj, val), obj.HTMLComponent.Layout = val; end
        function val = get.Layout(obj), val = obj.HTMLComponent.Layout; end

        function set.Row(obj, val),    obj.HTMLComponent.Layout.Row    = val; end
        function val = get.Row(obj),   val = obj.HTMLComponent.Layout.Row;    end
        function set.Column(obj, val), obj.HTMLComponent.Layout.Column = val; end
        function val = get.Column(obj),val = obj.HTMLComponent.Layout.Column; end
    end

    % ======================================================================
    %  CSS / convenience property setters  (trigger refresh)
    % ======================================================================
    methods
        % CSS string and CSSFile always require a full rebuild (structural).
        function set.CSS(obj, val)
            obj.CSS = val;
            if ~obj.Updating_
                if obj.Loaded_ && obj.isReady()
                    obj.pushCmd(struct('cmd','setCSS', ...
                        'vars',obj.buildVarCSS(),'override',obj.buildOverrideCSS()));
                elseif obj.isReady()
                    obj.refresh();
                end
            end
        end
        function set.CSSFile(obj, val)
            obj.CSSFile = val;
            if ~obj.Updating_ && obj.isReady(), obj.refresh(); end
        end

        % Convenience CSS-var properties: when already loaded, push the full
        % compiled CSS (:root vars + user CSS string) as a single setCSS
        % command so the component state and obj.CSS always stay in sync.
        function set.Color(obj, val)
            obj.Color = val;
            obj.pushFullCSS();
        end
        function set.BackgroundColor(obj, val)
            obj.BackgroundColor = val;
            obj.pushFullCSS();
        end
        function set.FontSize(obj, val)
            obj.FontSize = val;
            obj.pushFullCSS();
        end
        function set.FontFamily(obj, val)
            obj.FontFamily = val;
            obj.pushFullCSS();
        end
        function set.FontWeight(obj, val)
            obj.FontWeight = val;
            obj.pushFullCSS();
        end
        function set.BorderRadius(obj, val)
            obj.BorderRadius = val;
            obj.pushFullCSS();
        end
        function set.BoxShadow(obj, val)
            obj.BoxShadow = val;
            obj.pushFullCSS();
        end
        function set.InsetShadow(obj, val)
            obj.InsetShadow = val;
            obj.pushFullCSS();
        end
        function set.Opacity(obj, val)
            obj.Opacity = val;
            obj.pushFullCSS();
        end
        function set.Cursor(obj, val)
            obj.Cursor = val;
            obj.pushFullCSS();
        end
        function set.Padding(obj, val)
            obj.Padding = val;
            obj.pushFullCSS();
        end
        function set.Width(obj, val)
            obj.Width = val;
            obj.pushFullCSS();
        end
        function set.Height(obj, val)
            obj.Height = val;
            obj.pushFullCSS();
        end
        function set.AspectRatio(obj, val)
            obj.AspectRatio = val;
            obj.pushFullCSS();
        end
        function set.OuterPadding(obj, val)
            obj.OuterPadding = val;
            obj.pushFullCSS();
        end
        function set.Border(obj, val)
            obj.Border = val;
            obj.pushFullCSS();
        end
        function set.FontStyle(obj, val)
            obj.FontStyle = val;
            obj.pushFullCSS();
        end
        function set.LetterSpacing(obj, val)
            obj.LetterSpacing = val;
            obj.pushFullCSS();
        end
        function set.LineHeight(obj, val)
            obj.LineHeight = val;
            obj.pushFullCSS();
        end
        function set.TextTransform(obj, val)
            obj.TextTransform = val;
            obj.pushFullCSS();
        end
        function set.TextDecoration(obj, val)
            obj.TextDecoration = val;
            obj.pushFullCSS();
        end
        function set.HorizontalAlignment(obj, val)
            obj.HorizontalAlignment = val;
            obj.pushFullCSS();
        end
        function set.VerticalAlignment(obj, val)
            % Accept MATLAB-style names and map to CSS flex values
            switch lower(val)
                case 'top',    val = 'flex-start';
                case 'bottom', val = 'flex-end';
            end
            obj.VerticalAlignment = val;
            obj.pushFullCSS();
        end
        function set.MinWidth(obj, val)
            obj.MinWidth = val;
            obj.pushFullCSS();
        end
        function set.MinHeight(obj, val)
            obj.MinHeight = val;
            obj.pushFullCSS();
        end
        function set.MaxWidth(obj, val)
            obj.MaxWidth = val;
            obj.pushFullCSS();
        end
        function set.MaxHeight(obj, val)
            obj.MaxHeight = val;
            obj.pushFullCSS();
        end
        % Margin is intentionally omitted: applying margin to a 100%-wide
        % element causes overflow.  Use OuterPadding for inset spacing.
    end

    % ======================================================================
    %  Public methods
    % ======================================================================
    methods (Access = public)

        function setStyle(obj, style)
            %SETSTYLE  Apply a named preset or CSSPreset object after construction.
            %   Batches all property changes into a single refresh.
            %   Example:  btn.setStyle('flat')
            %             btn.setStyle(CSSPreset.glass())
            obj.Updating_ = true;
            obj.applyPreset(style);
            obj.Updating_ = false;
            if obj.isReady(), obj.refresh(); end
        end

    end

    % ======================================================================
    %  Protected helpers (available to all subclasses)
    % ======================================================================
    methods (Access = protected)

        function endInit(obj)
            obj.Updating_ = false;
            obj.refresh();
        end

        function refresh(obj)
            obj.Loaded_ = false;
            html = obj.buildHTML();
            html = obj.assembleHTML(html);
            obj.safeDeleteTempFile();
            obj.TempFile_ = obj.writeTempFile(html);
            obj.HTMLComponent.HTMLSource = obj.TempFile_;
        end

        function pushCmd(obj, s)
            if obj.Loaded_ && ~isempty(obj.HTMLComponent) && isvalid(obj.HTMLComponent)
                obj.HTMLComponent.Data = s;
            else
                obj.CmdQueue_{end+1} = s;
            end
        end

        function onMessage(~, ~)
        end

        function ok = isReady(obj)
            ok = ~isempty(obj.HTMLComponent) && isvalid(obj.HTMLComponent);
        end

        %************************************************************
        %                  FIXED: PUSH FULL CSS
        %************************************************************
        function applyCSSOptions(obj, options)
            %APPLYCSSOPTOONS  Apply any CSS convenience properties found in an
            %   options struct to this component.  Called by subclass constructors
            %   to forward constructor name-value arguments to the base properties.
            %   Only non-empty values are applied so defaults are not overwritten.
            props = {'Color','BackgroundColor','FontSize','FontFamily','FontWeight', ...
                'FontStyle','LetterSpacing','LineHeight','TextTransform','TextDecoration', ...
                'HorizontalAlignment','VerticalAlignment','BorderRadius','BoxShadow', ...
                'InsetShadow','Opacity','Cursor','Padding','MinWidth','MinHeight', ...
                'MaxWidth','MaxHeight','Width','Height','OuterPadding','Border','AspectRatio'};
            for i = 1:numel(props)
                p = props{i};
                if isfield(options, p) && ~isempty(options.(p))
                    obj.(p) = options.(p);
                end
            end
        end

        function pushFullCSS(obj)
            %PUSHFULLCSS  Always safe: queues before load, pushes after load.
            %
            %   - Before load: queues command
            %   - After load: sends immediately
            %   - Coalesces duplicate queued CSS updates

            if ~obj.isReady(), return; end

            cmd = struct('cmd','setCSS', ...
                'vars',obj.buildVarCSS(),'override',obj.buildOverrideCSS());

            if obj.Loaded_
                obj.HTMLComponent.Data = cmd;
            else
                % Coalesce last CSS command instead of stacking many
                if ~isempty(obj.CmdQueue_) && ...
                        isfield(obj.CmdQueue_{end}, 'cmd') && ...
                        strcmp(obj.CmdQueue_{end}.cmd, 'setCSS')
                    obj.CmdQueue_{end} = cmd;
                else
                    obj.CmdQueue_{end+1} = cmd;
                end
            end
        end

        function pushVar(obj, name, val)
            %PUSHVAR  Live-push a single CSS custom property to the document root.
            %   More efficient than a full CSS rebuild when only one variable changes.
            %   name  — CSS custom property name, e.g. '--my-color'
            %   val   — CSS value string, e.g. '#ff0000'
            obj.pushCmd(struct('cmd','setVar','name',name,'value',val));
        end

    end

    % ======================================================================
    %  Private
    % ======================================================================
    methods (Access = private)

        function routeDataChanged(obj, src, ~)
            data = src.Data;
            if ~isstruct(data) || ~isfield(data, 'event'), return; end

            switch data.event
                case 'ready'
                    obj.Loaded_ = true;
                    % Do NOT delete the temp file here.  If CEF reloads the
                    % webview after a tab switch it must still be able to read
                    % the file.  safeDeleteTempFile() is called at the START of
                    % the next refresh() call (and in delete()), so files never
                    % accumulate.
                    obj.flushQueue();
                case 'error'
                    warning('CSSBase:jsError', 'JS error: %s', data.message);
            end

            obj.onMessage(data);
        end

        function flushQueue(obj)
            if isempty(obj.HTMLComponent) || ~isvalid(obj.HTMLComponent), return; end

            % Always append a fresh setCSS as the LAST command.
            % When the tab was in the background, CEF may have throttled or
            % dropped earlier setCSS pushes.  Appending one here guarantees
            % the correct CSS is applied the moment the component goes live,
            % regardless of what was (or wasn't) processed before ready fired.
            cssCmd  = struct('cmd','setCSS', ...
                'vars',obj.buildVarCSS(),'override',obj.buildOverrideCSS());
            allCmds = [obj.CmdQueue_ {cssCmd}];

            if numel(allCmds) == 1
                obj.HTMLComponent.Data = allCmds{1};
            else
                % Batch all pending commands into one Data assignment so the
                % JS DataChanged handler sees them all in a single event.
                % This prevents the race where rapid successive Data writes
                % cause the JS to read only the latest value for every event.
                batchCmd.cmd      = 'batch';
                batchCmd.commands = allCmds;
                obj.HTMLComponent.Data = batchCmd;
            end
            obj.CmdQueue_ = {};
        end

        function applyPreset(obj, style)
            %APPLYPRESET  Read a CSSPreset and assign its non-empty fields.
            if isempty(style), return; end

            if ischar(style) || isstring(style)
                name = char(style);
                try
                    preset = CSSPreset.(name)();
                catch ME
                    avail = CSSPreset.list();
                    if ismember(name, avail)
                        % Preset exists but threw internally — rethrow the real error
                        rethrow(ME);
                    end
                    error('CSSBase:badPreset', ...
                        'Unknown preset "%s". Available: %s', ...
                        name, strjoin(avail, ', '));
                end
            elseif isa(style, 'CSSPreset')
                preset = style;
            else
                error('CSSBase:badStyle', ...
                    'Style must be a preset name (char) or CSSPreset object.');
            end

            fn = properties(preset);
            for i = 1:numel(fn)
                val = preset.(fn{i});
                if isempty(val), continue; end
                if strcmp(fn{i}, 'CSS')
                    % Preset CSS is stored separately so user obj.CSS always
                    % takes priority — they are combined in buildOverrideCSS().
                    obj.PresetCSS_ = val;
                elseif isprop(obj, fn{i})
                    obj.(fn{i}) = val;
                end
            end
        end

        function html = assembleHTML(obj, componentHTML)
            %ASSEMBLEHTML  Inject CSS variables, user CSS, CSSFile, and bridge.
            html = componentHTML;

            % --- 1. Build head-injection block (after <head>) -------------
            headInject = '';

            % CSSFile link
            if ~isempty(obj.CSSFile)
                fp = obj.CSSFile;
                % Make absolute if relative
                if ~startsWith(fp, '/') && ~contains(fp, ':')
                    fp = fullfile(pwd, fp);
                end
                fp = strrep(fp, '\', '/');
                if ~startsWith(fp, 'file:///')
                    fp = ['file:///' fp];
                end
                headInject = sprintf('<link rel="stylesheet" href="%s">', fp);
            end

            % Infrastructure CSS: global reset, outer layout, container, disabled rule
            %
            %   html / body  — fill 100% of the uihtml position; body is a
            %                  flex centering context for #css-root.
            %   #css-root    — sizing container.  Width/Height/OuterPadding
            %                  control how it occupies the MATLAB component area.
            %                  Defaults to 100% × 100% with no padding so existing
            %                  components are visually unchanged unless overridden.
            %                  No align-items here — each component sets its own.
            %   .css-disabled — opacity:0.5, box-shadow:none, pointer-events:none on all children.
            infraCSS = [ ...
                '*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}' ...
                '::-webkit-scrollbar{display:none!important;}' ...
                '::-webkit-scrollbar-track{background:transparent!important;}' ...
                '::-webkit-scrollbar-corner{background:transparent!important;}' ...
                'html{' ...
                  'width:100%;height:100%;' ...
                  'overflow:hidden;' ...
                  'background:transparent!important;' ...
                  'scrollbar-width:none;' ...
                  '-ms-overflow-style:none;' ...
                '}' ...
                'body{' ...
                  'width:100%;height:100%;' ...
                  'overflow:visible;' ...
                  'background:transparent!important;' ...
                  'display:flex;align-items:center;justify-content:center;' ...
                '}' ...
                '#css-root{' ...
                'box-sizing:border-box;' ...
                'background:transparent;' ...
                'width:var(--width,100%);' ...
                'height:var(--height,100%);' ...
                'min-width:var(--min-width,0);' ...
                'min-height:var(--min-height,0);' ...
                'max-width:var(--max-width,none);' ...
                'max-height:var(--max-height,none);' ...
                'padding:var(--outer-padding,0);' ...
                'aspect-ratio:var(--aspect-ratio,none);' ...
                'border:var(--border,none);' ...
                'display:flex;' ...
                'text-align:var(--text-align,inherit);' ...
                '}' ...
                '.css-disabled{pointer-events:none!important;opacity:0.5;}' ...
                '.css-disabled *{pointer-events:none!important;cursor:not-allowed!important;box-shadow:none!important;text-shadow:none!important;}' ...
                '.css-error .css-control{border:2px solid #e53935!important;border-radius:var(--border-radius,8px)!important;}' ...
                ];

            % cssbase-vars holds :root{custom props} — injected early so all
            % component CSS can reference them via var(...).
            % cssbase-override holds preset CSS + obj.CSS — injected AFTER the
            % component's own <style> so user rules win at equal specificity.
            headInject = [headInject ...
                '<style>' infraCSS '</style>' ...
                '<style id="cssbase-vars">' obj.buildVarCSS() '</style>'];

            html = regexprep(html, '(?i)(<head>)', ['$1' headInject]);

            % Inject override block immediately before </head>, after component CSS.
            overrideTag = ['<style id="cssbase-override">' obj.buildOverrideCSS() '</style>'];
            k = regexpi(html, '</head>');
            if ~isempty(k)
                html = [html(1:k(1)-1) overrideTag html(k(1):end)];
            else
                warning('CSSBase:noHeadClose', 'No </head> tag — cssbase-override appended before </body>.');
                html = regexprep(html, '(?i)(</body>)', [overrideTag '$1']);
            end

            % --- 3. Inject JS bridge (before </body>) --------------------
            html = CSSBase.injectBridge(html, obj.Enabled_, obj.IsError_);
        end

        function s = buildVarBlock(obj)
            %BUILDVARBLOCK  Compile convenience properties to CSS custom props.
            s   = '';
            map = CSSBase.varMap();
            fn  = fieldnames(map);
            for i = 1:numel(fn)
                val = obj.(fn{i});
                if ~isempty(val)
                    s = [s map.(fn{i}) ':' val ';']; %#ok<AGROW>
                end
            end
        end

        function s = buildVarCSS(obj)
            %BUILDVARCSS  Build the :root{} custom-property block for cssbase-vars.
            varBlock = obj.buildVarBlock();
            if ~isempty(varBlock)
                s = [':root{' varBlock '}'];
            else
                s = '';
            end
        end

        function s = buildOverrideCSS(obj)
            %BUILDOVERRIDECSS  Build the override block for cssbase-override.
            %   Preset CSS comes first so user obj.CSS wins at equal specificity.
            s = [obj.PresetCSS_ obj.CSS];
        end

        function validateTempDir(~, d)
            if ~isfolder(d)
                error('CSSBase:badTempDir', 'TempDir does not exist: %s', d);
            end
            probe = fullfile(d, ['cssbase_probe_' CSSBase.randomTag()]);
            fid   = fopen(probe, 'w');
            if fid == -1
                error('CSSBase:notWritable', 'TempDir is not writable: %s', d);
            end
            fclose(fid); delete(probe);
        end

        function fp = writeTempFile(obj, html)
            fp  = fullfile(obj.TempDir_, ...
                ['cssbase_' CSSBase.randomTag() '.html']);
            fid = fopen(fp, 'w', 'n', 'UTF-8');
            if fid == -1
                error('CSSBase:fileError', 'Cannot write temp file: %s', fp);
            end
            fprintf(fid, '%s', html);
            fclose(fid);
        end

        function safeDeleteTempFile(obj)
            if ~isempty(obj.TempFile_) && isfile(obj.TempFile_)
                try, delete(obj.TempFile_); catch, end
                obj.TempFile_ = '';
            end
        end

    end

    % ======================================================================
    %  Static — protected (available to subclasses)
    % ======================================================================
    methods (Static, Access = protected)

        function tag = randomTag()
            tag = sprintf('%08x', randi([0 2^32-1], 1, 1, 'uint32'));
        end

        function s = htmlEscape(s)
            s = strrep(s, '&', '&amp;');
            s = strrep(s, '<', '&lt;');
            s = strrep(s, '>', '&gt;');
        end

        function s = attrEscape(s)
            s = CSSBase.htmlEscape(s);
            s = strrep(s, '"', '&quot;');
        end

    end

    % ======================================================================
    %  Static — private
    % ======================================================================
    methods (Static, Access = private)

        function html = injectBridge(html, enabledInit, isErrorInit)
            %INJECTBRIDGE  Insert the JS command/event bridge before </body>.
            if enabledInit,  jsEn  = 'true';  else, jsEn  = 'false'; end
            if isErrorInit,  jsErr = 'true';  else, jsErr = 'false'; end

            bridge = [ ...
                '<script>(function(){' ...
                'var _hc,_queue=[],_ready=false,_en=' jsEn ',_err=' jsErr ';' ...
                ...
                'function dispatch(cmd){' ...
                'switch(cmd.cmd){' ...
                'case"setEnabled":_en=cmd.value;applyEn(_en);break;' ...
                'case"setError":_err=cmd.value;applyErr(_err);break;' ...
                'case"setText":' ...
                'var _ct=document.getElementById("cssbase-text");' ...
                'if(_ct)_ct.textContent=cmd.value;break;' ...
                'case"setVar":' ...
                'document.documentElement.style.setProperty(cmd.name,cmd.value);break;' ...
                'case"setCSS":' ...
                'var _sv=document.getElementById("cssbase-vars");' ...
                'if(_sv)_sv.textContent=cmd.vars||"";' ...
                'var _so=document.getElementById("cssbase-override");' ...
                'if(_so)_so.textContent=cmd.override||"";break;' ...
                'case"batch":' ...
                'var c=cmd.commands;' ...
                'for(var i=0;i<c.length;i++)dispatch(c[i]);break;' ...
                'default:' ...
                'if(window.onCommand){' ...
                'try{window.onCommand(cmd);}' ...
                'catch(e){_hc.Data={event:"error",message:e.message};}' ...
                '}}}' ...
                ...
                'function applyEn(en){' ...
                'var el=document.getElementById("css-root");' ...
                'if(el)el.classList.toggle("css-disabled",!en);' ...
                '}' ...
                'function applyErr(err){' ...
                'var el=document.getElementById("css-root");' ...
                'if(el)el.classList.toggle("css-error",!!err);' ...
                '}' ...
                ...
                'function setup(hc){' ...
                '_hc=hc;applyEn(_en);applyErr(_err);' ...
                'hc.addEventListener("DataChanged",function(){' ...
                'var d=_hc.Data;if(!d||!d.cmd)return;' ...
                'if(_ready){dispatch(d);}else{_queue.push(d);}' ...
                '});' ...
                'try{if(window.componentSetup)window.componentSetup(hc);}' ...
                'catch(e){_hc.Data={event:"error",message:e.message};}' ...
                '_ready=true;' ...
                'for(var i=0;i<_queue.length;i++)dispatch(_queue[i]);' ...
                '_queue=[];' ...
                '_hc.Data={event:"ready"};' ...
                '}' ...
                ...
                'window.setup=setup;' ...
                'window.sendEvent=function(d){if(_hc)_hc.Data=d;};' ...
                '})();</script>' ...
                ];

            injected = regexprep(html, '(?i)</body>', [bridge '</body>']);
            if strcmp(injected, html)
                warning('CSSBase:noBodyTag', ...
                    'No </body> tag found — bridge appended to end.');
                injected = [html bridge];
            end
            html = injected;
        end

        function map = varMap()
            %VARMAP  Convenience property name --> CSS custom property name.
            map = struct( ...
                'Color',               '--color', ...
                'BackgroundColor',     '--bg-color', ...
                'FontSize',            '--font-size', ...
                'FontFamily',          '--font-family', ...
                'FontWeight',          '--font-weight', ...
                'FontStyle',           '--font-style', ...
                'LetterSpacing',       '--letter-spacing', ...
                'LineHeight',          '--line-height', ...
                'TextTransform',       '--text-transform', ...
                'TextDecoration',      '--text-decoration', ...
                'HorizontalAlignment', '--text-align', ...
                'VerticalAlignment',   '--align-items', ...
                'BorderRadius',        '--border-radius', ...
                'BoxShadow',           '--box-shadow', ...
                'InsetShadow',         '--inset-shadow', ...
                'Opacity',             '--opacity', ...
                'Cursor',              '--cursor', ...
                'Padding',             '--padding', ...
                'MinWidth',            '--min-width', ...
                'MinHeight',           '--min-height', ...
                'MaxWidth',            '--max-width', ...
                'MaxHeight',           '--max-height', ...
                'Width',               '--width', ...
                'Height',              '--height', ...
                'OuterPadding',        '--outer-padding', ...
                'AspectRatio',         '--aspect-ratio', ...
                'Border',              '--border');
        end

    end

end
