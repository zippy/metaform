require File.dirname(__FILE__) + '/../spec_helper'

describe FieldInstance do
  it "should complain when creating duplicate field instances" do
    f = FieldInstance.new({:field_id=>'x', :form_instance_id => 1, :idx => 0,:state => 'answered'})
    f.save.should == true
    f2 = FieldInstance.new({:field_id=>'x', :form_instance_id => 1, :idx => 0,:state => 'answered'})
    f2.save.should == false
    f2.errors.on(:field_id).should == "attempt to create duplicate field instance for: x"
    f = FieldInstance.new({:field_id=>'x', :form_instance_id => 1, :idx => 1,:state => 'answered'})
    f.save.should == true
    f = FieldInstance.new({:field_id=>'y', :form_instance_id => 1, :idx => 0,:state => 'answered'})
    f.save.should == true
    f = FieldInstance.new({:field_id=>'x', :form_instance_id => 2, :idx => 0,:state => 'answered'})
    f.save.should == true
  end
end