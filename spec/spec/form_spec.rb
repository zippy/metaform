require File.dirname(__FILE__) + '/../spec_helper'

describe SimpleForm do
  before(:each) do
    @form = SimpleForm.new 
    @record = Record.make(@form,'create',{:name =>'Bob Smith'})
  end
  
  describe "-- dsl: " do
    describe "labeling" do
      before(:each) do
        @name_q = @form.questions['name']
      end
      it "should set the default label options" do
        @form.label_options[:postfix].should == ":"
      end
      it "should render labels with the default postfix" do
        @name_q.render(@form).should == "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" /></div>"
      end
      it "should render questions that override the postfix" do
        mq = @form.get_questions_by_field_name('married')[0]
        mq.render(@form).should == "<div id=\"question_married\" class=\"question\"><label class=\"label\" for=\"record[married]\">Married?</label><select name=\"record[married]\" id=\"record_married\">\n   <option value=\"y\">Yes</option>\n<option value=\"n\">No</option>\n</select>\n</div>"
      end
    end
    
    describe "c (define a condition)" do
      it "should provide access to conditions via a #conditions accessor" do
        @form.conditions['age_is_nil'].instance_of?(Condition).should == true
      end
      it "should evaluate 'is nil' correctly in ruby" do
        @form.with_record(@record) do
          @form.conditions['age_is_nil'].evaluate.should == true
          @record.age = '44'
          @form.conditions['age_is_nil'].evaluate.should == false
        end
      end
      it "should evaluate correctly == in ruby for integers" do
        @form.with_record(@record) do
          @form.conditions['age=44'].evaluate.should == false
          @record.age = '44'
          @form.conditions['age=44'].evaluate.should == true
        end
      end
      it "should evaluate correctly < in ruby for integers" do
         @form.with_record(@record) do
           @form.conditions['age<44'].evaluate.should == false
           @record.age = '43'
           @form.conditions['age<44'].evaluate.should == true
           @record.age = '45'
           @form.conditions['age<44'].evaluate.should == false
         end
      end
      it "should return the created condition" do
        the_c = @form.c 'eye_color=ffffff',:description => "has black eyes"
        the_c.instance_of?(Condition).should == true
      end
      it "should assign the default condition ruby and javascript for simple conditions" do
        the_c = @form.c 'eye_color=ffffff',:description => "has black eyes"
        the_c.humanize.should == "has black eyes"
        the_c.instance_of?(Condition).should == true
        the_c.ruby.should == nil
        the_c.generate_javascript_function({'eye_color'=>[TextFieldWidget,nil]})[0].should == "function value_eye_color() {return $F('record_eye_color')};function has_black_eyes() {return value_eye_color() == \"ffffff\"}"
        @form.with_record(@record) do
          the_c.evaluate.should == false
          @record.eye_color = 'ffffff'
          the_c.evaluate.should == true
        end
      end
    end
    
    # describe "if_c (define a constraint condition)" do
    #   it "should define a ConstraintCondition object" do
    #     cc = @form.if_c('age=60',true)
    #     cc.instance_of?(ConstraintCondition).should == true
    #     cc.constraint_value.should == true
    #     cc.condition.instance_of?(Condition).should == true
    #     cc.condition.field_value.should == '60'
    #     cc.condition.humanize.should == 'age is 60'
    #   end
    # end
    
    describe "if_c (define a constraint condition))" do
      it "should correctly perform an if when a simple condition is false" do
        @record.name = 'Joe'
        r = @form.build('if_c_user_simple',@record)
        r.should == ["<div id=\"presentation_if_c_user_simple\" class=\"presentation\">\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      it "should correctly perform an if when a simple condition is true" do
        @record.name = 'Sue'
        r = @form.build('if_c_user_simple',@record)
        r.should == ["<div id=\"presentation_if_c_user_simple\" class=\"presentation\">\n<p>Her name is sue</p>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      it "should correctly perform an if when a simple condition is false and condition_value is false" do
        @record.name = 'Joe'
        r = @form.build('if_c_user_false',@record)
        r.should == ["<div id=\"presentation_if_c_user_false\" class=\"presentation\">\n<p>Her name is sue</p>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      it "should correctly perform an if when a simple condition is true and condition_value is false" do
        @record.name = 'Sue'
        r = @form.build('if_c_user_false',@record)
        r.should == ["<div id=\"presentation_if_c_user_false\" class=\"presentation\">\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      it "should correctly perform an if when a complex condition is false" do
        @record.age = 59
        @record.name = 'Joe'
        r = @form.build('if_c_user_complex',@record)
        r.should == ["<div id=\"presentation_if_c_user_complex\" class=\"presentation\">\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      it "should correctly perform an if when a complex condition is true" do
        @record.age = 61
        @record.name = 'Sue'
        r = @form.build('if_c_user_complex',@record)
        r.should == ["<div id=\"presentation_if_c_user_complex\" class=\"presentation\">\n<p>She is both Sue and old</p>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">", ""]
      end
      
      
    end
    
    describe "cs (define a constraint)" do
      it "should add constraints to specified fields" do
#        @form.cs :fields=> ['senior'], :constraints => {'required' => true}
        @form.fields['senior'].constraints['required'].should == true
      end
    end
    
    describe "f (define a field)" do
      it "should create a form with a name field" do
        @form.fields['name'].class.should == Field
      end
      it "should set hash options given to def_fields to all fields defined in the block" do
        @form.fields['name'].constraints.has_key?('required').should == true
        @form.fields['age'].constraints.has_key?('required').should == true
        @form.fields['higher_ed_years'].constraints.has_key?('required').should == true
        @form.fields['eye_color'].constraints.has_key?('required').should == false

        @form.fields['name'].constraints.has_key?('range').should == false
        @form.fields['age'].constraints.has_key?('range').should == true
        @form.fields['higher_ed_years'].constraints.has_key?('range').should == true
        @form.fields['eye_color'].constraints.has_key?('range').should == false

        @form.fields['eye_color'].constraints.has_key?('enumeration').should == true
      end
      it "should set array options given to def_fields to all fields defined in the block" do
        @form.fields['name'].properties.should == [Invalid,FieldNameHasG]
      end
      it "should allow fields in a def_fields block to override options" do
        @form.fields['higher_ed_years'].constraints['range'].should == '0-10'
      end
      it "should raise an error for unknown field types" do
        lambda {@form.f('fish',:type => 'squid')}.should raise_error("Unknown field type: squid")
      end
            
      describe ":followups option"do
        before(:each) do
          @followup = @form.fields['other_eye_color']
        end
        it "should define the followup field" do
          @followup.class.should == Field
        end
        it "should set a force_nil_if condition for sub fields" do
          f = @form.fields['eye_color'].force_nil_if
          f.keys[0].object_id.should == @form.c('eye_color=x').object_id
          f[f.keys[0]].should == ['other_eye_color']
        end
        it "should generate condition objects to trigger followup fields" do
          @form.fields['eye_color'].followup_conditions["other_eye_color"].should == @form.c("eye_color=x")
        end
        it "should generate regex condition objects" do
          @form.fields['higher_ed_years'].followup_conditions['degree'].should == @form.c('higher_ed_years=~/../')
        end
      end
      
      describe ":groups option" do
        it "should add field to the group" do
          @form.groups['basic_info']['name'].should == true
        end
        it "should not add field to groups not specified" do
          @form.groups['basic_info']['married'].should == nil
        end
        it "should add field to additional groups" do
          @form.groups['kids']['children'].should == true
          @form.groups['family_info']['children'].should == true
        end
      end
      describe ":force_nil_if option" do
        it "should force listed fields to nil if the condition is true" do
          @form.with_record(@record) do
            @record.children = '4'
            @record.oldest_child_age = '12'
            @record.oldest_child_age.should == '12'
            @record.children = 0
            @record.oldest_child_age.should == nil
          end
        end
      end
    end # f
    
    describe "presentation (define a presentation)" do
      it "should define the 'simple' presentation" do
        @form.presentations['simple'].class.should == Presentation
      end
      it "should set the create_with_workflow option if present" do
       @form.workflow_for_new_form('create').should == 'standard'
      end
      it "should not set the create_with_workflow option if not present" do
       lambda {@form.workflow_for_new_form('simple')}.should raise_error("simple doesn't define a workflow for create!")
      end
      it "should build a map between field and question names" do
        @form.presentations['simple'].question_names.should == {
            "name"=>"name",
            "married"=>"married-208205125",
            "eye_color"=>"eye_color-876727679",
            "other_eye_color"=>"other_eye_color-316587098", 
            "higher_ed_years"=>"higher_ed_years",
            "age"=>"age"
          }
      end
    end # presentation
    
    describe "q (display a question)" do
      before(:each) do
       @name_q = @form.questions['name']
       @record = Record.make(@form,'create',{:name =>'Bob Smith'})
      end
      it "should raise an exception for an undefined field" do
        lambda {@form.q 'froboz'}.should raise_error(MetaformUndefinedFieldError)
      end
      it "should define the 'name' question" do
        @name_q.class.should == Question
        @name_q.field.should == @form.fields['name']
        @name_q.widget.should == 'TextField'
        @name_q.params.should == nil
      end
      it "should render without a value" do
       @name_q.render(@form).should == "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" /></div>"
      end
      it "should render with a value" do
        @name_q.render(@form,'Bob Smith').should == "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"
      end
      it "should render read-only if forced" do
        @name_q.render(@form,'Bob Smith',true).should == "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record_name\">Bob Smith</span></div>"
      end
      it "should render an enumeration based widget" do
        mq = @form.get_presentation_question('married_questions','married')
        mq.render(@form,'y').should == "<div id=\"question_married\" class=\"question\"><label class=\"label\" for=\"record[married]\">Married?</label><select name=\"record[married]\" id=\"record_married\">\n\t<option value=\"y\" selected=\"selected\">Yes</option>\n<option value=\"n\">No</option>\n</select>\n</div>"
      end
      it "should render in read-only mode" do
        nq = @form.get_questions_by_field_name('name')[1]
        nq.render(@form,'Bob Smith').should == "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record_name\">Bob Smith</span></div>"
      end
      it "should render erb" do
        nq = @form.get_questions_by_field_name('age')[0]
        nq.render(@form,'22').should == "<tr><td class='field_label'>Age:</td><td><input id=\"record_age\" name=\"record[age]\" type=\"text\" value=\"22\" /></td></tr>"
      end
      it "should render erb in read only mode" do
        nq = @form.get_questions_by_field_name('higher_ed_years')[0]
        nq.render(@form,'5').should == "<tr><td class='field_label'>Higher ed years:</td><td><span id=\"record_higher_ed_years\">5</span></td></tr>"
      end
      it "should render a property" do
        (@form.questions['age'].render(@form) =~ /g question!/).should_not == nil
        (@form.questions['higher_ed_years'].render(@form) =~ /g question!/).should_not == nil
        (@form.questions['name'].render(@form) =~ /g question!$/).should == nil
      end
      it "should render multiple properties" do
        @form.set_verification(true)
        (@form.questions['age'].render(@form,'99') =~ /g question!/).should_not == nil
        (@form.questions['age'].render(@form,'99') =~ /<span class="errors">/).should == nil
        (@form.questions['higher_ed_years'].render(@form,'99') =~ /g question!/).should_not == nil
        (@form.questions['higher_ed_years'].render(@form,'99') =~ /<span class="errors">/).should_not == nil
      end
      describe "-- :followups option" do
        def setup_q
          @form.with_record(@record) do
            @record.eye_color = 'x'
            yield
          end
        end
        it "should render questions with a followup question" do
          setup_q do
            @form.q 'eye_color', :followups => [{'other_eye_color' => {:widget=>'TextArea'}}]
          end
          @form.get_body.should==["<div id=\"question_eye_color\" class=\"question\"><label class=\"label\" for=\"record[eye_color]\">Eye color:</label><input id=\"record_eye_color\" name=\"record[eye_color]\" type=\"text\" value=\"x\" /></div>", "<div id=\"uid_1\" class=\"followup\">", "<div id=\"question_other_eye_color\" class=\"question\"><label class=\"label\" for=\"record[other_eye_color]\">Other eye color:</label><textarea id=\"record_other_eye_color\" name=\"record[other_eye_color]\"></textarea></div>", "</div>"]
          @form.get_observer_jscripts.should == {"eye_color=x"=>{:neg=>["Element.hide('uid_1')"], :pos=>["Element.show('uid_1')"]}}
        end
        it "should accept a single hash if there is only one followup" do
          setup_q do
            @form.q 'eye_color', :followups => {'other_eye_color' => {:widget=>'TextArea'}}
          end
          @form.get_body.should==["<div id=\"question_eye_color\" class=\"question\"><label class=\"label\" for=\"record[eye_color]\">Eye color:</label><input id=\"record_eye_color\" name=\"record[eye_color]\" type=\"text\" value=\"x\" /></div>", "<div id=\"uid_1\" class=\"followup\">", "<div id=\"question_other_eye_color\" class=\"question\"><label class=\"label\" for=\"record[other_eye_color]\">Other eye color:</label><textarea id=\"record_other_eye_color\" name=\"record[other_eye_color]\"></textarea></div>", "</div>"]
        end
        it "should accept a single hash with a string value that is the widget" do
          setup_q do
            @form.q 'eye_color', :followups => {'other_eye_color' => 'TextArea'}
          end
          @form.get_body.should==["<div id=\"question_eye_color\" class=\"question\"><label class=\"label\" for=\"record[eye_color]\">Eye color:</label><input id=\"record_eye_color\" name=\"record[eye_color]\" type=\"text\" value=\"x\" /></div>", "<div id=\"uid_1\" class=\"followup\">", "<div id=\"question_other_eye_color\" class=\"question\"><label class=\"label\" for=\"record[other_eye_color]\">Other eye color:</label><textarea id=\"record_other_eye_color\" name=\"record[other_eye_color]\"></textarea></div>", "</div>"]
        end
        it "should accept a string value which is just the field and assumes all default options" do
          setup_q do
            @form.q 'eye_color', :followups => 'other_eye_color'
          end
          @form.get_body.should==["<div id=\"question_eye_color\" class=\"question\"><label class=\"label\" for=\"record[eye_color]\">Eye color:</label><input id=\"record_eye_color\" name=\"record[eye_color]\" type=\"text\" value=\"x\" /></div>", "<div id=\"uid_1\" class=\"followup\">", "<div id=\"question_other_eye_color\" class=\"question\"><label class=\"label\" for=\"record[other_eye_color]\">Other eye color:</label><input id=\"record_other_eye_color\" name=\"record[other_eye_color]\" type=\"text\" /></div>", "</div>"] 
        end
        it "should produce the correct javascript for regex based followups " do
          @form.with_record(@record) do
            @form.q 'higher_ed_years',:followups => 'degree'
            @form.get_observer_jscripts.should == {"higher_ed_years=~/../"=>{:neg=>["Element.hide('uid_1')"], :pos=>["Element.show('uid_1')"]}}
          end
        end
        it "should produce the correct javascript for negated value followups " do
          @form.with_record(@record) do
            @form.q 'higher_ed_years',:followups => 'no_ed_reason'
            @form.get_observer_jscripts.should == {"higher_ed_years=!0"=>{:neg=>["Element.hide('uid_1')"], :pos=>["Element.show('uid_1')"]}}
          end
        end
      end # q:followups
      it "should raise an error if followups option specified for a field not defined with followups" do
        lambda {@form.q 'name',:followups =>{}}.should raise_error("no followups defined for field 'name'")
      end
      describe "-- with calcualted fields" do
        it "should render calculated fields in read only mode" do
          @record.age = 32
          @record.higher_ed_years = 4
          @form.with_record(@record) do
            @form.q('age_plus_education',:read_only => true)
            @form.get_body.should == ["<div id=\"question_age_plus_education\" class=\"question\"><label class=\"label\" for=\"record[age_plus_education]\">Age plus education:</label><span id=\"record_age_plus_education\">36</span>g question!</div>"]
          end
        end
        it "should raise an exception if used in non-read-only mode" do
          lambda {@form.q 'age_plus_education'}.should raise_error('calculated fields can only be used read-only')
        end
      end
      describe "-- with verification" do
        it "should add the verification html if q specifies the :force_verify option" do
          @record.name = ''
          @form.with_record(@record) do
            @form.q('name',:force_verify => true)
            @form.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"\" /><span class=\"errors\">this field is required</span></div>"]
          end
        end
        it "should not add the verification html if q specifies the :force_verify option but the value of the field is ok" do
          @form.with_record(@record) do
            @form.q('name',:force_verify => true)
            @form.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>"]
          end
        end
        it "should add the verification html for an erb question"
        it "should add the verification html if record is in a workflow that requires validation" 
        #do
#          @record.name = ''
#          @record.workflow_state= 'verifying'
#          SampleForm.prepare_for_build(@record,@form,nil)
#          SampleForm.q 'name', 'TextField'
#          SampleForm.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"\" /><span class=\"errors\">this field is required</span></div>"]
#        end
      end
    end # q
    
    describe "qro (display a question read only)" do
      it "should be a short-hand for adding the :read_only option to a q" do
        @form.in_phase(:build) do
          @form.qro('name')
          @form.get_body.should == ["<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record_name\"></span></div>"]
        end
      end
    end #qro
    
    describe "p (display a presentation)" do
      it "should render the contents of a presentation" do
        @form.in_phase(:build) do
          @form.p('create')
          @form.get_body.should == ["<div id=\"presentation_create\" class=\"presentation\">", "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" /></div>", "</div>"]
        end
      end
      it "should render presentations with sub-presentations" do
        @form.in_phase(:build) do
          @form.p('container')
          @form.get_body.should == ["<div id=\"presentation_container\" class=\"presentation\">", "<div id=\"presentation_name_only\" class=\"presentation\">", "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" /></div>", "</div>", "<div id=\"presentation_education_info\" class=\"presentation\">", "<div id=\"question_higher_ed_years\" class=\"question\"><label class=\"label\" for=\"record[higher_ed_years]\">Higher ed years:</label><input id=\"record_higher_ed_years\" name=\"record[higher_ed_years]\" type=\"text\" />g question!</div>", "<div id=\"question_age_plus_education\" class=\"question\"><label class=\"label\" for=\"record[age_plus_education]\">Age plus education:</label><span id=\"record_age_plus_education\"></span>g question!</div>", "</div>", "</div>"]
        end
      end
      it "should render the contents readonly of a presentation with force_read_only true" do
        @form.in_phase(:build) do
          @form.p('name_read_only')
          @form.get_body.should == ["<div id=\"presentation_name_read_only\" class=\"presentation\">", "<div id=\"presentation_name_only\" class=\"presentation\">", "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><span id=\"record_name\"></span></div>", "</div>", "</div>"]
        end
      end
    end #p
        
    describe "p (display an indexed presentation)" do
      def do_p
        @record.save
        @form.with_record(@record) do
          @form.p 'name_only',:indexed => {:add_button_text => 'Add a name',:add_button_position=>'bottom',:delete_button_text=>'Delete this name', :reference_field => 'name'}
        end
      end

      it "should raise an error if you don't specify the reference_field" do
        lambda {@form.p 'name_only',:indexed => {}}.should raise_error("reference_field option must be defined")
      end

      it "should setup" do
        @form.p 'name_only',:indexed => {:add_button_text => 'Add a name',:add_button_position=>'bottom',:delete_button_text=>'Delete this name', :reference_field => 'name'}
      end
      
      it "should set the use_multi_index? flag" do
        @form.use_multi_index?.should == nil
        do_p
        @form.use_multi_index?.should == 1
      end

      it "should add indexed presentation html to the body" do
        do_p
        @form.get_body.should == [
          "<div id=\"presentation_name_only\" class=\"presentation_indexed\">",
            "<ul id=\"presentation_name_only_items\">",
              "<li class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[_0_name]\">Name:</label><input id=\"record__0_name\" name=\"record[_0_name]\" type=\"text\" value=\"Bob Smith\" /></div>",
                "<input type=\"button\" class=\"float_right\" value=\"Delete this name\" onclick=\"name_only.removeItem($(this).up())\"><div class=\"clear\"></div>",
              "</li>",
            "</ul>",
            "<input type=\"button\" onclick=\"doAddname_only()\" value=\"Add a name\">",
          "</div>"]
      end

      it "should add a list item per index to the presentation html" do
        @record[:name,1] = 'Herbert Fink'
        do_p
        @form.get_body.should == [
          "<div id=\"presentation_name_only\" class=\"presentation_indexed\">",
            "<ul id=\"presentation_name_only_items\">",
              "<li class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[_0_name]\">Name:</label><input id=\"record__0_name\" name=\"record[_0_name]\" type=\"text\" value=\"Bob Smith\" /></div>",
                "<input type=\"button\" class=\"float_right\" value=\"Delete this name\" onclick=\"name_only.removeItem($(this).up())\"><div class=\"clear\"></div>",
              "</li>",
              "<li class=\"presentation_indexed_item\">",
                "<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[_1_name]\">Name:</label><input id=\"record__1_name\" name=\"record[_1_name]\" type=\"text\" value=\"Herbert Fink\" /></div>",
                "<input type=\"button\" class=\"float_right\" value=\"Delete this name\" onclick=\"name_only.removeItem($(this).up())\"><div class=\"clear\"></div>",
              "</li>",
            "</ul>",
            "<input type=\"button\" onclick=\"doAddname_only()\" value=\"Add a name\">",          
            "</div>"]
      end
      
      it "should add javascript initialization to the javascripts" do
        do_p
        @form.get_jscripts.should == [
          "var name_only = new indexedItems;name_only.elem_id=\"presentation_name_only_items\";name_only.delete_text=\"Delete this name\";name_only.self_name=\"name_only\";", 
          "            function doAddname_only() {name_only.addItem(\"<div id=\\\"question_name\\\" class=\\\"question\\\"><label class=\\\"label\\\" for=\\\"record[name]\\\">Name:<\\/label><input id=\\\"record_name\\\" name=\\\"record[name]\\\" type=\\\"text\\\" value=\\\"Bob Smith\\\" \\/><\\/div>\")}"
          ]
      end
    end #p-indexed

    describe "qp (display a question and a javascript activated sub-presentation)" do
      it "should render a complicated bunch of html and add observer javascripts" do
        @form.with_record(@record) do
          @form.qp('age',:presentation_name => 'education_info',:show_hide_options=>{:condition => "age=18"})
          @form.get_body.should == [
            "<div id=\"question_age\" class=\"question\"><label class=\"label\" for=\"record[age]\">Age:</label><input id=\"record_age\" name=\"record[age]\" type=\"text\" />g question!</div>",
            "<div id=\"uid_1\" class=\"hideable_box_with_border\">",
              "<div id=\"presentation_education_info\" class=\"presentation\">",
                "<div id=\"question_higher_ed_years\" class=\"question\"><label class=\"label\" for=\"record[higher_ed_years]\">Higher ed years:</label><input id=\"record_higher_ed_years\" name=\"record[higher_ed_years]\" type=\"text\" />g question!</div>",
                "<div id=\"question_age_plus_education\" class=\"question\"><label class=\"label\" for=\"record[age_plus_education]\">Age plus education:</label><span id=\"record_age_plus_education\">0</span>g question!</div>",
              "</div>",
            "</div>"]
          @form.get_observer_jscripts.should == {"age=18"=>{:pos=>["Element.hide('uid_1')"], :neg=>["Element.show('uid_1')"]}}
        end
      end
    end #qp
    
    describe "html (display arbitrary html)" do
      it "should render the html passed in" do
        @form.in_phase(:build) do
          @form.html('<b>text</b>').should == "<b>text</b>"
        end
      end
    end #html
    
    describe "t (display a text element)" do
      it "should render a text element using defaults" do
        @form.in_phase(:build) do
          @form.t('here is some test text').should == "<p>here is some test text</p>"
        end
      end
      it "should render a text element using options" do
        @form.in_phase(:build) do
          @form.t('here is a table cell',:element=>'td',:css_class=>'cell_class').should == "<td class=\"cell_class\">here is a table cell</td>"
        end
      end
    end #t

    describe "q_meta_workflow_state (display a list of workflow states)" do
      it "should render the html element" do
        @form.with_record(@record) do
          @form.q_meta_workflow_state('States:','PopUp').should == <label class=\"label\" for=\"meta[workflow_state]\">States:</label><select name=\"meta[workflow_state]\" id=\"meta_workflow_state\">\n   <option value=\"completed\">completed: Form Completed</option>\n<option value=\"logged\">logged: Form Logged</option>\n<option value=\"verifying\">verifying: Form in verification</option>\n</select>\n"
        end
      end
    end

    describe "tip (add a tool-tip)" do
      it "should add an 'info' icon with a tool-tip" do
        @form.in_phase(:build) do
          @form.tip('this is the text of the first tip').should == '<img src="/images/info_circle.gif" alt="info" id="tip_1">'
          @form.tip('this is the text of the "second" tip').should == '<img src="/images/info_circle.gif" alt="info" id="tip_2">'
          @form.get_jscripts.should == [
            %q|new Tip('tip_1',"this is the text of the first tip")|,
            %q|new Tip('tip_2',"this is the text of the \"second\" tip")|
          ]
        end
      end
    end    
    
    describe "function_button (display a javascript button)" do
      it "should render a button" do
        @form.in_phase(:build) do
          @form.function_button('Alert') {"alert('boink)"}
          @form.get_body.last.should == "<input type=\"button\" value=\"Alert\" onclick=\"alert('boink)\">"
        end
      end
      it "should render a button with a class specification option" do
        @form.in_phase(:build) do
          @form.function_button('Alert',:css_class => 'cool_button') {"alert('boink)"}
          @form.get_body.last.should == "<input type=\"button\" value=\"Alert\" class=\"cool_button\" onclick=\"alert('boink)\">"
        end
      end
    end #function_button
    
    describe "javascript_show_hide_if (display a block conditionally at 'runtime' on the browser)" do
      it "should produce body html and observer javascripts" do
        @form.with_record(@record) do
          @form.javascript_show_hide_if(:condition => 'married=y')
          @form.get_body.should == ["<div id=\"uid_1\" class=\"hideable_box_with_border\" style=\"display:none\">", "</div>"]
          @form.get_observer_jscripts.should == 
            {"married=y"=>{:neg=>["Element.hide('uid_1')"], :pos=>["Element.show('uid_1')"]}}
        end
      end
      it "should be able to use a custom wrapper id and element type" do
        @form.with_record(@record) do
          @form.javascript_show_hide_if(:condition => 'married=y',:wrapper_id => 'special_id',:wrapper_element => 'p')
          @form.get_body.should == ["<p id=\"special_id\" class=\"hideable_box_with_border\" style=\"display:none\">", "</p>"]
        end
      end
      it "should be able to use a custom wrapper and and css class" do
        @form.with_record(@record) do
          @form.javascript_show_hide_if(:condition => 'married=y',:wrapper_id => 'special_div',:css_class=>'shiny_box')
          @form.get_body.should == ["<div id=\"special_div\" class=\"shiny_box\" style=\"display:none\">","</div>"]
        end
      end
      it "should be able to use a condition object instead of a condition string" do
        @form.with_record(@record) do
          @form.javascript_show_hide_if(:condition => @form.c("age=12"))
          @form.get_observer_jscripts.should == {"age=12"=>{:neg=>["Element.hide('uid_1')"], :pos=>["Element.show('uid_1')"]}}
        end
      end
      it "should be able to hide by default instead of show" do
        @form.with_record(@record) do
          @form.javascript_show_hide_if(:condition => 'married=y',:show => false)
          @form.get_observer_jscripts.should == {"married=y"=>{:neg=>["Element.show('uid_1')"], :pos=>["Element.hide('uid_1')"]}}
        end
      end      
      it "should add the elements from the block into the div" do
        @form.with_record(@record) do
          @form.p('married_questions')
          @form.get_body.should == ["<div id=\"presentation_married_questions\" class=\"presentation\">", "<div id=\"question_married\" class=\"question\"><label class=\"label\" for=\"record[married]\">Married?</label><select name=\"record[married]\" id=\"record_married\">\n   <option value=\"y\">Yes</option>\n<option value=\"n\">No</option>\n</select>\n</div>", "<div id=\"uid_1\" class=\"hideable_box_with_border\" style=\"display:none\">", "<div id=\"question_children\" class=\"question\"><label class=\"label\" for=\"record[children]\">Children:</label><input id=\"record_children\" name=\"record[children]\" type=\"text\" /></div>", "</div>", "</div>"]
        end
      end
    end #javascript_show_hide_if
    describe "javascript_show_if (show a block conditionally at 'runtime' on the browser)" do
      it "should be like calling javascript_show_hide_if" do
        @form.with_record(@record) do
          @form.javascript_show_if('married=y')
          @form.get_body.should == ["<div id=\"uid_1\" class=\"hideable_box\" style=\"display:none\">", "</div>"]
          @form.get_observer_jscripts.should == {"married=y"=>{:pos=>["Element.show('uid_1')"], :neg=>["Element.hide('uid_1')"]}}
        end
      end
    end #javascript_show_if
    describe "javascript_hide_if (hide a block conditionally at 'runtime' on the browser)" do
      it "should be like calling javascript_show_hide_if with :show=>false" do
        @form.with_record(@record) do
          @form.javascript_hide_if('married=y')
          @form.get_body.should == ["<div id=\"uid_1\" class=\"hideable_box\" style=\"display:none\">", "</div>"]
          @form.get_observer_jscripts.should == {"married=y"=>{:pos=>["Element.hide('uid_1')"], :neg=>["Element.show('uid_1')"]}}
        end
      end
    end #javascript_hide_if
    
    describe "javascript helpers-- " do
      describe "javascript_if_field" do
        it "should generate a comparison wrapper around the javascript returned by the block" do
          @form.in_phase(:build) do
            @form.javascript_if_field('name','==','Bob Smith') {'alert("Go Bob!")'}.should == 
              ["if ($F('record_name') == 'Bob Smith') {alert(\"Go Bob!\")};"]
          end
        end
      end #javascript_if_field
      describe "javascript_confirm" do
        it "should generate a confirm wrapper around the javascript returned by the block" do
          @form.in_phase(:build) do
            @form.javascript_confirm('Are you sure you want to erase everyting') {'erase("everyting")'}.should == 
              ["if (confirm('Are you sure you want to erase everyting')) {erase(\"everyting\")};"]
          end
        end
      end #javascript_confirm
      describe "javascript_submit" do
        it "should generate a script that submits the form" do
          @form.in_phase(:build) do
            @form.javascript_submit.should == ["$('metaForm').submit();"]
          end
        end
        it "should generate a script that submits the form with a workflow_action" do
          @form.in_phase(:build) do
            @form.javascript_submit(:workflow_action => 'create').should == ["$('meta_workflow_action').value = 'create';$('metaForm').submit();"]
          end
        end
      end #javascript_submit
    end #javascript

    describe "workflow (define a workflow)" do
      before(:each) do
        @workflow = @form.workflows['standard']
      end
      it "should create a workflow" do
        @workflow.class.should == Workflow
      end
      it "should create the workflow's actions" do
        @workflow.actions.keys.sort.should == ['continue','create','finish']
      end
      it "should create the workflow's states" do
        @workflow.states.keys.sort.should == ['completed','logged','verifying']
      end
      it "should allow"
    end #workflow

    describe "def_tabs (define a tab group)" do
      before(:each) do
        @tabs = @form.tabs['simple_tabs']
      end
      it "should create a tab group" do
        @tabs.class.should == Proc
      end
    end #def_tabs
    describe "tab (render a tab)" do
      it "should render a tab with default options" do
        @form.with_record(@record) do
          @form.tab('view').should == "<li class=\"tab_view\"> <a href=\"#\" onClick=\"return submitAndRedirect('/records//view')\" title=\"Click here to go to View\"><span>View</span></a> </li>"
        end
      end
      it "should render a tab with specified options" do
        @record[:name,1] = "Herb Monkel"
        @form.with_record(@record) do
          @form.tab('view',:label => 'The View',:index => 1).should == "<li class=\"tab_view\"> <a href=\"#\" onClick=\"return submitAndRedirect('/records//view/1')\" title=\"Click here to go to The View\"><span>The View</span></a> </li>"
        end
      end
    end #tab
  end  #-- dsl

  describe "generators" do
    describe "build_tabs (render a tab group)" do
      it "should render a tab group with the current tab identified" do
        @form.build_tabs('simple_tabs','simple',@record).should == "<div class=\"tabs\"> <ul>\n<li class=\"current tab_simple\"> <a href=\"#\" onClick=\"return submitAndRedirect('/records//simple/simple_tabs')\" title=\"Click here to go to Edit\"><span>Edit</span></a> </li>\n<li class=\"tab_view\"> <a href=\"#\" onClick=\"return submitAndRedirect('/records//view/simple_tabs')\" title=\"Click here to go to View\"><span>View</span></a> </li>\n</ul></div>"
      end
      it "should raise an error for tab group that doesn't exist" do
        lambda {@form.build_tabs('sss','',@record)}.should raise_error("tab group 'sss' doesn't exist")
      end
    end # build_tabs
    describe "build (render form)" do
      it "should collect up a list of all the questions encountered during the build" do
        @form.build('container')
        @form.get_questions_built.should == ['name','higher_ed_years']
      end
      it "should generate html for a simple presentation" do
        @form.with_record(@record) do
          @form.build('name_only').should == [
            "<div id=\"presentation_name_only\" class=\"presentation\">\n<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" /></div>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">",
            ""
          ]
        end
      end
      it "should generate all the html and javascript for a complex presentation" do
        @form.with_record(@record) do
              r = @form.build('simple',@record)
              r.should == [
                "<div id=\"presentation_simple\" class=\"presentation\">\n<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>\n<div id=\"question_age\" class=\"question\"><label class=\"label\" for=\"record[age]\">Age:</label><input id=\"record_age\" name=\"record[age]\" type=\"text\" />g question!</div>\n<div id=\"question_higher_ed_years\" class=\"question\"><label class=\"label\" for=\"record[higher_ed_years]\">Higher ed years:</label><input id=\"record_higher_ed_years\" name=\"record[higher_ed_years]\" type=\"text\" />g question!</div>\n<div id=\"question_eye_color\" class=\"question\"><label class=\"label\" for=\"record[eye_color]\">Eye color:</label><input id=\"record_eye_color\" name=\"record[eye_color]\" type=\"text\" /></div>\n<div id=\"uid_1\" class=\"followup\" style=\"display:none\">\n<div id=\"question_other_eye_color\" class=\"question\"><label class=\"label\" for=\"record[other_eye_color]\">Other eye color:</label><textarea id=\"record_other_eye_color\" name=\"record[other_eye_color]\"></textarea></div>\n</div>\n<div id=\"question_married\" class=\"question\"><label class=\"label\" for=\"record[married]\">Married?</label><input id=\"record_married\" name=\"record[married]\" type=\"text\" /></div>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">",
                "function actions_for_eye_color_is_x() {\n  if (eye_color_is_x()) {Element.show('uid_1')}\n  else {Element.hide('uid_1')}\n}\n\nfunction value_eye_color() {return $F('record_eye_color')};function eye_color_is_x() {return value_eye_color() == \"x\"}\nEvent.observe('record_eye_color', 'change', function(e){ actions_for_eye_color_is_x(); });"
              ]
        end
      end
    end # build
  end # generators

  describe 'helpers' do
    describe "#field_value" do
      it "should return the value of a field" do
        @form.with_record(@record) do
          @form.field_value('name').should == 'Bob Smith'
          @form.field_value('age').should == nil
        end
      end
      it "should return the value of a calculated field" do
        @record.age = 50
        @record.higher_ed_years = 4
        @form.with_record(@record) do
          @form.field_value('age_plus_education').should == '54'
        end
      end
      it "should raise an error if @record has not be set" do
        lambda {@form.field_value('name').should}.should raise_error("attempting to get field value of 'name' with no record")
      end
    end
    describe "#field_valid" do
      it "should return whether a field is valid or not"
    end
    describe '#get_questions_by_field_name' do
      it "should find all questions defined on the named field" do
        mqs = @form.get_questions_by_field_name('married')
        mqs.each {|q| q.field.name.should == 'married'}
      end
      it "should find all questions defined on the named field when more than one are defined" do
        mqs = @form.get_questions_by_field_name('name')
        mqs.size.should == 2
      end
    end
    describe "#field_exists?" do
      it "should test whether a field has been defined" do
        @form.field_exists?('name').should == true
        @form.field_exists?('piggy').should == false
      end
    end
    describe "#presentation_exists?" do
      it "should test whether a presentations has been defined" do
        @form.presentation_exists?('simple').should == true
        @form.presentation_exists?('piggy').should == false
      end
    end
    describe "#find_conditions_with_fields" do
      it "should return a list of conditions that depend on the given fields" do
        conds = @form.find_conditions_with_fields(['eye_color'])
        conds.size.should == 1
        conds[0].name.should == 'eye_color=x'
        the_c = @form.c 'eye_color=ffffff',:description => "has black eyes"
        conds = @form.find_conditions_with_fields(['eye_color'])
        conds.size.should == 2
        conds[0].name.should == 'eye_color=ffffff'
        conds[1].name.should == 'eye_color=x'
      end
    end
    describe "#record_workflow" do
      it "should return the workflow this form was created with" do
        @form.with_record(@record) do
          @form.record_workflow.should == 'standard'
        end
      end
    end
    describe "#workflow_state" do
      it "should return the nil when the record is first created" do
        @form.with_record(@record) do
          @form.workflow_state.should == nil
        end
      end
    end
    describe "#created_at" do
      it "should return datetime it was created" do
        @record.save
        @form.with_record(@record) do
          @form.created_at.to_s.should == Time.now().to_s
        end
      end
    end
    describe "#updated_at" do
    end
  end

  describe "-- workflow actions" do
    it "should return the correct state after a workflow action is taken" do
      @form.with_record(@record) do
        @form.do_workflow_action('create',nil).should == {:next_state=>"logged", :redirect_url=>"/"}
      end
    end
  end
  
  describe "-- Form class utitlites" do
    it "should store a cash of form objects created" do
      cache = Form.cache
      cache.keys[0].should == 'SimpleForm'
      cache.values[0].instance_of?(SimpleForm).should == true
    end
    it "should return a directory where to look for forms" do
      Form.forms_dir.should == 'forms'
    end
  end
  
  describe "#js_conditional_tab" do
    it "should create the correct html and javascript when when using tab changers" do
      r = @form.build('tab_changer',@record)
      r.should == [
        "<div id=\"presentation_tab_changer\" class=\"presentation\">\n<div id=\"question_name\" class=\"question\"><label class=\"label\" for=\"record[name]\">Name:</label><input id=\"record_name\" name=\"record[name]\" type=\"text\" value=\"Bob Smith\" /></div>\n</div>\n<input type=\"hidden\" name=\"meta[workflow_action]\" id=\"meta_workflow_action\">\n<input type=\"hidden\" name=\"___age\" id=\"___age\" value=\"\">",
        "function actions_for_multi_tab_changer() {\n  if (multi_tab_changer()) {$$(\".tab_multi_tab\").invoke('remove');insert_tabs('<li class=\"tab_multi_tab\"> <a href=\"#\" onClick=\"return submitAndRedirect(\\'/records//multi_tab/INDEX\\')\" title=\"Click here to go to  NUM\"><span> NUM</span></a> </li>','.tab_finish',true,'.tab_finish',value_age()-1,true);}\n  else {$$(\".tab_multi_tab\").invoke('remove');}\n}\n\nfunction value_age() {return $F('___age')};function multi_tab_changer() {return value_age() > 0}\nfunction actions_for_view_changer() {\n  if (view_changer()) {$$(\".tab_view\").invoke('remove');insert_tabs('<li class=\"tab_view\"> <a href=\"#\" onClick=\"return submitAndRedirect(\\'/records//view/mutliple_value_tabs\\')\" title=\"Click here to go to View\"><span>View</span></a> </li>','.tab_finish',true,'.tab_finish',1,false);}\n  else {$$(\".tab_view\").invoke('remove');}\n}\n\nfunction value_age() {return $F('___age')};function view_changer() {return value_age() > 0}\nfunction actions_for_simple_changer() {\n  if (simple_changer()) {$$(\".tab_simple\").invoke('remove');insert_tabs('<li class=\"current tab_simple\"> <a href=\"#\" onClick=\"return submitAndRedirect(\\'/records//simple/mutliple_value_tabs\\')\" title=\"Click here to go to Simple\"><span>Simple</span></a> </li>','.tab_finish',true,'.tab_finish',1,false);}\n  else {$$(\".tab_simple\").invoke('remove');}\n}\n\nfunction value_name() {return $F('record_name')};function simple_changer() {return value_name() == Sue}\nEvent.observe('record_name', 'change', function(e){ actions_for_simple_changer(); });"
      ]
    end    
  end
  
end