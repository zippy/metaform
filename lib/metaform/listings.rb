#require 'metaform/utilities'

class Listings
  class << self
    include Utilities

    def lists
      @lists ||= {}
      @lists
    end

    #################################################################################
    # expected options are :workflow_state_filter,:fields,:conditions,:forms
    def list(list_name, opts, &block)
      options = {
        :workflow_state_filter => nil,
        :fields => nil,
        :conditions => nil,
        :forms => nil 
      }.update(opts)
      self.lists[list_name] = Struct.new(:block,*options.keys)[block,*options.values]
    end

    #################################################################################
    def get_list(list_name,options = {})
      forms = []
      l = self.lists[list_name]
      raise "unknown list #{list_name}" if !l      
      #Use the list to create locate_options
      locate_options = {}
      locate_options[:forms] = l.forms if l.forms
      locate_options[:fields] = l.fields if l.fields
      locate_options[:conditions] = l.conditions if l.conditions
      wsf = []
      wsf << l.workflow_state_filter if l.workflow_state_filter
      wsf << options[:workflow_state_filter] if options[:workflow_state_filter]
      wsf = wsf.flatten
      locate_options[:workflow_state_filter] = wsf if wsf.size > 0
      #Grab any filters from the options
      locate_options[:filters] = options[:filters] if options[:filters]
      locate_options[:sql_prefilters] = options[:sql_prefilters] if options[:sql_prefilters]
      forms = Record.locate(:all,locate_options)
      # TODO-LISA
      # implement 1) sub-sorting, and 2) sorting by type, i.e. this sorting only does
      # alphabetical.  We should be converting dates to dates and sorting by that
      # numbers to numbers, etc.  Actually, perhaps that should be solved by
      # the loading of the field instances answer value and then the <=> should just work right.
      order_field = options[:order] ? options[:order] : (l.fields ? l.fields[0] : nil)
      # puts "forms.inspect = #{forms.inspect}"
      order_field ? forms.sort {|x,y| x.send(order_field) ? (x.send(order_field) <=> y.send(order_field)) : 0 } : forms
    end
  end
end
