################################################################################
class OptionalNoteWidget < Widget
  ################################################################################
  def self.render_form_object(field_instance_id,value,options)
  	params = options[:params]
  	if params
  		(size,middle_html) = params.split(/,/)
		opts = size ? {:size => size, :style=>'display:none'} : {:size => 25,:style=>'display:none'}
		result = "&nbsp;&nbsp;"
		div_id = build_html_id(field_instance_id)
		result << form.link_to_function('',"do_click_#{field_instance_id}()",:id => "#{field_instance_id}_link")
		result << middle_html if middle_html
		result << "#{form.text_field_tag(build_html_name(field_instance_id),value,opts)}"
		js = <<-EOJS
		function do_click_#{field_instance_id}() {
			update_label_#{field_instance_id}(false);
			Effect.toggle($('#{div_id}'),'blind',{duration: .3});
		}
		
		function update_label_#{field_instance_id}(visible_bool) {
		 var label;
		 if( $('#{div_id}').visible() == visible_bool ) {
		  	label='Hide Note';
		  } else {
		  	if( ($('#{div_id}').value)=='') {
		  		label='Optional Note';
		  	} else {
		  		label='Show Note';
		  	}
		  }		  
		  $('#{field_instance_id}_link').innerHTML=label;
		  }
		  update_label_#{field_instance_id}(true);
		EOJS
		result << "#{form.javascript_tag(js)}"
		result
	end
  end
  
    
end
################################################################################




