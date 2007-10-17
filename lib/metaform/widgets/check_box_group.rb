################################################################################
class CheckBoxGroupWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    e = enumeration(options[:constraints],'set')
    result = []
    checked = value.split(/,/) if value
    checked ||= []
    e.each do |key,val|
      result << %Q|<input name="#{build_html_multi_name(field_instance_id,val)}" id="#{build_html_multi_id(field_instance_id,val)}" type="checkbox" value="#{val}" #{checked.include?(val) ? 'checked' : ''}> #{key}|
    end
    params = options[:params]
    if params 
      (rows,cols) = params.split(/,/)
      result = unflatten(result,rows.to_i).collect {|col| col.join("<br />") }
      result = %Q|<table class="checkbox_group"><tr><td class="checkbox_group">#{result.join('</td><td class="checkbox_group">')}</td></tr></table>|
    else
      result = result.join("\n")
    end
    result << %Q|<input name="#{build_html_multi_name(field_instance_id,'__none__')}" id="#{build_html_multi_id(field_instance_id,'__none__')}" type="hidden"}>|
  end
  
  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span>#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('#{build_html_name(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    e = enumeration(constraints,'set')
    result = ""
    e.each do |key,value|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,value)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.is_multi_value?
    true
  end
  
  ################################################################################
  def self.convert_html_value(value)
    value.delete('__none__')
    return nil if value.size == 0
    value.keys.join(',')
  end
  
end
################################################################################
