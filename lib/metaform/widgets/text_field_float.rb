################################################################################
class TextFieldFloatWidget < Widget
  class << self 
    include Utilities
  end
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    opts = {}
    if options[:params]
      (size,max_length,allow_negatives) = options[:params].split(/\W*,\W*/)
      if size
        opts[:size] = size
        opts[:class] = "textfield_"+size
      end
      opts[:maxlength] = max_length if max_length
    end
    id = build_html_id(field_instance_id)
    opts.update({:id => id, :onkeyup => "mark_invalid_float('#{id}')",:onchange => "mark_invalid_float('#{id}')"})
	  field_html = form.text_field_tag(build_html_name(field_instance_id),value,opts)
    multi_field_wrapper_html(field_instance_id,field_html)
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    return nil if ! is_numeric?(value)
    v = value.to_f
    return nil if v < 0
    v
  end
   
end
################################################################################

