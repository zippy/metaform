class Field < Bin
  def bins
    {
      :name => nil,
      :label => nil,
      :type => nil,
      :constraints => nil,
      :followups => nil,
      :followup_conditions => nil,
      :default => nil,
      :indexed_default_from_null_index => nil,
      :calculated => nil,
      :properties => [Invalid],
      :calculated => nil,
      :default => nil, 
      :indexed_default_from_null_index => nil,
      :groups => nil,
      :force_nil_if => nil
    }
  end
  def required_bins
    [:name,:type]
  end
  def force_nil_fields
    return nil if force_nil_if.nil?
    f = []
    force_nil_if.each { |cond,fields| f.concat(fields) if cond.evaluate }
    f
  end
end

class Condition < Bin
  OperatorMatch = /(\w*)\s*((<)|(>)|(!=)|(=!)|(=~)|(!~)|(~!)|(=+)|(includes)|(!includes)|(answered)|(!answered))\s*(.*)/
  def bins 
    { :form => nil,:name => nil, :description => nil, :ruby => nil,:javascript => nil,:operator =>nil,:field_value =>nil,:field_name =>nil }
  end
  def required_bins
    [:form,:name]
  end
  
  def initialize(b={})
    super(b)
    if name =~ OperatorMatch
      self.field_name = $1
      self.operator = $2
      self.field_value = $15
    else
      raise MetaformException, "javascript not defined or definable for condition '#{name}'" if javascript.nil?
    end
  end
   
  def humanize
    return description if description
    form_field = form.fields[self.field_name]
    hfn = form_field.label if form_field
    hfn ||= field_name
    case operator
    when '=','=='
     "#{hfn} is #{field_value}"
    when '!=','=!'
      "#{hfn} is not #{field_value}"
    when '<'
      "#{hfn} is less than #{field_value}"
    when '>'
      "#{hfn} is greater than #{field_value}"
    when '=~'
      "#{hfn} matches regex #{field_value}"
    when '!~','~!'
      "#{hfn} does not match regex #{field_value}"
    when 'includes'
      "#{hfn} includes #{field_value}"
    when '!includes'
      "#{hfn} does not include #{field_value}"
    when 'answered'
      "#{hfn} is answered"
    when '!answered'
      "#{hfn} is not answered"
    else
      name.gsub(/_/,' ')
    end
  end
  
  def js_function_name
    js = humanize
    js = js.gsub(/[- ]/,'_')
    js = js.gsub(/\W/,'')
  end
  
  def evaluate(index = -1)
    if ruby
      ruby.call(self)
    else
      cur_val = form.field_value(field_name,index)      
      case operator
      when '=','=='
       cur_val == field_value
      when '!=','=!'
        cur_val != field_value
      when '<'
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i < field_value.to_i)
      when '>'
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i > field_value.to_i)
      when '=~'
        r = Regexp.new(field_value)
        r =~ cur_val
      when '!~','~!'
        r = Regexp.new(field_value)
        r !~ cur_val
      when 'includes'
        !field_value.split(/,/).find{|val| cur_val.include?(val) if cur_val}.nil?
      when '!includes'
        field_value.split(/,/).find{|val| cur_val.include?(val) if cur_val}.nil?
      when 'answered'
        cur_val && cur_val != nil && cur_val != ''
      when '!answered'
        cur_val.nil? || cur_val == ''
      end
    end
  end
  
  def uses_fields(field_list)
    if javascript
      uses = false
      javascript.gsub(/:(\w+)/) {|v| uses = true if field_list.include?($1)}
      uses
    else
      field_list.include?(field_name)
    end
  end
  
  def fields_used
    f = []
    if javascript
      javascript.gsub(/:(\w+)/) {|v| f << $1}
    else
      f << field_name
    end
    f.uniq
  end
    
  def generate_javascript_function(field_widget_map)
    if javascript
      js = javascript
    else
      multi = false
      
      #TODO-Eric this fails if the hidden value is multi.
      if field_widget_map.has_key?(field_name)
        (widget,widget_options) = field_widget_map[field_name]
        multi = widget.is_multi_value?
      end
      the_field_value = field_value  #Ruby gets confused below and interprets field_value as
      # a local variable.  This is necessary to use bin#[]=
      js = case operator
        when '=','=='
          %Q|:#{field_name} == "#{the_field_value}"|
        when '!=','=!'
          %Q|:#{field_name} != "#{the_field_value}"|
        when '<'
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} < #{the_field_value.to_i})|
        when '>'
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} > #{the_field_value.to_i})|
        when '=~'
          if the_field_value =~ /^\/(.*)\/$/
            the_field_value = $1
          end
          multi ? %Q|arrayMatch(:#{field_name},'#{the_field_value}')| :
          %Q|:#{field_name}.match('#{the_field_value}')|
        when '!~','~!'  
          if the_field_value =~ /^\/(.*)\/$/
            the_field_value = $1
          end
          multi ? %Q|!arrayMatch(:#{field_name},'#{the_field_value}')| :
          %Q|!:#{field_name}.match('#{the_field_value}')|
        when 'includes'
          %Q|"#{the_field_value}" in oc(:#{field_name})|
        when '!includes'
          %Q|"!(#{the_field_value}" in oc(:#{field_name}))|
        when 'answered'
          %Q|:#{field_name} != null && :#{field_name} != ""|
        when '!answered'
          %Q*:#{field_name} == null || :#{field_name} == ""*
      end
    end
    hiddens = []
    variable_declarations = []
    js = js.gsub(/:(\w+)/) do |m|
      f = $1
      if field_widget_map.has_key?(f)
        (widget,widget_options) = field_widget_map[f]
        variable_declarations << "function value_#{f}() {return #{widget.javascript_get_value_function(f)}}"
      else
        hiddens << f
        variable_declarations << "function value_#{f}() {return $F('___#{f}')}"
      end
      "value_#{f}()"
    end
    ["#{variable_declarations.join(';')};function #{js_function_name}() {return #{js}}",hiddens]
  end
#  def generate_show_hide_js_options(value_is_array)
#    if value == :answered
#      opts[:condition] = %Q|field_value != null && field_value != ""|
#    elsif value =~ /^\/(.*)\/$/
#      if the_q.get_widget.is_multi_value?
#        opts[:condition] = %Q|arrayMatch(field_value,#{value})|
#      else
#        opts[:condition] = %Q|field_value.match(#{value})|
#      end 
#    else
#      if value =~ /^\!(.*)/
#        opts[:value] = $1
#        opts[:operator] = the_q.get_widget.is_multi_value? ? :not_in : '!='
#      else
#        opts[:value] = value
#        opts[:operator] = the_q.get_widget.is_multi_value? ? :in : '=='
#      end
#    end
#  end
end

class ConstraintCondition
  attr_accessor :condition, :constraint_value
  def initialize(cond,cv)
    @condition = cond
    @constraint_value = cv
    self
  end
end

class Workflow < Bin
  def bins 
    { :actions => nil, :order => nil, :states => nil}
  end
  def initialize(bins)
    s = {}
    o = []
    st = bins[:states]
    while st.size > 0
      state = st.shift
      value = st.shift
      raise "States array not complete." if value.nil?
      s[state] = value
      o.push state
    end
    bins[:states] = s
    bins[:order] = o
    super bins
  end
  def make_states_enumeration
    order.collect do |name|
      value = states[name]
      label = value[:label] if value.instance_of?(Hash)
      label ||= value
      ["#{name}: #{label}",name]
    end
  end
  def should_validate?(state)
    v = states[state]
    v.instance_of?(Hash) ? v[:validate] : false
  end
  def label(state)
    v = states[state]
    v.instance_of?(Hash) ? v[:label] : v
  end
end

class Presentation < Bin
  include Utilities

  def bins 
    { :name => nil, :block => nil, :legal_states => nil, :create_with_workflow => nil, :initialized => false, :question_names => {}, :force_read_only => false, :validation => nil, :invalid_fields => nil}
  end

  def required_bins
    [:name , :block]
  end

  def fields
    question_names.keys
  end

  def is_legal_state?(state)
    ls = legal_states.call if legal_states.is_a?(Proc)
    ls ||= legal_states
    ls == :any || arrayify(ls).include?(state)
  end

  def confirm_legal_state!(state)
    if !is_legal_state?(state)
      raise MetaformIllegalStateForPresentationError.new(state,name)
    end
  end
end

class Question < Bin
  def bins
    {
      :field => nil,
      :appearance => nil, #TODO remove me!
      :widget => nil,
      :params => nil
    }
  end
  def required_bins
    [:field, :widget]
  end
  
  def get_widget
    Widget.fetch(widget)
  end
  
  def render(form,value = nil,force_read_only = nil)
    require 'erb'
    
    w = get_widget
    widget_options = {:constraints => field.constraints, :params => params}
    
    ro = force_read_only || read_only
    widget_options[:read_only] = ro if !ro.nil?

    field_label = field.label
    field_name = field.name
    field_label = field_name.humanize if field_label.nil?
    postfix = labeling[:postfix] if labeling && labeling.has_key?(:postfix)
    postfix ||= form.label_options[:postfix] if form.label_options.has_key?(:postfix)
    if postfix && !(field_label =~ /[.:;\?\!]$/)
      field_label = field_label + postfix
    end

    field_id = field_name
    if form.use_multi_index? && idx = form.index
      field_id = "_#{idx}_#{field_name}"
    end
    if erb
      field_element = ro ?
        w.render_form_object_read_only(field_id,value,widget_options) :
        w.render_form_object(field_id,value,widget_options)
      hiding_js = form.hiding_js?
    end
    field_html = w.render(field_id,value,field_label,widget_options)
    
    css_class_html = %Q| class="#{css_class}"| if css_class
    
    properties = field.properties
    if properties
      properties.each do |p|
        property_value = p.evaluate(form,field,value)
        field_html=p.render(field_html,property_value,self,form)
      end
    end
  
    if erb
      field_html = ERB.new(erb).result(binding)
    else
      field_html =  %Q|<div id="question_#{field.name}"#{css_class_html}#{initially_hidden ? ' style="display:none"' : ""}>#{field_html}</div>|
    end
        
    field_html
  end
end