class Shady < Property
  def self.evaluate(form,field,value)
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
    f 'education', :label => 'Post-secondary formal education (years)', :type => 'integer', :constraints => {"range"=>"0-14"}
    f 'occupation', :label => 'Occupation', :type => 'string'
    f 'field_with_default', :label => 'FWD', :type => 'string', :default=> 'fish'
    f 'indexed_field_no_default', :label => 'AF', :type => 'string', :indexed_default_from_null_index => true
    f 'indexed_field_with_default', :label => 'AFWD', :type => 'string', :default=> 'cow',:indexed_default_from_null_index => true
    fo = f('fruit_other', :label => 'Other fruit', :type => 'string', :constraints => {"required"=>"fruit=other"})
    f 'fruit', :label => '', :type => 'string', :constraints => {"enumeration"=>[{"apple_mac"=>"Macintosh Apple"}, {"apple_mutsu"=>"Mutsu"}, {"pear"=>"Pear"}, {"banana"=>"Banana"}, {"other"=>"Other...*"}, {"x"=>"XOther...*"}], "required"=>true}, :followups => {'/other|x/' => fo}
    f 'breastfeeding', :label => 'BF', :type => 'string', :indexed_default_from_null_index => true
    f 'reverse_name_and_job', :label => 'reversed name and occupation', :type => 'string', :calculated => {
      :proc => Proc.new { |form,index| (form.field_value('name',index).to_s+form.field_value('occupation',index).to_s).reverse}
    }
  end
        
#  def_workflows do 
    workflow 'standard',{'logged' => 'Form Logged','completed'=> 'Form Completed','verifying'=>{:label => 'Form in verification',:validate => true}} do
    	action 'create',[nil] do
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
	
	presentation 'new_entry',:legal_states => [nil],:create_with_workflow => 'standard' do
    q 'name', :widget => 'TextField'
    q 'due_date', :widget => 'Date'
    q 'education', :widget => 'TextField'
    q 'occupation', :widget => 'TextField'
    q 'fruit', :widget => 'RadioButtons', :followups => [{'fruit_other' => {:widget=>'TextField'}}]
    q 'breastfeeding', :widget => 'TextField'
    function_button "New Entry" do
      javascript_submit :workflow_action => 'create'
    end  
  end
  
  presentation 'simple' do
    q 'name'
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

class Log < Listings
    # the conditions hash works like this.  The value portion is a mysql fragment about the field. (or array of fragments
    # to be anded together)
    listing 'samples', 
      :forms => ['SampleForm'],
#      :workflow_state_filter => ['logged'],
#      :conditions => {'fruit' => '!= "pear"'},
      :fields => ['name','fruit']
end

class Stats < Reports
  def_report('fruits', 
    :description => 'Fruits',    
    :forms => ['SampleForm'],
#    :fields => ['education'],
#    :workflow_state_filter => ['logged'],
#    :sql_conditions => {'Dem_MomAge' => '> 0'},
    :count_queries => {
   		:bananas => 	"count.increment if :fruit == 'banana'",
   		:apples => "count.increment if :fruit =~ /apple*/",
   		:painters => "count.increment if :occupation.include?('painter')",
   		:slackers => "count.increment if :occupation.include?('unemployed')"
  	}) { |q,forms|
      Struct.new(*(q.keys))[*q.values]
    }
end
