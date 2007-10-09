################################################################################
class DateWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
    require 'parsedate'
    date = Time.local(*ParseDate.parsedate(value))
    <<-EOHTML
    <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'month')}" id="#{build_html_multi_id(field_instance_id,'month')}" value="#{date.month}" /> /
    <input type="text" size=2 name="#{build_html_multi_name(field_instance_id,'day')}" id="#{build_html_multi_id(field_instance_id,'day')}" value="#{date.day}" /> /
    <input type="text" size=4 name="#{build_html_multi_name(field_instance_id,'year')}" id="#{build_html_multi_id(field_instance_id,'year')}" value="#{date.year}" />
    EOHTML
  end

  ################################################################################
  def self.convert_html_value(value)
    date = Time.local(value['year'],value['month'],value['day'])
    date.strftime('%Y-%m-%d')
  end

end
################################################################################
