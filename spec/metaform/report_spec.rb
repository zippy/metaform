require File.dirname(__FILE__) + '/../spec_helper'

describe Reports do  
  describe "using sample form as 'schema'" do
    before(:each) do
      Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Oliver Smith',:fruit => 'banana', :occupation => 'game_designer'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Steve Smith', :occupation => ''}).save('new_entry')
      r = Record.make(SampleForm.new,'new_entry',{:name =>'Emma Smith',:occupation => 'scientist'})
      r[:occupation,1] = 'painter'
      r.save('new_entry')
      r[:occupation,1] = 'farmer'
      r.occupation__2 = 'painter'
      r.save('new_entry')
    
      @report = Stats.get_report('fruits')
    end
    it "should report a count of 2 bananas" do
      @report.bananas.should == 2
    end

    it "should report 2 apples" do
      @report.apples.should == 2
    end

    it "should report 2 nil fruits, even when field instances don't exist" do
      FieldInstance.find(:all,:conditions => "field_id = 'fruit'").size.should == 4
      FormInstance.find(:all).size.should == 6
      
      @report.null_fruits.should == 2
    end
  
    it "should report 1 painter" do
      @report.painters.should == 1
    end

    it "should report 3 slackers" do
      @report.slackers.should == 3
    end  
  
    it "should report four painters or slackers" do
      @report.painters_or_slackers.should == 4
    end
  
    it "should report one person who has an occupation other than painter or slacker" do
      @report.other_than_painter_or_slacker.should == 1
    end
  end

  describe "using filters" do
    before(:each) do
      Record.make(SampleForm.new,'new_entry',{:name =>'Frank Lazy',:fruit => 'kiwi',:occupation => 'worker'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Lizy Lazy',:fruit => 'kiwi',:occupation => 'unemployed'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Mark Fish',:fruit => 'mango',:occupation => 'unemployed'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Herb Jones',:fruit => 'kiwi',:occupation => 'worker'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'worker'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'worker'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'worker'}).save('new_entry')
      Record.make(SampleForm.new,'new_entry',{:name =>'Jane Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    end

    it "should pre-filter with sql" do
      @report = Stats.get_report('fruits')
      @report.kiwis.should == 3
      @report = Stats.get_report('fruits',:sql_prefilters => ":occupation = 'worker'")
      @report.kiwis.should == 2
    end

    it "should filter out desired entries for field not being counted" do
      filters = [':name != "Bob Smith"']
      @report = Stats.get_report('fruits',:filters => filters)
      @report.bananas.should == 1
    end

    it "should filter out desired entries for field being counted" do
      filters = [':fruit =~ /mutsu/']
      @report = Stats.get_report('fruits',:filters => filters)
      @report.apples.should == 1
    end

    it "should not count items in the wrong workflow state" do
      @records = []
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records.last.workflow_state = 'standard'
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
      @records.each { |recs| recs.save('new_entry') }
      @report_workflow = Stats.get_report('report_with_workflow')
      @report_workflow.bobs.should == 1
    end

    it "should count items in any of the filtered workflow states" do
      @records = []
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records.last.workflow_state = 'standard'
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
      @records.last.workflow_state = 'unusual'
      @records.each { |recs| recs.save('new_entry') }
      @report_workflow = Stats.get_report('report_with_2_workflows')
      @report_workflow.bobs.should == 2
    end

    it "should count items in any of the filtered workflow states, when workflow state filter is a regex" do
      @records = []
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records.last.workflow_state = 'standard_1'
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Fox',:fruit => 'pear'})
      @records.last.workflow_state = 'standard_2'
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Jones',:fruit => 'pear'})
      @records.last.workflow_state = 'unusual'
      @records.each { |recs| recs.save('new_entry') }
      @report_workflow = Stats.get_report('report_with_workflow')
      #puts "@report_workflow = #{@report_workflow.inspect}"
      @report_workflow.bobs.should == 2
    end

    it "should be abele to count items with indexed values with nils" do
      @records = []
      @records << r = Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Herb Smith',:fruit => 'apple',:prev_preg_outcome=> 'happy',:prev_preg_value=> 'some_val'})
      @records.each { |recs| recs.save('new_entry') }
      r.update_attributes({
          0 => {:prev_preg_flag => 'Y',:prev_preg_REF => 1, :prev_preg_outcome => 'happy'},
          1 => {:prev_preg_REF => 1, :prev_preg_outcome => 'happy',:prev_preg_value=> 'some_val'},
          2 => {:prev_preg_REF => 1, :prev_preg_outcome => 'sad'},
          3 => {:prev_preg_REF => 1, :prev_preg_outcome => 'sad',:prev_preg_value=> 'some_val'},
          4 => {:prev_preg_REF => 1, :prev_preg_outcome => 'happy'}
          },
            'indexed_presentation_by_flag',nil,:multi_index => true)
      @report = Stats.get_report('pregnancies')
      @report.happy_no_val_pregs.should == 2
    end

  end
end