###################################################################
# a property can be attached to a field.  Properties are used
# to implement validity checking for fields

#TODO implment caching of property-values
class Property
  # override evaluate to return the result of the property
  def self.evaluate(form,field,value)
    false
  end
  def self.render(question_html,property_value,question,form,field,read_only)
    question_html + property_value.to_s
  end
end

class Invalid < Property
  def self.evaluate(form,field,value)
    Constraints.verify(field.constraints, value, form)
  end
  def self.render(question_html,property_value,question,form,field,read_only)
    if !property_value.empty? && (v = form.validating?) && !read_only
      errs = property_value.join("; ")
      if v != :no_explanation
        error_class = "validation_item"
        fname = question.field.name
        index = form.index
        if index != Form::MultiIndexMarker  # if this is template render we don't include explanation or approval html
          ex_val = form.get_record.explanation(fname,index)
          if v == :approval
            achecked = ''
            if form.field_state(fname) == 'approved'
              achecked =  'checked'
            end
            vals = {
              'err'=>errs.to_s,
              'exp'=>ex_val.to_s,
              'chk'=> %Q|<input tabindex=\"1\" name=\"approvals[#{fname}][#{index}]\" id=\"approvals_#{fname}_#{index}\" type="checkbox" value=\"Y\" #{achecked}>|
              }

            err_message_template = field.constraints["err__explanation_approval"]
            err_message_template ||= $metaform_error_messages['_explanation_approval']
            txt ||= Constraints.fill_error(err_message_template,vals)
            errs = txt.gsub(/\?\{(.*?)\}/) {|key| vals[$1]} +
                    %Q|<input name=\"approvals[#{fname}][#{index}]\" id=\"approvals_#{fname}_#{index}\"  type="hidden" value=\"\" >|
          else
            err_message_template = field.constraints["err__explanation"]
            err_message_template ||= $metaform_error_messages['_explanation']
            txt ||= Constraints.fill_error(err_message_template,{'exp'=>"<input tabindex=\"1\" id=\"explanations_#{fname}_#{index}\" name=\"explanations[#{fname}][#{index}]\" type=\"text\" value=\"#{ex_val}\" />"})
            errs += txt
          end
        end
      else
        error_class = "validation_error"
      end
      question_html + %Q| <div class="#{error_class}">#{errs}</div>|
    else
      question_html
    end
  end
end