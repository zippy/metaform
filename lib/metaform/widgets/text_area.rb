################################################################################
class TextAreaWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
   params = options[:params]
    if params
      (rows,cols) = params.split(/,/)
      opts = {:cols => cols, :rows => rows}
    else
      opts = {}
    end
    #TODO This generates HTML with id=name, so the id follows the wrong syntax.
    form.text_area_tag(build_html_name(field_instance_id),value,opts)
  end
end
################################################################################
