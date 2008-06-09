require "metaform/widget_date_time_helper"
################################################################################
class TimeWidget < Widget
  class <<self
    include TimeHelper
  end

  ################################################################################
  def self.parse_value(value)
    parse_time_value(value)
  end
  
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    time_html(form,field_instance_id,value,options)
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    humanize_time_value(value,options)
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$TF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    javascript_build_time_observe_function(field_instance_id,script,options)
  end
  

  ################################################################################
  def self.convert_html_value(value,params={})
    date = convert_time_html_value(value,params)
    date.strftime('%H:%M') if !date.nil?
  end
end
################################################################################
