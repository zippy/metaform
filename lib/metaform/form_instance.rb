class FormInstance < ActiveRecord::Base
#  belongs_to :form
  has_many :field_instances, {:dependent => :destroy}
  validates_presence_of :form_id

  def form
    form_id.constantize
  end
  
  def get_validation_data
    return validation_data if validation_data.is_a?(Hash)
    v = YAML.load(validation_data) if !validation_data.nil?
    v ||= {}
  end  
    
  def get_fresh_validation_data
    f = FormInstance.find(id)
    f.get_validation_data
  end
  
  def FormInstance.update_validation_data(id,updated_vd)
    f = FormInstance.find(id)
    f.validation_data = f.get_validation_data.update(updated_vd)
    f.save
  end
  
  def update_validation_data(updated_vd)
    FormInstance.update_validation_data(self.id,updated_vd)
  end
    
end

