module MetaformHelper
  def include_metaform_assets
    if @metaform_include_assets
	    javascript_include_tag('metaform') << stylesheet_link_tag('metaform', :media => "all")
    else
      ''
    end
  end
end
