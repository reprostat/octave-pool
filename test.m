clear classes

Pool = PoolClass('+pooldef\+local_PS\local_PS.json');
j = JobClass(Pool);
j.AdditionalPaths = {'D:\Projects\aaq_octave'};
j.addTask('test',@fprintf,{'%f\n' pi});


