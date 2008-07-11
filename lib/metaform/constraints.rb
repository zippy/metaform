################################################################################
module Constraints
  def Constraints.verify (constraints, value, form)
    constraint_errors = []
    return constraint_errors if !constraints
    constraints.each do |type, constraint|
      next if type =~ /^err_/
      
      # if this constraint is conditional, then evaluate the constraint condition
      # before attempting to apply the constraint!
      if constraint.instance_of?(ConstraintCondition)
        next if !constraint.condition.evaluate
        constraint = constraint.constraint_value
        condition_extra_err = " when #{constraint.condition.humanize}"
      else
        condition_extra_err = ""
      end
      
      err_override = constraints["err_#{type}"]
      case type
      when "proc"
        raise MetaformException,"value of proc constraint must be a Proc!" if !constraint.instance_of?(Proc)
        e = constraint.call(value,form)
        constraint_errors << e if e
      when "regex"
        #for the required constraint the value will be the regex to match the value against
        r = Regexp.new(constraint)
        if r !~ value
          constraint_errors << (err_override || "value must match regular expression #{constraint}#{condition_extra_err}")
        end
      when "range"
        #for the range constraint the value must be a string "X-Y" where X<Y
        (low,hi) = constraint.split("-")
        if value.to_i < low.to_i || value.to_i > hi.to_i
          constraint_errors << (err_override || "value out of range, must be between #{low} and #{hi}#{condition_extra_err}")
        end
      when "required"
        # if the constraint is a string instead of (true | false) then build a condition on the fly
        case constraint
        when String
          cond = form.c constraint
          next if !cond.evaluate
          condition_extra_err = " when #{cond.humanize}"
          constraint = true
        when TrueClass
        when FalseClass
        else
          raise MetaformException,"value of required constraint must be a true, false or a condition string!"
        end
        if constraint && (value == nil || value == "")
          constraint_errors << (err_override || "this field is required#{condition_extra_err}")
        end
      when "set"
        #for the set constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]
        ok_values = constraint[0].is_a?(String) ? constraint : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.keys[0]}
        ok_values << nil if !ok_values.include?(nil)
        ok_values << '' if !ok_values.include?('')
        cur_values = !value ? [nil] : value.split(',')
        if not cur_values.all? {|v| ok_values.include?(v)}
          constraint_errors << (err_override || ("value out of range, must be in " << ok_values.join(', ')))
        end
      when "enumeration"
        #for the enumeration constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]

        ok_values = constraint[0].is_a?(String) ? constraint : (constraint[0].is_a?(Array) ?  constraint.collect{|h| h[0]} : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.keys[0]})
        ok_values << nil if !ok_values.include?(nil)
        ok_values << '' if !ok_values.include?('')
        if !ok_values.include?(value)
          constraint_errors << (err_override || ("value out of range, must be in " << ok_values.join(', ')))
        end
      end
    end
    constraint_errors
  end
end