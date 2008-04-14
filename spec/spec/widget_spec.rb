require File.dirname(__FILE__) + '/../spec_helper'

describe TextFieldWidget do
  before(:each) do
    @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
  end

  it "should render an html input text with a label" do
    TextFieldWidget.render(@form,1,'value','the label').should == 
      "<label class=\"label\" for=\"record[1]\">the label</label><input id=\"record[1]\" name=\"record[1]\" type=\"text\" value=\"value\" />"
  end
  it "should render an html input text with a label and a size parameter" do
    TextFieldWidget.render(@form,1,'value','the label',{:params=>'3'}).should == 
      "<label class=\"label\" for=\"record[1]\">the label</label><input class=\"textfield_3\" id=\"record[1]\" name=\"record[1]\" size=\"3\" type=\"text\" value=\"value\" />"
  end
  it "should render an html label and the value as text with a read_only parameter" do
    TextFieldWidget.render(@form,1,'value','the label',{:read_only=>true}).should == 
      "<label class=\"label\" for=\"record[1]\">the label</label><span id=\"record[1]\">value</span>"
  end
end