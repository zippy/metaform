module Utilities
  ###########################################################
  # used for parameters that can optionally be an array.
  # converts non-array params to a single element array
  HTML_ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }

  def html_escape(s)
    s.to_s.gsub(/[&\"><]/) { |special| HTML_ESCAPE[special] }
  end

  def arrayify(param)
    return [] if param == nil
    param = [param]  if param.class != Array
    param
  end

  def array_for_sql(a)
    a.collect{|f| "'#{f}'"}.join(',')
  end
  
  def sql_workflow_condition(workflows,add_and=false)
    result = ''
    if workflows
      result << " and " if add_and
      result << %Q|workflow_state in (#{array_for_sql(arrayify(workflows))})|
    end
    result
  end
  
  def sql_field_conditions(conditions,add_and=false)
    result = ''
    if conditions
      result << " and " if add_and
      conditions = arrayify(conditions)
      result << conditions.collect do |c|
        c =~ /:([a-zA-Z0-9_-]+)/
        field_name = $1
        c = c.gsub(/:#{field_name}/,'answer')
        %Q|if(field_id='#{field_name}',if(#{c},true,false),true)|
      end.join(' and ')
    end
    result
  end
end