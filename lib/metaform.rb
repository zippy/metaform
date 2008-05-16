class MetaformException < RuntimeError
end
class MetaformUndefinedFieldError < MetaformException
#  attr :field
#  def initialize(field)
#    @field = field
#  end
end

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
      if file =~ /(.*form)\.rb$/i
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
    file = Form.forms_dir+'/'+klass+'.rb'
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
