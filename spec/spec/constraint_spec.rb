require File.dirname(__FILE__) + '/../spec_helper'

describe Constraints do
  describe 'regex' do
    it "should trigger when value is nil" do
      Constraints.verify({'regex' => 'a.c'}, nil, SampleForm).should == ["value does not match regular expression a.c"]
    end
    it "should trigger when value is " do
      Constraints.verify({'regex' =>'a.c'}, 'abc', SampleForm).should == []
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'regex' =>'a.c'}, 'abd', SampleForm).should == ["value does not match regular expression a.c"]
    end
  end
  describe 'required' do
    it "should trigger when value is nil" do
      Constraints.verify({'required' =>true}, nil, SampleForm).should == ["this field is required"]
    end
    it "should trigger when value is ''" do
      Constraints.verify({'required' =>true}, '', SampleForm).should == ["this field is required"]
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'required' =>true}, 'fish', SampleForm).should == []
    end
  end
  describe 'required conditional' do
    before(:each) do
      @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith'})
      SampleForm.prepare_for_build(@record,@form,nil)
    end
    describe '-- using related field and = operator' do
      it "should trigger when related field has stated value" do
        Constraints.verify({'required' =>'name=Bob Smith'}, nil, SampleForm).should == ["this field is required when name is Bob Smith"]
      end
      it "should not trigger when related field has different value from stated value" do
        Constraints.verify({'required' =>'name=Joe Smith'}, nil, SampleForm).should == []
      end
    end
    describe '-- using related field and =~ as regex operator' do
      it "should trigger when related field has stated regex" do
        Constraints.verify({'required' =>'name=~S.*h'}, nil, SampleForm).should == ["this field is required when name matches regex S.*h"]
      end
      it "should not trigger when related field has different value from stated regex" do
        Constraints.verify({'required' =>'name=~^x$'}, nil, SampleForm).should == []
      end
    end
    describe '-- using a Proc' do
      before(:each) do
        @theProc = Proc.new {|value,form| value == 'squidness' ? 'no sqiddyiness' : nil}
      end
      it "should trigger when the given proc returns an error message" do
        Constraints.verify({'required' =>@theProc}, 'squidness', SampleForm).should == ['no sqiddyiness']
      end
      it "should trigger not when the given proc returns no error message" do
        Constraints.verify({'required' =>@theProc}, 'cow', SampleForm).should == []
      end
    end
    describe '-- using a Proc to test against other form values' do
      before(:each) do
        @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
        @record = Record.make('SampleForm','new_entry',{:occupation =>'cowherd'})
        @theProc = Proc.new {|value,form| form.field_value('name') =~ /Smith$/ && form.field_value('occupation') == 'cowherd' ? 'no Smith cowherds when value of the field is boink' : nil}
      end
      it "should trigger when the given proc returns an error message" do
        @record.name = "Bob Smith"
        SampleForm.prepare_for_build(@record,@form,nil)
        Constraints.verify({'required' =>@theProc}, 'boink', SampleForm).should == ['no Smith cowherds when value of the field is boink']
      end
      it "should trigger when the given proc returns an error message" do
        @record.name = "Bob Smith"
        SampleForm.prepare_for_build(@record,@form,nil)
        Constraints.verify({'required' =>@theProc}, 'squidness', SampleForm).should == ['no Smith cowherds when value of the field is boink']
      end
      it "should trigger not when the given proc returns no error message" do
        @record.name = "Bob Jones"
        SampleForm.prepare_for_build(@record,@form,nil)
        Constraints.verify({'required' =>@theProc}, 'cow', SampleForm).should == []
      end
      it "should trigger not when the given proc returns no error message" do
        @record.name = "Bob Jones"
        SampleForm.prepare_for_build(@record,@form,nil)
        Constraints.verify({'required' =>@theProc}, 'voink', SampleForm).should == []
      end
    end
  end
end
