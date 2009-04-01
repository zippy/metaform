class Field < Bin
  def bins
    {
      :name => nil,
      :label => nil,
      :type => 'string',
      :constraints => nil,
      :followups => nil,
      :followup_conditions => nil,
      :default => nil,
      :indexed_default_from_null_index => nil,
      :calculated => nil,
      :properties => [Invalid],
      :calculated => nil,
      :default => nil,
      :groups => nil,
      :force_nil => nil,
      :dependent_fields => nil,
      :indexed => false
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
  Expression = Struct.new("Expression",:field_name,:field_value,:operator,:index)
  OperatorMatch = /([a-zA-Z_\[\]0-9\*]*)\s*((<>=)|(>=)|(<=)|(<>)|(<)|(>)|(!=)|(=!)|(=~)|(!~)|(~!)|(=+)|(includes)|(!includes)|(answered)|(!answered))\s*(.*)/
  def bins
    { :form => nil,:name => nil, :description => nil, :ruby => nil,:javascript => nil,:booleanjoins=>nil,:expressions=>nil,:fields_to_use => nil}
  end
  def required_bins
    [:form,:name]
  end

  def initialize(b={})
    super(b)
    if javascript.nil? && ruby.nil?
      parse_expressions(name) 
      if expressions.empty?
        raise MetaformException, "javascript not defined or definable for condition '#{name}'" if javascript.nil?
      end
    end
  end

  def parse_expressions(str)
    self.expressions = []
    expr = []
    x = []
    str.split(/\s+/).each do |t|
      if t == 'or' || t == 'and'
        self.booleanjoins ||= []
        booleanjoins << t
        expr << x.join(' ')
        x=[]
      else
        x << t
      end
    end
    expr << x.join(' ') if !x.empty?
    expr.each do |e|
      if e =~ OperatorMatch
        exp = Expression.new
        exp.field_name = $1
        exp.operator = $2
        exp.field_value = $19
        #puts "exp.field_name = #{exp.field_name}"
        if exp.field_name =~ /(.*)\[([0-9]+)\]/ 
          exp.field_name = $1
          exp.index = $2.to_i
        elsif exp.field_name =~ /(.*)\[(\*)\]/ 
          exp.field_name = $1
          exp.index = $2
        end
         #puts "   exp.field_name = #{exp.field_name}"
         #puts "   exp.index = #{exp.index}"
         #puts "   exp.field_value = #{exp.field_value}"
        self.expressions << exp
      end
    end
  end

  def humanize(use_label = true)
    return description if description
    return name if javascript || ruby
    result = ""
    expressions.each_with_index do |e,indx|
      result << humanize_expression(e,use_label)
      result << ' '+self.booleanjoins[indx]+' ' if booleanjoins && booleanjoins[indx]
    end
    result
  end

  def humanize_expression(expr,use_label)
    field_name = expr.field_name
    form_field = form.fields[field_name]
    hfn = form_field.label if form_field && use_label
    hfn ||= field_name
    field_value = expr.field_value
    case expr.operator
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

  def evaluate
    raise MetaformException,"attempting to evaluate condition with no record" if form.get_record.nil?
    if ruby
      ruby.call
    else
      result = false
      expressions.each_with_index do |e,indx|
        result = evaluate_expression(e)
        if booleanjoins && booleanjoins[indx]
          if booleanjoins[indx] == 'or'
            break if result
          elsif booleanjoins[indx] == 'and'
            break if !result
          end
        end
      end
      result
    end
  end

  def evaluate_expression(expr)
    field_name = expr.field_name
    field_value = expr.field_value
    cur_val = expr.index ? form.field_value_at(field_name,expr.index) : form.field_value(field_name)
    # puts "field_name = #{field_name}"
    # puts "   field_value = #{field_value}"
    # puts "   expr.index = #{expr.index}"
    # puts "   cur_val = #{cur_val}"
    case expr.operator
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

  def uses_fields(field_list)
    uses = false
    if javascript
      javascript.gsub(/:(\w+)/) {|v| uses = true if field_list.include?($1)}
    else
      expressions.each {|e| uses = true if field_list.include?(e.field_name)}
    end
    uses
  end

  def fields_used
    if fields_to_use then
      fields_to_use
    else
      f = []
      if javascript
        javascript.gsub(/:(\w+)/) {|v| f << $1 if $1 != 'any'}
      else
        expressions.each {|e| f << e.field_name}
      end
      # puts "name = #{name}"
      # puts "   f = #{f.inspect}"
      f.uniq
    end
  end
  
  def make_javascript_index_string(fn,idx)
    if idx.blank?
      field = form.fields[fn]
      # puts "fn = #{fn.inspect}"
      # puts "   field = #{field.inspect}"
      field.indexed ? '[cur_idx]' : '[0]'          
    else
      (idx == '*') ? '' : "[#{idx}]"
    end
  end

  def generate_javascript_function(field_widget_map)
    if javascript
      js = javascript
      js = js.gsub(/:(\w+)(\[((\*)|([\d]*))\])*/) do |m|
        f = $1
        idx_string = make_javascript_index_string(f,$3)
        "values_for_#{f}#{idx_string}"
      end
    else
      js = ""
      jsmap = {'or'=>'||','and'=>'&&'}
      expressions.each_with_index do |e,indx|
        js << generate_javascript_expression(e,field_widget_map)
        js << ' '+jsmap[self.booleanjoins[indx]]+' ' if booleanjoins && booleanjoins[indx]
      end
      js
    end
    "function #{js_function_name}() {return #{js}}"
  end
  
  def generate_javascript_expression(expr,field_widget_map)
    field_value = expr.field_value
    field_name = expr.field_name
    # puts "field_name = #{field_name}"
    # puts "field_value = #{field_value}"
    idx_string = make_javascript_index_string(field_name,expr.index)
    if field_widget_map.has_key?(field_name)
      (widget,widget_options) = field_widget_map[field_name]
    end
    js = case expr.operator
      when '=','=='
        %Q|:#{field_name} == "#{field_value}"|
      when '!=','=!'
        %Q|:#{field_name} != "#{field_value}"|
      when '<'
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} < #{field_value.to_i})|
      when '>'
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} > #{field_value.to_i})|
      when '<='
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} <= #{field_value.to_i})|
      when '>='
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} >= #{field_value.to_i})|
      when '<>'
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} > #{field_value.split(',')[0].to_i}) && (:#{field_name} < #{field_value.split(',')[1].to_i})|
      when '<>='
        %Q|(:#{field_name} != null) && (:#{field_name} != '') && (:#{field_name} >= #{field_value.split(',')[0].to_i}) && (:#{field_name} <= #{field_value.split(',')[1].to_i})|
      when '=~'
        if field_value =~ /^\/(.*)\/$/
          field_value = $1
        end
        %Q|regexMatch(:#{field_name},'#{field_value}')|
      when '!~','~!'
        if field_value =~ /^\/(.*)\/$/
          field_value = $1
        end
        %Q|!regexMatch(:#{field_name},'#{field_value}')|
      when 'includes'
        %Q|includes(:#{field_name},"#{field_value}")|
      when '!includes'
        %Q|!includes(:#{field_name},"#{field_value}")|
      when 'answered'
        %Q|:#{field_name} != null && :#{field_name} != ""|
      when '!answered'
        %Q*:#{field_name} == null || :#{field_name} == ""*
    end
    js = js.gsub(/:(\w+)/) do |m|
      f = $1
      "values_for_#{f}#{idx_string}"
    end
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

    if widget.is_a?(Proc)
      w = Widget
      value = widget.call(value)
    else
      w = get_widget
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
      properties.each_with_index do |p,i|
        next if i == 0 && !form.validating?
        property_value = p.evaluate(form,field,value)
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
