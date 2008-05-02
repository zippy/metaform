################################################################################
class CheckBoxGroupWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    e = enumeration(options[:constraints])
    none_fields = []
    e.map!{|value_label,val|
      new_val = val.chomp('*')
      if new_val != val || val == 'none'
        none_fields << new_val
      end
      [value_label,new_val]
    }
    checked = value.split(/,/) if value
    checked ||= []
    result = []
    js_none = ""
    none_fields.each { |none_val|
      none_id = build_html_multi_id(field_instance_id,none_val)
      js_none << <<-EOJS
       if ($('#{none_id}')) {
         $('#{none_id}').checked = false;
       }
       EOJS
     }
    js = <<-EOJS
       function do_click_#{field_instance_id}_none(theCheckbox,theValue) {
           if (theCheckbox.checked) {  
             mapCheckboxGroup('#{build_html_name(field_instance_id)}',$('metaForm'),function(e,val){if (val != theValue) {e.checked=false}})
           }
    		}  
    		function do_click_#{field_instance_id}_regular(theCheckbox,theValue,theFollowupID) {
          var e = $(theFollowupID); 
          if (theCheckbox.checked) {
            #{js_none}
          } else {
            mapCheckboxGroup('record[#{field_instance_id}][_'+theValue+'-',$('metaForm'),function(el,val){el.checked=false})
          }           
   		  }
        
    	EOJS
    e.each do |key,val|
      if none_fields.include?(val) 
        # Javscript: uncheck all items in this checkbox group if the users clicks on none and also hide all the followups.
        javascript = "do_click_#{field_instance_id}_none(this,'#{val}')"
      else
        javascript = "do_click_#{field_instance_id}_regular(this,'#{val}')"
      end
      result << %Q|<input name="#{build_html_multi_name(field_instance_id,val)}" id="#{build_html_multi_id(field_instance_id,val)}" type="checkbox" value="#{val}" #{checked.include?(val) ? 'checked' : ''} onClick="#{javascript}"> #{key}|
    end
    params = options[:params]
    if params 
      (rows,cols) = params.split(/,/)
      result = unflatten(result,rows.to_i).collect {|col| col.join("<br />") }
      result = %Q|<table class="checkbox_group"><tr><td class="checkbox_group" valign="top">#{result.join('</td><td class="checkbox_group" valign="top">')}</td></tr></table>|
    else
      result = result.join("\n")
    end
    result + %Q|<input name="#{build_html_multi_name(field_instance_id,'__none__')}" id="#{build_html_multi_id(field_instance_id,'__none__')}" type="hidden"}>| +  "#{form.javascript_tag(js)}" 
  end

  def self.humanize_value(value,options=nil)
    e = enumeration(options[:constraints])
    checked = value.split(/,/) if value
    checked ||= []
    e = Hash[*e.collect {|r| r.reverse}.flatten]
    checked.collect {|c| e[c]}.join(', ')
  end
  
  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span>#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('#{build_html_name(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    e = enumeration(options[:constraints])
    result = ""
    e.each do |key,value|
       result << %Q|var watcher_#{build_html_multi_id(field_instance_id,value.chomp('*'))} = new WidgetWatcher('#{build_html_multi_id(field_instance_id,value.chomp('*'))}', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.is_multi_value?
    true
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    value.delete('__none__')
    return nil if value.size == 0
    value.keys.join(',')
  end
  
end
################################################################################
