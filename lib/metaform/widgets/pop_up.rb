################################################################################
class PopUpWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    e = enumeration(options[:constraints])
    raise (constraints.inspect << field_instance_id) if e.nil?
    form.select('record',field_instance_id,e,{:selected => value})
  end
end
################################################################################
