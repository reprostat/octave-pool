classdef workerClass < handle
    properties
        host
        processID
        logFile
        logLevel
    end

    properties (Access = private, Constant = true)
        LOGLEVELS = containers.Map(...
            {'info' 'warning' 'error'},...
            [0 1 2] ...
            );
    end

    methods
        function this = workerClass(varargin)
            thisProc = strsplit(char(javaMethod('getName',javaMethod('getRuntimeMXBean','java.lang.management.ManagementFactory'))),'@');

            if isstruct(varargin{1}) % load from struct
                varargin = {varargin{1}.logFile,varargin{1}.logLevel};
            end

            argParse = inputParser;
            argParse.addOptional('logFile','',@ischar);
            argParse.addOptional('logLevel',0,@isnumeric);
            argParse.addOptional('pid',str2double(thisProc{1}),@isnumeric);
            argParse.addOptional('host',thisProc{2},@ischar);
            argParse.parse(varargin{:});

            this.host = argParse.Results.host;
            this.processID = argParse.Results.pid;
            this.logFile = argParse.Results.logFile;
            this.logLevel = argParse.Results.logLevel;
        end

        function val = struct(this)
            val = struct('logFile',this.logFile,'logLevel',this.logLevel);
        end

        function set.logFile(this,val)
            if ~strcmp(this.logFile,val)
                if ~isempty(this.logFile), movefile(this.logFile,val);
                else, fclose(fopen(val,'w'));
                end
                this.logFile = val;
            end
        end

        function toLog = addLog(this,varargin)
            logType = regexp(varargin{1},'^.*(?=:)','match');
            toLog = this.LOGLEVELS.isKey(logType{1}) && (this.LOGLEVELS(logType{1}) >= this.logLevel);
            if toLog
                varargin = [{['[%s] - ' varargin{1}]} {char(datetime())} varargin(2:end)];
                if ~strcmp(varargin{1}(end-1:end),'\n'), varargin{1} = [varargin{1} '\n']; end
                fid = fopen(this.logFile,'a');
                fprintf(fid, varargin{:});
                fclose(fid);
            end
        end

    end

end

