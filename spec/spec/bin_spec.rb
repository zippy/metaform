require File.dirname(__FILE__) + '/../spec_helper'

describe Bin do
  it "should be created with a bin bins hash" do
    b = Bin.new(:name => 'the_name',:type => 'string',:label=>'the_label')
    b.name.should == 'the_name'
    b.type.should == 'string'
    b.label.should == 'the_label'
    lambda {b.xxx.should}.should raise_error(NoMethodError)
  end
  it "should be possible to create a new bin by assigning to it directly" do
    b = Bin.new
    b.fish='dog'
    b.fish.should == 'dog'
  end
  it "should be possible to access a bin with the [] method" do
    b = Bin.new(:name => 'the_name',:type => 'string',:label=>'the_label')
    b[:name].should == 'the_name'
  end
  it "should be possible to store values to a bin with the []= method" do
    b = Bin.new(:name => 'the_name',:type => 'string',:label=>'the_label')
    b[:label].should == 'the_label'
    b[:label]= 'bob'
    b[:label].should == 'bob'
  end
end