################################################################################
class WeightWidget < Widget
  self.extend Utilities

  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    params = options[:params]
    js_update_weight = <<-EOJS
      function #{build_html_multi_id(field_instance_id,'update_weight')}(change_grams) {
          if (change_grams) {
            var pounds = check_float($F('#{build_html_multi_id(field_instance_id,'pounds_box')}'));
            var ounces = check_float($F('#{build_html_multi_id(field_instance_id,'ounces_box')}'));
            if ((pounds==null) && (ounces==null)){
              $('#{build_html_multi_id(field_instance_id,'grams_box')}').value=''
            }else{
              if (pounds==null) { $('#{build_html_multi_id(field_instance_id,'pounds_box')}').value=''; pounds = 0};
              if (ounces==null) { $('#{build_html_multi_id(field_instance_id,'ounces_box')}').value=''; ounces = 0};
              var grams = (pounds * 16 + ounces) * 28.3495231;
              $('#{build_html_multi_id(field_instance_id,'grams_box')}').value = Math.round(grams);
            }
          } else {
            var grams = check_float($F('#{build_html_multi_id(field_instance_id,'grams_box')}'));
            if (grams==null){
              $('#{build_html_multi_id(field_instance_id,'pounds_box')}').value='';
              $('#{build_html_multi_id(field_instance_id,'ounces_box')}').value='';
            }else{
              var total_ounces = grams * 0.0352739619;
              $('#{build_html_multi_id(field_instance_id,'pounds_box')}').value = Math.floor(total_ounces / 16);
              $('#{build_html_multi_id(field_instance_id,'ounces_box')}').value = Math.round(total_ounces % 16);
            }
          }
      }
      EOJS
    if !value.blank?
      grams = value
      total_ounces = (grams.to_i * 0.0352739619).round
      pounds = total_ounces / 16
      ounces = total_ounces % 16
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}" value="#{pounds}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> lb
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'ounces_box')}" id="#{build_html_multi_id(field_instance_id,'ounces_box')}" value="#{ounces}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> oz or
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'grams_box')}" id="#{build_html_multi_id(field_instance_id,'grams_box')}" value="#{grams}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(false)" /> g
      #{form.javascript_tag(js_update_weight)}
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'pounds_box')}" id="#{build_html_multi_id(field_instance_id,'pounds_box')}" onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> lb
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'ounces_box')}" id="#{build_html_multi_id(field_instance_id,'ounces_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(true)" /> oz or
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'grams_box')}" id="#{build_html_multi_id(field_instance_id,'grams_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_weight')}(false)" /> g
      #{form.javascript_tag(js_update_weight)}
      EOHTML
      end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    "#{value} grams"
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$F("#{build_html_multi_id(field_instance_id,'grams_box')}")|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,options)
    result = ""
    %w(pounds_box ounces_box grams_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    val = value['grams_box']
    return '' if val.blank?
    return val if is_integer?(val)
    nil
  end

end
################################################################################
