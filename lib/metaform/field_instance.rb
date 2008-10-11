class FieldInstance < ActiveRecord::Base
  belongs_to :form_instance
#  belongs_to :field
  validates_uniqueness_of :field_id, :scope => [:form_instance_id,:idx]
  validates_presence_of :field_id,:form_instance_id

  States = %w(unanswered answered invalid explained calculated approved)
  validates_inclusion_of :state, :in => States
    
  def field
    form_instance.form.field_exists?(field_id)
  end
  
  #TODO figure out if we want to do rails level validation of field instances...
  def validatex
    logger.info "fish"
    unless field
      errors.add(:field_id, "doesn't exist")
    end

    unless form_instance
      errors.add(:form_instance_id, "doesn't exist")
    end
    
    #only show this message if the other two aren't there (annoying otherwise)
    if field && form_instance
#      unless field.in_form?(form_instance.form)
#        errors.add(:field_id, "is not in this form")
#      end
    end
  end

end
