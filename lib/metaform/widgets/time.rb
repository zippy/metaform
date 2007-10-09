################################################################################
class TimeWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    form.time_select('record', field_instance_id)
  end
end
################################################################################
