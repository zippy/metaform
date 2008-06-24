################################################################################
class PopUpWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
  #puts "line 1 popupwidget"
    e = enumeration(options[:constraints])
    e.unshift([options[:params],nil]) if options[:params]  # the popup widget param is the text for a nil option
    e.map!{|x| [x[0],x[1].to_s]}
    #puts "line 2 popupwidget"
    raise "enumeration not specified for #{field_instance_id}" if !e
    if value
      <<-EOHTML
<select name="#{build_html_name(field_instance_id)}" id="#{build_html_id(field_instance_id)}">
	#{form.options_for_select(e, value)}
</select>
      EOHTML
    else
      <<-EOHTML
<select name="#{build_html_name(field_instance_id)}" id="#{build_html_id(field_instance_id)}">
   #{form.options_for_select(e)}
</select>
      EOHTML
    end
  end
  ################################################################################
  def self.humanize_value(value,options=nil)
    e = enumeration(options[:constraints])
    e = Hash[*e.collect {|r| r.reverse}.flatten]
    e[value]
  end
end
################################################################################
