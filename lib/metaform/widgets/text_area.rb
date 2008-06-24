################################################################################
class TextAreaWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
   params = options[:params]
    if params
      (rows,cols) = params.split(/,/)
      opts = {:cols => cols, :rows => rows}
    else
      opts = {}
    end
    opts.update({:id => build_html_id(field_instance_id)})
    form.text_area_tag(build_html_name(field_instance_id),value,opts)
  end
end
################################################################################
