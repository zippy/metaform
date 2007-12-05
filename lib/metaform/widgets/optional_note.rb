################################################################################
class OptionalNoteWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
  	opts = options[:params] ? {:size => options[:params], :style=>'display:none'} : {:size => 25,:style=>'display:none'}
    result = "&nbsp;&nbsp;"
#    div_id = "#{field_instance_id}_optional_note"
    div_id = build_html_name(field_instance_id)
    result << form.link_to_function((value && value != '') ? 'Edit Note' : 'Add Note', 
      "Effect.toggle($('#{div_id}'),'blind',{duration: .3});", #$('#{field_instance_id}_link').update('hide');
      :id => "#{field_instance_id}_link")
    result << <<-EOHTML
   	#{form.text_field_tag(build_html_name(field_instance_id),value,opts)}
    EOHTML
    result
  end
    
end
################################################################################

