classdef CSSuiLabel < CSSBase
%UILABEL  CSS-styled text label component.
%
%   USAGE
%     lbl = uiLabel(parent, 'Text','Status:')
%     lbl = uiLabel(parent, 'Text','Title', 'Style','shadow')
%     lbl.Text = 'Updated';        % live-patches without rebuild
%
%   PROPERTIES
%     Text    Display string                                    default: 'Label'

    properties (Access = public)
        Text = 'Label'
    end

    % =====================================================================
    methods
        function obj = CSSuiLabel(parent, options)
            arguments
                parent = []
                options.Position  (1,4) double  = [10 10 150 28]
                options.Enabled   (1,1) logical = true
                options.TempDir   (1,:) char    = tempdir()
                options.Style                   = 'shadow'
                options.CSS       (1,:) char    = ''
                options.CSSFile   (1,:) char    = ''
                options.Text      (1,:) char    = 'Label'
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

            if isempty(parent), parent = uifigure('Name','CSSuiLabel'); end
            obj@CSSBase(parent, ...
                'Position', options.Position, ...
                'Enabled',  options.Enabled, ...
                'TempDir',  options.TempDir, ...
                'Style',    options.Style, ...
                'CSS',      options.CSS, ...
                'CSSFile',  options.CSSFile);

            obj.applyCSSOptions(options);
            obj.Text = options.Text;
            obj.endInit();
        end

        function set.Text(obj, val)
            obj.Text = val;
            if ~obj.Updating_
                if obj.Loaded_
                    obj.pushCmd(struct('cmd','setText','value',val));
                elseif obj.isReady()
                    obj.refresh();
                end
            end
        end
    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            % Global reset and html/body base are provided by CSSBase infraCSS.
            % setText is handled by the CSSBase bridge targeting id="cssbase-text".
            css = [ ...
                '#uihb{display:flex;align-items:center;width:100%;height:100%;' ...
                'color:var(--color,inherit);' ...
                'background-color:var(--bg-color,transparent);' ...
                'font-size:var(--font-size,13px);' ...
                'font-family:var(--font-family,inherit);' ...
                'font-weight:var(--font-weight,inherit);' ...
                'opacity:var(--opacity,1);' ...
                'cursor:var(--cursor,default);' ...
                'padding:var(--padding,4px 6px);' ...
                'user-select:none;white-space:nowrap;overflow:hidden;' ...
                'text-overflow:ellipsis;}' ...
            ];

            html = [ ...
                '<!DOCTYPE html><html><head><style>' css '</style></head><body>' ...
                '<div id="uihb" class="css-surface css-label"><span id="cssbase-text">' ...
                CSSBase.htmlEscape(obj.Text) '</span></div>' ...
                '</body></html>' ...
            ];
        end

    end

end
