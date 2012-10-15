def flagq(field_name, opts = {})
  options = {
      :widget => 'RadioButtons',
      :default_state_hidden => true,
      :css_class => 'flag',
      :show_dependents_on => 'Y'
  }.update(opts)
  if @force_show_followups
    options[:default_state_hidden] = true
    options[:show_dependents_on] = :allways
  end

  show_dependents_on = options[:show_dependents_on]
  default_state_hidden = options[:default_state_hidden]
  condition = case show_dependents_on
    when :answered
      "#{field_name} answered"
    when :allways
      "#{field_name}!=XXX"
    else
      "#{field_name}=#{show_dependents_on}"
  end
  shopts = default_state_hidden ? {:condition => condition, :show => true} : {}
  options.delete(:default_state_hidden)
  options.delete(:show_dependents_on)

  if options[:show_hide_css_class]
    shopts[:css_class] = options[:show_hide_css_class]
    options.delete(:show_hide_css_class)
  end
  qp field_name, :question_options => options, :show_hide_options => shopts
end

class Shady < Property
  def self.evaluate(form,field,value,index)
    form.field_value('name') =~ /Capone/
  end
  def self.render(question_html,property_value,question,form,field)
    if property_value
      %Q|<div class="shady">#{question_html}</div>|
    else
      question_html
    end
  end
end

class Log < Listings
    # the conditions hash works like this.  The value portion is a mysql fragment about the field. (or array of fragments
    # to be anded together)
    list 'samples', 
      :forms => ['SampleForm']
#      :workflow_state_filter => ['logged'],
#      :conditions => {'fruit' => '!= "pear"'},
end

class Stats < Reports
  def_report('fruits', 
    :forms => ['SampleForm'],
    :fields => ['name'],  #gotta include this so that the null_fruits querry will count over all records.
    :count_queries => {
      :bananas => 	"count.increment if :fruit == 'banana'",
      :kiwis => 	"count.increment if :fruit == 'kiwi'",
      :apples => "count.increment if :fruit =~ /apple*/",
      :null_fruits => "count.increment if :fruit.blank?",
      :painters => "count.increment if :occupation.include?('painter')",
      :slackers => "count.increment if :occupation.include?('unemployed')",
      :painters_or_slackers => ":occupation.any?('painter','unemployed')",
      :other_than_painter_or_slacker => ":occupation.other?('painter','unemployed')"

      }) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }

  def_report('report_with_workflow',
    :forms => ['SampleForm'],
    :workflow_state_filter => "standard%",
    :count_queries => {
      :bananas => 	"count.increment if :fruit == 'banana'",
      :apples => "count.increment if :fruit =~ /apple*/",
      :bobs => "count.increment if :name =~ /^Bob/",
      :joes => "count.increment if :name =~ /^Joe/",
    }) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }

  def_report('report_with_2_workflows',
    :forms => ['SampleForm'],
    :workflow_state_filter => ['standard','unusual'],
    :count_queries => {
      :bananas => 	"count.increment if :fruit == 'banana'",
      :apples => "count.increment if :fruit =~ /apple*/",
      :bobs => "count.increment if :name =~ /^Bob/",
      :joes => "count.increment if :name =~ /^Joe/",
    }) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }

  def_report('report_with_', 
    :forms => ['SampleForm'],
    :workflow_state_filter => ['standard','unusual'],
    :count_queries => {
      :bananas => 	"count.increment if :fruit == 'banana'",
      :apples => "count.increment if :fruit =~ /apple*/",
      :bobs => "count.increment if :name =~ /^Bob/",
      :joes => "count.increment if :name =~ /^Joe/",
    }) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }
    
  def_report('pregnancies',
    :forms => ['SampleForm'],
    :count_queries => {
      :happy_no_val_pregs => %Q@:prev_preg_outcome.zip(:prev_preg_value) {|o,v| count.increment if o == 'happy' && v.blank? }@,
    }) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }

end
