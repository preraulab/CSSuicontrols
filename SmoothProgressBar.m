classdef SmoothProgressBar < CSSUIProgressBar
    % SmoothProgressBar - Timer-driven smooth progress bar for MATLAB apps
    %
    %   Extends CSSUIProgressBar with continuous-time animation: a timer
    %   interpolates bar position between iteration updates, a colormap
    %   drives the fill colour, and an EMA estimates time remaining.
    %
    %   During the first iteration (before timing data is available) the bar
    %   pulses via a CSS keyframe animation running in the browser compositor
    %   at 60 fps, independent of MATLAB's timer and event loop.
    %
    % USAGE:
    %   pb = SmoothProgressBar(parent)          % set N later via pb.N = 10
    %   pb = SmoothProgressBar(parent, N)       % positional N
    %   pb = SmoothProgressBar(parent, 'N', N)  % name-value N
    %
    %   Any CSSUIProgressBar / CSSBase styling option can also be passed:
    %   pb = SmoothProgressBar(parent, 10, 'Color','#e53935', 'BarHeight',0.7)
    %
    % INPUTS:
    %   parent  - UI container (uigridlayout, uifigure, uipanel, etc.)
    %   N       - Total number of iterations / work units (positive scalar)
    %
    % PROPERTIES:
    %   N                  - Total iterations
    %   Colormap           - Colormap name for the fill gradient (default 'turbo')
    %   ShowTimeRemaining  - Show time-remaining string in the label
    %   ShowPercentage     - Show percentage in the label
    %   TimerPeriod        - Timer update interval in seconds (default 0.25)
    %
    %   All CSSUIProgressBar / CSSBase styling properties are also available
    %   (Color, BackgroundColor, BarHeight, BarBorderRadius, FontSize, etc.)
    %
    % METHODS:
    %   start()              - Start / restart the animation timer
    %   updateIteration(k)   - Notify that iteration k has completed
    %   complete()           - Force bar to 100% immediately
    %   reset()              - Reset bar to 0 and stop the timer
    %
    % EXAMPLE:
    %   fig = uifigure('Position',[100 100 600 80]);
    %   gl  = uigridlayout(fig,[1 1]);
    %
    %   pb = SmoothProgressBar(gl, 10);
    %   pb.ShowPercentage    = true;
    %   pb.ShowTimeRemaining = true;
    %
    %   pb.start();
    %   for k = 1:10
    %       pause(2 + rand);
    %       pb.updateIteration(k);
    %   end
    %
    % =========================================================================
    %                  DYNAM-O Toolbox  |  Prerau Laboratory
    % =========================================================================

    % =====================================================================
    properties
        N (1,1) double {mustBeNonnegative} = 0
        TimerPeriod (1,1) double {mustBePositive} = 0.25
        Colormap = 'turbo'
        ShowTimeRemaining (1,1) logical = true
        ShowPercentage    (1,1) logical = true
    end

    % =====================================================================
    properties (Access = private)
        Timer_
        Current_     (1,1) double  = 0
        LastIterTime_               % tic token from previous updateIteration
        AvgIterTime_                % EMA of per-iteration wall-clock time
        StartTime_                  % tic token from start()
        IsFinal_     (1,1) logical = false
        LastPct_     (1,1) double  = 0
    end

    % =====================================================================
    methods

        function obj = SmoothProgressBar(parent, varargin)
            % Support positional N:  SmoothProgressBar(parent, 10)
            if ~isempty(varargin) && isnumeric(varargin{1}) && isscalar(varargin{1})
                varargin = [{'N'}, varargin];
            end

            % Strip SmoothProgressBar-only keys so they don't reach
            % the CSSUIProgressBar / CSSBase argument validator.
            spbKeys  = {'N','TimerPeriod','Colormap','ShowTimeRemaining','ShowPercentage'};
            spbPairs = {};
            baseArgs = {};
            hasTextPos = false;
            i = 1;
            while i <= numel(varargin)
                key = varargin{i};
                if ischar(key) && ismember(key, spbKeys) && i < numel(varargin)
                    spbPairs{end+1} = key;        %#ok<AGROW>
                    spbPairs{end+1} = varargin{i+1}; %#ok<AGROW>
                    i = i + 2;
                else
                    if ischar(key) && strcmpi(key,'TextPosition')
                        hasTextPos = true;
                    end
                    baseArgs{end+1} = varargin{i}; %#ok<AGROW>
                    i = i + 1;
                end
            end

            % Default TextPosition to 'above' for the status label
            if ~hasTextPos
                baseArgs = [{'TextPosition','above'}, baseArgs];
            end

            obj@CSSUIProgressBar(parent, baseArgs{:});

            % Apply SmoothProgressBar-specific options
            for k = 1:2:numel(spbPairs)
                obj.(spbPairs{k}) = spbPairs{k+1};
            end
            % Animation CSS is injected via buildHTML() into a dedicated
            % <style id="spb-anim"> that CSSBase's setCSS never touches,
            % so the @keyframes definition remains stable across property
            % changes and animation-play-state toggling works reliably.
        end

        function delete(obj)
            obj.cleanupTimer_();
        end

        % ------------------------------------------------------------------

        function start(obj)
            obj.cleanupTimer_();

            obj.Current_      = 0;
            obj.AvgIterTime_  = [];
            obj.LastIterTime_ = [];
            obj.StartTime_    = tic;
            obj.IsFinal_      = false;
            obj.LastPct_      = 0;

            initPct = 100 / max(obj.N, 1);
            batch.cmd      = 'batch';
            batch.commands = { ...
                struct('cmd','setVar','name','--spb-play-state',     'value','running'), ...
                struct('cmd','setVar','name','--transition-duration', 'value',sprintf('%.3fs',obj.TimerPeriod)), ...
                struct('cmd','setVar','name','--color',               'value',''), ...
                struct('cmd','setVar','name','--progress-pct',        'value',sprintf('%.4f%%',initPct)), ...
                struct('cmd','setText','value',obj.buildLabel_(0,'--:--')) ...
            };
            obj.pushCmd(batch);

            obj.Timer_ = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'Period',        obj.TimerPeriod, ...
                'TimerFcn',      @(~,~) obj.tick_());
            start(obj.Timer_);
        end

        function updateIteration(obj, iteration)
            if iteration > obj.N
                error('SmoothProgressBar:iterationExceedsN', ...
                      'Iteration (%d) exceeds N (%d).', iteration, obj.N);
            end
            now_ = tic;
            if ~isempty(obj.LastIterTime_)
                dt = toc(obj.LastIterTime_);
                if isempty(obj.AvgIterTime_)
                    obj.AvgIterTime_ = dt;
                else
                    obj.AvgIterTime_ = 0.15*dt + 0.85*obj.AvgIterTime_;
                end
            end
            obj.LastIterTime_ = now_;
            obj.Current_      = iteration;
        end

        function complete(obj)
            obj.IsFinal_ = true;
            obj.cleanupTimer_();
            obj.Current_ = obj.N;
            obj.LastPct_ = 100;
            cmap = obj.colormap_();
            batch.cmd      = 'batch';
            batch.commands = { ...
                struct('cmd','setVar','name','--spb-play-state', 'value','paused'), ...
                struct('cmd','setVar','name','--color',          'value',obj.hex_(cmap(end,:))), ...
                struct('cmd','setVar','name','--progress-pct',   'value','100.0000%'), ...
                struct('cmd','setText','value',obj.buildLabel_(100,'00:00')) ...
            };
            obj.pushCmd(batch);
            drawnow limitrate
        end

        function reset(obj)
            %RESET  Stop the timer and return the bar to zero.
            obj.cleanupTimer_();
            obj.Current_      = 0;
            obj.AvgIterTime_  = [];
            obj.LastIterTime_ = [];
            obj.StartTime_    = [];
            obj.IsFinal_      = false;
            obj.LastPct_      = 0;
            batch.cmd      = 'batch';
            batch.commands = { ...
                struct('cmd','setVar','name','--spb-play-state', 'value','paused'), ...
                struct('cmd','setVar','name','--color',           'value',''), ...
                struct('cmd','setVar','name','--progress-pct',    'value','0.0000%'), ...
                struct('cmd','setText','value',obj.buildLabel_(0,'--:--')) ...
            };
            obj.pushCmd(batch);
            drawnow limitrate
        end

    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            html = buildHTML@CSSUIProgressBar(obj);
            % Inject a dedicated <style id="spb-anim"> directly into the
            % HTML before </head>.  CSSBase's setCSS only ever updates
            % cssbase-vars and cssbase-override — it never touches spb-anim.
            % That makes the @keyframes definition stable for the lifetime
            % of the page, which is required for animation-play-state
            % toggling (via --spb-play-state setVar) to work reliably.
            html = strrep(html, '</head>', [ ...
                '<style id="spb-anim">' ...
                '@keyframes spb-pulse{' ...
                    '0%{opacity:1}' ...
                    '60%{opacity:0.3}' ...
                    '100%{opacity:1}' ...
                '}' ...
                '.css-bar{' ...
                    'animation:spb-pulse 1.1s ease-in-out infinite;' ...
                    'animation-play-state:var(--spb-play-state,running);' ...
                '}' ...
                '</style>' ...
                '</head>' ...
            ]);
        end

    end

    % =====================================================================
    methods (Access = private)

        function tick_(obj)
            if ~isvalid(obj) || isempty(obj.StartTime_), return; end

            if isempty(obj.AvgIterTime_)
                % No timing data yet — CSS animation is pulsing the bar in
                % the browser compositor.  Just keep the progress indicator
                % current; no MATLAB-side animation work needed.
                pulsePct = 100 * max(obj.Current_, 1) / max(obj.N, 1);
                batch.cmd      = 'batch';
                batch.commands = { ...
                    struct('cmd','setVar','name','--progress-pct','value',sprintf('%.4f%%',pulsePct)), ...
                    struct('cmd','setText','value',obj.buildLabel_(0,'--:--')) ...
                };
                obj.pushCmd(batch);
            else
                % Timing known — stop the pulse and drive smooth progress.
                [pct, trem] = obj.estimateProgress_();
                pct          = max(pct, obj.LastPct_);   % enforce monotonicity
                obj.LastPct_ = pct;
                cmap     = obj.colormap_();
                idx      = max(1, round((pct/100) * size(cmap,1)));
                batch.cmd      = 'batch';
                batch.commands = { ...
                    struct('cmd','setVar','name','--spb-play-state', 'value','paused'), ...
                    struct('cmd','setVar','name','--color',          'value',obj.hex_(cmap(idx,:))), ...
                    struct('cmd','setVar','name','--progress-pct',   'value',sprintf('%.4f%%',pct)), ...
                    struct('cmd','setText','value',obj.buildLabel_(pct,trem)) ...
                };
                obj.pushCmd(batch);

                if obj.Current_ >= obj.N && obj.N > 0 && ~obj.IsFinal_
                    obj.complete();
                end
            end
        end

        function [pct, trem] = estimateProgress_(obj)
            if isempty(obj.AvgIterTime_) || obj.N == 0
                pct  = 0;
                trem = '--:--';
                return
            end
            elapsed  = toc(obj.StartTime_);
            total    = obj.AvgIterTime_ * obj.N;
            pct      = min(100, (elapsed / total) * 100);
            trem     = char(duration(0, 0, max(total-elapsed,0), 'Format','mm:ss'));
        end

        function str = buildLabel_(obj, pct, trem)
            str = sprintf('Progress: %d/%d', obj.Current_, obj.N);
            if obj.ShowPercentage
                str = sprintf('%s  %.1f%%', str, pct);
            end
            if obj.ShowTimeRemaining
                str = sprintf('%s | Time Remaining: %s', str, trem);
            end
        end

        function cmap = colormap_(obj)
            try
                cmap = feval(obj.Colormap, 256);
            catch
                cmap = turbo(256);
            end
        end

        function hex = hex_(~, rgb)
            hex = sprintf('#%02x%02x%02x', round(rgb*255));
        end

        function cleanupTimer_(obj)
            if ~isempty(obj.Timer_) && isvalid(obj.Timer_)
                stop(obj.Timer_);
                delete(obj.Timer_);
            end
            obj.Timer_ = [];
        end

    end
end
