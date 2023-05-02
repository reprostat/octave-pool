function j = batch(pool,func,nOut,argIn,varargin)
% Convenience wrapper to create and submit a job and returns a handle to it.
%
% FORMAT j = batch(pool,func,nOut,argIn)
%
% INPUT
% See also jobClass/addTask
%   pool  - pool object
%   func  - function string or handle
%   nOout - number of outputs
%   argIn - cell of input arguments. '$thisworker' can be used to pass task.worker (for logging).
%
% FORMAT j = batch(...,Name,Value)
%   'name'              - name of the job as it appears on the scheduler (default = '')
%   'autoAddClientPath' - automatically add current Ocatave path to the job (default = false)
%   'additionalPaths'   - cell of paths to be added to the job (default = {})
%
%
% SEE ALSO
% jobClass

    % Parse input
    if ischar(func), func = str2func(func); end

    argParse = inputParser;
    argParse.addParameter('name','',@ischar);
    argParse.addParameter('autoAddClientPath',false,@(x) islogical(x) | isnumeric(x));
    argParse.addParameter('additionalPaths',{},@iscellstr);
    argParse.parse(varargin{:});

    % Prepare job
    jobName = argParse.Results.name;
    if isempty(jobName), jobName = func2str(func); end

    additionalPaths = {};
    if argParse.Results.autoAddClientPath, additionalPaths = [strsplit(path,pathsep) additionalPaths]; end % client paths take precedence
    if ~isempty(argParse.Results.additionalPaths), additionalPaths = [argParse.Results.additionalPaths additionalPaths]; end % additionalPaths take precedence

    % Run job
    j = pool.addJob();
    if ~isempty(additionalPaths), j.additionalPaths = unique(additionalPaths,'stable'); end
    j.addTask(jobName,func,nOut,argIn);
    j.submit();

end
