################################################################################
class TextFieldWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    opts = {}
    if options[:params]
      (size,max_length) = options[:params].split(/\W*,\W*/)
      if size
        opts[:size] = size
        opts[:class] = "textfield_"+size
      end
      opts[:maxlength] = max_length if max_length
    end
    opts.update({:id => build_html_id(field_instance_id)})
	  form.text_field_tag(build_html_name(field_instance_id),value,opts)
  end
    
end
################################################################################

