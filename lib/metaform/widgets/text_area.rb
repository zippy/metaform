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
    form.text_area_tag("record[#{field_instance_id}]",value,opts)
  end
end
################################################################################
