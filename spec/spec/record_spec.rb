require File.dirname(__FILE__) + '/../spec_helper'

describe Record do
  
  describe "(creating a new one)" do
    before(:each) do
      @record = Record.make('SampleForm','new_entry',{:name =>'Fred Smith'})
    end
    
    it "should return values via the [] operator" do
      @record[:name].should == 'Fred Smith'
    end
    
    it "should return values directly as attributes of the object" do
      @record.name.should == 'Fred Smith'
    end
    
    it "should return nil for un-initialized attributes" do
      @record.due_date.should == nil 
    end
    
    it "should complain when accessing an attribute that doesn't exist" do
      lambda { @record.fish }.should raise_error(NoMethodError)
    end
  end
  
end