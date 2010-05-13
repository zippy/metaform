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
      Form.set_store(:time_zone,'Eastern Time (US & Canada)')
      d2 = parse_date("1/1/2009")
      d2.should == d1
    end
  end
end