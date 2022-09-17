classdef TaskClass < handle
    properties
        Name
        CreateDateTime = datetime.empty
        StartDateTime = datetime.empty

        Parent

        InputArguments = {}
    endproperties

    properties (Hidden)
        Folder
        ShellFile
        LogFile
    endproperties

    properties (Access = private)
        ScriptFile
        DiaryFile
        ProcessFile
        ErrorFile
    endproperties

    properties (Dependent)
        State
        Worker
        FinishDateTime
        Diary
        ErrorMessage
        Error
    endproperties

    methods
        function this = TaskClass(Job=[], Name='', varargin)
            if isempty(Job), return; endif
            this.CreateDateTime = datetime();

            this.Parent = Job;
            this.Name = sprintf('Task%d_%s',this.Parent.latestTaskID+1,Name);
            this.Folder = fullfile(this.Parent.Folder,this.Name);
            mkdir(this.Folder)

            if ispc
              this.ShellFile = fullfile(this.Folder,'run.bat');
            else
              this.ShellFile = fullfile(this.Folder,'run.sh');
            endif
            this.LogFile = fullfile(this.Folder,'log.txt');
            this.ScriptFile = fullfile(this.Folder,'run.m');
            this.DiaryFile = fullfile(this.Folder,'diary.txt');
            this.ProcessFile = fullfile(this.Folder,'process');
            this.ErrorFile = fullfile(this.Folder,'error.mat');

            % assemble command
            pathCommand = '';
            varCommand = '';
            Command = func2str(varargin{1});
            if nargin < 4
                userVariable = [];
            else
                this.InputArguments = varargin{2};
                varStr = sprintf('arg%d,',1:numel(this.InputArguments));
                varList = textscan(varStr,'%s','delimiter',',');
                userVariable = cell2struct(this.InputArguments,varList{1}',2);
                Command = [Command, '('];
                Command = [Command, varStr];
                Command(end) = ')';
            endif
            if ~isempty(this.Parent.AdditionalPaths)
                userVariable.reqpath = this.Parent.AdditionalPaths;
                pathCommand = sprintf('load(''%s'',''reqpath'');addpath(reqpath{:});',fullfile(this.Folder,'data.mat'));
            endif
            if ~isempty(userVariable)
                save('-binary',fullfile(this.Folder,'data.mat'),'-struct','userVariable');
                varCommand = sprintf('load(''%s'',%s);',fullfile(this.Folder,'data.mat'),['''' strrep(varStr(1:end-1),',',''',''') '''']);
            endif
            Command = [pathCommand, varCommand, Command ';'];

            % create script
            fid = fopen(this.ShellFile,'w');
            switch this.Parent.Pool.Type
                case 'Slurm'
                    switch this.Parent.Pool.Shell
                        case 'bash'
                            fprintf(fid,'#!/bin/bash\n');
                    endswitch
            endswitch
            if ~isempty(this.Parent.Pool.initialConfiguration), fprintf(fid,'%s;',this.Parent.Pool.initialConfiguration); endif
            fprintf(fid,'%s %s', fullfile(OCTAVE_HOME, 'bin', 'octave-cli'), this.ScriptFile);
            fclose(fid);
            fid = fopen(this.ScriptFile,'w');
            fprintf(fid,'diary %s;\nfid = fopen(''%s'',''w''); fprintf(fid,''%%d@%%s\\n'',getpid,gethostname); fclose(fid);\ntry\n    %s\ncatch E\n    save(''-binary'',''%s'',''E'');\nend_try_catch\nfid = fopen(''%s'',''a''); fprintf(fid,''%%s'',datetime().toString); fclose(fid);\ndiary off',...
                this.DiaryFile,this.ProcessFile,Command,this.ErrorFile,this.ProcessFile);
            fclose(fid);

        endfunction

        function val = get.State(this)
            val = 'unknown';
            if exist(this.ProcessFile,'file')
                val = 'running';
                fid = fopen(this.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = 'finished'; endif
            end
            if exist(this.ErrorFile,'file'), val = 'error'; endif
        endfunction

        function val = get.Worker(this)
            val = WorkerClass.empty;
            if exist(this.ProcessFile,'file')
                fid = fopen(this.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 2, val = WorkerClass(lines{2},str2double(lines{1})); endif
            endif
        endfunction

        function val = get.FinishDateTime(this)
            val = datetime.empty;
            if any(strcmp({'finished','error'},this.State))
                fid = fopen(this.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = datetime(lines{3}); endif
            endif
        endfunction

        function val = get.Diary(this)
            val = '';
            if exist(this.DiaryFile,'file')
                fid = fopen(this.DiaryFile,'r');
                while ~feof(fid)
                    line = fgets(fid);
                    if ~isnumeric(line), val = cat(2,val,line); endif
                endwhile
                fclose(fid);
            endif
        endfunction

        function val = get.ErrorMessage(this)
            val = '';
            if exist(this.ErrorFile,'file')
                load(this.ErrorFile)
                val = E.message;
            endif
        endfunction

        function val = get.Error(this)
            val = lasterror; val.stack = val.stack(false); val = val(false);
            if exist(this.ErrorFile,'file')
                load(this.ErrorFile)
                val = E;
            endif
        endfunction

    endmethods

    methods  (Static = true)
        function this = empty()
            this = TaskClass();
            this = this(false);
        endfunction
    endmethods
endclassdef
