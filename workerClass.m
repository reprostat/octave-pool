classdef workerClass < handle
    properties
        host
        processID
        logFile
        logLevel = 0
    end

    properties (Access = private, Constant = true)
        LOGLEVELS = containers.Map(...
            {'info' 'warning' 'error'},...
            [0 1 2] ...
            );
    end

    methods
        function this = workerClass(host='',pid=[],logFile='')
            this.host = host;
            this.processID = pid;
            this.logFile = logFile;
        end

        function delete(this)
            delete(this.logFile);
        end

        function set.logFile(this,val)
            if ~strcmp(this.logFile,val)
                if ~isempty(this.logFile), movefile(this.logFile,val);
                else, fclose(fopen(val,'w'));
                end
                this.logFile = val;
            end
        end

        function addLog(this,varargin)
            logType = regexp(varargin{1},'^.*(?=:)','match');
            if this.LOGLEVELS.isKey(logType{1}) && (this.LOGLEVELS(logType{1}) >= this.logLevel)
                d = datetime;
                varargin = [{['[%s] - ' varargin{1}]} {d.toString} varargin(2:end)];
                if ~strcmp(varargin{1}(end-1:end),'\n'), varargin{1} = [varargin{1} '\n']; end
                fid = fopen(this.logFile,'a');
                fprintf(fid, varargin{:});
                fclose(fid);
            end
        end

    end

    methods  (Static = true)
        function this = empty()
            this = workerClass();
            this = this(false);
        end
    end
end

