################################################################################
class HeightWidget < Widget
  self.extend Utilities
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
    params = options[:params]
    js_update_height = <<-EOJS
      function #{build_html_multi_id(field_instance_id,'update_height')}(change_meters) {
        if (change_meters) {
          var feet = check_float($F('#{build_html_multi_id(field_instance_id,'feet_box')}'));
          var inches = check_float($F('#{build_html_multi_id(field_instance_id,'inches_box')}'));
          if (feet == null && inches == null){
              $('#{build_html_multi_id(field_instance_id,'meters_box')}').value=''
            }else{
              if (feet == null) { $('#{build_html_multi_id(field_instance_id,'feet_box')}').value=''; feet = 0};
              if (inches == null) { $('#{build_html_multi_id(field_instance_id,'inches_box')}').value=''; inches = 0};
               var meters = Math.round((feet * 12 + inches) *  2.54)/100;
              $('#{build_html_multi_id(field_instance_id,'meters_box')}').value = meters;
            }
          } else {
            var meters = check_float($F('#{build_html_multi_id(field_instance_id,'meters_box')}'));
            if (meters == null){
              $('#{build_html_multi_id(field_instance_id,'feet_box')}').value='';
              $('#{build_html_multi_id(field_instance_id,'inches_box')}').value='';
            }else{
              var total_inches = meters * 39.370079;
              var feet = Math.floor(total_inches / 12);
              var inches = Math.round(total_inches % 12);
              if (inches == 12) {
                feet++;
                inches = 0;
              }
              $('#{build_html_multi_id(field_instance_id,'feet_box')}').value = feet;
              $('#{build_html_multi_id(field_instance_id,'inches_box')}').value = inches;
            }
          }
      }
      EOJS
    if !value.blank?
      meters = value.to_f.round.to_f / 100 # We store the value as centimeters
      total_inches = (meters * 39.370079).round
      feet = total_inches / 12
      inches = total_inches % 12
      if (inches == 12)
        feet++
        inches = 0
      end
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'feet_box')}" id="#{build_html_multi_id(field_instance_id,'feet_box')}" value="#{feet}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> ft
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'inches_box')}" id="#{build_html_multi_id(field_instance_id,'inches_box')}" value="#{inches}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> in or
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'meters_box')}" id="#{build_html_multi_id(field_instance_id,'meters_box')}" value="#{meters}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(false)" /> m
      #{form.javascript_tag(js_update_height)}
      EOHTML
    else
      <<-EOHTML
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'feet_box')}" id="#{build_html_multi_id(field_instance_id,'feet_box')}" onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> ft
      <input type="text" size=2 class="textfield_2" name="#{build_html_multi_name(field_instance_id,'inches_box')}" id="#{build_html_multi_id(field_instance_id,'inches_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_height')}(true)" /> in or
      <input type="text" size=4 class="textfield_4" name="#{build_html_multi_name(field_instance_id,'meters_box')}" id="#{build_html_multi_id(field_instance_id,'meters_box')}"  onchange="#{build_html_multi_id(field_instance_id,'update_height')}(false)" /> m
      #{form.javascript_tag(js_update_height)}
      EOHTML
    end
  end

  ################################################################################
  def self.humanize_value(value,options=nil)
    return '' if value.nil?
    meters = value.to_f / 100 # We store the value as centimeters
    total_inches = (meters * 39.370079).round
    feet = total_inches / 12
    inches = total_inches % 12
    %Q|#{feet}' #{inches}" (#{value} cm)|
  end

  ################################################################################
  def self.javascript_get_value_function (field_instance_id)
    %Q|$F("#{build_html_multi_id(field_instance_id,'meters_box')}") * 100|
  end

  ################################################################################
  def self.javascript_build_observe_function(field_instance_id,script,constraints)
    result = ""
    %w(feet_box inches_box meters_box).each do |field|
      result << %Q|Event.observe('#{build_html_multi_id(field_instance_id,field)}', 'change', function(e){ #{script} });\n|
    end
    result
  end

  ################################################################################
  def self.convert_html_value(value,params={})
    meters = value['meters_box']
    return '' if meters.blank?
    return nil if !is_numeric?(meters)
    meters.to_f * 100 #Store as centimeters
  end

end
################################################################################
