################################################################################
class TimeIntervalWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    if value 
      hours = value.to_i / 60
      minutes = value.to_i % 60
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" /> hours
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{minutes}" /> minutes
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/> hours
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  /> minutes
      EOHTML
    end
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(hours minutes).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
      interval = (value['hours'].to_i * 60 + value['minutes'].to_i).to_s
    rescue
      nil
    end
  end

end
################################################################################
