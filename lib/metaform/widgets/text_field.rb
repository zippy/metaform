################################################################################
class TextFieldWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    if options[:read_only] 
      "<span id=\"record[#{field_instance_id}]\">#{value}</span>"
    else
      opts = options[:params] ? {:size => options[:params], :class  => "textfield_"+options[:params] } : {}	
  	  form.text_field_tag(build_html_name(field_instance_id),value,opts)
  	end
  end
    
end
################################################################################

