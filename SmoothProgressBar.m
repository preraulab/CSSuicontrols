classdef SmoothProgressBar < CSSUIProgressBar
    %SMOOTHPROGRESSBAR  Browser-driven smooth progress bar for MATLAB apps
    %
    %   Usage:
    %       pb = SmoothProgressBar(parent)          % set N later via pb.N
    %       pb = SmoothProgressBar(parent, N)
    %       pb = SmoothProgressBar(parent, 'N', N)
    %       pb = SmoothProgressBar(parent, 10, 'Color', '#e53935', 'BarHeight', 0.7)
    %
    %   Inputs:
    %       parent : graphics container - UI container (uigridlayout, uifigure, uipanel, ...) -- required
    %       N      : double - total number of iterations / work units (optional, positive scalar)
    %
    %   Name-Value Pairs:
    %       'N'                 : double - total iterations (default: [])
    %       'Colormap'          : char - colormap for the fill gradient (default: 'turbo')
    %       'ShowTimeRemaining' : logical - show time-remaining in label (default: false)
    %       'ShowPercentage'    : logical - show percentage in label (default: false)
    %       'TimerPeriod'       : double - CSS transition hint in seconds (default: 0.25)
    %       (plus all CSSUIProgressBar / CSSBase styling properties)
    %
    %   Outputs:
    %       pb : SmoothProgressBar handle
    %
    %   Notes:
    %       Extends CSSUIProgressBar with continuous-time animation. All frame
    %       work (progress interpolation, colormap lookup, label formatting,
    %       time-remaining estimation) runs inside the uihtml Chromium instance
    %       via requestAnimationFrame at native 60 fps. MATLAB only sends
    %       discrete lifecycle events — no MATLAB-side animation timer, no
    %       per-tick colormap allocation, no per-tick IPC round-trip.
    %
    %       During the first iteration (before timing data is available) the
    %       bar pulses via a requestAnimationFrame opacity animation running
    %       in the browser compositor, independent of MATLAB's event loop.
    %
    %       Key methods: start(), updateIteration(k), complete(), reset().
    %
    %   Example:
    %       fig = uifigure('Position',[100 100 600 80]);
    %       gl  = uigridlayout(fig,[1 1]);
    %       pb  = SmoothProgressBar(gl, 10);
    %       pb.ShowPercentage    = true;
    %       pb.ShowTimeRemaining = true;
    %
    %   See also: CSSUIProgressBar, CSSBase, CSSProgressBarDemo
    %
    %   ∿∿∿  Prerau Laboratory MATLAB Codebase · sleepEEG.org  ∿∿∿
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
        % Live label prefix shown to the left of the count (e.g. for a
        % batch loop you can set this to "Subject 3/12, Channel 2/4" and
        % update it each iteration). Empty prefix renders just "k/N …".
        LabelPrefix       (1,:) char    = ''
    end

    % =====================================================================
    properties (Access = private)
        Current_     (1,1) double  = 0
        LastIterTime_               % tic token from previous updateIteration
        AvgIterTime_                % EMA of per-iteration wall-clock time (s)
        StartTime_                  % tic token from start()
        IsFinal_     (1,1) logical = false
        Running_     (1,1) logical = false
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
        end

        % ------------------------------------------------------------------

        function start(obj)
            % Compute the colormap ONCE and ship it to the browser as a
            % pre-hex-encoded array; JS will index it every frame.
            cmap    = obj.safeColormap_();
            hexList = cell(1, size(cmap,1));
            for k = 1:size(cmap,1)
                hexList{k} = sprintf('#%02x%02x%02x', round(cmap(k,:)*255));
            end

            obj.Current_      = 0;
            obj.AvgIterTime_  = [];
            obj.StartTime_    = tic;
            obj.LastIterTime_ = obj.StartTime_;
            obj.IsFinal_      = false;
            obj.Running_      = true;

            anim.cmd               = 'startAnim';
            anim.N                 = obj.N;
            anim.transitionSeconds = obj.TimerPeriod;
            anim.colormap          = hexList;
            anim.showPct           = obj.ShowPercentage;
            anim.showTime          = obj.ShowTimeRemaining;
            anim.labelPrefix       = obj.LabelPrefix;
            obj.pushCmd(anim);
            % Flush so startAnim reaches JS before any caller sets
            % LabelPrefix / pushes updateAnim. Without this, back-to-back
            % writes to HTMLComponent.Data collapse to the latest value
            % and JS sees only the trailing cmd (with S still null), so
            % the rAF loop never starts and the bar appears inert.
            drawnow limitrate
        end

        function updateIteration(obj, iteration)
            if iteration > obj.N
                error('SmoothProgressBar:iterationExceedsN', ...
                      'Iteration (%d) exceeds N (%d).', iteration, obj.N);
            end
            if isempty(obj.StartTime_)
                % start() was never called or reset() cleared it.
                % Skip silently so callers can safely reset a halted bar.
                return;
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

            if isempty(obj.AvgIterTime_)
                avgMs = 0;
            else
                avgMs = obj.AvgIterTime_ * 1000;
            end
            elapsedMs = toc(obj.StartTime_) * 1000;

            upd.cmd       = 'updateAnim';
            upd.iteration = iteration;
            upd.avgIterMs = avgMs;
            upd.elapsedMs = elapsedMs;
            obj.pushCmd(upd);
            % Force the Chromium event loop to actually consume this
            % updateAnim Data write before MATLAB's next instruction
            % (typically the caller's next-iteration LabelPrefix →
            % setPrefix push). drawnow alone flushes MATLAB's render
            % queue but does NOT wait for the embedded webview to read
            % HTMLComponent.Data — so two writes back-to-back collapse
            % to the latest value and JS never sees the updateAnim that
            % carries avgIterMs > 0. The pause(0.005) yields the CPU
            % long enough for the webview's onCommand to fire on this
            % payload before the next write replaces it.
            drawnow
            pause(0.005)

            if obj.Current_ >= obj.N && obj.N > 0 && ~obj.IsFinal_
                obj.complete();
            end
        end

        function complete(obj)
            obj.IsFinal_ = true;
            obj.Running_ = false;
            obj.Current_ = obj.N;
            obj.pushCmd(struct('cmd','completeAnim'));
            drawnow limitrate
        end

        function set.LabelPrefix(obj, val)
            obj.LabelPrefix = val;
            % If a run is already underway, push the new prefix to the
            % browser so the next animation frame picks it up.
            if obj.Running_
                obj.pushCmd(struct('cmd','setPrefix','value',val));
                drawnow limitrate
            end
        end

        function reset(obj)
            %RESET  Return the bar to zero and stop animation.
            obj.Current_      = 0;
            obj.AvgIterTime_  = [];
            obj.LastIterTime_ = [];
            obj.StartTime_    = [];
            obj.IsFinal_      = false;
            obj.Running_      = false;
            obj.pushCmd(struct('cmd','resetAnim'));
            drawnow limitrate
        end

    end

    % =====================================================================
    methods (Access = protected)

        function html = buildHTML(obj)
            html = buildHTML@CSSUIProgressBar(obj);

            % Inject a window.onCommand handler that runs the full animation
            % loop in the browser via requestAnimationFrame.  MATLAB only
            % sends discrete events (startAnim / updateAnim / completeAnim /
            % resetAnim); every frame's progress %, color, and label is
            % computed here at native 60 fps on the Chromium compositor
            % thread, independent of MATLAB's event loop.
            script = [ ...
                '<script>(function(){' ...
                'var S=null,raf=null;' ...
                'function pad(n){return (n<10?"0":"")+n;}' ...
                'function mmss(ms){' ...
                    'var s=Math.max(0,Math.floor(ms/1000));' ...
                    'return pad(Math.floor(s/60))+":"+pad(s%60);' ...
                '}' ...
                'function fmtLabel(pct,tremStr){' ...
                    'var pfx=S.labelPrefix||"";' ...
                    'var s=pfx?(pfx+" - "+S.current+"/"+S.N):(S.current+"/"+S.N);' ...
                    'if(S.showPct){s+="  "+pct.toFixed(1)+"%";}' ...
                    'if(S.showTime){s+=" | "+tremStr;}' ...
                    'return s;' ...
                '}' ...
                'function setProg(pct){' ...
                    'var el=document.querySelector(".css-bar");' ...
                    'if(el)el.style.width=pct.toFixed(4)+"%";' ...
                '}' ...
                'function setColor(hex){' ...
                    'var el=document.querySelector(".css-bar");' ...
                    'if(el)el.style.background=hex;' ...
                '}' ...
                'function setLabel(txt){' ...
                    'var el=document.getElementById("cssbase-text");' ...
                    'if(el)el.textContent=txt;' ...
                '}' ...
                'function setOpacity(o){' ...
                    'var el=document.querySelector(".css-bar");' ...
                    'if(el)el.style.opacity=o;' ...
                '}' ...
                'function setTransition(sec){' ...
                    'document.documentElement.style.setProperty(' ...
                        '"--transition-duration",sec+"s");' ...
                '}' ...
                'function step(ts){' ...
                    'if(!S||!S.running){raf=null;return;}' ...
                    'if(S.avgIterMs>0){' ...
                        'var elapsed=S.elapsedBaseMs+(ts-S.baseTs);' ...
                        'var total=S.avgIterMs*S.N;' ...
                        'var pct=total>0?Math.min(100,100*elapsed/total):0;' ...
                        'if(pct<S.prevPct)pct=S.prevPct;' ...
                        'S.prevPct=pct;' ...
                        'var idx=Math.max(0,Math.min(S.colormap.length-1,' ...
                            'Math.round(pct/100*(S.colormap.length-1))));' ...
                        'setProg(pct);' ...
                        'setColor(S.colormap[idx]);' ...
                        'var trem=Math.max(0,total-elapsed);' ...
                        'setLabel(fmtLabel(pct,mmss(trem)));' ...
                    '}else{' ...
                        'var dur=1100;' ...
                        'setOpacity(0.55+0.45*Math.cos(' ...
                            '2*Math.PI*((ts-S.pulseT0)%dur)/dur));' ...
                        'var pulsePct=100*Math.max(S.current,1)/Math.max(S.N,1);' ...
                        'setProg(pulsePct);' ...
                        'setLabel(fmtLabel(0,"--:--"));' ...
                    '}' ...
                    'raf=requestAnimationFrame(step);' ...
                '}' ...
                'window.onCommand=function(c){' ...
                    'if(c.cmd==="startAnim"){' ...
                        'S={running:true,N:c.N,current:0,' ...
                            'colormap:c.colormap||[],' ...
                            'showPct:!!c.showPct,showTime:!!c.showTime,' ...
                            'labelPrefix:c.labelPrefix||"",' ...
                            'avgIterMs:0,elapsedBaseMs:0,' ...
                            'baseTs:performance.now(),' ...
                            'pulseT0:performance.now(),' ...
                            'prevPct:0};' ...
                        'setTransition(0);' ...
                        'setColor("");' ...
                        'setOpacity(1);' ...
                        'setProg(100/Math.max(S.N,1));' ...
                        'var pfxInit=S.labelPrefix||"";' ...
                        'setLabel((pfxInit?(pfxInit+" - "):"")+"0/"+S.N' ...
                            '+(S.showPct?"  0.0%":"")' ...
                            '+(S.showTime?" | --:--":""));' ...
                        'if(raf)cancelAnimationFrame(raf);' ...
                        'raf=requestAnimationFrame(step);' ...
                    '}else if(c.cmd==="updateAnim"){' ...
                        'if(!S)return;' ...
                        'S.current=c.iteration;' ...
                        'if(c.avgIterMs&&c.avgIterMs>0){' ...
                            'S.avgIterMs=c.avgIterMs;' ...
                            'S.elapsedBaseMs=c.elapsedMs||0;' ...
                            'S.baseTs=performance.now();' ...
                            'setOpacity(1);' ...
                        '}' ...
                    '}else if(c.cmd==="setPrefix"){' ...
                        'if(!S)return;' ...
                        'S.labelPrefix=c.value||"";' ...
                    '}else if(c.cmd==="completeAnim"){' ...
                        'if(!S)return;' ...
                        'S.running=false;' ...
                        'S.current=S.N;' ...
                        'if(raf){cancelAnimationFrame(raf);raf=null;}' ...
                        'setOpacity(1);' ...
                        'setProg(100);' ...
                        'var last=S.colormap.length?' ...
                            'S.colormap[S.colormap.length-1]:"";' ...
                        'setColor(last);' ...
                        'setLabel(fmtLabel(100,"00:00"));' ...
                    '}else if(c.cmd==="resetAnim"){' ...
                        'if(raf){cancelAnimationFrame(raf);raf=null;}' ...
                        'if(S){S.running=false;}' ...
                        'setOpacity(1);' ...
                        'setColor("");' ...
                        'setProg(0);' ...
                        'setLabel("0/"+((S&&S.N)||0)+"  0.0% | --:--");' ...
                        'S=null;' ...
                    '}' ...
                '};' ...
                '})();</script>' ...
            ];
            html = strrep(html, '</body>', [script '</body>']);
        end

    end

    % =====================================================================
    methods (Access = private)

        function cmap = safeColormap_(obj)
            try
                cmap = feval(obj.Colormap, 256);
            catch
                cmap = turbo(256);
            end
        end

    end
end
