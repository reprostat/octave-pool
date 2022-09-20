classdef workerClass < handle
    properties
        host
        processID
        logFile
    endproperties

    methods
        function this = workerClass(host='',pid=[],logFile='')
            this.host = host;
            this.processID = pid;
            this.logFile = logFile;
        endfunction

        function delete(this)
            delete(this.logFile);
        endfunction

        function set.logFile(this,val)
            if ~strcmp(this.logFile,val)
                if ~isempty(this.logFile), movefile(this.logFile,val);
                else, fclose(fopen(val,'w'));
                endif
                this.logFile = val;
            endif
        endfunction

        function addLog(this,msg)
            d = datetime;
            fid = fopen(this.logFile,'a');
            fprintf(fid, '[%s] - %s\n',d.toString,msg);
            fclose(fid);
        endfunction

    endmethods

    methods  (Static = true)
        function this = empty()
            this = workerClass();
            this = this(false);
        endfunction
    endmethods
endclassdef

