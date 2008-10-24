################################################################################
# This widget expects parameters:
# sublabel,[followups...]  and assumes a set constraint just like the checkboxgroup
#This widget handles 'none' values like checkboxgroup.  In addition, followup params
#can have * at the end of their value to act like 'none' within the followups.
class CheckBoxGroupFollowupWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    e = set(options[:constraints])
    result = []
    set_values = YAML.load(value) if value
    set_values ||= {}
    params =  options[:params].split(/,/)
    sub_label = params.shift
    none_fields_regular = []
    e.map!{|value_label,val|
      new_val = val.chomp('*')
      if new_val != val || val == 'none'
        none_fields_regular << new_val
      end
      [value_label,new_val]
    }
    none_fields_followup = []
    params.map!{|val|
      new_val = val.chomp('*')
      if new_val != val || val == 'none'
        none_fields_followup << new_val
      end
      new_val
    }
    js_none = ""
    js = ""
    if none_fields_regular.length > 0 
      none_fields_regular.each { |none_val|
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
              $$('.#{field_instance_id}').each(function(cb){
               var val = cb.value;
               if (val != theValue) {cb.checked = false};
               var followup_id='#{field_instance_id}_'+val;
               var h = $(followup_id);
               if (h != null) {
                 $$('.'+followup_id+'_followup').each(function(cb){cb.checked=false});
                 Effect.BlindUp(h, {duration:.5})}
              });
            }
     		}
      EOJS
    end
    js << <<-EOJS
    		function do_click_#{field_instance_id}_regular(theCheckbox,theValue,theFollowupID) {
          var e = $(theFollowupID); 
          if (theCheckbox.checked) {
            Effect.BlindDown(e, {duration:.5});
            #{js_none}
          } else {
            Effect.BlindUp(e, {duration:.5});
            $$('.#{field_instance_id}_'+theValue+'_followup').each(function(cb){cb.checked=false});
          }           
   		  }        
    	EOJS
    
    e.each do |value_label,val|
      checked = set_values[val]
      if none_fields_regular.include?(val) 
        followup_span = ''  # 'none' doesn't get followups
        # Javscript: uncheck all items in this checkbox group if the users clicks on none and also hide all the followups.
        javascript = "do_click_#{field_instance_id}_none(this,'#{val}')"
      else
        followups = []
        followup_id = "#{field_instance_id}_#{val}"
        params.each do |param|
          idx = "_#{val}-#{param}"
          id = build_html_multi_id(field_instance_id,idx)
          checked_string = (checked && checked.include?(param)) ? 'checked' : ''
          if none_fields_followup.include?(param)
            on_click_string = <<-EOJS
              onClick="  
                if ($('#{id}').checked) {$$('.#{field_instance_id}_#{val}_followup').each(function(cb){if (cb.value != '#{param}') {cb.checked=false}})};
                try{update_value_hash_for_cbfg('#{field_instance_id}',values_for_#{field_instance_id});condition_actions_for_#{field_instance_id}();}catch(err){};"
              EOJS
          elsif none_fields_followup.length > 0
            none_js = ''
            none_fields_followup.each { |none_field_val|
              none_id = build_html_multi_id(field_instance_id,"_#{val}-#{none_field_val}")
              none_js << <<-EOJS
                if ($('#{none_id}')) {
                  $('#{none_id}').checked = false;
                }              
              EOJS
            }
            on_click_string = <<-EOJS
              onClick="
                #{none_js};
                try{update_value_hash_for_cbfg('#{field_instance_id}',values_for_#{field_instance_id});condition_actions_for_#{field_instance_id}();}catch(err){};"
            EOJS
          end
          followups << <<-EOHTML
          <input name="#{build_html_multi_name(field_instance_id,idx)}" id="#{id}" class="#{field_instance_id}_#{val}_followup" type="checkbox" value="#{param}" #{checked_string} #{on_click_string}> #{param.humanize}
          EOHTML
        end  
        followup_span = <<-EOHTML 
          <span id="#{followup_id}" class="checkbox_followups" style="display:#{checked ? 'inline' : 'none'}">
          &nbsp;&nbsp; #{sub_label} #{followups.join("\n")}
          </span>
        EOHTML
        # Javscript: hide/show the followup (unchecking all items in the followup if hiding, and unchecking the none value if showing)
        javascript = "do_click_#{field_instance_id}_regular(this,'#{val}','#{followup_id}')"
      end  
      result << <<-EOHTML 
      <input name="#{build_html_multi_name(field_instance_id,'__none__')}" id="#{build_html_multi_id(field_instance_id,'__none__')}" type="hidden"}>
      <span class="check_box_followup_input"><input name="#{build_html_multi_name(field_instance_id,val)}" id="#{build_html_multi_id(field_instance_id,val)}" class="#{field_instance_id}" type="checkbox" value="#{val}" #{checked ? 'checked' : ''}
        onClick="#{javascript};try{update_value_hash_for_cbfg('#{field_instance_id}',values_for_#{field_instance_id});condition_actions_for_#{field_instance_id}();}catch(err){};">
        #{value_label}</span>
        #{followup_span}
      EOHTML
    end
    result.join("<br />") + '<div class="clear"></div>' + "#{form.javascript_tag(js)}"     
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    e = set(options[:constraints])
    set_values = YAML.load(value) if value
    set_values ||= {}
    params =  options[:params].split(/,/)
    sub_label = params.shift
    params.map!{|val|
      new_val = val.chomp('*')
      new_val
    }
    e = Hash[*e.collect {|r| 
      r[1] = r[1].chomp('*')
      r.reverse}.flatten]
    result = []
    set_values.each {|key,value|
      result << e[key] + ':  ' + value.collect!{|v| v.humanize}.join(', ')
    }
    result.join('\n')
  end
  
  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span><br />#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('.#{field_instance_id}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    #Note that this is not an observe function!  CheckboxFollowupGroup widgets have a try block in their onClick handler.  This will
    #call fhe following function if it is present.  It will be present if this field_instance_id is listed as a fields used for a condition.
    %Q|function condition_actions_for_#{field_instance_id}(){#{script}}|
  end
  
  ################################################################################  
  def self.update_value_hash_function(field_instance_id)
    %Q|update_value_hash_for_cbfg('#{field_instance_id}',values_for_#{field_instance_id})|
  end
  
  ################################################################################
  def self.convert_html_value(value,params={})
    value.delete('__none__')
    return nil if value.size == 0
    result = {}
    value.each do |key,value|
      if key =~ /^_(.*)-(.*)/
        result[$1] ||= []
        result[$1] << value
      else
        result[value] ||= []
      end
    end
    result
  end
  
end
################################################################################
