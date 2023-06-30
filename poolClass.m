classdef poolClass < handle
% Class to represent a computation pool, which CAN be a single PC and a cluster. It REQUIRES a basic definition containing properties and methods specified in
% a JSON file as stored in <package folder>/+pooldef/+<pool name>. Definitions CAN also be stored externally in a folder '+'<pool name>.
%
% POOL DEFINITION
% Take a look at the bundled 'local_PS' and 'Slurm' pool definitions for inspiration and guidance.
%
% PROPERTIES
%   name                 - pool name,
%   type                 - scheduler ('powershell', 'Slurm', 'Torque', 'LSF', 'Generic')
%   shell                - shell for the shceuler commands ('windows', 'bash'), used in taskClass/taskClass
%   numWorkers           - maximum number of active workers
%   jobStorageLocation   - folder to store submission files (shell and Octave scripts, input, output, log files)
%   resourceTemplate     - submission parameters describing resource requirements
%   submitArguments      - additional submission parameters
%   initialConfiguration - command(s) to excute right before Octave
%   octaveExecutable     - Octave executable ('octave-cli', 'octave')
%
% METHODS
% One-liner functions CAN be stored in the JSON under 'functions/<method name>Fcn'. More complex functions MUST be placed in the pool definition folder (along
% with the JSON file) as <method name>.m.
%   submitString    - compiles the command string to submit
%   schedulerID     - retrieves ID assigned by the scheduler to the worker
%   jobState        - retrieves status (as string) of the worker
%   jobDeleteString - compiles the submission command
%
%
% POOL CLASS
%
% PROPERTIES (additional)
%   reqMemory   - required memory (in GB)
%   reqWalltime - required execution time (in hour)
%   jobs        - read-only, list of jobs
%
% METHODS
%   FORMAT j = pool.addJob()
%   Creates a new job class for the pool a returns a handle to it.
%
%   FORMAT val = getJobState()
%   Generates a summary of jobs according to their states.
%
%   FORMAT val = getJobState(state)
%   Retrieves the number of jobs at the given state.
%
%
% SEE ALSO
% jobClass

    properties
        type
        jobStorageLocation

        host = gethostname
        shell
        octaveExecutable
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

    properties (Hidden)
        resourceTemplate = ''
        submitArguments
    end

    properties (Hidden, Access = protected)
        externalPoolDefinitionStore = ''
        _jobs = {}
    end

    properties (Depend)
        jobs
    end

    methods
        function this = poolClass(poolName)
            if exist(fullfile(fileparts(mfilename('fullpath')),'+pooldef',['+' poolName]),'dir')
                configJSON = fullfile(fileparts(mfilename('fullpath')),'+pooldef',['+' poolName],[poolName '.json']);
                funcPrefix = 'pooldef.';
            elseif exist(poolName,'file')
                configJSON = poolName;
                fprintf('External pool definition detected: %s\n',configJSON);
                [this.externalPoolDefinitionStore pooldefFolder] = fileparts(fileparts(configJSON));
                [~,poolName,~] = fileparts(configJSON);
                assert(strcmp(pooldefFolder,['+' poolName]),'Pool definition MUST be stored in the folder ''+''<pool name>');
                addpath(this.externalPoolDefinitionStore);
                funcPrefix = '';
            else, error('pool definition %s not found',poolName);
            end
            def = jsonread(configJSON);

            this.type = def.type;
            this.shell = def.shell;
            this.octaveExecutable = def.octaveExecutable;
            if ~isempty(def.jobStorageLocation), this.jobStorageLocation = def.jobStorageLocation; end
            this.numWorkers = str2double(def.numWorkers);
            this.resourceTemplate = def.resourceTemplate;
            this.submitArguments = def.submitArguments;

            if isstruct(def.functions)
                for funcstr = {'submitString' 'schedulerID' 'jobState' 'jobDeleteString'}
                    if isfield(def.functions, [funcstr{1} 'Fcn'])
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(def.functions.([funcstr{1} 'Fcn']));
                    else
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(sprintf('%s%s.%s',funcPrefix,def.name,funcstr{1}));
                    end
                end
            end

            switch this.type
                case {'Slurm'}
                    datWT = str2double(regexp(this.resourceTemplate,'(?<=--time=)[0-9]*','match','once'))/60;
                    datMem = str2double(regexp(this.resourceTemplate,'(?<=--mem=)[0-9]*','match','once'));
                case {'local' 'powershell'}
                    datWT = NaN;
                    datMem = NaN;
            end

            this.reqWalltime = datWT;
            this.reqMemory = datMem;
        end

        function delete(this)
            this.close();
        end

        function close(this)
            if ~isempty(this.externalPoolDefinitionStore), rmpath(this.externalPoolDefinitionStore); end
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
            this.updateResourceTemplate;
        end

        function set.reqMemory(this,value)
            if isempty(value), return; end
            this.reqMemory = value;
            this.updateResourceTemplate;
        end

        function job = addJob(this)
            job = jobClass(this);
            this._jobs{end+1} = job;
            this.latestJobID = this.latestJobID + 1;
        end

        function val = get.jobs(this)
            val = this._jobs(cellfun(@(j) j.isvalid, this._jobs));
        end

        function val = getJobState(this,state)
            val = containers.Map('KeyType','char', 'ValueType','double');
            jobStates = cellfun(@(j) j.state, this.jobs, 'UniformOutput',false);
            for s = jobStates
                if ~val.isKey(s{1}), val(s{1}) = 0; end
                val(s{1}) = val(s{1}) + 1;
            end

            if nargin > 1
                if val.isKey(state), val = val(state);
                else, val = 0;
                end
            end
        end

    end

    methods (Hidden, Access = protected)
        function updateResourceTemplate(this)
            memory = this.reqMemory;
            walltime = this.reqWalltime;

            switch this.type
                case 'Slurm'
                    if round(memory) == memory % round
                        memory = sprintf('%dG',memory);
                    else % non-round --> MB
                        memory = sprintf('%dM',memory*1000);
                    end
                    this.resourceTemplate = sprintf('--mem=%s --time=%d',memory,walltime*60);
                case 'Torque'
                    if round(memory) == memory % round
                        memory = sprintf('%dGB',memory);
                    else % non-round --> MB
                        memory = sprintf('%dMB',memory*1000);
                    end
                    this.resourceTemplate = sprintf('-q compute -l mem=%s -l walltime=%d',memory,walltime*3600);
                case 'LSF'
                    this.resourceTemplate = sprintf('-c %d -M %d -R "rusage[mem=%d:duration=%dh]"',walltime*60,memory*1000,memory*1000,walltime);
                case 'Generic' % SoG/OSG
                    this.resourceTemplate = sprintf('-l s_cpu=%d:00:00 -l s_rss=%dG',walltime,memory);
            end
        end
    end
end

%!test
%! pathToAdd = [...
%!    fileparts(mfilename('fullpath')) pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'extrafunctions')) pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'external')) ...
%!    ];
%! addpath(pathToAdd)
%! if ispc(), pool = poolClass('local_PS');
%! else, pool = poolClass('slurm');
%! end
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! j = pool.addJob();
%! j.additionalPaths = strsplit(pathToAdd,pathsep);
%! j.addTask('test',@eig,1,{rand(5000)});
%! j.submit();
%! pause(1);
%! assert(pool.getJobState('running'), 1)
%! j.delete();
%! pause(1);
%! assert(numel(pool.jobs),0)
%! rmpath(pathToAdd)

%!test
%! pathToAdd = [...
%!    fileparts(mfilename('fullpath')) pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'extrafunctions')) pathsep ...
%!    genpath(fullfile(fileparts(mfilename('fullpath')),'external')) ...
%!    ];
%! addpath(pathToAdd)
%! if ispc(), pool = poolClass('local_PS');
%! else, pool = poolClass('slurm');
%! end
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! inp = rand(1000);
%! j = batch(pool,@eig,1,{inp},'name','test','additionalPaths',strsplit(pathToAdd,pathsep));
%! while ~any(strcmp({'finished' 'error'}, j.state)), pause(1); end
%! assert(j.state, 'finished')
%! out = j.getOutput();
%! assert(out{1}{1}, eig(inp))
%! j.delete()
%! rmpath(pathToAdd)
