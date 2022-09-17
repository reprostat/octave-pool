classdef JobClass < handle
    properties
        ID
        Name
        AdditionalPaths = {}
        Tasks = TaskClass.empty;
    endproperties

    properties (Dependent)
        State
    endproperties

    properties (Hidden)
        Pool
        Folder
        latestTaskID = 0
    endproperties

    properties (Hidden, Access = protected)
        schedulerID = NaN
    endproperties

    methods
        function this = JobClass(Pool=[])
            if isempty(Pool), return; endif
            this.Pool = Pool;

            this.ID = this.Pool.latestJobID+1;
            this.Name = sprintf('Job%d',this.ID);

            this.Folder = fullfile(this.Pool.JobStorageLocation,this.Name);
%             while exist(this.Folder,'dir')
%                 this.Folder = [this.Folder '+'];
%             end
            mkdir(this.Folder);
        endfunction

        function val = isvalid(this)
            val = exist(this.Folder,'dir');
        endfunction

        function delete(this)
            if ~this.isvalid, return; endif
            if this.cancel
                pause(1);
                confirm_recursive_rmdir(0,'local')
                rmdir(this.Folder,'s');
                delete@handle(this)
            else
                warning('Job %s could not be killed!\nYou may need to kill manually by calling %s.',this.ID,this.Pool.getJobDeleteStringFcn(this.schedulerID));
            endif
        endfunction

        function s = cancel(this)
            s = false;
            if ~any(strcmp({'unknown','finished','error'},this.State)), [s, w] = system(this.Pool.getJobDeleteStringFcn(this.schedulerID)); endif
            if s, warning(w);
%             else
%                 this.Pool.Jobs([this.Pool.Jobs.ID]==this.ID) = [];
            endif
            s = ~s;
        endfunction

        function addTask(this,Name,func,nOut,args)
            Task = TaskClass(this,Name,func,nOut,args);
            this.Tasks(end+1) = Task;
            this.latestTaskID = this.latestTaskID + 1;
        endfunction

        function Submit(this)
            [s, w] = system(this.Pool.getSubmitStringFcn(this));
            for t = 1:numel(this.Tasks)
                this.Tasks(t).StartDateTime = datetime();
            endfor
            if ~s
                this.schedulerID = this.Pool.getSchedulerIDFcn(w);
            endif
        endfunction

        function val = get.State(this)
            val = 'unknown';
            if ~isnan(this.schedulerID)
                val = this.Pool.getJobStateFcn(this.schedulerID);
            endif
            if any(strcmp({'finished','error'},val)), val = this.Tasks.State; endif
        endfunction

        function val = getOutput(this)
            val = {};
            if strcmp(this.State,'finished')
                val = arrayfun(@(t) this.Tasks(t).getOutput(), 1:numel(this.Tasks), 'UniformOutput',false);
            endif
        endfunction
    endmethods

        methods  (Static = true)
        function this = empty()
            this = JobClass();
            this = this(false);
        endfunction
    endmethods
endclassdef

