require File.dirname(__FILE__) + '/../spec_helper'

describe Form do
  
  describe "(using SampleForm as 'schema')" do
    it "should have 11 fields" do
      SampleForm.fields.size.should == 11
    end
  end
  
  describe "-- dsl: " do
    before(:each) do
      @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith'})
      SampleForm.prepare_for_build(@record,@form,nil)
    end
    
    describe "labeling" do
      it "should set the default label" do
        SampleForm.label_options[:postfix].should == ":"
      end
      it "should render labels with the default postfix" do
        SampleForm.q 'name', 'TextField'
        SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
      end
      it "should render questions that override the postfix" do
        SampleForm.q 'name', 'TextField',nil,nil,:labeling => {:postfix => '!'}
        SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name!</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
      end
    end
    
    describe "f (define a field)" do
      it "should add a field to the list of fields" do
        SampleForm.fields['new_field'].should == nil
        SampleForm.f 'new_field','New field label'
        SampleForm.fields['new_field'].should_not == nil
      end
    end
    
    describe "q (display a question)" do
      it "should raise an exception for an undefined field" do
        lambda {SampleForm.q 'froboz', 'TextField'}.should raise_error(MetaformException)
      end
      it "should add question html to the body" do
        SampleForm.q 'name', 'TextField'
        SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
      end
      it "should add multiple questions html to the body" do
        SampleForm.q 'name', 'TextField'
        SampleForm.q 'due_date', 'Date'
        SampleForm.get_body.should == [
          "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>",
          "<div id=\"question_due_date\" class=\"question\"><label class=\"label\" for=\"record[due_date]\">Due Date:</label><input type=\"text\" size=2 class=\"textfield_2\" name=\"record[due_date][month]\" id=\"record_due_date_month\"/> /\n<input type=\"text\" size=2 class=\"textfield_2\" name=\"record[due_date][day]\" id=\"record_due_date_day\"  /> /\n<input type=\"text\" size=4 class=\"textfield_2\" name=\"record[due_date][year]\" id=\"record_due_date_year\"  /> <span class=\"instructions\">(MM/DD/YYYY)</span>\n</div>"
          ]
      end
      it "should add question html to the body in read-only mode" do
        SampleForm.q 'name', 'TextField',nil,nil,:read_only => true
        SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record[name]\">Bob Smith</span></div>"]
      end

      describe "-- with verification" do
        it "should add the verification html if q specifies the :force_verify option" do
          @record.name = ''
          SampleForm.q 'name', 'TextField',nil,nil,:force_verify => true
          SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"\" /><span class=\"errors\">this field is required</span></div>"]
        end
        it "should not add the verification html if q specifies the :force_verify option but the value of the field is ok" do
          SampleForm.q 'name', 'TextField',nil,nil,:force_verify => true
          SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
        end
        it "should add the verification html if record is in a workflow that requires validation" do
          @record.name = ''
          @record.workflow_state= 'verifying'
          SampleForm.prepare_for_build(@record,@form,nil)
          SampleForm.q 'name', 'TextField'
          SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"\" /><span class=\"errors\">this field is required</span></div>"]
        end
      end
    end
    describe "qro (display a question read only)" do
      it "should be a short-hand for adding the :read_only option to a q" do
        SampleForm.qro 'name', 'TextField'
        SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record[name]\">Bob Smith</span></div>"]
      end
    end
    describe "p (display a presentation)" do
      it "should add presentation html to the body" do
        SampleForm.p 'simple'
        SampleForm.get_body.should == ["<div id=\"presentation_simple\" class=\"presentation\">", "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>", "</div>"]
      end      
    end
    
    describe "p (display an indexed presentation)" do
      def do_p
        SampleForm.p 'simple',:indexed => {:add_button_text => 'Add a name',:add_button_position=>'bottom',:delete_button_text=>'Delete this name', :reference_field => 'name'}
      end
      before(:each) do
        do_p
      end

      it "should raise an error if you don't specify the refernce_field" do
        lambda {
          SampleForm.p 'simple',:indexed => {}
        }.should raise_error("reference_field option must be defined")
      end
      
      it "should add indexed presentation html to the body" do
        SampleForm.get_body.should == [
          "<div id=\"presentation_simple\" class=\"presentation_indexed\">",
            "<ul id=\"presentation_simple_items\">",
              "<li id=\"item_0\" class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>",
                "<input type=\"button\" value=\"Delete this name\" onclick=\"simple.removeItem($(this).up())\">",
              "</li>",
            "</ul>",
            "<input type=\"button\" onclick=\"doAddsimple()\" value=\"Add a name\">",
          "</div>"]
      end

      it "should add a list item per index to the presentation html" do
        @record[:name,1] = 'Herbert Fink'
        SampleForm.prepare_for_build(@record,@form,nil)
        do_p
        SampleForm.get_body.should == [
          "<div id=\"presentation_simple\" class=\"presentation_indexed\">",
            "<ul id=\"presentation_simple_items\">",
              "<li id=\"item_0\" class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>",
                "<input type=\"button\" value=\"Delete this name\" onclick=\"simple.removeItem($(this).up())\">",
              "</li>",
              "<li id=\"item_1\" class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record[name]\" name=\"record[name]\" type=\"text\" value=\"Herbert Fink\" /></div>",
                "<input type=\"button\" value=\"Delete this name\" onclick=\"simple.removeItem($(this).up())\">",
              "</li>",
            "</ul>",
            "<input type=\"button\" onclick=\"doAddsimple()\" value=\"Add a name\">",
          "</div>"]
      end
      
      it "should add javascript initialization to the javascripts" do
        SampleForm.get_jscripts.should == [
          "var simple = new indexedItems;simple.elem_id=\"presentation_simple_items\";simple.delete_text=\"Delete this name\";simple.self_name=\"simple\";",
          "function doAddsimple() {simple.addItem(\"<div id=\\\"question_name\\\" class=\\\"question\\\"><label class=\\\"label\\\" for=\\\"record[name]\\\">Name:</label><input id=\\\"record[name]\\\" name=\\\"record[name]\\\" type=\\\"text\\\" value=\\\"Bob Smith\\\" /></div>\")}"
          ]
      end
    end
  end

  describe "utility functions" do
    describe '#get_field_constraints_as_hash' do
      it "should convert the enum list to a simple hash" do
        SampleForm.get_field_constraints_as_hash('fruit','enumeration').should ==
          {"apple_mac"=>"Macintosh Apple","apple_mutsu"=>"Mutsu","pear"=>"Pear","banana"=>"Banana","other"=>"Other...*","x"=>"XOther...*"}
      end
    end
  end
end