require File.dirname(__FILE__) + '/../spec_helper'
include Utilities
describe Constraints do
  before(:each) do
    $metaform_error_messages = Constraints::DefaultErrorMessages.clone
    Form.configuration[:hide_required_extra_errors] = false
    @form = SampleForm.new
  end
  describe 'regex' do
    it "should not trigger when value is nil" do
      Constraints.verify({'regex' => 'a.c'}, nil, @form).should == []
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

  describe 'integer' do
    it "should trigger if value isn't an integer" do
      Constraints.verify({'integer' => true}, 'x', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => true}, '-0', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => true}, '10.0', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => true}, '10xx0', @form).should == ["Answer must be an integer"]
    end
    it "should not trigger if value an integer" do
      Constraints.verify({'integer' => true}, '1', @form).should == []
      Constraints.verify({'integer' => true}, '-1', @form).should == []
      Constraints.verify({'integer' => true}, '-1,000', @form).should == []
      Constraints.verify({'integer' => true}, '1,000', @form).should == []
    end
    it "should for negative values is limitd to postitive integers" do
      Constraints.verify({'integer' => 'positive'}, '-1', @form).should == ["Answer must be a positive integer"]
      Constraints.verify({'integer' => 'positive'}, '-100', @form).should == ["Answer must be a positive integer"]
    end
    it "should trigger if value isn't an integer when value is limmited to positive integer" do
      Constraints.verify({'integer' => 'positive'}, 'x', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => 'positive'}, '-0', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => 'positive'}, '10.0', @form).should == ["Answer must be an integer"]
      Constraints.verify({'integer' => 'positive'}, '10xx0', @form).should == ["Answer must be an integer"]
    end
  end

  describe 'numeric' do
    it "should trigger if value isn't a number" do
      Constraints.verify({'numeric' => true}, 'x', @form).should == ["Answer must be numeric"]
      Constraints.verify({'numeric' => true}, '10..0', @form).should == ["Answer must be numeric"]
      Constraints.verify({'numeric' => true}, '10xx0', @form).should == ["Answer must be numeric"]
      Constraints.verify({'numeric' => true}, 'x1', @form).should == ["Answer must be numeric"]
      Constraints.verify({'numeric' => true}, '1x', @form).should == ["Answer must be numeric"]
    end
    it "should not trigger if value an integer" do
      Constraints.verify({'numeric' => true}, '1', @form).should == []
      Constraints.verify({'numeric' => true}, '10.234', @form).should == []
      Constraints.verify({'numeric' => true}, '-10.234', @form).should == []
      Constraints.verify({'numeric' => true}, '-1', @form).should == []
      Constraints.verify({'numeric' => true}, '-1,000', @form).should == []
      Constraints.verify({'numeric' => true}, '1,000', @form).should == []
    end
  end

  describe 'range' do
    it "should raise an error if a range can't be extracted" do
      lambda{Constraints.verify({'range' => '5-1'}, 1, @form)}.should raise_error("range constraint 5-1 is ilegal. Must be of form X:Y where X<Y")
      lambda{Constraints.verify({'range' => '0-5'}, 1, @form)}.should raise_error("range constraint 0-5 is ilegal. Must be of form X:Y where X<Y")
      lambda{Constraints.verify({'range' => '5'}, 1, @form)}.should raise_error("range constraint 5 is ilegal. Must be of form X:Y where X<Y")
    end
    it "should raise an error if a range is illegal" do
      lambda{Constraints.verify({'range' => '5:1'}, 1, @form)}.should raise_error("range constraint 5:1 is ilegal. Must be of form X:Y where X<Y")
    end
    it "should not trigger when value is nil" do
      Constraints.verify({'range' => '1:5'}, nil, @form).should == []
    end
    it "should not trigger when value is empty string" do
      Constraints.verify({'range' => '1:5'}, '', @form).should == []
    end
    it "should trigger if value isn't an integer" do
      Constraints.verify({'range' => '1:5'}, "X", @form).should == ["Answer must be numeric"]
      Constraints.verify({'range' => '1:5'}, "1X", @form).should == ["Answer must be numeric"]
      Constraints.verify({'range' => '1:5'}, "1..0", @form).should == ["Answer must be numeric"]
    end
    it "should trigger when value is out of range" do
      Constraints.verify({'range' => '1:5'}, '9', @form).should == ["Answer must be between 1 and 5"]
    end
    it "should not trigger when value is not out of range and negative" do
      Constraints.verify({'range' => '-5:5'}, '0', @form).should == []
    end
    it "should trigger when value is out of range and negative" do
      Constraints.verify({'range' => '-5:5'}, '-6', @form).should == ["Answer must be between -5 and 5"]
    end
    it "should not trigger when value is in range" do
      Constraints.verify({'range' => '1:3'}, '1', @form).should == []
      Constraints.verify({'range' => '1:3'}, '2', @form).should == []
      Constraints.verify({'range' => '1:3'}, '3', @form).should == []
    end
  end

  describe 'date' do
    before(:each) do
      @today = Date.today
    end
    it "should not trigger when date is nil" do
      Constraints.verify({'date' => :in_past}, nil, @form).should == []
    end
    it ":in_past should complain when date is in the future" do
      Constraints.verify({'date' => :in_past}, (@today+1.day).to_s, @form).should == ["Date cannot be in the future"]
    end
    it ":in_past should not trigger when date is today" do
      Constraints.verify({'date' => :in_past}, (@today).to_s, @form).should == []
    end
    it ":in_past should trigger when date is in the past" do
      Constraints.verify({'date' => :in_past}, (@today-1.day).to_s, @form).should == []
    end
    it ":in_future should trigger when date is in the future" do
      Constraints.verify({'date' => :in_future}, (@today-1.day).to_s, @form).should == ["Date cannot be in the past"]
    end
    it ":in_future should trigger when date is in the past" do
      Constraints.verify({'date' => :in_future}, (@today+1.day).to_s, @form).should == []
    end
    it ":in_future should trigger when date is today" do
      Constraints.verify({'date' => :in_future}, (@today).to_s, @form).should == ["Date cannot be in the past"]
    end
    it "should check date ranges" do
      Constraints.verify({'date_range' => ">=1950-01-01"}, "1900-02-01", @form).should == ["Date must be on or after 01/01/1950"]
      Constraints.verify({'date_range' => ">1950-01-01"}, "1900-02-01", @form).should == ["Date must be after 01/01/1950"]
      Constraints.verify({'date_range' => ">1950-01-01"}, "1960-02-01", @form).should == []
      Constraints.verify({'date_range' => "<=1950-01-01"}, "1970-02-01", @form).should == ["Date must be on or before 01/01/1950"]
      Constraints.verify({'date_range' => "<1950-01-01"}, "1975-02-01", @form).should == ["Date must be before 01/01/1950"]
      Constraints.verify({'date_range' => "<1950-01-01"}, "1920-02-01", @form).should == []
      Constraints.verify({'date_range' => "1950-02-01:2001-02-01"}, "1920-01-01", @form).should == ["Date must be between 02/01/1950 and 02/01/2001"]
      Constraints.verify({'date_range' => "1950-02-01:2000-02-01"}, "1999-01-01", @form).should == []
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
      Constraints.verify({'required' =>true}, nil, @form).should == [Constraints::RequiredErrMessage]
    end
    it "should trigger when value is ''" do
      Constraints.verify({'required' =>true}, '', @form).should == [Constraints::RequiredErrMessage]
    end
    it "should give a different error message if also constrianed as set" do
      Constraints.verify({'required' =>true,'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, '', @form).should == [Constraints::RequiredMultiErrMessage]
    end
    it "should not trigger when value is not nil or ''" do
      Constraints.verify({'required' =>true}, 'fish', @form).should == []
    end
    it "should join conditions in an array with 'and'" do
      @record = Record.make(@form,'new_entry',{:name =>'Bob'})
      @form.with_record(@record) do
        Constraints.verify({'required' =>["name=Bob","name=Sue"]}, '', @form).should == []
        Constraints.verify({'required' =>["name=Bob","name=~B"]}, '', @form).should == ["#{Constraints::RequiredErrMessage} when Name is Bob and Name matches regex B"]
      end
    end
  end
  describe 'required conditional' do
    before(:each) do
      @record = Record.make(@form,'new_entry',{:name =>'Bob Smith'})
    end
    describe '-- using related field and = operator' do
      it "should trigger when related field has stated value" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=Bob Smith'}, nil, @form).should == ["#{Constraints::RequiredErrMessage} when Name is Bob Smith"]
        end
      end
      it "should not show the when part of the error message if options switched off" do
        @form.with_record(@record) do
          Form.configuration[:hide_required_extra_errors] = true
          Constraints.verify({'required' =>'name=Bob Smith'}, nil, @form).should == ["#{Constraints::RequiredErrMessage}"]
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
          Constraints.verify({'required' =>'name=~S.*h'}, nil, @form).should == ["#{Constraints::RequiredErrMessage} when Name matches regex S.*h"]
        end
      end
      it "should not trigger when related field has different value from stated regex" do
        @form.with_record(@record) do
          Constraints.verify({'required' =>'name=~^x$'}, nil, @form).should == []
        end
      end
    end
  end
  describe 'enumeration' do
    describe 'specified with a hash' do
      before(:each) do
        @enum = {'enumeration' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}
      end
      it "should trigger when value is not in enum list" do
        Constraints.verify(@enum, 'kiwi', @form).should == ["Answer must be one of Apple, Banana"]
      end
      it "should not trigger when value is in enum list" do
        Constraints.verify(@enum, 'banana', @form).should == []
      end
    end
    describe 'specified with a simple array' do
      before(:each) do
        @enum = {'enumeration' => %w(apple banana)}
      end
      it "should trigger when value is not in enum list" do
        Constraints.verify(@enum, 'kiwi', @form).should == ["Answer must be one of apple, banana, , "]
      end
      it "should not trigger when value is in enum list" do
        Constraints.verify(@enum, 'banana', @form).should == []
      end
    end
    describe 'specified with a rails style select array' do
      before(:each) do
        @enum = {'enumeration' => [['Apple','apple'],['Banana', 'banana']]}
      end
      it "should trigger when value is not in enum list" do
        Constraints.verify(@enum, 'kiwi', @form).should == ["Answer must be one of Apple, Banana"]
      end
      it "should not trigger when value is in enum list" do
        Constraints.verify(@enum, 'banana', @form).should == []
      end
    end
  end
  describe 'set' do
    it "should trigger when value is not in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'kiwi,apple', @form).should == ["Answer must be one of Apple, Banana"]
    end
    it "should trigger when more than one value and one is the 'none' starred value" do
      Constraints.verify({'set' => [{'no_fruit*' => 'None'},{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'no_fruit,apple', @form).should == ["Answer cannot include None and other items"]
      Constraints.verify({'set' => [{'none' => 'None'},{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'none,apple', @form).should == ["Answer cannot include None and other items"]
    end

    it "should not trigger when value is in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, 'banana', @form).should == []
    end

    it "should trigger when value YAML encoded and is not in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, {'banana'=>:stuff,'kiwi'=>:more_stuff}.to_yaml, @form).should == ["Answer must be one of Apple, Banana"]
    end

    it "should not trigger when value YAML encoded and is in set" do
      Constraints.verify({'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, {'banana'=>:stuff,'apple'=>:more_stuff}.to_yaml, @form).should == []
    end
  end
  describe 'overriding error messages' do
    it 'should use a simple replacement string' do
      $metaform_error_messages['range'] = "Please double-check this value"
      Constraints.verify({'range' => '1:5'}, "X", @form).should == ["Please double-check this value"]
    end
    it 'should be able to override the multi-required error message' do
      $metaform_error_messages['_required_multi'] = "No way dude!"
      Constraints.verify({'required' =>true,'set' => [{'apple' => 'Apple'},{'banana' => 'Banana'}]}, '', @form).should == ["No way dude!"]
    end
  end
end
