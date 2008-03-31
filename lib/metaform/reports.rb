require 'metaform/utilities'

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
      
      total = form_instances.size
      #puts "---------count_queries:" 
      r.count_queries.each do |stat,q|
        count = Counter.new
        form_instances.each do |f|
          begin
            expr = Record.eval_field(q)
            eval(expr)
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
