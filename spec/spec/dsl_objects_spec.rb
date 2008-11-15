require File.dirname(__FILE__) + '/../spec_helper'

describe Field do
  it "should require name and type parameters" do
    lambda {Field.new}.should raise_error("Field reqires 'name' to be defined")
    lambda {Field.new(:name=>'bob')}.should raise_error("Field reqires 'type' to be defined")
    lambda {Field.new(:name=>'bob',:type=>'string')}.should_not raise_error
  end
end

describe Workflow do
  before :each do
    @w = Workflow.new(:name=>'standard',:states=>[{'logged' => 'Form Logged'}, {'completed' => 'Form Completed'}, {'verifying'=> {:label => 'Form in validation',:validate => true}}])
  end

  describe "initializaton" do
    it "should initialize both order and states from a list of pairs" do
      @w.states.should == {'logged' => 'Form Logged', 'completed' => 'Form Completed', 'verifying'=> {:label => 'Form in validation',:validate => true}}
      @w.order.should == ['logged', 'completed', 'verifying']
    end
  end

  describe "methods" do
    it "should build an enumeration list from the states data" do
      @w.make_states_enumeration.should == [["logged: Form Logged", "logged"], ["completed: Form Completed", "completed"], ["verifying: Form in validation", "verifying"]]
    end
    it "should report validation for validate states" do
      @w.should_validate?('verifying').should == true
    end
    it "should not report validation for non validate states" do
      @w.should_validate?('completed').should_not == true
      @w.should_validate?('logged').should_not == true
    end
    it "should report label for a simple state" do
      @w.label('completed').should == 'Form Completed'
    end
    it "should report label for a validate state" do
      @w.label('verifying').should == 'Form in validation'
    end
  end

end

describe Question do
  it "should require field and widget parameters" do
    lambda {Question.new}.should raise_error("Question reqires 'field' to be defined")
    lambda {Question.new(:field=>'bob')}.should raise_error("Question reqires 'widget' to be defined")
    lambda {Question.new(:field=>'bob',:widget=>'Date')}.should_not raise_error
  end
end

describe Presentation do
  it "should require name and block parameters" do
    lambda {Presentation.new}.should raise_error("Presentation reqires 'name' to be defined")
    lambda {Presentation.new(:name=>'bob')}.should raise_error("Presentation reqires 'block' to be defined")
    lambda {Presentation.new(:name=>'bob',:block=>lambda{})}.should_not raise_error
  end
end

describe Condition do
  it "should require name" do
    lambda {Condition.new(:form => 'x')}.should raise_error("Condition reqires 'name' to be defined")
    lambda {Condition.new(:form => 'x',:name=>'age=nil')}.should_not raise_error
  end
  describe "initialzing from name" do
    it "should handle regex operator" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '=~'
      c.field_value.should == '/^[0-9]+$/'
    end
    it "should handle whitespace around operator" do
      c = Condition.new(:name=>'age = 10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '='
      c.field_value.should == '10'
    end
    it "should handle field name index" do
      c = Condition.new(:name=>'age[1] = 10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '='
      c.field_value.should == '10'
      c.index.should == 1
    end
    it "should handle field name index *" do
      c = Condition.new(:name=>'age[*] includes 3',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == 'includes'
      c.field_value.should == '3'
      c.index.should == "*"
    end
    it "should handle equals operator" do
      c = Condition.new(:name=>'age=10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '='
      c.field_value.should == '10'
    end
    it "should handle not equals operator" do
      c = Condition.new(:name=>'age!=10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '!='
      c.field_value.should == '10'
    end
    it "should handle greater than or equal operator" do
      c = Condition.new(:name=>'age>=10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '>='
      c.field_value.should == '10'
    end
    it "should handle less than or equal operator" do
      c = Condition.new(:name=>'age<=10',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '<='
      c.field_value.should == '10'
    end
    it "should handle between operator" do
      c = Condition.new(:name=>'age<>10,20',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '<>'
      c.field_value.should == '10,20'
    end
    it "should handle between or equal" do
      c = Condition.new(:name=>'age<>=10,20',:form=>'x').expressions[0]
      c.field_name.should == 'age'
      c.operator.should == '<>='
      c.field_value.should == '10,20'
    end
    it "should handle boolean expressions" do
      c = Condition.new(:name=>'age<10 or age>20',:form=>'x')
      c.expressions[0].field_name.should == 'age'
      c.expressions[0].operator.should == '<'
      c.expressions[0].field_value.should == '10'
      c.expressions[1].field_name.should == 'age'
      c.expressions[1].operator.should == '>'
      c.expressions[1].field_value.should == '20'
      c.booleanjoins[0].should == 'or'
    end
  end
  describe "#humanize" do
    before :each do
      @form = SimpleForm.new
    end
    it "should be able to derive a description from the a name" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>@form).humanize.should == 'age matches regex /^[0-9]+$/'
    end
    it "should be able to derive a description from the field label if provided" do
      Condition.new(:name=>'higher_ed_years=1',:form=>@form).humanize.should == 'years of higher education is 1'
    end
    it "should be able to derive a description for boolean expressions" do
      Condition.new(:name=>'age<10 or age>20',:form=>@form).humanize.should == 'age is less than 10 or age is greater than 20'
    end
    it "should use the description if provided" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>@form,:description=>'age is only digits').humanize.should == 'age is only digits'
    end
  end
  describe "#uses_fields" do
    it "should confirm usage of field for simple conditions" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x')
      c.uses_fields(['age']).should == true
      c.uses_fields(['fish']).should == false
    end
    it "should confirm usage of field for custom conditions" do
      c = Condition.new(:name=>'collies_owned_by_joe',:form=>'x',:javascript => ":dog_type == 'collie' && :owner == 'joe'")
      c.uses_fields(['fish']).should == false
      c.uses_fields(['fish','dog_type']).should == true
      c.uses_fields(['fish','owner']).should == true
    end
    it "should confirm usage of field for boolean conditions" do
       c = Condition.new(:name=>'age<10 or height>20',:form=>'x')
       c.uses_fields(['age']).should == true
       c.uses_fields(['height']).should == true
    end
  end
  describe "#fields_used" do
    it "should return the list of fields used by simple conditions" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x')
      c.fields_used.should == ['age']
    end
    it "should  return lists of fields for boolean conditions" do
      c = Condition.new(:name=>'age<10 or height>20',:form=>SimpleForm.new)
      c.fields_used.should == ['age','height']
    end
    it "should return lists of fields for custom conditions" do
      c = Condition.new(:name=>'collies_owned_by_joe',:form=>'x',:javascript => ":dog_type == 'collie' && :owner == 'joe'")
      c.fields_used.should == ['dog_type','owner']
    end
  end

  describe "javascript" do
    it "should be able to produce a javascript function name" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>SimpleForm.new).js_function_name.should == 'age_matches_regex_0_9'
    end
    it "should be able to produce a javascript function name for boolean conditions" do
      Condition.new(:name=>'age<10 or height>20',:form=>SimpleForm.new).js_function_name.should == 'age_is_less_than_10_or_height_is_greater_than_20'
    end
    it "should use the description for deriving the javascript name if provided" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>SimpleForm.new,:description=>'age is only digits').js_function_name.should == 'age_is_only_digits'
    end
    it "should create javascript for simple conditions with no widget" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>SimpleForm.new)
      c.generate_javascript_function({}).should == "function age_matches_regex_0_9() {return regexMatch(values_for_age[0],'^[0-9]+$')}"
    end
    it "should create javascript for simple conditions with no widget for indexed fields" do
      c = Condition.new(:name=>'house_value>100',:form=>SimpleForm.new)
      c.generate_javascript_function({}).should == "function house_value_is_greater_than_100() {return (values_for_house_value[cur_idx] != null) && (values_for_house_value[cur_idx] != '') && (values_for_house_value[cur_idx] > 100)}"
    end
    it "should create javascript for simple conditions with no widget for fields with a specified indexs of fields marked as indexed" do
      c = Condition.new(:name=>'house_value[0]>100',:form=>SimpleForm.new)
      c.generate_javascript_function({}).should == "function house_value_is_greater_than_100() {return (values_for_house_value[0] != null) && (values_for_house_value[0] != '') && (values_for_house_value[0] > 100)}"
    end
    it "should create javascript for simple conditions with no widget for fields specified index * of fields marked as indexed" do
      c = Condition.new(:name=>'house_value[*] includes 3',:form=>SimpleForm.new)
      c.generate_javascript_function({}).should == "function house_value_includes_3() {return includes(values_for_house_value,\"3\")}"
    end
    it "should create javascript for simple conditions with no widget for fields with a specified indexs of fields not marked as indexed" do
      c = Condition.new(:name=>'age[1]>100',:form=>SimpleForm.new)
      c.generate_javascript_function({}).should == "function age_is_greater_than_100() {return (values_for_age[1] != null) && (values_for_age[1] != '') && (values_for_age[1] > 100)}"
    end
    it "should create javascript for boolean conditions" do
       c = Condition.new(:name=>'age<10 or age>20',:form=>SimpleForm.new)
       c.generate_javascript_function({}).should == "function age_is_less_than_10_or_age_is_greater_than_20() {return (values_for_age[0] != null) && (values_for_age[0] != '') && (values_for_age[0] < 10) || (values_for_age[0] != null) && (values_for_age[0] != '') && (values_for_age[0] > 20)}"
    end
    it "should create javascript for custom conditions with a widget" do
      c = Condition.new(:name=>'collies_owned_by_joe',:form=>SimpleForm.new,:javascript => ":dog_type == 'collie' && :owner == 'joe'")
      c.generate_javascript_function({'dog_type'=>[Widget.fetch('TextField'),{}]}).should == "function collies_owned_by_joe() {return values_for_dog_type[0] == 'collie' && values_for_owner[0] == 'joe'}"
    end
  end
end

describe Tabs do
  before :each do
    @current_tab ='start'
    @tab = Tabs.new(
      :name => 'midwife',
      :block => nil
    )
  end
  it "should render a tab" do
    @tab.render_tab('end','End','/end',false).should == "<li class=\"tab_end\"> <a href=\"#\" onClick=\"return submitAndRedirect('/end')\" title=\"Click here to go to End\"><span>End</span></a></li>"
  end
  it "should render the current tab" do
    @tab.render_tab('start','Start','/start',true).should == "<li class=\"current tab_start\"> <a href=\"#\" onClick=\"return submitAndRedirect('/start')\" title=\"Click here to go to Start\"><span>Start</span></a></li>"
  end
  it "should render the current tab with additional info added to the label via a callback" do
    @tab.render_proc = Proc.new {|presentation_name,index| " fish"}
    @tab.render_tab('start','Start','/start',true).should == "<li class=\"current tab_start\"> <a href=\"#\" onClick=\"return submitAndRedirect('/start')\" title=\"Click here to go to Start\"><span>Start fish</span></a></li>"
  end
end


#describe Constraint do
#  it "should require " do
#    lambda {Condition.new}.should raise_error("Condition reqires 'name' to be defined")
#    lambda {Condition.new(:name=>'age_is_nil')}.should_not raise_error
#  end
#end
