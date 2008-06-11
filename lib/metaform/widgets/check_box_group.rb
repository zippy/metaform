################################################################################
#This widget assumes that if a checkbox has a value of 'none', then that checkbox
#should be a special type that un-checks all other checkboxes in the group.  Also,
#any other checkbox in the group will un-check a 'none' checkbox.  The user can
#make any checkbox a act like 'none' by putting a '*' at the end of its value.
#For example, value = 'none__sometimes*' and value = 'none__never*' will have the
#stripped off and then act as none.
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
    js = ""
    if none_fields.length > 0 
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
        function do_click_#{field_instance_id}_regular(checked) {
          if (checked) {#{js_none}}           
    		}
    		EOJS
    	js << <<-EOJS
           function do_click_#{field_instance_id}_none(checked,theValue) {
               if (checked) {  
                 $$('.#{field_instance_id}').each(function(cb) {
                   if (cb.value != theValue) {cb.checked = false}
                 });
               }
        		}          
      EOJS
      js = form.javascript_tag(js)
    end


    e.each do |key,val|
      if none_fields.include?(val) 
        # Javscript: uncheck all items in this checkbox group if the users clicks on a none-type value.
        javascript = "do_click_#{field_instance_id}_none(this.checked,'#{val}')"
      else
          # Javscript: uncheck all none items in this checkbox group if the users clicks on a regular value.
          javascript = (none_fields.length > 0) ? "do_click_#{field_instance_id}_regular(this.checked)" : ""
      end
      result << %Q|<input name="#{build_html_multi_name(field_instance_id,val)}" id="#{build_html_multi_id(field_instance_id,val)}" class="#{field_instance_id}" type="checkbox" value="#{val}" #{checked.include?(val) ? 'checked ' : ''}onClick="#{javascript}"> #{key}|
    end
    params = options[:params]
    if params 
      (rows,cols,table_class) = params.split(/,/)
      table_class ||= 'checkbox_group_table'
      result = unflatten(result,rows.to_i).collect {|col| col.join("<br />") }
      i = 0
      result.map!{|r| i = i + 1; "<td class='checkbox_group_cell col_#{i}' valign='top'>#{r}</td>"}
      result = %Q|<table class="#{table_class}"><tr>#{result.join}</tr></table>|
    else
      result = result.join("\n")
    end
    result + %Q|<input name="#{build_html_multi_name(field_instance_id,'__none__')}" id="#{build_html_multi_id(field_instance_id,'__none__')}" type="hidden"}>| +  js 
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    e = enumeration(options[:constraints])
    checked = value.split(/,/) if value
    checked ||= []
    e = Hash[*e.collect {|r| 
      r[1] = r[1].chomp('*')
      r.reverse}.flatten]
    checked.collect {|c| e[c]}.join(', ')
  end
  
  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span>#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('.#{field_instance_id}')|    
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    e = enumeration(options[:constraints])
    result = ""
    e.each do |key,value|
       new_val = value.chomp('*')
       #result << %Q|var watcher_#{build_html_multi_id(field_instance_id,new_val)} = new WidgetWatcher('#{build_html_multi_id(field_instance_id,new_val)}', function(e){ #{script} });\n|
       result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,new_val)}', 'click', function(e){ #{script} });\n|
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
