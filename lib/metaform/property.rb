###################################################################
# a property can be attached to a field.  Properties are used
# to implement validity checking for fields

#TODO implment caching of property-values
class Property
  # override evaluate to return the result of the property
  def self.evaluate(form,field,value)
    false
  end
  def self.render(question_html,property_value,question,form,read_only)
    question_html + property_value.to_s
  end
end

class Invalid < Property
  def self.evaluate(form,field,value)
    form.validating? ? Constraints.verify(field.constraints, value, form) : []
  end
  def self.render(question_html,property_value,question,form,read_only)
    if !property_value.empty? && (v = form.validating?) && !read_only
      errs = property_value.join("; ")
      if v != :no_explanation
        error_class = "validation_item"
        fname = question.field.name
        ex_val = form.get_record.explanation(fname)
#        if read_only
#          errs += ex_val.blank? ? ";(no explanation given)" : "; (explained with: #{ex_val})"
#        else
          errs += "; please correct (or explain here: <input id=\"explanations_#{fname}\" name=\"explanations[#{fname}]\" type=\"text\" value=\"#{ex_val}\" />)"
#        end
      else
        error_class = "validation_error"
      end
      question_html + %Q| <div tabindex="1" class="#{error_class}">#{errs}</div>|
    else
      question_html
    end
  end
end