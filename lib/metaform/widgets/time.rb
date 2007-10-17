################################################################################
class TimeWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    form.time_select('record', field_instance_id)
    require 'parsedate'
    if value
      d = *ParseDate.parsedate(value)
      date = Time.local(1,1,1,d[3],d[4])
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{date.hour}" /> :
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{date.min}" />
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/> :
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  />
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
  def self.convert_html_value(value)
    begin
      date = Time.local(1,1,1,value['hours'],value['minutes'])      
      date.strftime('%H:%M')
    rescue
      nil
    end
    
  end

end
################################################################################
