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
    @w = Workflow.new(:name=>'standard',:states=>{'logged' => 'Form Logged','completed'=> 'Form Completed','verifying'=>{:label => 'Form in verification',:verify => true}})
  end
    
  it "should build an enumeration list from the states data" do
    @w.make_states_enumeration.should == [["completed: Form Completed", "completed"], ["logged: Form Logged", "logged"], ["verifying: Form in verification", "verifying"]]
  end
  it "should report verification for verify states" do
    @w.should_verify?('verifying').should == true
  end
  it "should not report verification for non verify states" do
    @w.should_verify?('completed').should_not == true
    @w.should_verify?('logged').should_not == true
  end
  it "should report label for a simple state" do
    @w.label('completed').should == 'Form Completed'
  end
  it "should report label for a verify state" do
    @w.label('verifying').should == 'Form in verification'
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
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '=~'   
      c.field_value.should == '/^[0-9]+$/'
    end
    it "should handle whitespace around operator" do
      c = Condition.new(:name=>'age = 10',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '='   
      c.field_value.should == '10'
    end
    it "should handle equals operator" do
      c = Condition.new(:name=>'age=10',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '='   
      c.field_value.should == '10'
      c = Condition.new(:name=>'age==10',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '=='
      c.field_value.should == '10'
    end
    it "should handle not equals operator" do
      c = Condition.new(:name=>'age!=10',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '!='   
      c.field_value.should == '10'
      c = Condition.new(:name=>'age=!10',:form=>'x')
      c.field_name.should == 'age'   
      c.operator.should == '=!'   
      c.field_value.should == '10'
    end
  end
  describe "#humanize" do
    it "should be able to derive a description from the a name" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x').humanize.should == 'age matches regex /^[0-9]+$/'    
    end
    it "should use the description if provided" do
      Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x',:description=>'age is only digits').humanize.should == 'age is only digits'
    end
  end
  it "should be able to produce a javascript function name" do
    Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x').js_function_name.should == 'age_matches_regex_0_9'    
  end
  it "should use the description for deriving the javascript name if provided" do
    Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x',:description=>'age is only digits').js_function_name.should == 'age_is_only_digits'
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
  end
  describe "#fields_used" do
    it "should return the list of fields used by simple conditions" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x')
      c.fields_used.should == ['age']
    end
    it "should return lists of fields for custom conditions" do
      c = Condition.new(:name=>'collies_owned_by_joe',:form=>'x',:javascript => ":dog_type == 'collie' && :owner == 'joe'")
      c.fields_used.should == ['dog_type','owner']
    end
  end
      
  describe "#generate_javascript_function" do
    it "should javascript for simple conditions with no widget" do
      c = Condition.new(:name=>'age=~/^[0-9]+$/',:form=>'x')
      c.generate_javascript_function({}).should == ["function value_age() {return $F('___age')};function age_matches_regex_0_9() {return value_age().match('^[0-9]+$')}", ["age"]]
    end
    it "should javascript for custom conditions with a widget" do
      c = Condition.new(:name=>'collies_owned_by_joe',:form=>'x',:javascript => ":dog_type == 'collie' && :owner == 'joe'")
      c.generate_javascript_function({'dog_type'=>[Widget.fetch('TextField'),{}]}).should == ["function value_dog_type() {return $F('record_dog_type')};function value_owner() {return $F('___owner')};function collies_owned_by_joe() {return value_dog_type() == 'collie' && value_owner() == 'joe'}", ["owner"]] 
    end
  end
end

#describe Constraint do
#  it "should require " do
#    lambda {Condition.new}.should raise_error("Condition reqires 'name' to be defined")
#    lambda {Condition.new(:name=>'age_is_nil')}.should_not raise_error
#  end
#end