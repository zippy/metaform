
class Form
  include Utilities
  include FormHelper

  # directory in which to auto-load form setup files
  @@forms_dir = 'forms'
  @@cache = {}
  cattr_accessor :forms_dir,:cache

  FieldTypes = ['string','integer','float','decimal','boolean','date','datetime','time','text']

  attr_accessor :fields, :conditions, :questions, :presentations, :groups, :workflows, :listings, :tabs, :label_options

  def initialize
    @fields = {}
    @conditions = {}
    @questions = {}
    @presentations = {}
    @groups = {}
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
  # a placeholder for defining a bunch of conditions
  def def_conditions()
    yield
  end

  #################################################################################
  #################################################################################
  # defines conditions
  # The options for a condition definition are:
  # * :javascript - which is pseudo javascript (field names are preceeded with 
  #   colons and will re replaced with javascript necessary to get values frome
  #   the field widget at runtime)
  # * :overwrite - normally calling c will not overwrite a condition that has 
  #   allready been defined.  use :overwrite to force redefining a condition
  #################################################################################
  def c(name,opts = {},&block)
    if !conditions.has_key?(name) || opts.has_key?(:overwrite)
      options = {:form => self}.update(opts)
      if block_given?
        options[:ruby] = block
      end
      options[:name] = name
      the_condition = Condition.new(options)
      conditions[name] = the_condition
    else
      conditions[name]
    end
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
  #   the list of field definitions of followup fields, and the key is either
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
  # * :group - a string name of a group the field is a member of
  # * :groups - a list of string names of groups the field is a member of
  # * :calculated - this field is not stored but calculated from other values.
  #################################################################################
  def f(name,opts = {})
    options = {
      :type => 'string'
    }.update(opts)

    if options.has_key?(:group)
      options[:groups] = [options[:group]]
      options.delete(:group)
    end
    
    the_field = Field.new(:name=>name,:type=>options[:type])
    options.delete(:type)

    @_commons.each do |option_name,option_values|
      option_values.each { |v| set_option_by_class(the_field,option_name,v)}
    end
    options.each { |option_name,v| set_option_by_class(the_field,option_name,v)}

    #TODO handle user defined types
    raise MetaformException,"Unknown field type: #{the_field[:type]}" unless FieldTypes.include?(the_field.type)

    if the_field.groups
      the_field.groups.each { |g| groups[g] ||= {}; groups[g][name] = true }
    end

    if options.has_key?(:followups)
      conds = {}
      the_field.followups.each do |followup_condition,followup_fields|
        fields = arrayify(followup_fields)
        case followup_condition
        when String
          if followup_condition =~ Condition::OperatorMatch
            cond = c(followup_condition)
          else
            if the_field.constraints && the_field.constraints['set']
              cond = c("#{name} includes #{followup_condition}")
            else
              if followup_condition =~ /^\/.*\/$/
                cond = c("#{name}=~#{followup_condition}")
              elsif followup_condition =~ /^!\/.*\/$/
                  cond = c("#{name}!~#{followup_condition}")
              else
                cond = c("#{name}=#{followup_condition}")
              end
            end
          end
        when Condition
          cond = followup_condition
        when :answered
          cond = c("#{name} answered")
        else
          raise MetaformException, "followup key '#{followup_condition.inspect}' is invalid.  It must be a value, a full string condition defintion or a condition defined by c(...)"
        end
          
        the_field.force_nil_if = {cond,fields.collect {|f| f.name}}
        fields.each do |field|
          conds[field.name] = cond
#TODO-Eric
#TODO-Ellen  constraints auto-defined for followups?  Required?
#          field.constraints ||= {}
#          field.constraints['required'] = "#{name}=#{field_answer}"
        end 
      end
      the_field.followup_conditions = conds
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
    if common_options.has_key?(:group)
      common_options[:groups] = []
      common_options[:groups] << common_options[:group]
      common_options.delete(:group)
    end
    common_options.each {|option_name,option_value| @_commons[option_name] ||= [];@_commons[option_name].push option_value}
    yield
    common_options.each {|option_name,option_value| @_commons[option_name].pop;@_commons.delete(option_name) if @_commons[option_name].size == 0}
  end

  #################################################################################
  # a placeholder for defining a bunch of constraitns
  def def_constraints()
    yield
  end

  #################################################################################
  #################################################################################
  # defines constraints
  # The options for a constraint definition are:
  # * :fields - a list of fields to add the constraints to
  # * :constraints - a hash of the constraints
  #################################################################################
  def cs(opts = {})
    field_list = opts[:fields]
    field_list.each { |f| fields[f].constraints.update(opts[:constraints])} if opts[:constraints]
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
    body tab_html(presentation_name,opts)
  end    
  
  def tab_html(presentation_name,opts)
    options = {
      :label => nil,
      :index => -1,
      :tabs_name => @tabs_name,
      :current_tab => @current_tab
    }.update(opts)
    index = options[:index]
    index = index == -1 ? @_index : index
    url = Record.url(@record.id,presentation_name,options[:tabs_name],index)
    label = options[:label]
    label ||= presentation_name.humanize
    current_text = (@_index.to_s == index.to_s && options[:current_tab] == presentation_name) ? "current " : ""
    %Q|<li class=\"#{current_text}tab_#{presentation_name}\"> <a href=\"#\" onClick=\"return submitAndRedirect('#{url}')\" title=\"Click here to go to #{label}\"><span>#{label}</span></a> </li>|
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
      :legal_states => :any,
      :force_read_only => nil
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
    read_only = @force_read_only>0 || options[:read_only]
    @_questions_built << question_name if @_questions_built && ! read_only
        
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
      raise MetaformException,'calculated fields can only be used read-only' if fields[field_name].calculated && !read_only
      widget_type,widget_parameters = parse_widget(widget)
      options.update({:field=>fields[field_name],:widget =>widget_type,:params =>widget_parameters})
      the_q = questions[question_name] = Question.new(options)
    end
      
    case 
#    when @phase == 'verify' || :build
    when @phase == :build
      field = the_q.field
      value = @record ? @record[field.name,@_index] : nil 
      body the_q.render(self,value,read_only)
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
          
        conds = the_q.field.followup_conditions
        cond = conds[followup_field_name]
        opts = {:css_class => 'followup',:condition=>cond}
#        opts.update(cond.generate_show_hide_js_options(the_q.get_widget.is_multi_value?))
        javascript_show_hide_if(opts) do
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
      @force_read_only ||= 0
      @force_read_only += 1 if pres.force_read_only
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
        raise MetaformException,"reference_field option must be defined" if !indexed[:reference_field]
        if @phase == :build
          orig_index = @_index
          @_index = '%X%'
          template = save_context(:body) do
            pres.block.call
          end

          template = quote_for_javascript(template.join(''))
          @_multi_index_fields ||= {}
          template.scan(/\[_%X%_(.*?)\]/) {|f| @_multi_index_fields[f] = true}

          #TODO-Eric for now this just removes info icons from newly created items, but in the future
          # we should make the javascript be able to create tool-tips on the fly for any info items that
          # happen to be in the template.
          template.gsub!(/<info>(.*?)<\/info>/,'')           

          javascript %Q|var #{presentation_name} = new indexedItems;#{presentation_name}.elem_id="presentation_#{presentation_name}_items";#{presentation_name}.delete_text="#{indexed[:delete_button_text]}";#{presentation_name}.self_name="#{presentation_name}";|
          javascript <<-EOJS
            function doAdd#{presentation_name}() {
              var t = "#{template}";
              var idx = parseInt($F('multi_index'));
              t = t.replace(/%X%/g,idx);
              $('multi_index').value = idx+1;
              #{presentation_name}.addItem(t);
            }
          EOJS
          add_button_html = %Q|<input type="button" onclick="doAdd#{presentation_name}()" value="#{indexed[:add_button_text]}">|
          body add_button_html if indexed[:add_button_position] != 'bottom'
          body %Q|<ul id="presentation_#{presentation_name}_items">|
          answers = @record[indexed[:reference_field],:any]
          @_use_multi_index = answers ? answers.size : 0
          @_use_multi_index = 1 if @_use_multi_index == 0
          (0..@_use_multi_index-1).each do |i|
            @_index = i
            body %Q|<li id="item_#{i}" class="presentation_indexed_item">|
            pres.block.call
            body %Q|<input type="button" class="float_right" value="#{indexed[:delete_button_text]}" onclick="#{presentation_name}.removeItem($(this).up())"><div class="clear"></div>|
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
    @force_read_only -= 1 if pres.force_read_only
    if reset_pres
      @_presentation = nil
    end
  end

  #################################################################################
  #################################################################################
  # Question with sub-presentation.  Use this to declare a question which if the 
  # given condition is true then display a sub-presentation.  The default condition
  # is <field_name>=N
  # It assumes that the presentation name is the same as the field name unless
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
      :condition => "#{field_name}=N",
      :show => false
    }.update(options[:show_hide_options])
    q field_name, options[:question_options]
    presentation_name = options[:presentation_name]
    presentation_name ||= field_name
    javascript_show_hide_if(show_hide_options) do
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
    #TODO , :params => widget_parameters
    w = widget.render(@@form,'workflow_state',workflow_state,label,:constraints => {"enumeration"=>states})
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
  def js_conditional_tab(opts={})  
    if @phase == :build
      options = {
        :before_anchor => true
      }.update(opts)
      condition = c("#{options[:tab]}_changer")
      raise MetaformException "condition must be defined" if !condition.instance_of?(Condition)
      raise MetaformException "tabs_name must be defined" if !options[:tabs_name]
      if options[:multi]
        tab_html_options = {:label => "#{options[:label]} NUM", :index => "INDEX", :current_tab => options[:current_tab]}  
        tab_num_string = "value_#{options[:multi]}()-1"
        multi_string = "true"
      else
        tab_html_options = {:label => options[:label], :index => options[:index], :tabs_name => options[:tabs_name], :current_tab => options[:current_tab]}
        tab_num_string = "1"
        multi_string = "false"
      end
      html_string = tab_html(options[:tab],tab_html_options).gsub(/'/, '\\\\\'')
      js_remove = %Q|$$(".tab_#{options[:tab]}").invoke('remove');|
      js_add = %Q|insert_tabs('#{html_string}','.tab_#{options[:anchor_css]}',#{options[:before_anchor]},'.tab_#{options[:default_anchor_css]}',#{tab_num_string},#{multi_string});|
      add_observer_javascript(condition.name,js_remove+js_add,false)
      add_observer_javascript(condition.name,js_remove,true)
    end
  end

  #################################################################################
  # Add a block of elements that will appear conditionally 
  # at runtime on the browser depending on other form field values as specified
  # by the options.
  #
  # Options:
  # * :operator - the javascript operator to use to compare (defaults to '==')  
  # * :value - the value to compare the field to (defaults to nil)
  # * :wrapper_element - set a custom wrapper element.  Default is 'div'
  # * :wrapper_id - set a custom id for the wrapper element that gets generated.  By default it will
  #   simply auto-generate a unique id for the element.  Note that if you use a custom
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
  #Note:  invoke_on_class => <class_name> requires that '<%if hiding_js%>style="display:none" <% end %>' be placed
  #in the html tag for each element of class_name where this hiding behaviour should happen on page load.  By default,
  #javascript will control on page action but the ruby, page-load action needs a little help.
  def javascript_show_hide_if(opts={})
    options = {
     :operator => '==',
     :value => nil,
     :wrapper_element => 'div',
     :wrapper_id =>nil,
     :invoke_on_class => nil,
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
    wrapper_id = options[:wrapper_id]
    css_class = options[:css_class]

    if !wrapper_id
      @_unique_ids ||= 0
      wrapper_id = "uid_#{@_unique_ids += 1}"
    end
    condition = options[:condition]
    if condition.instance_of?(String)
      condition = c(condition)
    end
    raise MetaformException "condition must be defined" if !condition.instance_of?(Condition)
    show_actions = []
    hide_actions = []
    show_actions << options[:jsaction_show] if options[:jsaction_show]
    hide_actions << options[:jsaction_hide] if options[:jsaction_hide]
    if invoke_on_class = options[:invoke_on_class]
      show_actions << %Q|$$(".#{invoke_on_class}").invoke("show")|
      hide_actions << %Q|$$(".#{invoke_on_class}").invoke("hide")|
    else
      show_actions << "Element.show('#{wrapper_id}')"
      hide_actions << "Element.hide('#{wrapper_id}')"
    end
    add_observer_javascript(condition.name,show_actions.join(';'),!show)
    add_observer_javascript(condition.name,hide_actions.join(';'),show)
    
    cond_value = condition.evaluate
    hide = !block_given? || (show && !cond_value) || (!show && cond_value)
    @_hiding_js = hide
    if wrapper_element = options[:wrapper_element]
      wrapper = %Q|<#{wrapper_element} id="#{wrapper_id}"|
      wrapper << %Q| class="#{css_class}"| if css_class
      wrapper << %Q| style="display:none"| if hide
      wrapper << '>'
      body wrapper
    end
    yield if block_given?
    body "</#{wrapper_element}>" if wrapper_element
    @_hiding_js = nil
  end
  
  ###############################################
  # show a block conditionally at 'runtime' on the browser
  # (convenience function to javascript_show_hide_if)
  #
  # Options: see #javascript_show_hide_if
  #
  # Example: 
  #   javascript_show_if('married=y') do
  #     q 'children'
  #   end
  ###############################################      
  def javascript_show_if(condition,opts={},&block)
    options = {
      :css_class=>"hideable_box"
    }.update(opts)
    options.update({:condition => condition,:show=>true})
    javascript_show_hide_if(options,&block)
  end

  ###############################################
  # hide a block conditionally at 'runtime' on the browser
  # (convenience function to javascript_show_hide_if)
  #
  # Options: see #javascript_show_hide_if
  def javascript_hide_if(condition,opts={},&block)
    options = {
      :css_class=>"hideable_box"
    }.update(opts)
    options.update({:condition => condition,:show=>false})
    javascript_show_hide_if(options,&block)
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
  #TODO-Eric make this match new syntax for conditions i.e. one string with :fieldname and get 
  # figure out the widgets on the fly
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
    @_questions_built = []
    @_use_multi_index = nil
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
      if use_multi_index?
        body %Q|<input type="hidden" name="multi_index" id="multi_index" value="#{@_use_multi_index}">|
        body %Q|<input type="hidden" name="multi_index_fields" id="multi_index_fields" value="#{@_multi_index_fields.keys.join(',')}">|
      end
      
      jscripts = []
      hiddens_added = {}

      field_widget_map = questions_field_widget_map(get_questions_built)
      ojs = get_observer_jscripts
       if ojs
        field_name_action_hash = {}
        ojs.collect do |condition_name,actions|
          cond = conditions[condition_name]
          raise condition_name if cond.nil?
          fnname = 'actions_for_'+cond.js_function_name
          cond.fields_used.each do |field_name|
            if field_widget_map.has_key?(field_name)
              field_name_action_hash.key?(field_name) ? field_name_action_hash[field_name] << fnname : field_name_action_hash[field_name] = [fnname]
             end
          end
          jscripts << <<-EOJS
function #{fnname}() {
  if (#{cond.js_function_name}()) {#{actions[:pos].join(";")}}
  else {#{actions[:neg].join(";")}}
}
EOJS
#{fnname}();

          (js,hiddens) = cond.generate_javascript_function(field_widget_map)
          jscripts << js
          hiddens.each { |h| body %Q|<input type="hidden" name="___#{h}" id="___#{h}" value="#{field_value(h)}">| if !hiddens_added[h];hiddens_added[h]=true }
        end
        field_name_action_hash.each do |the_field_name,the_functions|
          (widget,widget_options) = field_widget_map[the_field_name];
          jscripts << widget.javascript_build_observe_function(the_field_name,"#{the_functions.join('();')}();",widget_options)
        end
      end

      b = get_body.join("\n")
      b.gsub!(/<info>(.*?)<\/info>/) {|match| tip($1)}

      if @_tip_id
        b = javascript_include_tag("prototip-min") + stylesheet_link_tag('prototip',:media => "screen")+b
      end

      js = get_jscripts
      jscripts << js if js
      
      [b,jscripts.join("\n")]
    end
  end
    
  # build a field_name to widget mapping so that we can pass it into the conditions
  # to build the necessary javascript
  def questions_field_widget_map(question_list)
    field_widget_map = {}
    question_list.each do |question_name|
      q = questions[question_name]
      field_name = q.field.name
      w = q.get_widget
      raise MetaformException,"Ouch! two different widgets for field #{field_name} (#{field_widget_map[field_name].inspect} && #{w.inspect})" if field_widget_map[field_name] && field_widget_map[field_name][0] != w
      field_widget_map[field_name] = [w,{:constraints => q.field.constraints, :params => q.params}]        
    end
    field_widget_map
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
  # add a "tool tip"
  #################################################################################
  def tip(text,opts={})
#    options = {
#    }.update(opts)
    @_tip_id ||= 1
    tip_id = "tip_#{@_tip_id}"
    javascript %Q|new Tip('#{tip_id}',"#{quote_for_javascript(text)}")|
    @_tip_id += 1
    %Q|<img src="/images/info_circle.gif" alt="info" id="#{tip_id}">|
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

  def field_valid(field_names)
    return true
#    field_names = arrayify(field_names)
#    field_names.each do |field_name|
#      field = fields[field_name]
#      p = field.properties[0]
#      return false if p.evaluate(self,field,field_value(field_name))
#    end
#    true
  end

  def field_value(field_name,index = -1)
    return if @phase == :setup
    raise MetaformException,"attempting to get field value of '#{field_name}' with no record" if @record.nil?
    index = index == -1 ? @_index : index
    @record[field_name,index]
  end
  
  #TODO-Eric or Lisa
  # this meta-information is not easily accessible in the same way that questions are, and probably
  # should be.  We need to formalize and unify the concept of meta or housekeeping information
  def workflow_state
    return if @phase == :setup
    raise MetaformException,"attempting to get workflow state with no record" if @record.nil?
    @record.workflow_state
  end

  def created_at
    return if @phase == :setup
    raise MetaformException,"attempting to get created_at state with no record" if @record.nil?
    @record.created_at
  end
  
  def updated_at
    return if @phase == :setup
    raise MetaformException,"attempting to get updated_at state with no record" if @record.nil?
    @record.updated_at
  end

  def created_by_id
    return if @phase == :setup
    raise MetaformException,"attempting to get created_by_id state with no record" if @record.nil?
    @record.created_by_id
  end
  
  def updated_by_id
    return if @phase == :setup
    raise MetaformException,"attempting to get updated_by_id state with no record" if @record.nil?
    @record.updated_by_id
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

  def get_questions_built
    @_questions_built
  end

  def get_record
    @record
  end
  
  def hiding_js?
    @_hiding_js
  end
  
  def use_multi_index?
    @_use_multi_index
  end

  def index
    @_index
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
  
  def find_conditions_with_fields(field_list)
    conds = []
    conditions.each { |name,c| conds << c if c.uses_fields(field_list) }
    conds
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
  
  def if_c(condition,condition_value=true)
    return if @phase != :build
    if condition.instance_of?(String)
      condition = c(condition)
    end
    raise MetaformException "condition must be defined" if !condition.instance_of?(Condition)
    yield if (condition_value ? condition.evaluate : !condition.evaluate)
  end
  
  # def if_c(condition,condition_value)
  #    case condition
  #    when Condition
  #      cond = c
  #    else
  #      cond = c(condition.to_s) 
  #    end
  #    ConstraintCondition.new(cond,condition_value)
  #  end
 
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
  def add_observer_javascript(condition_name,script,negate = false)
    #we collect up all the conditions/functions pairs by field because Event.Observer can
    # only be called once per field id.  Thus we have to collect all the javascript bits we want to execute on the
    # observed field, and then generate the javascript call to Event.Observe down in the #build method

    @_stuff[:observer_js] ||= {}
    @_stuff[:observer_js][condition_name] ||= {:pos => [],:neg =>[]}
    @_stuff[:observer_js][condition_name][negate ? :neg : :pos] << script
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
    text.gsub(/\n/,'\n').gsub(/"/,'\"').gsub(/\//,'\/')
  end

  ###########################################################
  def quote_for_html_attribute(text)
    text.gsub(/"/,'&quot;')
  end
  
    
end