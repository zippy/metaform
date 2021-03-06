################################################################################
class TimeIntervalWidget < Widget
  self.extend Utilities
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    if !value.blank?
      hours = value.to_i / 60
      minutes = value.to_i % 60
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" /> hours
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{minutes}" /> minutes
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/> hours
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  /> minutes
      EOHTML
    end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    hours = value.to_i / 60
    minutes = value.to_i % 60
    "#{hours} hours, #{minutes} minutes"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$TIF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(hours minutes).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    hours = value['hours']
    minutes = value['minutes']
    return '' if hours.blank? && minutes.blank?
    return nil if (!is_numeric?(hours) && hours != '') || (!is_numeric?(minutes) && minutes != '')
    return (hours.to_f*60+minutes.to_i).to_i.to_s
  end

end
################################################################################
