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
        is_indexed? ? @value[0] : @value
      else
        is_indexed? ? @value[index] : ((index == 0) ? @value : nil)
      end
    end

    def []=(index,val)
      if is_indexed?
        @value[index ? index : 0] = val
      else
        if index  #convert to array if necessary
          @value = [@value]
          @value[index] = val
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
        @value.compact.size
      else
        @value ? 1 : 0
      end
    end
    
    def exists?
      self.size > 0
    end
    
    def each(&block)
      if is_indexed?
        @value.each {|v| block.call(v)}
      else
        block.call(@value)
      end
    end
    
    def zip(other_answer,&block)
      if is_indexed?
        @value.zip(other_answer.value) {|a| block.call(a)}
      else
         block.call([@value,other_answer.value])
      end
    end
    
    def include?(desired_value)
      if is_indexed?
        @value.include?(desired_value)
      else
        @value == desired_value
      end
    end
    
    def is_indexed?
      @value.is_a?(Array)
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

      # build up the lists of fields we need to get from the database by looking in 
      # count queries, the sum querries and the fiters
      field_list = {}
      r.fields.each {|f| field_list[f]=1} if r.fields
      r.count_queries.each { |stat,q| q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} if q.is_a?(String)}
      filters = arrayify(r.filters)
      if options[:filters]
        filters = filters.concat(arrayify(options[:filters]))
        filters.each { |fltr| fltr.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1}}
      end

      w = sql_workflow_condition(r.workflow_state_filter,true)
      #To do:  Stats will present forms that have passed validation but not data review, 
      #and data reveiwed.  Correct w when these states are finalized
      
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
        i.field_instances.each do |fld|
          if f.has_key?(fld.field_id)
            a = f[fld.field_id]
            a[fld.idx] = fld.answer
          else
            f[fld.field_id]= Answer.new(fld.answer,fld.idx)
          end
        end
        filtered = false
        field_list.keys.each {|field_id| f[field_id] = Answer.new(nil,nil) if !f.has_key?(field_id)}
        if filters.size > 0
          eval_field(filters.collect{|x| "(#{x})"}.join('&&')) {|expr| 
            filtered = eval(expr)
            }
        end
        forms[i.id]=f if !filtered    
      end
      total = forms.size
     
      #puts "---------count_queries:" 
      r.count_queries.each do |stat,q|
        count = Counter.new
        forms.values.each {|f| eval_field(q) { |expr| eval(expr)}}
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
