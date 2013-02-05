require "metaform/version"

#module Metaform
  # Your code goes here...
#end

class MetaformException < RuntimeError
end
class MetaformIllegalStateForPresentationError < MetaformException
  def initialize state, presentation
    super "presentation #{presentation} is not allowed when form is in state #{state}"
  end
end
class MetaformIllegalStateForActionError < MetaformException
  def initialize state, action
    super "action #{action} is not allowed when form is in state #{state}"
  end
end
class MetaformFieldUpdateError < MetaformException
  attr :saved_attributes
  attr :unsaved_field_instances
  def initialize saved_attribs, unsaved_fields
    @unsaved_field_instances = unsaved_fields
    @saved_attributes = saved_attribs
    super "Some field(s) were not saved: #{unsaved_fields.collect {|f| f.field_id}.inspect}"
  end
end
class MetaformUndefinedFieldError < MetaformException
#  attr :field
#  def initialize(field)
#    @field = field
#  end
end

class MetaformIllegalSearchParameterError < MetaformException
end

require 'metaform/listing_utilities'
require 'metaform/engine'
require 'metaform/utilities'
require 'metaform/form_proxy'
require 'metaform/form_helper'
require 'metaform/bin'
require 'metaform/property'
#require 'metaform/forms'
require 'metaform/form'
require 'metaform/reports'
require 'metaform/constraints'
require 'metaform/widget'
require 'metaform/record'
require 'metaform/record_cache'
# require 'metaform/records_controller'
# require 'metaform/field_instance'
# require 'metaform/form_instance'
require 'metaform/metaform_helper_methods'
require 'metaform/dsl_objects'

