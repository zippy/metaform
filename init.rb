if defined?(ActiveSupport::Dependencies)
  if ActiveSupport::Dependencies.respond_to?(:load_once_paths)
    ActiveSupport::Dependencies.load_once_paths -= ActiveSupport::Dependencies.load_once_paths.select{|path| path =~ %r(^#{File.dirname(__FILE__)}) }
  elsif ActiveSupport::Dependencies.respond_to?(:autoload_once_paths)
    ActiveSupport::Dependencies.autoload_once_paths -= ActiveSupport::Dependencies.autoload_once_paths.select{|path| path =~ %r(^#{File.dirname(__FILE__)}) }
  end
else
  #Prior to Rails 2.2.2 (?) we call Dependencies directly, without ActiveSupport.
  Dependencies.load_once_paths -= Dependencies.load_once_paths.select{|path| path =~ %r(^#{File.dirname(__FILE__)})}
end
require 'metaform'
ActionView::Base.send :include, MetaformHelper
