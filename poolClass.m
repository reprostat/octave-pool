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
    endproperties

    properties (Hidden)
        latestJobID = 0

        getSubmitStringFcn
        getSchedulerIDFcn
        getJobStateFcn
        getJobDeleteStringFcn
    endproperties

    properties (Hidden, Access = protected)
        resourceTemplate = ''
        submitArguments
        _jobs = jobClass.empty
    endproperties

    properties (Dependent)
        jobs
    endproperties

    methods
        function this = poolClass(configJSON)
            def = jsonread(configJSON);

            this.type = def.type;
            this.shell = def.shell;
            if ~isempty(def.jobStorageLocation), this.jobStorageLocation = def.jobStorageLocation; endif
            this.numWorkers = def.numWorkers;
            this.resourceTemplate = def.resourceTemplate;
            this.submitArguments = def.submitArguments;

            if isstruct(def.functions)
                for funcstr = {'submitString' 'schedulerID' 'jobState' 'jobDeleteString'}
                    if isfield(def.functions, [funcstr{1} 'Fcn'])
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(def.functions.([funcstr{1} 'Fcn']));
                    else
                        this.(['get' upper(funcstr{1}(1)) funcstr{1}(2:end) 'Fcn']) = str2func(sprintf('pooldef.%s.%s',def.name,funcstr{1}));
                    endif
                endfor
            endif

            switch this.type
                case 'local'
                    datWT = NaN;
                    datMem = NaN;
            endswitch

            this.reqWalltime = datWT;
            this.reqMemory = datMem;
        endfunction

        function set.jobStorageLocation(this,value)
            this.jobStorageLocation = value;
            if isempty(this.jobStorageLocation)
                warning('jobStorageLocation is not specified. The current directory of %s will be used',pwd);
                this.jobStorageLocation = pwd;
            elseif ~exist(this.jobStorageLocation,'dir'), mkdir(this.jobStorageLocation);
            endif
        endfunction

        function set.reqWalltime(this,value)
            if isempty(value), return; endif
            this.reqWalltime = value;
            this.updateSubmitArguments;
        endfunction

        function set.reqMemory(this,value)
            if isempty(value), return; endif
            this.reqMemory = value;
            this.updateSubmitArguments;
        endfunction

        function job = addJob(this)
            job = jobClass(this);
            this._jobs(end+1) = job;
            this.latestJobID = this.latestJobID + 1;
        endfunction

        function val = get.jobs(this)
            val = this._jobs(arrayfun(@(j) this._jobs(j).isvalid, 1:numel(this._jobs)));
        endfunction

    endmethods

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
            endswitch
        endfunction
    endmethods
end

%!test
%! addpath([fileparts(mfilename('fullpath')) pathsep fullfile(fileparts(mfilename('fullpath')),'extrafunctions')])
%! pool = poolClass('+pooldef\+local_PS\local_PS.json');
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! j = pool.addJob();
%! j.additionalPaths = {fileparts(mfilename('fullpath')),fullfile(fileparts(mfilename('fullpath')),'extrafunctions')};
%! j.addTask('test',@eig,1,{rand(5000)});
%! j.submit();
%! j.delete();
%! assert(numel(pool.jobs),0)

%!test
%! addpath([fileparts(mfilename('fullpath')) pathsep fullfile(fileparts(mfilename('fullpath')),'extrafunctions')])
%! pool = poolClass('+pooldef\+local_PS\local_PS.json');
%! pool.jobStorageLocation = fullfile(fileparts(mfilename('fullpath')),'test');
%! j = pool.addJob();
%! j.additionalPaths = {fileparts(mfilename('fullpath')),fullfile(fileparts(mfilename('fullpath')),'extrafunctions')};
%! inp = rand(1000);
%! j.addTask('test',@eig,1,{inp});
%! j.submit();
%! while ~strcmp(j.state,'finished'), pause(1); endwhile
%! out = j.getOutput();
%! assert(out{1}{1}, eig(inp))
%! j.delete()

