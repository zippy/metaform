################################################################################
class OptionalNoteWidget < Widget
  ################################################################################
  def self.render_form_object(form,field_instance_id,value,options)
  	params = options[:params]
  	if params
  		(size,inner_html) = params.split(/,/)
		opts = size ? {:size => size, :style=>'display:none'} : {:size => 25,:style=>'display:none'}
		inner_html = '' if !inner_html
		result = "&nbsp;&nbsp;"
		div_id = build_html_name(field_instance_id)
		result << form.link_to_function((value && value != '') ? 'Edit Note' : 'Add Note', 
		  "Effect.toggle($('#{div_id}'),'blind',{duration: .3});if(this.innerHTML=='Add Note') {this.innerHTML='Hide Note'} else {this.innerHTML='Add Note'};", #$('#{field_instance_id}_link').update('hide');
		  :id => "#{field_instance_id}_link")
		result << inner_html
		result << <<-EOHTML
		#{form.text_field_tag(build_html_name(field_instance_id),value,opts)}
		EOHTML
		result
	end
  end
  
    
end
################################################################################
