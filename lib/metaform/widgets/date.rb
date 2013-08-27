require "metaform/widget_date_time_helper"
################################################################################
class DateWidget < Widget
  class <<self
    include DateHelper
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
    html + multi_field_wrapper_html(field_instance_id,date_html(field_instance_id,value,options))
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
    d = convert_date_html_value(value,params)
    d.strftime("%Y-%m-%d") if !d.nil?
  end

end
################################################################################
