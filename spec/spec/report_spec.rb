require File.dirname(__FILE__) + '/../spec_helper'

describe Reports, "using sample form as 'schema'" do
  before(:each) do
    Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
    r = Record.make(SampleForm.new,'new_entry',{:name =>'Jane Smith',:fruit => 'banana',:occupation => 'unemployed'})
    r[:occupation,1] = 'farmer'
    r.occupation__2 = 'painter'
    r.save('new_entry')
    
    @report = Stats.get_report('fruits')
  end
  it "should report a count of 2 bananas" do 
    @report.bananas.should == 2
  end

  it "should report 2 apples" do 
    @report.apples.should == 2
  end
  
  it "should report 1 painter" do 
    @report.painters.should == 1
  end

  it "should report 4 slackers" do 
    @report.slackers.should == 4
  end  
end

describe Reports, "using simple filters" do
  before(:each) do
    Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
    r = Record.make(SampleForm.new,'new_entry',{:name =>'Jane Smith',:fruit => 'banana',:occupation => 'unemployed'})
    r[:occupation,1] = 'farmer'
    r.occupation__2 = 'painter'
    r.save('new_entry')    
  end
  
  it "should filter out desired entries for field not being counted" do
    filters = [':name != "Bob Smith"']
    @report = Stats.get_report('fruits',:filters => filters)
    @report.bananas.should == 1
  end
  
  it "should filter out desired entries for field being counted" do
    filters = [':fruit =~ /mutsu/']
    @report = Stats.get_report('fruits',:filters => filters)
    @report.apples.should == 1
  end
  
  it "should not count items in the wrong workflow state" do
    @records = []
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
    @records.last.workflow_state = 'standard'
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
    @records.each { |recs| recs.save('new_entry') }
    @report_workflow = Stats.get_report('report_with_workflow')
    @report_workflow.bobs.should == 1
  end
  
  it "should count items in any of the filtered workflow states" do
    @records = []
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
    @records.last.workflow_state = 'standard'
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
    @records.last.workflow_state = 'unusual'
    @records.each { |recs| recs.save('new_entry') }
    @report_workflow = Stats.get_report('report_with_2_workflows')
    @report_workflow.bobs.should == 2
  end
  
  it "should count items in any of the filtered workflow states, when workflow state filter is a regex" do
    @records = []
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
    @records.last.workflow_state = 'standard_1'
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
    @records.last.workflow_state = 'standard_2'
    @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Jones',:fruit => 'pear'})
    @records.last.workflow_state = 'unusual'
    @records.each { |recs| recs.save('new_entry') }
    @report_workflow = Stats.get_report('report_with_workflow')
    puts "@report_workflow = #{@report_workflow.inspect}"
    @report_workflow.bobs.should == 2
  end
end
