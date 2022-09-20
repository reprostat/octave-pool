classdef taskClass < handle
    properties
        name
        createDateTime = datetime.empty
        startDateTime = datetime.empty

        parent

        inputArguments = {}
    endproperties

    properties (Hidden)
        folder
        shellFile
    endproperties

    properties (Access = private)
        scriptFile
        diaryFile
        processFile
        outFile = ''
        errorFile
        _worker
    endproperties

    properties (Dependent)
        state
        worker
        finishDateTime
        diary
        errorMessage
        error
    endproperties

    methods
        function this = taskClass(job=[], name='', func=[], nOut=0, args={})
            if isempty(job), return; endif
            this.createDateTime = datetime();

            this.parent = job;
            this.name = sprintf('Task%d_%s',this.parent.latestTaskID+1,name);
            this.folder = fullfile(this.parent.folder,this.name);
            mkdir(this.folder)

            if ispc
              this.shellFile = fullfile(this.folder,'run.bat');
            else
              this.shellFile = fullfile(this.folder,'run.sh');
            endif
            this._worker = workerClass('',[],fullfile(this.folder,'log.txt'));
            this.scriptFile = fullfile(this.folder,'run.m');
            this.diaryFile = fullfile(this.folder,'diary.txt');
            this.processFile = fullfile(this.folder,'process');
            this.errorFile = fullfile(this.folder,'error.mat');
            if nOut > 0, this.outFile = fullfile(this.folder,'out.mat'); endif

            ## assemble command
            pathCommand = '';
            varCommand = '';
            command = func2str(func);
            userVariable = [];
            ## - execute
            if ~isempty(args)
                this.inputArguments = args;
                varStr = sprintf('arg%d,',1:numel(this.inputArguments));
                varList = textscan(varStr,'%s','delimiter',',');
                userVariable = cell2struct(this.inputArguments,varList{1}',2);
                command = [command, '('];
                command = [command, varStr];
                command(end) = ')';
            endif
            ## - output
            if nOut > 0
                outputStr = strjoin(arrayfun(@(o) sprintf('o%d',o), 1:nOut, 'UniformOutput', false),',');
                command = sprintf('[ %s ] = %s; save(''-binary'',''%s'', ''%s'')', outputStr, command, this.outFile, strrep(outputStr,',',''','''));
            endif
            ## - path
            if ~isempty(this.parent.additionalPaths)
                userVariable.reqpath = this.parent.additionalPaths;
                pathCommand = sprintf('load(''%s'',''reqpath'');addpath(reqpath{:});',fullfile(this.folder,'data.mat'));
            endif
            ## - input
            if ~isempty(userVariable)
                save('-binary',fullfile(this.folder,'data.mat'),'-struct','userVariable');
                varCommand = sprintf('load(''%s'',%s);',fullfile(this.folder,'data.mat'),['''' strrep(varStr(1:end-1),',',''',''') '''']);
            endif
            command = [pathCommand, varCommand, command ';'];

            ## create script
            fid = fopen(this.shellFile,'w');
            switch this.parent.pool.type
                case 'Slurm'
                    switch this.parent.pool.shell
                        case 'bash'
                            fprintf(fid,'#!/bin/bash\n');
                    endswitch
            endswitch
            if ~isempty(this.parent.pool.initialConfiguration), fprintf(fid,'%s;',this.parent.pool.initialConfiguration); endif
            fprintf(fid,'%s %s', fullfile(OCTAVE_HOME, 'bin', 'octave-cli'), this.scriptFile);
            fclose(fid);
            fid = fopen(this.scriptFile,'w');
            fprintf(fid,'diary %s;\nfid = fopen(''%s'',''w''); fprintf(fid,''%%d@%%s\\n'',getpid,gethostname); fclose(fid);\ntry\n    %s\ncatch E\n    save(''-binary'',''%s'',''E'');\nend_try_catch\nfid = fopen(''%s'',''a''); fprintf(fid,''%%s'',datetime().toString); fclose(fid);\ndiary off',...
                this.diaryFile,this.processFile,command,this.errorFile,this.processFile);
            fclose(fid);

        endfunction

        function val = get.state(this)
            val = 'unknown';
            if exist(this.processFile,'file')
                val = 'running';
                fid = fopen(this.processFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = 'finished'; endif
            end
            if exist(this.errorFile,'file'), val = 'error'; endif
        endfunction

        function val = get.worker(this)
            if isempty(this._worker.host) && exist(this.processFile,'file')
                fid = fopen(this.processFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 2
                    this._worker.host = lines{2};
                    this._worker.pid = str2double(lines{1});
                endif
            endif
            val = this._worker;
        endfunction

        function val = get.finishDateTime(this)
            val = datetime.empty;
            if any(strcmp({'finished','error'},this.state))
                fid = fopen(this.processFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = datetime(lines{3}); endif
            endif
        endfunction

        function val = get.diary(this)
            val = '';
            if exist(this.diaryFile,'file')
                fid = fopen(this.diaryFile,'r');
                while ~feof(fid)
                    line = fgets(fid);
                    if ~isnumeric(line), val = cat(2,val,line); endif
                endwhile
                fclose(fid);
            endif
        endfunction

        function val = getOutput(this)
            val = {};
            if strcmp(this.state,'finished') && ~isempty(this.outFile)
                val = struct2cell(load('-binary',this.outFile));
            endif
        endfunction

        function val = get.errorMessage(this)
            val = '';
            if exist(this.errorFile,'file')
                load(this.errorFile)
                val = E.message;
            endif
        endfunction

        function val = get.error(this)
            val = lasterror; val.stack = val.stack(false); val = val(false);
            if exist(this.errorFile,'file')
                load(this.errorFile)
                val = E;
            endif
        endfunction

    endmethods

    methods  (Static = true)
        function this = empty()
            this = taskClass();
            this = this(false);
        endfunction
    endmethods
endclassdef
