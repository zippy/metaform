
class Form
  include Utilities
  include FormHelper
  include ListingUtilities
  
  MultiIndexMarker = '%X%'
  EventObserveMarker = 'EventObserveMarker'
  RecalculateConditionsMarker = 'RecalculateConditionsMarker'
  # directory in which to auto-load form setup files
  @@forms_dir = 'forms'
  @@cache = {}
  @@store = {}
  @@config = {}
  @@_loaded_helpers = {}
  @@listings = {}
  cattr_accessor :forms_dir,:cache,:config, :listings

  FieldTypes = ['string','integer','float','decimal','boolean','date','datetime','time','text','hash','array']

  attr_accessor :fields, :conditions, :questions, :presentations, :groups, :workflows, :tabs, :zapping_proc, :label_options, :calculated_field_dependencies, :current_tab_label

  def initialize
    @fields = {}
    @conditions = {}
    @questions = {}
    @presentations = {}
    @groups = {}
    @workflows = {}
    @tabs = {}
    @zapping_proc = nil
    @label_options = {}
    @calculated_field_dependencies = {}
    
    @_commons = {}
    @_stuff = {}
    @_contexts = {}
    setup
    @@cache[self.class.to_s] = self
  end
  
  def setup
#    raise "override with your dsl defintion"
  end
  
  @@last_form_date = nil
  def Form.make_form(form_name)
    the_form = nil
    # in development mode we reload the forms if there have been any changes
    # in the forms directory
    if RAILS_ENV == 'development'
      require 'find'
      forms_date = Time.at(0)
      Find.find(Form.forms_dir) do |f|
        begin
          m = File.new(f).stat.mtime
          forms_date = m if m > forms_date
        rescue
        end
      end
      if forms_date == @@last_form_date
        the_form = Form.cache[form_name]
      else
        @@last_form_date = forms_date
        Form.cache[form_name] = nil
      end
    else
      the_form = Form.cache[form_name]
    end
    the_form ||= form_name.constantize.new
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
  # define a workflow
  # the states parameter is a hash of the form:
  # {'state_name' => 'human readable state name'}
  # or
  # {'state_name' => {:label => 'human readable state name',:validate => true/false}}  
  # if you want the state to allways display validation errors
  #################################################################################
  def workflow(workflow_name,states)
    @actions = {}
    yield
    workflows[workflow_name] = Workflow.new(:actions => @actions, :states => states)
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
    #If you need to, you can implement passing in a hash that
    #gets turned into key-value pairs added to the url.
    @_action_result[:redirect_url] = url
  end

  def action_return_data(data)
    @_action_result[:return_data] = data
  end

  def validatation(action,data)
    case action
    when :update
      @_action_result[:update_validation_data] = data
    end
  end
  
  def flash(key,value)
    @_action_result[:flash] = {:key=> key,:value=>value}
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
  # * :ruby - ruby code that defines the condition.  Normally this code is supplied
  #   not as a Proc in the options but simply as the block
  # * :overwrite - normally calling c will not overwrite a condition that has 
  #   allready been defined.  use :overwrite to force redefining a condition
  # * :description - a human readable description of what the contition is
  #   this value will be used by Condition#humanize if available instead of the
  #   auto-generated text
  # * :operator, :field_value, :field_name are options that can be supplied to
  #   specify a condition definition.  Normally these are not supplied and instead
  #   will be auto-parsed from the name.  i.e. c('age<18') could instead be defined
  #   c('underage',:field_name=>'age',:operator=>'<',:field_value=>'18')
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
  # a placeholder for defining a bunch of listings
  def Form.def_listings()
    yield
  end

  #################################################################################
  #################################################################################
  # defines a listing
  # The options for a condition definition are:
  #################################################################################
  def Form.listing(name,opts = {},&block)
    if !listings.has_key?(name) || opts.has_key?(:overwrite)
      options = {:form => self}.update(opts)
      # if block_given?
      #   options[:ruby] = block
      # end
      options[:name] = name
      the_listing = Listing.new(options)
      listings[name] = the_listing
    else
      listings[name]
    end
  end
  

  #################################################################################
  #################################################################################
  # defines fields
  # The options for a field definition are:
  # * :type - defaults to 'string' and can be one of: 
  #   string, integer, float, decimal, boolean, date, datetime, time, text, array, hash
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
  # * :indexed - this field defaults to false and should be set to true when the field will be 
  #   on an indexed presentation.
  #################################################################################
  def f(name,opts = {})
    options = {
      :type => 'string',
    }.update(opts)
    raise "Duplicate field name: '#{name}'" if fields.has_key?(name)

    #TODO we should really make enums and constraints an first class object and this check should happen there
    if c = options[:constraints]
      required_constraint_given = c.has_key?('required')
      x = Widget.enumeration(c) if c['enumeration']
      x ||= Widget.set(c) if c['set']
      if x
        o = {}
        l = {}
        x.each do |label,option|
          raise "Duplicate set/enumeration option: #{option.inspect}" if o.has_key?(option)
          raise "Duplicate set/enumeration label: #{label.inspect}" if l.has_key?(label)
          o[option] = 1
          l[label] = 1
        end
      end
    end
    @fields_defined << name if @fields_defined
    if options.has_key?(:calculated)
      if options[:calculated].has_key?(:from_condition) 
        c = conditions[options[:calculated][:from_condition]]
        based_on_fields = c.fields_used
        negate = options[:calculated][:negate]
        options[:calculated][:proc] = Proc.new do |form,index|
          if negate
            c.evaluate ? "false" : "true"
          else
            c.evaluate ? "true" : "false"
          end
        end
      else
        based_on_fields = options[:calculated][:based_on_fields]
      end
      raise MetaformException,"calculated fields need a :proc option that defines a Proc" unless options[:calculated][:proc].class == Proc
      raise MetaformException,"calculated fields need a :based_on_fields option that defines a list of fields used by the calculation proc" unless based_on_fields.class == Array
      based_on_fields.each do |f|
        @calculated_field_dependencies[f] ||= []
        @calculated_field_dependencies[f]<<name
        @calculated_field_dependencies[f].uniq!
      end
    end
    
    if options.has_key?(:group)
      options[:groups] = [options[:group]]
      options.delete(:group)
    end
    
    the_field = Field.new(:name=>name,:type=>options[:type],:required_constraint_given => required_constraint_given)
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
          raise MetaformException, "followup key '#{followup_condition.inspect}' is invalid.  It must be a value, a full string condition defintion or a condition defined by c(...) or an array of these items"
        end
      
        the_field.add_force_nil_case(cond.name,fields.collect {|f| f.name},:unless)
      
        dependents = []
        fields.each do |field|
          dependents << field.name
          conds[field.name] = cond
          if !field.required_constraint_given
            field.constraints ||= {}
            field.constraints['required'] = cond.name
          end
        end
        the_field.set_dependent_fields(dependents)
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
    @fields_defined = []
    yield
    common_options.each {|option_name,option_value| @_commons[option_name].pop;@_commons.delete(option_name) if @_commons[option_name].size == 0}
  end
  
  #################################################################################
  #################################################################################
  # Specifies a dependency of a group of fields on a condition.  The fields
  # will all have the 'required' constraint set for that condition, and any
  # fields mentioned in the condition will have the force_nil options set on
  # the condition.
  # 
  # This makes it easy to implement setting values which are automatically cleared
  # and required.
  #
  # Options: you can set override the default options that the fields :force nil options
  # will be set to with:
  # :force_nil_override => a condition other than the negated dependent condition
  # :force_nil_negate => whether or not the condition in force_nil_override should be negated
  #    by default this value is nil, thus the override condition will NOT be negated
  # All other options will be treated as common options for the fields defined in the block just
  #    as if this were a def_fields call.
  #
  # Example-- to define two feilds which both are required if the first field is y
  #   f 'dietary_restrictions', :label => "Dietary restrictions", :constraints => {'enumeration' => [{'y' => 'Yes'},{'n'=>'No'}]}
  #   def_dependent_fields('dietary_restrictions=y') do
  #     f 'dr_type', :label => "type", :constraints => {'enumeration' => [{nil=>'-'},{'choice'=>'By choice'},{'medical'=>'for medical reasons'}]}
  #     f 'dr_other', :label => "more info"
  #   end
  #
  #################################################################################
  def def_dependent_fields(condition,common_options = {})
    if required_conds = common_options.delete(:additional_required_conditions)
      required_conds = [required_conds] if required_conds.is_a?(String)
      required_conds << condition
    else
      required_conds = condition
    end
    condition = make_condition(condition)
    negate = :unless
    if force_nil_condition = common_options.delete(:force_nil_override)
      force_nil_condition = make_condition(force_nil_condition)
      negate = common_options.delete(:force_nil_negate)
    else
      force_nil_condition = condition
    end
    common_options[:constraints] ||= {}
    common_options[:constraints]['required'] = required_conds
    def_fields(common_options) do
      yield
    end
    condition.fields_used.each {|f| fields[f].set_dependent_fields(@fields_defined)}
    force_nil_condition.fields_used.each do |fn|
      f = fields[fn]
      f.add_force_nil_case(force_nil_condition,@fields_defined.clone,negate)
    end
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
  def def_tabs(tabs_name,options={},&block)
    tabs[tabs_name] = Tabs.new(:name => tabs_name,:block => block,:render_proc => options[:render_proc])
  end
  
  def def_zapping_proc
    @zapping_proc = yield
  end

  #################################################################################
  # Rendering elements that can be used inside a tab definition: =ndoc
  #################################################################################
  
  #################################################################################
  # Renders a tab, or if not in render mode just adds the presentation to the
  # hash of tabs
  #
  # Options:
  # * :label  if no label is given the "humanzied" version of presentation_name
  #   will be uses
  # * :index
  #################################################################################
  def tab(presentation_name,opts={})
    if @render
      body tab_html(presentation_name,opts)
    else
      if @_tabs.has_key?(presentation_name)
        p = @_tabs[presentation_name]
        p = [p] if !p.is_a?(Array)
        p << opts
        @_tabs[presentation_name] = p
      else
        @_tabs[presentation_name] = opts
      end
    end
  end    
  
  def tab_html(presentation_name,opts)
    options = {
      :label => nil,
    }.update(opts)
    index = options[:index] ? options[:index] : 0
    url = Record.url(@record.id,presentation_name,index)
    label = options[:label]
    if @current_tab == presentation_name
      @current_tab_label = label ? label : presentation_name.humanize
    end
    label ||= presentation_name.humanize
    tabs[@tabs_name].render_tab(presentation_name,label,url,@_index.to_i == index.to_i && @current_tab == presentation_name,index)
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
  #
  # by default the presentation will be displayed in the context of the erb template:
  # #{RAILS_ROOT}/app/views/records/show.html.erb
  # but you can add a file of the presentation name into {RAILS_ROOT}/app/views/records
  # and metaform will use that template instead.
  #################################################################################

  def presentation(presentation_name,opts={}, &block)
    options = {
      :legal_states => :any,
      :force_read_only => nil
    }.update(opts)
    raise MetaformException,'presentations can not be defined inside presentations' if @root_presentation
    the_presentation = Presentation.new(:name=>presentation_name,:block=>block)
    options.each { |option_name,v| set_option_by_class(the_presentation,option_name,v)}
    presentations[presentation_name] = the_presentation
#    in_phase :setup do
#      p(presentation_name)
#    end
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
      :labeling => nil,
      :read_only => nil,
      :name => nil
    }.update(opts)
    raise MetaformException,"attempting to process question for #{field_name} with no record" if @record.nil?
    widget = options[:widget]
    question_name = options[:name]
    question_name ||= (opts.size > 0) ? field_name+opts.inspect.hash.to_s : field_name
    read_only = @force_read_only>0 || options[:read_only]

    # save the field name/question name mapping into the presentation so that we can get it out later 
    # when we are trying to figure out which widget to use to render it a given field
#    if cur_pres = @current_presentation #@_stuff[:current_presentation]
#      mapping = cur_pres.question_names[field_name]
#      if mapping.nil?
#        cur_pres.question_names[field_name] = question_name
#      elsif mapping != question_name
#        raise MetaformException,"field '#{field_name}' is already defined in presentation"
#      end
#    end

    # note: we can't do this only in setup because the question block may have if's that only
    # get triggered in the build phase by specific values of the question.  So we must 
    # allways be ready to define a question if it wasn't already defined  
    the_q = questions[question_name]
    if widget.is_a?(Proc)
      widget_type = widget
    else
      widget_type,widget_parameters = parse_widget(widget)
      field_types_allowed = Widget.fetch(widget_type).field_types_allowed
      if field_types_allowed 
        raise MetaformException,"#{widget_type}(#{field_name}) must belong to a field of type #{field_types_allowed.inspect}" if !field_types_allowed.include?(fields[field_name][:type])
      end
    end
    if the_q
      the_q.params = widget_parameters
    else
      raise MetaformUndefinedFieldError,field_name if !field_exists?(field_name)
      raise MetaformException,'calculated fields can only be used read-only' if fields[field_name].calculated && !read_only
      options.update({:field=>fields[field_name],:widget =>widget_type,:params =>widget_parameters})
      the_q = questions[question_name] = Question.new(options)
    end
    if @_stuff[:current_questions] && ! read_only
      @_stuff[:current_questions][field_name] = the_q 
    end

    if @render      
      field = the_q.field
      if @record && @_index != MultiIndexMarker
        if options[:flow_through]
          raise "The question #{field_name} is set as flow_through, but its field is not indexed" if !fields[field_name][:indexed]
          raise "The question #{field_name} is set as flow_through, but was not given a proc" if !options[:flow_through].is_a?(Proc)
          index_to_use = options[:flow_through].call(@_index,@record)  #This will return either an index to use, or nil if we should use the default
        end
        index_to_use ||= @_index 
        value =  @record[field.name,index_to_use]
      else
        value = nil
      end
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
        followup_question_options[:flow_through] = options[:flow_through] if options[:flow_through]  #A followup is flow-through if it's parent is.  
        conds = the_q.field.followup_conditions
        cond = conds[followup_field_name]
        opts = {:css_class => 'followup',:condition=>cond}
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
    raise MetaformException,"attempting to process presentation #{presentation_name} with no record" if @record.nil?
    if @root_presentation.nil?
      @root_presentation = pres
    end
    parent_presentation = @current_presentation
    @current_presentation = pres
    
    # we put this in begin ensure block to make sure that even if a error is thrown that the
    # @root_presentation and the @current_presentation get set back to the appropriate values as
    # the stack is unwound.
    begin
      @force_read_only += 1 if pres.force_read_only
      pres.confirm_legal_state!(workflow_state) if @root_presentation == pres
      pres.initialized = true
      indexed = options[:indexed]
      css_class = indexed ? 'presentation_indexed' : 'presentation'
      body %Q|<div id="presentation_#{presentation_name}" class="#{css_class}">|
      if indexed
        raise MetaformException,"reference_field option must be defined" if !indexed[:reference_field]
        exclude_buttons = indexed[:exclude_buttons]
        if @render
          orig_index = @_index
          @_index = MultiIndexMarker
          @_use_multi_index = 1
          template = save_context(:body) do
            pres.block.call
          end
          template = template.join('')

          #TODO-Eric for now this just removes info icons from newly created items, but in the future
          # we should make the javascript be able to create tool-tips on the fly for any info items that
          # happen to be in the template.
          template.gsub!(/<info>(.*?)<\/info>/,'')           

          template = quote_for_javascript(template)
          @_multi_index_fields ||= {}
          template.scan(/\[_#{MultiIndexMarker}_(.*?)\]/) {|f| @_multi_index_fields[f] = true}

          javascript %Q|var #{presentation_name} = new indexedItems;#{presentation_name}.elem_id="presentation_#{presentation_name}_items";#{presentation_name}.delete_text="#{indexed[:delete_button_text]}";#{presentation_name}.self_name="#{presentation_name}";|
          javascript <<-EOJS
            function doAddIndexedPresentationItem() {
              var t = "#{template}";
              var idx = parseInt($F('multi_index'));
              t = t.replace(/#{MultiIndexMarker}/g,idx);
              $('multi_index').value = idx+1;
              #{presentation_name}.addItem(t,idx);
              var js = "#{EventObserveMarker}"
              js = js.replace(/#{MultiIndexMarker}/g,idx);
              window.globalEval(js)
            }
            function doRemoveIndexedPresentationItem(item,idx) {
              var js = "#{RecalculateConditionsMarker}"
              js = js.replace(/#{MultiIndexMarker}/g,idx);
              window.globalEval(js)
              #{presentation_name}.removeItem($(item).up())
            }
          EOJS
          add_button_html = %Q|<input type="button" onclick="doAddIndexedPresentationItem()" value="#{indexed[:add_button_text]}">|
          body add_button_html if indexed[:add_button_position] != 'bottom' && !exclude_buttons
          body %Q|<ul id="presentation_#{presentation_name}_items">|
          answers = @record[indexed[:reference_field],:any].delete_if {|a| a.blank? }
          @_use_multi_index = answers ? answers.size : 0
          @_use_multi_index = 1 if @_use_multi_index == 0
          (0..@_use_multi_index-1).each do |i|
            @_index = i
            body %Q|<li class="presentation_indexed_item">|
            pres.block.call
            body %Q|<input type="button" class="float_right" value="#{indexed[:delete_button_text]}" onclick="doRemoveIndexedPresentationItem(this,#{i})"><div class="clear"></div>| unless exclude_buttons
            body '</li>'
          end
          @_index = orig_index
          body '</ul>'
          body add_button_html if indexed[:add_button_position] == 'bottom'
          @_any_multi_index = @_use_multi_index  #This is used to properly set up the hidden fields necessary for an indexed presentation
          @_use_multi_index = nil
        else
          pres.block.call
        end
      else
        pres.block.call
      end
      body "</div>"
    ensure
      @force_read_only -= 1 if pres.force_read_only
      if @root_presentation == pres
        @root_presentation = nil
      end
      @current_presentation = parent_presentation
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
    presentation_name = options[:question_options][:presentation_name]
    presentation_name ||= field_name
    javascript_show_hide_if(show_hide_options) do
      p presentation_name
    end      
  end

  #################################################################################
  #################################################################################
  # add arbitrary html
  #################################################################################
  def html(text = '')
    return if !@render
    text += yield if block_given?
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
  def t(text = '',opts={})
    options = {
      :css_class => nil,
      :element => 'p'
    }.update(opts)
    return if !@render
    text += yield if block_given?
    css_class = options[:css_class]
    css_class = %Q| class="#{css_class}"| if css_class
    element = options[:element]
    text = %Q|<#{element}#{css_class}>#{text}</#{element}>| if element
    body text
  end

  #################################################################################
  #################################################################################
  # add in a workflow state widget as meta data which will be passed through
  # to do_workflow_action.  This is used when you want to give the user explicit
  # control over which workflow state to go to next
  def q_meta_workflow_state(label,widget_type)
    return if !@render
    widget = Widget.fetch(widget_type)
    #TODO , :params => widget_parameters
    states = workflows[record_workflow].make_states_enumeration
    w = widget.render('workflow_state',workflow_state,label,:constraints => {"enumeration"=>states})
    #TODO this is a cheat and we need to fix it in widget to generalize it, but it works ok!
    w = w.gsub(/record(.)workflow_state/,'meta\1workflow_state')
    html w
  end
  

  #################################################################################
  # render button that when pressed executes a javascript function
  #
  # Options:
  # * :css_class 
  #################################################################################
  def function_button(name,opts={})
    return if !@render
    options = {
      :css_class => nil
    }.update(opts)
    js = yield
    css_class = options[:css_class]
    css_class = %Q| class="#{css_class}"| if css_class
    disabled = options[:disabled] ? ' disabled="disabled"' : ''
    body %Q|<input type="button" value="#{name}"#{css_class} onclick="#{js}"#{disabled}>|
  end
  
  #################################################################################
  #This method is used to create all of the html and javscript to control whether a 
  #tab is displayed, based on a condition.
  #Options:
  # :tab - name of presentation displayed by this tab
  # :anchor_css - used to find tab which this tab will go immediately before
  # :multi - used when a tab is controlled by a numbered field, ie when the number of this flavor of tab is variable
  # :tabs_name - group the tab is a part of
  # :current_tab - whether or not the page is currently on this tab
  # :label - label for the tab 
  # :default_anchor_css - if desired tab isn't there, use this tab as an anchor
  # :condition - condition which should be checked to see if tab should be shown.  If this is not present, then
  # the default is :tab followed by '_changer'
  # :before_anchor - whether the tab appears before or after the anchor tab, defaults to true
  def js_conditional_tab(opts={})
    return if !@render
    options = {
      :before_anchor => true
    }.update(opts)
    condition = options[:condition] ? c(options[:condition]) : c("#{options[:tab]}_changer")
    raise MetaformException "condition must be defined" if !condition.instance_of?(Condition)
    if options[:multi]
      tab_html_options = {:label => "#{options[:label]} NUM", :index => "INDEX"}  
      tab_num_string = "values_for_#{options[:multi]}[cur_idx]-1"
      multi_string = "true"
    else
      tab_html_options = {:label => options[:label], :index => options[:index]}
      tab_num_string = "1"
      multi_string = "false"
    end
    prepare_for_tabs(options[:tabs_name],options[:current_tab])
    html_string = tab_html(options[:tab],tab_html_options).gsub(/'/, '\\\\\'')
    js_remove = %Q|$$(".tab_#{options[:tab]}").invoke('remove');|
    js_add = %Q|insert_tabs('#{html_string}','.tab_#{options[:anchor_css]}',#{options[:before_anchor]},'.tab_#{options[:default_anchor_css]}',#{tab_num_string},#{multi_string});|
    add_observer_javascript(condition.name,js_remove+js_add,false)
    add_observer_javascript(condition.name,js_remove,true)
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
    # but yield so that any sub-questions and stuff can be processed.
    if !@render
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
    condition = make_condition(options[:condition])
    show_actions = []
    hide_actions = []
    show_actions << options[:jsaction_show] if options[:jsaction_show]
    hide_actions << options[:jsaction_hide] if options[:jsaction_hide]
    if invoke_on_class = options[:invoke_on_class]
      show_actions << %Q|$$('.#{invoke_on_class}').invoke('show')|
      hide_actions << %Q|$$('.#{invoke_on_class}').invoke('hide')|
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
      widget = get_current_question_by_field_name(field_name).get_widget
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
      if options[:workflow_action]
        if options[:workflow_action_force]
          @_stuff[:need_workflow_action] = options[:workflow_action]
        else
          js = %Q|$('meta_workflow_action').value = '#{options[:workflow_action]}';#{js}|
          @_stuff[:need_workflow_action] = true
        end
      end
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
    with_record(record,:render) do
      save_context(:body) do
        the_tabs = tabs[tabs_name]
        raise MetaformException,"tab group '#{tabs_name}' doesn't exist" if !tabs.has_key?(tabs_name)
        prepare_for_tabs(tabs_name,current)
        body %Q|<div class="tabs"><ul>|
        the_tabs.block.call
        body %Q|</ul></div><div class='clear'></div>|
        tabs_html = get_body.join("\n")
      end
    end
    tabs_html
  end
  
  def prepare_for_tabs(tabs_name,current_tab = nil)
    @tabs_name = tabs_name
    @current_tab = current_tab
  end
  
  #################################################################################
  # return a list of the tabs for the current record
  def setup_tabs(tabs_name,record)
    with_record(record) do
      the_tabs = tabs[tabs_name]
      raise MetaformException,"tab group '#{tabs_name}' doesn't exist" if !tabs.has_key?(tabs_name)
      prepare_for_tabs(tabs_name)
      @_tabs = {}
      the_tabs.block.call
      @_tabs
    end
  end

  #################################################################################
  def prepare(index,force_read_only=false)
    set_current_index(index)
    @_stuff = {}
    @_stuff[:current_questions] = {}
    @_use_multi_index = nil  #This will be set to true during def p of any presentation which is multi-indexed, then reset to nil
    @_any_multi_index = nil  #This will be set to true if any single presentation is multi-indexed
    @force_read_only = force_read_only ? 1 : 0
  end

  #################################################################################
  def set_current_index(index)
    #raise "set_current_index:  index = #{index}" if index == 2
    @_index = index
  end
  def get_current_index
    @_index
  end

  #################################################################################
  def setup_validating(presentation_name)
    if !validating? #if someone else set the validating state globally accept that
      raise MetaformException, "presentation #{presentation_name} not found" if !presentation_exists?(presentation_name)
      v = presentations[presentation_name].validation  # otherwise use the presentation validation state
      if !v.nil?
        # if validation from the presentation is :before save then we set validation back to nil because
        # we want to validation on first presentation, and record.rb sets validation if there was an error
        v = nil if v == :before_save
      else
        #otherwise use the state default validation state
        v = workflows[record_workflow].should_validate?(workflow_state)
      end
      set_validating(v) if v
    end
  end

  #################################################################################
  # run through the presentation not rendering.
  def setup_presentation(presentation_name,record,index=0)
    index ||= 0
    prepare(index)
    with_record(record) do
      setup_validating(presentation_name)
      p(presentation_name)
    end
  end

  #################################################################################
  # produce the html and javascript necessary to run the form
  def build(presentation_name,record=nil,index=0,force_read_only = false)
    index ||= 0
    prepare(index,force_read_only)
    with_record(record,:render) do
      setup_validating(presentation_name)
      p(presentation_name)
      body %Q|<input type="hidden" name="meta[force_read_only]" id="meta_force_read_only" value="1">| if force_read_only
      body %Q|<input type="hidden" name="meta[last_updated]" id="meta_last_updated" value=#{record.updated_at.to_i}>|
      if @_stuff[:need_workflow_action]
        body %Q|<input type="hidden" name="meta[workflow_action]" id="meta_workflow_action"#{@_stuff[:need_workflow_action].is_a?(String) ? %Q*value="#{@_stuff[:need_workflow_action]}"* : ''}>|
      end
      if any_multi_index?
        body %Q|<input type="hidden" name="multi_index" id="multi_index" value="#{@_any_multi_index}">|
        body %Q|<input type="hidden" name="multi_index_fields" id="multi_index_fields" value="#{@_multi_index_fields.keys.join(',')}">|
      end
      jscripts = []
      multi_index_jscripts = []
      stored_value_string = ''
      stored_values_added = {}

      field_widget_map = current_questions_field_widget_map
      ojs = get_observer_jscripts
      observe_js_for_add_function = ''
      recalculate_conditions_js_for_remove_function = ''
      special_fnname = ''
    if ojs
      field_name_action_hash = {}
      ojs.collect do |condition_name,actions|
        cond = conditions[condition_name]
        raise condition_name if cond.nil?
        if condition_name =~ /(.*)_#{MultiIndexMarker}$/
          multi_indexed_presentation = $1
          special_fnname = 'actions_for_' + multi_indexed_presentation
          fnname = 'actions_for_'+cond.js_function_name.gsub('_X',"_#{MultiIndexMarker}")
        else
          multi_indexed_presentation = nil
          fnname = 'actions_for_'+cond.js_function_name
        end
        cond.fields_used.each do |field_name|
          if field_widget_map.has_key?(field_name)
            field_name_action_hash.key?(field_name) ? field_name_action_hash[field_name] << fnname : field_name_action_hash[field_name] = [fnname]
           end
           #Every field_name listed as a fields_used for any condition will have a javascript array set up and printed on the page.  
           #This array will be called values_for_#{field_name}
           #The array will have the same structure as the result of calling field_value_at(field_name,:any), ie an array with the ith member
           #being the answer value for the field_instance with field_id = field_name and idx = i. If the type of the field is a hash we will have
           #to use load_yaml to convert to javascript.
           if !stored_values_added[field_name]
             (widget,widget_options) = field_widget_map[field_name];
             stored_value_string << %Q|var values_for_#{field_name} = new Array();|
             value_array = field_value_at(field_name,:any)
             field = fields[field_name]
             if value_array.compact.size > 0  #if the whole array is nil, we don't need to put the value on the page
               if field[:type] == 'hash'
                 result = ''
                 value_array.map! do |val_string| 
                   js_hash_builder = []
                   load_yaml(val_string).each{|k,v| js_hash_builder << "'#{k}':'#{v}'"}
                   "{#{js_hash_builder.join(',')}}"
                 end
                 val = "[$H(#{value_array.join('),$H(')})]"
               elsif field[:type] == 'array'
                 val = '[' + value_array.inspect[1..-2].split(', ').map{|val_string| val_string == 'nil' ? "undefined" : %Q|[#{val_string.split(',').join('","')}]|}.join(",") + ']' 
               else
                 val = "[" + value_array.inspect[1..-2].split(', ').map{|val_string| val_string == 'nil'? "undefined" : val_string}.join(",") +"]"
               end
               stored_value_string <<  %Q|values_for_#{field_name} = #{val};|
             end
             stored_values_added[field_name] = true
           end
         end unless multi_indexed_presentation         
         #fnname is like actions_for_<condition_name>     
         if multi_indexed_presentation
           multi_index_jscripts << "function #{fnname}() {if (#{cond.js_function_name}()) {#{actions[:pos].join(";")}}else {#{actions[:neg].join(";")}}}"
         else
           jscripts << <<-EOJS
function #{fnname}() {
  if (#{cond.js_function_name}()) {#{actions[:pos].join(";")}}
  else {#{actions[:neg].join(";")}}
}
EOJS
        end
        if multi_indexed_presentation
          js = cond.generate_javascript_function(field_widget_map) 
          js = js.gsub('_X',"_#{MultiIndexMarker}")
          multi_index_jscripts << js
        else
          js = cond.generate_javascript_function(field_widget_map) 
          jscripts << js
        end
      end
      field_name_action_hash.each do |the_field_name,the_functions|
        (widget,widget_options) = field_widget_map[the_field_name];
        if @_multi_index_fields && @_multi_index_fields.keys && @_multi_index_fields.keys.flatten.include?(the_field_name)
          the_field_name_with_index = "_#{MultiIndexMarker}_#{the_field_name}"
          the_functions_for_this_presentation = ["#{special_fnname}_#{MultiIndexMarker}"]
          the_functions.each do |func|
            the_functions_for_this_presentation << func unless func =~ /#{special_fnname}/
          end
          the_functions_for_this_presentation = "#{the_functions_for_this_presentation.join('();')}();"
          recalculate_conditions_js_for_remove_function = %Q|values_for_#{the_field_name}[#{MultiIndexMarker}] = undefined;#{the_functions_for_this_presentation}|
          (0..@_any_multi_index).each do |i|
            i = MultiIndexMarker if i == @_any_multi_index #Use the last index to set up the general js for the indexed presentation Add button
            observe_functions = widget.javascript_build_observe_function(the_field_name_with_index,"values_for_#{the_field_name}[#{i}] = #{widget.javascript_get_value_function(the_field_name_with_index)};#{the_functions_for_this_presentation}",widget_options)
            if i == MultiIndexMarker
              observe_js_for_add_function = (observe_functions +';'+ multi_index_jscripts.join(";")).gsub(/\n/,'').gsub('_X',"_#{MultiIndexMarker}") +';'+ the_functions_for_this_presentation
            else
              jscripts << observe_functions.gsub(/#{MultiIndexMarker}/,i.to_s)
            end
          end
        else
          jscripts << widget.javascript_build_observe_function(the_field_name,"values_for_#{the_field_name}[cur_idx] = #{widget.javascript_get_value_function(the_field_name)};#{the_functions.join('();')}();",widget_options)
        end
      end
    end 
  
    b = get_body.join("\n")
    b.gsub!(/<info(.*?)>(.*?)<\/info>/) {|match| tip($2,$1)}

    if @_tip_id
      b = javascript_include_tag("prototip-min") + stylesheet_link_tag('prototip',:media => "screen")+b
    end

    js = get_jscripts
    jscripts << js if js
    b = '<script>var cur_idx=find_current_idx();' + stored_value_string + '</script>' + b if stored_value_string != '' && !presentations[presentation_name].force_read_only
    js = jscripts.join("\n")
    js.gsub!(/#{EventObserveMarker}/,observe_js_for_add_function) if observe_js_for_add_function != ''      
    js.gsub!(/#{RecalculateConditionsMarker}/,recalculate_conditions_js_for_remove_function) if recalculate_conditions_js_for_remove_function != ''      
    [b,js]
  end
end
    
  # build a field_name to widget mapping so that we can pass it into the conditions
  # to build the necessary javascript
  def current_questions_field_widget_map
    field_widget_map = {}
    get_current_questions.each do |q|
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
  # meta[:record] the record object
  # all parameters x from the form submission that are named as "meta[x]"
  # and anything put into it by a callback #meta_data_for_save defined in the application controller
  def do_workflow_action(action_name,meta)
    @_action_result = {}
    workflow_name = @record.workflow
    w = self.workflows[workflow_name]
    raise MetaformException,"unknown workflow #{workflow_name}" if !w
    a = w.actions[action_name]
    raise MetaformException,"unknown action #{action_name}" if !a
#    raise MetaformException,"'#{@_action_result[:next_state]}' is not a state defined in the '#{workflow_state}' workflow" if !w.states.keys.include?(@_action_result[:next_state])
    raise MetaformIllegalStateForActionError.new(workflow_state,action_name) if !a.legal_states.include?(:any) && !a.legal_states.include?(@record.workflow_state)
    a.block.call(meta)
    after_workflow_action(@_action_result,meta) if respond_to?(:after_workflow_action)
    @_action_result
  end
  
  #################################################################################
  #################################################################################
  # add a "tool tip"
  #################################################################################
  def tip(text="",hook_bottom = nil)
    return if !@render
    options = []
    text += yield if block_given?
    @_tip_id ||= 1
    tip_id = "tip_#{@_tip_id}"
    options << "hook: {target: 'bottomRight', tip: 'topLeft'}" if !hook_bottom.blank?
    option_string = options.size > 0 ? ",{ #{options.join(' , ')} }" : ""
    javascript %Q|new Tip('#{tip_id}',"#{quote_for_javascript(text)}"#{option_string})|
    @_tip_id += 1
    %Q|<img src="/images/info_circle.gif" alt="" id="#{tip_id}">|
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

  def field_valid(field_name,value = :get_from_form)
    field = fields[field_name]
    raise MetaformException, "couldn't find field #{field_name} in fields list" if field.nil?
    p = field.properties[0]
    value = field_value(field_name) if value == :get_from_form
    valid = p.evaluate(self,field,value).empty?
    valid
  end

  def field_value(field_name)
    raise MetaformException,"attempting to get field value of '#{field_name}' with no record" if @record.nil?
    field = fields[field_name]
    index = field[:indexed] ? @_index : 0
    #puts "field[:indexed] = #{field[:indexed].inspect}"
    #puts "field_name = #{field_name}, index = #{index.inspect}"
    @record[field_name,index]
  end
  
  def field_value_at(field_name,index)
    raise MetaformException,"attempting to get field value of '#{field_name}' with no record" if @record.nil?
    @record[field_name,index]
  end

  def field_state(field_name,index = -1)
    raise MetaformException,"attempting to get field state of '#{field_name}' with no record" if @record.nil?
    index = index == -1 ? @_index : index
    fi = @record.form_instance.field_instances.find_by_field_id_and_idx(field_name.to_s,index)
    fi ? fi.state : nil
  end
  
  #This method will call YAML.load if Rails has not already turned the string into a hash for us.
  def load_yaml(field_value)
    return {} if field_value.blank?
    field_value.is_a?(String) ? YAML.load(field_value) : field_value
  end
  
  #TODO-Eric or Lisa
  # this meta-information is not easily accessible in the same way that questions are, and probably
  # should be.  We need to formalize and unify the concept of meta or housekeeping information
  def record_workflow
    raise MetaformException,"attempting to get workflow with no record" if @record.nil?
    @record.workflow
  end

  def workflow_state
    raise MetaformException,"attempting to get workflow state with no record" if @record.nil?
    @record.workflow_state
  end

  def created_at
    raise MetaformException,"attempting to get created_at with no record" if @record.nil?
    @record.created_at
  end
  
  def updated_at
    raise MetaformException,"attempting to get updated_at with no record" if @record.nil?
    @record.updated_at
  end

  def created_by_id
    raise MetaformException,"attempting to get created_by_id with no record" if @record.nil?
    @record.created_by_id
  end
  
  def updated_by_id
    raise MetaformException,"attempting to get updated_by_id with no record" if @record.nil?
    @record.updated_by_id
  end
  
  def validating?
    @validating
  end
  
  def set_validating(val)
    @validating = val
  end
  
#  def in_phase(phase,record=nil)
#    with_record(record,phase) do
#      yield
#    end
#  end

  def with_record(record,render = false)
    old_render = @render
    old_record = @record
    @record = record
    @render = render
    result = yield
    @record = old_record
    @render = old_render
    result
  end
  
  def set_record(record)
    @record = record
  end

  def set_render(render)
    @render = render
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

  def get_current_questions
    raise MetaformException,"attempting to get current questions without a setup presentation." if @_stuff[:current_questions].nil?
   @_stuff[:current_questions].values
  end
  
  def get_current_field_names
    raise MetaformException,"attempting to get current field names without a setup presentation." if @_stuff[:current_questions].nil?
    @_stuff[:current_questions].keys
  end

  def get_current_question_by_field_name(field_name)
    raise MetaformException,"attempting to search for current question without a setup presentation." if @_stuff[:current_questions].nil?
    @_stuff[:current_questions][field_name]
  end

  def get_record
    @record
  end
  
  def hiding_js?
    @_hiding_js
  end
  
  #If the presentation currently being handled is multi_index, this will return true
  def use_multi_index?
    @_use_multi_index
  end
  #If any presentation is multi_index, this will return true
  def any_multi_index?
    @_any_multi_index 
  end
  
  def index
    @_index
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
  
  def dependent_fields(field)
    fields[field].dependent_fields
  end
  
  def workflow_state_label(workflow,workflow_state)
    workflow_state.blank? ? '' : workflows[workflow].label(workflow_state)
  end
  
  #################################################################################
  #################################################################################
  # loads all the files in the "forms" directory that end Form.rb as forms
  # and requires the rest
  def self.boot
  end
  
  def self.set_store(key,value)
    @@store[key] = value
  end
  
  def self.get_store(key)
    @@store[key]
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
    return if @@_loaded_helpers[file] == self.class
    @@_loaded_helpers[file] = self.class
    fn = Form.forms_dir+'/'+file
    file_contents = IO.read(fn)
    Form.class_eval(file_contents,fn)
  end
  
  def if_c(condition,condition_value=true)
    condition = make_condition(condition)
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
 
  ###########################################################
  def make_condition(condition)
    if condition.instance_of?(String)
      condition = c(condition)
    end
    raise MetaformException "condition must be defined" if !condition.instance_of?(Condition)
    condition
  end

  ###########################################################
  def evaluate_force_nil(field_name,index)
    field = fields[field_name]
    return nil unless field.force_nil
    field.force_nil.each do |condition,force_nil_fields,negate|
      condition = make_condition(condition)
      condition_value = condition.evaluate
      if negate ? !condition_value : condition_value
#        puts "FORCE NIL: condition #{condition.name} with negate: #{negate.to_s}"
        force_nil_fields.each do |f|
          #puts "    FORCING: #{f}"
          yield f
        end
      end
    end
  end
  
  ###########################################################
  # This method determines which field_instance states should
  # not be counted as invalid.  Override it for more complicated 
  # behaviors
  def validation_exclude_states
    'explained'
  end
 
  #################################################################################
  #################################################################################
  private
    
  ###########################################################
  # collects up html generated by the rendering calls in a presentation
  # during the build phase
  # returns what was added to the body
  def body(html)
    return if !@render
    @_stuff[:body] ||= []
    @_stuff[:body] << html
    html
  end

  ###########################################################
  # collects up javascripts generated by the rendering calls in a presentation
  def javascript(js)
    return if !@render
    @_stuff[:js] ||= []
    @_stuff[:js] << js
    js
  end
  
  ###############################################
  # for a given field, add a javascript boolean condition and the script to run if it's true
  # into the list of scripts that will be added to the end of the rendered form.
  def add_observer_javascript(condition_name,script,negate = false)
    #we collect up all the conditions/functions pairs by field because Event.Observer can
    # only be called once per field id.  Thus we have to collect all the javascript bits we want to execute on the
    # observed field, and then generate the javascript call to Event.Observe down in the #build method
    return if !@render
    @_stuff[:observer_js] ||= {}
    @_stuff[:observer_js][condition_name] ||= {:pos => [],:neg =>[]}
    @_stuff[:observer_js][condition_name][negate ? :neg : :pos] << script
  end

  ###########################################################
  # used to save and restore something in the stuff hash for a block call
  def save_context(*what)
    what.each do |stuff_item|
      @_contexts[stuff_item] ||= []
      current_item = @_stuff[stuff_item]
      @_contexts[stuff_item].push current_item
      @_stuff[stuff_item] = case current_item
      when Array
        []
      when Hash
        {}
      else
        nil
      end
    end
    yield
    the_stuff = nil
    what.each do |stuff_item|
      the_stuff = @_stuff[stuff_item]
      @_stuff[stuff_item] = @_contexts[stuff_item].pop
    end
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