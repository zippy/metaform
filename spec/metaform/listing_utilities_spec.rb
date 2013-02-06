require File.dirname(__FILE__) + '/../spec_helper'

include ListingUtilities

describe ListingUtilities do
  
  it 'should be possible to sepecify a paramters that when returned by the client that will be used to search for fields' do
    def_search_rule('n') {|search_for| ["name = ?", search_for]}
    @search_rules.keys.should==['n']
  end
  
  it 'should produce search parameters for Record.locate' do
    def_search_rule('n') {|search_for| ":name == '#{search_for}'"}
    def_search_rule('e') {|search_for| ":email =~ /#{search_for}/"}
#    def_search_rule('w',:workflow) {|search_for| [search_for,true]}
    @search_params = {'on_name'=>'n','for_name'=>'bob','on_e'=>'e','for_e'=>'claimed'}
    generate_search_options(:locate).include?(":name == 'bob'").should == true
    generate_search_options(:locate).include?(":email =~ /claimed/").should == true
#{:filters=>[":name == 'bob"], :workflow_state_filter=>["claimed"],:workflow_state_filter_negate=>true}
  end
  
  it 'should produce search paramters for Record.locate by using defaults generated by def_search_rules' do
    def_search_rules(:locate, 'n' => :name, 'e' => :email)
    @search_params = {'on_name' => 'n_is', 'for_name' => 'bob', 'on_e' => 'e_b', 'for_e' => 'claimed'}
    generate_search_options(:locate).include?(":name == 'bob'").should == true
    generate_search_options(:locate).include?(":email =~ /^claimed/i").should == true
  end

  it 'should produce search parameters for a rails sql Find' do
    def_search_rule('n') {|search_for| ["name = ?", search_for]}
    def_search_rule('e') {|search_for| ["email like ?", '%'+search_for+'%']}
    @search_params = {'on_name'=>'n','for_name'=>'bob','on_email'=>'e','for_email'=>'herb'}
    o = generate_search_options(:sql)
    o.include?('(email like ?) and (name = ?)').should == true
    o.include?("bob").should == true
    o.include?('%herb%').should == true
  end

  it 'should produce search parameters for a rails sql Find and not fail for items that do not have params' do
    def_search_rule('n') {|search_for| ["name = ?", search_for]}
    def_search_rule('e') {|search_for| ["email = 'joe@bob.com'"]}
    @search_params = {'on_name'=>'n','for_name'=>'bob','on_email'=>'e','for_email'=>'herb'}
    generate_search_options(:sql).should == ["(email = 'joe@bob.com') and (name = ?)","bob"]
  end

  it 'should produce search parameters for Record.search' do
    def_search_rule('n') {|search_for| ":name = '#{search_for}'"}
    def_search_rule('e') {|search_for| ":email like '%#{search_for}%'"}
    def_search_rule('w',:meta_condition=>true) {|search_for| "workflow_state = '#{search_for}'"}
    @search_params = {'on_name'=>'n','for_name'=>'bob','on_email'=>'e','for_email'=>'herb','on_w'=>'w','for_w'=>'claimed'}
    generate_search_options(:search).should == {:meta_condition=>"(workflow_state = 'claimed')", :conditions=>"(:email like '%herb%') and (:name = 'bob')"}
  end

  it 'should produce search parameters for Record.search with | search_for' do
    def_search_rule('n') {|search_for| ":name = '#{search_for}'"}
    @search_params = {'on_name'=>'n','for_name'=>'bob|herb'}
    generate_search_options(:search).should == {:conditions => "(:name = 'bob' or :name = 'herb')"}
  end

  it 'should produce search parameters for Record.search with multiple meta_conditions' do
    def_search_rule('i',:meta_condition=>true) {|search_for| "id > #{search_for.to_i}"}
    def_search_rule('w',:meta_condition=>true) {|search_for| "workflow_state = '#{search_for}'"}
    @search_params = {'on_w'=>'w','for_w'=>'claimed','on_i'=>'i','for_i'=>'2'}
    results = generate_search_options(:search)[:meta_condition]
    results.should include "(id > 2)"
    results.should include "(workflow_state = 'claimed')"
  end

  it 'should produce search parameters for Record.search with | search_for for meta_fields' do
    def_search_rule('w',:meta_condition=>true) {|search_for| "workflow_state = '#{search_for}'"}
    @search_params = {'on_w'=>'w','for_w'=>'claimed|done'}
    generate_search_options(:search).should == {:meta_condition => "(workflow_state = 'claimed' or workflow_state = 'done')"}
  end
  
  it 'should produce search parameters for Record.search with negation_parameter' do
    def_search_rule('w',:meta_condition=>true,:negate =>true) {|search_for| "workflow_state = '#{search_for}'"}
    @search_params = {'on_w'=>'w','for_w'=>'claimed|done'}
    generate_search_options(:search).should == {:meta_condition => "not (workflow_state = 'claimed' or workflow_state = 'done')"}
  end
  
  it 'should generate default search rules' do
    def_search_rules(:search,'birth_code' => 'H_Ccode')
    @search_params = {'on_w'=>'birth_code_is','for_w'=>'ABCD'}
    generate_search_options(:search).should == {:conditions=>"(:H_Ccode = 'ABCD')"}
    @search_params = {'on_w'=>'birth_code_not','for_w'=>'ABCD'}
    generate_search_options(:search).should == {:conditions=>"not (:H_Ccode = 'ABCD')"}
    @search_params = {'on_w'=>'birth_code_b','for_w'=>'ABCD'}
    generate_search_options(:search).should == {:conditions=>"(:H_Ccode like 'ABCD%')"}
    @search_params = {'on_w'=>'birth_code_c','for_w'=>'ABCD'}
    generate_search_options(:search).should == {:conditions=>"(:H_Ccode like '%ABCD%')"}
    Metaform.set_usingPostgres(true)
    def_search_rules(:search,'birth_code' => 'H_Ccode')
    generate_search_options(:search).should == {:conditions=>"(:H_Ccode ilike '%ABCD%')"}
    Metaform.set_usingPostgres(false)
  end
end
