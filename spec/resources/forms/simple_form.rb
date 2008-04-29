class FieldNameHasG < Property
  def self.evaluate(form,field,value)
    field.name =~ /g/ ? true : false
  end
  def self.render(question_html,property_value,question,form)
    if property_value
      question_html + 'g question!'
    else
      question_html
    end
  end
end

class SimpleForm < Zform
  def setup

    def_tabs 'simple_tabs' do
      tab 'simple', :label => 'Edit'
      tab 'view'
    end

    labeling(:postfix => ':')
    def_fields :properties=>[FieldNameHasG] do
      def_fields :constraints=>{'required' => true} do
        f 'name'
        def_fields :constraints=>{"range"=>"1-100"} do
          f 'age'
          f 'higher_ed_years',:constraints=>{'range'=>'0-10'},:followups=>{'/../' => f('degree'),'!0'=>f('no_ed_reason')}
        end
      end
      f 'eye_color',
        :constraints=>{'enumeration' => [{'ffffff' => 'black'},{'00ff00'=>'green'},{'0000ff'=>'blue'},{'x'=>'other'}]},
        :followups =>{'x'=>f('other_eye_color')}
      f 'age_plus_education', :calculated => {
        :proc => Proc.new { |form,index| (form.field_value('age',index).to_i+form.field_value('higher_ed_years',index).to_i).to_s}
      }
    end
    f 'married', :constraints=>{'enumeration' => [{'y' => 'Yes'},{'n'=>'No'}]}
    f 'children', :type=>'integer'

    presentation 'create', :create_with_workflow =>'standard' do
      q 'name'
    end
    
    presentation 'name_only' do
      q 'name'
    end

    presentation 'education_info' do
      q 'higher_ed_years'
      qro 'age_plus_education'
    end

    presentation 'container' do
      p 'name_only'
      p 'education_info'
    end

    presentation 'simple' do
      q 'name'
      q 'age'
      q 'higher_ed_years'
      q 'eye_color', :followups => [{'other_eye_color' => {:widget=>'TextArea'}}]
      q 'married',:labeling => {:postfix => '?'}
    end

    presentation 'married_questions' do
      q 'married',:widget=>'PopUp',:labeling => {:postfix => '?'}
      javascript_show_hide_if('married',:value => 'y') do
        q 'children'
      end
    end
    
    presentation 'view' do
      q 'name',:read_only => true
      q 'age',:erb =>%Q|<tr><td class='field_label'><%=field_label%></td><td><%=field_element%></td></tr>|
      q 'higher_ed_years',:read_only => true,:erb =>%Q|<tr><td class='field_label'><%=field_label%></td><td><%=field_element%></td></tr>|
    end

    workflow 'standard' do
#      def_states_normal :logged,:completed
#      def_states_verification :verifying
    	action 'create',[nil] do
        state 'logged'
        redirect_url '/'
    	end
    	action 'continue','logged' do
    	  state 'logged'
        redirect_url '/'
    	end
    	action 'finish','logged' do
    	  state 'completed'
        redirect_url '/'
    	end
  	end
    
  end
end