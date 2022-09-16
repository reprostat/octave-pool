classdef PoolClass < handle
    properties
        Type
        JobStorageLocation
        Jobs = JobClass.empty

        Host = gethostname
        Shell
        NumWorkers

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
        newGenericVersion
        initialSubmitArguments = ''
        SubmitArguments
    endproperties

    methods
        function this = PoolClass(configJSON)
            def = jsonread(configJSON);

            this.Type = def.Type;
            this.Shell = def.Shell;
            this.JobStorageLocation = def.JobStorageLocation;
            this.NumWorkers = def.NumWorkers;

            if isstruct(def.Functions)
                for funcstr = {'SubmitStringFcn' 'SchedulerIDFcn' 'JobStateFcn' 'JobDeleteStringFcn'}
                    if isfield(def.Functions, funcstr{1})
                        this.(['get' funcstr{1}]) = str2func(def.Functions.(funcstr{1}));
                    else
                        this.(['get' funcstr{1}]) = str2func(sprintf('pooldef.%s.%s',def.Name,funcstr{1}));
                    endif
                endfor
            endif

            switch this.Type
                case 'local'
                    datWT = NaN;
                    datMem = NaN;
            endswitch

            obj.reqWalltime = datWT;
            obj.reqMemory = datMem;
        endfunction

    endmethods
end
