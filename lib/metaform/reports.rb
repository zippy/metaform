#require 'metaform/utilities'

class Reports

  # we store the field answers in an answer class that can handle the indexes but also 
  # has accessors for the non-indexted case
  
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
        :workflow_state_filter_negate => false,
        :fields => nil,
        :forms => nil,
        :filters => nil,
        :count_queries => {},
        :sum_queries => {}
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
      locate_options[:workflow_state_filter_negate] = r.workflow_state_filter_negate if r.workflow_state_filter_negate

      # build up the list of extra fields we need to get from the database by looking in count queries
      field_list = {}
      r.fields.each {|f| field_list[f]=1} if r.fields
      
      count_queries = r.count_queries
      if options[:count_queries]
        count_queries.update(options[:count_queries])
      end
      count_queries.each { |stat,q| 
        if q.is_a?(String)
          q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} 
          count_queries[stat] = 'count.increment if (' + q + ')' if !q.match('count')
          #puts "count_queries[stat] = #{count_queries[stat]}"
        end
        }
        
      sum_queries = r.sum_queries
      if options[:sum_queries]
        sum_queries.update(options[:sum_queries])
      end
      sum_queries.each { |stat,q| 
        if q.is_a?(String)
          q.scan(/:([a-zA-Z0-9_-]+)/) {|z| field_list[z[0]] = 1} 
          sum_queries[stat] = 'count.increment(' + q + '.to_i) if (' + q + ')' if !q.match('count')
          #puts "sum_queries[stat] = #{sum_queries[stat]}"
        end
        }
      
      filters = arrayify(r.filters)
      if options[:filters]
        filters = filters.concat(arrayify(options[:filters]))
      end
      
      locate_options[:fields] = field_list.keys
      locate_options[:filters] = filters if filters.size>0
      locate_options[:return_answers_hash] = true
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
      form_instances = Record.locate(:all,locate_options) 
      # puts "form_instances = #{form_instances.inspect}"
      
      total = form_instances.size
      count_queries.each do |stat,q|
        #puts "count_queries:  stat = #{stat}, q = #{q}"
        count = Counter.new
        form_instances.each do |f|
          #puts "f['New_Sex'] = #{ f['New_Sex'].inspect}"
          #puts "f['New_Grams'] = #{ f['New_Grams'].inspect}"
          begin
            expr = Record.eval_field(q)
            #puts "count_query expr = #{expr}"
            eval(expr)
            #puts "count.value = #{count.value}"
          rescue Exception => e
            raise "Eval error '#{e.to_s}' while evaluating: #{expr}"
          end
        end
        results[stat] = count.value
      end
      
      sum_queries.each do |stat,q|
        #puts "sum_queries:  stat = #{stat}, q = #{q}"
        count = Counter.new
        form_instances.each do |f|
          #puts "f['New_Sex'] = #{ f['New_Sex'].inspect}"
          #puts "f['New_Grams'] = #{ f['New_Grams'].inspect}"
          begin
            expr = Record.eval_field(q)
            #puts "sum_query expr = #{expr}"
            eval(expr)
            #puts "count.value = #{count.value}"
          rescue Exception => e
            raise "Eval error '#{e.to_s}' while evaluating: #{expr}"
          end
        end
        results[stat] = count.value
      end
      
      results[:total] = total
      r.block.call(results,form_instances)
    end
    
  end
end
