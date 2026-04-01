classdef CSSPreset
%CSSPreset  Named CSS style presets for CSSBase components.
%
%   A CSSPreset is a pure data container — it holds convenience property
%   values and a raw CSS string.  It has no behaviour beyond static factory
%   methods.  Pass it to any CSSBase component via the 'Style' argument.
%
%   USAGE
%     btn = CSSuiButton(parent, 'Style', 'shadow');          % by name
%     btn = CSSuiButton(parent, 'Style', CSSPreset.shadow()); % by object
%
%     % Customise a preset before applying:
%     p = CSSPreset.flat();
%     p.Color = '#2a7a2a';
%     btn = CSSuiButton(parent, 'Style', p);
%
%     % Change preset after construction:
%     btn.setStyle('neon');
%
%   AVAILABLE PRESETS
%     CSSPreset.shadow()  — Neumorphic raised-shadow (default for buttons/labels)
%     CSSPreset.flat()    — Clean flat modern style
%     CSSPreset.glass()   — Frosted-glass / glassmorphism style
%     CSSPreset.neon()    — Cyberpunk dark with glowing cyan borders
%     CSSPreset.pill()    — Rounded pill with solid purple accent
%     CSSPreset.dark()    — Dark-mode flat (VS Code style)
%     CSSPreset.list()    — Cell array of preset names
%
%   HOW PRESETS WORK
%   A preset sets convenience properties (Color, BackgroundColor, …) and
%   appends a CSS string that targets the standard element schema:
%
%     .css-surface    — primary rendered surface (button, input wrapper, etc.)
%     .css-clickable  — interactive elements; adds hover/active animations
%     .css-label      — adjacent text label (EditField, Dropdown, etc.)
%
%   These class names are stable across all components, so a single preset
%   CSS string styles every component type consistently.
%
%   UTILITIES
%     CSSPreset.scaleShadow(shadow, factor)   scale shadow px/em values
%     CSSPreset.invertShadow(shadow)          flip outset → inset shadow

    % =====================================================================
    %  Properties — same names as CSSBase convenience properties + CSS
    % =====================================================================
    properties (Access = public)
        Color           = ''
        BackgroundColor = ''
        FontSize        = ''
        FontFamily      = ''
        FontWeight      = ''
        BorderRadius    = ''
        BoxShadow       = ''
        InsetShadow     = ''
        Opacity         = ''
        Cursor          = ''
        Padding         = ''
        OuterPadding    = ''
        CSS             = ''    % Raw CSS string (hover, active, etc.)
    end

    % =====================================================================
    %  Preset factories
    % =====================================================================
    methods (Static)

        function p = shadow()
            %SHADOW  Neumorphic raised-shadow preset.
            p = CSSPreset();
            p.Color           = '#414c57';
            p.BackgroundColor = '';      % transparent — components use their own bg defaults
            p.FontFamily      = '"Segoe UI",system-ui,sans-serif';
            p.FontSize        = '12px';
            p.BorderRadius    = '8px';

            % Raised (outset) shadow for buttons
            p.BoxShadow   = '3px 3px 6px rgba(0,0,0,0.15),-3px -3px 6px rgba(255,255,255,0.9)';
            % Carved-in (inset) shadow for inputs, dropdowns, textareas
            p.InsetShadow = 'inset 2px 2px 5px #bcbcbc,inset -2px -2px 5px #ffffff';
            % Room for hover shadow (4px offset + 8px blur) plus 2px translateY
            p.OuterPadding = '8px';

            p.CSS = [ ...
                '.css-surface{border:none;transition:box-shadow 0.15s ease,transform 0.15s ease;' ...
                '.css-label{box-shadow:none!important;background-color:transparent!important;}' ...
                '.css-clickable{cursor:pointer;user-select:none;}' ...
                '.css-clickable:hover{transform:translateY(-2px);' ...
                'box-shadow:4px 4px 8px rgba(0,0,0,0.18),-4px -4px 8px rgba(255,255,255,0.9);}' ...
                '.css-clickable:active{transform:translateY(1px);' ...
                'box-shadow:inset 2px 2px 4px rgba(0,0,0,0.18),inset -2px -2px 4px rgba(255,255,255,0.9);}' ...
            ];
        end

        function p = flat()
            %FLAT  Clean flat modern preset.
            p = CSSPreset();
            p.Color           = '#333333';
            p.BackgroundColor = '#ffffff';
            p.FontFamily      = '"Segoe UI",system-ui,sans-serif';
            p.FontSize        = '13px';
            p.BorderRadius    = '6px';
            p.BoxShadow       = 'none';
            p.OuterPadding    = '3px';

            p.CSS = [ ...
                '.css-surface.css-clickable{border:1px solid #d0d0d0;user-select:none;' ...
                'transition:border-color 0.15s ease,background-color 0.15s ease,transform 0.12s ease;}' ...
                '.css-label{box-shadow:none!important;background-color:transparent!important;border:none!important;}' ...
                '.css-surface.css-clickable:hover{border-color:#999;background-color:#f8f8f8;transform:translateY(-1px);}' ...
                '.css-surface.css-clickable:active{background-color:#f0f0f0;transform:translateY(1px);}' ...
                '.css-surface:focus{outline:2px solid #4a90d9;outline-offset:1px;}' ...
            ];
        end

        function p = glass()
            %GLASS  Frosted-glass / glassmorphism preset.
            %   Note: backdrop-filter is omitted — it blocks pointer events in
            %   MATLAB's embedded webview.  The glass look comes from the
            %   semi-transparent background and white border instead.
            p = CSSPreset();
            p.Color           = '#1a1a2e';
            p.BackgroundColor = 'rgba(255,255,255,0.25)';
            p.FontFamily      = '"Segoe UI",system-ui,sans-serif';
            p.FontSize        = '13px';
            p.BorderRadius    = '12px';
            p.BoxShadow       = '0 4px 20px rgba(0,0,0,0.12)';
            p.InsetShadow     = 'inset 0 1px 0 rgba(255,255,255,0.6),inset 0 -1px 0 rgba(0,0,0,0.05)';
            % Room for hover shadow to bleed outward
            p.OuterPadding    = '10px';

            p.CSS = [ ...
                '.css-surface{' ...
                'user-select:none;' ...
                'transition:background-color 0.2s ease,box-shadow 0.2s ease,transform 0.15s ease;}' ...
                '.css-surface.css-clickable{' ...
                'border:1px solid rgba(255,255,255,0.5);cursor:pointer;}' ...
                '.css-label{box-shadow:none!important;background-color:transparent!important;border:none!important;}' ...
                '.css-surface.css-clickable:hover{' ...
                'background-color:rgba(255,255,255,0.42);' ...
                'box-shadow:0 8px 32px rgba(0,0,0,0.18);' ...
                'transform:translateY(-2px);}' ...
                '.css-surface.css-clickable:active{' ...
                'background-color:rgba(255,255,255,0.15);' ...
                'box-shadow:0 2px 8px rgba(0,0,0,0.1);' ...
                'transform:translateY(1px);}' ...
            ];
        end

        function p = neon()
            %NEON  Cyberpunk dark theme with glowing cyan borders.
            p = CSSPreset();
            p.Color           = '#00e5ff';
            p.BackgroundColor = '#0a0a1a';
            p.FontFamily      = '"Segoe UI",system-ui,monospace';
            p.FontSize        = '12px';
            p.FontWeight      = '600';
            p.BorderRadius    = '4px';
            p.BoxShadow       = '0 0 6px rgba(0,229,255,0.25),0 0 12px rgba(0,229,255,0.1)';
            p.InsetShadow     = 'inset 0 0 8px rgba(0,229,255,0.08)';
            p.OuterPadding    = '8px';

            p.CSS = [ ...
                '.css-surface{' ...
                'border:1px solid rgba(0,229,255,0.4);' ...
                'letter-spacing:0.06em;' ...
                'transition:box-shadow 0.2s ease,border-color 0.2s ease,transform 0.15s ease,' ...
                'background-color 0.2s ease;}' ...
                '.css-label{box-shadow:none!important;border:none!important;' ...
                'background-color:transparent!important;}' ...
                '.css-surface.css-clickable{cursor:pointer;user-select:none;}' ...
                '.css-surface.css-clickable:hover{' ...
                'border-color:rgba(0,229,255,0.9);' ...
                'box-shadow:0 0 10px rgba(0,229,255,0.5),0 0 24px rgba(0,229,255,0.2);' ...
                'transform:translateY(-2px);}' ...
                '.css-surface.css-clickable:active{' ...
                'transform:translateY(1px);' ...
                'box-shadow:0 0 4px rgba(0,229,255,0.3);' ...
                'background-color:rgba(0,229,255,0.08);}' ...
            ];
        end

        function p = pill()
            %PILL  Modern pill-shaped buttons with a solid purple accent.
            p = CSSPreset();
            p.Color           = '#ffffff';
            p.BackgroundColor = '#6c63ff';
            p.FontFamily      = '"Segoe UI",system-ui,sans-serif';
            p.FontSize        = '13px';
            p.FontWeight      = '600';
            p.BorderRadius    = '50px';
            p.BoxShadow       = '0 4px 14px rgba(108,99,255,0.4)';
            p.InsetShadow     = 'inset 0 1px 3px rgba(0,0,0,0.1)';
            p.OuterPadding    = '6px';

            p.CSS = [ ...
                '.css-surface.css-clickable{' ...
                'cursor:pointer;user-select:none;' ...
                'transition:transform 0.15s ease,box-shadow 0.15s ease,background-color 0.15s ease;}' ...
                '.css-label{box-shadow:none!important;background-color:transparent!important;' ...
                'color:#6c63ff!important;}' ...
                '.css-surface.css-clickable:hover{' ...
                'transform:scale(1.05);' ...
                'box-shadow:0 6px 20px rgba(108,99,255,0.55);}' ...
                '.css-surface.css-clickable:active{' ...
                'transform:scale(0.96);' ...
                'box-shadow:0 2px 6px rgba(108,99,255,0.3);}' ...
            ];
        end

        function p = dark()
            %DARK  Dark-mode flat preset (VS Code / editor style).
            p = CSSPreset();
            p.Color           = '#cccccc';
            p.BackgroundColor = '#2d2d2d';
            p.FontFamily      = '"Segoe UI",system-ui,sans-serif';
            p.FontSize        = '13px';
            p.BorderRadius    = '4px';
            p.BoxShadow       = 'none';
            p.InsetShadow     = 'none';
            p.OuterPadding    = '4px';

            p.CSS = [ ...
                '.css-surface.css-clickable{' ...
                'border:1px solid #454545;cursor:pointer;user-select:none;' ...
                'transition:background-color 0.12s ease,border-color 0.12s ease,transform 0.1s ease;}' ...
                '.css-label{box-shadow:none!important;background-color:transparent!important;' ...
                'border:none!important;color:#888!important;}' ...
                '.css-surface.css-clickable:hover{' ...
                'background-color:#3a3a3a;border-color:#666;' ...
                'transform:translateY(-1px);}' ...
                '.css-surface.css-clickable:active{' ...
                'background-color:#252525;border-color:#555;' ...
                'transform:translateY(1px);}' ...
                'input,select,textarea{' ...
                'background-color:#1e1e1e!important;' ...
                'color:#cccccc!important;' ...
                'box-shadow:none!important;}' ...
            ];
        end

        function names = list()
            %LIST  Cell array of available preset names.
            names = {'shadow', 'flat', 'glass', 'neon', 'pill', 'dark'};
        end

    end

    % =====================================================================
    %  Static utilities
    % =====================================================================
    methods (Static)

        function out = scaleShadow(shadow, factor)
            %SCALESHADOW  Multiply all numeric px/em offsets in a box-shadow.
            out = regexprep(shadow, '(-?[\d.]+)(px|em)', ...
                sprintf('${num2str(str2double($1)*%.4g)}$2', factor));
        end

        function out = invertShadow(shadow)
            %INVERTSHADOW  Flip outset shadow to inset (pressed) shadow.
            parts = strtrim(strsplit(shadow, ','));
            for i = 1:numel(parts)
                p = strtrim(parts{i});
                if ~startsWith(p, 'inset')
                    p = regexprep(p, ...
                        '^(\s*)(-?[\d.]+)(px|em)(\s+)(-?[\d.]+)(px|em)', ...
                        '$1${num2str(-str2double($2))}$3$4${num2str(-str2double($5))}$6');
                    p = ['inset ' strtrim(p)]; 
                end
                parts{i} = p;
            end
            out = strjoin(parts, ',');
        end

    end

end
