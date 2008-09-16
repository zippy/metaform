require File.dirname(__FILE__) + '/../spec_helper'

describe Constraints do
  before(:each) do
    @form = SampleForm.new
  end
  describe 'regex' do
    it "should trigger when value is nil" do
      Constraints.verify({'regex' => 'a.c'}, nil, @form).should == ["Answer must match regular expression a.c"]
    end
    it "should not trigger when value matches regex " do
      Constraints.verify({'regex' =>'a.c'}, 'abc', @form).should == []
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'regex' =>'a.c'}, 'abd', @form).should == ["Answer must match regular expression a.c"]
    end
    it "should accept regex objects as the value" do
      Constraints.verify({'regex' =>/a.c/}, 'abc', @form).should == []
    end
  end

  describe 'range' do
    it "should not trigger when value is nil" do
      Constraints.verify({'range' => '1-5'}, nil, @form).should == []
    end
    it "should not trigger when value is empty string" do
      Constraints.verify({'range' => '1-5'}, '', @form).should == []
    end
    it "should trigger when value is out of range" do
      Constraints.verify({'range' => '1-5'}, '9', @form).should == ["Answer must be between 1 and 5"]
    end
    it "should not trigger when value is in range" do
      Constraints.verify({'range' => '1-3'}, '1', @form).should == []
      Constraints.verify({'range' => '1-3'}, '2', @form).should == []
      Constraints.verify({'range' => '1-3'}, '3', @form).should == []
    end
  end

  describe 'date' do
    it "should not trigger when date is nil" do
      Constraints.verify({'date' => :in_past}, nil, @form).should == []
    end
    it ":in_past should trigger when date is in the future" do
      Constraints.verify({'date' => :in_past}, (Time.now+100).to_s, @form).should == ["Date cannot be in the future."]
    end
    it ":in_past should trigger when date is in the past" do
      Constraints.verify({'date' => :in_past}, (Time.now-100).to_s, @form).should == []
    end
    it ":in_future should trigger when date is in the future" do
      Constraints.verify({'date' => :in_future}, (Time.now-100).to_s, @form).should == ["Date cannot be in the past."]
    end
    it ":in_future should trigger when date is in the past" do
      Constraints.verify({'date' => :in_future}, (Time.now+100).to_s, @form).should == []
    end
  end

  describe 'max_length' do
    it "should trigger when value has more characters than the given length" do
      Constraints.verify({'max_length' => 2}, 'abc', @form).should == ["Answer must not be more than 2 characters long"]
    end
    it "should not trigger when value has fewer characters than the given length" do
      Constraints.verify({'max_length' => 2}, 'ab', @form).should == []
      Constraints.verify({'max_length' => 2}, 'a', @form).should == []
    end
  end

  describe 'unique' do
    before(:each) do
      @record = Record.make(@form,'new_entry',{:name =>'Herbert Smith'})
      @record.save('new_entry')
      @record = Record.make(@form,'new_entry',{:name =>'Bob Smith'})
      @record.save('new_entry')
    end
    it "should trigger when a field value is not unique" do
      @form.with_record(@record) do
        Constraints.verify({'unique' => 'name'}, 'Herbert Smith', @form).should == ['Answer must be unique']
      end
    end
    it "should not trigger when a field value not unique but is the value of the current record" do
      @form.with_record(@record) do
        Constraints.verify({'unique' => 'name'}, 'Bob Smith', @form).should == []
      end
    end
    it "should not trigger when a field value is unique" do
      @form.with_record(@record) do
        Constraints.verify({'unique' => 'name'}, 'Fred', @form).should == []
      end
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
      Constraints.verify({'required' =>true}, nil, @form).should == ["This field is required"]
    end
    it "should trigger when value is ''" do
      Constraints.verify({'required' =>true}, '', @form).should == ["This field is required"]
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
          Constraints.verify({'required' =>'name=Bob Smith'}, nil, @form).should == ["This field is required when Name is Bob Smith"]
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
          Constraints.verify({'required' =>'name=~S.*h'}, nil, @form).should == ["This field is required when Name matches regex S.*h"]
        end
      end
      it "should not trigger when related field has different value from stated regex" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=~^x$'}, nil, @form).should == []
        end
      end
    end
  end
  describe 'set' do
    it "should trigger when value is not in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'kiwi,apple', @form).should == ["Answer must be one of Apple, Banana"]
    end

    it "should not trigger when value is not in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'banana', @form).should == []
    end

    it "should trigger when value YAML encoded and is not in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, {'banana'=>:stuff,'kiwi'=>:more_stuff}.to_yaml, @form).should == ["Answer must be one of Apple, Banana"]
    end

    it "should not trigger when value YAML encoded and is in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, {'banana'=>:stuff,'apple'=>:more_stuff}.to_yaml, @form).should == []
    end
  end
end
