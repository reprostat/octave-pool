clear classes

addpath(['D:\Projects\aaq_octave' pathsep 'D:\Projects\aaq_octave\extrafunctions'])

Pool = PoolClass('+pooldef\+local_PS\local_PS.json');
j = Pool.addJob();
j.AdditionalPaths = {'D:\Projects\aaq_octave','D:\Projects\aaq_octave\extrafunctions'};
j.addTask('test',@eig,1,{rand(5000)});
j.Submit();
j.delete();

j = Pool.addJob();
j.AdditionalPaths = {'D:\Projects\aaq_octave','D:\Projects\aaq_octave\extrafunctions'};
j.addTask('test',@eig,1,{rand(1000)});
j.Submit();
while ~strcmp(j.State,'finished'), pause(1); endwhile
j.getOutput()
j.delete()


