module TimeHelper
  def time_html(field_instance_id,value,options,time_type=:time)
    meridian_options = [ ["AM","am"] , ["PM","pm"] ]
    id = build_html_id(field_instance_id)
    fn = "mark_invalid_#{time_type.to_s}"
    js = %Q|onblur="if (#{id}_first_pass) {#{fn}('#{id}')}"|
    jsh = (time_type == :time) ?  %Q|onblur="#{fn}('#{id}');#{id}_first_pass = true;"| : js
    if value
      (hours,minutes,meridian) = parse_time_value(value)
      <<-EOHTML
      <input #{js} type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" maxlength="2"/>:
      <input #{jsh} type="text" class="left_margin_neg_5 textfield_2" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{minutes}" maxlength="2"/>
      <select #{js} name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
      	#{form.options_for_select(meridian_options, meridian)}
	  </select>
      EOHTML
    else
      <<-EOHTML
      <input #{js} type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" maxlength="2"/>:
      <input #{jsh} type="text" class="left_margin_neg_5 textfield_2" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" maxlength="2" />
      <select name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
	  	   #{form.options_for_select(meridian_options, "am")}
	  </select>
      EOHTML
    end
  end

  ################################################################################
  def has_time?(value)
    value =~ /:/ ? true : false
  end

  ################################################################################
  def parse_time_value(value)
    return nil if value.blank?
    return nil if !has_time?(value)
    date = Time.parse(value)
    hours = date.hour
    meridian = "am"
    if (hours > 12)
    	hours = hours - 12
    	meridian =  "pm"
  	elsif (hours == 0)
  	  hours = 12
  	elsif (hours == 12)
    	meridian =  "pm"
    end
    [hours.to_s,sprintf("%02d",date.min),meridian]
  end

  ################################################################################
  def humanize_time_value(value,options=nil)
    time = parse_time_value(value)
    if time
      (hours,minutes,meridian) = time
      "#{hours}:#{minutes} #{meridian}"
    end
  end

  ################################################################################
  def javascript_time_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(hours minutes am_pm).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def convert_time_html_value(value,params={})
    h = value['hours']
    m = value['minutes']
    return nil if h.blank? || m.blank?
    return nil if h =~ /[^0-9]/ || m =~ /[^0-9]/
    begin
      str = "#{h}:#{m}"
      str << " #{value['am_pm']}" if h.to_i < 13
      date = Time.parse(str)
    rescue
      nil
    end
  end
end

module DateHelper
  ################################################################################
  def date_html(field_instance_id,value,options,date_type=:date)
    date = parse_date_value(value)
    id = build_html_id(field_instance_id)
    fn = "mark_invalid_#{date_type.to_s}"
    js = %Q|onblur="if (#{id}_first_pass) {#{fn}('#{id}')}"|
    jsy = %Q|onblur="#{fn}('#{id}');#{id}_first_pass = true;"|
    if date
      result = <<-EOHTML
<input #{js} type="text" #{auto_tab_text(field_instance_id,'day')} size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" value="#{date.month}" maxlength="2"/> /
<input #{js} type="text" #{auto_tab_text(field_instance_id,'year')} size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}" value="#{date.day}" maxlength="2"/> /
<input #{jsy} type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}" value="#{date.year.to_s[0..3]}" maxlength="4"/> <span class=\"instructions\">(MM/DD/YYYY)</span>
EOHTML
    else
      result = <<-EOHTML
<input #{js} type="text" #{auto_tab_text(field_instance_id,'day')} size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" maxlength="2"/> /
<input #{js} type="text" #{auto_tab_text(field_instance_id,'year')} size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}" maxlength="2" /> /
<input #{jsy} type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}"  maxlength="4"/> <span class=\"instructions\">(MM/DD/YYYY)</span>
EOHTML
    end
    result
  end
  def auto_tab_text(f_id, next_field)
    # %Q*onkeyup="tabNext(this,'up',2,$('#{build_html_multi_id(f_id,next_field)}'))" onkeydown="tabNext(this,'down',2)"*
  end

  ################################################################################
  def parse_date_value(value)
    require 'date'
    date = nil
    if value
      begin
        date = Utilities._parse_datetime(value).to_date
      rescue
      end
    end
    date
  end

  ################################################################################
  def humanize_date_value(value,options=nil)
    date = parse_date_value(value)
    if date
      "#{date.month}/#{date.day}/#{date.year}"
    end
  end

  ################################################################################
  def javascript_date_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(month year day).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def convert_date_html_value(value,params={})
    begin
      if !value['year'].blank? && !value['month'].blank? && !value['day'].blank? && value['year'] =~ /^[0-9]+$/ && value['month'] =~ /^[0-9]+$/ && value['day'] =~ /^[0-9]+$/
        year = value['year'].to_i
        year = year + 2000 if year <= 37
        year = year + 1900 if year > 37 && year < 100
        date = Time.mktime(year,value['month'].to_i,value['day'].to_i)
      else
        nil
      end
    rescue
      nil
    end
  end

end

module MonthYearHelper
  ################################################################################
  def month_year_html(field_instance_id,value,options)
    date = parse_value(value)
    hide_label = options[:params]
  	label = hide_label ? "" : " (month/year)"
    id = build_html_id(field_instance_id)
    fn = 'mark_invalid_month_year'
    js = %Q|onblur="if (#{id}_first_pass) {#{fn}('#{id}')}"|
    jsy = %Q|onblur="#{fn}('#{id}');#{id}_first_pass = true;"|
    if date
      result = <<-EOHTML
<input #{js} type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" value="#{date.month}" /> /
<input #{jsy} type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}" value="#{date.year}" />#{label}
EOHTML
    else
     result = <<-EOHTML
<input #{js} type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}"/> /
<input #{jsy} type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}"  />#{label}
EOHTML
    end
    result
  end

  ################################################################################
  def convert_month_year_html_value(value,params={})
    value['day']='1'
    convert_date_html_value(value,params)
  end

end
