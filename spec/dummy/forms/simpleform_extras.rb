class ::FieldNameHasG < Property
  def self.evaluate(form,field,value)
    field.name =~ /g/ ? true : false
  end
  def self.render(question_html,property_value,question,form,field,read_only)
    if property_value
      if read_only
        question_html + 'g question read only!'
      else
        question_html + 'g question!'
      end
    else
      question_html
    end
  end
end