######################################################################################
# this is the class that encapuslates an instance of a record of a meta-form
# i.e. it stands in front of the usual ActiveRecord model classes to provide the same
# type of interface for the controller and the views, but really it's pulling it's data
# from FormInstances and FieldInstances

#require 'form_proxy'


class Record

  class Answer
    def initialize(val,index=nil)
      if index.instance_of?(String)
        index = index.split(/,/)
      else
        index = [index]
      end
      self[*index] = val
    end

    def value
      return nil if @value.size == 0
      return @value[0] if @value.size == 1
      return @value
    end

    def value=(val,index=nil)
      self[index] = val
    end
    
    def make_multi_dimensional(i1,i2)
      #puts "ANSWER#make_multi_dimensional i1 = #{i1.inspect}"
      #puts "ANSWER#make_multi_dimensional i2 = #{i2.inspect}"
      #puts "ANSWER#make_multi_dimensional @value = #{@value.inspect}"
      @value.collect! {|v| [v]} unless @value[0].instance_of?(Array)
      #puts "ANSWER#make_multi_dimensional @value = #{@value.inspect}"
      #puts "ANSWER#make_multi_dimensional i1.to_i = #{i1.to_i}"
      while @value.size <= i1.to_i
        #puts "ANSWER#make_multi_dimensional @value = #{@value.inspect}"
        @value << []
      end
    end
    
    def [](*index)
      make_multi_dimensional(*index) if index.size > 1
      if index.size == 0
        index = 0
        @value[index]
      elsif index.size == 1
        index = index[0].to_i
        @value[index]
      else
        @value[index[0].to_i][index[1].to_i]
      end
    end

    def []=(index,*args)
      # puts "----------------------"
      # puts "ANSWER#[]= index = #{index.inspect}, args = #{args.inspect}"
      @value ||= []
      #puts "ANSWER#[]= @value = #{@value.inspect}"
      val = args.pop
      if index && index.to_s.include?(',')
        index_array = index.split(',')
        while index_array.size > 1 
          args.unshift index_array.pop
        end
        index = index_array[0]
      end
      # puts "ANSWER#[]= index = #{index.inspect}, args = #{args.inspect}"
      
      #puts "ANSWER#[]= val = #{val.inspect}"
      #puts "ANSWER#[]= args = #{args.inspect}"
      if args.size == 0 && muilt_dimensional?
        #puts "ANSWER#[]= args.size == 0 && muilt_dimensional? is true"
        #puts "PUSHING"
        args.push 0
        #puts "ANSWER#[]= args = #{args.inspect}"
      end
      
      if args.size == 0
        #puts "ANSWER#[]= arbs.size == 0 is true"
        @value[index.to_i] = val
        #puts "ANSWER#[]= @value = #{@value.inspect}"
      else
        #puts "ANSWER#[]= arbs.size == 0 is NOT true"
        index2 = args.pop
        #puts "ANSWER#[]= index = #{index.inspect}"
        #puts "ANSWER#[]= index2 = #{index2}"
        make_multi_dimensional(index,index2)
        #puts "ANSWER#[]= index = #{index.inspect}"
        #puts "ANSWER#[]= index2 = #{index2.inspect}"
        @value[index.to_i][index2.to_i] = val        
      end
    end
    
    def size
      @value.size
    end
    
    # this probably needs to have yield block so that we can count any property
    # not just which ones aren't nil
    def count(expr = nil)
      answers = @value
      answers.map!{|answer| eval(expr)  ? answer : nil } if expr
      answers.compact.size 
    end
    
    def exists?
      self.size > 0
    end
    
    def each(&block)
      @value.each {|v| block.call(v)}
    end
    
    def zip(other_answer,&block)
      if !@value.nil? && !other_answer.value.nil?
        my_value = @value.instance_of?(Array) ? @value : [@value]
        other_value = other_answer.value.instance_of?(Array) ? other_answer.value : [other_answer.value]
        if block
          my_value.zip(other_value) {|a| block.call(a)} 
        else
          my_value.zip(other_value)
        end
      else
       [[nil,nil]]          
      end
    end
    
    def map(&block)
      if @value
        @value.map {|v| 
          block.call(v)}
      end
    end
    
    def include?(desired_value)
      @value.include?(desired_value)
    end
    
    def is_indexed?
      @value.size > 1
    end
    
    def muilt_dimensional?
      @value[0].instance_of?(Array)
    end
        
  end
  
  attr :form_instance
  attr :errors
  attr_accessor :action_result
  ######################################################################################
  # creating a new Record happens either because we pass in a given FormInstance
  # or we create a raw new one here

  def initialize(the_instance = nil,the_form = nil,attributes = nil,presentation_name=nil,options = {})
    #puts "INITIALIZE"
    #puts "the_instance = #{the_instance.inspect}"
    #puts "attributes = #{attributes.inspect}"
    #puts "options = #{options.inspect}"
    reset_attributes
    the_instance = FormInstance.new if !the_instance
    @form_instance = the_instance
    
    #TODO this is bogus!!
    #what about adding with_record here?  more bogusness
    if the_form.nil?
      the_form = get_cached_or_new_form(the_instance.form)
    end
      
    @form = the_form
    
    # if attributes
    #   set_attributes(attributes,options)
    # end
    set_attributes(attributes,presentation_name,options)
  end
  
  @@last_form_date = nil
  def get_cached_or_new_form(form_class)
    form_name = form_class.to_s
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
    the_form ||= form_class.new
  end
    
  ######################################################################################
  # set the attributes from a hash optionally converting from HTML
  def set_attributes(attributes,presentation_name,options = {})
    reset_attributes

    if options[:multi_index]
      attribs = attributes
      if attribs.has_key?(0)
        attribs[nil] = attribs[0]
        attribs.delete(0)
      end
    else
      if options[:index]
        idx = options[:index].to_i
        idx = nil if idx == 0
        attribs = {idx=>attributes}
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
        	q = form.get_presentation_question(presentation_name,attribute)
          raise MetaformException,"question #{attribute} was not found in presentation #{presentation_name}" if !q
          value = Widget.fetch(q.widget).convert_html_value(value,q.params)
        end
        set_attribute(attribute,value,index)
      end if a
    end
  end
  
  def attributes(index=nil)
    index = index.to_s if index
    @attributes[index]
  end
  def reset_attributes
    @attributes = {nil=>{}}
  end
  def attribute_exists(attribute,index=nil)
    #puts "attribute_exists @attributes = #{@attributes.inspect}"
    #puts "attribute_exists @index = #{@index.inspect}"
    index = index.to_s if index
    #puts "attribute_exists @index = #{@index.inspect}"
    @attributes.has_key?(index) && @attributes[index].has_key?(attribute.to_s)
  end
  def get_attribute(attribute,index=nil)
    index = index.to_s if index
    i = @attributes[index]
    i ? i[attribute.to_s] : nil
  end
  
  def set_attribute(attribute,value,index=nil,ignore_force_nil=false)
    attrib = attribute.to_s
    raise MetaformException,"you can't store a value to a calculated field" if form.fields[attrib].calculated
    index = normalize(index)
    i = @attributes[index]
    @attributes[index] = i = {} if !i
    i[attrib] = value
    if !ignore_force_nil && form.get_record  # TODO-Eric  This sucks and is bass-ackwards.
      fields = form.fields[attribute].force_nil_fields
      fields.each { |f| set_attribute(f,nil,index) } if fields
    end
    value
  end
  
  def answers_hash(*fields)
    h = {}
    fields = fields.collect {|f| f.to_s}
    fields.each do |field|
      a = Answer.new(nil,nil)
      h[field] = a
      @attributes.each do |index,values|
        if values.keys.include?(field)
          a[index]=values[field]
        end
      end
    end
    h
  end
  
  ######################################################################################
  # some paramaters are just those of the form instance object
  def id
    form_instance.id
  end
  
  def form
    @form
#    form_instance.form
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
  
  def created_at
    form_instance.created_at
  end
  
  def updated_at
    form_instance.updated_at
  end

  def created_by_id
    form_instance.created_by_id
  end
  
  def updated_by_id
    form_instance.updated_by_id
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
  # TODO the use of :any here is kind of weird and needs to be refactored out and unified with
  #  all the Answer stuff.  Also the way in which this code loads in the instances should be refactored
  #  into a generalized "load" function that can be shared with how Locate loads in information too.
  def [](attribute,*index)
    #puts "[] attribute = #{attribute.inspect}"
    #puts "[] index = #{index.inspect}"
    if index == [:any]
      index = :any
    else
      index = normalize(index)
    end
    field_name = attribute.to_s
    return get_attribute(field_name,index) if attribute_exists(field_name,index)
    raise MetaformUndefinedFieldError, field_name if !form.field_exists?(field_name)
    if c = form.fields[field_name].calculated
      return c[:proc].call(form,index)
    end
    
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
      conditions = ["form_instance_id = ? and field_id = ?",@form_instance.id,field_name]
      if index
        if index != :any
          conditions[0] <<  " and idx = ?"
          conditions << index
        end
      else
        conditions[0] <<  " and idx is null"
      end
      field_instances ||= FieldInstance.find(:all, :conditions => conditions)
    end

    # use the database value or get the default value
    if field_instances
      values = []
      field_instances.each do |field_instance|
        value = field_instance.answer
        #cache the value in the attributes hash
        values << set_attribute(field_name,value,field_instance.idx,true)
      end
      if index == :any
        values
      else
        values[0]
      end
    else
      index = nil if index == :any
      if index && form.fields[field_name].indexed_default_from_null_index
        value = self[attribute,nil]
      else
        value = form.fields[field_name].default
      end
      #cache the value in the attributes hash
      set_attribute(field_name,value,index,true)
    end
  end
  
  def []=(attribute,*args)
    value = args.pop
    set_attribute(attribute,value,args)
  end
  
  def method_missing(method,*args)
    #is this an attribute setter? or questioner?
    a = method.to_s
    a =~ /^(.*?)(__([^=?]))*([=?])*$/
    (attribute,index,action) = [$1,$3,$4]
    if form.field_exists?(attribute)
      case action
      when '?'
        val = self[attribute,index]
        return val && val != ''
      when '='
        value = args[0]
        return set_attribute(attribute,value,index)
      else
        #otherwise assume an attribute getter
        return self[attribute,index]
      end
    end
    super
  end
  
  def normalize(index)
    if index.instance_of?(Array)
      index.pop while index.size > 0 && (index[-1] == '' || index[-1] == 0 || index[-1] == nil ) 
    end
    if index.instance_of?(Array)
      if index.size == 0
        index = nil
      else
        index = index.join(',')
      end
    elsif index 
      if index.size == 0 || index == [nil] || index == ""
        index = nil
      else
        index = index.to_s
      end
    end
    index
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
    if form.presentation_exists?(presentation)
      form.build(presentation,self,index)
#    p = form.find_presentation(presentation_id)
#    if p
#      p.build_html(f,self,current)
    else
      #TODO: fix this to be a user-friendly exception mechanism that logs errors and sends admins e-mails etc (i.e. see WAGN)
      raise MetaformException, "presentation #{presentation} not found"
    end
  end
    
  ######################################################################################
  # to save a record we have to update the form_instance info as well as update any
  # attributes
  # TODO here is another place where it's clear that things are wonky.  Mixing in the
  # workflow_action into the save function is odd.  
  def save(presentation = 0,meta_data = nil)
    #puts "SAVE presentation = #{presentation.inspect}"
    #puts "SAVE meta_data = #{meta_data.inspect}"
    #puts "SAVE  @form_instance = #{@form_instance.inspect}"
    #puts "SAVE  @attributes = #{@attributes.inspect}"
    #puts "SAVE self = #{self.inspect}"
    #TODO we need to test this transactionality to see how it works if different parts
    # of the _update_attributes process fails.
    begin
      FormInstance.transaction do
        result = @form_instance.save
        #puts "result = #{result.inspect}"
        if result
          result = _update_attributes(presentation,meta_data)
          raise "no new state" if !result
        end
        #puts "SAVE self = #{self.inspect}"
        #puts "Errors #{self.errors.full_messages.inspect}"
        #puts "Errors #{self.errors.empty?}"
        
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
#    form.setup(presentation,self)
    set_attributes(attribs,presentation,options)
    if zap_fields = options[:clear_indexes]
      FieldInstance.destroy_all(["form_instance_id = ? and field_id in (?)",@form_instance.id,zap_fields])
    end
    _update_attributes(presentation,meta_data)
  end

  def _update_attributes(presentation,meta_data)
    
    #TODO by moving the workflow action stuff to the begining here I've introduced a 
    # transactionality problem.  I.e. if the workflow changes state info and then the 
    # field instance values can't be saved, then the record is in a screwed up state.
    # Thus this stuff should be roll-backable in some way.  This may have been handled
    # by the transactionality handling I added up in save, but then we we should also add it to
    # to update_attributes.
    if meta_data && meta_data[:workflow_action] && meta_data[:workflow_action] != ''
      meta_data[:record] = self
      form.with_record(self,:workflow_action) do
        self.action_result = form.do_workflow_action(meta_data[:workflow_action],meta_data)
      end
      if self.action_result[:next_state]
        form_instance.update_attributes({:workflow_state => self.action_result[:next_state]})
      else
        return false
      end
    else
#      form.setup(presentation,self)
    end

    #TODO scalability.  This could be responsible for slowness.  Why check all the indexes!?!
    field_list = @attributes.values.collect {|a| a.keys}.flatten.uniq
    field_instances = @form_instance.field_instances.find(:all, :conditions => ["field_id in (?) and form_instance_id = ?",field_list,id])
#    field_instances.each {|fi| logger.info("#{fi.answer} #{fi.idx.to_s} ZZZZZ" << fi.idx.class.to_s)}
    @attributes.each do |index,attribs|
  	  attribs.each do |field_instance_id,value|
        raise MetaformException,"field '#{field_instance_id}' not in form" if !form.field_exists?(field_instance_id)
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
    # puts "--------------"
    # puts "slice:  field_names = #{field_names.inspect}"
    r = Record.locate(self.id,:index => :any, :fields => field_names)
    # puts "slice:  r = #{r.inspect}"
    result = {}
    field_names.each {|a| result[a] = {}}
    r.form_instance.field_instances.collect do |fi| 
      result[fi.field_id][fi.idx] = fi.answer
    end
    result = result[field_names[0]] if field_names.size == 1
    # puts "result = #{result.inspect}"
    result
  end
  
  def answer_num(field,answer,index=nil)
    # puts "---------"
    # puts "answer_num: field = #{field.inspect}"
    # puts "answer_num: answer = #{answer.inspect}"
    # puts "answer_num: index = #{index.inspect}"
    # puts "answer_num: self.id = #{self.id}"
    r = Record.locate(self.id,:index => :any,:fields => [field], :return_answers_hash => true)
    if r
      if index
        r[field].value.map{ |a| a[index] }.delete_if {|x| x != answer}.size
      else
        r[field].value.delete_if{ |x| x != answer}.size
      end
    end
  end
  
  def last_answer(field,index=nil)
    r = Record.locate(self.id,:index => :any,:fields => [field], :return_answers_hash => true)
    if r
      if index
        r[field].value.map{ |a| a[index] }.compact[-1]
      else
        r[field].value.compact[-1]
      end
    end
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
    #puts "----------"
    #puts "begin Record.locate"
    #puts "what = #{what.inspect}"
    #puts "options = #{options.inspect}"
    condition_strings = []
    conditions_params = []
    
   #puts "searching for #{what} options = " + options.inspect
    
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
    #puts "condition_strings = #{condition_strings}"
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
    #puts "find_opts = #{find_opts.inspect}"
    begin
      form_instances = FormInstance.find(what,find_opts)
    rescue
      form_instances = nil
    end
        
    return_answers_hash = options.has_key?(:return_answers_hash)
    
    forms = []
    #puts "1 form_instances = #{form_instances.inspect}"
    #puts "filters = #{filters.inspect}"
    #puts "return_answers_hash = #{return_answers_hash}"
    if form_instances && (filters || return_answers_hash)
      #puts "after if"
        if !form_instances.respond_to?('each')
          form_instances = [form_instances]
          did_it = true
          #puts "DID IT"
        end
      filter_eval_string = filters.collect{|x| "(#{x})"}.join('&&') if filters
      #TODO test for scalability on large datatsets
      #puts "next line"
      #puts "2 form_instances = #{form_instances.inspect}"
      form_instances.each do |r|
        #puts "r = #{r.inspect}"
        f = {'workflow_state' => Answer.new(r.workflow_state),'updated_at' => Answer.new(r.updated_at)}
        #puts "1:  f = #{f.inspect}"
        #puts "r.field_instances = #{r.field_instances.inspect}"
        r.field_instances.each do |field_instance|
          #puts "field_instance = #{field_instance.inspect}"
          #puts "key: #{field_instance.field_id}, answer: #{field_instance.answer}, idx: #{field_instance.idx}"
          if f.has_key?(field_instance.field_id)
            #puts "f.has_key?  TRUE field_instance.field_id #{field_instance.field_id}"
            a = f[field_instance.field_id]
            #puts "a = #{a.inspect}"
            #puts "field_instance.idx = #{field_instance.idx}"
            #puts "field_instance.answer = #{ field_instance.answer}"
            a[field_instance.idx] = field_instance.answer
            #puts "a = #{a.inspect}"
          else
            #puts "f.has_key? FALSE field_instance.field_id #{field_instance.field_id}"
            #puts "field_instance = #{field_instance.inspect}"
            #puts "field_instance.answer = #{field_instance.answer.inspect}"
            #puts "field_instance.idx = #{field_instance.idx.inspect}"
            f[field_instance.field_id]= Answer.new(field_instance.answer,field_instance.idx)
            #puts "f[#{field_instance.field_id}] = #{f[field_instance.field_id].inspect}"
          end
          #puts "!!! f[field_instance.field_id] = #{f[field_instance.field_id].inspect}"
        end
        field_list.keys.each {|field_id| f[field_id] = Answer.new(nil,nil) if !f.has_key?(field_id)}
        the_form = return_answers_hash ? f : r
        # puts "2:  f = #{f.inspect}"
        # puts "r = #{r.inspect}"
        if filters && filters.size > 0
          kept = false
          begin
            expr = eval_field(filter_eval_string)
            kept = eval expr
          rescue Exception => e
            raise MetaformException,"Eval error '#{e.to_s}' while evaluating: #{expr}"
          end
          forms << the_form if kept
        else
          forms << the_form
        end
      end
      forms = forms[0] if forms.length == 1 && did_it
    else
      forms = form_instances
    end
    #puts "forms = #{forms.inspect}"
    return forms if return_answers_hash
    Record.create(forms)
  end
  def Record.eval_field(expression)
#      #puts "---------"
#      #puts "eval_Field:  expression=#{expression}"
    expr = expression.gsub(/:([a-zA-Z0-9_-]+)\.(size|exists\?|count|is_indexed\?|each|zip|map|include\?)/,'f["\1"].\2')
#      #puts "eval_field:  expr=#{expr}"
    expr = expr.gsub(/:([a-zA-Z0-9_-]+)\./,'f["\1"].value.')
#      #puts "eval_field:  expr=#{expr}"
    expr = expr.gsub(/:([a-zA-Z0-9_-]+)\[/,'f["\1"][')
#      #puts "eval_field:  expr=#{expr}"
    if /\.zip/.match(expr)
      expr = expr.gsub(/\.zip\(:([a-zA-Z0-9_-]+)/,'.zip(f["\1"]')
    else
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)/,'(f["\1"].is_indexed? ? f["\1"].value[0] : f["\1"].value)')
    end
      # #puts "eval_field:  expr=#{expr}"
#      #puts "---------"
    expr
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
  
  def Record.make(the_form,presentation,attribs = {},options ={})
    #puts "RECORD.make attribs = #{attribs.inspect}"
    #TODO there is a circularity problem here.  To set up the form we call it with a presentation
    # but part of the setup gets us the default presentation if we don't have one!

    #TODO this is more evidence that we don't have things right.  Currently a "form instance" is spread accross
    # Record, FormInstance, and "setting up" the class variables in W30L to work correctly.  All this needs
    # to be unified, because right now there will be two calls to setup.  Once here "manually" and also later
    # in Record#update_attributes
    fi = FormInstance.new
    #puts "Record.make fi = #{fi.inspect}"
    fi.form_id = the_form.class.to_s
    fi.workflow = the_form.workflow_for_new_form(presentation)
#    the_form.setup(presentation,nil)
    #puts "Record.make fi = #{fi.inspect}"
    #puts "Record.make attribs = #{attribs.inspect}"
    #puts "Record.make options = #{options.inspect}"
    
    @record = Record.new(fi,the_form,attribs,presentation,options)    
  end
  
  
  ######################################################################################
  # convienence class method to create a bunch of records from a single or a list of 
  # FormInstances
  def Record.create(form_instances)
    #puts "Record.create form_instances = #{form_instances.inspect}"
    if form_instances.is_a?(Array)
      #puts "Record.create is_a?(Array) is true"
      result = []
      form_instances.each{|r| result.push(Record.new(r))}
    else
      #puts "Record.create is_a?(Array) is false"
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
   