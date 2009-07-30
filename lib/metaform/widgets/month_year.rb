require "metaform/widget_date_time_helper"
################################################################################
class MonthYearWidget < Widget
  class <<self
    include MonthYearHelper
  end
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    html = <<-EOHTML
    <script type="text/javascript">
    //<![CDATA[
    var record_#{field_instance_id}_first_pass =  #{value.blank? ? 'false' : 'true'};
    //]]>
    </script> 
    EOHTML
    html + multi_field_wrapper_html(field_instance_id,month_year_html(field_instance_id,value,options))
  end

  ################################################################################
  def self.parse_value(value)
    require 'parsedate'
    date = nil
    if !value.blank? && (d = ParseDate.parsedate(value))[0]
      date = Date.new(*d[0..2])
    end
    date
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    date = parse_value(value)
    if date
      "#{date.month}/#{date.year}"
    end
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id) 
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(month year).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
      date = Date.new(value['year'].to_i,value['month'].to_i,1)      
      date.to_s
    rescue
      nil
    end
  end

end
################################################################################
