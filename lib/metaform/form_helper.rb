module FormHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  def table(attributes={},&block)
    html_tag 'table',attributes,block
  end

  def div(attributes={},&block)
    html_tag 'div',attributes,block
  end

  def html_tag(tag,attributes,block)
    if @render
      attribute_string = ''
      attributes.each { |key,value|
        attribute_string << " #{key}='#{html_escape(value)}'"
      }
      html %Q|<#{tag}#{attribute_string}>|
      block.call
      html "</#{tag}>"
    else
      block.call
    end
  end

  def workflow_action_button(label, workflow_state, options={})
    options[:container_attrs] ||= {}
    options[:container_attrs]['class'] ||= 'submit_form_button'
    options[:button_attrs] ||= {}
    options[:button_attrs][:css_class] ||= nil
    div(options[:container_attrs]) do
      function_button label,options[:button_attrs] do
        r = ["this.disabled=true;"]
        r << "$('#{options[:loading_img_id]}').show();" if options[:loading_img_id]
        r << javascript_submit(:workflow_action => workflow_state)
        r
      end
      html image_tag(options[:loading_img] || 'loading.gif', :id=>"#{options[:loading_img_id]}", :style=>"display:none;") if options[:loading_img_id]
    end
  end
end
