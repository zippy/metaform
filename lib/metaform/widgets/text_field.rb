################################################################################
class TextFieldWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
  	opts = options[:params] ? {:size => options[:params] } : {}		
  	form.text_field_tag(build_html_name(field_instance_id),value,opts)
  end
    
end
################################################################################

