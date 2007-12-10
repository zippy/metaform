######################################################################################
# this is the class that encapuslates an instance of a record of a meta-form
# i.e. it stands in front of the usual ActiveRecord model classes to provide the same
# type of interface for the controller and the views, but really it's pulling it's data
# from FormInstances and FieldInstances

require 'metaform/form_proxy'

class Record
  
  attr :form_instance
  attr :errors
  attr_accessor :action_result
  ######################################################################################
  # creating a new Record happens either because we pass in a given FormInstance
  # or we create a raw new one here

  def initialize(the_instance = nil,attributes = nil,options = {})
    reset_attributes
    the_instance = FormInstance.new if !the_instance
    @form_instance = the_instance
    if attributes
      set_attributes(attributes,options)
    end
  end
  
  ######################################################################################
  # set the attributes from a hash optionally converting from HTML
  def set_attributes(attributes,options = {})
    reset_attributes
    
    if options[:multi_index]
      attribs = attributes
    else
      if options[:index]
        attribs = {options[:index].to_i=>attributes} 
      else
        attribs = {nil => attributes}
      end
    end
    convert_from_html = options[:convert_from_html]
    attribs.each do |index,a|
      a.each do |attribute,value|
        attribute = attribute.to_s
        # if we are converting from HTML then we assume that a presentation was
        # setup and we check to make sure that the questions exist in this presentation
        # as a santity check.  TODO.  This check should be moved elsewhere!!
        if convert_from_html
        	q = form.get_question(attribute)
          raise "unknown question #{attribute}" if !q
          value = Widget.fetch(q.appearance).convert_html_value(value,q.params)
        end
        set_attribute(attribute,value,index)
      end if a
    end
  end
  
  def attributes(index=nil)
    index = index.to_i if index
    @attributes[index]
  end
  def reset_attributes
    @attributes = {nil=>{}}
  end
  def attribute_exists(attribute,index=nil)
    index = index.to_i if index
    @attributes.has_key?(index) && @attributes[index].has_key?(attribute.to_s)
  end
  def get_attribute(attribute,index=nil)
    index = index.to_i if index
    i = @attributes[index]
    i ? i[attribute.to_s] : nil
  end
  def set_attribute(attribute,value,index=nil)
    index = index.to_i if index
    i = @attributes[index]
    @attributes[index] = i = {} if !i
    i[attribute.to_s] = value
  end
  ######################################################################################
  # some paramaters are just those of the form instance object
  def id
    form_instance.id
  end
  
  def form
    form_instance.form
  end

  def workflow
    form_instance.workflow
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
  
  # get the default field as definined in the form
  def field_label(field_name)
    form.fields[field_name].label
  end

  ######################################################################################
  # field accessors

  # the field_value is either pulled from the attributes hash if it exists or from the database
  # TODO we need to make a system where field_instance values can be pre-loaded for a full presentation, otherwise
  # this causes one hit to the database per field per page.
  def [](attribute,index=nil)
    field_name = attribute.to_s
    return get_attribute(field_name,index) if attribute_exists(field_name,index)
    raise "field #{field_name} not in form " if !form.field_exists?(field_name)
    if !@form_instance.new_record?      
      field_instance = nil 
      # The instance may already have been loaded in the instances from a Record.locate so check there first
      field_instance = nil
      @form_instance.field_instances.each do |fi|
        if fi.field_id == field_name && fi.idx == index
          field_instance = fi
          break
        end
      end
      field_instance ||= FieldInstance.find(:first, :conditions => ["form_instance_id = ? and field_id = ? and idx #{index ? '=' : 'is'} ?",@form_instance.id,field_name,index])
    end

    # use the database value or get the default value
    if field_instance
      value = field_instance.answer
    else
      if index && form.fields[field_name].arrayable_default_from_null_index
        value = self[attribute,nil]
      else
        value = form.fields[field_name].default
      end
    end
    #cache the value in the attributes hash
    set_attribute(field_name,value,index)
  end
  
  def []=(attribute,index=nil,value=nil)
    set_attribute(attribute,value,index)
  end
  
  def method_missing(method,*args)
    #is this an attribute setter? or questioner?
    a = method.to_s
    a =~ /^(.*?)(__([0-9]+))*([=?])*$/
    (attribute,index,action) = [$1,$3,$4]
    if form.field_exists?(attribute)
      case action
      when '?'
        val = self[attribute,index]
        return val && val != ''
      when '='
        return set_attribute(attribute,args[0],index)
      else
        #otherwise assume an attribute getter
        return self[attribute,index]
      end
    end
    super
  end
  
  ######################################################################################
  # return and or create ActiveRecord errors object
  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def build_tabs(tabs,current)
    form.build_tabs(tabs,current,self)
  end
  
  def build_html(presentation = 0,current=nil,index=nil)
    
    f = FormProxy.new(form.name.gsub(/ /,'_'))
    if form.presentation_exists?(presentation)
      form.build(presentation,self,f,index)
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
  def update_attributes(attribs,presentation = 0,meta_data = nil,options={})
    form.setup(presentation,self)
    set_attributes(attribs,options)
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
      form.verify(presentation,self,attributes)
      meta_data[:record] = self
      self.action_result = form.do_workflow_action(meta_data[:workflow_action],self,meta_data)
      if self.action_result[:next_state]
        form_instance.update_attributes({:workflow_state => self.action_result[:next_state]})
      else
        return false
      end
    else
      form.setup(presentation,self)
    end

    field_list = @attributes.values.collect {|a| a.keys}.flatten.uniq
    field_instances = @form_instance.field_instances.find(:all, :conditions => ["field_id in (?) and form_instance_id = ?",field_list,id])
    field_instances.each {|fi| logger.info("#{fi.answer} #{fi.idx.to_s} ZZZZZ" << fi.idx.class.to_s)}
    @attributes.each do |index,attribs|
  	  attribs.each do |field_instance_id,value|
  			raise "field '#{field_instance_id}' not in form" if !form.field_exists?(field_instance_id)
  			f = field_instances.find {|fi| fi.field_id == field_instance_id && fi.idx == index}
  			if f != nil
  				f.answer = value
  			else
  				f = FieldInstance.new({:answer => value, :field_id=>field_instance_id, :form_instance_id => id, :idx => index})
  				field_instances << f
  			end
  			f.state = 'answered'		
  		end
		end
		    
    if errors.empty?
      FieldInstance.transaction do
        field_instances.each do |i|
          if !i.save!
    				errors.add(i.field_id,i.errors.full_messages.join(','))
          end
        end
      end

#      form.submit(presentation,self)

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
  
  def url(presentation,tab=nil,index=nil)
    Record.url(id,presentation,tab,index)
  end
    

  def self.human_attribute_name(attribute_key_name) #:nodoc:
    attribute_key_name
  end

  def slice(*field_names)
    r = Record.locate(self.id,:index => :any, :fields => field_names)
    result = {}
    field_names.each {|a| result[a] = {}}

    r.form_instance.field_instances.collect do |fi| 
      result[fi.field_id][fi.idx] = fi.answer
    end
    result = result[field_names[0]] if field_names.size == 1
    result
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
    
    if options.has_key?(:index)
      idx = options[:index]
      if idx != :any
        condition_strings << "(idx #{idx ? '=' : 'is'} ?)"
        conditions_params << idx
      end
    else
      condition_strings << "(idx is null)"      
    end
    
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
    
    begin
      form_instances = FormInstance.find(what,find_opts)
    rescue 
      form_instances = nil
    end
      
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
  
  def Record.url(record_id,presentation,tab=nil,index=nil)
    url = "/records/#{record_id}"
    url << "/#{presentation}" if presentation != ""
    url << "/#{tab}" if tab
    url << "/#{index}" if index
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
  
  def Record.make(form_name,presentation,attribs = {},options ={})
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
    the_form.setup(presentation,nil)
    
    @record = Record.new(fi,attribs,options)    
  end
  
  
  ######################################################################################
  # convienence class method to create a bunch of records from a single or a list of 
  # FormInstances
  def Record.create(form_instances)
    if form_instances.is_a?(Array)
      result = []
      form_instances.each{|r| result.push(Record.new(r))}
    else
      result = Record.new(form_instances)
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
   