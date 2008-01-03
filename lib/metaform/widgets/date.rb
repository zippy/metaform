################################################################################
class DateWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    require 'parsedate'
    if value && (d = ParseDate.parsedate(value))[0]
      date = Date.new(*d[0..2])
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" value="#{date.month}" /> /
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}" value="#{date.day}" /> /
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}" value="#{date.year}" />
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}"/> /
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}"  /> /
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}"  />
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
    %w(month year day).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
      date = Date.new(value['year'].to_i,value['month'].to_i,value['day'].to_i)      
      date.to_s
    rescue
      nil
    end
  end

end
################################################################################
