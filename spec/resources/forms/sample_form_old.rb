=begin
class OldSampleForm < FormOld
  
  labeling(:postfix => ':')

  property_appearances do |q_html,properties|
    q_result = q_html
    if properties[:invalid]
      q_result << %Q|<span class="errors">#{properties[:invalid]}</span>|
    end
    if properties[:shady]
      q_result = %Q|<div class="shady">#{q_result}</div>|
    end
    q_result
  end
  
  def_fields(nil,{:shady => Proc.new {|form| (form.field_value('name') =~ /Capone/) }}) do
    f 'name', 'Name', 'string', {"required"=>true}
    f 'due_date', 'Due Date', 'date'
    f 'education', 'Post-secondary formal education (years)', 'integer', {"range"=>"0-14"}
    f 'occupation', 'Occupation', 'string'
    f 'field_with_default', 'FWD', 'string', nil, :default=> 'fish'
    f 'indexed_field_no_default', 'AF', 'string', nil, :indexed_default_from_null_index => true
    f 'indexed_field_with_default', 'AFWD', 'string', nil, :default=> 'cow',:indexed_default_from_null_index => true
    fo = f('fruit_other', 'Other fruit', 'string', {"required"=>"fruit=other"})
    fwf 'fruit', '', 'string', {"enumeration"=>[{"apple_mac"=>"Macintosh Apple"}, {"apple_mutsu"=>"Mutsu"}, {"pear"=>"Pear"}, {"banana"=>"Banana"}, {"other"=>"Other...*"}, {"x"=>"XOther...*"}], "required"=>true}, :followups => {'/other|x/' => fo}
    f 'breastfeeding', 'BF', 'string', nil, :indexed_default_from_null_index => true
    f 'reverse_name_and_job', 'reversed name and occupation','string',nil, :calculated => {
      :proc => Proc.new { |form,index| (form.field_value('name',index).to_s+form.field_value('occupation',index).to_s).reverse}
    }
  end
        
  def_workflows do 
    workflow 'standard' do
      def_states_normal :logged,:completed
      def_states_verification :verifying
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
    q 'breastfeeding', 'TextField'
    function_button "New Entry" do
      javascript_submit_workflow_action('create')
    end  
  end
  
  presentation 'simple' do
    q 'name'
  end
  
  presentation 'indexed_sub_presentation' do
    p 'simple',:indexed => {:appearance => :list, :add_button_text => 'Add a name', :delete_button_text => 'Delete this name'}
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
=end