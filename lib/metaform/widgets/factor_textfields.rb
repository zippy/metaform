################################################################################
# This widget expects parameters:
# (factor, first_label, second_label) where factor is the ration between the units 
# of the first textfield and the second textfield.  
class FactorTextFieldsWidget < Widget
  
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
   params = options[:params]
    if params
      (factor,first_label,second_label) = params.split(/,/)
      if value 
      	first_value = value.to_i / factor.to_i
      	second_Value = value.to_i % factor.to_i
      	<<-EOHTML
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'first_box')}" id="#{build_html_multi_id(field_instance_id,'first_box')}" value="#{first_value}" /> #{first_label}
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'second_box')}" id="#{build_html_multi_id(field_instance_id,'second_box')}" value="#{second_Value}" /> #{second_label}
EOHTML
      else
      	<<-EOHTML
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'first_box')}" id="#{build_html_multi_id(field_instance_id,'first_box')}"/> #{first_label}
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'second_box')}" id="#{build_html_multi_id(field_instance_id,'second_box')}"  /> #{second_label}
EOHTML
      end
    end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    params = options[:params]
    if params
      (factor,first_label,second_label) = params.split(/,/)
      if value 
    	  first_value = value.to_i / factor.to_i
    	  second_Value = value.to_i % factor.to_i
        "#{first_value} #{first_label} #{second_Value} #{second_label}"
      end
  	end
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$DF('#{build_html_id(field_instance_id)}')|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(first_box second_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    begin
    	factor = params.split(/,/)[0];
    	result = (value['first_box'].to_i * factor.to_i + value['second_box'].to_i).to_s
 	rescue
 		nil
    end
  end

end
################################################################################
