require File.dirname(__FILE__) + '/../spec_helper'

describe Form, "using sample form as 'fixture'" do
  it "should define a SampleForm class" do
    SampleForm.should == SampleForm
  end
  it "should have 9 fields" do
    SampleForm.fields.size.should == 9
  end
end