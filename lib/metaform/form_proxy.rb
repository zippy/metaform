class FormProxy
  if Rails::VERSION::STRING =~ /^2./
    include ActionView::Helpers::ActiveRecordHelper
  elsif Rails::VERSION::STRING =~ /^3./
    include ActionView::Helpers::ActiveModelHelper
  end
    include ActionView::Helpers::AssetTagHelper
  #  include ActionView::Helpers::BenchmarkHelper
  #  include ActionView::Helpers::CacheHelper
  #  include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::DateHelper
  #  include ActionView::Helpers::DebugHelper
    include ActionView::Helpers::FormHelper
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::JavaScriptHelper
#    include ActionView::Helpers::JavaScriptMacrosHelper
  #  include ActionView::Helpers::NumberHelper
  #  include ActionView::Helpers::PaginationHelper
#    include ActionView::Helpers::PrototypeHelper
#    include ActionView::Helpers::PrototypeHelper::JavaScriptGenerator::GeneratorMethods
#    include ActionView::Helpers::ScriptaculousHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

  attr_accessor :name
  def initialize(n)
    @name = n
  end
end