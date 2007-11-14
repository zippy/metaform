######################################################################################
# this is the class that encapuslates an instance of a record of a meta-form
# i.e. it stands in front of the usual ActiveRecord model classes to provide the same
# type of interface for the controller and the views, but really it's pulling it's data
# from FormInstances and FieldInstances

require 'metaform/form_proxy'

class Record
  
  attr :form_instance
  attr :errors
  attr :attributes
  attr_accessor :action_result
  ######################################################################################
  # creating a new Record happens either because we pass in a given FormInstance
  # or we create a raw new one here

  def initialize(the_instance = nil,attributes = nil)
    @attributes = {}
    the_instance = FormInstance.new if !the_instance
    @form_instance = the_instance
    self.attributes= attributes if attributes
  end
  
  ######################################################################################
  # set the attributes from a hash that comes from the http PUT.
  def attributes= (attribs)
    @attributes = {}

    attribs.each do |id,value|
      id = id.to_s
      q = form.get_question(id)
      raise "unknown question #{id}" if !q
      @attributes[id] = Widget.fetch(q.appearance).convert_html_value(value)
    end
  end
  
  ######################################################################################
  # some paramaters are just those of the form instance object
  def id
    form_instance.id
  end
  
  def form
    form_instance.form
  end
  
  def workflow_state
    form_instance.workflow_state
  end
  
  def workflow_state=(new_state)
    form_instance.update_attribute(:workflow_state,new_state)
  end

  def workflow_state_name
    n = workflow_state
    n.nil? ? '' : n.titleize
  end

  ######################################################################################
  # field accessors

  # the field_value is either pulled from the attributes hash if it exists or from the database
  # TODO we need to make a system where field_instance values can be pre-loaded for a full presentation, otherwise
  # this causes one hit to the database per field per page.
  def [](attribute)
    field_name = attribute.to_s
    return @attributes[field_name] if @attributes.has_key?(field_name)
    raise "field #{field_name} not in form " if !form.field_exists?(field_name)
    if !@form_instance.new_record?  && field_instance = FieldInstance.find(:first, :conditions => ["form_instance_id = ? and field_id = ?",@form_instance.id,field_name])
      #cache the value in the attributes hash
      @attributes[field_name] = field_instance.answer
    else
      #TODO get the default from the definition if we aren't getting the value from the database
      nil
    end
  end
  
  def method_missing(attribute,*args)
    #is this an attribute setter?
    if attribute.to_s =~ /^(.*)=$/ && form.field_exists?($1)
      return @attributes[$1] = args[0]
    else
      #otherwise assume an attribute getter
      return self[attribute] if form.field_exists?(attribute)
    end
    super
  end

  ######################################################################################
  # return and or create ActiveRecord errors object
  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def build_tabs(tabs,current)
    form.build_tabs(tabs,current,@form_instance)
  end
  
  def build_html(presentation = 0,current=nil)
    
    f = FormProxy.new(form.name.gsub(/ /,'_'))
    if form.presentation_exists?(presentation)
      form.build(presentation,@form_instance,f)
#    p = form.find_presentation(presentation_id)
#    if p
#      p.build_html(f,self,current)
    else
      #TODO: fix this to be a user-friendly exception mechanism that logs errors and sends admins e-mails etc (i.e. see WAGN)
      raise "presentation #{presentation} not found"
    end
  end
    
  ######################################################################################
  # to save a record we have to update the form_instance info as well as update any
  # attributes
  # TODO here is another place where it's clear that things are wonky.  Mixing in the
  # workflow_action into the save function is odd.  
  def save(presentation = 0,meta_data = nil)
    #TODO we need to test this transactionality to see how it works if different parts
    # of the _update_attributes process fails.
    begin
      FormInstance.transaction do
        result = @form_instance.save
        if result
          result = _update_attributes(presentation,meta_data)
          raise "no new state" if !result
        end
        result
      end
    rescue Exception => e
      # if the error was a thrown inside _update_attributes then we should
      # rethrow it.  Otherwise we can just return false to the caller.
      #TODO make our own Exception class instead of just using the string value.
      raise e if e.to_s != "no new state"
      false
    end
  end
  
  ######################################################################################
  # To update the record attributes we have to update all the field instances objects
  # that are what actually are the "attributes."  The attributes parameter should be a 
  # hash where the keys are the FieldInstance ids and the values are the answers
  def update_attributes(attribs,presentation = 0,meta_data = nil)
    form.setup(presentation,@form_instance)
    self.attributes = attribs
    _update_attributes(presentation,meta_data)
  end

  def _update_attributes(presentation,meta_data)
    
    #TODO this is screwey right now because form.verify call has to come first
    # to initialize the form object so any actions taken will have all the 
    # data set up in the form.  This is part of how things are currently screwy and
    # form should be an instance created by new, which initializes all the data or
    # something like that.  i.e. form = V2Form.new(@presentation,@form_instance)
    # then all the stuff that is currently stored as a class variable in form
    # can be simple object instance variables.

    #TODO by moving the workflow action stuff to the begining here I've introduced a 
    # transactionality problem.  I.e. if the workflow changes state info and then the 
    # field instance values can't be saved, then the record is in a screwed up state.
    # Thus this stuff should be roll-backable in some way.  This may have been handled
    # by the transactionality handling I added up in save, but then we we should also add it to
    # to update_attributes.
    if meta_data && meta_data[:workflow_action] && meta_data[:workflow_action] != ''
      form.verify(presentation,@form_instance,@attributes)
      meta_data[:record] = self
      self.action_result = form.do_workflow_action(meta_data[:workflow_action],@form_instance,meta_data)
      if self.action_result[:next_state]
        form_instance.update_attributes({:workflow_state => self.action_result[:next_state]})
      else
        return false
      end
    else
      form.setup(presentation,@form_instance)
    end

    field_instances = @form_instance.field_instances.find(:all, :conditions => ["field_id in (?) and form_instance_id = ?",@attributes.keys,id])
		@attributes.each do |field_instance_id,value|
			raise "field '#{field_instance_id}' not in form" if !form.field_exists?(field_instance_id)
			f = field_instances.find {|field_instance| field_instance.attributes['field_id'] == field_instance_id}
			if f != nil
				f.answer = value				
			else
				f = FieldInstance.new({:answer => value, :field_id=>field_instance_id, :form_instance_id => id})
				field_instances << f
			end
			f.state = 'answered'		
		end
		    
    if errors.empty?
      FieldInstance.transaction do
        field_instances.each do |i|
          if !i.save 
    				errors.add(i.field_id,i.errors.full_messages.join(','))
          end
        end
      end

      form.submit(presentation,@form_instance)

      true
    else
      #TODO if there is a field instance that is invalid, i.e. for example because
      # the field is in a questions that is in group that is in a presentation that isn't
      # in a form, you'll see something very ugly.  Currently validate puts things in place
      # so that the standard rails error message shows up.  Note that this is different from
      # our own validation.
#      raise errors.inspect
      false
    end
  end  
  
  def logger
    form_instance.logger
  end
  
  def url(presentation,tab)
    Record.url(id,presentation,tab)
  end
    

  def self.human_attribute_name(attribute_key_name) #:nodoc:
    attribute_key_name
  end

  ######################################################################################
  ######################################################################################
  # CLASS METHODS
  ######################################################################################
  # Record.find just delegates to FormInstance.find
  def Record.find(parm,*rest)
    forms = FormInstance.find(parm,rest)
    Record.create(forms)
  end
  
  # Record.locate
  def Record.locate(what,options = {})
    condition_strings = []
    conditions_params = []
    
    field_list = {} 
    
    if options.has_key?(:forms)
      condition_strings << "(form_id in (?))"
      conditions_params << options[:forms]
    end
    if options.has_key?(:workflow_state_filter)
      condition_strings << "(workflow_state in (?))"
      conditions_params << options[:workflow_state_filter]
    end

    if options.has_key?(:filters)
      filters = arrayify(options[:filters])
      filters.each { |fltr| fltr.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1}}
    end
    if options.has_key?(:fields)
      condition_strings << "(field_id in (?))"
      options[:fields].each {|x| field_list[x] = 1 }
      conditions_params << field_list.keys
    end
    if options.has_key?(:conditions)
      c = arrayify (options[:conditions])
      c.each {|x| x =~ /([a-zA-Z0-9_-]+)(.*)/; condition_strings << %Q|if(field_id = '#{$1}',if (answer #{$2},true,false),false)|}
    end

    if !condition_strings.empty?
      condition_string = condition_strings.join(' and ')
      if !conditions_params.empty?
        conditions = [condition_string].concat(conditions_params)
      else
        conditions = condition_string
      end
      find_opts = {
        :conditions => conditions, 
        :include => [:field_instances]
      }
    end
    find_opts ||= {}
    
    form_instances = FormInstance.find(what,find_opts)
      
    if filters
      forms = []
      #TODO This has got to be way inneficient!  It would be much better to push this
      # off the SQL server, but I don't know how to do that yet in the context of rails
      # and the structure of having the field instances in their own tables.
      form_instances.each do |r|
        f = {'workflow_state' => r.workflow_state,'updated_at' => r.updated_at}
        r.field_instances.each {|fld| f[fld.field_id]=fld.answer}
        kept = false
        if filters.size > 0
          eval_field(filters.collect{|x| "(#{x})"}.join('&&')) {|expr| kept = eval(expr)}
        end
        forms << r if kept
      end
    else
      forms = form_instances
    end

    Record.create(forms)
  end
  
  def Record.eval_field(expression)
    begin
      expr = expression.gsub(/:([a-zA-Z0-9_-]+)/,'f["\1"]')
      yield expr
    rescue Exception => e
      raise "Eval error '#{e.to_s}' while evaluating: #{expr}"
    end
  end
  
  def Record.url(record_id,presentation,tab)
    url = "/records/#{record_id}"
    url << "/#{presentation}" if presentation != ""
    url << "/#{tab}" if tab
    url
  end
  
  def Record.create_url(form,presentation,current)
    url = "/forms/#{form}/records"
    url << "/#{presentation}" if presentation && presentation != ""
    url << "/#{current}" if current && current != ''
    url
  end
  
  def Record.listing_url(listing,order = nil)
    url = "/records/listings/#{listing}"
    url << "?search[order]=#{order}" if order && order != ''
    url
  end
  
  def Record.make(form_name,presentation,attribs = {})
    the_form = Form.find(form_name)
    #TODO there is a circularity problem here.  To set up the form we call it with a presentation
    # but part of the setup gets us the default presentation if we don't have one!

    #TODO this is more evidence that we don't have things right.  Currently a "form instance" is spread accross
    # Record, FormInstance, and "setting up" the class variables in V2Form to work correctly.  All this needs
    # to be unified, because right now there will be two calls to setup.  Once here "manually" and also later
    # in Record#update_attributes
    fi = FormInstance.new
    fi.form_id = the_form.to_s
    fi.workflow = the_form.workflow_for_new_form(presentation)
    the_form.setup(presentation,fi)
    @record = Record.new(fi,attribs)    
  end
  
  
  ######################################################################################
  # convienence class method to create a bunch of records from a single or a list of 
  # FormInstances
  def Record.create(records)
    if records.is_a?(Array)
      result = []
      records.collect{|r| result.push(Record.new(r))}
    else
      result = Record.new(records)
    end
    result
  end
  
  private
  def Record.arrayify(param)
    return [] if param == nil
    param = [param]  if param.class != Array
    param
  end
  
end
   