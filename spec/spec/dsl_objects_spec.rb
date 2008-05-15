require File.dirname(__FILE__) + '/../spec_helper'

describe Field do
  it "should require name and type parameters" do
    lambda {Field.new}.should raise_error("Field reqires 'name' to be defined")
    lambda {Field.new(:name=>'bob')}.should raise_error("Field reqires 'type' to be defined")
    lambda {Field.new(:name=>'bob',:type=>'string')}.should_not raise_error
  end
end