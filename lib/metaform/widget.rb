# Thanks to Peter Jones (pmade.com) for inspiring this coding pattern
################################################################################
class Widget
  #TODO -FIXME!!  FormProxy should totally disapear
  @@form_proxy = FormProxy.new('SampleForm'.gsub(/ /,'_'))
  def self.form
    @@form_proxy
  end
  ################################################################################
  def self.inherited(klass)
    instance_eval { (@widgets ||= {}).store(klass.to_s.sub(/Widget/, ''), klass) }
  end

  ################################################################################
  def self.list
    instance_eval {@widgets.keys}
  end
  
  def self.set(constraints)
    get_multi(constraints,'set')
  end
  def self.enumeration(constraints)
    get_multi(constraints,'enumeration')
  end
  
  def self.get_multi(constraints,type)
    
    constraint_name = nil
    #TODO this is stupid.  Fix!  Error message isn't clear if you make a mistake
    constraint_types = [type,"#{type}_lookup"].each {|e| constraint_name = e if constraints.has_key?(e); }
    raise "fields displayed with #{self.to_s} must be constrained with: #{type}" if !constraint_name
    if constraints && constraints[constraint_name]
      case 
      when constraint_name == 'enumeration' || constraint_name == 'set'
        enum = constraints[constraint_name].collect{|h| h.is_a?(Hash) ? h.to_a[0].reverse : ( h.is_a?(Array) ? h : [h.to_s.humanize,h.to_s]) }
      when constraint_name =~ /(set|enumeration)_lookup/
        spec = constraints[constraint_name]
        #spec[:model] can be a string or a class
        model = spec[:model].is_a?(String) ? spec[:model].constantize : spec[:model]
        if spec[:find_args]
          results = model.find(*spec[:find_args])
        elsif spec[:func]
          results = spec[:func].call
        end
        enum = results.collect {|r| spec.has_key?(:proc) ? spec[:proc].call(r) : [r.name,r.id]}
# this code does lookup within Forms, 
#        spec = constraints["enumeration_lookup"]
#        the_form = Form.find(:first, :conditions => ["name = ?",spec["form_name"]])
#        the_field = Field.find(:first, :conditions => ["name = ?",spec["field_name"]])
#        the_form.form_instances.each do |form_instance|
#          field_instance = FieldInstance.find(:first, :conditions => ["form_instance_id = ? and field_id = ?",form_instance.id,the_field.id])
#          enum << [field_instance.answer, field_instance.id]
#        end
      end
    end
    enum
  end

  ################################################################################
  def self.fetch(name)
    widgets = instance_eval {@widgets}

    raise "Unknown widget #{name}" unless widgets.has_key?(name)
    widgets[name]
  end

  ################################################################################
  def self.render(field_instance_id,value,label,options={})
    render_label(label,field_instance_id,options[:read_only] ? render_form_object_read_only(field_instance_id,value,options) : render_form_object(field_instance_id,value,options))
  end

  def self.render_form_object(field_instance_id,value,options)
    raise "This method should be overrided by your widget class!"
  end
  
  def self.render_form_object_read_only(field_instance_id,value,options)
    "<span id=\"#{build_html_id(field_instance_id)}\">#{humanize_value(value,options)}</span>"
  end

  def self.humanize_value(value,options=nil)
    if options && options[:constraints]
      case
      when options[:constraints]["enumeration"]
        options[:constraints]["enumeration"].each do |value_pair|
          case value_pair
          when Hash
            return value_pair.values[0] if value_pair.keys[0] == value
          when Array
            return value_pair[0] if value_pair[1] == value
          else
            return value_pair = value == value_pair
          end
        end
      when options[:constraints]["set"]
        return nil if value.nil?
        pairs = {}
        options[:constraints]["set"].each do |value_pair|
          case value_pair
          when Hash
            pairs[value_pair.keys[0]] = value_pair.values[0]
          when Array
            pairs[value_pair[1]] = value_pair[0]
          else
            pairs[value_pair] = value_pair
          end
        end
        return value.split(/,/).collect {|v| pairs[v]}.join(', ')
      when options[:constraints]['enumeration_lookup']
        return "" if value.blank?
        spec = options[:constraints]['enumeration_lookup'] 
        results = spec[:func].call
        return results.each do |r| 
          val = spec.has_key?(:proc) ? spec[:proc].call(r) : [r.name,r.id]
          return val[0] if val[1] == value.to_i
        end
      end
    end
    value
  end

  ################################################################################
  # convert the value produced by rails submit to an sql saveable value
  def self.convert_html_value(value,params={})
    value
  end

  ################################################################################
  def self.render_label(label,field_instance_id,form_object)
    %Q|<label class="label" for="#{build_html_id(field_instance_id)}">#{label}</label>#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function(field_instance_id)
    %Q|$F('#{build_html_id(field_instance_id)}')|
  end
  
  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    %Q|Event.observe('#{build_html_id(field_instance_id)}', 'change', function(e){ #{script} });|
  end

  def self.build_html_name(field_name)
    "record[#{field_name}]"
  end
  
  def self.build_html_multi_name(field_name,multi_elem_widget_value)
    "record[#{field_name}][#{multi_elem_widget_value}]"
  end

  def self.build_html_id(field_name)
    "record_#{field_name}"
  end

  def self.build_html_multi_id(field_name,multi_elem_widget_value)
    result = "record_#{field_name}_"
    if multi_elem_widget_value
      value = multi_elem_widget_value.to_s.downcase
      if value =~ /[^a-z0-9_]/
        value = value.split(//).collect {|c| c =~ /[^a-z0-9_]/ ? c.ord.to_s : c}.join('')
      end
      result << value
    end
    result
  end
  
  def self.field_types_allowed
    return nil
  end
  
  def self.multi_field_wrapper_html(field_name,html)
    <<-EOHTML
    <span id="#{build_html_id(field_name)}_wrapper">#{html}</span>
    EOHTML
  end

  protected
  
  def self.unflatten(array,cols)
    result = []
    sub = []
    array.each do |elem|
      sub << elem 
      if sub.size >= cols
        result << sub
        sub = []
      end
    end
    result << sub if sub.size > 0
    result
  end
  
  
  
end
################################################################################
Dir.foreach(File.join(File.dirname(__FILE__), 'widgets')) do |file|
  require 'metaform/widgets/' + file if file.match(/\.rb$/)
end
################################################################################
