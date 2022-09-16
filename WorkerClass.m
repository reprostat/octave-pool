classdef WorkerClass
    properties
        Host
        ProcessId
    endproperties

    methods
        function this = WorkerClass(host='localhost',pid=0)
            this.Host = host;
            this.ProcessId = pid;
        endfunction
    endmethods

    methods  (Static = true)
        function this = empty()
            this = WorkerClass();
            this = this(false);
        endfunction
    endmethods
endclassdef

