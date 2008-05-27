module FormHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper

  def table(attributes={},&block)
    html_tag 'table',attributes,block
  end

  def div(attributes={},&block)
    html_tag 'div',attributes,block
  end

  def html_tag(tag,attributes,block)
    attribute_string = ''
    attributes.each { |key,value|
      attribute_string << " #{key}='#{html_escape(value)}'"
    }
    html %Q|<#{tag}#{attribute_string}>|
    block.call
    html "</#{tag}>"
  end


end
