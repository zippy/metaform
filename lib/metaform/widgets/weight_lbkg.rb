################################################################################
class WeightLbkgWidget < Widget
  self.extend Utilities
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    params = options[:params]
    allow_negatives = (params == "allow_negatives") ? "true" : "null"
    js_update_weight = <<-EOJS
function #{build_html_multi_id(field_instance_id,'update_weight')}(change_kilograms) {
 if (change_kilograms) {
  var pounds = check_float($F('#{build_html_multi_id(field_instance_id,'pounds_box')}'),#{allow_negatives});
  if (pounds == null) {
    $('#{build_html_multi_id(field_instance_id,'kilograms_box')}').value='';
  } else {
    $('#{build_html_multi_id(field_instance_id,'kilograms_box')}').value = Math.round(pounds *  4.5359237)/10;
   }
 } else {
  var kilograms = check_float($F('#{build_html_multi_id(field_instance_id,'kilograms_box')}'),#{allow_negatives});
  if (kilograms == null) {
    $('#{build_html_multi_id(field_instance_id,'pounds_box')}').value='';
  }else {
    $('#{build_html_multi_id(field_instance_id,'pounds_box')}').value = Math.round(kilograms * 2.20462262);
  }
 }
}
EOJS
    if !value.blank?
      kilograms = (value.to_f / 100).round.to_f / 10 # We store the value as grams and want it displayed to 1 decimal places
      pounds = (kilograms * 2.20462262).round
      <<-EOHTML
      <input type="text" size=2 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}" value="#{pounds}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> lb or
      <input type="text" size=4 class="textfield_5" name="#{build_html_multi_name(field_instance_id,'kilograms_box')}" id="#{build_html_multi_id(field_instance_id,'kilograms_box')}" value="#{kilograms}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(false)" /> kg
      #{form.javascript_tag(js_update_weight)}
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> lb or
      <input type="text" size=4 class="textfield_5" name="#{build_html_multi_name(field_instance_id,'kilograms_box')}" id="#{build_html_multi_id(field_instance_id,'kilograms_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(false)" /> kg
      #{form.javascript_tag(js_update_weight)}
      EOHTML
    end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    kilograms = (value.to_f / 1000)
    pounds = (kilograms * 2.20462262)
    "#{sprintf("%.1f",pounds)} lb (#{sprintf("%.1f",kilograms)} kg)"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$F("#{build_html_multi_id(field_instance_id,'grams_box')}")|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(pounds_box kilograms_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    val = value['kilograms_box']
    return '' if val.blank?
    if is_numeric?(val)
      val = val.to_f * 1000 
      return nil if !(params == "allow_negatives") && val < 0
      val
    else
      nil
    end
  end

end
################################################################################
