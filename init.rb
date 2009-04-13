if defined?(ActiveSupport::Dependencies)
  ActiveSupport::Dependencies.load_once_paths -= ActiveSupport::Dependencies.load_once_paths.select{|path| path =~ %r(^#{File.dirname(__FILE__)}) }
else
  #Prior to Rails 2.2.2 (?) we call Dependencies directly, without ActiveSupport.
  Dependencies.load_once_paths -= Dependencies.load_once_paths.select{|path| path =~ %r(^#{File.dirname(__FILE__)})}
end
require 'metaform'
ActionView::Base.send :include, MetaformHelperMethods
