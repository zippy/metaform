################################################################################
class WeightLbkgWidget < Widget
  
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
	params = options[:params]
	js_update_height = <<-EOJS
			function #{build_html_multi_id(field_instance_id,'update_height')}(change_kilograms) {
					if (change_kilograms) {
						var pounds = parseFloat($F('#{build_html_multi_id(field_instance_id,'pounds_box')}')); 
						if (isNaN(pounds)) {pounds=0};
						var kilograms = Math.round(pounds *  4.5359237)/10; 
						$('#{build_html_multi_id(field_instance_id,'kilograms_box')}').value = kilograms;
					} else {
						var kilograms = parseFloat($F('#{build_html_multi_id(field_instance_id,'kilograms_box')}')); 
						if (isNaN(kilograms)) {kilograms=0};
						var pounds = kilograms * 2.20462262;
						$('#{build_html_multi_id(field_instance_id,'pounds_box')}').value = Math.round(pounds);
					}
			}
			EOJS
	  if value 
		kilograms = (value.to_f / 100).round.to_f / 10 # We store the value as grams and want it displayed to 1 decimal places
		pounds = (kilograms * 2.20462262).round
		<<-EOHTML
		<input type="text" size=2 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}" value="#{pounds}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> lb or
		<input type="text" size=4 class="textfield_5" name="#{build_html_multi_name(field_instance_id,'kilograms_box')}" id="#{build_html_multi_id(field_instance_id,'kilograms_box')}" value="#{kilograms}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(false)" /> kg
		#{form.javascript_tag(js_update_height)}
		EOHTML
	  else
		<<-EOHTML
		<input type="text" size=2 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> lb
		<input type="text" size=4 class="textfield_5" name="#{build_html_multi_name(field_instance_id,'kilograms_box')}" id="#{build_html_multi_id(field_instance_id,'kilograms_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_height')}(false)" /> kg
		#{form.javascript_tag(js_update_height)}
		EOHTML
	  end
  end
  
  ################################################################################
  def self.humanize_value(value,options=nil)
    "#{value} kilograms"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(feet_box pounds_box kilograms_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
   		result = value['kilograms_box'].to_f * 1000 #Store as grams
 	rescue
 		nil
    end
  end

end
################################################################################
