######################################################################################
# this is the class that encapuslates an instance of a record of a meta-form
# i.e. it stands in front of the usual ActiveRecord model classes to provide the same
# type of interface for the controller and the views, but really it's pulling it's data
# from FormInstances and FieldInstances

#require 'form_proxy'

DEBUG1 = false
CACHE = false  #Note:  Didn't implment using :index for call to @ficache.clear in def delete_fields

class Record
  include Utilities
  class << self
    include Utilities
  end
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
    
    def each_with_index(&block)
      @value.each_with_index {|v,i| block.call(v,i)}
    end
    
    def to_i
      @value.compact.inject(0){|s,v| s += v.to_i}
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
    
    def any?(*desired_values)
       desired_values.any?{|x| @value.any?{|y| y && y.include?(x)}}
    end
    
    def other?(*undesired_values)
      !@value.to_s.blank? && !undesired_values.any?{|x| @value.any?{|y| y && y.include?(x)}}
    end
    
    def is_indexed?
      @value.size > 1
    end
    
    def muilt_dimensional?
      @value[0].instance_of?(Array)
    end
    
    def blank?
      return true if @value.nil?
      @value.compact.delete_if{|v| v == ""}.blank?
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

        
  end
  
class AnswersHash < Hash
  
  def answer_num(field,answer,other_than = false)
    raise "You can not request the answer_num for a nil or empty string answer" if answer.blank?
    answers = self[field].value
    answers = [answers] if answers.is_a?(String)
    return 0 if !answers
    if other_than
      answers.find_all{ |x| x != answer}.size
    else
      answers.find_all{ |x| x == answer}.size
    end
  end
  
  def method_missing(method,*args)
    a = method.to_s
    if self.has_key?(a)
      return self[a].value[args[0]] if args.size > 0  #If there is an arg, assume it's the index we want from the value of the Answer.
      return self[a].value
    end
    super
  end
end
  
  attr :form_instance
  attr :errors
  attr_accessor :action_result,:cache
  ######################################################################################
  # creating a new Record happens either because we pass in a given FormInstance
  # or we create a raw new one here

  def initialize(the_instance = nil,the_form = nil,attributes = nil,presentation_name=nil,options = {})
    @cache = RecordCache.new
    @ficache = RecordCache.new if CACHE
    the_instance = FormInstance.new if !the_instance
    @form_instance = the_instance
  
    #TODO this is bogus!!
    #what about adding with_record here?  more bogusness
    if the_form.nil?
      the_form = Form.make_form(the_instance.form.to_s)
    end
      
    @form = the_form
    
    if attributes
      set_attributes(attributes,presentation_name,options)
    end
  end

  ######################################################################################
  # set the attributes from a hash optionally converting from HTML
  def set_attributes(attributes,presentation_name,options = {})
#    reset_attributes
    @form.setup_presentation(presentation_name,self ,options[:index])

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
        	q = form.get_current_question_by_field_name(attribute)
          raise MetaformException,"question #{attribute} was not found in presentation #{presentation_name}" if !q
          value = Widget.fetch(q.widget).convert_html_value(value,q.params)
        end
        set_attribute(attribute,value,index)
      end if a
    end
  end

    def trace
      caller[1..3].collect {|l| l.gsub('/Users/eric/Coding/Consulting/MANA/MetaForm/git/manastats/vendor/plugins/metaform/lib/metaform/','')}.inspect
    end

  def reset_attributes
    puts "<br>RESETTING Attributes #{trace}" if DEBUG1
    @cache.clear
    @ficache.clear if CACHE
    @record_loaded = false
  end 
  
  def set_attribute(attribute,value,index=0,load_calculated_fields=false)
    raise "whoops index was :any" if index == :any
    attrib = attribute.to_s
    raise MetaformUndefinedFieldError, attrib if !form.field_exists?(attrib)
    return if form.fields[attrib].calculated && !load_calculated_fields
#    raise MetaformException,"you can't store a value to a calculated field (#{attrib})" if form.fields[attrib].calculated
    @cache.set_attribute(attribute,value,index)
    value
  end
  
  def answers_hash(*fields)
    h = {}
    fields = fields.collect {|f| f.to_s}
    fields.each do |field|
      a = Answer.new(nil,nil)
      h[field] = a
      @cache.each(:attributes => field) do |attribute,value,index|
        a[index]=value
      end
    end
    h
  end
  
  def delete_fields(idx,*fields)
    if idx == :all
      FieldInstance.destroy_all(["form_instance_id = ? and field_id in (?)",@form_instance.id,fields])
    else
      FieldInstance.destroy_all(["form_instance_id = ? and field_id in (?) and idx = ?",@form_instance.id,fields,idx])
    end
    opts = {:attributes => fields}
    opts.update(:index => idx) if idx != :all
    @cache.clear(opts)
    @ficache.clear(:attributes => fields)  if CACHE  
  end

  def delete_fields_except(*fields)
    FieldInstance.destroy_all(["form_instance_id = ? and field_id not in (?)",@form_instance.id,fields])
    @cache.clear(:attributes => fields,:except => true)
    @ficache.clear(:attributes => fields,:except => true) if CACHE
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

  def workflow_state_label
    @form.workflow_state_label(workflow,workflow_state)
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
  # Load attributes from the database, setting items to nil if they aren't found in dabase
  # the index parameter can be :any if all indexes should be loaded.
  def load_attributes(fields,index = 0,reset = true)
    reset_attributes if reset
    if index == :any
      field_instances = @form_instance.field_instances.find(:all,:conditions => "state != 'calculated'")
      _load_attributes(field_instances,fields,nil)
    else
      index = index.to_i
      field_instances = @form_instance.field_instances.find(:all,:conditions => ["state != 'calculated' and idx = ?",index])
      _load_attributes(field_instances,fields,index)
    end
    field_instances
  end
  
  def _load_attributes(field_instances,fields,index)
    fields_found = []
    field_instances.each do |fi|
      fields_found << fi.field_id
      set_attribute(fi.field_id,fi.answer,fi.idx)
    end
    _set_nil_attributes(fields-fields_found,index)
  end
  
  def _set_nil_attributes(fields,index=0)
    index = 0 if index == :any
    fields.each {|f| set_attribute(f,nil,index)}
  end
  
  ######################################################################################
  # Load attributes from the database
  def load_record(fields=nil,index=nil,force = false,load_calculated_fields = false)
    return if !force && (@record_loaded || @form_instance.new_record?)
    puts "<br>LOADING RECORD" if DEBUG1
#    reset_attributes if !fields
    @record_loaded = true if !fields
    conditions = []
    conditions << "state != 'calculated'" unless load_calculated_fields
    condition_params = []
    if fields
      conditions << "field_id in (?)"
      condition_params << fields
    end
    if index && index != :any
      conditions << "idx = ?"
      condition_params << index
    end
    #    field_instances = @form_instance.field_instances.find(:all, :conditions => ["field_id in (?) and form_instance_id = ?",field_list,id])

    instances = @form_instance.field_instances.find(:all,:conditions => [conditions.join(' and ')].concat(condition_params))
    attributes_set = {}
    instances.each do |fi|
      next if !form.field_exists?(fi.field_id)
      set_attribute(fi.field_id,fi.answer,fi.idx,load_calculated_fields)
      @ficache.set_attribute(fi.field_id,fi,fi.idx) if CACHE
      attributes_set[fi.field_id] ||= []
      attributes_set[fi.field_id] << fi.idx
    end
    if fields
      if index == :any
        fields.each {|f| set_attribute(f,nil) if !attributes_set.has_key?(f)}
      else
        fields.each {|f| set_attribute(f,nil,index) if !attributes_set.has_key?(f) || (!index.nil? && !attributes_set[f].include?(index))}
      end
    end
  end

  ######################################################################################
  # field accessors

  # the field_value is either pulled from the attributes hash if it exists or from the database
  # TODO the use of :any here is kind of weird and needs to be refactored out and unified with
  #  all the Answer stuff.  Also the way in which this code loads in the instances should be refactored
  #  into a generalized "load" function that can be shared with how Locate loads in information too.
  def [](attribute,index=0)
#    puts "[#{attribute.to_s},#{index.to_s}]<br>"
    attribute = attribute.to_s
    load_record

    if c = form.fields[attribute].calculated
      form.set_record(self)
      if index == :any
        last_index = @cache.indexes.pop
        result = []
        (0..last_index).each{|i|result << c[:proc].call(form,i)}
        return result
      else
        return c[:proc].call(form,index)
      end
    end
    
    if @cache.attribute_exists?(attribute,index)
#      puts "<br> loading #{attribute}[#{index}] from cache"
      @cache.get_attribute(attribute,index)
    else
#      puts "<br> loading #{attribute}[#{index}] from DB"
      was_any = false
      if index == :any
        index = nil
        was_any = true
      end
      if index && form.fields[attribute].indexed_default_from_null_index
        value = self[attribute,nil]
      else
        value = form.fields[attribute].default
      end
      #cache the value in the attributes hash
      set_attribute(attribute,value,index)
      was_any ? [value] : value
    end
  end
  
  def []=(attribute,*args)
    value = args.pop
    index = args[0]
    set_attribute(attribute,value,index)
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
  
  ######################################################################################
  # return and or create ActiveRecord errors object
  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def build_tabs(tabs,current)
    form.build_tabs(tabs,current,self)
  end
  
  def build_html(presentation = 0,index=nil)
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
  def save(presentation,meta_data = nil)
    #puts "SAVE presentation = #{presentation.inspect}"
    #puts "SAVE meta_data = #{meta_data.inspect}"
    #puts "SAVE  @form_instance = #{@form_instance.inspect}"
    #puts "SAVE self = #{self.inspect}"
    #TODO we need to test this transactionality to see how it works if different parts
    # of the _update_attributes process fails.
    @record_loaded = true
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
  def update_attributes(attribs,presentation,meta_data = nil,options={})
    # puts "attribs = #{attribs.inspect}"
    # puts "presentation = #{presentation.inspect}"
    # puts "meta_data = #{meta_data.inspect}"
    # puts "options = #{options.inspect}"
    
    result = nil
    #puts "BENCHMARK"+ Benchmark.measure {
    load_record #pulls in everything from the database into record cache called @cache
    extra_validate_fields = []
     if zap_fields = options[:clear_indexes]
       delete_fields(:all,*zap_fields)
       extra_validate_fields.concat(zap_fields)
     end
    preflight_state = []
    zap_fields = {}
    if @form.zapping_proc
      @form.with_record(self)  do
        preflight_state = @form.zapping_proc[:preflight_state].call(form)
      end
    end    
    set_attributes(attribs,presentation,options) 
    if @form.zapping_proc
      @form.with_record(self)  do
        zap_fields = @form.zapping_proc[:fields_hit].call(form,preflight_state)
      end
    end
    if zap_fields
      zap_fields.each do |idx,fields|
        delete_fields(idx,*fields)
        extra_validate_fields.concat(fields)
      end
    end    
    if options[:multi_index]
      index = :any
      fields = []
      attribs.each {|idx,a| fields << a.keys}
      fields = fields.flatten.uniq
    else
      fields = attribs.nil? ? nil : attribs.keys
    end
    index ||= options[:index]
    extra_validate_fields.uniq!
    result=_update_attributes(presentation,meta_data,fields,index,extra_validate_fields)
    #}.to_s
    result
  end

  def _update_attributes(presentation,meta_data,fields=nil,idx=0,extra_validate_fields=nil)
    # determine if this presentation is allowed to be used for updating the 
    # record in the current state
    puts "<br>CACHE on entrance to _update_attributes: #{@cache.dump.inspect}" if DEBUG1
    p = @form.presentations[presentation]
    p.confirm_legal_state!(workflow_state)
    invalid_fields = nil
    validation_exclude_states = nil
    
    if fields
      field_list = fields.collect { |f| f.to_s }
    else
      field_list = @cache.attribute_names
    end
    @form.with_record(self) do
      # force any attributes to nil that need forcing
      field_list.concat set_force_nil_attributes(field_list)

      # evaluate the validity of the attributes to be saved
      invalid_fields = _validate_attributes(field_list)
      p.invalid_fields = invalid_fields
      validation_exclude_states = form.validation_exclude_states
    end

    # if presentation requires valid data before saving it then return
    if p.validation == :before_save && invalid_fields.size > 0
      @form.set_validating(:no_explanation)
      return false
    end
    #TODO by moving the workflow action stuff to the begining here I've introduced a 
    # transactionality problem.  I.e. if the workflow changes state info and then the 
    # field instance values can't be saved, then the record is in a screwed up state.
    # Thus this stuff should be roll-backable in some way.  This may have been handled
    # by the transactionality handling I added up in save, but then we we should also add it to
    # to update_attributes.
    if meta_data && meta_data[:workflow_action] && meta_data[:workflow_action] != ''
      form.with_record(self) do
        self.action_result = form.do_workflow_action(meta_data[:workflow_action],meta_data)
      end
      if self.action_result[:next_state]
        attrs = {:workflow_state => self.action_result[:next_state]}
        if self.action_result[:update_validation_data]
          vd = form_instance.get_validation_data
          vd.update(self.action_result[:update_validation_data])
          attrs[:validation_data] = vd
        end
        form_instance.update_attributes(attrs)
      else
        return false
      end
    else
#      form.setup(presentation,self)
    end

    explanations = meta_data[:explanations] if meta_data
    approvals = meta_data[:approvals] if meta_data

#    field_instances = @form_instance.field_instances.find(:all, :conditions => ["field_id in (?) and form_instance_id = ?",field_list,id])
#    field_instances.each {|fi| logger.info("#{fi.answer} #{fi.idx.to_s} ZZZZZ" << fi.idx.class.to_s)}
    field_instances_to_save = []
    if meta_data && meta_data[:last_updated]
      last_updated =  meta_data[:last_updated].to_i
      field_instances_protected = []
    end
    calculated_fields_to_update = {}
    states = {}
    @cache.each do |field_instance_id,value,index|
      #TODO change this to confirm that field_instance_id is in the current presentation.  We
      # shouldn't be updating fields against the workflow rules.
      raise MetaformException,"field '#{field_instance_id}' not in form" if !form.field_exists?(field_instance_id)
#      f = field_instances.find {|fi| fi.field_id == field_instance_id && fi.idx == index}
      f = FieldInstance.find(:first, :conditions=>["form_instance_id = ? and field_id = ? and idx = ?",form_instance.id,field_instance_id,index]) if !CACHE
      f = @ficache.get_attribute(field_instance_id,index) if CACHE
      has_explanation = explanations && explanations[field_instance_id] && explanations[field_instance_id].has_key?(index.to_s)
      explanation_value = explanations[field_instance_id][index.to_s] if has_explanation
      is_approval = approvals && approvals[field_instance_id]
      approval_value = approvals[field_instance_id][index.to_s] if is_approval
      if f != nil
        if f.answer != (value.nil? ? nil : value.to_s) || (has_explanation && f.explanation != explanation_value) ||
            (is_approval && approval_value)
          # if we are checking last_updated dates don't do the update if the fields updated_at
          # is greater than the last_updated date passed in, and store this to report later
          if last_updated && f.updated_at.to_i > last_updated
            field_instances_protected << f
          else
            f.answer = value
            f.explanation = explanation_value if has_explanation
            field_instances_to_save << f
          end
        end
      else
        puts "<br>Creating new fi for #{field_instance_id}" if DEBUG1
        f = FieldInstance.new({:answer => value, :field_id=>field_instance_id, :form_instance_id => id, :idx => index})
        @ficache.set_attribute(field_instance_id,f,index) if CACHE
        f.explanation = explanation_value if has_explanation
        field_instances_to_save << f
      end
      if @form.calculated_field_dependencies[field_instance_id]
        calculated_fields_to_update[index] ||= []
        calculated_fields_to_update[index] << @form.calculated_field_dependencies[field_instance_id]
      end
      if (invalid_fields[field_instance_id] && invalid_fields[field_instance_id][index])
        if is_approval
          f.state = approval_value.blank? ? 'explained' : 'approved'
        else
          f.state = (!has_explanation || explanation_value.blank?) ? 'invalid' : 'explained'
        end
      else
        f.state = 'answered'
      end
      states[field_instance_id] ||= []
      states[field_instance_id][index] = f.state
    end

		# only save field instances if there were no errors and if any of the attributes were actually any
		# different from what they previously were.
    if errors.empty?
      saved_attributes = {}
      if !field_instances_to_save.empty?
    		dependents = []
        FieldInstance.transaction do
          field_instances_to_save.each do |i|
            deps = @form.dependent_fields(i.field_id)
            dependents.concat(deps) if deps
            saved_attributes[i.field_id] = i.answer
            if (i.answer == nil || i.answer == '') && i.state== 'answered' && i.explanation.blank? && i.idx == 0
              puts "<br>about to delete #{i.attributes.inspect}" if DEBUG1
              i.delete unless i.new_record?
            else
              puts "<br>about to save #{i.attributes.inspect}" if DEBUG1
              if !i.save!
                errors.add(i.field_id,i.errors.full_messages.join(','))
              end
            end
          end
        end
        vd = form_instance.get_validation_data #This holds the validation information which is presented in
        #red at the top of a form.
        
        # any dependents and fields that were passed in for validation (usually because the were cleared
        # by a zapping ropt) that aren't being updated in this group of attributes must have
        # their validity status updated too.
        dependents.concat(extra_validate_fields).uniq! if extra_validate_fields
        deps_to_check = dependents-field_list
        if !deps_to_check.empty?
          load_attributes(deps_to_check,idx,false)
          @form.with_record(self) do
            invalid_deps = _validate_attributes(deps_to_check)
            invalid_fields.update(invalid_deps)
          end
          invalid_field_list = field_list+deps_to_check
        else
          invalid_field_list = field_list
        end
        _merge_invalid_fields(vd,invalid_field_list,invalid_fields,idx)
        _update_presentation_error_count(vd,presentation,idx,states,validation_exclude_states)

        if !calculated_fields_to_update.empty?
          form.with_record(self) do
            update_calculated_fields(calculated_fields_to_update)
          end
        end
        ok = form_instance.update_attributes({:updated_at => Time.now, :validation_data => vd})
        raise MetaformException, "error updating form_instance: #{form_instance.errors.full_messages}" if !ok
      end
      if field_instances_protected && !field_instances_protected.empty?
        raise MetaformFieldUpdateError.new(saved_attributes,field_instances_protected)
      end
#      form.submit(presentation,self)

      saved_attributes
    else
      #TODO if there is a field instance that is invalid, i.e. for example because
      # the field is in a questions that is in group that is in a presentation that isn't
      # in a form, you'll see something very ugly.  Currently validate puts things in place
      # so that the standard rails error message shows up.  Note that this is different from
      # our own validation.
      false
    end
  end

  #################################################################################
  # returns the field_instance states of the current attributes
  #################################################################################
  def get_attribute_states
    states = {}
    @form_instance.field_instances.each do |fi| 
      states[fi.field_id] ||= []
      states[fi.field_id][fi.idx.to_i] = fi.state
    end
    states
  end

  def update_calculated_fields(fields_hash)
    fields_hash.each do |index,fields|
      field_list = fields.flatten.uniq
      if !field_list.empty?
        condition_values = [@form_instance.id,field_list]
        condition_string = "form_instance_id = ? and field_id in (?)"
        index = index.to_i
        condition_string << " and idx = ?"
        condition_values << index
        condition_values.unshift(condition_string)
        FieldInstance.destroy_all(condition_values)
        field_list.each do |f|
          the_field = form.fields[f]
          value = the_field.calculated[:proc].call(form,index)
          idx = the_field.calculated[:summary_calculation] ? 0 : index
          fi = FieldInstance.new({:answer => value, :field_id=>f, :form_instance_id => @form_instance.id, :idx => idx, :state => 'calculated'})
          fi.save
        end
      end
    end
  end

  #################################################################################
  # merges the invalid_fields information into the validation data hash
  #################################################################################
  def _merge_invalid_fields(vd,field_list,invalid_fields,index = nil)
    v = vd['_']
    v ||= {}
    if index == :any
      # if the index is any, then we assume that the invalid_fields has
      # all the invalidity data for all indexes so we can just delete
      # everyting from the validity data hash and merge in the current
      # invalid state
      field_list.each {|f| v.delete(f)}
      v.update(invalid_fields)
    else
      # if an index is specified, then we only assume that the validity information
      # for that index (not any others) is specified in invalid_fields, so we
      # only clear and merge for that index
      index = index.to_i
      field_list.each do |f|
        v[f] ||= []
        if invalid_fields[f]
          v[f][index] = invalid_fields[f][index]
        else
          v[f][index] = nil
        end
        v.delete(f) if v[f].compact.size == 0
      end
    end
    vd['_'] = v
  end

  #################################################################################
  # updates the count of invalid fields in the validation_data hash per presentation and index
  # NOTE: this method only works if the given presentation has been properly set up
  #       by a call to form#setup_presentation or form#build
  #################################################################################
  def _update_presentation_error_count(validation_data,presentation,index=nil,states={},exclude_states=[])
    vd = validation_data
    v = vd['_']
    states_to_exclude = arrayify(exclude_states)
    count = vd[presentation]
    if index == :any
      count = [0]
      @form.get_current_field_names.each do |f| 
        errs = v[f]
        s = states[f]
        if errs
          errs.each_with_index do |e,i|
            if e
              count[i] ||= 0
              count[i] += 1 if !s || !states_to_exclude.include?(s[i])
            end
          end
        end
      end
    else
      count ||= []
      index = index.to_i
      count[index] = 0
      @form.get_current_field_names.each {|f| errs = v[f]; s = states[f]; count[index] += 1 if errs && errs[index] && (!s || !states_to_exclude.include?(s[index]))}
    end
    vd[presentation] = count
    vd
  end


  #################################################################################
  # Returns a hash of which of the currently set attributes are invalid
  #################################################################################
  def _validate_attributes(fields = nil)
    invalid_fields = {}
    @cache.each(:attributes => fields) do |f,value,index|
      @form.set_current_index(index)
      invalid = Invalid.evaluate(@form,@form.fields[f],value)
      if !invalid.empty?
        invalid_fields[f] ||= []
        invalid_fields[f][index.to_i] = invalid
      end
    end
    invalid_fields
  end

  #################################################################################
  # Returns a the cached invalid fields list for the current fields
  #################################################################################
  def current_invalid_fields
  	v = form_instance.get_validation_data['_']
  	d = {}
  	@form.get_current_field_names.each {|f| d[f] = v[f] if v[f]} if v
  	d
  end

  #################################################################################
  # Returns a the cached count of invalid fields for a given presentation and index
  #################################################################################
  def get_invalid_field_count(presentation_name,index=nil)
    count = @form_instance.get_validation_data[presentation_name]
    if count
      if index == :any
        count.compact.inject { |sum,x| sum+x }
      else
        count[index.to_i]
      end
    end
  end

#  def recalcualte_invalid_fields
#    vd = form_instance.get_validation_data
#    all_fields = @form.fields.values.find_all {|f| !f.calculated}.collect {|f| f.name}
#    load_attributes(all_fields,:any)
#    vd['_'] = _validate_attributes
#    form_instance.update_attributes!({:validation_data => vd})
#    vd
#  end
  
  def set_force_nil_attributes(fields=nil)
    fields_forced = []
    @cache.each(:attributes => fields) do |attrib,value,index|
      @form.set_current_index(index)
      form.evaluate_force_nil(attrib,index) do |f|
        set_attribute(f,nil,index)
        fields_forced << f
      end
    end
    fields_forced
  end
  
  def logger
    form_instance.logger
  end
  
  def url(presentation,index=0)
    Record.url(id,presentation,index)
  end
    
  def explanation(field_name,index = 0)
    index = index.to_i
    fi = @form_instance.field_instances.find_by_field_id_and_idx(field_name.to_s,index)
    fi.explanation if fi
  end

  def explanations(fields,index = 0)
    index = index.to_i
    expl = {}
    field_instances = @form_instance.field_instances.find(:all,:conditions =>["field_id in (?)",fields])
    field_instances.each {|fi| expl[fi.field_id] = fi.explanation if fi.idx == index}
    expl
  end
  
  def any_explanations?
    field_instances = @form_instance.field_instances.find(:all)
    field_instances.each {|fi| return true unless fi.explanation.blank?}
    return false
  end

  def self.human_attribute_name(attribute_key_name) #:nodoc:
    attribute_key_name
  end
  
  def Record.slice(id,*field_names)
    conditions = {:form_instance_id => id, :field_id => field_names}
    result = {}
    field_instances = FieldInstance.find(:all,:conditions => conditions, :order => 'idx DESC')
    field_names.each {|a| result[a] = {}}
    field_instances.each do |fi|
      result[fi.field_id][fi.idx] = fi.answer unless fi.answer.blank?   #To-do:  Use this line when database no longer has blank answers
      #result[fi.field_id][fi.idx] = fi.answer #To-do:  Use this line when database no longer has blank answers
    end if field_instances
    result = result[field_names[0]] if field_names.size == 1
    result
  end
  def slice(*field_names)
    Record.slice(self.id,*field_names)
  end
  
  def Record.answer_num(id,field,answer,other_than=false)
    raise "You can not request the answer_num for a nil or empty string answer" if answer.blank?
    answer = answer.to_s
    if other_than
      #conditions = "form_instance_id = '#{id}' and field_id = '#{field}' and answer != '#{answer}'" To-do:  Use this line when database no longer has blank answers
      conditions = "form_instance_id = '#{id}' and field_id = '#{field}' and answer != '#{answer}' and answer is not null and answer != ''"
    else
      conditions = {:form_instance_id => id, :field_id => field, :answer => answer} #We store answers as strings in the database and postgres would like us to do the conversion.
    end
    FieldInstance.find(:all,:conditions => conditions).size
  end
  def answer_num(field,answer,other_than=false)
    Record.answer_num(self.id,field,answer,other_than)
  end
  
  #This method will return the highest index for a particular field.  Note that if a field has been
  #set to a nil or '' value, it will not be stored in the database and will thus not affect this
  #calculation.  It is therefore the highest non-blank index.
  def Record.max_index(id,field)
    conditions = {:form_instance_id => id, :field_id => field}
    max_index_field_instance = FieldInstance.find(:first,:conditions => conditions, :order => 'idx DESC')
    max_index_field_instance ? max_index_field_instance.idx : nil
  end
  def max_index(field)
    Record.max_index(self.id,field)
  end
  
  def Record.last_answer(id,field)
    conditions = "form_instance_id = '#{id}' and field_id = '#{field}' and answer is not null and answer != ''"
    #conditions = {:form_instance_id => id, :field_id => field}  To-do:  Use this line when database no longer has blank answers
    max_index_field_instance = FieldInstance.find(:first,:conditions => conditions, :order => 'idx DESC')
    max_index_field_instance ? max_index_field_instance.answer : nil
  end
  def last_answer(field)
    Record.last_answer(self.id,field)
  end 
 
  #################################################################################
  # exports the attributes of the record in the format specified
  # The options to export are:
  # * :format - which format to export the record.  Currently support are:
  #     :csv
  # currently 
  #################################################################################
  require 'csv.rb'
  def export(opts = {})
    options = {
      :format => :csv
    }.update(opts)
    case options[:format]
    when :csv
      result = []
      fields = options[:fields]
      date_format = options[:date_format]
      date_time_format = options[:date_time_format]
      raise "you must specify the :fields option with a list of fields to export" if !fields
      puts "<br>CACHE on entrance to export: #{@cache.dump.inspect}" if DEBUG1
      @cache.indexes.each do |index|
        row = []
        row << self.form.class.to_s
        row << self.id
        row << index
        if date_time_format
          row << self.created_at.strftime(date_time_format)
          row << self.updated_at.strftime(date_time_format)
        else
          row << self.created_at
          row << self.updated_at
        end
        row << self.workflow_state
        fields.each do |f|
          field_def = form.fields[f]
          if field_def.nil?
            row << nil
          else
            d = @cache.attributes(index)[f]
            field_type = field_def.type
            begin
              if field_type == 'time' && !d.blank?
                row << Time.local(*ParseDate.parsedate(d)[0..6]).strftime("%H:%M:%S")
              elsif date_format && field_type == 'date' && !d.blank?
                row << Time.local(*ParseDate.parsedate(d)[0..2]).strftime(date_format)
              elsif date_time_format && field_type == 'datetime' && !d.blank?
                row << Time.local(*ParseDate.parsedate(d)[0..4]).strftime(date_time_format)
              else
                row << d
              end
            rescue
              row << d
            end
          end
        end
        result << CSV.generate_line(row)
      end
      result
    else
      raise "#{options[:format].inspect} is an unknown export format"
    end
  end
  
  def self.export_csv_header(field_list)
    CSV.generate_line(['form','id','index','created_at','updated_at','workflow_state'].concat(field_list))
  end
 
  def loaded?
    @record_loaded
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
  
  #Record.locate calls Record.gather with a collection of form_instances which are determined by what and locate_options
  #locate_options are used to create a condition string for the call to FormInstance.find
  def Record.locate(what,locate_options = {})
    gather_options = {}
    condition_strings = []
    conditions_params = []
    field_list = {}
   puts "LOCATE OPTIONS: #{locate_options.inspect}"
    
    if locate_options.has_key?(:filters)
      gather_options[:filters] = locate_options[:filters]
      filters = arrayify(locate_options[:filters])
      filters.each { |fltr| fltr.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1}}
    end

    if locate_options.has_key?(:fields)  
      locate_options[:fields].each {|x| field_list[x] = 1 }
    end

    if field_list.size > 0
      condition_strings << "(field_instances.field_id in (?))"
      conditions_params << field_list.keys
      gather_options[:field_list] = field_list
    end
    
    if locate_options.has_key?(:index)
      idx = locate_options[:index]
      if idx != :any
        condition_strings << "(field_instances.idx #{idx ? '=' : 'is'} ?)"
        conditions_params << idx
      end
    else
      condition_strings << "(field_instances.idx = 0)"      
    end

    if locate_options.has_key?(:forms)
      condition_strings << "(form_id in (?))"
      conditions_params << locate_options[:forms]
    end

    if locate_options.has_key?(:workflow_state_filter)
      if locate_options[:workflow_state_filter].is_a?(Array)
        condition_strings << "#{"NOT" if locate_options[:workflow_state_filter_negate]} (workflow_state in (?))"
      else
        condition_strings << "(#{"NOT" if locate_options[:workflow_state_filter_negate]} workflow_state like (?))"
      end
      conditions_params << locate_options[:workflow_state_filter]
    end
    puts "condition_strings = #{condition_strings.inspect}"
puts "conditions_params = #{conditions_params.inspect}"
    if locate_options.has_key?(:conditions)
      c = arrayify(locate_options[:conditions])
      c.each {|x| x =~ /([a-zA-Z0-9_-]+)(.*)/; condition_strings << %Q|if(field_instances.field_id = '#{$1}',if (answer #{$2},true,false),false)|}
    end

    if pf = locate_options[:sql_prefilters]
      pfr = Record.search(:conditions => pf)
      if !pfr.empty?
        condition_strings << 'form_instances.id in ('+pfr.collect {|r| r.id}.join(',')+')'
      else
        return []
      end
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
    #puts "find_opts = #{find_opts.inspect}"
    gather_options[:records] = Proc.new {
      begin
        puts "what = #{what.inspect}"
        puts "find_opts = #{find_opts.inspect}"
        FormInstance.find(what,find_opts)
      rescue ActiveRecord::RecordNotFound
        nil
      end
    }
    gather_options[:return_answers_hash] = locate_options[:return_answers_hash] if locate_options[:return_answers_hash]
    Record.gather(gather_options)
  end
  
  #Record.gather can return an Answers Hash (or an array of them) or a FormInstance (or an array of them)
  #It can start with a list of FormInstances or call a proc to find the desired FormInstances
  #It can call Record.filter to filter out results based on ruby to call on field values.
  def Record.gather(gather_options)
    puts "GATHER OPTIONS = #{gather_options.inspect}"
    filter_options = {}
    field_list = {} 
    
    if gather_options.has_key?(:filters)
      filters = arrayify(gather_options[:filters])
      filter_options[:filters] = filters
    end
    
    if gather_options.has_key?(:field_list) 
        filter_options[:field_list] = gather_options[:field_list]
    else
      filters.each { |fltr| fltr.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1}} if filters
      if gather_options.has_key?(:fields) 
        gather_options[:fields].each {|x| field_list[x] = 1 }
      end
      filter_options[:field_list] = field_list
    end
    
    if gather_options.has_key?(:return_answers_hash)
      return_answers_hash = true
      filter_options[:return_answers_hash] = true
    else
      return_answers_hash = false
    end
    #Note:  We pass in the fields so that the proc can use the array to limit the size of what comes back from the <user>.field_instances call (which is what it probably is doing)
    filter_options[:records] = gather_options[:records].is_a?(Proc) ? gather_options[:records].call(filter_options[:field_list].keys) : gather_options[:records]
    if filter_options[:records]  && (filters || return_answers_hash)
      forms = Record.filter(filter_options)
    else
      forms = filter_options[:records] 
    end
    return nil if !forms
    if return_answers_hash
      if forms.is_a?(Hash)
        return AnswersHash.new.update(forms)
      else
        return forms.map{|r| AnswersHash.new.update(r) }
      end
    end
    return Record.create(forms)
  end
  
  def Record.filter(filter_options)
    puts "FILTER OPTIONS = #{filter_options.inspect}"
    return_answers_hash = filter_options.has_key?(:return_answers_hash)
    
    filters = filter_options[:filters]
    filter_eval_string = filters.collect{|x| "(#{x})"}.join('&&') if filters
    filter_expr = eval_field(filter_eval_string) if filters
    
    form_instances = filter_options[:records]
    if !form_instances.respond_to?('each')
      form_instances = [form_instances]
      did_it = true
    end
    
    forms = []
    form_instances.each do |r|
      f = {'form_instance_id' => Answer.new(r.id), 'workflow_state' => Answer.new(r.workflow_state),'created_at' => Answer.new(r.created_at), 'updated_at' => Answer.new(r.updated_at), 'form_id' => Answer.new(r.form.to_s)}
      r.field_instances.each do |field_instance|
        if f.has_key?(field_instance.field_id)
          #puts "if:  #{field_instance.field_id}"
          a = f[field_instance.field_id]
          a[field_instance.idx] = field_instance.answer
        else
          #puts "else:  #{field_instance.field_id}"
          f[field_instance.field_id]= Answer.new(field_instance.answer,field_instance.idx)
        end
      end
      filter_options[:field_list].keys.each {|field_id| f[field_id] = Answer.new(nil,nil) if !f.has_key?(field_id)}
      the_form = return_answers_hash ? f : r
      if filters && filters.size > 0
        kept = false
        begin
          kept = eval filter_expr
        rescue Exception => e
          raise MetaformException,"Eval error '#{e.to_s}' while evaluating: #{filter_expr}"
        end
        forms << the_form if kept
      else
        forms << the_form
      end
    end
    forms = forms[0] if forms.length == 1 && did_it
    puts "forms[0]['workflow_state]=#{forms[0]['workflow_state']}"
    forms
  end
    
  def Record.eval_field(expression)
      #puts "---------"
      #puts "eval_Field 0:  expression=#{expression}"
      expr = expression.gsub(/\!:(\S+)/,'!(:\1)')
      #puts "eval_Field 1:  expr=#{expr}"
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)\.(size|exists\?|count|is_indexed\?|each|each_with_index|to_i|zip|map|include|any|other\?|blank\?)/,'f["\1"].\2')
      #puts "eval_field 2:  expr=#{expr}"
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)\./,'f["\1"].value.')
      #puts "eval_field 4:  expr=#{expr}"
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)\[/,'f["\1"][')
      #puts "eval_field 5:  expr=#{expr}"
      if /\.zip/.match(expr)
        expr = expr.gsub(/\.zip\(:([a-zA-Z0-9_-]+)/,'.zip(f["\1"]')
      else
        expr = expr.gsub(/:([a-zA-Z0-9_-]+)/,'(f["\1"] ? (f["\1"].is_indexed? ? f["\1"].value[0] : f["\1"].value) : nil)')
      end
      #puts "eval_field 5:  expr=#{expr}"
      #puts "---------"
      expr
  end
  
  def Record.url(record_id,presentation,index=nil)
    url = "/records/#{record_id}"
    url << "/#{presentation}" if presentation != ""
    url << "/#{index}" if index && index != 0 
    url
  end
  
  def Record.create_url(form,presentation,current)
    url = "/forms/#{form}/records"
    url << "/#{presentation}" if presentation && presentation != ""
    url << "/#{current}" if current && current != ''
    url
  end
  
  def Record.listing_url(listing,params = nil)
    url = "/records/listings/#{listing}"
    url << ("?" + params.keys.map{|k| "search[#{k}]=#{params[k]}"}.join("&")) if params
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

  ######################################################################################
  # faster replacement for Record.Locate
  #select form_instances.id,x.answer as H_Ccode,y.answer as Q,z.answer as Z from form_instances left outer join field_instances as x on form_instance_id = form_instances.id and field_id = 'H_Ccode' inner join field_instances as y on y.form_instance_id = form_instances.id and y.field_id='H_Source' and y.answer='PMID0' inner join field_instances as z on z.form_instance_id = form_instances.id and z.field_id = 'Book_EstimatedDueDate' and z.answer like '%-03-%' where workflow_state = 'done' order by id limit 10"
  def Record.search(options)
    fields = arrayify(options[:fields]).collect {|f| f.to_s}
    left_join_fields = fields.clone
    where_conditions = []
    if conditions = options[:conditions]
      c = conditions.is_a?(Array) ? conditions[0] : conditions
      c = c.call if c.is_a?(Proc)
      c.scan(/:([a-zA-Z0-9_-]+)/) { |f| left_join_fields = f.concat(left_join_fields)}
      sql = sql_fieldname_convert(c)
      if conditions.is_a?(Array)
        idx = 0
        sql.gsub!(/\?/) {|match| idx +=1;"'#{conditions[idx]}'"}
      end
      where_conditions.push('('+sql+')')

      left_join_fields = left_join_fields.uniq
#      # if a field is in the conditions inner join, we don't need to add it to the left joins below, so get rid of them
#      left_join_fields -= options[:conditions].keys.collect {|f| f.to_s}
#      inner_join_sql = options[:conditions].collect {|f,v| fq = UsingPostgres ? "\"#{f}\"" : f;"inner join field_instances as #{fq} on #{fq}.form_instance_id = form_instances.id and #{fq}.field_id = '#{f}' and #{fq}.answer #{v}"}.join(' ')
    end
    meta_fields = ['id']
    meta_fields += arrayify(options[:meta_fields]) if options[:meta_fields]
    fields_sql = fields.collect {|f| fq = UsingPostgres ? "\"#{f}\"" : f;"#{fq}.answer as #{fq}"}.concat(meta_fields.collect {|f| "form_instances.#{f}"}).join(", ")
    fields_sql += "," + arrayify(options[:raw_fields]).join(',') if options[:raw_fields]
    left_join_sql = left_join_fields.collect{|f| fq = UsingPostgres ? "\"#{f}\"" : f;"left outer join field_instances as #{fq} on #{fq}.form_instance_id = form_instances.id and #{fq}.field_id = '#{f}' "}.join(" ") if !left_join_fields.empty?

    select = "#{fields_sql} from form_instances"
    select += ' ' + left_join_sql if left_join_sql
#    select += ' ' + inner_join_sql if inner_join_sql
    where_conditions.push('('+options[:meta_condition]+')') if options[:meta_condition]
    select += ' where ' + where_conditions.join(' and ') if !where_conditions.empty?
    if options[:order]
      order_fields = arrayify(options[:order])
      if UsingPostgres
        # got to add the order fields into the column list (if they aren't there)
        # because in Postgres distinct requires them to be in the column list too
        order_fields = order_fields.collect {|o| o.to_s}
        order_fields_for_select = order_fields-(fields+left_join_fields)
        select = order_fields_for_select.join(',')+","+select if !order_fields_for_select.empty?

        order_fields = order_fields.collect do |f|
          # quote the field name but not the table name if given
          if f =~ /(.*)\.(.*)/
            "#{$1}.\"#{$2}\""
          else
            "\"#{f}\""
          end
        end
        
        
      end
      order_fields = order_fields.join(',')
      select += " order by "+order_fields
    end
    select += " limit #{options[:limit].to_i}" if options[:limit]
#    puts select
    r = FormInstance.find_by_sql("select distinct "+select)
  end
  
  def Record.sql_fieldname_convert(str)
    str.gsub(/:([a-zA-Z0-9_-]+)/,UsingPostgres ? '"\1".answer' : '\1.answer')
  end
  
  private
  def Record.arrayify(param)
    return [] if param == nil
    param = [param]  if param.class != Array
    param
  end
  
end
   