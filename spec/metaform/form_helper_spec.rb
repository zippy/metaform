require File.dirname(__FILE__) + '/../spec_helper'

describe FormHelper do
  before(:each) do
    @form = SimpleForm.new
    @record = Record.make(@form,'create',{:name =>'Bob Smith'})
    @form.set_record(@record)
    @form.set_render(:render)
  end
  
  it 'should create div html' do
    @form.div do
      @form.html "some div content"
    end
    @form.div(:id =>"my-div") do
      @form.html "other div content"
    end
    @form.get_body.should == ["<div>", "some div content", "</div>", "<div id='my-div'>", "other div content", "</div>"]
  end
  describe 'workflow_action button' do
    it 'should create default workflow_action buttons' do
      @form.workflow_action_button("Mark Form Completed", 'finish')
      @form.get_body.should == ["<div class='submit_form_button'>", "<input type=\"button\" value=\"Mark Form Completed\" onclick=\"this.disabled=true;$('meta_workflow_action').value = 'finish';$('metaForm').submit();\">", "</div>"]
    end
    it 'should create workflow_action buttons with options' do
      @form.workflow_action_button("Mark Form Completed", 'finish',:container_attrs => {'class' => 'my-submit-button'}, :button_attrs => {:css_class => 'centered'})
      @form.get_body.should == ["<div class='my-submit-button'>", "<input type=\"button\" value=\"Mark Form Completed\" class=\"centered\" onclick=\"this.disabled=true;$('meta_workflow_action').value = 'finish';$('metaForm').submit();\">", "</div>"]
    end
    it 'should create workflow_action button with loading spinner' do
      @form.workflow_action_button("Mark Form Completed", 'finish',:loading_img_id => 'my-spinner-id')
      @form.get_body.should == ["<div class='submit_form_button'>", "<input type=\"button\" value=\"Mark Form Completed\" onclick=\"this.disabled=true;$('my-spinner-id').show();$('meta_workflow_action').value = 'finish';$('metaForm').submit();\">", "<img alt=\"Loading\" id=\"my-spinner-id\" src=\"/images/loading.gif?1222090550\" style=\"display:none;\" />", "</div>"]
    end
  end
end
