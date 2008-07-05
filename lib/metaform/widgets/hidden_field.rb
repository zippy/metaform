################################################################################
class HiddenFieldWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    value = options[:params] if options[:params]
    opts = {:id => build_html_id(field_instance_id)}
	  form.hidden_field_tag(build_html_name(field_instance_id),value,opts)
  end
  def self.render_label(label,field_instance_id,form_object)
    form_object
  end
end
################################################################################

