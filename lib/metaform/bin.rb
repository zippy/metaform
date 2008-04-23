###############################################################
# A bin is kind of like a Struct, but you can create bins on 
# the fly
class Bin
  def initialize(b={})
    @bins = bins
    k = b.keys
    required_bins.each {|rb| raise MetaformException,"#{self.class} reqires '#{rb}' to be defined" if !k.include?(rb)}
    @bins.update(b)
  end
  
  def bins
    {}
  end
  def required_bins
    []
  end

  def type
    @bins.has_key?(:type) ? @bins[:type] : super
  end
  
  def [](bin)
    @bins[bin]
  end
  def []=(bin,value)
    @bins[bin] = value
  end

  def method_missing(method,*args)
    if method.to_s =~ /(.*)=$/
      return @bins[$1.intern] = args[0]
    else
      return @bins[method] if @bins.has_key?(method)
    end
    super
  end
end