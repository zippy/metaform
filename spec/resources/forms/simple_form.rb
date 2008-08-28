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

class SimpleForm < Form
  def setup

    def_tabs 'simple_tabs' do
      tab 'simple', :label => 'Edit'
      tab 'view'
    end
    
    def_tabs 'mutliple_value_tabs' do
      tab 'simple', :label => 'Edit'
      tab 'view'
      if_c 'multi_tab_changer' do
         (2..field_value('age',nil).to_i).each {|i| tab 'multi_tab', :label => 'Multiple #'<< i.to_s,:index => i}
      end
    end

    labeling(:postfix => ':')
    def_fields :properties=>[FieldNameHasG] do
      def_fields :constraints=>{'required' => true}, :group => 'basic_info' do
        f 'name'
        def_fields :constraints=>{"range"=>"1-100"} do
          f 'age'
          f 'higher_ed_years',:constraints=>{'range'=>'0-10'},:followups=>{'/../' => f('degree'),'!0'=>f('no_ed_reason')},:label => 'years of higher education'
        end
        f 'senior'
      end
      	
      f 'eye_color',
        :constraints=>{'enumeration' => [{'ffffff' => 'black'},{'00ff00'=>'green'},{'0000ff'=>'blue'},{'x'=>'other'}]},
        :followups => {'x'=>f('other_eye_color')}
      f 'age_plus_education', :calculated => {
        :proc => Proc.new { |form,index| (form.field_value('age',index).to_i+form.field_value('higher_ed_years',index).to_i).to_s}
      }
    end
    
    def_conditions do
      c 'simple_changer', :javascript => ":name == Sue" do
        field_value("name") == 'Sue'
      end 
      c 'view_changer', :javascript => ":age > 0" do
        field_value("age") > 0
      end
      c 'multi_tab_changer', :javascript => ":age > 0" do
        field_value('age') > 0
      end
      c 'age_is_nil', :description=> 'age is nil',:javascript => ':age == ""' do
        field_value("age").nil?
      end
      c 'no_children', :description=> 'no children',:javascript => ':children != "" && parseInt(:children)>0' do
        field_value("children").to_i <= 0
      end
      c 'age=44'
      c 'age<44'
      c 'Sue_is_Old', :javascript => ':name == "Sue" && :age > 60' do
        field_value("name") == "Sue" && field_value("age") > 60 
      end
    end
    
    def_fields :groups => ['family_info'] do
      f 'married', :constraints=>{'enumeration' => [{'y' => 'Yes'},{'n'=>'No'}]}
      f 'children', :type=>'integer', :group => 'kids', :force_nil_if => { c('no_children') => ['oldest_child_age']}
      f 'oldest_child_age', :type=>'integer', :group => 'kids'
    end
        
 #  def_constraints do
 #    cs :fields=> ['senior'],:constraints => {'must_be' => if_c('Flg!=Y',nil)}, :force_on_save => true
##     cs :group => 'intrapartum',:condition => mom_died_AP || pregnancy_ended_before13,:constraints => {'must_be' => nil, :force_on_save => true}
 #  end

    presentation 'create', :create_with_workflow =>'standard' do
      q 'name'
    end
    
    presentation 'name_only' do
      q 'name'
    end

    presentation 'name_read_only',:force_read_only => true do
      p 'name_only'
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
      q 'eye_color', :followups => {'other_eye_color' => 'TextArea'}
      q 'married',:labeling => {:postfix => '?'}
    end

    presentation 'married_questions' do
      q 'married',:widget=>'PopUp',:labeling => {:postfix => '?'}
      javascript_show_hide_if(:condition => 'married=y') do
        q 'children'
      end
    end
    
    presentation 'view' do
      q 'name',:read_only => true
      q 'age',:erb =>%Q|<tr><td class='field_label'><%=field_label%></td><td><%=field_element%></td></tr>|
      q 'higher_ed_years',:read_only => true,:erb =>%Q|<tr><td class='field_label'><%=field_label%></td><td><%=field_element%></td></tr>|
    end
    
    presentation 'tab_changer' do
      q 'name'      
      js_conditional_tab(:tab => 'simple', :anchor_css => 'finish', :tabs_name => 'mutliple_value_tabs', :current_tab => 'simple', :default_anchor_css => 'finish')
      js_conditional_tab(:tab => 'view', :anchor_css => 'finish', :tabs_name => 'mutliple_value_tabs', :current_tab => 'simple', :default_anchor_css => 'finish')
      js_conditional_tab(:tab => 'multi_tab', :anchor_css => 'finish', :multi => 'age', :tabs_name => 'mutliple_value_tabs', :current_tab => 'simple', :default_anchor_css => 'finish')
    end

    presentation 'if_c_user_simple' do
      if_c 'name=Sue' do
        t 'Her name is sue'
      end
    end
    
    presentation 'if_c_user_false' do
      if_c('name=Sue',false) do
        t 'Her name is sue'
      end
    end
    
    presentation 'if_c_user_complex' do
      if_c 'Sue_is_Old' do
        t 'She is both Sue and old'
      end
    end

    workflow 'standard', ['logged' , 'Form Logged','completed', 'Form Completed','verifying',{:label => 'Form in validation',:validate => true}] do
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




# def_group_relations do
#   g 'start'
#   g 'demographic'
#   g 'history'
#   g 'pregnancy'
#   unless pregnancy_ended_before9
#     unless pregnancy_ended_before13
#       unless mom_died_AP
#         g 'intrapartum', :label => 'Labor & Birth'
#       end
#     end
#     if transferred_care(:any)
#       g 'transfer_of_care', :label => 'Transfer of Care'
#     end
#     if transported
#       g 'transport'
#     end
#     unless mom_died_AP
#       unless mom_died_IP
#         g 'postpartum_maternal', :label => 'Postpartum-Maternal'
#       end
#     end
#     unless pregnancy_ended_before20
#       g 'postpartum_newborn', :label => 'Postpartum-Newborn'
#     end
#   end
# end
# 
# g 'intrapartum', :constraints => {'must_be' => if_c([mom_died_AP || pregnancy_ended_before13],nil)}
# g 'transfer_of_care', :requires => transferred_care(:any) && !pregnancy_ended_before9
# g 'transport', :requires => transported && !pregnancy_ended_before9
# g 'postpartum_maternal', :requires => !mom_died_IP && !mom_died_AP && !pregnancy_ended_before9
# g 'postpartum_newborn', :requires => !pregnancy_ended_before20 && !pregnancy_ended_before9
#
# def_groups do
#   g 'start'
#   g 'demographic'
#   g 'history'
#   g 'pregnancy'
#   def_groups :constraints => {!pregnancy_ended_before9} do
#     g 'intrapartum', :requires => !mom_died_AP && !pregnancy_ended_before13 && !pregnancy_ended_before9
#     g 'transfer_of_care', :requires => transferred_care(:any) && !pregnancy_ended_before9
#     g 'transport', :requires => transported && !pregnancy_ended_before9
#     g 'postpartum_maternal', :requires => !mom_died_IP && !mom_died_AP && !pregnancy_ended_before9
#     g 'postpartum_newborn', :requires => !pregnancy_ended_before20 && !pregnancy_ended_before9
#   end
# end
# 
# 
#  
#    def pregnancy_ended_before9
#      v = field_value("Prg_LossBefore20Wk")
#      v && v != '' && v.to_i < 9
#    end
#
#    def pregnancy_ended_before13
#      v = field_value("Prg_LossBefore20Wk")
#      v && v != '' && v.to_i < 13
#    end
#
#    def pregnancy_ended_before20
#      v= field_value("Prg_LossBefore20_Flg")
#      v && v == 'Y'
#    end
#
#    def mom_died_AP
#      v= field_value("AP_MaternalDeath_Flg")
#      v && v == 'Y'
#    end
#
#    def mom_died_IP
#      v= field_value("IP_MaternalDeath_Flg")
#      v && v == 'Y'
#    end
#
#    def baby_dead_at_birth
#      v = field_value('Prg_LossAfter20_Flg')
#      v2 = field_value('IP_FetalDemise_Flg')
#      (v or v2) && (v == 'Y' or v2 == 'Y')
#    end
#
#    def consented
#      v = field_value("Book_ConsentHashCode")
#      v && v != nil
#  end