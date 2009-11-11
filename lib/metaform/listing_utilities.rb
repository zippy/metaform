#These listing utility methods are used by Listings.  ActionController::Base subclasses
#can also include them to take advantage of nice methods for organizing search and sort parameters.

ILIKE = UsingPostgres ? 'ilike' : 'like'

module ListingUtilities
 
  def def_sort_rules(*args)
    @sort_rules = {}
    args.each{|k| def_sort_rule(k)}
    yield if block_given?
  end
  
  def def_sort_rule(sort_key,proc=nil,&block)  #This was previously just def sort_rule
    if block_given?
      @sort_rules[sort_key] = block
    else
      if sort_key.is_a?(String)
        if proc
          @sort_rules[sort_key] = proc
        else
          @sort_rules[sort_key] = Proc.new do |r|
            r && r["#{sort_key}"] ? r["#{sort_key}"].downcase : ""
          end
        end
      else  #This style only works for Rails models & find
        @sort_rules[sort_key[0]] = Proc.new do 
          sort_key[1] ? sort_key[1].downcase : ""
        end
      end
    end
  end
  def def_sort_rule_date(sort_key) #This was previously just def sort_rule_date
    @sort_rules[sort_key] = Proc.new do |r|
      (r && r[sort_key] && r[sort_key] != '') ? Time.mktime(*ParseDate.parsedate(r[sort_key])[0..2]) : Time.new
    end
  end
  def apply_sort_rule(r = nil)
    orders = []
    order = @search_params[:order]
    if order
      raise "No sort rule is defined for #{order}" if  !@sort_rules[order]
      orders << order
      if @order_second
        order_second = @order_second.is_a?(Proc) ? @order_second.call(order) : @order_second
        if order_second
          raise "No sort rule is defined for #{order_second}" if order_second && !@sort_rules[order_second]
          orders = orders << order_second
        end
      end
    end
    orders.map{|order| @sort_rules[order].call(r)} 
  end
    
  def def_search_rules(kind,pairs)
    @search_rules ||= {}
    @search_rules['all'] = 'dummy value'
    case kind
    when :sql #The search rules generated here will be used for a call to Rails find.
      pairs.each do |key,field|
        def_search_rule(key+'_b') {|search_for| ["#{field} #{ILIKE} ?",search_for+'%']}
        def_search_rule(key+'_c') {|search_for| ["#{field} #{ILIKE} ?",'%'+search_for+'%']}
        def_search_rule(key+'_is') {|search_for| ["#{field} = ?", search_for]}
        def_search_rule(key+'_not') {|search_for| ["#{field} != ?", search_for]}
      end
    when :locate #The search rules generated here will be used for a call to Record.locate
      pairs.each do |key,field|
        def_search_rule(key+'_b', :regex=>true) {|search_for| ":#{field} =~ /^#{search_for}/i"}
        def_search_rule(key+'_c', :regex=>true) {|search_for| ":#{field} =~ /#{search_for}/i"}
        def_search_rule(key+'_is') {|search_for| ":#{field} == '#{search_for}'"}
        def_search_rule(key+'_not') {|search_for| ":#{field} != '#{search_for}'"}
      end
    when :search  #The search rules generated here will be used for a call to Record.search
      pairs.each do |key,field|
        def_search_rule(key+'_b') {|search_for| ":#{field} #{ILIKE} '#{search_for}%'"}
        def_search_rule(key+'_c') {|search_for| ":#{field} #{ILIKE} '%#{search_for}%'"}
        def_search_rule(key+'_is') {|search_for| ":#{field} = '#{search_for}'"}
        def_search_rule(key+'_not',:negate=>true) {|search_for| ":#{field} = '#{search_for}'"}
      end
    end
  end
  
  def def_search_rule(key,params={},&block)
    @search_rules ||= {}
    if params.is_a?(Proc)
      @search_rules[key] = {:block => params}
    elsif block
      @search_rules[key] = params.update(:block => block) 
    else
      @search_rules[key] = params
    end
  end
  
  def generate_search_options(kind)
    case kind
    when :sql
      apply_search_rules(true)
    when :locate
      apply_search_rules(false)
    when :search
      options = {}
      conditions = []
      meta_conditions = []
      generate_options do |search_rule,search_for|
        # searching for something with | in it requires ust to generate the full conditions ored together
        c = '('+search_for.split(/\W*\|\W*/).collect {|search_for| search_rule[:block].call(search_for)}.join(' or ')+')'
        c = 'not '+c if search_rule[:negate]
        search_rule[:meta_condition] ? meta_conditions.push(c) : conditions.push(c)
      end
      options[:conditions] = conditions.join(' and ') if !conditions.empty?
      options[:meta_condition] = meta_conditions.join(' and ') if !meta_conditions.empty?
      options = nil if options.empty?
      options
    end
  end
  
  def generate_options
    @search_params.each_pair do |k,v|
      if v == 'all'
        @display_all = true
      elsif k =~ /^on(.*)/ && v && v != ''
        params_key = k
        params_value = v      
        matching_params_key = 'for' + $1 
        raise "No search rule is defined for #{params_value}" if !@search_rules.has_key?(params_value)
        raise "No search value is defined for #{matching_params_key}" if !@search_params.has_key?(matching_params_key)
        if @search_params[matching_params_key] != ''
          yield @search_rules[params_value],@search_params[matching_params_key]
        end
      end
    end
  end
  
  def apply_search_rules(sql)
    filters ||= []
    generate_options do |search_rule,search_for|
      if search_rule[:regex]
        search_for = Regexp.escape(search_for).gsub('/','\/') unless sql
        search_for = search_for.split(/\\\||\|/)
      else
        search_for = [search_for]
      end
      queries = []
      terms = [] if sql
      search_for.map!{|s| search_rule[:block].call(s)}.each do |s|
        if sql
          queries << s[0]
          terms << s[1..s.size]
          terms = terms.flatten
        else
          queries << s
        end
      end
      if sql 
        search_for = ["(#{queries.join(' or ')})",terms]
      else
        search_for = queries.join(' || ')
      end
      filters << search_for
    end
    if sql #Combine filters in format sql likes
      conditions = []
      sql_terms = []
      filters.each do |f|
        sql_terms << f[0]
        conditions = conditions + f[1]
      end
      sql_terms = sql_terms << @search_params[:sql] if (@search_params[:sql] && @search_params[:sql] != '')
      filters = [sql_terms.join(" and ")] + conditions if (sql_terms != [] || conditions != [])
    end
    filters = nil if filters.empty? 
    filters
  end
  
  def field_blank_sql(field)
    "(:#{field} = '' or :#{field} is null)"
  end
  
  def set_params(listing_type,use_session,defaults={})  
    @params = params if self.methods.include?('params')
    @session = session if self.methods.include?('session')
    if !@params[:search] 
      # if the search params aren't in the actual params from the request
      # then you can look for them in the session, if that's what the page would like
      if use_session
        @search_params = @session[listing_type]
      end
    else
      @search_params = @params[:search].update({:page => @params[:page]})
    end
    @search_params ||= {}
    #This is currently deprecated.  Rewrite in the current listings framework if it is ever necessary:
    #@search_params[:order_last] = @session[listing_type][:order] if @session[listing_type] && @session[listing_type].key?(:order)  
    #grab order param from session for secondary sort, if it's nontrivial and not the current order
    defaults.each do |param,default|
      if (!use_session || param = :order) && (!@search_params.key?(param) || @search_params[param] == '')
        @search_params[param] = default
      end
    end
    @search_params.each_pair do |k,v| 
      if k =~ /^on(.*)/ && (!v || v == '')
        matching_params_key = 'for' + $1 
        @search_params[matching_params_key] = ''
      end
    end
    session[listing_type] = @search_params if self.methods.include?('session')   #Store in session in case needed later
  end

  def get_sql_options
    options = {}
    options[:order] = apply_sort_rule.join(",")
    options[:conditions] = generate_search_options(:sql)
    options
  end
  
end