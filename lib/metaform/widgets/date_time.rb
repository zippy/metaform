require "metaform/widget_date_time_helper"
################################################################################
class DateTimeWidget < Widget
  class << self
    include DateHelper
    include TimeHelper
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
    html + multi_field_wrapper_html(field_instance_id,
      time_html(field_instance_id,value,options,:date_time) +
      date_html(field_instance_id,value,options,:date_time)
      )
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    date = humanize_date_value(value,options)
    date ||= '--'
    time = humanize_time_value(value,options)
    time ||= '--'
    date  + ' ' + time
  end

  ################################################################################
  def self.javascript_get_value_function(field_instance_id) 
    %Q|$DTF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    javascript_date_build_observe_function(field_instance_id,script,options) + 
    javascript_time_build_observe_function(field_instance_id,script,options)
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    date = convert_date_html_value(value,params)
    time = convert_time_html_value(value,params)
    return nil if date.nil? || time.nil?
    Time.mktime(date.year,date.month,date.day,time.hour,time.min).strftime('%Y-%m-%d %H:%M')
  end

end
################################################################################
