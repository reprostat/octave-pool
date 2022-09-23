classdef jobClass < handle
    properties
        id
        name
        additionalPaths = {}
        tasks = taskClass.empty;
    end

    properties (Depend)
        state
    end

    properties (Hidden)
        pool
        folder
        latestTaskID = 0
    end

    properties (Hidden, Access = protected)
        schedulerID = NaN
    end

    methods
        function this = jobClass(pool=[])
            if isempty(pool), return; end
            this.pool = pool;

            this.id = this.pool.latestJobID+1;
            this.name = sprintf('Job%d',this.id);

            this.folder = fullfile(this.pool.jobStorageLocation,this.name);
%             while exist(this.folder,'dir')
%                 this.folder = [this.folder '+'];
%             end
            mkdir(this.folder);
        end

        function val = isvalid(this)
            val = logical(exist(this.folder,'dir'));
        end

        function delete(this)
            if ~this.isvalid, return; end
            if this.cancel
                pause(1);
                confirm_recursive_rmdir(0,'local')
                rmdir(this.folder,'s');
                delete@handle(this)
            else
                warning('Job %s could not be killed!\nYou may need to kill manually by calling %s.',this.id,this.pool.getJobDeleteStringFcn(this.schedulerID));
            end
        end

        function s = cancel(this)
            s = false;
            if ~any(strcmp({'unknown','finished','error'},this.state)), [s, w] = system(this.pool.getJobDeleteStringFcn(this.schedulerID)); end
            if s, warning(w);
%             else
%                 this.pool.Jobs([this.pool.Jobs.id]==this.id) = [];
            end
            s = ~s;
        end

        function addTask(this,name,func,nOut,args)
            task = taskClass(this,name,func,nOut,args);
            this.tasks(end+1) = task;
            this.latestTaskID = this.latestTaskID + 1;
        end

        function submit(this)
            [s, w] = system(this.pool.getSubmitStringFcn(this));
            for t = 1:numel(this.tasks)
                this.tasks(t).startDateTime = datetime();
            end
            if ~s
                this.schedulerID = this.pool.getSchedulerIDFcn(w);
            end
        end

        function val = get.state(this)
            val = 'unknown';
            if ~isnan(this.schedulerID)
                val = this.pool.getJobStateFcn(this.schedulerID);
            end
            if any(strcmp({'finished','error'},val)), val = this.tasks.state; end
        end

        function val = getOutput(this)
            val = {};
            if strcmp(this.state,'finished')
                val = arrayfun(@(t) this.tasks(t).getOutput(), 1:numel(this.tasks), 'UniformOutput',false);
            end
        end
    end

        methods  (Static = true)
        function this = empty()
            this = jobClass();
            this = this(false);
        end
    end
end

