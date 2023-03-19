function j = batch(pool,func,nOut,argIn,varargin)

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
