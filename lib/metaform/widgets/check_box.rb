################################################################################
class CheckBoxWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    checked = (value == 'Y')
    opts = options[:params] ? {:class  => "checkbox_"+options[:params] } : {}
    opts.update({:id => build_html_id(field_instance_id)})
	  form.check_box_tag(build_html_name(field_instance_id),"Y",checked,opts)
  end 
   
   ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CB('#{build_html_id(field_instance_id)}')|
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    return (value.size == 0) ? nil : "Y"
  end
  
end
################################################################################
