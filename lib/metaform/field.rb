class Field < Bin
  def bins
    {
      :name => nil,
      :label => nil,
      :type => nil,
      :constraints => nil,
      :followups => nil,
      :followup_name_map => nil,
      :default => nil,
      :indexed_default_from_null_index => nil,
      :calculated => nil,
      :properties => [Invalid],
      :calculated => nil,
      :default => nil, 
      :indexed_default_from_null_index => nil
    }
  end
  def required_bins
    [:name,:type]
  end
end

class Workflow < Bin
  def bins 
    { :actions => nil, :states => nil}
  end
end

class Presentation < Bin
  def bins 
    { :name => nil, :block => nil, :legal_states => nil, :create_with_workflow => nil, :initialized => false, :question_names => {}}
  end
  def required_bins
    [:name , :block]
  end
end

class Question < Bin
  def bins
    {
      :field => nil,
      :appearance => nil, #TODO remove me!
      :widget => nil,
      :params => nil
    }
  end
  def required_bins
    [:field, :widget]
  end
  
  def get_widget
    Widget.fetch(widget)
  end
  
  def render(form,value = nil)
    require 'erb'

    w = get_widget
    widget_options = {:constraints => field.constraints, :params => params}
    widget_options[:read_only] = read_only if !read_only.nil?

    field_label = field.label
    field_name = field.name
    field_label = field_name.humanize if field_label.nil?
    postfix = labeling[:postfix] if labeling && labeling.has_key?(:postfix)
    postfix ||= form.label_options[:postfix] if form.label_options.has_key?(:postfix)
    field_label = field_label + postfix if postfix

    #TODO -FIXME!!  FormProxy should totally disapear
    form_proxy = FormProxy.new('SampleForm'.gsub(/ /,'_'))
    if erb
      field_element = read_only ?
        w.render_form_object_read_only(form_proxy,field_name,value,widget_options) :
        w.render_form_object(form_proxy,field_name,value,widget_options)
    end
    field_html = w.render(form_proxy,field_name,value,field_label,widget_options)

    css_class_html = %Q| class="#{css_class}"| if css_class
    
    properties = field.properties
    properties.each {|p| field_html=p.render(field_html,p.evaluate(form,field,value),self,form)} if properties
  
    if erb
      field_html = ERB.new(erb).result(binding)
    else
      field_html =  %Q|<div id="question_#{field.name}"#{css_class_html}#{initially_hidden ? ' style="display:none"' : ""}>#{field_html}</div>|
    end
        
    field_html
  end
end