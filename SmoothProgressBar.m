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
    %   TimerPeriod        - Timer update interval in seconds (default 0.05)
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
        TimerPeriod (1,1) double {mustBePositive} = 0.05
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

            % Inject the pulse keyframe animation CSS.  The animation only
            % activates when the .css-pulsing class is on the bar element;
            % start()/complete()/reset() toggle that class via the JS bridge.
            % This runs entirely in the browser compositor — no MATLAB timer
            % cycles are spent on the visual pulse effect.
            animCSS = [ ...
                '@keyframes spb-pulse{' ...
                    '0%{opacity:1}' ...
                    '60%{opacity:0.3}' ...
                    '100%{opacity:1}' ...
                '}' ...
                '.css-bar.css-pulsing{' ...
                    'animation:spb-pulse 1.1s ease-in-out infinite;' ...
                '}' ...
            ];
            obj.CSS = [animCSS obj.CSS];
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
                struct('cmd','addClass',  's','.css-bar','cls','css-pulsing'), ...
                struct('cmd','setVar','name','--transition-duration','value',sprintf('%.3fs',obj.TimerPeriod)), ...
                struct('cmd','setVar','name','--color',        'value',''), ...
                struct('cmd','setVar','name','--progress-pct', 'value',sprintf('%.4f%%',initPct)), ...
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
                struct('cmd','removeClass','s','.css-bar','cls','css-pulsing'), ...
                struct('cmd','setVar','name','--color',        'value',obj.hex_(cmap(end,:))), ...
                struct('cmd','setVar','name','--progress-pct', 'value','100.0000%'), ...
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
                struct('cmd','removeClass','s','.css-bar','cls','css-pulsing'), ...
                struct('cmd','setVar','name','--color',        'value',''), ...
                struct('cmd','setVar','name','--progress-pct', 'value','0.0000%'), ...
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
            % Inject a minimal window.onCommand handler so CSSBase's bridge
            % can forward addClass / removeClass commands to DOM elements.
            % This is the mechanism that starts and stops the CSS pulse
            % animation without any MATLAB-side timer driving the visuals.
            script = [ ...
                '<script>' ...
                'window.onCommand=function(c){' ...
                    'var e=document.querySelector(c.s);if(!e)return;' ...
                    'if(c.cmd==="addClass")e.classList.add(c.cls);' ...
                    'else if(c.cmd==="removeClass")e.classList.remove(c.cls);' ...
                '};' ...
                '</script>' ...
            ];
            html = strrep(html, '</body>', [script '</body>']);
        end

    end

    % =====================================================================
    methods (Access = private)

        function tick_(obj)
            if ~isvalid(obj) || isempty(obj.StartTime_), return; end

            if isempty(obj.AvgIterTime_)
                % No timing data yet — the CSS animation is pulsing the bar
                % in the browser.  Just keep the progress indicator current.
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
                    struct('cmd','removeClass','s','.css-bar','cls','css-pulsing'), ...
                    struct('cmd','setVar','name','--color',        'value',obj.hex_(cmap(idx,:))), ...
                    struct('cmd','setVar','name','--progress-pct', 'value',sprintf('%.4f%%',pct)), ...
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
