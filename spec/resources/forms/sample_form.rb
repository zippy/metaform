class SampleForm < Form

  def_fields do
    f 'name', 'Name', 'string'
    f 'due_date', 'Due Date', 'date'
    f 'education', 'Post-secondary formal education (years)', 'integer', {"range"=>"0-14"}
    f 'occupation', 'Occupation', 'string'
    f 'field_with_default', 'FWD', 'string', nil, :default=> 'fish'
    f 'arrayable_field_no_default', 'AF', 'string', nil, :arrayable_default_from_null_index => true
    f 'arrayable_field_with_default', 'AFWD', 'string', nil, :default=> 'cow',:arrayable_default_from_null_index => true
    fo = f('fruit_other', 'Other fruit', 'string', {"required"=>"fruit=other"})
    fwf 'fruit', '', 'string', {"enumeration"=>[{"apple_mac"=>"Macintosh Apple"}, {"apple_mutsu"=>"Mutsu"}, {"pear"=>"Pear"}, {"banana"=>"Banana"}, {"other"=>"Other...*"}, {"x"=>"XOther...*"}], "required"=>true}, :followups => {'/other|x/' => fo}
  end
        
  def_workflows do 
    workflow 'standard' do
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
  end
	
	presentation 'new_entry',:legal_states => [nil],:create_with_workflow => 'standard' do
    q 'name', 'TextField'
    q 'due_date', 'Date'
    q 'education', 'TextField'
    q 'occupation', 'TextField'
    q 'fruit', 'RadioButtons',nil,'fruit_other'
    function_button "New Entry" do
      javascript_submit_workflow_action('create')
    end  
  end
  
	presentation 'update_entry',:legal_states =>'logged' do
    t "name: #{field_value('name')}"
    q 'due_date', 'Date'
    q 'education', 'TextField'
    q 'occupation', 'TextField'
    q 'fruit', 'RadioButtons',nil,'fruit_other'
    function_button "Update" do
      javascript_submit_workflow_action('continue')
    end  
    function_button "Finish" do
      javascript_submit_workflow_action('finish')
    end  
  end

end

class Log < Listings
    # the conditions hash works like this.  The value portion is a mysql fragment about the field. (or array of fragments
    # to be anded together)
    listing 'samples', 
      :forms => ['SampleForm'],
      :workflow_state_filter => ['logged','completed'],
#      :conditions => {'fruit' => '!= "pear"'},
      :fields => ['name','fruit']
end

class Stats < Reports
  def_report('fruits', 
    :description => 'Fruits',    
    :forms => ['SampleForm'],
    :fields => ['education'],
    :workflow_state_filter => ['logged'],
#    :sql_conditions => {'Dem_MomAge' => '> 0'},
    :percent_queries => {
   		:bananas => 	":fruit == 'banana'",
   		:apples => ":fruit == 'apple_mutsu' || :fruit == 'apple_mac'"
  	}) { |q,forms|
      r = Struct.new(*(q.keys+[:education_av]))[*q.values]

    education_av = 0
    forms.values.each {|f| education_av = education_av + f['education'].to_i if f['education']}
  	education_av = education_av/forms.values.size
  	r.education_av = sprintf("%.0f",education_av) if education_av > 0;

    r
  }
end