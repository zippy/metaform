################################################################################
class TextFieldWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    form.text_field_tag("record[#{field_instance_id}]",value)
  end
    
end
################################################################################
