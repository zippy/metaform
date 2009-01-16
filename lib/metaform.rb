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

UsingPostgres = ActiveRecord::Base.connection.class == ActiveRecord::ConnectionAdapters::PostgreSQLAdapter

require 'metaform/utilities'
require 'metaform/form_proxy'
require 'metaform/form_helper'
require 'metaform/bin'
require 'metaform/property'
require 'metaform/dsl_objects'
#require 'metaform/forms'
require 'metaform/form'
require 'metaform/listings'
require 'metaform/reports'
require 'metaform/constraints'
require 'metaform/widget'
require 'metaform/record'
require 'metaform/record_cache'
require 'metaform/records_controller'
require 'metaform/field_instance'
require 'metaform/form_instance'
require 'metaform/metaform_helper'

=begin
################################################################################
# Load the form definitions from RAILS_ROOT/definitions
if File.directory?(Form.forms_dir)
  Dir.foreach(Form.forms_dir) do |file|
    require File.join(Form.forms_dir, file) if file.match(/\.rb$/)
  end
end
################################################################################
=end

if File.directory?(Form.forms_dir)
  forms = []
  requires = []
  Dir.foreach(Form.forms_dir) do |file|
    if file =~ /(.*)\.rb$/
      if file =~ /(.*)form\.rb$/i
        forms << $1
      else
        requires << file
      end
    end
  end
  requires.each do |file|
    require File.join(Form.forms_dir, file)
  end
  forms.each do |klass|
    file = Form.forms_dir+'/'+klass+'form.rb'
    file_contents = IO.read(file)
    new_class = <<-EORUBY
    class #{klass} < Form
      def setup
        #{file_contents}
      end
    end
    EORUBY
    eval new_class,nil,file
  end
end
