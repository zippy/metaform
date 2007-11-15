
################################################################################
################################################################################
# Form is a base class which allows the creation of Form and Workflows using
# a domain specific language.  (The implementation of the storage and mapping the
# language into a working system is done in record.rb, records_controller.rb, 
# field_instance.rb & form_instance.rb)

#TODO organize the function definitions below so that reading the code, and also 
# an rdoc pass will naturally show what statements in the language are declarations
# which are run-time helper function, which are the user hooks (build, verify, setup), etc

require 'yaml'

module Utilites
  ###########################################################
  # used for parameters that can optionally be an array.
  # converts non-array params to a single element array
  def arrayify(param)
    return [] if param == nil
    param = [param]  if param.class != Array
    param
  end

  def array_for_sql(a)
    a.collect{|f| "'#{f}'"}.join(',')
  end
  
  def sql_workflow_condition(workflows,add_and=false)
    result = ''
    if workflows
      result << " and " if add_and
      result << %Q|workflow_state in (#{array_for_sql(arrayify(workflows))})|
    end
    result
  end
  
  def sql_field_conditions(conditions,add_and=false)
    result = ''
    if conditions
      result << " and " if add_and
      conditions = arrayify(conditions)
      result << conditions.collect do |c|
        c =~ /:([a-zA-Z0-9_-]+)/
        field_name = $1
        c = c.gsub(/:#{field_name}/,'answer')
        %Q|if(field_id='#{field_name}',if(#{c},true,false),true)|
      end.join(' and ')
    end
    result
  end
end

class Reports
  class << self
    include Utilites
    
    def reports
      @reports ||= {}
      @reports
    end

    #################################################################################
    def def_report(report_name, opts, &block)
      options = {
        :workflow_state_filter => nil,
        :fields => nil,
        :forms => nil,
        :filters => nil,
        :sum_queries => {},
        :count_queries => {}
      }.update(opts)
      self.reports[report_name] = Struct.new(:block,*options.keys)[block,*options.values]
    end

    #################################################################################
    def get_report(report_name,options = {})

      r = self.reports[report_name]
      raise "unknown report #{report_name}" if !r 
      results = {}

      # build up the lists of fields we need to get from the database by looking in 
      # count queries, the sum querries and the fiters
      field_list = {}
      r.fields.each {|f| field_list[f]=1}
      r.count_queries.each { |stat,q| q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} if q.is_a?(String)}
      r.sum_queries.each { |stat,q| q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} if q.is_a?(String)}
      filters = arrayify(r.filters)
      if options[:filters]
        filters = filters.concat(arrayify(options[:filters]))
        filters.each { |fltr| fltr.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1}}
      end

      w = sql_workflow_condition(r.workflow_state_filter,true)
      
#      sql_conditions = sql_field_conditions(r.sql_conditions,true)
#      sql_conditions << sql_field_conditions(options[:sql_conditions],true)

      form_instances = FormInstance.find(:all, 
        :conditions => ["form_id in (?) and field_id in (?)" << w ,r.forms,field_list.keys], 
        :include => [:field_instances]
        )
        
      forms = {}
      
      #TODO This has got to be way inneficient!  It would be much better to push this
      # off the SQL server, but I don't know how to do that yet in the context of rails
      # and the structure of having the field instances in their own tables.
      form_instances.each do |i|
        f = {}
        i.field_instances.each {|fld| f[fld.field_id]=fld.answer}
        filtered = false
        if filters.size > 0
          eval_field(filters.collect{|x| "(#{x})"}.join('&&')) {|expr| filtered = !eval(expr)}
        end
        forms[i.id]=f if !filtered
      end
      total = forms.size
      
      r.sum_queries.each do |stat,q|
        t = 0
        forms.values.each {|f| eval_field(q) { |expr| t = t + eval(expr).to_i }}
        results[stat] = t
      end
      
      r.count_queries.each do |stat,q|
        t = 0
        forms.values.each {|f| eval_field(q) { |expr| t = t + 1 if eval(expr) }}
        results[stat] = t
      end
      results[:total] = total
      r.block.call(results,forms)
    end
 
    def eval_field(expression)
      begin
        expr = expression.gsub(/:([a-zA-Z0-9_-]+)/,'f["\1"]')
        yield expr
      rescue Exception => e
        raise "Eval error '#{e.to_s}' while evaluating: #{expr}"
      end
    end

  end
end

class Listings
  class << self
    include Utilites

    def listings
      @listings ||= {}
      @listings
    end

    #################################################################################
    # expected options are :workflow_state_filter,:fields,:conditions,:forms
    def listing(listing_name, opts, &block)
      options = {
        :workflow_state_filter => nil,
        :fields => nil,
        :conditions => nil,
        :forms => nil 
      }.update(opts)
      self.listings[listing_name] = Struct.new(:block,*options.keys)[block,*options.values]
    end

    #################################################################################
    #TODO-LISA this is both inefficient, and also tied into the FormInstance/FieldInstance impelementation
    # of the data storage model.  
    # The ideas is that Form should be based on the idea is that the data-storage model should be abstracted out
    # out of Form and implemented someplace else.
    # i.e. we should refactor this into field_values(field_list) that gets the values of all the fields instead of
    # calling FieldInstance.find here
    def get_list(list_name,options = {})
      forms = []
      l = self.listings[list_name]
      raise "unknown list #{list_name}" if !l      
      
      options[:order] ||= l.fields[0]
      
      locate_options = {}
      locate_options[:forms] = l.forms if l.forms
      locate_options[:fields] = l.fields if l.fields
      locate_options[:conditions] = l.conditions if l.conditions
      locate_options[:workflow_state_filter] = l.workflow_state_filter if l.workflow_state_filter
      locate_options[:filters] = options[:filters] if options[:filters]
      
      forms = Record.locate(:all,locate_options)

      # TODO-LISA
      # implement 1) sub-sorting, and 2) sorting by type, i.e. this sorting only does
      # alphabetical.  We should be converting dates to dates and sorting by that
      # numbers to numbers, etc.  Actually, perhaps that should be solved by
      # the loading of the field instances answer value and then the <=> should just work right.
      order_field = options[:order]
      forms.sort {|x,y| x.send(order_field) ? (x.send(order_field) <=> y.send(order_field)) : 0 }
    end
  end
end

class Form
  cattr_accessor :forms_dir
  @@forms_dir = 'forms'
  
  FieldTypes = ['string','integer','float','decimal','boolean','date','datetime','time','text']
  
  class << self
    include Utilites
    
    #TODO boy does this look like it could be refactored doesn't it!!!  It should all be generalized
    # into the meta-langage/abstraction for generating DSLs
    attr_accessor :stuff, :fields, :questions, :presentations, :workflows, :listings, :tabs

    def stuff
      @stuff ||= {}
      @stuff
    end
    def fields
      @fields ||= {}
      @fields
    end
    def questions
      @questions ||= {}
      @questions
    end
    def presentations
      @presentations ||= {}
      @presentations
    end
    def workflows
      @workflows ||= {}
      @workflows
    end
    def tabs
      @tabs ||= {}
      @tabs
    end
  end

### TODO ok this sucks I can't use these "class globals"  They are screwing things up.  Time to 
# change all this definitions stuff over to modules or something different. and make these variables be
# class instance variables.

#  @@phase = :setup
  @@contexts = []
  @@attributes = nil
  @@action_result = nil

  #TODO  BOGUS!!!!! this shouldn't exist and will cause concurrency problems
  def self.reset_attributes
    @@attributes = nil
  end


  ################################################################################
  def self.inherited (klass)
    instance_eval { (@forms ||= {}).store(klass.to_s.sub(/^Form/, ''), klass) }
  end
  ################################################################################
  def self.find (name)
    forms = instance_eval {@forms}
    name = name.to_s
    raise "Unknown form #{name}" unless forms.has_key?(name)
    forms[name]
  end
  ################################################################################
  def self.list
    instance_eval {
      @forms.keys
    }
  end

  ################################################################################
  class << self
    
    def default_create_presentation(p)
      self.stuff[:default_create_presentation] = p
    end

    def get_stuff(stuff)
      self.stuff[stuff]
    end
        
    #################################################################################
    #################################################################################
    # here we are defining the metaform DSL
    
    # define a groupd of fields all to have a constraint (typically "required")
    # TODO-LISA make this work so that you can nest def_fields.  Also, make sure that
    # nested constraints properlly override constraints from the nesting group, etc.
    def def_fields(constraints = nil)
      @@constraints = constraints
      yield
      @@constraints = nil
    end
    
    #################################################################################
    # setup functions for DSL
    
    # define a field with optional constraint
    # constraint should be a hash of constrainttype, constraintvalue pairs, or a YAML encoded hash.
    def f(field_name,label = "", field_type = "string",constraints=nil)
      field_name = field_name.to_s
 #TODO handle user defined types:
# boolean_TxCCTf
# boolean_CCTfTpTf
# boolean_TxCCTpTf     
#      raise "unknown field type #{field_type}" if !FieldTypes.include?(field_type)
      
      field = Struct.new(:name, :label, :type, :constraints,:followups,:followup_name_map)
      c = @@constraints
      c ||= {}
      if constraints
        constraints = YAML.load(constraints) if constraints.class == String
        c = c.merge(constraints)
      else
        c = c.clone
      end
#TODO reinstate this line once we fix the dups created in V1Form
#      raise "#{field_name} allready defined" if self.fields.has_key?(field_name)
      self.fields[field_name] = field[field_name,label,field_type,c,nil,nil]
    end
    
    #################################################################################
    #TODO-LISA test that fwf works with nested fwf fields.
    # define a field with followup fields
    def fwf(field_name,label = "", field_type = "string",constraints=nil,followups = {})
      the_field = f field_name,label,field_type,constraints
      the_field.followups = followups
      map = {}
      followups.each do |field_answer,followup_fields|
        fields = arrayify(followup_fields)
        fields.each do |field|
          map[field.name] = field_answer
          field.constraints ||= {}
          #TODO-LISA this constraints needs to distinguish between enumerations and sets it currently
          # is assuming that the contraints is just and enumeration.
          field.constraints['required'] = "#{field_name}=#{field_answer}"
        end 
      end
      the_field.followup_name_map = map
    end
    
    #################################################################################
    def presentation(presentation_name,opts={}, &block)
      options = {
        :legal_states => :any
      }.update(opts)
      pres = Struct.new(:block,:options,:initialized)
      legal_viewing_states = [legal_viewing_states]  if legal_viewing_states != :any && legal_viewing_states.class != Array
      self.presentations[presentation_name] = pres[block,options,false]
    end
    
    #################################################################################
    def question(field_name,appearance_type,appearance_parameters=nil)
      field_name = field_name.to_s
      qs = self.questions
      if qs[field_name]
        current_question = qs[field_name]
      else
        question = Struct.new(:appearance,:params)
        current_question = question[appearance_type,appearance_parameters]
        qs[field_name] = current_question        
      end
    end
        

    #################################################################################
    #################################################################################
    # DSL methods for workspaces and actions
    def def_workflows()
      yield
    end
    
    # build up a hash table of actions for the workflow
    # TODO This will fail if we nest workspaces.  We have to save the context instead of 
    # just saving the current action hash in a class variable.
    def workflow(workflow_name)
      @@actions = {}
      yield
      self.workflows[workflow_name] = Struct.new(:actions)[@@actions]
    end
    
    # an action consist of a block to execute when running the action as well as a list of
    # states that the form must be in for the action to execute.
    def action(action_name,states_for_action,&block)
      # convert to array if we were called with a single state
      states_for_action = arrayify(states_for_action)
      @@actions[action_name] = Struct.new(:block,:legal_states)[block,states_for_action]
    end

    # TODO this implies that somehow this should all be abastracted so that that method can only be called in
    # the context of defining a workflow.  All this requires some interesting refactoring into a meta-language
    # for defining DSLs like this one.
    def state(s)
      @@action_result[:next_state] = s
    end

    def redirect_url(url)
      @@action_result[:redirect_url] = url
    end
    
    #################################################################################
    # DSL methods for tabs
    # build up a hash table of actions for the workflow
    # TODO This will fail if we nest workspaces.  We have to save the context instead of 
    # just saving the current action hash in a class variable.
    def def_tabs(tabs_name,&block)
      self.tabs[tabs_name] = block
    end
        
    #################################################################################
    # DSL rendering functions
    
    ###############################################
    # produces a "text" element.  Defaults to a <p></p> html element with no class
    def t(text,css_class = nil,element = 'p')
      css_class = %Q| class = "#{css_class}"| if css_class
      text = %Q|<#{element}#{css_class}>#{text}</#{element}>| if element
      body text
    end
    
    def html(text)
      body text
    end
    
    def q_meta_workflow_state(label,appearance_type,states)
      widget = Widget.fetch(appearance_type)
      w = widget.render(@@form,'workflow_state',workflow_state,label,:constraints => {"enumeration"=>states}) #TODO , :params => appearance_parameters
      #TODO this is a cheat and we need to fix it in widget to generalize it, but it works ok!
      w = w.gsub(/record(.)workflow_state/,'meta\1workflow_state')
      html w
      @@meta[:workflow_state] = 1
    end
    
    
    ###############################################
    # produces a question, with a optional followup questions (field had to be defined with fwf)
    # options: 
    # :erb => specify an erb block to render how the question should be displayed.  The default rendering is
    # the equivalent of this:
    #    <div id="question_<%=field_name%>"<%=css_class%><%=initially_hidden ? ' style="display:none"' : ""%>><%=field_html%></div>
    #  though it is done as a straight interpolated string for speed.
    #  additionally the variables available for inserting into the erb block are:
    #     field_name, field_label, field_element, and field_html which is the label and element joined 
    #     rendered together by the widget.
    
    def q(field_name,appearance = "TextField",css_class = nil,followup_appearances = nil,opts = {})
      require 'erb'
      options = {
        :initially_hidden => false,
      }.update(opts)

      initially_hidden = options[:initially_hidden]
      appearance_type,appearance_parameters = parse_appearance(appearance)
      question(field_name,appearance_type,appearance_parameters)
      
      return if !(@@phase == :build || @@phase == :verify)
      value = field_value(field_name)
      the_field = self.fields[field_name]
      constraints = the_field.constraints
      constraint_errors = Constraints.verify(constraints, value, self)
      if !constraint_errors.empty?
        @@constraint_errors ||= {}
        @@constraint_errors[field_name] = constraint_errors
      end
      return if @@phase == :verify
      
      widget = Widget.fetch(appearance_type)
      if options[:erb]
        field_element = widget.render_form_object(@@form,field_name,value,:constraints => constraints, :params => appearance_parameters)
        field_label = the_field.label
      end
      field_html = widget.render(@@form,field_name,value,the_field.label,:constraints => constraints, :params => appearance_parameters)

      #TODO, this produces an ugly list of errors right now.  Control over this should be
      # made much higher, i.e. some errors shouldn't show up depending on which other errors
      # have been detected (i.e. if required, then don't bother to show an enum error)
      if !constraint_errors.empty?
        errs = constraint_errors.join("; ")
        field_html  << %Q|<span class="errors">#{errs}</span>|
      end
      css_class ||= 'question'
      css_class = %Q| class="#{css_class}"|
      if options[:erb]
        body ERB.new(options[:erb]).result(binding)
      else
        body %Q|<div id="question_#{field_name}"#{css_class}#{initially_hidden ? ' style="display:none"' : ""}>#{field_html}</div>|
      end
      
      #TODO-LISA find some way that the "followup" css spec can be passed in as part of the followup
      # appearance specification, and also to pass in a css_class specification for the followup question
      # itself
      if followup_appearances 
        raise "no followups defined for #{field_name}" if !the_field.followups
        map = self.fields[field_name].followup_name_map
        followup_appearances.each do |app|
          case 
          when app.is_a?(String)
            followup_field_name = app; followup_field_appearance = 'TextField'
          when app.is_a?(Hash)
            followup_field_name = app.keys[0]; followup_field_appearance =  app.values[0]
          when app.is_a?(Array)
            followup_field_name = app[0]; followup_field_appearance =  app[1]
          else
            raise "followp spec must be String, Hash or Array, got #{app.class} #{app.inspect}"
          end
          followup_appearance_type,followup_appearance_parameters = parse_appearance(followup_field_appearance)
          question(followup_field_name,followup_appearance_type,followup_appearance_parameters)  #declare the question to make sure it exists   
          value = map[followup_field_name]
          opts = {:css_class => 'followup'}
          if value == :answered
            opts[:condition] = %Q|field_value != null && field_value != ""|
          elsif value =~ /^\/(.*)\/$/
            #TODO-LISA make this work if the field value is an array (which it would be for a set instead of an enum)
            opts[:condition] = %Q|field_value.match(#{value})|
          else
            opts[:value] = value
            opts[:operator] = widget.is_multi_value? ? :in : '=='
          end
          javascript_show_hide_if(field_name,opts) do
            q followup_field_name,followup_field_appearance,'question_followup'
          end
        end
      end
    end
    
    ###############################################
    # Question with followup and an action taken.
    # TODO this should probably be in V2Form, it's not general enough to be a metaform method
    def qfa(field_name,followup_field_name,options=nil,appearance ="PopUp",css_class = nil,followup_appearance="CheckBoxGroup",action_appearance="CheckBoxGroup")
      q field_name, appearance, css_class
      javascript_show_if(field_name,'==',"Y",nil,"followup") do
        followup_spec = []
        options = get_field_enumeration_values(followup_field_name) if options == nil
        options.each do |o|
          afn = "#{field_name}_#{o}_Action"
          f afn,"#{o} action taken", 'string', <<-YAML
enumeration:
- transport: "Transported"
- nothing: "Did Nothing"
- something: "Did Something"
YAML
        followup_spec << (o << "=#{afn}")
        end
        qf followup_field_name,followup_spec.join(','),followup_appearance,nil,action_appearance
      end
    end
    

    ###############################################
    # Question with sub-presentation.  Use this to declare a question which if the value
    # of the question is "value" (defaults to "N") then display a sub-presentation
    def qp(field_name,appearance = "TextField",opts = {})
      options = {
        :operator => '==',
        :value => 'N',
        :question_css_class => nil,
        :show_hide_css_class => nil,
        :condition => nil,
        :show => false
      }.update(opts)
      q field_name, appearance, options[:question_css_class]
      options.delete(:question_css_class)
      options[:css_class] = options[:show_hide_css_class] if options[:show_hide_css_class]
      options.delete(:show_hide_css_class)
      javascript_show_hide_if(field_name,options) do
        p field_name
      end      
    end

    ###############################################
    # Presentation
    def p(presentation_name)
      pres = self.presentations[presentation_name]
      raise "presentation #{presentation_name} doesn't exist" if !pres
      if @@phase == :setup
        return if pres.initialized
      end
      if @@phase == :build
        legal_states = pres.options[:legal_states]
        if legal_states != :any && !arrayify(legal_states).include?(workflow_state)
          raise "presentation #{presentation_name} is not allowed when form is in state #{workflow_state}"
        end
      end
      pres.initialized = true
      body %Q|<div id="presentation_#{presentation_name}" class="presentation">|      
      pres.block.call
      body "</div>"
    end
    
    ###############################################
    # Tabs
    def build_tabs(tabs_name,current,form_instance)
      @@form_instance = form_instance
      @@body = []
      tabs = self.tabs[tabs_name]
      raise "tab group #{tabs_name} doesn't exist" if !tabs
      @@current_tab = current
      @@tabs_name = tabs_name
      body %Q|<div class="tabs"> <ul>|
      tabs.call
      body "</ul></div>"
      @@body.join("\n")
    end
    
    def tab(presentation_name,pretty_name = nil)
      url = Record.url(@@form_instance.id,presentation_name,@@tabs_name)
      name = pretty_name ? pretty_name : presentation_name
      body %Q|<li #{(@@current_tab == presentation_name) ? 'id="current"' : '' } class="tab_#{presentation_name}"> <a href="#" onClick="return submitAndRedirect('#{url}')" title="Click here to go to #{name}"><span>#{name}</span></a> </li>|
    end    
    ###############################################
    # a javascript function button
    def function_button(name,css_class=nil,&block)
      js = block.call
      css = css_class ? %Q| class="#{css_class}"| : ''
      body %Q|<input type="button" value="#{name}"#{css} onclick="#{js}">|
    end
    
    ###############################################
    # a javascript check to do something if the value of one of the fields in the form
    # matches an expression
    def javascript_if_field(field,expr,value,&block)
      save_context(:js) do
        javascript %Q|if (#{get_field_value_javascript_function(field)} #{expr} '#{value}') {#{block.call} };|
      end
    end

    ###############################################
    # a javascript check to present a confirm alert and complete an action if agreed
    def javascript_confirm(text,&block)
      save_context(:js) do
        javascript %Q|if (confirm('#{quote_for_javascript(text)}')) {#{block.call}};|
      end
    end
    def javascript_submit(&block)
      save_context(:js) do
        javascript %Q|$('metaForm').submit();|
      end
    end

    ###############################################
    #
    def javascript_submit_workflow_action(state)
      save_context(:js) do
        javascript %Q|$('meta_workflow_action').value = '#{state}';$('metaForm').submit();|
      end
    end
    
    ###############################################
    #
    def javascript_show_if(field,expr,value,div_id=nil,css_class="hideable_box",&block)
      javascript_show_hide_if(field,:operator => expr,:value => value,:div_id=>div_id,:show=>true,:css_class=>css_class,&block)
    end

    ###############################################
    #
    def javascript_hide_if(field,expr,value,div_id=nil,css_class="hideable_box",&block)
      javascript_show_hide_if(field,:operator => expr,:value => value,:div_id=>div_id,:show=>false,:css_class=>css_class,&block)
    end
    
    ###############################################
    # for a given field, add a javascript boolean condition and the script to run if it's true
    # into the list of scripts that will be added to the end of the rendered form.
    def add_observer_javascript(field,condition,script)
      #we collect up all the conditions/functions pairs by field because Event.Observer can
      # only be called once per field id.  Thus we have to collect all the javascript bits we want to execute on the
      # observed field, and then generate the javascript call to Event.Observe down in the #build method

      @@observer_jscripts[field] ||= []
      @@observer_jscripts[field] << {:condition => condition, :script => script}
    end
    
    ###############################################
    #
    def build_javascript_boolean_expression(operator,value)
      case operator
      when :in
        %Q|"#{value}" in oc(field_value)|
      else
        %Q|field_value #{operator} "#{value}"|
      end
    end      
    
    ###############################################
    #
    def javascript_show_hide_if(field,opts={},&block)
      options = {
        :operator => '==',
        :value => nil,
        :div_id =>nil,
        :show => true,
        :css_class => "hideable_box_with_border",
        :condition => nil,
        :jsaction_show => nil,
        :jsaction_hide => nil
      }.update(opts)
            
      # if we are not actually building skip the generation of javascript
      # but yield so that any sub-questions and stuff can be initialized.
      if @@phase != :build
        block.call if block
        return
      end

      show = options[:show]
      div_id = options[:div_id]
      css_class = options[:css_class]

      div_id = "uid_#{@@unique_ids += 1}" if !div_id
      condition = options[:condition]
      condition ||= build_javascript_boolean_expression(options[:operator],options[:value])
      add_observer_javascript(field,%Q|(#{!show ? "!" : ""}(#{condition}))|,"Element.show('#{div_id}');#{options[:jsaction_show]};} else {Element.hide('#{div_id}');#{options[:jsaction_hide]};}")
      
      if block
        body %Q|<div id="#{div_id}" class="#{css_class}">|
        block.call
        body '</div>'
      else
        body %Q|<div id="#{div_id}" style="display:none"></div>|
      end
    end
    
    #################################################################################
    # the function called by the client to actually render the the html of the form
    def build(presentation_name,form_instance=nil,form = nil)
      @@form = form
      @@unique_ids = 0  
      @@body = []
      @@jscripts = []
      @@observer_jscripts =  {}
      @@form_instance = form_instance
      @@phase = :build
      @@constraint_errors = nil
      @@meta = {}
      p(presentation_name)
      body %Q|<input type="hidden" name="meta[workflow_action]" id="meta_workflow_action">| if !@@meta[:workflow_action]
      
      foot_jscripts = @@observer_jscripts.collect do |field,jsc|
        widget = Widget.fetch(get_field_appearance(field))
        observer_function = widget.javascript_build_observe_function(field,"check_#{field}()",self.fields[field].constraints)
        value_function = widget.javascript_get_value_function(field)
        scripts = ""
        jsc.each {|action| scripts << "if (#{action[:condition]}) {#{action[:script]}"}
        script = <<-EOJS
          #{observer_function}
          function check_#{field}() {
            var field_value = #{value_function};
            #{scripts}
          }
          check_#{field}();
        EOJS
      end
      
      [@@body.join("\n"),foot_jscripts.join("\n")]
    end
    
    def setup(presentation_name,form_instance)
      @@form_instance = form_instance
      @@phase = :setup
      p(presentation_name)
    end

    def verify(presentation_name,form_instance,attributes)
      @@phase = :verify
      @@form_instance = form_instance
      @@attributes = attributes
      @@constraint_errors = nil
      p(presentation_name)
    end
 
    # the meta information that will be available to an actions is:
    # meta[:request] the request object
    # meta[:session] the session object
    # and anything put into it by a callback #meta_data_for_save that should
    # be definined in the application controller
    def do_workflow_action(action_name,form_instance,meta)
      @@action_result = {}
      @@form_instance = form_instance      
      workflow_name = form_instance.workflow
      w = self.workflows[workflow_name]
      raise "unknown workflow #{workflow_name}" if !w
      a = w.actions[action_name]
      raise "unknown action #{action_name}" if !a
      raise "action #{action_name} is not allowed when form is in state #{workflow_state}" if !a.legal_states.include?(:any) && !a.legal_states.include?(form_instance.workflow_state)
      a.block.call(meta)
      @@action_result
    end

    def submit(presentation_name,form_instance)
      @@phase = :submit
      @@form_instance = form_instance
      p(presentation_name)
    end
    
    def workflow_for_new_form(presentation_name)
      w = get_presentation_option(presentation_name,:create_with_workflow)
      raise "#{presentation_name} doesn't define a workflow for create!" if !w
      w
    end

    def get_presentation_option(presentation_name,option)
      pres = self.presentations[presentation_name]
      pres.options[option]
    end

    #################################################################################
    # submitting functions
    # TODO, we took this out in favor of the workflow model, but I think it may need
    # to come back in to handle redirects, etc.
    def submit_actions()
      if @@phase == :submit 
        yield
      end
    end
    
    # for now this function assumes that either a build or a verify pass was called on the
    # presentation so that the errors are stored in @@constraint_errors.
    def field_valid(field_names)
      return true if !@@constraint_errors
      
      field_names = arrayify(field_names)
      field_names.each do |field_name|
        return false if @@constraint_errors.has_key?(field_name)
      end
      true
    end
    
    # the field_value is either pulled from the attributes hash if it exists or from the database
    #TODO this needs to be migrated over to get the value from Record.
    def field_value(field_name)
      raise "field #{field_name} not in form " if !field_exists?(field_name)
      field_instance = FieldInstance.find(:first, :conditions => ["form_instance_id = ? and field_id = ?",@@form_instance.id,field_name])
      if @@attributes && @@attributes.has_key?(field_name)
        @@attributes[field_name]
      elsif @@form_instance && !@@form_instance.new_record?  && field_instance = FieldInstance.find(:first, :conditions => ["form_instance_id = ? and field_id = ?",@@form_instance.id,field_name])
        #cache the value in the attributes hash
        @@attributes ||= {}
        @@attributes[field_name] = field_instance.answer
      else
        #TODO get the default from the definition if we aren't getting the value from the database
        nil
      end
    end
        
    # TODO, remember why I wrote this.  Now I'm just using pure ruby ifs in the DNS.  This seems
    # really cumbersome.
    def if_field(field_name,operator,value)
      result = case operator
      when :eq
        field_value(field_name) == value
      when :neq
        field_value(field_name) != value
      when :gt
        field_value(field_name).to_i > value.to_i
      when :lt
        field_value(field_name).to_i < value.to_i
      else 
        false
      end
      yield if result
    end
    
    ##################################################################################
    #TODO-LISA? figure out a better way to be doing this.  Right now the fact that these calls
    # require @@form_instance to be set right (as a global) is a clear indication that this
    # should actually be (in some form) an object that is instantiated.  Perhaps these
    # calls should be over in Record, not in Form.
    
    def workflow_state
      @@form_instance.workflow_state
    end
        
    #################################################################################
    ## accessors
    def field_exists?(field_name)
      self.fields.has_key?(field_name.to_s)
    end

    def presentation_exists?(presentation_name)
      self.presentations.has_key?(presentation_name)
    end

    #TODO this is going to have to switch to "question_name" when that gets implemented
    # to distinguish between questions that render the same field differently
    def get_question(field_name)
      q = self.questions[field_name.to_s]
      raise "question: #{field_name} has not been defined" if !q
      q
    end
    
    def body(text)
      return if @@phase != :build
      @@body << text
    end
    def javascript(js)
      return if @@phase != :build
      self.stuff[:js] << js
    end
    
    #################################################################################
    private
    
    ###########################################################

    ###########################################################
    # split the appearance type from its parameters
    def parse_appearance(a)
      if a =~ /(.*)\((.*)\)/
        [$1,$2]
      else
        a
      end
    end
    
    ###########################################################
    def get_field_appearance(field)
      qs = get_question(field)
      qs.appearance
    end

    ###########################################################
    def get_field_value_javascript_function(field)
      widget = Widget.fetch(get_field_appearance(field))
      widget.javascript_get_value_function(field)
    end
    
    ###########################################################
    def get_field_id(field)
      qs = get_question(field)
      "record_#{field}"
    end

    ###########################################################
    def get_field_enumeration_values(field)
      c = self.fields[field].constraints
      if c
        enum = c['enumeration']
        raise "expecting enumeration constraint for field #{field}!" if !enum
        enum.collect {|h| "#{h.keys[0]}"}
      else
        nil
      end
    end
    
    ###########################################################
    def save_context(what)
      @@contexts.push self.stuff[what]
      self.stuff[what] = []
      yield
      the_stuff = self.stuff[what]
      self.stuff[what] = @@contexts.pop
      the_stuff
    end
    
    ###########################################################
    def quote_for_javascript(text)
      text.gsub(/\n/,'\n').gsub(/"/,'\"')
    end
    
  end
end

################################################################################
# Load the form definitions from RAILS_ROOT/definitions
if File.directory?(Form.forms_dir)
  Dir.foreach(Form.forms_dir) do |file|
    require File.join(Form.forms_dir, file) if file.match(/\.rb$/)
  end
end
################################################################################
