require File.dirname(__FILE__) + '/../spec_helper'

include TimeHelper
include DateHelper

describe DateHelper do
  describe 'parse_date_value' do
    it 'should convert date to a Date object' do
      parse_date_value("1/2/2001").should == Date.new(2001,1,2)
    end
    it 'should convert nil to a nil' do
      parse_date_value(nil).should == nil
    end
    it 'should convert empty string to a nil' do
      parse_date_value('').should == nil
    end
  end
  describe 'convert_date_html_value' do
    it 'should convert html values to a Time object' do
      convert_date_html_value({'year'=>'2001','month'=>'1','day'=>'2'}).should == Time.mktime(2001,1,2)
    end
    it 'should convert empty html values to nil' do
      convert_date_html_value({'year'=>'','month'=>'','day'=>''}).should == nil
    end
    it 'should convert invalid html values to nil' do
      convert_date_html_value({'year'=>'xsy','month'=>'99','day'=>''}).should == nil
    end
    it 'should convert 2 digit years less than 38 to 2000s and greater than 37 to 1900s' do
      convert_date_html_value({'year'=>'12','month'=>'1','day'=>'2'}).should == Time.mktime(2012,1,2)
      convert_date_html_value({'year'=>'37','month'=>'1','day'=>'2'}).should == Time.mktime(2037,1,2)
      convert_date_html_value({'year'=>'38','month'=>'1','day'=>'2'}).should == Time.mktime(1938,1,2)
    end
  end
end

describe TimeHelper do
  describe 'has_time?' do
    it 'should be true for 2001-01-01 12:00' do
      has_time?("2001-01-01 12:00").should == true
    end
    it 'should be false for 2001-01-01' do
      has_time?("2001-01-01").should == false
    end
    it 'should be true for 12:00' do
      has_time?("12:00").should == true
    end
  end
  describe 'parse_time_value' do
    it 'should convert 0:0 to 12:00 am' do
      parse_time_value("0:0").should == ['12','00','am']
    end
    it 'should convert 1:0 to 1:00 am' do
      parse_time_value("1:0").should == ['1','00','am']
    end
    it 'should convert 11:0 to 11:00 am' do
      parse_time_value("11:0").should == ['11','00','am']
    end
    it 'should convert 12:0 to 12:00 pm' do
      parse_time_value("12:0").should == ['12','00','pm']
    end
    it 'should convert 13:0 to 1:00 pm' do
      parse_time_value("13:0").should == ['1','00','pm']
    end
    it 'should convert 23:0 to 11:00 pm' do
      parse_time_value("23:0").should == ['11','00','pm']
    end
    it 'should convert nil to nil' do
      parse_time_value(nil).should == nil
    end
    it 'should convert empty string to nil' do
      parse_time_value('').should == nil
    end
    it 'should covert dates without time to nil' do
      parse_time_value('2012-10-01').should == nil
    end
  end
  describe 'convert_time_html_value' do
    it 'should convert 12:00 am to 00:00' do
      convert_time_html_value({'hours'=>'12','minutes'=>'00','am_pm'=>'am'}).strftime("%H:%M").should == "00:00"
    end
    it 'should convert 1:00 am 1:00' do
      convert_time_html_value({'hours'=>'1','minutes'=>'0','am_pm'=>'am'}).strftime("%H:%M").should == "01:00"
    end
    it 'should convert 11:00 am to 11:00' do
      convert_time_html_value({'hours'=>'11','minutes'=>'0','am_pm'=>'am'}).strftime("%H:%M").should == "11:00"
    end
    it 'should convert 12:00 pm to 12:00' do
      convert_time_html_value({'hours'=>'12','minutes'=>'0','am_pm'=>'pm'}).strftime("%H:%M").should == "12:00"
    end
    it 'should convert 1:00 pm to 13:00' do
      convert_time_html_value({'hours'=>'1','minutes'=>'0','am_pm'=>'pm'}).strftime("%H:%M").should == "13:00"
    end
    it 'should convert 11:00 pm to 23:00' do
      convert_time_html_value({'hours'=>'11','minutes'=>'0','am_pm'=>'pm'}).strftime("%H:%M").should == "23:00"
    end
    it 'should convert 13:00 am to 13:00' do
      convert_time_html_value({'hours'=>'13','minutes'=>'00','am_pm'=>'am'}).strftime("%H:%M").should == "13:00"
    end
    it 'should convert 13:00 pm to 13:00' do
      convert_time_html_value({'hours'=>'13','minutes'=>'00','am_pm'=>'pm'}).strftime("%H:%M").should == "13:00"
    end
    it 'should convert no values to nil' do
      convert_time_html_value({'hours'=>'','minutes'=>'','am_pm'=>'pm'}).should == nil
    end
    it 'should convert x:00 pm to nil' do
      convert_time_html_value({'hours'=>'x','minutes'=>'00','am_pm'=>'pm'}).should == nil
    end
    it 'should convert 12:x pm to nil' do
      convert_time_html_value({'hours'=>'12','minutes'=>'x','am_pm'=>'pm'}).should == nil
    end
    it 'should convert :00 pm to nil' do
      convert_time_html_value({'hours'=>'','minutes'=>'00','am_pm'=>'pm'}).should == nil
    end
    it 'should convert 12: pm to nil' do
      convert_time_html_value({'hours'=>'12','minutes'=>'','am_pm'=>'pm'}).should == nil
    end
  end
end
