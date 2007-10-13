################################################################################
# This widget expects parameters:
# sublabel,[followups...]  and assumes a set constraint just like the checkboxgroup
class CheckBoxGroupFollowupWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)

    e = enumeration(options[:constraints],'set')
    result = []
    set_values = YAML.load(value) if value
    set_values ||= {}
    
    params = options[:params].split(/,/)
    sub_label = params.shift

    e.each do |value_label,val|
      checked = set_values[val]
      followup_id = "#{field_instance_id}_#{val}"

      idx = "_#{val}-none"
      none_checked = checked && checked['none']
      followups = [<<-EOHTML
        <input name="#{build_html_multi_name(field_instance_id,idx)}" id="#{build_html_multi_id(field_instance_id,idx)}" type="checkbox" value="none" #{ none_checked ? 'checked' : ''}> None
        EOHTML
        ]
      params.each do |i|
        idx = "_#{val}-#{i}"
        followups << <<-EOHTML
        <input name="#{build_html_multi_name(field_instance_id,idx)}" id="#{build_html_multi_id(field_instance_id,idx)}" type="checkbox" value="#{i}" #{ (checked && checked[i]) ? 'checked' : ''}> #{i.humanize}
        EOHTML
      end

      result << <<-EOHTML 
        <input name="#{build_html_multi_name(field_instance_id,val)}" id="#{build_html_multi_id(field_instance_id,val)}" type="checkbox" value="#{val}" #{checked ? 'checked' : ''}
        onClick="var e = $('#{followup_id}'); this.checked ? e.show() : e.hide();">
        #{value_label}
        <span id="#{followup_id}" class="checkbox_followups" style="display:#{checked ? 'inline' : 'none'}">
        &nbsp;&nbsp; #{sub_label} #{followups.join("\n")}
        </span>
      EOHTML
    end

    result.join("<br />")
    
  end

  ################################################################################
  def self.render_label (label,field_instance_id,form_object)
    %Q|<span class="label">#{label}</span><br />#{form_object}|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$CF('#{build_html_name(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    e = enumeration(constraints,'set')
    result = ""
    e.each do |key,value|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,value)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.is_multi_value?
    true
  end
  
  
  ################################################################################
  def self.convert_html_value(value)
    result = {}
    value.each do |key,value|
      if key =~ /^_(.*)-(.*)/
        result[$1] ||= []
        result[$1] << value
      else
        result[value] ||= []
      end
    end
    raise result.inspect
  end
  
end
################################################################################
