################################################################################
class VolumeWidget < Widget
  
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
	params = options[:params]
	js_update_volume = <<-EOJS
			function #{build_html_multi_id(field_instance_id,'update_volume')}(change_ml) {
					if (change_ml) {
						var cups = parseFloat($F('#{build_html_multi_id(field_instance_id,'cups_box')}')); 
						if (isNaN(cups)) {cups=0};
						var ml = cups * 236.588237; 
						$('#{build_html_multi_id(field_instance_id,'ml_box')}').value = Math.round(ml);
					} else {
						var ml = parseFloat($F('#{build_html_multi_id(field_instance_id,'ml_box')}')); 
						if (isNaN(ml)) {ml=0};
						var total_cups = ml * 0.00422675283;
						$('#{build_html_multi_id(field_instance_id,'cups_box')}').value = Math.round(total_cups);
					}
			}
			EOJS
	  if value 
		ml = value	
		cups = (ml.to_i * 0.00422675283).round	
		<<-EOHTML
		<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'cups_box')}" id="#{build_html_multi_id(field_instance_id,'cups_box')}" value="#{cups}" onchange="#{build_html_multi_id(field_instance_id,'update_volume')}(true)" /> cups
		<input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'ml_box')}" id="#{build_html_multi_id(field_instance_id,'ml_box')}" value="#{ml}" onchange="#{build_html_multi_id(field_instance_id,'update_volume')}(false)" /> ml
		#{form.javascript_tag(js_update_volume)}
		EOHTML
	  else
		<<-EOHTML
		<input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'cups_box')}" id="#{build_html_multi_id(field_instance_id,'cups_box')}" onchange="#{build_html_multi_id(field_instance_id,'update_volume')}(true)" /> cups
		<input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'ml_box')}" id="#{build_html_multi_id(field_instance_id,'ml_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_volume')}(false)" /> ml
		#{form.javascript_tag(js_update_volume)}
		EOHTML
	  end
  end
  
  ################################################################################
  def self.humanize_value(value,options=nil)
    "#{value} ml"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$F("#{build_html_multi_id(field_instance_id,'ml_box')}")|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(cups_box ml_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
   		result = value['ml_box']
 	rescue
 		nil
    end
  end

end
################################################################################
