# Thanks to Peter Jones (pmade.com) for inspiring this coding pattern
################################################################################
class Widget
  ################################################################################
  def self.inherited(klass)
    instance_eval { (@widgets ||= {}).store(klass.to_s.sub(/Widget/, ''), klass) }
  end

  ################################################################################
  def self.list
    instance_eval {@widgets.keys}
  end
  
  def self.enumeration (constraints)
    
    constraint_name = nil
    #TODO this is stupid.  Fix!
    ['enumeration','set','enumeration_lookup','set_lookup'].each {|e| constraint_name = e if constraints.has_key?(e); }
    raise constraints.inspect if !constraint_name
    if constraints && constraints[constraint_name]
      case 
      when constraint_name == 'enumeration' || constraint_name == 'set'
        enum = constraints[constraint_name].collect{|h| h.is_a?(Hash) ? h.to_a[0].reverse : [h.to_s.humanize,h.to_s] }
      when constraint_name =~ /(set|enumeration)_lookup/
        spec = constraints[constraint_name]
        #spec[:model] can be a string or a class
        model = spec[:model].is_a?(String) ? spec[:model].constantize : spec[:model]
        results = model.find(*spec[:find_args])
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
  def self.render(form,field_instance_id,value,label,options={})
    render_label(label,field_instance_id,render_form_object(form,field_instance_id,value,options))
  end

  ################################################################################
  # convert the value produced by rails submit to an sql saveable value
  def self.convert_html_value(value)
    value
  end
  
  ################################################################################
  # TODO at some point this needs to be generalized into a value type system i.e
  # scalar/array/hash
  def self.is_multi_value?
    false
  end

  ################################################################################
  def self.render_label(label,field_instance_id,form_object)
    %Q|<label class="label" for="#{build_html_name(field_instance_id)}">#{label}</label>#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function(field_instance_id)
    %Q|$F('#{build_html_id(field_instance_id)}')|
  end
  
  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
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
      value = value.gsub(/[^a-z0-9_]/i,'')
      result << value
    end
    result
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
