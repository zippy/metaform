################################################################################
module Constraints
  def Constraints.verify (constraints, value, form)
    constraint_errors = []
    return constraint_errors if !constraints
    constraints.each do |type, constraint|
      next if type =~ /^err_/
      err_override = constraints["err_#{type}"]
      case type
      when "regex"
        #for the required constraint the value will be the regex to match the value against
        r = Regexp.new(constraint)
        if r !~ value
          constraint_errors << (err_override || "value does not match regular expression #{constraint}")
        end
      when "range"
        #for the range constraint the value must be a string "X-Y" where X<Y
        (low,hi) = constraint.split("-")
        if value.to_i < low.to_i || value.to_i > hi.to_i
          constraint_errors << (err_override || "value out of range, must be between #{low} and #{hi}")
        end
      when "required"
        #for the required constraint the value will be true or false or a proc to run
        # the proc will get the value as a parameter and must return an error string if the
        # field was required or nil if it isn't
        case
        when constraint.class == Proc
          e = constraint.call(value)
          constraint_errors << e if e
        when constraint.class == String
          #for the required_if constraint the value must be a string of the form "field_name=value" or "field_name=~value" for regex matching
          constraint =~ /(.*)(=~*)(.*?)/
          (field_name,op,field_value) = [$1,$2,$3]
          case op
          when '='
            if form.field_value(field_name) == field_value && (value == nil || value == '')
              constraint_errors << (err_override || "this field is required when #{field_name} is #{field_value}")
            end
          when '=~'
            r = Regexp.new(field_value)
            if r !~ form.field_value(field_name)
              constraint_errors << (err_override || "this field is required when #{field_name} matches regexp #{field_value}")
            end
          end
        when constraint && (value == nil || value == "")
          constraint_errors << (err_override || "this field is required")
        end
      when "set"
        #for the set constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]
        ok_values = constraint[0].is_a?(String) ? constraint : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.keys[0]}
        cur_values = !value ? [nil] : value.split(',')
        if not cur_values.all? {|v| ok_values.include?(v)}
          constraint_errors << (err_override || ("value out of range, must be in " << ok_values.join(', ')))
        end
      when "enumeration"
        #for the enumeration constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]

        #TODO-LISA this doesn't yet handle when null is allowed.  Which fact also has to be added
        # to the definition of "f" in definition.rb

        ok_values = constraint[0].is_a?(String) ? constraint : constraint.collect{|h| h.keys[0]}
        if !ok_values.include?(value)
          constraint_errors << (err_override || ("value out of range, must be in " << ok_values.join(', ')))
        end
      end
    end
    constraint_errors
  end
end