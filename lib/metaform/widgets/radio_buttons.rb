################################################################################
class RadioButtonsWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    result = ""
    e = enumeration(options[:constraints])
    result = []
    e.each do |key,val|
      field_id = build_html_multi_id(field_instance_id,val)
      result << %Q|<input name="#{build_html_name(field_instance_id)}" id="#{field_id}" class="#{field_instance_id}" type="radio" value="#{val}" #{value==val ? 'checked' : ''}> <label for="#{field_id}">#{key}</label>|
    end
    params = options[:params]
    if params
      (rows,cols,table_class) = params.split(/,/)
      table_class ||= 'radio_buttons'
      result = unflatten(result,rows.to_i).collect {|col| col.join("<br />") }
      i = 0
      result.map!{|r| i = i + 1; "<td class='radio_buttons col_#{i}' valign='top'>#{r}</td>"}
      %Q|<table class="#{table_class}"><tr>#{result.join}</tr></table>|
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
    %Q|$RF('.#{field_instance_id}')| 
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    e = enumeration(options[:constraints])
    result = ""
    e.each do |key,value|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,value)}', 'click', function(e){#{script} });\n| 
    end
    result
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    value = nil if value == ''
    value
  end

end
################################################################################
