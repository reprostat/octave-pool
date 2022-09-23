classdef workerClass < handle
    properties
        host
        processID
        logFile
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

        function addLog(this,msg)
            d = datetime;
            fid = fopen(this.logFile,'a');
            fprintf(fid, '[%s] - %s\n',d.toString,msg);
            fclose(fid);
        end

    end

    methods  (Static = true)
        function this = empty()
            this = workerClass();
            this = this(false);
        end
    end
end

