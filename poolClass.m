classdef poolClass < handle
    properties
        type
        jobStorageLocation

        host = gethostname
        shell
        numWorkers

        reqMemory = 1
        reqWalltime = 1
        initialConfiguration = ''
    end

    properties (Hidden)
        latestJobID = 0
        jobDirNameFormat = 'Job%d'

        getSubmitStringFcn
        getSchedulerIDFcn
        getJobStateFcn
        getJobDeleteStringFcn
    end

    properties (Hidden, Access = protected)
        resourceTemplate = ''
        submitArguments
        _jobs = {}
    end

    properties (Depend)
        jobs
    end

    methods
        function this = poolClass(configJSON)
            def = jsonread(configJSON);

            this.type = def.type;
            this.shell = def.shell;
            if ~isempty(def.jobStorageLocation), this.jobStorageLocation = def.jobStorageLocation; end
            this.numWorkers = def.numWorkers;
            this.resourceTemplate = def.resourceTemplate;
            this.submitArguments = def.submitArguments;

            if isstruct(def.functions)
                for funcstr = {'submitString' 'schedulerID' 'jobState' 'jobDeleteString'}
                    if isfield(def.functions, [funcstr{1} 'Fcn'])
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(def.functions.([funcstr{1} 'Fcn']));
                    else
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(sprintf('pooldef.%s.%s',def.name,funcstr{1}));
                    end
                end
            end

            switch this.type
                case {'local' 'powershell'}
                    datWT = NaN;
                    datMem = NaN;
            end

            this.reqWalltime = datWT;
            this.reqMemory = datMem;
        end

        function set.jobStorageLocation(this,value)
            this.jobStorageLocation = value;
            if isempty(this.jobStorageLocation)
                warning('jobStorageLocation is not specified. The current directory of %s will be used',pwd);
                this.jobStorageLocation = pwd;
            elseif ~exist(this.jobStorageLocation,'dir'), mkdir(this.jobStorageLocation);
            else
                while exist(fullfile(this.jobStorageLocation,sprintf(this.jobDirNameFormat,this.latestJobID+1)),'dir')
                    this.latestJobID = this.latestJobID + 1;
                end
            end
        end

        function set.reqWalltime(this,value)
            if isempty(value), return; end
            this.reqWalltime = value;
            this.updateSubmitArguments;
        end

        function set.reqMemory(this,value)
            if isempty(value), return; end
            this.reqMemory = value;
            this.updateSubmitArguments;
        end

        function job = addJob(this)
            job = jobClass(this);
            this._jobs{end+1} = job;
            this.latestJobID = this.latestJobID + 1;
        end

        function val = get.jobs(this)
            val = this._jobs(cellfun(@(j) j.isvalid, this._jobs));
        end

    end

    methods (Hidden, Access = protected)
        function updateSubmitArguments(this)
            memory = this.reqMemory;
            walltime = this.reqWalltime;

            switch this.type
                case 'Slurm'
                    if round(memory) == memory % round
                        memory = sprintf('%dG',memory);
                    else % non-round --> MB
                        memory = sprintf('%dM',memory*1000);
                    end
                    this.submitArguments = sprintf('--mem=%s -t %d ',memory,walltime*60);
                case 'Torque'
                    if round(memory) == memory % round
                        memory = sprintf('%dGB',memory);
                    else % non-round --> MB
                        memory = sprintf('%dMB',memory*1000);
                    end
                    this.submitArguments = sprintf('-q compute -l mem=%s -l walltime=%d',memory,walltime*3600);
                case 'LSF'
                    this.submitArguments = sprintf('-c %d -M %d -R "rusage[mem=%d:duration=%dh]"',walltime*60,memory*1000,memory*1000,walltime);
                case 'Generic'
                    this.submitArguments = sprintf('-l s_cpu=%d:00:00 -l s_rss=%dG',walltime,memory);
            end
        end
    end
end

%!test
%! pathToAdd = [...
%!    fileparts(mfilename('fullpath')) pathsep ...
%!    fullfile(fileparts(mfilename('fullpath')),'extrafunctions') pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'external')) ...
%!    ];
%! addpath(pathToAdd)
%! pool = poolClass('+pooldef\+local_PS\local_PS.json');
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! j = pool.addJob();
%! j.additionalPaths = strsplit(pathToAdd,pathsep);
%! j.addTask('test',@eig,1,{rand(5000)});
%! j.submit();
%! j.delete();
%! assert(numel(pool.jobs),0)
%! rmpath(pathToAdd)

%!test
%! pathToAdd = [...
%!    fileparts(mfilename('fullpath')) pathsep ...
%!    fullfile(fileparts(mfilename('fullpath')),'extrafunctions') pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'external')) ...
%!    ];
%! addpath(pathToAdd)
%! pool = poolClass('+pooldef\+local_PS\local_PS.json');
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! inp = rand(1000);
%! j = batch(pool,@eig,1,{inp},'name','test','additionalPaths',strsplit(pathToAdd,pathsep));
%! while ~strcmp(j.state,'finished'), pause(1); end
%! out = j.getOutput();
%! assert(out{1}{1}, eig(inp))
%! j.delete()
%! rmpath(pathToAdd)
