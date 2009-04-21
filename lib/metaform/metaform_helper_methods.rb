#These metaform helper methods are automatically added to all ActionViews

ILIKE = UsingPostgres ? 'ilike' : 'like'

module MetaformHelperMethods

  #####################################################################################
  # use include_metaform_assets in your layouts that will be rendering metaform forms
  # then you can turn on actually including these assets programatically in a view-by-view
  # bases by setting @metaform_include_assets to true
  def include_metaform_assets
    if @metaform_include_assets
      javascript_include_tag('metaform') << stylesheet_link_tag('metaform', :media => "all")
    else
      ''
    end
  end
  #####################################################################################

  #This method creates a fieldset which holds a form used to set filters for a search.  It can be used
  #for metaform records searches by listings and also by Rails-model searches.  
  def get_search_form_html(params)
    order_choices = params[:order_choices]
    search_pair_info = params[:search_pair_info]
    select_options = {}
    params[:select_options].each{|k,v| select_options[k] = v.is_a?(Proc) ? v.call : v }
    allow_manual_filters = params[:allow_manual_filters]
    allow_manual_filters ||= false
    form_pairs_html = []
    search_pair_info.each do |pair|
      first_focus = pair[:first_focus] ? {:class => 'first_focus'} : {}
      this_html = pair[:label] ? pair[:label] : ''
      this_html = this_html + 
        case pair[:on]
        when :select
          select_tag("search[on_#{pair[:name]}]", options_for_select(select_options[pair[:name]],@search_params["on_#{pair[:name]}"])) 
        when :text_field
          text_field_tag("search[on_#{pair[:name]}]", @search_params["on_#{pair[:name]}"])
        when :hidden
          hidden_field(:search, "on_#{pair[:name]}", :value => pair[:value])
        else
          ''
        end
      this_html = this_html +
        case pair[:for]
        when :select
          select_tag("search[for_#{pair[:name]}]", options_for_select(select_options[pair[:name]],@search_params["for_#{pair[:name]}"]),first_focus) 
        when :text_field
          val = ''
          val = @search_params["for_#{pair[:name]}"] if !['all','',nil].include?(@search_params["on_#{pair[:name]}"]) 
          text_field_tag("search[for_#{pair[:name]}]", val,first_focus)
        when :hidden
          hidden_field(:search, "for_#{pair[:name]}", :value => pair[:value])
        else
          ''
        end
      this_html = this_html + text_field_tag("search[sql]", @search_params[:sql]) if pair[:sql]
      form_pairs_html << this_html
    end
  	order_select = "Order by:  " + select_tag('search[order_current]', options_for_select(order_choices,@search_params[:order_current]))
  	mf = %Q|<p>Manual filters: #{ text_field_tag('search[manual_filters]', @search_params[:manual_filters], :size=>60)}</p>| if allow_manual_filters
  
    html =<<-EOHTML
    <fieldset class='search_box'><legend>Search</legend><p>#{form_pairs_html.join("</p><p>")}</p>
      <p>#{order_select}</p>#{mf}
      <p>#{check_box_tag('search[paginate]','yes',@search_params[:paginate]=='yes')} Paginate results
        <input id='search[paginate]' name='search[paginate]' type='hidden' value='no' />
      </p>
      <p><input type='submit' name='Submit' value='Search'></p>
    </fieldset>
    EOHTML
  end
end