classdef director < handle
%DIRECTOR Handle advanced animations
%   Detailed explanation goes here
    
    properties (Access = private)
        % Video properties
        fps;
        dt;
        duration;
        tick;
        figHandle;
        % File properties
        exportPath;
        exportFile;
        exportFormat;
        % Choreography
        varNames;
        keyframeTime;
        keyframeData;
        keyframeEasing;
    end
    
    methods
        function obj = director()
            % Video properties
            obj.fps = 60;
            obj.dt = 1/60;
            obj.duration = 10;
            obj.tick = -1;
            obj.figHandle = [];
            % File properties
            obj.exportPath = '';
            obj.exportFile = '';
            obj.exportFormat = 'gif';
            % Choreography
            obj.varNames = {};
            obj.keyframeTime = {};
            obj.keyframeData = {};
            obj.keyframeEasing = {};
        end
        
        % OBJECT METHODS OVERRIDES
        function disp(obj)
        %DISP Override disp
            fprintf('I''m a director:\n');
            fprintf('- fps:      %i frames/second\n', obj.fps);
            fprintf('- duration: %i seconds\n', obj.duration);
            fprintf('- vars: %s\n', strjoin(obj.varNames, ', '));
        end
        
        function obj = set(obj, prop, value)
        %SET Set a property
            switch lower(prop)
                case 'fps'
                    obj.fps = value;
                    obj.dt = 1/value;
                case 'duration'
                    obj.duration = value;
                case {'handle' 'fighandle'}
                    obj.figHandle = value;
                case 'path'
                    obj.exportPath = value;
                case 'file'
                    obj.exportFile = value;
                case 'format'
                    obj.exportFormat = value;
                case {'dt' 'ticks' 'timeline' 'currentstate'}
                    error('Property %s is read-only\n', prop);
                otherwise
                    error('Property %s not recognized\n', prop);
            end
        end
        
        function value = get(obj, prop)
        %GET Get a property
            switch lower(prop)
                case 'fps'
                    value = obj.fps;
                case 'dt'
                    value = obj.dt;
                case 'duration'
                    value = obj.duration;
                case 'tick'
                    value = obj.tick;
                case {'handle' 'fighandle'}
                    value = obj.figHandle;
                case 'path'
                    value = obj.exportPath;
                case 'file'
                    value = obj.exportFile;
                case 'format'
                    value = obj.exportFormat;
                case 'ticks'
                    value = obj.getTicks;
                case 'timeline'
                    value = obj.getTimeline;
                case 'currentstate'
                    value = obj.getCurrentState;
                otherwise
                    fprintf('Property %s not recognized\n', prop);
            end
        end
        
        % GENERAL FUNCTIONS
        function obj = getReady(obj)
        %GETREADY Check if everything is ready to start animating
        %   director.getReady() makes a few checks and fills in some unset
        %   properties and should therefore be only called once right
        %   before the first director.update().
        %
        %   See also director.update
        
            % Set the fig handle
            if isempty(obj.figHandle)
                obj.figHandle = gcf;
            end
            
            % Set the exported file's path
            if isempty(obj.exportPath)
                obj.exportPath = pwd;
            end
            
            % Set the exported file's name
            if isempty(obj.exportFile)
                obj.exportFile = datestr(now, 'yyyymmddHHMMSS');
            end
            
            % Set tick to 0, signals everything is ok
            obj.tick = 0;
        end
        
        function obj = update(obj)
        %UPDATE Update the director by advancing the tick count
        %   director.update() advances the tick count and should therefore
        %   be the first method called for each iteration of a loop.
        %
        %   See also director.getReady
        
            % Get director ready if he isn't already
            if obj.tick < 0
                obj.getReady();
            end
            
            % Advance the tick count
            obj.tick = obj.tick + 1;
        end
        
        function ticks = getTicks(obj)
            ticks = 1:obj.time2tick(obj.duration);
        end
        
        function tline = getTimeline(obj)
            tline = obj.tick2time(1:obj.time2tick(obj.duration));
        end
        
        % CHOREOGRAPHY METHODS
        function obj = addAnimatedVariable(obj, name, varargin)
        %ADDANIMATEDVARIABLE Add a variable to animate
            obj.varNames{end+1} = name;
            obj.keyframeTime{end+1}   = [];
            obj.keyframeData{end+1}   = [];
            obj.keyframeEasing{end+1} = [];
        end
        
        function obj = addKeyframe(obj, name, tp, data, varargin)
        %ADDKEYFRAME Add a keyframe to a variable
            p = inputParser();
            p.addRequired('name');
            p.addRequired('tp');
            p.addRequired('data');
            p.addOptional('easing', []);
            p.parse(name, tp, data, varargin{:});
            p = p.Results;
            
            idx = ismember(obj.varNames, p.name);
            obj.keyframeTime{idx}   = [obj.keyframeTime{idx} p.tp];
            obj.keyframeData{idx}   = [obj.keyframeData{idx} p.data];
            if isempty(p.easing)
                obj.keyframeEasing{idx} = [obj.keyframeEasing{idx} ones(size(p.data))];
            else
                obj.keyframeEasing{idx} = [obj.keyframeEasing{idx} p.easing];
            end
        end
        
        function obj = inspect(obj)
        %INSPECT Inspect one or all animated variables
            figure;
            hold on;
            [data tline] = obj.computeTimeline();
            plot(tline, data);
            xlim([0 obj.duration]);
        end
        
        function data = getCurrentState(obj)
        %GETCURRENTSTATE Give a state update
            if obj.tick < 1
                data = [];
            else
                data = obj.getDataAtTick(obj.tick);
            end
        end
        
        function av = getDataAtTime(obj, time)
        %GETDATAATTIME Get variable data at a specified timepoint
            data = obj.computeTimeline();
            av = struct;
            av.time = time;
            av.tick = obj.time2tick(time);
            for iVar = 1:numel(obj.varNames)
                av.(obj.varNames{iVar}) = data(av.tick+1, iVar);
            end
        end
        
        function av = getDataAtTick(obj, tick)
        %GETDATAATTICK Get variable data at a specified tick
            data = obj.computeTimeline();
            av = struct;
            av.time = obj.tick2time(tick);
            av.tick = tick;
            for iVar = 1:numel(obj.varNames)
                av.(obj.varNames{iVar}) = data(av.tick, iVar);
            end
        end
        
        % EXPORT METHODS
        function obj = saveFrame(obj)
        %SAVEFRAME
            switch(obj.exportFormat)
                case 'gif'
                    obj = obj.exportGif();
                otherwise
                    error('Only GIF export is currently supported');
            end
        end
    end
    
    methods (Access = private)
        function tick = time2tick(obj, time)
            tick = floor(time./obj.dt)+1;
        end
        
        function time = tick2time(obj, tick)
            time = obj.dt.*(tick-1);
        end
        
        function obj = exportGif(obj)
            filename = fullfile(obj.exportPath, [obj.exportFile '.gif']);
            frame = getframe(obj.figHandle);
            im = frame2im(frame);
            [imind, cm] = rgb2ind(im, 256);

            if obj.tick == 1
                imwrite(imind, cm, filename, 'gif', 'Loopcount', inf, 'DelayTime', obj.dt);
            else
                imwrite(imind, cm, filename, 'gif', 'WriteMode', 'append', 'DelayTime', obj.dt);
            end
        end
        
        function [data tline] = computeTimeline(obj)
        %COMPUTETIMELINE Compute the entire timeline
            data = zeros(obj.time2tick(obj.duration), numel(obj.varNames));
            tline = obj.tick2time(1:obj.time2tick(obj.duration));
            for iVar = 1:numel(obj.varNames)
                t = obj.keyframeTime{iVar};
                d = obj.keyframeData{iVar};
                easing = obj.keyframeEasing{iVar};
                if numel(t) == 0
                    continue;
                end
                [t iT] = sort(t);
                d = d(iT);
                
                d(t < 0 | t > obj.duration) = [];
                t(t < 0 | t > obj.duration) = [];
                
                if t(1) ~= 0
                    t = [0 t];
                    d = [d(1) d];
                end
                if t(end) ~= obj.duration
                    t = [t obj.duration];
                    d = [d d(end)];
                end
                
                for iKF = 1:numel(t)-1
                    tStart = obj.time2tick(t(iKF));
                    tEnd   = obj.time2tick(t(iKF+1));
                    dInter = obj.interpolate(d(iKF), d(iKF+1), easing(iKF), 1+tEnd-tStart);
                    data(tStart:tEnd, iVar) = dInter;
                end
            end
        end
    end
    
    methods (Static)
        function y = interpolate(valStart, valEnd, easingF, n)
        %INTERPOLATE Apply easing using matlab-easing
            t = linspace(0,1,n);
            y = easing(t, valStart, valEnd-valStart, 1, easingF);
        end
    end
    
end
