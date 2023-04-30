function cmd = submitString(job)
    cmd = sprintf('sbatch $thispool.submitArguments $thispool.resourceTemplate -J %s -o "%s" -e "%s" "%s"', job.name, job.tasks{1}.logFile, job.tasks{1}.logFile, job.tasks{1}.shellFile);
end
