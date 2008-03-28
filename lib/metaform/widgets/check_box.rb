################################################################################
class CheckBoxWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    checked = value ? 'checked' : '' 
    result = []
    result << %Q|<input name="#{build_html_multi_name(field_instance_id,"Y")}" id="#{build_html_multi_id(field_instance_id,"Y")}" type="checkbox" #{checked}>|
    result << "\n"
    result << %Q|<input name="#{build_html_multi_name(field_instance_id,'__none__')}" id="#{build_html_multi_id(field_instance_id,'__none__')}" type="hidden"}>|
    result
  end 
   
   ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('#{build_html_name(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    %Q|var watcher_#{build_html_multi_id(field_instance_id,"Y")} = new WidgetWatcher('#{build_html_multi_id(field_instance_id,"Y")}', function(e){ #{script} });\n|
  end

  ################################################################################
  def self.is_multi_value?
    true
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    value.delete('__none__')
    return (value.size == 0) ? nil : "Y"
  end
  
end
################################################################################