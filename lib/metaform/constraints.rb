################################################################################
module Constraints
  RequiredErrMessage = "This information is required"
  DefaultErrorMessages = {
    'regex' => "Answer must match regular expression ?{constraint}?{extra}",
    'max_length' => "Answer must not be more than ?{constraint} characters long",
    'range' => "Answer must be between ?{low} and ?{hi}?{extra}",
    'date' => {:in_past=>"Date cannot be in the future",:in_future=>"Date cannot be in the past"},
    'unique' => 'Answer must be unique',
    'required' => RequiredErrMessage+'?{extra}',
    'set' => 'Answer must be one of ?{labels}',
    'enumeration' => 'Answer must be one of ?{labels}',
    'explanation_approval' => %Q|Error was "?{err}"; the explanation was: "?{exp}" (Fix, or approve ?{chk})|,
    'explanation' => "; please correct (or explain here: ?{exp})"
  }
  $metaform_error_messages = DefaultErrorMessages.clone
  
  RequiredMultiErrMessage = "You must check at least one choice from this list"
  class << self 
    include Utilities
  end
  def Constraints.fill_error(type,values=nil)
    errors=$metaform_error_messages
    message = errors[type]
    case values
    when nil
      message
    when Hash
      message.gsub(/\?\{(.*?)\}/) {|key| values[$1]}
    else
      message[values]
    end
  end
  def Constraints.verify (constraints, value, form)
    constraint_errors = []
    return constraint_errors if !constraints
    constraints.each do |type, constraint|
      next if type =~ /^err_/
      
#      # if this constraint is conditional, then evaluate the constraint condition
#      # before attempting to apply the constraint!
#      if constraint.instance_of?(ConstraintCondition)
#        next if !constraint.condition.evaluate
#        constraint = constraint.constraint_value
#        condition_extra_err = " when #{constraint.condition.humanize}"
#      else
#        condition_extra_err = ""
#      end
      condition_extra_err = ''
      
      err_override = constraints["err_#{type}"]
      case type
      when "proc"
        raise MetaformException,"value of proc constraint must be a Proc!" if !constraint.instance_of?(Proc)
        e = constraint.call(value,form)
        constraint_errors << e if e
      when "regex"
        #for the required constraint the value will be the regex to match the value against
        if !value.blank?
          r = Regexp.new(constraint)
          if r !~ value
            constraint_errors << (err_override || fill_error('regex',{'constraint'=>constraint,'extra'=>condition_extra_err}))
          end
        end
      when "max_length"
        if !value.blank? && value.length > constraint
          constraint_errors << (err_override || fill_error('max_length',{'constraint'=>constraint,'extra'=>condition_extra_err}))
        end
      when "range"
        #for the range constraint the value must be a string "X:Y" where X<Y
        if !value.blank?
          (l,h) = constraint.split(":")
          low = l.to_i
          hi = h.to_i
          raise "range constraint #{constraint} is ilegal. Must be of form X:Y where X<Y" if low>hi || hi == nil
          if value.to_i < low || value.to_i > hi
            constraint_errors << (err_override || fill_error('range',{'low'=>low,'hi'=>hi,'extra'=>condition_extra_err}))
          end
        end
      when "date"
        if !value.blank?
          date = parse_date(value)
          if constraint == :in_past
            if date > Time.now
              constraint_errors << (err_override || fill_error('date',:in_past))
            end
          elsif constraint == :in_future
            if date < Time.now
              constraint_errors << (err_override || fill_error('date',:in_future))
            end
          end
        end
      when "unique"
        current_record_id = form.get_record.id
        records = Record.locate(:all,{:filters => [":#{constraint} == '#{value}'"],:index => :any,:fields => ['constraint']})
        constraint_errors << (err_override || fill_error('unique')) if records.size > 0 && !records.find{|r| r.id == current_record_id}
      when "required"
        # if the constraint is a string instead of (true | false) then build a condition on the fly
        #This is ugly as sin, but is the only way we could think of to get a global override for required.
        unless Form.get_store('override_required') && Form.get_store('override_required').call(form)
          constraint = [constraint] if constraint.is_a?(String)
          case constraint
          when Array
            err_str = []
            constraint.each do |cstrnt|
              cond = form.c cstrnt
              if !cond.evaluate
                constraint = false
                break
              end
              err_str << "#{cond.humanize}" unless Form.config[:hide_required_extra_errors]
            end
            next unless constraint
            constraint = true
            condition_extra_err = " when " + err_str.join(' and ') unless Form.config[:hide_required_extra_errors]
          when TrueClass
          when FalseClass
          else
            raise MetaformException,"value of required constraint must be a true, false or a condition string!"
          end
          if constraint && (value == nil || value == "")
            msg = err_override if err_override
            msg = RequiredMultiErrMessage if constraints.has_key?('set')
            msg ||= fill_error('required',{'extra'=>condition_extra_err})
            
#            msg ||= Form.config[:required_error_message] ? Form.config[:required_error_message] : RequiredErrMessage
            constraint_errors << msg
          end
        end
      when "set"
        #for the set constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]
        ok_values = constraint[0].is_a?(String) ? constraint : constraint.collect{|h| (h.is_a?(String) ? h.to_s : h.keys[0]).chomp('*')}
        ok_values << nil if !ok_values.include?(nil)
        ok_values << '' if !ok_values.include?('')
        cur_values = if value.blank?
          [nil]
        elsif value.is_a?(String)
          if value =~ /^---/
            YAML.load(value).keys
          else 
            value.split(',')
          end
        elsif value.is_a?(Hash)
          value.keys
        end
        if not cur_values.all? {|v| ok_values.include?(v)}
          labels = constraint[0].is_a?(String) ? ok_values.join(', ') : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.values[0]}
          labels = labels.join(', ')
          constraint_errors << (err_override || fill_error('set',{'labels'=>labels}))
        end
      when "enumeration"
        #for the enumeration constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]

        ok_values = constraint[0].is_a?(String) ? constraint : (constraint[0].is_a?(Array) ?  constraint.collect{|label,val| val} : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.keys[0]})
        ok_values << nil if !ok_values.include?(nil)
        ok_values << '' if !ok_values.include?('')
        if !ok_values.include?(value)
          labels = constraint[0].is_a?(String) ? constraint : (constraint[0].is_a?(Array) ?  constraint.collect{|label,val| label} : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.values[0]})
          labels = labels.join(', ')
          constraint_errors << (err_override || fill_error('enumeration',{'labels'=>labels}))
        end
      end
    end
    constraint_errors.flatten
  end
end