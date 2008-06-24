require "metaform/widget_date_time_helper"
################################################################################
class DateWidget < Widget
  class <<self
    include DateHelper
  end
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    date_html(field_instance_id,value,options)
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    humanize_date_value(value,options)
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id) 
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    javascript_date_build_observe_function(field_instance_id,script,options)
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    convert_date_html_value(value,params).to_s
  end

end
################################################################################
