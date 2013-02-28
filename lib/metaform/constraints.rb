################################################################################
module Constraints
  RequiredErrMessage = "This information is required"
  RequiredMultiErrMessage = "You must check at least one choice from this list"
  DefaultErrorMessages = {
    'regex' => "Answer must match regular expression ?{constraint}?{extra}",
    'max_length' => "Answer must not be more than ?{constraint} characters long",
    'numeric' => 'Answer must be numeric',
    'range' => {:numeric => 'Answer must be numeric', :range=> "Answer must be between ?{low} and ?{hi}?{extra}"},
    'date' => {:in_past=>"Date cannot be in the future",:in_future=>"Date cannot be in the past"},
    'integer' => {:integer=>"Answer must be an integer",:positive=>"Answer must be a positive integer"},
    'unique' => 'Answer must be unique',
    'required' => RequiredErrMessage+'?{extra}',
    'set' => 'Answer must be one of ?{labels}',
    'set.none' => 'Answer cannot include ?{none_label} and other items',
    'enumeration' => 'Answer must be one of ?{labels}',
    '_explanation_approval' => %Q|Error was "?{err}"; the explanation was: "?{exp}" (Fix, or approve ?{chk})|,
    '_explanation' => "; please correct (or explain here: ?{exp})",
    '_required_multi' => RequiredMultiErrMessage
  }
  $metaform_error_messages = DefaultErrorMessages.clone
  
  class << self 
    include Utilities
  end
  def Constraints.fill_error(message,values=nil)
    
    case message
    when Hash
      case values
      when Symbol
        message[values]
      when Hash
        key,vals = values.first
        message[key].gsub(/\?\{(.*?)\}/) {|key| vals[$1]}
      else
        raise "expecting a symbol or a hash as the error message value"
      end
    when String
      case values
      when Hash
        message.gsub(/\?\{(.*?)\}/) {|key| values[$1]}
      else
        message
      end
    else
      raise "error message must be a string (with replacement variables, or a hash of strings)"
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
      
      err_message_template = constraints["err_#{type}"]
      err_message_template ||= $metaform_error_messages[type]
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
            constraint_errors << fill_error(err_message_template,{'constraint'=>constraint,'extra'=>condition_extra_err})
          end
        end
      when "max_length"
        if !value.blank? && value.length > constraint
          constraint_errors << fill_error(err_message_template,{'constraint'=>constraint,'extra'=>condition_extra_err})
        end
      when "numeric"
        if !value.blank? && !is_numeric?(value)
          constraint_errors << fill_error(err_message_template)
        end
      when "integer"
        if !value.blank?
          if !is_integer?(value)
            constraint_errors << fill_error(err_message_template,:integer)
          elsif constraint == 'positive' && value.to_i < 0
            constraint_errors << fill_error(err_message_template,:positive)
          end
        end
      when "range"
        #for the range constraint the value must be a string "X:Y" where X<Y
        if !value.blank?
          (l,h) = constraint.split(":")
          low = l.to_i
          hi = h.to_i
          raise "range constraint #{constraint} is ilegal. Must be of form X:Y where X<Y" if h.nil? || low>hi || hi == nil
          val = value.to_i
          if !is_numeric?(value)
            constraint_errors << fill_error(err_message_template,:numeric)
          elsif val < low || val > hi
            constraint_errors <<  fill_error(err_message_template,{:range => {'low'=>low,'hi'=>hi,'extra'=>condition_extra_err}})
          end
          constraint_errors
        end
      when "date"
        if !value.blank?
          date = parse_date(value)
          if constraint == :in_past
            if date > Date.today
              constraint_errors << fill_error(err_message_template,:in_past)
            end
          elsif constraint == :in_future
            if date <= Date.today
              constraint_errors << fill_error(err_message_template,:in_future)
            end
          end
        end
      when "unique"
        current_record_id = form.get_record.id
        records = Record.locate(:all,{:filters => [":#{constraint} == '#{value}'"],:index => :any,:fields => ['constraint']})
        constraint_errors << fill_error(err_message_template) if records.size > 0 && !records.find{|r| r.id == current_record_id}
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
              err_str << "#{cond.humanize}" unless Form.configuration[:hide_required_extra_errors]
            end
            next unless constraint
            constraint = true
            condition_extra_err = " when " + err_str.join(' and ') unless Form.configuration[:hide_required_extra_errors]
          when TrueClass
          when FalseClass
          else
            raise MetaformException,"value of required constraint must be a true, false or a condition string!"
          end
          if constraint && (value == nil || value == "")
            if (constraints.has_key?('set'))
              msg = constraints["err__required_multi"]
              msg ||= $metaform_error_messages['_required_multi']
            end
            msg ||= fill_error(err_message_template,{'extra'=>condition_extra_err})
            
#            msg ||= Form.configuration[:required_error_message] ? Form.configuration[:required_error_message] : RequiredErrMessage
            constraint_errors << msg
          end
        end
      when "set"
        #for the set constraint the value will be an array of strings or of hashes of the form:
        # [{value => 'description'},{value2 => 'description'}, ...]
        none_val = nil
        none_label = nil
        ok_values = constraint[0].is_a?(String) ? constraint : constraint.collect do |h|
          val = h.is_a?(String) ? h.to_s : h.keys[0]
          if val =~ /(.*)\*$/ || val=~ /^(none)$/
            val = none_val = $1
            none_label = h.is_a?(String) ? h.to_s : h[h.keys[0]]
          end
          val
        end
        ok_values << nil if !ok_values.include?(nil)
        ok_values << '' if !ok_values.include?('')
        cur_values = load_set_value(value)
        if not cur_values.all? {|v| ok_values.include?(v)}
          labels = constraint[0].is_a?(String) ? ok_values.join(', ') : constraint.collect{|h| h.is_a?(String) ? h.to_s : h.values[0]}
          labels = labels.join(', ')
          constraint_errors << fill_error(err_message_template,{'labels'=>labels})
        end
        if none_val && cur_values.include?(none_val) && cur_values.size > 1
          constraint_errors << fill_error($metaform_error_messages['set.none'],{'none_label'=>none_label})
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
          constraint_errors << fill_error(err_message_template,{'labels'=>labels})
        end
      end
    end
    constraint_errors.flatten
  end
  
  def Constraints.load_set_value(value)
    if value.blank?
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
  end
  
end
