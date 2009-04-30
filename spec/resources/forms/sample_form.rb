class Shady < Property
  def self.evaluate(form,field,value,index)
    form.field_value('name') =~ /Capone/
  end
  def self.render(question_html,property_value,question,form)
    if property_value
      %Q|<div class="shady">#{question_html}</div>|
    else
      question_html
    end
  end
end

class SampleForm < Form
def setup
  
  labeling(:postfix => ':')
  
  def_fields :properties => [Shady] do
    f 'name', :label => 'Name', :type => 'string', :constraints => {"required"=>true}
    f 'due_date', :label => 'Due Date', :type => 'date'
    f 'some_time', :label => 'Some Date Time', :type => 'datetime'
    f 'education', :label => 'Post-secondary formal education (years)', :type => 'integer', :constraints => {"range"=>"0:14"}
    def_dependent_fields('education>0') do
      f 'degree', :type=>'string'
    end
    f 'occupation', :label => 'Occupation', :type => 'string'
    f 'hobby', :label => 'Hobby', :constraints => {"required"=>true}
    f 'field_with_default', :label => 'FWD', :type => 'string', :default=> 'fish'
    f 'indexed_field_no_default', :label => 'AF', :type => 'string', :indexed_default_from_null_index => true
    c 'condition_for_def_dependent_fields', :fields_to_use =>  'indexed_field_no_default',
      :javascript => ':indexed_field_no_default.include("pig")' do
        field_value_at('indexed_field_no_default',:any).include?("pig")
      end
    def_dependent_fields('condition_for_def_dependent_fields') do
      f 'yale_class', :label => '', :type => 'string', :constraints => {"enumeration"=>[{"math"=>"Cool Math Class"}, {"comp_sci"=>"Lots of Computer Theory"}, {"music"=>"Pretty Music"}]}
    end
    f 'indexed_field_with_default', :label => 'AFWD', :type => 'string', :default=> 'cow',:indexed_default_from_null_index => true
    fo = f('fruit_other', :label => 'Other fruit', :type => 'string', :constraints => {"required"=>"fruit=other"})
    f 'fruit', :label => '', :type => 'string', :constraints => {"enumeration"=>[{"apple_mac"=>"Macintosh Apple"}, {"apple_mutsu"=>"Mutsu"}, {"pear"=>"Pear"}, {"banana"=>"Banana"}, {"other"=>"Other...*"}, {"x"=>"XOther...*"}], "required"=>true}, :followups => {'/other|x/' => fo}
    f 'breastfeeding', :label => 'BF', :type => 'string', :indexed_default_from_null_index => true
    f 'reverse_name_and_job', :label => 'reversed name and occupation', :type => 'string', :calculated => {
      :based_on_fields => ['name','occupation'],
      :proc => Proc.new { |form,index| (form.field_value_at('name',index).to_s+form.field_value_at('occupation',index).to_s).reverse}
    }    
    f 'total_bobs', :label => 'total number of Bobs', :type => 'integer', :calculated => {
      :based_on_fields => ['name'],
      :summary_calculate => true,
      :proc => Proc.new { |form,index| answers = form.get_record.answers_hash('name');answers['name'].count("answer =~ /Bob/")}
    }    
    f 'people_num', :label => '', :type => 'string'
  end

#  def_workflows do 
    workflow 'standard',[{'logged' => 'Form Logged'},{'completed' => 'Form Completed'},{'verifying' => {:label => 'Form in validation',:validate => true}}] do
    	action 'create',[nil] do
        validatation :update,{:test => 1}
        state 'logged'
        redirect_url '/'
#        redirect_to_listing('log')
    	end
    	action 'continue','logged' do
    	  state 'logged'
        redirect_url '/'
#        redirect_to_listing('log')
    	end
    	action 'finish','logged' do
    	  state 'completed'
        redirect_url '/'
    	end
  	end
#  end

  def_conditions do
    c 'sue_is_a_plumber', :javascript => ":name == Sue && :occupation == 'plumber'" do
      field_value("name") == 'Sue' && field_value("occupation") == 'plumber'
    end
    c 'people_num_mult_changer', :javascript => ":people_num > 0" do
        field_value("people_num").to_i > 0
    end
  end
  
  def_zapping_proc do
    {:preflight_state => lambda {|form| 
                          result = {}
                          result['sue_is_a_plumber'] = ['breastfeeding'] if kaste(form.field_value('sue_is_a_plumber'))
                          result['people_num'] = [:mult, form.field_value('people_num'),['education','fruit']]
                          result},
                      :fields_hit => lambda {|form,preflight_state| 
                           result = {}
                           preflight_state.each do |k,v| 
                             if v[0] == :mult
                               if form.field_value(k).to_i < v[1].to_i
                                 (form.field_value(k).to_i..v[1].to_i).each{|idx| result[idx] ? result[idx] << v[2] : result[idx] = [v[2]]}
                               end
                             else
                               if !kaste(form.field_value(k))
                                 result[:all] ? result[:all] << v : result[:all] = [v]                                      
                               end
                             end
                           end
                           result.each_pair{|k,v| result[k] = v.flatten}
                           }}
  end

  
  
  
  def_fields do
    f 'sue_is_a_plumber', :type => 'boolean', :calculated =>  {:from_condition => 'sue_is_a_plumber'}
    f 'people_num_mult_changer', :type => 'integer', :calculated =>  {:from_condition => 'people_num_mult_changer'}
  end
	
	presentation 'new_entry',:legal_states => [nil,'standard','unusual','standard_1','standard_2'],:create_with_workflow => 'standard' do
    q 'name', :widget => 'TextField'
    q 'due_date', :widget => 'Date'
    q 'education', :widget => 'TextField'
    q 'occupation', :widget => 'TextField'
    q 'fruit', :widget => 'RadioButtons', :followups => [{'fruit_other' => {:widget=>'TextField'}}]
    q 'breastfeeding', :widget => 'TextField'
    function_button "New Entry" do
      javascript_submit :workflow_action => 'create', :workflow_action_force=> true
    end
  end

  presentation 'condition_test',:legal_states =>  [nil,'standard','unusual','standard_1','standard_2'],:create_with_workflow  => 'standard' do
    q 'indexed_field_no_default'
    q 'yale_class'
   end
  
  presentation 'simple' do
    q 'name'
  end
  
  presentation 'education_info' do
    q 'education'
    q 'degree'
  end
  
  presentation 'indexed_sub_presentation' do
    p 'simple',:indexed => {:appearance => :list, :add_button_text => 'Add a name', :delete_button_text => 'Delete this name', :reference_field=>'name'}
  end
  
	presentation 'update_entry',:legal_states =>'logged' do
    t "name: #{field_value('name')}"
    q 'due_date', :widget => 'Date'
    q 'education', :widget => 'TextField'
    q 'occupation', :widget => 'TextField'
    q 'fruit', :widget => 'RadioButtons', :followups => [{'fruit_other' => {:widget=>'TextField'}}]
    function_button "Update" do
      javascript_submit :workflow_action => 'continue'
    end  
    function_button "Finish" do
      javascript_submit :workflow_action => 'finish'
    end  
  end
end
end

# class Log < Listings
#     # the conditions hash works like this.  The value portion is a mysql fragment about the field. (or array of fragments
#     # to be anded together)
#     list 'samples', 
#       :forms => ['SampleForm']
# #      :workflow_state_filter => ['logged'],
# #      :conditions => {'fruit' => '!= "pear"'},
# end

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

end
