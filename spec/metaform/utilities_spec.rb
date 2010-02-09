require File.dirname(__FILE__) + '/../spec_helper'

include Utilities
describe Utilities do
  describe "parse_date" do
    it "should parse dates" do
      parse_date("10/20/2009").should == Time.local(2009,10,20)
    end
    it "should parse dates taking into account a timezone in Form.store" do
      Form.set_store(:time_zone,'UTC')
      d1 = parse_date("1/1/2009 05:00:00")
      Form.set_store(:time_zone,"Eastern Time (US & Canada)")
      d2 = parse_date("1/1/2009")
      d2.should == d1
    end
  end
  describe "numerics" do
    it "should test return false for non-numbers" do
      is_numeric?("x").should == false
      is_numeric?("1x").should == false
      is_numeric?("x3").should == false
      is_numeric?("3 3").should == false
      is_numeric?(nil).should == false
      is_numeric?("1.0.1").should == false
      is_numeric?("1..1").should == false
      is_numeric?("-1.0.1").should == false
    end
    it "should test return true for numbers" do
      is_numeric?("1.0").should == true
      is_numeric?("1.1").should == true
      is_numeric?("-1.1").should == true
      is_numeric?("100").should == true
      is_numeric?("-100").should == true
      is_numeric?("0").should == true
      is_numeric?("0.0").should == true
    end
  end
  describe "integers" do
    it "should test return false for non-integers" do
      is_integer?("x").should == false
      is_integer?("1x").should == false
      is_integer?("x3").should == false
      is_integer?("3 3").should == false
      is_integer?(nil).should == false
      is_integer?("1.0").should == false
      is_integer?("1.0.1").should == false
      is_integer?("1..1").should == false
      is_integer?("-1.0.1").should == false
    end
    it "should test return true for numbers" do
      is_integer?("100").should == true
      is_integer?("-100").should == true
      is_integer?("0").should == true
    end
  end
end