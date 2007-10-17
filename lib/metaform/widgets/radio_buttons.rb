################################################################################
class RadioButtonsWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    result = ""
    e = enumeration(options[:constraints])
    result = []
    e.each do |key,val|
      result << %Q|<input name="#{build_html_name(field_instance_id)}" id="#{build_html_multi_id(field_instance_id,val)}" type="radio" value="#{val}" #{value==val ? 'checked' : ''}> #{key}|
    end
    params = options[:params]
    if params
      (rows,cols) = params.split(/,/)
      result = unflatten(result,rows.to_i).collect {|col| col.join("<br />") }
      %Q|<table class="radio_buttons"><tr><td class="radio_buttons" valign="top">#{result.join('</td><td class="radio_buttons" valign="top">')}</td></tr></table>|
    else
      result.join("\n")
    end
  end
  
  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span>#{form_object}|
  end
  
  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$RF('#{build_html_name(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    e = enumeration(constraints)
    result = ""
    e.each do |key,value|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,value)}', 'change', function(e){ #{script} });\n|
    end
    result
  end
  
  ################################################################################
  def self.convert_html_value(value)
    value = nil if value == ''
    value
  end

end
################################################################################
