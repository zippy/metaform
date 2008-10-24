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
      :force_nil => nil,
      :dependent_fields => nil
    }
  end
  def required_bins
    [:name,:type]
  end

  def add_force_nil_case(condition,fields,negate = nil)
    self.force_nil ||= []
    self.force_nil << [condition,fields,negate]
  end

  def set_dependent_fields(field_list)
    self.dependent_fields ||= []
    self.dependent_fields = self.dependent_fields.concat(field_list).uniq
  end
end

class Condition < Bin
  OperatorMatch = /([a-zA-Z_\[\]0-9]*)\s*((<>=)|(>=)|(<=)|(<>)|(<)|(>)|(!=)|(=!)|(=~)|(!~)|(~!)|(=+)|(includes)|(!includes)|(answered)|(!answered))\s*(.*)/
  def bins 
    { :form => nil,:name => nil, :description => nil, :ruby => nil,:javascript => nil,:operator =>nil,:field_value =>nil,:field_name =>nil,:fields_to_use => nil,:index => -1}
  end
  def required_bins
    [:form,:name]
  end
  
  def initialize(b={})
    super(b)
    if name =~ OperatorMatch
      self.field_name = $1
      self.operator = $2
      self.field_value = $19
      if self.field_name =~ /(.*)\[([0-9]+)\]/
        self.field_name = $1
        self.index = $2
      end
    else
      raise MetaformException, "javascript not defined or definable for condition '#{name}'" if javascript.nil?
    end
  end
   
  def humanize(use_label = true)
    return description if description
    form_field = form.fields[self.field_name]
    hfn = form_field.label if form_field && use_label
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
    when '<='
      "#{hfn} is less than or equal to #{field_value}"
    when '>='
      "#{hfn} is greater than or equal to #{field_value}"
    when '<>'
      "#{hfn} is between #{!field_value.nil? ? field_value.gsub(',',' and ') : ''}"
    when '<>='
      "#{hfn} is between or equal to #{!field_value.nil? ? field_value.gsub(',',' and ') : ''}"
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
    js = humanize(false)
    js = js.gsub(/[- ]/,'_')
    js = js.gsub(/\W/,'')
  end
  
  def evaluate(idx = -1)
    raise MetaformException,"attempting to evaluate condition with no record" if form.get_record.nil?
    if ruby
      ruby.call(idx)
    else
      idx = self.index.to_i if self.index != -1
      cur_val = form.field_value(field_name,idx)
      case operator
      when '=','=='
       cur_val == field_value
      when '!=','=!'
        cur_val != field_value
      when '<'
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i < field_value.to_i)
      when '>'
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i > field_value.to_i)
      when '<='
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i <= field_value.to_i)
      when '>='
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i >= field_value.to_i)
      when '<>'
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i > field_value.split(',')[0].to_i) && (cur_val.to_i < field_value.split(',')[1].to_i)
      when '<>='
        !cur_val.nil? && (cur_val != '') && (cur_val.to_i >= field_value.split(',')[0].to_i) && (cur_val.to_i <= field_value.split(',')[1].to_i)
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
    if fields_to_use then
      fields_to_use
    else
      f = []
      if javascript
        javascript.gsub(/:(\w+)/) {|v| f << $1}
      else
        f << field_name
      end
      f.uniq
    end
  end
    
  def generate_javascript_function(field_widget_map)
    if javascript
      cur_idx = ''
      js = javascript
    else     
      cur_idx = '[cur_idx]' 
      #Note that if the condition does not have the javascript pre-defined, then we assume that the condition
      #only cares about the information on the tab it is being run on.
      if field_widget_map.has_key?(field_name)
        (widget,widget_options) = field_widget_map[field_name]
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
        when '<='
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} <= #{the_field_value.to_i})|
        when '>='
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} >= #{the_field_value.to_i})|
        when '<>'
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} > #{the_field_value.split(',')[0].to_i}) && (:#{field_name} < #{the_field_value.split(',')[1].to_i})|
        when '<>='
          %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} >= #{the_field_value.split(',')[0].to_i}) && (:#{field_name} <= #{the_field_value.split(',')[1].to_i})|
        when '=~'
          if the_field_value =~ /^\/(.*)\/$/
            the_field_value = $1
          end
          %Q|valueMatch(:#{field_name},'#{the_field_value}')|     
        when '!~','~!'  
          if the_field_value =~ /^\/(.*)\/$/
            the_field_value = $1
          end
          %Q|valueMatch(:#{field_name},'#{the_field_value}')|       
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
    variable_declarations = []
    js = js.gsub(/:(\w+)/) do |m|
      f = $1
      variable_declarations << "function value_#{f}() {return values_for_#{f}}"
      "value_#{f}()#{cur_idx}"
    end
    "#{variable_declarations.join(';')};function #{js_function_name}() {return #{js}}"
  end
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
    bins[:states].each do |workflow_pair|
      label = workflow_pair.keys[0]
      o.push label
      s[label] = workflow_pair[label]
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
    { :name => nil, :block => nil, :legal_states => nil, :create_with_workflow => nil, :initialized => false, :force_read_only => false, :validation => nil, :invalid_fields => nil}
  end

  def required_bins
    [:name , :block]
  end

#  def fields
#    question_names.keys
#  end

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
    
    if widget.is_a?(String)
      w = get_widget 
    else
      w = Widget
      value = widget.call(value)
      #puts "value = #{value}"
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
        property_value = p.evaluate(form,field,value,-1)
        if erb
          field_element = p.render(field_element,property_value,self,form,ro)
        end
        field_html=p.render(field_html,property_value,self,form,ro)
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

class Tabs < Bin
  def bins
    {
      :name => nil,
      :render_proc => nil,
      :block => nil
    }
  end

  def required_bins
    [:name,:block]
  end
  
  def render_tab(presentation_name,label,url,is_current,index=nil)
    css_class = "tab_#{presentation_name}"
    extra = render_proc.call(presentation_name,index) if render_proc
    css_class = "current #{css_class}" if is_current
    %Q|<li class="#{css_class}"> <a href="#" onClick="return submitAndRedirect('#{url}')" title="Click here to go to #{label}"><span>#{label}#{extra}</span></a></li>|
  end
end
