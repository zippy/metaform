require File.dirname(__FILE__) + '/../spec_helper'

include TimeHelper
include DateHelper

describe TimeHelper do
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