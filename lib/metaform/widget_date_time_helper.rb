module TimeHelper
  def time_html(field_instance_id,value,options)
    meridian_options = [ ["AM","am"] , ["PM","pm"] ]
    if value
      (hours,minutes,meridian) = parse_time_value(value)
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" />:
      <input type="text" class="left_margin_neg_5 textfield_2" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{minutes}" />
      <select name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
      	#{form.options_for_select(meridian_options, meridian)}
	  </select>
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/>:
      <input type="text" class="left_margin_neg_5 textfield_2" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  />
      <select name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
	  	   #{form.options_for_select(meridian_options, "am")}
	  </select>
      EOHTML
    end
  end
  ################################################################################
  def parse_time_value(value)
    return nil if value.nil? 
    require 'parsedate'
    d = *ParseDate.parsedate(value)
    date = Time.local(1,1,1,d[3],d[4])      
    hours = date.hour
    meridian = "am"
    if (hours > 12)
    	hours = hours - 12
    	meridian =  "pm"
    end
    [hours,sprintf("%02d",date.min),meridian]
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
    begin
      hours = value['hours'].to_i
      factor = value['am_pm'] == 'pm' && hours != 12 ? 12 : 0	
      date = Time.local(1,1,1,hours + factor,value['minutes'])
    rescue
      nil
    end
  end
end


module DateHelper
  ################################################################################
  def date_html(field_instance_id,value,options)
    date = parse_date_value(value)
    if date
      <<-EOHTML
<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" value="#{date.month}" /> /
<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}" value="#{date.day}" /> /
<input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}" value="#{date.year.to_s[0..3]}" /> <span class=\"instructions\">(MM/DD/YYYY)</span>
EOHTML
    else
      <<-EOHTML
<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}"/> /
<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}"  /> /
<input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}"  /> <span class=\"instructions\">(MM/DD/YYYY)</span>
EOHTML
    end
  end

  ################################################################################
  def parse_date_value(value)
    require 'parsedate'
    date = nil
    if value && (d = ParseDate.parsedate(value))[0]
      date = Date.new(*d[0..2])
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
      year = value['year'].to_i
      year = year + 2000 if year < 70
      year = year + 1900 if year >=70 && year < 100
      date = Time.mktime(year,value['month'].to_i,value['day'].to_i) 
    rescue
      nil
    end
  end
end
