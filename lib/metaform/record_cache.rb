class RecordCache
  def initialize
    @attributes = []
  end
  
  ######################################################################################
  # return a list of the attributes in the cache at a given index
  def attributes(index=0)
    @attributes[normalize_index(index)]
  end
  
  ######################################################################################
  # set an attribute value at a given index
  def set_attribute(attribute,value,index=0)
    index = normalize_index(index)
#    puts "<br>SETTING ATTRIBUTE #{attribute}[#{index}]=#{value} [caller: #{trace}]"
    @attributes[index] ||= {}
    @attributes[index][normalize_attribute(attribute)] = value
  end
  
#  def trace
#    caller[1..3].collect {|l| l.gsub('/Users/eric/Coding/Consulting/MANA/MetaForm/git/manastats/vendor/plugins/metaform/lib/metaform/','')}.inspect
#  end
  
  ######################################################################################
  # get an attribute value at a given index
  # options: you may specify :any as an index, in which case an array of values will 
  #          be returned
  def get_attribute(attribute,index=0)
    attrib = normalize_attribute(attribute)
    if index == :any
      result = []
      @attributes.each_with_index do |values,idx|
        result[idx] = values ? values[attrib] : nil
      end
      result
    else
      index = normalize_index(index)
      @attributes[index] ||= {}
      @attributes[index][attrib]
    end
  end
  
  ######################################################################################
  # enumerate through all the attributes in the cache.
  # options:
  #   :index => number or :any   Limits enumeration to a particular index
  #   :attributes => list of attributes   Limits enumeration to a attributes in the list  
  def each(opts={})
    options = {
      :index => :any
    }.update(opts)
    index = options[:index]
    attribs = normalize_attribute_list options[:attributes]
    if index == :any
      @attributes.each_with_index do |values,idx|
        values.clone.each { |attribute,value| next if attribs && !attribs.include?(attribute); yield attribute,value,idx } if values
      end
    else
      index = normalize_index(index)
      values = @attributes[index]
      values.clone.each { |attribute,value| next if attribs && !attribs.include?(attribute); yield attribute,value,index } if values
    end      
  end
  
  ######################################################################################
  # clear attributes in the cache
  # options:
  #   :attributes => list of attributes   Limits clearing to a attributes in the list  
  #   :except => true/false  causes clearing to be of all attributes except those in the list  
  def clear(opts={})
    attribs = normalize_attribute_list opts[:attributes]
    except = opts[:except]
    if attribs
      @attributes.each_with_index do |values,idx|
        if values
          attrs = except ? (values.keys-attribs) : attribs
          attrs.each {|a| values.delete(a)}
          @attributes[idx] = nil if values.empty?
        end
      end
      while @attributes[-1].nil? do
        @attributes.pop
      end
    else
      initialize
    end
  end

  ######################################################################################
  # returns a list of the names of all the attributes in the cache
  def attribute_names
    names = []
    @attributes.each {|values| names << values.keys if values}
    names.flatten.uniq
  end

  ######################################################################################
  # returns a list of the indexes in used
  def indexes
    indexes = []
    @attributes.each_with_index {|values,idx| indexes << idx if values}
    indexes
  end
  
  ######################################################################################
  # returns true or false for whether an attribute exists in the cache
  # options: you may specify :any as an index
  def attribute_exists?(attribute,index=0)
    attribute = normalize_attribute(attribute)
    if index == :any
      @attributes.each_with_index do |values,idx|
        return true if values && values.keys.include?(attribute)
      end
      return false
    else
      index = normalize_index(index)
      @attributes[index] != nil && @attributes[index].has_key?(attribute)
    end
  end
  
  def dump
    @attributes
  end
  
  private
  def normalize_index(index)
    index.to_i
  end
  def normalize_attribute(attribute)
    attribute.to_s
  end

  def normalize_attribute_list(attribs)
    if attribs 
      attribs = [attribs] if attribs.class != Array
      attribs = attribs.collect {|a| normalize_attribute(a)}
    end
    attribs
  end
end


# This code was used to convert multi-dimensional indexes into  strings
#def normalize(index)
#  if index.instance_of?(Array)
#    index.pop while index.size > 0 && (index[-1] == '' || index[-1] == 0 || index[-1] == nil ) 
#  end
#  if index.instance_of?(Array)
#    if index.size == 0
#      index = nil
#    else
#      index = index.join(',')
#    end
#  elsif index 
#    if index.size == 0 || index == [nil] || index == ""
#      index = nil
#    else
#      index = index.to_s
#    end
#  end
#  index
#end