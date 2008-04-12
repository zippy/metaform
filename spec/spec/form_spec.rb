require File.dirname(__FILE__) + '/../spec_helper'

describe Form, "using sample form as 'schema'" do
  it "should define a SampleForm class" do
    SampleForm.should == SampleForm
  end
  it "should have 9 fields" do
    SampleForm.fields.size.should == 10
  end
end