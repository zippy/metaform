#require 'metaform/utilities'

class Listings
  class << self
    include Utilities

    def listings
      @listings ||= {}
      @listings
    end

    #################################################################################
    # expected options are :workflow_state_filter,:fields,:conditions,:forms
    def listing(listing_name, opts, &block)
      options = {
        :workflow_state_filter => nil,
        :fields => nil,
        :conditions => nil,
        :forms => nil 
      }.update(opts)
      self.listings[listing_name] = Struct.new(:block,*options.keys)[block,*options.values]
    end

    #################################################################################
    def get_list(list_name,options = {})
      forms = []
      l = self.listings[list_name]
      raise "unknown list #{list_name}" if !l      
      #Use the listing to create locate_options
      locate_options = {}
      locate_options[:forms] = l.forms if l.forms
      locate_options[:fields] = l.fields if l.fields
      locate_options[:conditions] = l.conditions if l.conditions
      locate_options[:return_answers_hash] = l.return_answers_hash if l.return_answers_hash
      wsf = []
      wsf << l.workflow_state_filter if l.workflow_state_filter
      wsf << options[:workflow_state_filter] if options[:workflow_state_filter]
      wsf = wsf.flatten
      locate_options[:workflow_state_filter] = wsf if wsf.size > 0
      #Grab any filters from the options
      locate_options[:filters] = options[:filters] if options[:filters]
      locate_options[:sql_prefilters] = options[:sql_prefilters] if options[:sql_prefilters]
      locate_options[:index] = options[:index] if options[:index]
      forms = Record.locate(:all,locate_options)
      # TODO-LISA
      # implement 1) sub-sorting, and 2) sorting by type, i.e. this sorting only does
      # alphabetical.  We should be converting dates to dates and sorting by that
      # numbers to numbers, etc.  Actually, perhaps that should be solved by
      # the loading of the field instances answer value and then the <=> should just work right.
      order_field = options[:order] if options[:order]
      # puts "forms.inspect = #{forms.inspect}"
      order_field ? forms.sort {|x,y| x.send(order_field) ? (x.send(order_field) <=> y.send(order_field)) : 0 } : forms
    end
  end
end
