require File.dirname(__FILE__) + '/../spec_helper'

describe Record do
  
  describe "(creating a new one)" do
    before(:each) do
      @record = Record.make('SampleForm','new_entry',{:name =>'Fred Smith'})
    end
    
    it "should return values via the [] operator" do
      @record[:name].should == 'Fred Smith'
    end
    
    it "should return values directly as attributes of the object" do
      @record.name.should == 'Fred Smith'
    end
    
    it "should return nil for un-initialized attributes" do
      @record.due_date.should == nil 
    end
    
    it "should complain when accessing an attribute that doesn't exist" do
      lambda { @record.fish }.should raise_error(NoMethodError)
    end
  end
  
  describe "(setting_fields without initializing index)" do
    
    before(:each) do
    @record = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    end
    
    it "should change a value when set via []" do
      @record.name.should == 'Fred Smith'
      @record[:name,nil].should == 'Fred Smith'  # the nil index is the default index
      @record.fruit.should == 'banana'
      @record[:name,nil]='Herbert Smith'
      @record[:fruit,1]='apple'
      @record.name.should == 'Herbert Smith'
      @record[:fruit,1] == 'apple'
      @record.save('new_entry') 
      nr = Record.locate(:first)
      nr.name.should == 'Herbert Smith'
      nr[:name].should == 'Herbert Smith'
      nr[:name,nil].should == 'Herbert Smith'
      nr[:fruit,1].should == 'apple'
    end
    
    it "should change a value when set via [] at two different indices" do
      @record.name.should == 'Fred Smith'
      @record[:name,1].should == nil
      @record[:name,1] = 'Sue Smith'
      @record.name.should == 'Fred Smith'
      @record[:name,1].should == 'Sue Smith'
      @record.save('new_entry')
      nr = Record.locate(:first)
      nr.name.should == 'Fred Smith'
      nr[:name,nil].should == 'Fred Smith'
      nr[:name,1].should == 'Sue Smith'
    end
    
    it "should change a value when set via attribute" do
      @record.name.should == 'Fred Smith'
      @record.name='Herbert Smith'
      @record.name.should == 'Herbert Smith'
      @record.save('new_entry') 
      nr = Record.locate(:first)
      nr.name.should == 'Herbert Smith'
      nr[:name].should == 'Herbert Smith'
      nr[:name,nil].should == 'Herbert Smith'
    end
    
    it "should change a value when set via attribute arrayable" do
      @record.name.should == 'Fred Smith'
      @record.name__1='Herbert Smith'
      @record.name__1.should == 'Herbert Smith'
      @record.save('new_entry') 
      nr = Record.locate(:first)
      nr.name__1.should == 'Herbert Smith'
      nr[:name,1].should == 'Herbert Smith'
    end
    
    it "should change a value and retain it after a save" do
      @record = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'},:index=>1)
      @record.save('new_entry')
      @record = Record.find(:first)
      @record.name__1.should == 'Fred Smith'
      @record.name__1 = "Joe Smith"
      @record.save('new_entry')
      @record = Record.find(:first)
      @record.name__1.should == 'Joe Smith'
    end
  end
  
  describe "(setting fields with initializing index)" do

    it "should correctly set fields when one index is initialized" do
      @record = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'},:index => 1)
      @record.name.should == nil
      @record.name__1.should == 'Fred Smith'
    end

    it "should correctly set fields when two indices are initialized" do
       @record = Record.make('SampleForm','new_entry', {
          2 => {:name =>'Fred Smith 2',:fruit => 'apple'},
          1 => {:name =>'Fred Smith 1',:fruit => 'banana'}
          },:multi_index => true)
        @record.name.should == nil
        @record.name__1.should == 'Fred Smith 1'
        @record.name__2.should == 'Fred Smith 2'
        @record.fruit.should == nil
        @record.fruit__1.should == 'banana'
        @record.fruit__2.should == 'apple'
    end
    
  end
  
  describe "(locating records)" do
    
    before(:each) do
      @records = []
      @records << Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
      @records << Record.make('SampleForm','new_entry',{:name =>'Joe Smith',:fruit => 'banana'})
      @records << Record.make('SampleForm','new_entry',{:name =>'Frank Smith',:fruit => 'pear'})
    end
    
    it "should correctly set, save and locate arrayable fields, each of nil index" do
      @records.each {|recs| recs.save('new_entry')}
      @nr = Record.locate(@records[0].id)
      @nr.name.should == @records[0].name
      Record.locate(:all,{:index => nil}).size.should == 3     
    end
    
    it "should correctly set, save and locate arrayable fields, of non-nil indices" do
      @records[0][:name,1] = 'Fred Smith 1'
      @records[1][:name,99] = 'Joe Smith 99'
      @records[2][:name,1] = 'Frank Smith 1'
      @records.each { |recs| recs.save('new_entry') }
      Record.locate(:all,{:index => 1}).size.should == 2
      Record.locate(:all,{:index => 99}).size.should == 1
      Record.locate(:all,{:index => nil}).size.should == 3
    end
    
    it "should correctly set, save and locate arrayable fields, with work_flow_state" do
      @records.last.workflow_state = 'fish'
      @records << Record.make('SampleForm','new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all)
      recs.size.should == 4
      Record.locate(:all,{:filters => ':fruit == "banana"'}).size.should == 3
      Record.locate(:all,{:filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.locate(:all,{:filters => ':name =~ /^F/'}).size.should == 2
      Record.locate(:all,{:workflow_state_filter => 'fish'}).size.should == 1
    end
    
  end 
  
  describe "(testing using fields with defaults set in form)"  do
    
    it "should correctly set values when the field has a default and when it doesn't" do
        @records = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
        @records.occupation.should == nil
        @records.occupation__1.should == nil

        @records.field_with_default.should == 'fish'
        @records.field_with_default__1.should == 'fish'

        @records.arrayable_field_no_default.should == nil
        @records.arrayable_field_no_default__1.should == nil
        @records.arrayable_field_no_default = 'dog'
        @records.arrayable_field_no_default__2.should == 'dog'
        @records.arrayable_field_no_default__1.should == nil  #should still be nil because it was already set

        @records.arrayable_field_with_default.should == 'cow'
        @records.arrayable_field_with_default__1.should == 'cow'
        @records.arrayable_field_with_default = 'cat'
        @records.arrayable_field_with_default__2.should == 'cat'
        @records.arrayable_field_with_default__1.should == 'cow' #should still be 'cow' because it was already set
      end
    
  end
end