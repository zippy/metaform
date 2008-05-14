require File.dirname(__FILE__) + '/../spec_helper'

describe Widget do
  before(:each) do
    @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
  end
  
  describe 'default methods for all widgets' do
    it "should include a default #render_form_object_read_only" do
      Widget.render_form_object_read_only(@form,1,'value',{}).should == 
        "<span id=\"record_1\">value</span>"
    end
    it "should include #humanize_value" do
      Widget.humanize_value('value').should == 'value'
    end
  end
  
  describe TextFieldWidget do
    it "should render an html input text with a label" do
      TextFieldWidget.render_form_object(@form,1,'value',{}).should == 
        "<input id=\"record_1\" name=\"record[1]\" type=\"text\" value=\"value\" />"
    end
    it "should render an html input text with a size parameter" do
      TextFieldWidget.render_form_object(@form,1,'value',{:params=>'3'}).should == 
        "<input class=\"textfield_3\" id=\"record_1\" name=\"record[1]\" size=\"3\" type=\"text\" value=\"value\" />"
    end
    it "should render value as text with a read_only parameter" do
      TextFieldWidget.render_form_object_read_only(@form,1,'value',{}).should == 
        "<span id=\"record_1\">value</span>"
    end
  end

  describe DateWidget do
    it "should render three html input texts and the instructions" do
      DateWidget.render_form_object(@form,1,"2004-10-23",{}).should == 
        "<input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][month]\" id=\"record_1_month\" value=\"10\" /> /\n<input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][day]\" id=\"record_1_day\" value=\"23\" /> /\n<input type=\"text\" size=4 class=\"textfield_2\" name=\"record[1][year]\" id=\"record_1_year\" value=\"04\" /> <span class=\"instructions\">(MM/DD/YYYY)</span>\n"
    end
    it "should render date value as text with a read_only parameter" do
      DateWidget.render_form_object_read_only(@form,1,"2004-10-23",{}).should == 
        "<span id=\"record_1\">10/23/2004</span>"
    end
  end
  
  describe TimeWidget do
    it "should render two html input texts plus a select for am/pm" do
      TimeWidget.render_form_object(@form,1,"3:22",{}).should == 
        "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][hours &]\" id=\"record_1_hours\" value=\"3\" />:\n      <input type=\"text\" class=\"left_margin_neg_5 textfield_2\" size=2 name=\"record[1][minutes]\" id=\"record_1_minutes\" value=\"22\" />\n      <select name=\"record[1][am_pm]\" id=\"record_1_am_pm\">\n      \t<option value=\"am\" selected=\"selected\">AM</option>\n<option value=\"pm\">PM</option>\n\t  </select>\n"
    end
    it "should render time value as text with a read_only parameter" do
      TimeWidget.render_form_object_read_only(@form,1,"3:22",{}).should == 
        "<span id=\"record_1\">3:22 am</span>"
    end
    it "should render low min time values with a preceeding 0 text if read_only" do
      TimeWidget.render_form_object_read_only(@form,1,"13:02",{}).should == 
        "<span id=\"record_1\">1:02 pm</span>"
    end
  end

  describe TimeIntervalWidget do
    it "should render two html input texts plus a select for am/pm" do
      TimeIntervalWidget.render_form_object(@form,1,"500",{}).should == 
        "      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][hours]\" id=\"record_1_hours\" value=\"8\" /> hours\n      <input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][minutes]\" id=\"record_1_minutes\" value=\"20\" /> minutes\n"
    end
    it "should render interval value as text if read_only" do
      TimeIntervalWidget.render_form_object_read_only(@form,1,"500",{}).should == 
        "<span id=\"record_1\">8 hours, 20 minutes</span>"
    end
  end
  
  describe FactorTextFieldsWidget do
    it "should render two html input texts and lables from params" do
      FactorTextFieldsWidget.render_form_object(@form,1,"500",{:params=>"5,FirstLabel,SecondLabel"}).should == 
        "<input type=\"text\" size=2 name=\"record[1][first_box]\" id=\"record_1_first_box\" value=\"100\" /> FirstLabel\n<input type=\"text\" size=2 name=\"record[1][second_box]\" id=\"record_1_second_box\" value=\"0\" /> SecondLabel\n<input type=\"hidden\" name=\"record[1][factor]\"  id=\"record_1_factor\"/ value=\"5\">"
    end
    it "should render factor value as text if read_only" do
      FactorTextFieldsWidget.render_form_object_read_only(@form,1,"500",{:params=>"5,FirstLabel,SecondLabel"}).should == 
        "<span id=\"record_1\">100 FirstLabel 0 SecondLabel</span>"
    end
  end

  describe MonthYearWidget do
    it "should render two html input texts" do
      MonthYearWidget.render_form_object(@form,1,"2004-10-23",{}).should == 
        "<input type=\"text\" size=2 class=\"textfield_2\" name=\"record[1][month]\" id=\"record_1_month\" value=\"10\" /> /\n<input type=\"text\" size=4 class=\"textfield_4\" name=\"record[1][year]\" id=\"record_1_year\" value=\"2004\" /> (month/year)\n"
    end
    it "should render date value as text with a read_only parameter" do
      MonthYearWidget.render_form_object_read_only(@form,1,"2004-10-23",{}).should == 
        "<span id=\"record_1\">10/2004</span>"
    end
  end

  describe CheckBoxWidget do
    it "should render an html checkbox " do
      CheckBoxWidget.render_form_object(@form,1,"Y",{}).should == 
        ["<input name=\"record[1][Y]\" id=\"record_1_y\" type=\"checkbox\" checked>", "\n", "<input name=\"record[1][__none__]\" id=\"record_1___none__\" class=\"1\" type=\"hidden\"}>"]
    end
    it "should render 'Y' checked and read_only" do
      CheckBoxWidget.render_form_object_read_only(@form,1,"Y",{}).should == 
        "<span id=\"record_1\">Y</span>"
    end
  end

  describe CheckBoxGroupWidget do
    before(:each) do
      @options = {:constraints => {'set'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
    end
     
    it "should render html checkboxes with a custom label" do
      CheckBoxGroupWidget.render(@form,1,"val1",'the label',@options).should == 
      "<span class=\"label\">the label</span><input name=\"record[1][val1]\" id=\"record_1_val1\" class=\"1\" type=\"checkbox\" value=\"val1\" checked onClick=\"\"> Value 1\n<input name=\"record[1][val2]\" id=\"record_1_val2\" class=\"1\" type=\"checkbox\" value=\"val2\" onClick=\"\"> Value 2\n<input name=\"record[1][val3]\" id=\"record_1_val3\" class=\"1\" type=\"checkbox\" value=\"val3\" onClick=\"\"> Value 3<input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\"}>"
    end
    it "should render the list of human enumerations values if read_only" do
      CheckBoxGroupWidget.render_form_object_read_only(@form,1,"val1,val3",@options).should == 
        "<span id=\"record_1\">Value 1, Value 3</span>"
    end
    it "should render the list of human enumerations values if read_only and one field is a *-indicated none field" do
      @options = {:constraints => {'set'=>[{'val1*'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
       CheckBoxGroupWidget.render_form_object_read_only(@form,1,"val1,val3",@options).should == 
         "<span id=\"record_1\">Value 1, Value 3</span>"
     end
  end
  
  describe CheckBoxGroupFollowupWidget do
    before(:each) do
      @options = {:constraints => {'set'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'}]}, :params => "param_label,param1,param2"}
    end
     
    it "should render html checkboxes with a custom label" do
      CheckBoxGroupFollowupWidget.render(@form,1,"val1",'the label',@options).should == 
      "<span class=\"label\">the label</span><br />      <input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\"}>\n      <span class=\"check_box_followup_input\"><input name=\"record[1][val1]\" id=\"record_1_val1\" class=\"1\" type=\"checkbox\" value=\"val1\" checked\n        onClick=\"do_click_1_regular(this,'val1','1_val1')\">\n        Value 1</span>\n                  <span id=\"1_val1\" class=\"checkbox_followups\" style=\"display:inline\">\n          &nbsp;&nbsp; param_label           <input name=\"record[1][_val1-param1]\" id=\"record_1__val1param1\" class=\"1_val1_followup\" type=\"checkbox\" value=\"param1\"  > Param1\n\n          <input name=\"record[1][_val1-param2]\" id=\"record_1__val1param2\" class=\"1_val1_followup\" type=\"checkbox\" value=\"param2\"  > Param2\n\n          </span>\n\n<br />      <input name=\"record[1][__none__]\" id=\"record_1___none__\" type=\"hidden\"}>\n      <span class=\"check_box_followup_input\"><input name=\"record[1][val2]\" id=\"record_1_val2\" class=\"1\" type=\"checkbox\" value=\"val2\" \n        onClick=\"do_click_1_regular(this,'val2','1_val2')\">\n        Value 2</span>\n                  <span id=\"1_val2\" class=\"checkbox_followups\" style=\"display:none\">\n          &nbsp;&nbsp; param_label           <input name=\"record[1][_val2-param1]\" id=\"record_1__val2param1\" class=\"1_val2_followup\" type=\"checkbox\" value=\"param1\"  > Param1\n\n          <input name=\"record[1][_val2-param2]\" id=\"record_1__val2param2\" class=\"1_val2_followup\" type=\"checkbox\" value=\"param2\"  > Param2\n\n          </span>\n\n<div class=\"clear\"></div><script type=\"text/javascript\">\n//<![CDATA[\n    \t\tfunction do_click_1_regular(theCheckbox,theValue,theFollowupID) {\n          var e = $(theFollowupID); \n          if (theCheckbox.checked) {\n            Effect.BlindDown(e, {duration:.5});\n            \n          } else {\n            Effect.BlindUp(e, {duration:.5});\n            $$('.1_'+theValue+'_followup').each(function(cb){cb.checked=false});\n          }           \n   \t\t  }        \n\n//]]>\n</script>" 
    end
    it "should render the list of human enumerations values if read_only, including followups" do
      CheckBoxGroupFollowupWidget.render_form_object_read_only(@form,1,"val1: \n- param2\nval2: \n- param1\n- param2\n",@options).should == 
        "<span id=\"record_1\">Value 1:  Param2\\nValue 2:  Param1, Param2</span>"
    end
  end

  describe RadioButtonsWidget do
    before(:each) do
      @options = {:constraints => {'enumeration'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
    end
     
    it "should render html checkboxes with a custom label" do
      RadioButtonsWidget.render(@form,1,"val1",'the label',@options).should == 
        "<span class=\"label\">the label</span><input name=\"record[1]\" id=\"record_1_val1\" class=\"1\" type=\"radio\" value=\"val1\" checked> Value 1\n<input name=\"record[1]\" id=\"record_1_val2\" class=\"1\" type=\"radio\" value=\"val2\" > Value 2\n<input name=\"record[1]\" id=\"record_1_val3\" class=\"1\" type=\"radio\" value=\"val3\" > Value 3"
    end
    it "should render the human enumerations value if read_only" do
      RadioButtonsWidget.render_form_object_read_only(@form,1,"val2",@options).should == 
        "<span id=\"record_1\">Value 2</span>"
    end
  end

  describe PopUpWidget do
    before(:each) do
      @options = {:constraints => {'enumeration'=>[{'val1'=>'Value 1'},{'val2'=>'Value 2'},{'val3'=>'Value 3'}]}}
    end

    it "should render html select" do
      PopUpWidget.render_form_object(@form,1,"val1",@options).should == 
        "<select name=\"record[1]\" id=\"record_1\">\n\t<option value=\"val1\" selected=\"selected\">Value 1</option>\n<option value=\"val2\">Value 2</option>\n<option value=\"val3\">Value 3</option>\n</select>\n"
    end
    it "should render html select with nil option if specified as the param" do
      @options[:params] = "Please choose a value"
      PopUpWidget.render_form_object(@form,1,"val1",@options).should ==
        "<select name=\"record[1]\" id=\"record_1\">\n\t<option value=\"\">Please choose a value</option>\n<option value=\"val1\" selected=\"selected\">Value 1</option>\n<option value=\"val2\">Value 2</option>\n<option value=\"val3\">Value 3</option>\n</select>\n"
    end
    it "should render the human enumerations value if read_only" do
      PopUpWidget.render_form_object_read_only(@form,1,"val2",@options).should == 
        "<span id=\"record_1\">Value 2</span>"
    end
  end

  describe WeightWidget do
    it "should render an html input text with a label" do
      TextFieldWidget.render_form_object(@form,1,'2000',{}).should == 
        "<input id=\"record_1\" name=\"record[1]\" type=\"text\" value=\"2000\" />"
    end
    it "should render value as text with a read_only parameter" do
      WeightWidget.render_form_object_read_only(@form,1,'2000',{}).should == 
        "<span id=\"record_1\">2000 grams</span>"
    end
  end
end