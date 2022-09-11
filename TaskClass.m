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
        function obj = TaskClass(Job,Name,varargin)
            obj.CreateDateTime = datetime();

            obj.Parent = Job;
            obj.Name = sprintf('Task%d_%s',obj.Parent.latestTaskID+1,Name);
            obj.Folder = fullfile(obj.Parent.Folder,obj.Name);
            mkdir(obj.Folder)

            obj.ShellFile = fullfile(obj.Folder,'run.sh');
            obj.LogFile = fullfile(obj.Folder,'log.txt');
            obj.DiaryFile = fullfile(obj.Folder,'diary.txt');
            obj.ProcessFile = fullfile(obj.Folder,'process');
            obj.ErrorFile = fullfile(obj.Folder,'error.mat');

            % assemble command
            pathCommand = '';
            varCommand = '';
            Command = func2str(varargin{1});
            if nargin < 4
                userVariable = [];
            else
                obj.InputArguments = varargin{2};
                varStr = sprintf('arg%d,',1:numel(obj.InputArguments));
                varList = textscan(varStr,'%s','delimiter',',');
                userVariable = cell2struct(obj.InputArguments,varList{1}',2);
                Command = [Command, '('];
                Command = [Command, varStr];
                Command(end) = ')';
            endif
            if ~isempty(obj.Parent.AdditionalPaths)
                userVariable.reqpath = obj.Parent.AdditionalPaths;
                pathCommand = sprintf('load(''%s'',''reqpath'');addpath(reqpath{:});',fullfile(obj.Folder,'data.mat'));
            endif
            if ~isempty(userVariable)
                save(fullfile(obj.Folder,'data.mat'),'-struct','userVariable');
                varCommand = sprintf('load(''%s'',%s);',fullfile(obj.Folder,'data.mat'),['''' strrep(varStr(1:end-1),',',''',''') '''']);
            endif
            Command = [pathCommand, varCommand, Command ';'];

            % create script
            fid = fopen(obj.ShellFile,'w');
            switch obj.Parent.Pool.Type
                case 'Slurm'
                    switch obj.Parent.Pool.Shell
                        case 'bash'
                            fprintf(fid,'#!/bin/bash\n');
                    endswitch
            endswitch
            if ~isempty(obj.Parent.Pool.initialConfiguration), fprintf(fid,'%s;',obj.Parent.Pool.initialConfiguration); endif
            fprintf(fid,'octave-cli --eval "diary %s; fid = fopen(''%s'',''w''); fprintf(fid,''%%s\\n'',gethostname); fclose(fid); try; %s catch E; save(''%s'',''E''); end; fid = fopen(''%s'',''a''); fprintf(fid,''%%s'',char(datetime())); fclose(fid); quit"',...
                obj.DiaryFile,obj.ProcessFile,Command,obj.ErrorFile,obj.ProcessFile);
            fclose(fid);
        endfunction

        function val = get.State(obj)
            val = 'unknown';
            if exist(obj.ProcessFile,'file')
                val = 'running';
                fid = fopen(obj.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = 'finished'; endif
            end
            if exist(obj.ErrorFile,'file'), val = 'error'; endif
        endfunction

        function val = get.Worker(obj)
            val = WorkerClass.empty;
            if exist(obj.ProcessFile,'file')
                fid = fopen(obj.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 2, val = WorkerClass(lines{2},str2double(lines{1})); endif
            endif
        endfunction

        function val = get.FinishDateTime(obj)
            val = datetime.empty;
            if any(strcmp({'finished','error'},obj.State))
                fid = fopen(obj.ProcessFile,'r');
                lines = textscan(fid,'%s','delimiter','@'); lines = lines{1};
                fclose(fid);
                if numel(lines) >= 3, val = datetime(lines{3},'Timezone','local'); endif
            endif
        endfunction

        function val = get.Diary(obj)
            val = '';
            if exist(obj.DiaryFile,'file')
                fid = fopen(obj.DiaryFile,'r');
                while ~feof(fid)
                   val = cat(2,val,fgets(fid));
                endwhile
                fclose(fid);
            endif
        endfunction

        function val = get.ErrorMessage(obj)
            val = '';
            if exist(obj.ErrorFile,'file')
                load(obj.ErrorFile)
                val = E.message;
            endif
        endfunction

        function val = get.Error(obj)
            val = lasterror; val.stack = val.stack(false); val = val(false);
            if exist(obj.ErrorFile,'file')
                load(obj.ErrorFile)
                val = E;
            endif
        endfunction

    endmethods

endclassdef
