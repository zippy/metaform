################################################################################
# This widget expects parameters:
# (factor, first_label, second_label) where factor is the ratio between the units 
# of the first textfield and the second textfield.  
class FactorTextFieldsWidget < Widget
  self.extend Utilities
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
   params = options[:params]
    if params
      (factor,first_label,second_label) = params.split(/,/)
      result = ''
      if !value.blank?
        (first_value,second_value) = parse_value(value,factor)
      	result <<  <<-EOHTML
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'first_box')}" id="#{build_html_multi_id(field_instance_id,'first_box')}" value="#{first_value}" /> #{first_label}
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'second_box')}" id="#{build_html_multi_id(field_instance_id,'second_box')}" value="#{second_value}" /> #{second_label}
EOHTML
      else
      	result << <<-EOHTML
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'first_box')}" id="#{build_html_multi_id(field_instance_id,'first_box')}"/> #{first_label}
<input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'second_box')}" id="#{build_html_multi_id(field_instance_id,'second_box')}"  /> #{second_label}
EOHTML
      end
      result << %Q|<input type="hidden" name="#{build_html_multi_name(field_instance_id,'factor')}"  id="#{build_html_multi_id(field_instance_id,'factor')}"/ value="#{factor}">|
    end
  end

  def self.parse_value(value,factor)
  	first_value = value.to_i / factor.to_i
  	second_value = value.to_i % factor.to_i
  	[first_value,second_value]
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    params = options[:params]
    if params
      (factor,first_label,second_label) = params.split(/,/)
      if value 
        (first_value,second_value) = parse_value(value,factor)
        "#{first_value} #{first_label} #{second_value} #{second_label}"
      end
  	end
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$FTF('#{build_html_id(field_instance_id)}')|
  end
  
  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(first_box second_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    factor = params.split(/,/)[0];
    first_box = value['first_box']
    second_box = value['second_box']
    return '' if first_box.blank? && second_box.blank?
    return nil if !is_integer?(first_box) || !is_integer?(second_box)
    (first_box.to_i * factor.to_i + second_box.to_i).to_s
  end

end
################################################################################
