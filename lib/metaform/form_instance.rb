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
  
end
