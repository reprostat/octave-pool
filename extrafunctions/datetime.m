classdef datetime
    properties
        zone
        year
        month
        day
        hour
        minute
        second
        format
    end

    properties (Depend)
        systemTimezone
    end

    properties (Constant = true)
        MONTHS3 = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};
    end

    methods
        function this = datetime(t=clock,format='yyyy mmm dd HH:MM:SS z')
            this.zone = this.systemTimezone;

            if ischar(t)
                tmpformat = format;
                tmpformat = strrep(tmpformat,'yyyy','%d');
                tmpformat = strrep(tmpformat,'mmm','%s');
                tmpformat = strrep(tmpformat,'dd','%d');
                tmpformat = strrep(tmpformat,'HH','%d');
                tmpformat = strrep(tmpformat,'MM','%d');
                tmpformat = strrep(tmpformat,'SS','%d');
                tmpformat = strrep(tmpformat,'z','%s');
                [this.year, this.month, this.day, this.hour, this.minute, this.second, ~] = sscanf(t,tmpformat, 'C');
                this.month = find(strcmp(this.MONTHS3,this.month));
            else
                this.year = t(1);
                this.month = t(2);
                this.day = t(3);
                this.hour = t(4);
                this.minute = t(5);
                this.second = t(6);
            end

            this.format = format;
        end

        function val = toVec(this)
            val = [this.year this.month this.day this.hour this.minute this.second];
        end


        function val = char(this)
            if isempty(this), printf('\n'); return; end
            str = datestr(this.toVec,this.format);
            val = strrep(str,'z', this.zone);
        end

        function disp(this)
            printf('%s\n', this.char)
        end

        function val = minus(this1,this2)
            et = localtime(etime(this1.toVec,this2.toVec));
            et.hour = et.hour-et.gmtoff/3600;
            et.mday = et.mday - 1;
            val = strftime('%ed %H:%M:%S',et);
        end

        function val = get.systemTimezone(this)
            val = localtime(time).zone;
        end

    end

    methods  (Static = true)
        function this = empty()
            this = datetime();
            this = this(false);
        end
    end
end

%!test
%! d0 = datetime;
%! d1 = d0.toVec;
%! d1 = datetime(d1 + [0 0 1 1 1 1]);
%! assert(d1-d0,' 1d 01:01:01');
