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

            assert(~any(format=='$'), 'Illegal character ($) in format');

            if ischar(t)
                tmpformat = format;
                tmpformat = strrep(tmpformat,'yyyy','$%4d$');
                tmpformat = strrep(tmpformat,'mmm','$%s$');
                tmpformat = strrep(tmpformat,'mm','$%2d$');
                tmpformat = strrep(tmpformat,'dd','$%2d$');
                tmpformat = strrep(tmpformat,'HH','$%2d$');
                tmpformat = strrep(tmpformat,'MM','$%2d$');
                tmpformat = strrep(tmpformat,'SS','$%2d$');
                tmpformat = strrep(tmpformat,'z','$%s$');
                tmpformat = strrep(tmpformat,'$','');
                [this.year, this.month, this.day, this.hour, this.minute, this.second, ~] = sscanf(t,tmpformat, 'C');
                if ischar(this.month), this.month = find(strcmp(this.MONTHS3,this.month)); end
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

        function val = minus(this1,this2) % CAVE: cannot detect difference > 30d 23:59:59 days
            et = localtime(etime(this1.toVec,this2.toVec));
            et.hour = et.hour-et.gmtoff/3600;
            et.mday = et.mday - 1;
            val = strftime('%ed %H:%M:%S',et);
        end

        function val = eq(this1,this2)
            val = etime(this1.toVec,this2.toVec) == 0;
        end

        function val = gt(this1,this2)
            val = etime(this1.toVec,this2.toVec) > 0;
        end

        function val = lt(this1,this2)
            val = etime(this1.toVec,this2.toVec) < 0;
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
