class FormInstance < ActiveRecord::Base
#  belongs_to :form
  has_many :field_instances, {:dependent => :destroy}
  validates_presence_of :form_id
  serialize :validation_data
  
  attr_accessible :updated_at, :validation_data, :workflow_state
  
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


  # FROM DOULADATA
  # TODO: Figure out why the form_instance_extensions in douladata's app/model isn't working correctly in development mode.
  # It seems to be overriding this class, resulting in the error: Association named 'field_instances' was not found;

  def get_max_contact_index(type)
    get_validation_data["_#{type}_max_index"]
  end

  def FormInstance.get_max_contact_index(id,type)
    FormInstance.find(id).get_max_contact_index(type)
  end

  def update_max_contact_index(type,index)
    update_validation_data({"_#{type}_max_index" => index})
  end

end

