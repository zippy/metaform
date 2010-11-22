require File.dirname(__FILE__) + '/../spec_helper'

describe Widget do  
  describe 'default methods for all widgets' do
    it "should include a default #render_form_object_read_only" do
      Widget.render_form_object_read_only(1,'value',{}).should == 
        "<span id=\"record_1\">value</span>"
    end
    it "should include #humanize_value" do
      Widget.humanize_value('value').should == 'value'
    end
    it "should include #humanize_value that works on enumerations defined with hashes" do
      Widget.humanize_value('y',:constraints => {'enumeration' => [{'y' => 'Yes'},{'n'=>'No'}]}).should == 'Yes'
    end
    it "should include #humanize_value that works on enumerations defined in rails array style" do
      Widget.humanize_value('CAN',:constraints => {'enumeration' => [	[ "-" , nil ],[ "US" , "US" ],	[ "Canada" , "CAN" ]]}).should == 'Canada'
    end
    it "should include #humanize_value that works on enumerations when value is nil" do
      Widget.humanize_value(nil,:constraints => {'enumeration' => [{'y' => 'Yes'},{'n'=>'No'}]}).should == nil
    end
    it "should include #humanize_value that works on sets defined with hashes" do
      Widget.humanize_value('1',:constraints => {'set' => [{'1' => 'This'},{'2'=>'That'}]}).should == 'This'
      Widget.humanize_value('2,1',:constraints => {'set' => [{'1' => 'This'},{'2'=>'That'}]}).should == 'That, This'
    end
    it "should include #humanize_value that works on sets defined in rails array style" do
      Widget.humanize_value('CAN',:constraints => {'set' => [	[ "-" , nil ],[ "US" , "US" ],	[ "Canada" , "CAN" ]]}).should == 'Canada'
      Widget.humanize_value('CAN,US',:constraints => {'set' => [	[ "-" , nil ],[ "US" , "US" ],	[ "Canada" , "CAN" ]]}).should == 'Canada, US'
    end
    it "should include #humanize_value that works on sets when value is nil" do
      Widget.humanize_value(nil,:constraints => {'set' => [	[ "-" , nil ],[ "US" , "US" ],	[ "Canada" , "CAN" ]]}).should == nil
    end
  end
  
  describe TextFieldWidget do
    it "should render an html input text with a label" do
      TextFieldWidget.render_form_object(1,'value',{}).should == 
        "<input id=\"record_1\" name=\"record[1]\" type=\"text\" value=\"value\" />"
    end
    it "should render an html input text with a size parameter" do
      TextFieldWidget.render_form_object(1,'value',{:params=>'3'}).should == 
        "<input class=\"textfield_3\" id=\"record_1\" name=\"record[1]\" size=\"3\" type=\"text\" value=\"value\" />"
    end
    it "should render an html input text with a size and max parameter" do
      TextFieldWidget.render_form_object(1,'value',{:params=>'3,2'}).should == 
        "<input class=\"textfield_3\" id=\"record_1\" maxlength=\"2\" name=\"record[1]\" size=\"3\" type=\"text\" value=\"value\" />"
    end
    it "should render value as text with a read_only parameter" do
      TextFieldWidget.render_form_object_read_only(1,'value',{}).should == 
        "<span id=\"record_1\">value</span>"
    end
  end

  describe TextFieldIntegerWidget do
    it "should render an html input text with a label" do
      TextFieldIntegerWidget.render_form_object(1,'100',{}).should == 
      "    <span id=\"record_1_wrapper\"><input id=\"record_1\" name=\"record[1]\" onchange=\"mark_invalid_integer('record_1')\" onkeyup=\"mark_invalid_integer('record_1')\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render an html input text with a size parameter" do
      TextFieldIntegerWidget.render_form_object(1,'100',{:params=>'3'}).should == 
      "    <span id=\"record_1_wrapper\"><input class=\"textfield_3\" id=\"record_1\" name=\"record[1]\" onchange=\"mark_invalid_integer('record_1')\" onkeyup=\"mark_invalid_integer('record_1')\" size=\"3\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render an html input text with a size and max parameter" do
      TextFieldIntegerWidget.render_form_object(1,'100',{:params=>'3,2'}).should == 
      "    <span id=\"record_1_wrapper\"><input class=\"textfield_3\" id=\"record_1\" maxlength=\"2\" name=\"record[1]\" onchange=\"mark_invalid_integer('record_1')\" onkeyup=\"mark_invalid_integer('record_1')\" size=\"3\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render value as text with a read_only parameter" do
      TextFieldIntegerWidget.render_form_object_read_only(1,'100',{}).should == 
        "<span id=\"record_1\">100</span>"
    end
    it "should convert html values to a number" do
      TextFieldIntegerWidget.convert_html_value("100").should == 100
      TextFieldIntegerWidget.convert_html_value("0").should == 0
    end
    it "should convert bad html values to nil" do
      TextFieldIntegerWidget.convert_html_value("").should == nil
      TextFieldIntegerWidget.convert_html_value("x").should == nil
      TextFieldIntegerWidget.convert_html_value("-1").should == nil
      TextFieldIntegerWidget.convert_html_value("10.0").should == nil
      TextFieldIntegerWidget.convert_html_value("x0").should == nil
      TextFieldIntegerWidget.convert_html_value("0x").should == nil
      TextFieldIntegerWidget.convert_html_value("0x0").should == nil
    end
  end

  describe TextFieldFloatWidget do
    it "should render an html input text with a label" do
      TextFieldFloatWidget.render_form_object(1,'100',{}).should == 
      "    <span id=\"record_1_wrapper\"><input id=\"record_1\" name=\"record[1]\" onchange=\"mark_invalid_float('record_1')\" onkeyup=\"mark_invalid_float('record_1')\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render an html input text with a size parameter" do
      TextFieldFloatWidget.render_form_object(1,'100',{:params=>'3'}).should == 
      "    <span id=\"record_1_wrapper\"><input class=\"textfield_3\" id=\"record_1\" name=\"record[1]\" onchange=\"mark_invalid_float('record_1')\" onkeyup=\"mark_invalid_float('record_1')\" size=\"3\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render an html input text with a size and max parameter" do
      TextFieldFloatWidget.render_form_object(1,'100',{:params=>'3,2'}).should == 
      "    <span id=\"record_1_wrapper\"><input class=\"textfield_3\" id=\"record_1\" maxlength=\"2\" name=\"record[1]\" onchange=\"mark_invalid_float('record_1')\" onkeyup=\"mark_invalid_float('record_1')\" size=\"3\" type=\"text\" value=\"100\" /></span>\n"
    end
    it "should render value as text with a read_only parameter" do
      TextFieldFloatWidget.render_form_object_read_only(1,'100',{}).should == 
        "<span id=\"record_1\">100</span>"
    end
    it "should convert html values to a number" do
      TextFieldFloatWidget.convert_html_value("100").should == 100
      TextFieldFloatWidget.convert_html_value("0").should == 0
      TextFieldFloatWidget.convert_html_value("10.0").should == 10
      TextFieldFloatWidget.convert_html_value("10.1").should == 10.1
      TextFieldFloatWidget.convert_html_value("0.1").should == 0.1
      TextFieldFloatWidget.convert_html_value(".1").should == 0.1
    end
    it "should convert bad html values to nil" do
      TextFieldFloatWidget.convert_html_value("").should == nil
      TextFieldFloatWidget.convert_html_value("x").should == nil
      TextFieldFloatWidget.convert_html_value("-1").should == nil
      TextFieldFloatWidget.convert_html_value("x0").should == nil
      TextFieldFloatWidget.convert_html_value("0x").should == nil
      TextFieldFloatWidget.convert_html_value("0x0").should == nil
    end
    
  end
  describe TextAreaWidget do
    it "should render an html text area with a label" do
      TextAreaWidget.render_form_object(1,'value',{}).should == 
        "<textarea id=\"record_1\" name=\"record[1]\">value</textarea>"
    end
    it "should render an html input text with rows & columns parameters" do
      TextAreaWidget.render_form_object(1,'value',{:params=>'10,20'}).should == 
        "<textarea cols=\"20\" id=\"record_1\" name=\"record[1]\" rows=\"10\">value</textarea>"
    end
    it "should render value as text with a read_only parameter" do
      TextAreaWidget.render_form_object_read_only(1,'value',{}).should == 
        "<span id=\"record_1\">value</span>"
    end
  end

  describe DateWidget do
    it "should render three html input texts and the instructions" do
      DateWidget.render_form_object(1,"2004-10-23",{}).should == 
      "    <script type=\"text/javascript\">\n    //<![CDATA[\n    var record_1_first_pass =  true;\n    //]]>\n    </script> \n    <span id=\"record_1_wrapper\"><input onblur=\"if (record_1_first_pass) {mark_invalid_date('record_1')}\" type=\"text\"  size=2 class=\"textfield_2\" name=\"record[1][month]\" id=\"record_1_month\" value=\"10\" maxlength=\"2\"/> /\n<input onblur=\"if (record_1_first_pass) {mark_invalid_date('record_1')}\" type=\"text\"  size=2 class=\"textfield_2\" name=\"record[1][day]\" id=\"record_1_day\" value=\"23\" maxlength=\"2\"/> /\n<input onblur=\"mark_invalid_date('record_1');record_1_first_pass = true;\" type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][year]\" id=\"record_1_year\" value=\"2004\" maxlength=\"4\"/> <span class=\"instructions\">(MM/DD/YYYY)</span>\n</span>\n"
    end
    it "should render date value as text with a read_only parameter" do
      DateWidget.render_form_object_read_only(1,"2004-10-23",{}).should == 
        "<span id=\"record_1\">10/23/2004</span>"
    end
    it "should convert html values to an SQL style string date" do
      DateWidget.convert_html_value({'month'=>'12','day'=>'01','year'=>'2001'}).should == '2001-12-01'
    end
    it "should convert bad html values to nil" do
      DateWidget.convert_html_value({'month'=>'xx','day'=>'77','year'=>'2001'}).should == nil
      DateWidget.convert_html_value({'month'=>'','day'=>'','year'=>''}).should == nil
    end
  end
  
  describe TimeWidget do
    it "should render two html input texts plus a select for am/pm" do
      TimeWidget.render_form_object(1,"3:22",{}).should == 
        "     <script type=\"text/javascript\">\n     //<![CDATA[\n     var record_1_first_pass = true;\n     //]]>\n     </script> \n    <span id=\"record_1_wrapper\">      <input onblur=\"if (record_1_first_pass) {mark_invalid_time('record_1')}\" type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][hours]\" id=\"record_1_hours\" value=\"3\" maxlength=\"2\"/>:\n      <input onblur=\"mark_invalid_time('record_1');record_1_first_pass = true;\" type=\"text\" class=\"left_margin_neg_5 textfield_2\" size=2 name=\"record[1][minutes]\" id=\"record_1_minutes\" value=\"22\" maxlength=\"2\"/>\n      <select onblur=\"if (record_1_first_pass) {mark_invalid_time('record_1')}\" name=\"record[1][am_pm]\" id=\"record_1_am_pm\">\n      \t<option value=\"am\" selected=\"selected\">AM</option>\n<option value=\"pm\">PM</option>\n\t  </select>\n</span>\n"
    end
    it "should render time value as text with a read_only parameter" do
      TimeWidget.render_form_object_read_only(1,"3:22",{}).should == 
        "<span id=\"record_1\">3:22 am</span>"
    end
    it "should render low min time values with a preceeding 0 text if read_only" do
      TimeWidget.render_form_object_read_only(1,"13:02",{}).should == 
        "<span id=\"record_1\">1:02 pm</span>"
    end
    it "should convert html values to a 24 hour string date" do
      TimeWidget.convert_html_value({'hours'=>'12','minutes'=>'00','am_pm'=>'am'}).should == '00:00'
      TimeWidget.convert_html_value({'hours'=>'12','minutes'=>'00','am_pm'=>'pm'}).should == '12:00'
      TimeWidget.convert_html_value({'hours'=>'13','minutes'=>'00','am_pm'=>'am'}).should == '13:00'
      TimeWidget.convert_html_value({'hours'=>'1','minutes'=>'00','am_pm'=>'pm'}).should == '13:00'
    end
    it "should convert bad html values to nil" do
      TimeWidget.convert_html_value({'hours'=>'33','minutes'=>'xx','am_pm'=>'am'}).should == nil
      TimeWidget.convert_html_value({'hours'=>'99','minutes'=>'00','am_pm'=>'pm'}).should == nil
      TimeWidget.convert_html_value({'hours'=>'','minutes'=>'','am_pm'=>''}).should == nil
    end
  end
  
  describe DateTimeWidget do
    it "should convert html values to a date-time string" do
      d = {'month'=>'12','day'=>'01','year'=>'2001', 'hours'=>'12','minutes'=>'00','am_pm'=>'am'}
      DateTimeWidget.convert_html_value(d).should == '2001-12-01 00:00'
    end
    it "should convert bad html values to nil" do
      d = {'month'=>'','day'=>'','year'=>'', 'hours'=>'','minutes'=>'','am_pm'=>'am'}
      DateTimeWidget.convert_html_value(d).should == nil
    end
  end
  

  describe TimeIntervalWidget do
    it "should render two html input texts plus a select for am/pm" do
      TimeIntervalWidget.render_form_object(1,"500",{}).should == 
        "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][hours]\" id=\"record_1_hours\" value=\"8\" /> hours\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][minutes]\" id=\"record_1_minutes\" value=\"20\" /> minutes\n"
    end
    it "should render interval value as text if read_only" do
      TimeIntervalWidget.render_form_object_read_only(1,"500",{}).should == 
        "<span id=\"record_1\">8 hours, 20 minutes</span>"
    end
    it "should convert html values to minutes" do
      TimeIntervalWidget.convert_html_value({'hours'=>'','minutes'=>''}).should == ""
      TimeIntervalWidget.convert_html_value({'hours'=>'0','minutes'=>''}).should == "0"
      TimeIntervalWidget.convert_html_value({'hours'=>'','minutes'=>'0'}).should == "0"
      TimeIntervalWidget.convert_html_value({'hours'=>'0','minutes'=>'0'}).should == "0"
      TimeIntervalWidget.convert_html_value({'hours'=>'1','minutes'=>'30'}).should == "90"
      TimeIntervalWidget.convert_html_value({'hours'=>'0','minutes'=>'30'}).should == "30"
      TimeIntervalWidget.convert_html_value({'hours'=>'','minutes'=>'30'}).should == "30"
      TimeIntervalWidget.convert_html_value({'hours'=>'1','minutes'=>''}).should == "60"
      TimeIntervalWidget.convert_html_value({'hours'=>'1.5','minutes'=>''}).should == "90"
      TimeIntervalWidget.convert_html_value({'hours'=>'1.5','minutes'=>'4'}).should == "94"
    end
    it "should convert bad html values to nil" do
      TimeIntervalWidget.convert_html_value({'hours'=>'x','minutes'=>'30'}).should == nil
      TimeIntervalWidget.convert_html_value({'hours'=>'1','minutes'=>'x'}).should == nil
    end
  end
  describe TimeIntervalWithDaysWidget do
    it "should render three html input texts" do
      TimeIntervalWithDaysWidget.render_form_object(1,"500",{}).should == 
      "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][days]\" id=\"record_1_days\" value=\"0\" /> days\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][hours]\" id=\"record_1_hours\" value=\"8\" /> hours\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][minutes]\" id=\"record_1_minutes\" value=\"20\" /> minutes\n"
    end
    it "should render interval value as text if read_only" do
      TimeIntervalWithDaysWidget.render_form_object_read_only(1,"500",{}).should == 
        "<span id=\"record_1\">0 days, 8 hours, 20 minutes</span>"
    end
    it "should convert html values to minutes" do
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'','minutes'=>''}).should == ""
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'0','hours'=>'','minutes'=>''}).should == "0"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'0','minutes'=>''}).should == "0"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'','minutes'=>'0'}).should == "0"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'0','minutes'=>'0'}).should == "0"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'1','minutes'=>'30'}).should == "90"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'0','minutes'=>'30'}).should == "30"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'','minutes'=>'30'}).should == "30"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'1','minutes'=>''}).should == "60"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'1','hours'=>'','minutes'=>'1'}).should == "1441"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'1','hours'=>'1','minutes'=>'1'}).should == "1501"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'1.5','minutes'=>''}).should == "90"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'1.5','minutes'=>'4'}).should == "94"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'1','hours'=>'1.5','minutes'=>'4'}).should == "1534"
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'1.5','hours'=>'','minutes'=>''}).should == "2160"
    end
    it "should convert bad html values to nil" do
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'x','minutes'=>'30'}).should == nil
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'','hours'=>'1','minutes'=>'x'}).should == nil
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'x','hours'=>'','minutes'=>''}).should == nil
      TimeIntervalWithDaysWidget.convert_html_value({'days'=>'x','hours'=>'1','minutes'=>'1'}).should == nil
    end
  end
  
  describe FactorTextFieldsWidget do
    it "should render two html input texts and lables from params" do
      FactorTextFieldsWidget.render_form_object(1,"500",{:params=>"5,FirstLabel,SecondLabel"}).should == 
        "<input type=\"text\" size=2 name=\"record[1][first_box]\" id=\"record_1_first_box\" value=\"100\" /> FirstLabel\n<input type=\"text\" size=2 name=\"record[1][second_box]\" id=\"record_1_second_box\" value=\"0\" /> SecondLabel\n<input type=\"hidden\" name=\"record[1][factor]\"  id=\"record_1_factor\"/ value=\"5\">"
    end
    it "should render factor value as text if read_only" do
      FactorTextFieldsWidget.render_form_object_read_only(1,"500",{:params=>"5,FirstLabel,SecondLabel"}).should == 
        "<span id=\"record_1\">100 FirstLabel 0 SecondLabel</span>"
    end
    it "should convert html values based on the factor" do
      d = {'first_box'=>"100",'second_box'=>'0'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == "500"
      d = {'first_box'=>"100",'second_box'=>'3'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == "503"
      d = {'first_box'=>"0",'second_box'=>'0'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == "0"
      d = {'first_box'=>"",'second_box'=>''}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == ""
      d = {'first_box'=>"6",'second_box'=>''}
      ## NOTE: this tests that a single box left blank should be set to 0.  There are some uses of Metform that might not want that to be the case.
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == "30"
      d = {'first_box'=>"",'second_box'=>'3'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == "3"
    end
    it "should convert bad html values to nil" do
      d = {'first_box'=>"",'second_box'=>'x'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == nil

      d = {'first_box'=>"x",'second_box'=>''}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == nil
      d = {'first_box'=>"x",'second_box'=>'100'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == nil
      d = {'first_box'=>"100",'second_box'=>'x'}
      FactorTextFieldsWidget.convert_html_value(d,"5,FirstLabel,SecondLabel").should == nil
    end
  end

  describe MonthYearWidget do
    it "should render two html input texts" do
      MonthYearWidget.render_form_object(1,"2004-10-23",{}).should == 
        "    <script type=\"text/javascript\">\n    //<![CDATA[\n    var record_1_first_pass =  true;\n    //]]>\n    </script> \n    <span id=\"record_1_wrapper\"><input onblur=\"if (record_1_first_pass) {mark_invalid_month_year('record_1')}\" type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][month]\" id=\"record_1_month\" value=\"10\" /> /\n<input onblur=\"mark_invalid_month_year('record_1');record_1_first_pass = true;\" type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][year]\" id=\"record_1_year\" value=\"2004\" /> (month/year)\n</span>\n"
    end
    it "should render date value as text with a read_only parameter" do
      MonthYearWidget.render_form_object_read_only(1,"2004-10-23",{}).should == 
        "<span id=\"record_1\">10/2004</span>"
    end
  end

  describe CheckBoxWidget do
    it "should render an html checkbox " do
      CheckBoxWidget.render_form_object(1,"Y",{}).should == 
        ["<input name=\"record[1][Y]\" id=\"record_1_y\" type=\"checkbox\" checked>", "\n", "<input name=\"record[1][__none__]\" id=\"record_1___none__\" class=\"1\" type=\"hidden\">"]
    end
    it "should render 'Y' checked and read_only" do
      CheckBoxWidget.render_form_object_read_only(1,"Y",{}).should == 
        "<span id=\"record_1\">Y</span>"
    end
  end

  describe CheckBoxGroupWidget do
    before(:each) do
      @options = {:constraints => {'set'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3<x'=>'Value 3'}]}}
    end
     
    it "should render html checkboxes with a custom label" do
      CheckBoxGroupWidget.render(1,"val1",'the label',@options).should == 
        "<span class=\"label\">the label</span><input name=\"record[1][val1]\" id=\"record_1_val1\" class=\"1\" type=\"checkbox\" value=\"val1\" checked onClick=\"\"> <label for=\"record_1_val1\">Value 1</label>\n<input name=\"record[1][val2]\" id=\"record_1_val2\" class=\"1\" type=\"checkbox\" value=\"val2\" onClick=\"\"> <label for=\"record_1_val2\">Value 2</label>\n<input name=\"record[1][val3<x]\" id=\"record_1_val360x\" class=\"1\" type=\"checkbox\" value=\"val3<x\" onClick=\"\"> <label for=\"record_1_val360x\">Value 3</label><input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\">"
    end
    it "should render the list of human enumerations values if read_only" do
      CheckBoxGroupWidget.render_form_object_read_only(1,"val1,val3<x",@options).should == 
        "<span id=\"record_1\">Value 1, Value 3</span>"
    end
    it "should render the list of human enumerations values if read_only and one field is a *-indicated none field" do
      @options = {:constraints => {'set'=>[{'val1*'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
       CheckBoxGroupWidget.render_form_object_read_only(1,"val1,val3",@options).should == 
         "<span id=\"record_1\">Value 1, Value 3</span>"
     end
  end
  
  describe CheckBoxGroupFollowupWidget do
    before(:each) do
      @options = {:constraints => {'set'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'}]}, :params => "param_label,param1,param2"}
    end
     
    it "should render html checkboxes with a custom label" do
      CheckBoxGroupFollowupWidget.render(1,"val1",'the label',@options).should == 
      "<span class=\"label\">the label</span><br />      <input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\">\n      <span class=\"check_box_followup_input\"><input name=\"record[1][val1]\" id=\"record_1_val1\" class=\"1\" type=\"checkbox\" value=\"val1\" checked\n        onClick=\"do_click_1_regular(this,'val1','1_val1');try{values_for_1[cur_idx] = $CBFG('1');condition_actions_for_1();}catch(err){};\">\n        <label for=\"record_1_val1\">Value 1</label></span>\n                  <span id=\"1_val1\" class=\"checkbox_followups\" style=\"display:inline\">\n          &nbsp;&nbsp; param_label           <input name=\"record[1][_val1-param1]\" id=\"record_1__val145param1\" class=\"1_val1_followup\" type=\"checkbox\" value=\"param1\"  ><label for=\"record_1__val145param1\">Param1</label>\n\n          <input name=\"record[1][_val1-param2]\" id=\"record_1__val145param2\" class=\"1_val1_followup\" type=\"checkbox\" value=\"param2\"  ><label for=\"record_1__val145param2\">Param2</label>\n\n          </span>\n\n<br />      <input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\">\n      <span class=\"check_box_followup_input\"><input name=\"record[1][val2]\" id=\"record_1_val2\" class=\"1\" type=\"checkbox\" value=\"val2\" \n        onClick=\"do_click_1_regular(this,'val2','1_val2');try{values_for_1[cur_idx] = $CBFG('1');condition_actions_for_1();}catch(err){};\">\n        <label for=\"record_1_val2\">Value 2</label></span>\n                  <span id=\"1_val2\" class=\"checkbox_followups\" style=\"display:none\">\n          &nbsp;&nbsp; param_label           <input name=\"record[1][_val2-param1]\" id=\"record_1__val245param1\" class=\"1_val2_followup\" type=\"checkbox\" value=\"param1\"  ><label for=\"record_1__val245param1\">Param1</label>\n\n          <input name=\"record[1][_val2-param2]\" id=\"record_1__val245param2\" class=\"1_val2_followup\" type=\"checkbox\" value=\"param2\"  ><label for=\"record_1__val245param2\">Param2</label>\n\n          </span>\n\n<div class=\"clear\"></div><script type=\"text/javascript\">\n//<![CDATA[\n    \t\tfunction do_click_1_regular(theCheckbox,theValue,theFollowupID) {\n          var e = $(theFollowupID); \n          if (theCheckbox.checked) {\n            Effect.BlindDown(e, {duration:.5});\n            \n          } else {\n            Effect.BlindUp(e, {duration:.5});\n            $$('.1_'+theValue+'_followup').each(function(cb){cb.checked=false});\n          }           \n   \t\t  }        \n\n//]]>\n</script>"
    end
    it "should render the list of human enumerations values if read_only, including followups" do
      CheckBoxGroupFollowupWidget.render_form_object_read_only(1,"val1: \n- param2\nval2: \n- param1\n- param2\n",@options).should == 
        "<span id=\"record_1\">Value 1:  Param2\\nValue 2:  Param1, Param2</span>"
    end
  end

  describe RadioButtonsWidget do
    before(:each) do
      @options = {:constraints => {'enumeration'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
    end
     
    it "should render html checkboxes with a custom label" do
      RadioButtonsWidget.render(1,"val1",'the label',@options).should == 
        "<span class=\"label\">the label</span><input name=\"record[1]\" id=\"record_1_val1\" class=\"1\" type=\"radio\" value=\"val1\" checked> <label for=\"record_1_val1\">Value 1</label>\n<input name=\"record[1]\" id=\"record_1_val2\" class=\"1\" type=\"radio\" value=\"val2\" > <label for=\"record_1_val2\">Value 2</label>\n<input name=\"record[1]\" id=\"record_1_val3\" class=\"1\" type=\"radio\" value=\"val3\" > <label for=\"record_1_val3\">Value 3</label>"
    end
    it "should render the human enumerations value if read_only" do
      RadioButtonsWidget.render_form_object_read_only(1,"val2",@options).should == 
        "<span id=\"record_1\">Value 2</span>"
    end
  end

  describe PopUpWidget do
    before(:each) do
      @options = {:constraints => {'enumeration'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
    end

    it "should render html select" do
      PopUpWidget.render_form_object(1,"val1",@options).should == 
        "<select name=\"record[1]\" id=\"record_1\">\n\t<option value=\"val1\" selected=\"selected\">Value 1</option>\n<option value=\"val2\">Value 2</option>\n<option value=\"val3\">Value 3</option>\n</select>\n"
    end
    it "should render html select with nil option if specified as the param" do
      @options[:params] = "Please choose a value"
      PopUpWidget.render_form_object(1,"val1",@options).should ==
        "<select name=\"record[1]\" id=\"record_1\">\n\t<option value=\"\">Please choose a value</option>\n<option value=\"val1\" selected=\"selected\">Value 1</option>\n<option value=\"val2\">Value 2</option>\n<option value=\"val3\">Value 3</option>\n</select>\n"
    end
    it "should render the human enumerations value if read_only" do
      PopUpWidget.render_form_object_read_only(1,"val2",@options).should == 
        "<span id=\"record_1\">Value 2</span>"
    end
  end
  
  describe VolumeWidget do
    it "should render an html input text with a label" do
      VolumeWidget.render_form_object(1,'2000',{}).should == 
      "      <input type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][cups_box]\" id=\"record_1_cups_box\" value=\"8.45\" onchange=\"record_1_update_volume(true)\" /> cups or\n      <input type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][ml_box]\" id=\"record_1_ml_box\" value=\"2000\" onchange=\"record_1_update_volume(false)\" /> cc (milliliters)\n      <script type=\"text/javascript\">\n//<![CDATA[\n      function record_1_update_volume(change_ml) {\n          if (change_ml) {\n            var cups = check_float($F('record_1_cups_box'));\n            if (cups==null) {\n              $('record_1_ml_box').value = '';\n            } else {\n              $('record_1_ml_box').value = Math.round(cups * 236.588237);\n            }\n          } else {\n            var ml = check_float($F('record_1_ml_box'));\n            if (ml==null) {\n              $('record_1_pounds_box').value='';\n            } else {\n              $('record_1_cups_box').value = Math.round(ml * 0.422675283) / 100;\n            }\n          }\n      }\n\n//]]>\n</script>\n"
    end
    it "should convert html values based on the ml value rounded " do
      VolumeWidget.convert_html_value({'ml_box'=>'10.1'}).should == 10
      VolumeWidget.convert_html_value({'ml_box'=>''}).should == ''
    end
    it "should convert bad html values to nil" do
      VolumeWidget.convert_html_value({'ml_box'=>'x'}).should == nil
    end
  end

  describe HeightWidget do
    it "should render an html input text with a label" do
      HeightWidget.render_form_object(1,'2000',{}).should == 
      "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][feet_box]\" id=\"record_1_feet_box\" value=\"65\" onchange=\"record_1_update_height(true)\" /> ft\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][inches_box]\" id=\"record_1_inches_box\" value=\"7\" onchange=\"record_1_update_height(true)\" /> in or\n      <input type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][meters_box]\" id=\"record_1_meters_box\" value=\"20.0\" onchange=\"record_1_update_height(false)\" /> m\n      <script type=\"text/javascript\">\n//<![CDATA[\n      function record_1_update_height(change_meters) {\n        if (change_meters) {\n          var feet = check_float($F('record_1_feet_box'));\n          var inches = check_float($F('record_1_inches_box'));\n          if (feet == null && inches == null){\n              $('record_1_meters_box').value=''\n            }else{\n              if (feet == null) { $('record_1_feet_box').value=''; feet = 0};\n              if (inches == null) { $('record_1_inches_box').value=''; inches = 0};\n               var meters = Math.round((feet * 12 + inches) *  2.54)/100;\n              $('record_1_meters_box').value = meters;\n            }\n          } else {\n            var meters = check_float($F('record_1_meters_box'));\n            if (meters == null){\n              $('record_1_feet_box').value='';\n              $('record_1_inches_box').value='';\n            }else{\n              var total_inches = meters * 39.370079;\n              var feet = Math.floor(total_inches / 12);\n              var inches = Math.round(total_inches % 12);\n              if (inches == 12) {\n                feet++;\n                inches = 0;\n              }\n              $('record_1_feet_box').value = feet;\n              $('record_1_inches_box').value = inches;\n            }\n          }\n      }\n\n//]]>\n</script>\n"
    end
    it "should render value as text with a read_only parameter" do
      HeightWidget.render_form_object_read_only(1,'2000',{}).should == 
        "<span id=\"record_1\">65' 7\" (2000 cm)</span>"
    end
    it "should convert html values based on the meters box and convert to centimeters value" do
      HeightWidget.convert_html_value({'meters_box'=> '0.0'}).should == 0
      HeightWidget.convert_html_value({'meters_box'=> '0'}).should == 0
      HeightWidget.convert_html_value({'meters_box'=> ''}).should == ''
      HeightWidget.convert_html_value({'meters_box'=> '1.5'}).should == 150.0
      HeightWidget.convert_html_value({'meters_box'=> '.5'}).should == 50.0
      HeightWidget.convert_html_value({'meters_box'=> '1.54'}).should == 154.0
    end
    it "should convert bad html values to nil" do
      HeightWidget.convert_html_value({'meters_box'=> 'x'}).should == nil
      HeightWidget.convert_html_value({'meters_box'=> '0..1'}).should == nil
      HeightWidget.convert_html_value({'meters_box'=> '0x1'}).should == nil
    end
  end
  
  describe WeightWidget do
    it "should render an html input text with a label" do
      WeightWidget.render_form_object(1,'2000',{}).should == 
      "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][pounds_box]\" id=\"record_1_pounds_box\" value=\"4\" onchange=\"record_1_update_weight(true)\" /> lb\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][ounces_box]\" id=\"record_1_ounces_box\" value=\"7\" onchange=\"record_1_update_weight(true)\" /> oz or\n      <input type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][grams_box]\" id=\"record_1_grams_box\" value=\"2000\" onchange=\"record_1_update_weight(false)\" /> g\n      <script type=\"text/javascript\">\n//<![CDATA[\n      function record_1_update_weight(change_grams) {\n          if (change_grams) {\n            var pounds = check_float($F('record_1_pounds_box'));\n            var ounces = check_float($F('record_1_ounces_box'));\n            if ((pounds==null) && (ounces==null)){\n              $('record_1_grams_box').value=''\n            }else{\n              if (pounds==null) { $('record_1_pounds_box').value=''; pounds = 0};\n              if (ounces==null) { $('record_1_ounces_box').value=''; ounces = 0};\n              var grams = (pounds * 16 + ounces) * 28.3495231;\n              $('record_1_grams_box').value = Math.round(grams);\n            }\n          } else {\n            var grams = check_float($F('record_1_grams_box'));\n            if (grams==null){\n              $('record_1_pounds_box').value='';\n              $('record_1_ounces_box').value='';\n            }else{\n              var total_ounces = grams * 0.0352739619;\n              $('record_1_pounds_box').value = Math.floor(total_ounces / 16);\n              $('record_1_ounces_box').value = Math.round(total_ounces % 16);\n            }\n          }\n      }\n\n//]]>\n</script>\n"
    end
    it "should render value as text with a read_only parameter" do
      WeightWidget.render_form_object_read_only(1,'2000',{}).should == 
        "<span id=\"record_1\">2000 grams</span>"
    end
    it "should convert html values based on the grams value" do
      WeightWidget.convert_html_value({'grams_box'=> '2000'}).should == '2000'
    end
    it "should convert bad html values to nil" do
      WeightWidget.convert_html_value({'grams_box'=> 'x'}).should == nil
      WeightWidget.convert_html_value({'grams_box'=> 'x14'}).should == nil
      WeightWidget.convert_html_value({'grams_box'=> '1.5'}).should == nil
      WeightWidget.convert_html_value({'grams_box'=> '14x'}).should == nil
    end
    
  end

  describe WeightLbkgWidget do
    it "should render an html input text with a label" do
      WeightLbkgWidget.render_form_object(1,'1100',{}).should ==
      "      <input type=\"text\" size=2 class=\"textfield_4\" name=\"record[1][pounds_box]\" id=\"record_1_pounds_box\" value=\"2\" onchange=\"record_1_update_weight(true)\" /> lb or\n      <input type=\"text\" size=4 class=\"textfield_5\" name=\"record[1][kilograms_box]\" id=\"record_1_kilograms_box\" value=\"1.1\" onchange=\"record_1_update_weight(false)\" /> kg\n      <script type=\"text/javascript\">\n//<![CDATA[\nfunction record_1_update_weight(change_kilograms) {\n if (change_kilograms) {\n  var pounds = check_float($F('record_1_pounds_box'),null);\n  if (pounds == null) {\n    $('record_1_kilograms_box').value='';\n  } else {\n    $('record_1_kilograms_box').value = Math.round(pounds *  4.5359237)/10;\n   }\n } else {\n  var kilograms = check_float($F('record_1_kilograms_box'),null);\n  if (kilograms == null) {\n    $('record_1_pounds_box').value='';\n  }else {\n    $('record_1_pounds_box').value = Math.round(kilograms * 2.20462262);\n  }\n }\n}\n\n//]]>\n</script>\n"
    end
    it "should convert html values to grams based on the kiogram value" do
      d = {'kilograms_box'=>'1.2'}
      WeightLbkgWidget.convert_html_value(d).should == 1200
      d = {'kilograms_box'=>'-3.2'}
      WeightLbkgWidget.convert_html_value(d,"allow_negatives").should == -3200
      d = {'kilograms_box'=>'0'}
      WeightLbkgWidget.convert_html_value(d).should == 0.0
    end
    it "should convert bad html values to nil" do
      d = {'kilograms_box'=>'-3.2'}
      WeightLbkgWidget.convert_html_value(d).should == nil
      d = {'kilograms_box'=>'x'}
      WeightLbkgWidget.convert_html_value(d).should == nil
      d = {'kilograms_box'=>''}
      WeightLbkgWidget.convert_html_value(d).should == ''
      d = {'kilograms_box'=>'x14'}
      WeightLbkgWidget.convert_html_value(d).should == nil
      d = {'kilograms_box'=>'14x'}
      WeightLbkgWidget.convert_html_value(d).should == nil
    end
  end

end