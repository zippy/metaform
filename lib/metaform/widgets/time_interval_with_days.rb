################################################################################
class TimeIntervalWithDaysWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    if !value.blank?
      days = value.to_i / 1440
      minutes_left = value.to_i % 1440
      hours = minutes_left.to_i / 60
      minutes = minutes_left.to_i % 60
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'days')}" id="#{build_html_multi_id(field_instance_id,'days')}" value="#{days}" /> days
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" /> hours
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{minutes}" /> minutes
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'days')}" id="#{build_html_multi_id(field_instance_id,'days')}"/> days
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'hours')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/> hours
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  /> minutes
      EOHTML
    end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    days = value.to_i / 1440
    minutes_left = value - days* 1440
    hours = minutes_left.to_i / 60
    minutes = minutes_left.to_i % 60
    "#{days} days, #{hours} hours, #{minutes} minutes"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$TIWDF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(days hours minutes).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
      result = (!value['days'].blank? || !value['hours'].blank? || !value['minutes'].blank?) ? ((value['days'].to_i * 1440) + (value['hours'].to_i * 60) + value['minutes'].to_i).to_s : '' #Store as minutes
    rescue
      nil
    end
  end

end
################################################################################
