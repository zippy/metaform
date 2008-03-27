require File.dirname(__FILE__) + '/../spec_helper'

describe Reports, "using sample form as 'fixture'" do
  before(:each) do
    @initial_values = {:name =>'Fred Smith',:fruit => 'banana',:occupation => 'unemployed'}
    Record.make('SampleForm','new_entry',@initial_values).save('new_entry')
    Record.make('SampleForm','new_entry',@initial_values).save('new_entry')
    r = Record.make('SampleForm','new_entry',@initial_values)
    r[:occupation,1] = 'farmer'
    r.occupation__2 = 'painter'
    r.save('new_entry')
    
    @report = Stats.get_report('fruits')
  end
  it "should report a count of 3 bananas" do 
    @report.bananas.should == 3
  end
  
  it "should report 1 painter" do 
    @report.painters.should == 1
  end

  it "should report 3 slackers" do 
    @report.slackers.should == 3
  end
  
end