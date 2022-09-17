clear classes

addpath(['D:\Projects\aaq_octave' pathsep 'D:\Projects\aaq_octave\extrafunctions'])

Pool = PoolClass('+pooldef\+local_PS\local_PS.json');
j = Pool.addJob();
j.AdditionalPaths = {'D:\Projects\aaq_octave','D:\Projects\aaq_octave\extrafunctions'};
j.addTask('test',@eig,{rand(5000)});
j.Submit()
j.delete()


