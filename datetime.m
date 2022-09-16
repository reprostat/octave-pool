classdef datetime
    properties
        Zone
        Year
        Month
        Day
        Hour
        Minute
        Second
        Format
    endproperties

    properties (Dependent)
        SystemTimeZone
    endproperties

    properties (Constant = true)
        MONTHS3 = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};
    endproperties

    methods
        function this = datetime(t=clock,format='yyyy mmm dd HH:MM:SS z')
            this.Zone = this.SystemTimeZone;

            if ischar(t)
                tmpFormat = format;
                tmpFormat = strrep(tmpFormat,'yyyy','%d');
                tmpFormat = strrep(tmpFormat,'mmm','%s');
                tmpFormat = strrep(tmpFormat,'dd','%d');
                tmpFormat = strrep(tmpFormat,'HH','%d');
                tmpFormat = strrep(tmpFormat,'MM','%d');
                tmpFormat = strrep(tmpFormat,'SS','%d');
                tmpFormat = strrep(tmpFormat,'z','%s');
                [this.Year, this.Month, this.Day, this.Hour, this.Minute, this.Second, junk] = sscanf(t,tmpFormat, 'C');
                this.Month = find(strcmp(this.MONTHS3,this.Month));
            else
                this.Year = t(1);
                this.Month = t(2);
                this.Day = t(3);
                this.Hour = t(4);
                this.Minute = t(5);
                this.Second = t(6);
            endif

            this.Format = format;
        endfunction

        function val = toString(this)
            if isempty(this), printf('\n'); return; endif
            str = datestr(this.getVec,this.Format);
            val = strrep(str,'z', this.Zone);
        endfunction

        function disp(this)
            printf('%s\n', this.toString)
        endfunction

        function val = minus(this1,this2)
            et = localtime(etime(this1.getVec,this2.getVec));
            et.hour = et.hour-et.gmtoff/3600;
            et.mday = et.mday - 1;
            val = strftime('%ed %H:%M:%S',et);
        endfunction

        function val = get.SystemTimeZone(this)
            val = localtime(time).zone;
        endfunction

    endmethods

    methods (Access = private)
        function val = getVec(this)
            val = [this.Year this.Month this.Day this.Hour this.Minute this.Second];
        endfunction
    endmethods

    methods  (Static = true)
        function this = empty()
            this = datetime();
            this = this(false);
        endfunction
    endmethods
endclassdef
