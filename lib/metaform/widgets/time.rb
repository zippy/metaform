################################################################################
class TimeWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    meridian_options = [ ["AM","am"] , ["PM","pm"] ]
    require 'parsedate'
    if value
      d = *ParseDate.parsedate(value)
      date = Time.local(1,1,1,d[3],d[4])      
      hours = date.hour
      meridian = "am"
      if (hours > 12)
      	hours = hours - 12
      	meridian =  "pm"
	  end
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours &')}" id="#{build_html_multi_id(field_instance_id,'hours')}" value="#{hours}" />:
      <input type="text" class="narrow_left_margin" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}" value="#{date.min}" />
      <select name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
      	#{form.options_for_select(meridian_options, meridian)}
	  </select>
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'hours &')}" id="#{build_html_multi_id(field_instance_id,'hours')}"/>:
      <input type="text" class="narrow_left_margin" size=2 name="#{build_html_multi_name(field_instance_id,'minutes')}" id="#{build_html_multi_id(field_instance_id,'minutes')}"  />
      <select name="#{build_html_multi_name(field_instance_id,'am_pm')}" id="#{build_html_multi_id(field_instance_id,'am_pm')}">
	  	   #{form.options_for_select(meridian_options, "am")}
	  </select>
      EOHTML
    end
  end


  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(hours minutes am_pm).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
      factor = value['am_pm'] == 'am' ? 0 : 12	
      date = Time.local(1,1,1,value['hours'].to_i + factor,value['minutes'])
      date.strftime('%H:%M')
    rescue
      nil
    end
    
  end

end
################################################################################
