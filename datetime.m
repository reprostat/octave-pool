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

  methods
    function this = datetime(t=clock,format='yyyy mmm dd HH:MM:SS z')
      this.Zone = this.SystemTimeZone;

      this.Year = t(1);
      this.Month = t(2);
      this.Day = t(3);
      this.Hour = t(4);
      this.Minute = t(5);
      this.Second = t(6);

      this.Format = format;
    endfunction

    function disp(this)
      if isempty(this), printf('\n'); return; endif
      str = datestr(this.getVec,this.Format);
      str = strrep(str,'z', this.Zone);
      printf('%s\n', str)
    endfunction

    function val = minus(this1,this2)
      etime = localtime(etime(this1.getVec,this2.getVec));
      etime.mday = etime.mday - 1;
      val = strftime('%ed %H:%M:%S',etime);
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
