
class Form
  include Utilities
  include FormHelper

  # directory in which to auto-load form setup files
  @@forms_dir = 'forms'
  @@cache = {}
  cattr_accessor :forms_dir,:cache

  FieldTypes = ['string','integer','float','decimal','boolean','date','datetime','time','text']

  attr_accessor :fields, :questions, :presentations, :workflows, :listings, :tabs, :label_options

  def initialize
    @fields = {}
    @questions = {}
    @presentations = {}
    @workflows = {}
    @listings = {}
    @tabs = {}
    @label_options = {}
    
    @_commons = {}
    @_stuff = {}
    @_contexts = {}
    setup
    @@cache[self.class.to_s] = self
  end
  
  def setup
#    raise "override with your dsl defintion"
  end
  
  def name
    self.class.to_s
  end

  #################################################################################
  #################################################################################
  # The Metaform DSL for specifying the structure of forms and fields in those forms
  #################################################################################
  #################################################################################

  #################################################################################
  #################################################################################
  # define workflow
  #################################################################################
  def workflow(workflow_name,*states)
    @actions = {}
#    @@states = {}
    yield
    workflows[workflow_name] = Workflow.new(:actions => @actions)
  end
  
  # an action consist of a block to execute when running the action as well as a list of
  # states that the form must be in for the action to execute.
  def action(action_name,states_for_action,&block)
    # convert to array if we were called with a single state
    states_for_action = arrayify(states_for_action)
    @actions[action_name] = Struct.new(:block,:legal_states)[block,states_for_action]
  end

  #################################################################################
  # workflow runtime methods.  These are the methods that are used inside an action
  # block and are actually executed by #do_workflow_action
  # TODO this implies that somehow this should all be abastracted so that these methods can only be called in
  # the context of defining a workflow.  All this requires some interesting refactoring into a meta-language
  # for defining DSLs like this one.
  def state(s)
    @_action_result[:next_state] = s
  end

  def redirect_url(url)
    @_action_result[:redirect_url] = url
  end


  #################################################################################
  # a placeholder for defining a bunch of workflows
  def def_workflows()
    yield
  end

  #################################################################################
  #################################################################################
  # defines fields
  # The options for a field definition are:
  # * :type - defaults to 'string' and can be one of: 
  #   string, integer, float, decimal, boolean, date, datetime, time, text
  # * :label - a default label to be used in human interface when displaying
  #   this field
  # * :constraints - a hash of constraint specification key,value pairs
  #   valid constriaint types are: required, regex, range, set, enumeration
  #   see Constraints for details
  # * :followups - a list of fields that are require depending on the value of
  #   this field.  Followups are specified as key value pairs, where the value is
  #   the field definition of the followup field, and the key is either
  # 1. the symbol :answered, in which case the followup is required if the field
  #     has any value.
  # 2. a string value, in which case the followup is required if the field has
  #     the string value
  # 3. a regex or a string that looks like a regex (i.e. starts and ends with '/'),
  #     in which case the followup is required if the field value matches the regex
  # * :properties - a hash of properties that apply to this field.  This keys of this
  #   hash are the property name, and the values of the hash are a Proc object to execute
  #   at runtime that determines whether the field does or does not have the property.
  #   Note: constraints are simply parameters that are passed to the :valid property.
  # * :calculated - this field is not stored but calculated from other values.
  #################################################################################
  def f(name,opts = {})
    options = {
      :type => 'string'
    }.update(opts)
    
    the_field = Field.new(:name=>name,:type=>options[:type])
    options.delete(:type)

    @_commons.each do |option_name,option_values|
      option_values.each { |v| set_option_by_class(the_field,option_name,v)}
    end
    options.each { |option_name,v| set_option_by_class(the_field,option_name,v)}

    #TODO handle user defined types
    raise MetaformException,"Unknown field type: #{the_field[:type]}" unless FieldTypes.include?(the_field.type)

    if options.has_key?(:followups)
      map = {}
      the_field.followups.each do |field_answer,followup_fields|
        fields = arrayify(followup_fields)
        fields.each do |field|
          map[field.name] = field_answer
          field.constraints ||= {}
          #TODO this constraints needs to distinguish between enumerations and sets it currently
          # is assuming that the contraints is just and enumeration.
          field.constraints['required'] = "#{name}=#{field_answer}"
        end 
      end
      the_field.followup_name_map = map
    end
    fields[name] = the_field
  end

  #################################################################################
  #################################################################################
  # Specifies a set of common options for a group of fields.
  # 
  # This is most commonly used for specifying that a group of fields share a
  # common constraint a common property or a common type.
  #
  # Example-- to define two feilds which both are required:
  #   def_fields :constraints => {'required' => true}
  #     f 'name'
  #     f 'address'
  #   end
  #
  # def_fields calls can be nested.  Options which are hashes are merged together.  Options 
  # which are strings are overridden.
  #
  # Example-- to define three feilds which both are required the last of which has a 
  # regular expression based constraint:
  #   def_fields :constraints => {'required' => true}
  #     f 'name'
  #     f 'address'
  #     def_fields :constraints => {'regex' => /^[0-9]{5,5}(-[0-9]{4,4})*$/}
  #       f 'zip'
  #     end
  #   end
  #################################################################################
  def def_fields(common_options = {})
    common_options.each {|option_name,option_value| @_commons[option_name] ||= [];@_commons[option_name].push option_value}
    yield
    common_options.each {|option_name,option_value| @_commons[option_name].pop;@_commons.delete(option_name) if @_commons[option_name].size == 0}
  end

  #################################################################################
  # defines a tab group
  #################################################################################
  def def_tabs(tabs_name,&block)
    tabs[tabs_name] = block
  end

  #################################################################################
  # Rendering elements that can be used inside a tab definition: =ndoc
  #################################################################################
  
  #################################################################################
  # Renders a tab
  #
  # Options:
  # * :label  if no label is given the "humanzied" version of presentation_name
  #   will be uses
  # * :index
  #################################################################################
  def tab(presentation_name,opts={})
    options = {
      :label => nil,
      :index => -1
    }.update(opts)
    index = options[:index]
    index = index == -1 ? @_index : index
    url = Record.url(@record.id,presentation_name,@tabs_name,index)
    label = options[:label]
    label ||= presentation_name.humanize
    id_text = 'id="current"' if @_index.to_s == index.to_s && @current_tab == presentation_name
    body %Q|<li #{id_text} class="tab_#{presentation_name}"> <a href="#" onClick="return submitAndRedirect('#{url}')" title="Click here to go to #{label}"><span>#{label}</span></a> </li>|
  end    

  #################################################################################
  #################################################################################
  # Set default labeling options
  #
  # Options:
  # * :postfix  a string to add at the end of all labels (typically ":")
  #################################################################################
  def labeling(options={})
    label_options.update(options)
  end

  #################################################################################
  #################################################################################
  # define a grouping of rendering elements for display
  #
  # Options:
  # * :legal_states -
  # * :create_with_workflow - a string that specifies that this is a presentation 
  #   that can be used to create a new form record, and that it should be done using 
  #   the given workflow
  # The block given to this method is the list of questions (and supporting code)
  # that defines the questions to be displayed
  #################################################################################

  def presentation(presentation_name,opts={}, &block)
    options = {
      :legal_states => :any
    }.update(opts)
    raise MetaformException,'presentations can not be defined inside presentations' if @_in_presentation
    @_in_presentation = true
    the_presentation = Presentation.new(:name=>presentation_name,:block=>block)
    options.each { |option_name,v| set_option_by_class(the_presentation,option_name,v)}
    presentations[presentation_name] = the_presentation
    in_phase :setup do
      p(presentation_name)
    end
    @_in_presentation = false
  end

  #################################################################################
  #################################################################################
  #  Rendering elements that can be used inside a presentation definition:
  #################################################################################
  #################################################################################

  #################################################################################
  # display a question
  # with a optional followup questions (field had to be defined with :followups)
  # The options for a question definition are:
  # * :widget (defaults to 'TextField') the name of the Widget to render the question
  # * :css_class a css class to use in the question div html
  # * :followups an array of hashes that specifies the widgets to use
  #   for followup fields defined in the field definition
  # * :erb an erb block to render how the question should be displayed.  
  #   The default rendering is the equivalent of this:
  #    <div id="question_<%=field_name%>"<%=css_class_html%><%=initially_hidden ? ' style="display:none"' : ""%>><%=field_html%></div>
  #   though it is done as a straight interpolated string for speed.
  #   additionally variables available for inserting into the erb block are:
  #     field_name, field_label, field_element, field_html (which is the label and element joined 
  #     rendered together by the widget), and css_class_html which is 'class="question"' by default
  # * :initially_hidden (defaults to false) set to true if you want force the style of this question
  #   to "display:none"
  # * :force_verfiy (defaults to false)
  # * :labeling (defaults to nil, i.e. use labeling established globally)  Allows overriding of the global
  #   labeling options.  Takes the same hash of options that the #labeling method accespts
  # * :read_only (defaults to not set) 
  ###############################################

  def q(field_name,opts = {})
    require 'erb'
    options = {
      :widget => 'TextField',
      :css_class => 'question',
      :followups => nil,
      :erb => nil,
      :initially_hidden => false,
      :force_verify => false,
      :labeling => nil,
      :read_only => nil
    }.update(opts)
    widget = options[:widget]
    if opts.size > 0
      question_name = field_name+opts.inspect.hash.to_s
    else
      question_name = field_name
    end
    
    # save the field name/question name mapping into the presentation so that we can get it out later 
    # when we are trying to figure out which widget to use to render it a given field
    if cur_pres = @_presentation #@_stuff[:current_presentation]
      mapping = cur_pres.question_names[field_name]
      if mapping.nil?
        cur_pres.question_names[field_name] = question_name
      elsif mapping != question_name
        raise MetaformException,"field '#{field_name}' is already defined in presentation"
      end
    end

    # note: we can't do this only in setup because the question block may have if's that only
    # get triggered in the build phase by specific values of the question.  So we must 
    # allways be ready to define a question if it wasn't already defined  
    the_q = questions[question_name]
    unless the_q
      raise MetaformUndefinedFieldError,field_name if !field_exists?(field_name)
      raise MetaformException,'calculated fields can only be used read-only' if fields[field_name].calculated && !options[:read_only]
      widget_type,widget_parameters = parse_widget(widget)
      options.update({:field=>fields[field_name],:widget =>widget_type,:params =>widget_parameters})
      the_q = questions[question_name] = Question.new(options)
    end
      
    case 
#    when @phase == 'verify' || :build
    when @phase == :build
      field = the_q.field
      value = @record ? @record[field.name,@_index] : nil 
      body the_q.render(self,value)
    end
    
    if followups = options[:followups]
      raise MetaformException,"no followups defined for field '#{field_name}'" if !the_q.field.followups
      followups = arrayify(followups)
      followups.each do |w|
        #if the item is a String assume it's just the name of the field and all the followup field
        #options are just the defaults
        case w
        when String
          followup_field_name = w
          followup_question_options = {}
        when Hash
          followup_field_name = w.keys[0]
          followup_question_options = w.values[0]
          #if a value in any of the hashes is a string, assume that it is the widget option
          followup_question_options = {:widget => followup_question_options} if followup_question_options.instance_of?(String)
        else
          raise MetaformException,"followups must be specified with a String or a Hash"
        end
          
        map = the_q.field.followup_name_map
        value = map[followup_field_name]
        opts = {:css_class => 'followup'}
        if value == :answered
          opts[:condition] = %Q|field_value != null && field_value != ""|
        elsif value =~ /^\/(.*)\/$/
          #TODO-LISA make this work if the field value is an array (which it would be for a set instead of an enum)
          opts[:condition] = %Q|field_value.match(#{value})|
        else
          if value =~ /^\!(.*)/
            opts[:value] = $1
            opts[:operator] = the_q.get_widget.is_multi_value? ? :not_in : '!='
          else
            opts[:value] = value
            opts[:operator] = the_q.get_widget.is_multi_value? ? :in : '=='
          end
        end
        javascript_show_hide_if(field_name,opts) do
          q followup_field_name,followup_question_options
        end
      end    
    end
  end

  #################################################################################
  #################################################################################
  # display the questions defined in a presentation
  # The options are:
  # * :indexed
  #################################################################################
  def p(presentation_name,opts = {})
    options = {
    }.update(opts)
    pres = self.presentations[presentation_name]
    raise MetaformException,"presentation #{presentation_name} doesn't exist" if !pres
    reset_pres = false
    if @_presentation.nil?
      @_presentation = pres
      reset_pres = true
    end
      
#    save_context(:current_presentation,pres) do

#  Had to comment this out because we actually need to go through all the 
# calls to sub presentations to set up the questions mapping everywhere
# TODO- see if there is a better way to handle this.
#      if @phase == :setup
#        return if pres.initialized
#      end
      if @phase == :build
        legal_states = pres.legal_states
        if legal_states != :any && !arrayify(legal_states).include?(workflow_state)
          raise MetaformException,"presentation #{presentation_name} is not allowed when form is in state #{workflow_state}"
        end
      end
      pres.initialized = true
      indexed = options[:indexed]
      css_class = indexed ? 'presentation_indexed' : 'presentation'
      body %Q|<div id="presentation_#{presentation_name}" class="#{css_class}">|
      if indexed
        template = save_context(:body) do
          pres.block.call
        end
        raise MetaformException,"reference_field option must be defined" if !indexed[:reference_field]

        if @phase == :build
          template = quote_for_javascript(template.join(''))
          javascript %Q|var #{presentation_name} = new indexedItems;#{presentation_name}.elem_id="presentation_#{presentation_name}_items";#{presentation_name}.delete_text="#{indexed[:delete_button_text]}";#{presentation_name}.self_name="#{presentation_name}";|
          javascript %Q|function doAdd#{presentation_name}() {#{presentation_name}.addItem("#{template}")}|
          add_button_html = %Q|<input type="button" onclick="doAdd#{presentation_name}()" value="#{indexed[:add_button_text]}">|
          body add_button_html if indexed[:add_button_position] != 'bottom'
          body %Q|<ul id="presentation_#{presentation_name}_items">|
          answers = @record.answers_hash(indexed[:reference_field])
          answer = answers[indexed[:reference_field]]
          orig_index = @_index
          (0..answer.size-1).each do |i|
            @_index = i
            body %Q|<li id="item_#{i}" class="presentation_indexed_item">|
            pres.block.call
            body %Q|<input type="button" value="#{indexed[:delete_button_text]}" onclick="#{presentation_name}.removeItem($(this).up())">|
            body '</li>'
          end
          @_index = orig_index
          body '</ul>'
          body add_button_html if indexed[:add_button_position] == 'bottom'
        end
      else
        pres.block.call
      end
      body "</div>"
#    end
    if reset_pres
      @_presentation = nil
    end
  end

  #################################################################################
  #################################################################################
  # Question with sub-presentation.  Use this to declare a question which if the value
  # of the question is "value" (defaults to "N") then display a sub-presentation
  # it assumes that the presentation name is the same as the field name unless
  # the :presentation_name option is used
  #
  # Options:
  # * :presentation_name
  # * :question_options options to pass through to the question
  # * :show_hide_options options to pass through to the javascript_show_hide_if
  
   # Note that this behavior fails on IE6&7 on page re-load.  IE seems to update the value
   # of a form input after the page is rendered and after window.onLoad is called.
   # This means that we can't use the input value to cue follow-up display, since
   # that value will be incorrect. 
  #################################################################################
  def qp(field_name,opts = {})
    options = {:show_hide_options => {},:question_options=>{}}.update(opts)
    show_hide_options = {
      :operator => '==',
      :value => 'N',
      :show => false
    }.update(options[:show_hide_options])
    q field_name, options[:question_options]
    presentation_name = options[:presentation_name]
    presentation_name ||= field_name
    javascript_show_hide_if(field_name,show_hide_options) do
      p presentation_name
    end      
  end

  #################################################################################
  #################################################################################
  # add arbitrary html
  #################################################################################
  def html(text)
    body text
  end

  #################################################################################
  #################################################################################
  #  short-hand for adding the :read_only option to a q
  #################################################################################
  def qro(field_name,opts = {})
    options = {
      :read_only => true
    }.update(opts)
    q(field_name,options)
  end

  #################################################################################
  #################################################################################
  # add a "text" element
  #
  # Defaults to a <p></p> html element with no class
  # The options for a text element are:
  # * :css_class  a string to add at the end of all labels (typically ":")
  #################################################################################
  def t(text,opts={})
    options = {
      :css_class => nil,
      :element => 'p'
    }.update(opts)
    css_class = options[:css_class]
    css_class = %Q| class="#{css_class}"| if css_class
    element = options[:element]
    text = %Q|<#{element}#{css_class}>#{text}</#{element}>| if element
    body text
  end
  
  #################################################################################
  #################################################################################
  # add in a workflow state widget
  def q_meta_workflow_state(label,widget_type,states)
    widget = Widget.fetch(widget_type)
    #TODO FIXME!!!  @@form needs to go away!
    w = widget.render(@@form,'workflow_state',workflow_state,label,:constraints => {"enumeration"=>states}) #TODO , :params => widget_parameters
    #TODO this is a cheat and we need to fix it in widget to generalize it, but it works ok!
    w = w.gsub(/record(.)workflow_state/,'meta\1workflow_state')
    html w
    @_stuff[:added_workflow_action_widget] = true
  end
  

  #################################################################################
  # render button that when pressed executes a javascript function
  #
  # Options:
  # * :css_class 
  #################################################################################
  def function_button(name,opts={})
    options = {
      :css_class => nil
    }.update(opts)
    js = yield
    css_class = options[:css_class]
    css_class = %Q| class="#{css_class}"| if css_class
    body %Q|<input type="button" value="#{name}"#{css_class} onclick="#{js}">|
  end
  
  #################################################################################
  # Add a block of elements that will appear conditionally 
  # at runtime on the browser depending on other form field values as specified
  # by the options.
  #
  # Options:
  # * :operator - the javascript operator to use to compare (defaults to '==')  
  # * :value - the value to compare the field to (defaults to nil)
  # * :div_id - set a custom id for the div that gets generated.  By default it will
  #   simply auto-generate a unique id for the div.  Note that if you use a custom
  #   id it must be unique or the Javascript won't work.
  # * :show - used to specify whether the condition should show or hide the block (defaults to true i.e. "show")
  # * :css_class - a class for the generated div (defaults to "hideable_box_with_border")  
  # * :condition - the javascript condition to evaluate.  If nil the condition will be
  #   generated from the :operator and :value options instead.
  # * :jsaction_show - (defaults to nil)
  # * :jsaction_hide - (defaults to nil)
  # Example:
  #
  #   javascript_show_hide_if('married',:value => 'y') do
  #     q 'children'
  #   end
  # 
  #################################################################################
  def javascript_show_hide_if(field,opts={})
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
    if @phase != :build
      yield if block_given?
      return
    end

    show = options[:show]
    div_id = options[:div_id]
    css_class = options[:css_class]

    if !div_id
      @_unique_ids ||= 0
      div_id = "uid_#{@_unique_ids += 1}"
    end
    condition = options[:condition]
    condition ||= build_javascript_boolean_expression(options[:operator],options[:value])
    add_observer_javascript(get_field_question_name(field),%Q|(#{!show ? "!" : ""}(#{condition}))|,"Element.show('#{div_id}');#{options[:jsaction_show]};} else {Element.hide('#{div_id}');#{options[:jsaction_hide]};}")

    div = %Q|<div id="#{div_id}"|
    div << %Q| class="#{css_class}"| if css_class
    div << %Q| style="display:none"| unless block_given?
    div << '>'
    body div
    yield if block_given?
    body '</div>'
  end
  
  ###############################################
  # show a block conditionally at 'runtime' on the browser
  # (convenience function to javascript_show_hide_if)
  #
  # Options: see #javascript_show_hide_if
  #
  # Example: 
  #   javascript_show_hide_if('married','==',y') do
  #     q 'children'
  #   end
  ###############################################      
  def javascript_show_if(field,operator,value,opts={},&block)
    options = {
      :css_class=>"hideable_box"
    }.update(opts)
    options.update({:operator => operator,:value => value,:show=>true})
    javascript_show_hide_if(field,options,&block)
  end

  ###############################################
  # hide a block conditionally at 'runtime' on the browser
  # (convenience function to javascript_show_hide_if)
  #
  # Options: see #javascript_show_hide_if
  def javascript_hide_if(field,operator,value,opts={},&block)
    options = {
      :css_class=>"hideable_box"
    }.update(opts)
    options.update({:operator => operator,:value => value,:show=>false})
    javascript_show_hide_if(field,options,&block)
  end

#################################################################################
#################################################################################
# javascript support for rendering elements.  These parts of the DLS enable
# produce javascript that can maniupulate fields client-side
#################################################################################

  #################################################################################
  # returns a script check to do something if the value 
  # of one of the fields in the form matches an expression
  #################################################################################
  def javascript_if_field(field_name,expr,value)
    save_context(:js) do
      widget = questions[get_field_question_name(field_name)].get_widget
      javascript %Q|if (#{widget.javascript_get_value_function(field_name)} #{expr} '#{value}') {#{yield}};|
    end
  end

  #################################################################################
  # Returns a script to present a confirm alert and complete an action if agreed 
  #################################################################################
  def javascript_confirm(text)
    save_context(:js) do
      javascript %Q|if (confirm('#{quote_for_javascript(text)}')) {#{yield}};|
    end
  end
  
  #################################################################################
  # javascript_submit - returns a script to submit the current form
  #
  # Options
  # * :workflow_action - set a workflow action before submitting
  # --
  # TODO- this needs to be fixed so that there can be more than one metaform form per page
  #################################################################################
  def javascript_submit(opts = {})
    options = {
      :workflow_action => nil
    }.update(opts)
    save_context(:js) do
      js = %Q|$('metaForm').submit();|
      js = %Q|$('meta_workflow_action').value = '#{options[:workflow_action]}';#{js}| if options[:workflow_action]
      javascript js
    end
  end

    
  ###############################################
  #
  def build_javascript_boolean_expression(operator,value)
    case operator
    when :in
      %Q|"#{value}" in oc(field_value)|
    when :not_in
      %Q|"!(#{value}" in oc(field_value))|
    else
      %Q|field_value #{operator} "#{value}"|
    end
  end      
  
   
  #################################################################################
  #################################################################################
  # generators
  #################################################################################
  #################################################################################

  #################################################################################
  # produce the html for the given tab group setting current tab appropriately
  def build_tabs(tabs_name,current,record)
    tabs_html = ''
    with_record(record) do
      save_context(:body) do
        tabs_block = tabs[tabs_name]
        raise MetaformException,"tab group '#{tabs_name}' doesn't exist" if !tabs_block

        #TODO this should be moved to a render method in a Tabs object
        @current_tab = current
        @tabs_name = tabs_name
        body %Q|<div class="tabs"> <ul>|
        tabs_block.call
        body "</ul></div>"
        tabs_html = get_body.join("\n")
      end
    end
    tabs_html
  end

  #################################################################################
  def prepare_for_build(index)
    @_index = index
    @_stuff = {}
  end

  #################################################################################
  # produce the html and javascript necessary to run the form
  def build(presentation_name,record=nil,index=nil)
    prepare_for_build(index)
    with_record(record,:build) do
      p(presentation_name)
      if !@_stuff[:added_workflow_action_widget]
        body %Q|<input type="hidden" name="meta[workflow_action]" id="meta_workflow_action">| 
      end
      
      ojs = get_observer_jscripts
      if ojs
        jscripts = ojs.collect do |question_name,jsc|
          q = questions[question_name]
          field_name = q.field.name
          widget = q.get_widget
          widget_options = {:constraints => q.field.constraints, :params => q.params}
          observer_function = widget.javascript_build_observe_function(field_name,"check_#{field_name}()",widget_options)
          value_function = widget.javascript_get_value_function(field_name)
          scripts = ""
          jsc.each {|action| scripts << "if (#{action[:condition]}) {#{action[:script]}"}
          script = <<-EOJS
            #{observer_function}
            function check_#{field_name}() {
              var field_value = #{value_function};
              #{scripts}
            }
            check_#{field_name}();
          EOJS
        end
      end
      jscripts ||= []
      js = get_jscripts
      jscripts << js if js
  
      [get_body.join("\n"),jscripts.join("\n")]
    end
  end

  # the meta information that will be available to an action is:
  # meta[:request] the request object
  # meta[:session] the session object
  # and anything put into it by a callback #meta_data_for_save that should
  # be definined in the application controller
  def do_workflow_action(action_name,meta)
    @_action_result = {}
    workflow_name = @record.workflow
    w = self.workflows[workflow_name]
    raise MetaformException,"unknown workflow #{workflow_name}" if !w
    a = w.actions[action_name]
    raise MetaformException,"unknown action #{action_name}" if !a
#    raise MetaformException,"'#{@_action_result[:next_state]}' is not a state defined in the '#{workflow_state}' workflow" if !w.states.keys.include?(@_action_result[:next_state])
    raise MetaformException,"action #{action_name} is not allowed when form is in state #{workflow_state}" if !a.legal_states.include?(:any) && !a.legal_states.include?(@record.workflow_state)
    a.block.call(meta)
    @_action_result
  end

  #################################################################################
  #################################################################################
  ## helpers
  #################################################################################
  #################################################################################

  def field_exists?(field_name)
    self.fields.has_key?(field_name.to_s)
  end

  def presentation_exists?(presentation_name)
    self.presentations.has_key?(presentation_name.to_s)
  end
  
  def get_questions_by_field_name(field_name)
    field_names = self.questions.keys.find_all {|n| n =~ /^#{field_name}/}
    field_names.collect {|f| self.questions[f]}
  end

  def field_value(field_name,index = -1)
    return if @phase == :setup
    raise MetaformException,"attempting to get field value of '#{field_name}' with no record" if @record.nil?
    index = index == -1 ? @_index : index
    @record[field_name,index]
  end
  
  def workflow_state
    return if @phase == :setup
    raise MetaformException,"attempting to get workflow state with no record" if @record.nil?
    @record.workflow_state
  end
  
  def show_verification?
    @show_verification
  end
  
  def set_verification(val)
    @show_verification = val
  end
  
  def in_phase(phase,record=nil)
    with_record(record,phase) do
      yield
    end
  end

  def with_record(record,phase=:build)
    @record = record
    @phase = phase
    result = yield
    @phase = nil
    @record = nil
    result
  end
  
  def workflow_for_new_form(presentation_name)
    w = presentations[presentation_name].create_with_workflow
    raise MetaformException,"#{presentation_name} doesn't define a workflow for create!" if !w
    w
  end

  def get_body
    @_stuff[:body]
  end

  def get_jscripts
    @_stuff[:js]
  end

  def get_observer_jscripts
    @_stuff[:observer_js]
  end

  def get_record
    @record
  end
  
  #TODO this doesn't find questions from nested presentation
  def get_presentation_question(presentation_name,field_name)
    p = presentations[presentation_name]
    questions[p.question_names[field_name]]
  end

  def get_field_constraints_as_hash(field_name,constraint)
    set = fields[field_name].constraints[constraint]
    e = {}
    set.each {|h| k = h.keys[0];e[k]=h[k]}
    e
  end    
  
  #################################################################################
  #################################################################################
  # loads all the files in the "forms" directory that end Form.rb as forms
  # and requires the rest
  def self.boot
  end
  
  #################################################################################
  # helper function to allow separating the DSL commands into multiple files
  def include_definitions(file)
    fn = Form.forms_dir+'/'+file
    file_contents = IO.read(fn)
    eval(file_contents,nil,fn)
  end
  
  #################################################################################
  # helper function to allow separating the DSL commands into multiple files
  def include_helpers(file)
    fn = Form.forms_dir+'/'+file
    file_contents = IO.read(fn)
    Form.class_eval(file_contents,fn)
  end

  #################################################################################
  #################################################################################
  private
  
  ###########################################################
  # collects up html generated by the rendering calls in a presentation
  # during the build phase
  # returns what was added to the body
  def body(html)
    return if @phase != :build
    @_stuff[:body] ||= []
    @_stuff[:body] << html
    html
  end

  ###########################################################
  # collects up javascripts generated by the rendering calls in a presentation
  def javascript(js)
    return if @phase != :build
    @_stuff[:js] ||= []
    @_stuff[:js] << js
    js
  end

  ###############################################
  def get_field_question_name(field_name)
    if !(cur_pres = @_presentation)  #@_stuff[:current_presentation]
      puts "Warning: current presentation not set when trying to get question name for field '#{field_name}'"
      return field_name
    end
    
    q_name = cur_pres.question_names[field_name]
    raise MetaformException,"no question for field '#{field_name}' has been defined in presentation '#{cur_pres.name}'" if !q_name
    q_name
  end
  
  ###############################################
  # for a given field, add a javascript boolean condition and the script to run if it's true
  # into the list of scripts that will be added to the end of the rendered form.
  def add_observer_javascript(question_name,condition,script)
    #we collect up all the conditions/functions pairs by field because Event.Observer can
    # only be called once per field id.  Thus we have to collect all the javascript bits we want to execute on the
    # observed field, and then generate the javascript call to Event.Observe down in the #build method

    @_stuff[:observer_js] ||= {}
    @_stuff[:observer_js][question_name] ||= []
    @_stuff[:observer_js][question_name] << {:condition => condition, :script => script}
  end

  ###########################################################
  # used to save and restore something in the stuff hash for a block call
  def save_context(what,default = [])
    @_contexts[what] ||= []
    @_contexts[what].push @_stuff[what]
    @_stuff[what] = default
    yield
    the_stuff = @_stuff[what]
    @_stuff[what] = @_contexts[what].pop
    the_stuff
  end
  
  ###########################################################
  def set_option_by_class(the_bin,option_name,v)
    case v
    when Hash
      the_bin[option_name] ||= {}
      the_bin[option_name].update(v)
    when Array
      the_bin[option_name] ||= []
      the_bin[option_name].concat(v)
      the_bin[option_name].uniq!
    else
      the_bin[option_name] = v
    end
  end
  
  ###########################################################
  # split the widget type from its parameters
  def parse_widget(a)
    if a =~ /(.*)\((.*)\)/
      [$1,$2]
    else
      a
    end
  end

  ###########################################################
  def quote_for_javascript(text)
    text.gsub(/\n/,'\n').gsub(/"/,'\"')
  end

  ###########################################################
  def quote_for_html_attribute(text)
    text.gsub(/"/,'&quot;')
  end
  
    
end