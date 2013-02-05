require File.dirname(__FILE__) + '/../spec_helper'

include Utilities
describe Utilities do
  describe "parse_date" do
    it "should parse dates" do
      parse_date("10/20/2009").should == DateTime.new(2009,10,20)
      parse_date("2012-10-04 00:00:00").should == DateTime.new(2012,10,04)
    end
    it "should parse dates taking into account a timezone in Form.store" do
      Form.set_store(:time_zone,'UTC')
      d1 = parse_date("1/1/2009 05:00:00")
      Form.set_store(:time_zone,'Eastern Time (US & Canada)')
      d2 = parse_date("1/1/2009")
      d2.should == d1
    end
    it "should parse datetimes into an array" do
      parse_datetime("2012-12-20 1:2:3").should == [2012,12,20,1,2,3]
      parse_datetime("2012-12-20 1:2").should == [2012,12,20,1,2,0]
      parse_datetime("2012-12-20").should == [2012,12,20,0,0,0]
      parse_datetime("12/20/2012 1:2:3").should == [2012,12,20,1,2,3]
      parse_datetime("12/20/2012 1:2").should == [2012,12,20,1,2,0]
      parse_datetime("12/20/2012").should == [2012,12,20,0,0,0]
      parse_datetime("").should == [nil,nil,nil,nil,nil,nil]
    end
  end
  describe "numerics" do
    it "should test return false for non-numbers" do
      is_numeric?("").should == false
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
      is_integer?("").should == false
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