require 'metaform/utilities'

class Reports

  # we store the field answers in an answer class that can handle the indexes but also 
  # has accessors for the non-indexted case
  class Answer
    def initialize(val,index)
      self[index] = val
    end

    def value
      @value
    end

    def value=(val,index=nil)
      self[index] = val
    end
    
    def [](index)
      if index.nil?
        is_indexed? ? @value[nil] : @value
      else
        is_indexed? ? @value[index] : ((index == nil) ? @value : nil)
      end
    end

    def []=(index,val)
      if is_indexed?
        @value[index ? index : nil] = val
      else
        if index  #convert to hash if necessary
          v = {index => val}
          v[nil] = @value if @value
          @value = v
        else
          @value = val
        end
      end
    end
    
    def size
      if is_indexed?
        @value.size
      else
        @value ? 1 : 0
      end
    end
    
    # this probably needs to have yield block so that we can count any property
    # not just which ones aren't nil
    def count
      if is_indexed?
        @value.values.compact.size
      else
        @value ? 1 : 0
      end
    end
    
    def exists?
      self.size > 0
    end
    
    def each(&block)
      if is_indexed?
        @value.values.each {|v| block.call(v)}
      else
        block.call(@value)
      end
    end
    
    def zip(other_answer,&block)
      if is_indexed?
        @value.values.zip(other_answer.value) {|a| block.call(a)}
      else
         block.call([@value,other_answer.value])
      end
    end
    
    def include?(desired_value)
      if is_indexed?
        @value.values.include?(desired_value)
      else
        @value == desired_value
      end
    end
    
    def is_indexed?
      @value.is_a?(Hash)
    end
        
  end
  
  class << self
    include Utilities
    
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
        :count_queries => {}
      }.update(opts)
      self.reports[report_name] = Struct.new(:block,*options.keys)[block,*options.values]
    end

    #################################################################################
    class Counter
      attr :value
      def initialize
        @value = 0
      end
      def increment(by = 1)
        @value = @value + by
      end
    end
    def get_report(report_name,options = {})

      r = self.reports[report_name]
      raise "unknown report #{report_name}" if !r 
      results = {}

      locate_options = {}
      locate_options[:forms] = r.forms if r.forms
      locate_options[:workflow_state_filter] = r.workflow_state_filter if r.workflow_state_filter

      # build up the list of extra fields we need to get from the database by looking in count queries
      field_list = {}
      r.fields.each {|f| field_list[f]=1} if r.fields
      r.count_queries.each { |stat,q| q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} if q.is_a?(String)}
      filters = arrayify(r.filters)
      if options[:filters]
        filters = filters.concat(arrayify(options[:filters]))
      end
      
      locate_options[:fields] = field_list.keys
      locate_options[:filters] = filters if filters.size>0
      locate_options[:raw] = true
      locate_options[:index] = :any

#      w = sql_workflow_condition(r.workflow_state_filter,true)
      #TODO:  Stats will present forms that have passed validation but not data review, 
      #and data reveiwed.  Correct w when these states are finalized
      
#      sql_conditions = sql_field_conditions(r.sql_conditions,true)
#      sql_conditions << sql_field_conditions(options[:sql_conditions],true)

#      form_instances = FormInstance.find(:all, 
#        :conditions => ["form_id in (?) and field_id in (?)" << w ,r.forms,field_list.keys], 
#        :include => [:field_instances]
#        )
      forms = {}
      
      locate_options[:field_instances_proc] = Proc.new do |f,field_instance|
        if f.has_key?(field_instance.field_id)
          a = f[field_instance.field_id]
          a[field_instance.idx] = field_instance.answer
        else
          f[field_instance.field_id]= Answer.new(field_instance.answer,field_instance.idx)
        end
      end

      form_instances = Record.locate(:all,locate_options) 
      
      total = forms.size
      #puts "---------count_queries:" 
      r.count_queries.each do |stat,q|
        count = Counter.new
        form_instances.each {|f| eval_field(q) { |expr| eval(expr)}}
        results[stat] = count.value
      end
      
      results[:total] = total
      r.block.call(results,forms)
    end
    
    def eval_field(expression)
#      puts "---------"
#      puts "eval_Field:  expression=#{expression}"
      expr = expression.gsub(/:([a-zA-Z0-9_-]+)\.(size|exists\?|count|is_indexed\?|each|zip|include\?)/,'f["\1"].\2')
#      puts "eval_field:  expr=#{expr}"
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)\./,'f["\1"].value.')
#      puts "eval_field:  expr=#{expr}"
      expr = expr.gsub(/:([a-zA-Z0-9_-]+)\[/,'f["\1"][')
#      puts "eval_field:  expr=#{expr}"
      if /\.zip/.match(expr)
        expr = expr.gsub(/\.zip\(:([a-zA-Z0-9_-]+)/,'.zip(f["\1"]')
      else
        expr = expr.gsub(/:([a-zA-Z0-9_-]+)/,'(f["\1"].is_indexed? ? f["\1"].value[0] : f["\1"].value)')
      end
#      puts "eval_field:  expr=#{expr}"
#      puts "---------"
      begin
        yield expr
      rescue Exception => e
        raise "Eval error '#{e.to_s}' while evaluating: #{expr}"
      end
    end

  end
end
