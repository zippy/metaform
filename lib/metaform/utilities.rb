module Utilities
  ###########################################################
  # used for parameters that can optionally be an array.
  # converts non-array params to a single element array
  HTML_ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }

  def html_escape(s)
    s.to_s.gsub(/[&\"><]/) { |special| HTML_ESCAPE[special] }
  end

  def arrayify(param)
    return [] if param == nil
    param = [param]  if param.class != Array
    param
  end

  def array_for_sql(a)
    a.collect{|f| "'#{f}'"}.join(',')
  end
  
  def sql_workflow_condition(workflows,add_and=false)
    result = ''
    if workflows
      result << " and " if add_and
      result << %Q|workflow_state in (#{array_for_sql(arrayify(workflows))})|
    end
    result
  end
  
  def sql_field_conditions(conditions,add_and=false)
    result = ''
    if conditions
      result << " and " if add_and
      conditions = arrayify(conditions)
      result << conditions.collect do |c|
        c =~ /:([a-zA-Z0-9_-]+)/
        field_name = $1
        c = c.gsub(/:#{field_name}/,'answer')
        %Q|if(field_id='#{field_name}',if(#{c},true,false),true)|
      end.join(' and ')
    end
    result
  end
  
  def kaste(strng)
    return (strng == "true")
  end

  def parse_date(date)
    Utilities.parse_date(date)
  end
  
  def self.parse_date(value)
    tz = Form.get_store(:time_zone)
    if tz
      Utilities._parse_date(value).change(:offset => Time.find_zone(tz).formatted_offset)
    else
      Utilities._parse_date(value)
    end
  end

  def parse_datetime(datetime)
    Utilities.parse_datetime(datetime)
  end

  def self.parse_datetime(datetime)
    begin
      dt = _parse_datetime(datetime)
      [dt.year,dt.month,dt.day,dt.hour,dt.min,dt.sec]
    rescue
      [nil,nil,nil,nil,nil,nil]
    end
  end

  def self._parse_date(date)
    if date =~ /^\d+-/
      d = DateTime.parse(date)
    #DateTime parses 1/2/2012 as Feb 1st so account for that
    elsif date =~ /^\d+\/\d+\/\d+$/
      d = DateTime.strptime(date, '%m/%d/%Y')
    else
      d = DateTime.parse(date)
    end
    d.to_date
  end

  def self._parse_datetime(datetime)
    if datetime =~ /^\d+-/
      dt = DateTime.parse(datetime)
      #DateTime parses 1/2/2012 as Feb 1st so account for that
    elsif datetime =~ /^\d+\/\d+\/\d+$/
      dt = DateTime.strptime(datetime, '%m/%d/%Y')
    elsif datetime =~ /^\d+\/\d+\/\d+ \d+:\d+:\d+$/
      dt = DateTime.strptime(datetime, '%m/%d/%Y %H:%M:%S')
    elsif datetime =~ /^\d+\/\d+\/\d+ \d+:\d+$/
      dt = DateTime.strptime(datetime, '%m/%d/%Y %H:%M')
    else
      dt = DateTime.parse(datetime)
    end
    dt
  end

  def is_numeric?(i)
    return false if i == ''
    case i
    when Fixnum,Float
      true
    when String
      !(i.size == 1 ? i =~ /^\d$/ : i =~ /^(\d|-)?(\d|,)*\.?\d*$/).nil?
    else
      false
    end
  end
  def is_integer?(i)
    return false if i.nil?
    return true if i.is_a?(Fixnum)
    i = i.gsub(/,/,'')
    !(i.size == 1 ? i =~ /^\d$/ : i =~ /^[-+]?[1-9]\d*$/).nil?
  end
  
end