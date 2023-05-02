classdef datetime
% Class to represent date and time. It implements a functinality similar to MATLAB's datetime allowing formating and basic arithmetics.
%
% FORMAT dt = datetime();
% Return current date and time
%
% FORMAT dt = datetime([2022 05 21 14 0 0]);
% Return the representation of 21/05/2022 14:00:00 in the local time zone.
%
% FORMAT dt = datetime('21 May 2022 14:00:00 CET_Summer_Time','dd mmm yyyy HH:MM:SS z');
% Return the representation of 21/05/2022 14:00:00 in CET Summer Time.
% N.B.: as whitespace is treated as a delimiter, any whitespace MUST be replaced with underscore '_' in time zone
%
% FORMAT dt = datetime('14:00:00 CET_Summer_Time','HH:MM:SS z');
% Return the representation of 01/01/0 14:00:00 in CET Summer Time.
% CAVEAT: unspecified month and day are set to 1 (see warnings), however, they (along with the year defaulted to 0) will not be printed.
%   Changing the format will reveal them.
%
%   >> dt
%   dt =
%
%   14:00:00 CET Summer Time
%
%   >> dt.format = 'dd mm yyyy, HH:MM:SS z'
%   dt =
%
%   01 01 0000, 14:00:00 CET Summer Time

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

    properties (Hidden, Constant = true)
        MONTHS3 = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};
        MAPFORMAT = {'yyyy' 'mmm' 'mm' 'dd' 'HH' 'MM' 'SS' 'z'};
    end

    methods
        function this = datetime(t=clock,format='yyyy mmm dd HH:MM:SS z')
            this.zone = this.systemTimezone;

            assert(~any(format=='$'), 'Illegal character ($) in format');

            if ischar(t)
                indFormat = cellfun(@(p) regexp(format,p),this.MAPFORMAT, 'UniformOutput',false);
                indMonth = {unique([indFormat{2:3}])};
                indFormat = [indFormat(1) indMonth indFormat(4:end)];
                [~, ordFormat] = sort(cell2mat(indFormat(~cellfun(@isempty, indFormat)))); ordFormat = num2cell(ordFormat);
                indFormat(~cellfun(@isempty, indFormat)) = ordFormat;
                indFormat(cellfun(@isempty, indFormat)) = 0;
                ordFormat = cell2mat(indFormat);
                tmpt = cell(1,max(ordFormat));

%                 [~,ord] = sort(unique(cellfun(@(p) regexp(format,p),this.MAPFORMAT),'stable'));

                tmpFormat = format;
                tmpFormat = strrep(tmpFormat,'yyyy','$%4d$');
                tmpFormat = strrep(tmpFormat,'mmm','$%s$');
                tmpFormat = strrep(tmpFormat,'mm','$%2d$');
                tmpFormat = strrep(tmpFormat,'dd','$%2d$');
                tmpFormat = strrep(tmpFormat,'HH','$%2d$');
                tmpFormat = strrep(tmpFormat,'MM','$%2d$');
                tmpFormat = strrep(tmpFormat,'SS','$%2d$');
                tmpFormat = strrep(tmpFormat,'z','$%s$');
                tmpFormat = strrep(tmpFormat,'$','');

                [tmpt{:}] = sscanf(t,tmpFormat, 'C');
                tmpt(ordFormat>0) = tmpt(ordFormat(ordFormat>0));
                tmpt(ordFormat==0) = 0;

                if ischar(tmpt{2}), tmpt{2} = find(strcmpi(this.MONTHS3,tmpt{2})); end
                if ischar(tmpt{7}), this.zone = strrep(tmpt{7},'_',' '); end
                t = cell2mat(tmpt(1:6));
            end

            this.year = t(1);
            this.month = t(2);
            this.day = t(3);
            this.hour = t(4);
            this.minute = t(5);
            this.second = t(6);
            if this.month < 1 || this.month > 12
                warning('month MUST be in [1-12] -> month is set to 1');
                this.month = 1;
            end
            if this.day < 1 || this.month > 31
                warning('day MUST be in [1-31] -> day is set to 1');
                this.day = 1;
            end

            this.format = format;
        end

        function val = toVec(this)
            val = [this.year this.month this.day this.hour this.minute this.second];
        end


        function val = char(this)
            if isempty(this), printf('\n'); return; end
            str = datestr(this.toVec(),this.format);
            val = strrep(str,'z', this.zone);
        end

        function disp(this)
            printf('%s\n', this.char)
        end

        function val = minus(this1,this2) % CAVE: ignore timezones and cannot detect difference > 30d 23:59:59 days
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
