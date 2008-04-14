require File.dirname(__FILE__) + '/../spec_helper'

describe Form do
  describe "(using SampleForm as 'schema')" do
    it "should have 10 fields" do
      SampleForm.fields.size.should == 10
    end
  end
  describe "(Form#q-- defining questions)" do
    before(:each) do
      @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith'})
      SampleForm.prepare_for_build(@record,@form,nil)
    end
    it "should add question html to the body" do
      SampleForm.q 'name', 'TextField'
      SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
    end
    it "should add question html to the body in read-only mode" do
      SampleForm.q 'name', 'TextField',nil,nil,:read_only => true
      SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name</label><span id=\"record[name]\">Bob Smith</span></div>"]
    end
    it "should Form#qro as as short hand for read-only" do
      SampleForm.qro 'name', 'TextField'
      SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name</label><span id=\"record[name]\">Bob Smith</span></div>"]
    end
  end
end