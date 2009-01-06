require File.dirname(__FILE__) + '/../spec_helper'

describe Listings do
  before(:each) do
    Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
    r = Record.make(SampleForm.new,'new_entry',{:name =>'Jane Smith',:fruit => 'banana',:occupation => 'unemployed'})
    r[:occupation,1] = 'farmer'
    r.occupation__2 = 'painter'
    r.save('new_entry')
  end
  it "should return 4 items" do 
    @list = Log.get_list('samples')
    @list.size.should == 4
  end
  
  it "should return 1 item when called on a single member array of Form Instances" do
    @list = Log.get_list('samples',:records => [FormInstance.find(:first)])
    @list.size.should == 1
  end
  
  it "should return 1 item when called via a proc which returns a single member array of Form Instances" do
    @list = Log.get_list('samples',:records => Proc.new {[FormInstance.find(:first)] })
    @list.size.should == 1
  end
end