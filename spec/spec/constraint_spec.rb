require File.dirname(__FILE__) + '/../spec_helper'

describe Constraints do
  before(:each) do
    @form = SampleForm.new
  end
  describe 'regex' do
    it "should trigger when value is nil" do
      Constraints.verify({'regex' => 'a.c'}, nil, @form).should == ["value must match regular expression a.c"]
    end
    it "should not trigger when value matches regex " do
      Constraints.verify({'regex' =>'a.c'}, 'abc', @form).should == []
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'regex' =>'a.c'}, 'abd', @form).should == ["value must match regular expression a.c"]
    end
    it "should accept regex objects as the value" do
      Constraints.verify({'regex' =>/a.c/}, 'abc', @form).should == []
    end
  end

  describe 'range' do
    it "should trigger when value is out of range" do
      Constraints.verify({'range' => '1-5'}, '9', @form).should == ["value out of range, must be between 1 and 5"]
    end
    it "should not trigger when value is in range" do
      Constraints.verify({'range' => '1-3'}, '1', @form).should == []
      Constraints.verify({'range' => '1-3'}, '2', @form).should == []
      Constraints.verify({'range' => '1-3'}, '3', @form).should == []
    end
  end

  describe '-- using a Proc' do
    before(:each) do
      @theProc = Proc.new {|value,form| value == 'squidness' ? 'no sqiddyiness' : nil}
    end
    it "should trigger when the given proc returns an error message" do
      Constraints.verify({'proc' =>@theProc}, 'squidness', @form).should == ['no sqiddyiness']
    end
    it "should trigger not when the given proc returns no error message" do
      Constraints.verify({'proc' =>@theProc}, 'cow', @form).should == []
    end
  end
  describe '-- using a Proc to test against other form values' do
    before(:each) do
      @record = Record.make(@form,'new_entry',{:occupation =>'cowherd'})
      @theProc = Proc.new {|value,form| form.field_value('name') =~ /Smith$/ && form.field_value('occupation') == 'cowherd' ? 'no Smith cowherds when value of the field is boink' : nil}
    end
    it "should trigger when the given proc returns an error message" do
      @record.name = "Bob Smith"
      @form.with_record(@record) do
        Constraints.verify({'proc' =>@theProc}, 'boink', @form).should == ['no Smith cowherds when value of the field is boink']
      end
    end
    it "should trigger when the given proc returns an error message" do
      @record.name = "Bob Smith"
      @form.with_record(@record) do
        Constraints.verify({'proc' =>@theProc}, 'squidness', @form).should == ['no Smith cowherds when value of the field is boink']
      end
    end
    it "should trigger not when the given proc returns no error message" do
      @record.name = "Bob Jones"
      @form.with_record(@record) do
        Constraints.verify({'proc' =>@theProc}, 'cow', @form).should == []
      end
    end
    it "should trigger not when the given proc returns no error message" do
      @record.name = "Bob Jones"
      @form.with_record(@record) do
        Constraints.verify({'proc' =>@theProc}, 'voink', @form).should == []
      end
    end
  end

  describe 'required' do
    it "should trigger when value is nil" do
      Constraints.verify({'required' =>true}, nil, @form).should == ["this field is required"]
    end
    it "should trigger when value is ''" do
      Constraints.verify({'required' =>true}, '', @form).should == ["this field is required"]
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'required' =>true}, 'fish', @form).should == []
    end
  end
  describe 'required conditional' do
    before(:each) do
      @record = Record.make(@form,'new_entry',{:name =>'Bob Smith'})
    end
    describe '-- using related field and = operator' do
      it "should trigger when related field has stated value" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=Bob Smith'}, nil, @form).should == ["this field is required when name is Bob Smith"]
        end
      end
      it "should not trigger when related field has different value from stated value" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=Joe Smith'}, nil, @form).should == []
        end
      end
    end
    describe '-- using related field and =~ as regex operator' do
      it "should trigger when related field has stated regex" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=~S.*h'}, nil, @form).should == ["this field is required when name matches regex S.*h"]
        end
      end
      it "should not trigger when related field has different value from stated regex" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=~^x$'}, nil, @form).should == []
        end
      end
    end
  end
end
