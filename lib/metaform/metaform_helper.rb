module PagesHelper
  def include_metaform_assets
    if @metaform_include_assets
	    javascript_include_tag('metaform') << stylesheet_link_tag('metaform')
    else
      ''
    end
  end
end
