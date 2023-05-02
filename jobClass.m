classdef jobClass < handle
% Class to represent a job submitted to the pool. It is usually not created by directly calling its constructor but rather via poolClass/addJob and batch.
%
% PROPERTIES
%   id              - read-only, job number in the pool to determine job name.
%   name            - read-only, job name in the pool to deternmine the job storage folder in pool.jobStorageLocation.
%   additionalPaths - cell of paths to be added to the job (default = {})
%   tasks           - list of tasks (usually 1)
%   state           - job state as return by the scheduler
%
% METHODS
%   FORMAT addTask(name,func,nOut,args)
%   Create a task (with folder and files) and add it to the job
%   INPUT
%     name - name of the job as it appears on the scheduler
%     func - function string or handle
%     nOut - number of outputs
%     args - cell of input arguments. '$thisworker' can be used to pass task.worker (for logging).
%
%   FORMAT submit() - Submits the job
%
%   FORMAT cance()  - Cancel the job
%
%   FORMAT delete() - Cancel the job and delete the job storage folder
%
%   FORMAT val = getOutput()
%   Retrieve the output (if any)
%   OUTPUT
%     val - 1xN cell array, where N corresponds to the number of outputs
%
%
% SEE ALSO
% poolClass, batch

    properties (SetAccess = private)
        id
        name
    end

    properties
        additionalPaths = {}
        tasks = {};
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
            this.pool = pool;

            this.id = this.pool.latestJobID+1;
            this.name = sprintf(this.pool.jobDirNameFormat,this.id);

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
            this.tasks{end+1} = task;
            this.latestTaskID = this.latestTaskID + 1;
        end

        function submit(this)
            cmd = this.pool.getSubmitStringFcn(this);

            % - parse special cases
            if contains(cmd,'\$thispool','regularExpression',true)
                for poolVars = regexp(cmd,'(?<=\$thispool\.)[^ ]*','match')
                    cmd = strrep(cmd,['$thispool.' poolVars{1}],this.pool.(poolVars{1}));
                end
            end

            [s, w] = system(cmd);
            for t = 1:numel(this.tasks)
                this.tasks{t}.startDateTime = datetime();
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

            % double check with tasks
            taskStates = cellfun(@(t) t.state, this.tasks, 'UniformOutput',false);
            if any(strcmp({'finished','error'},val))
                if any(~strcmp(taskStates,'finished')), val = 'error'; % if the tasks has not finished -> error
                else, val = 'finished';
                end
            elseif any(strcmp(taskStates,'running')), val = 'running'; % last resort
            end
        end

        function val = getOutput(this)
            val = {};
            if strcmp(this.state,'finished')
                val = cellfun(@(t) t.getOutput(), this.tasks, 'UniformOutput',false);
            end
        end
    end

end

