class MetaformException < RuntimeError
end
class MetaformUndefinedFieldError < MetaformException
  attr :field
  def initialize(field)
    @field = field
  end
end

require 'metaform/forms'
require 'metaform/listings'
require 'metaform/reports'
require 'metaform/constraints'
require 'metaform/widget'
require 'metaform/record'
require 'metaform/records_controller'
require 'metaform/field_instance'
require 'metaform/form_instance'
require 'metaform/metaform_helper'

################################################################################
# Load the form definitions from RAILS_ROOT/definitions
if File.directory?(Form.forms_dir)
  Dir.foreach(Form.forms_dir) do |file|
    require File.join(Form.forms_dir, file) if file.match(/\.rb$/)
  end
end
################################################################################
