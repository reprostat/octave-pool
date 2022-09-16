clear classes

Pool.Type = 'local';
Pool.Shell = 'ps';
Pool.initialConfiguration = '';
Pool.latestJobID = 0;
Pool.JobStorageLocation = 'D:\Projects\aaq_octave\test';
Pool.getSubmitStringFcn = @(Job) sprintf( 'powershell -Command "$P = Start-Process %s -PassThru; Write-Output $P.ID"', ...
    Job.Tasks.ShellFile);;
Pool.getSchedulerIDFcn = @str2double;
Pool.getJobStateFcn = @local_PS_getJobState;
Pool.getJobDeleteStringFcn = '';
j = JobClass(Pool);
j.AdditionalPaths = {'D:\Projects\aaq_octave'};
j.addTask('test',@fprintf,{'%f\n' pi});


