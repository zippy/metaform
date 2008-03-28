require File.dirname(__FILE__) + '/../spec_helper'

describe Reports, "using sample form as 'schema'" do
  before(:each) do
    Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    Record.make('SampleForm','new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
    Record.make('SampleForm','new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
    r = Record.make('SampleForm','new_entry',{:name =>'Jane Smith',:fruit => 'banana',:occupation => 'unemployed'})
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