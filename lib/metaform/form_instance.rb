class FormInstance < ActiveRecord::Base
#  belongs_to :form
  has_many :field_instances, {:dependent => :destroy}
  validates_presence_of :form_id
 
  def form
    form_id.constantize
  end
  
end
