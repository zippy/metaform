require File.dirname(__FILE__) + '/../spec_helper'

describe Record do
  
  describe "(creating a new one)" do
    before(:each) do
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith'})
    end
    
    it "should return values via the [] operator" do
      @record[:name].should == 'Bob Smith'
    end
    
    it "should return values directly as attributes of the object" do
      @record.name.should == 'Bob Smith'
    end
    
    it "should return nil for un-initialized attributes" do
      @record.due_date.should == nil 
    end
    
    it "should complain when accessing an attribute that doesn't exist" do
      lambda { @record.fish }.should raise_error(NoMethodError)
    end
  end
  
  describe "(indexed fields)" do
    before(:each) do
      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
      @record = Record.make('SampleForm','new_entry',@initial_values)
    end

    it "should work to use numerical indexes" do
      @record[:name,1]='Herbert Smith'
      @record.name__1.should == 'Herbert Smith'
      @record[:name,1].should == 'Herbert Smith'
      @record.name.should == 'Bob Smith'
    end 
    it "should work to use string indexes" do
      @record[:name,'x']='Herbert Smith'
      @record[:name,'y']='Frankfurt Smith'
      @record[:name,'x'].should == 'Herbert Smith'
      @record[:name,'y'].should =='Frankfurt Smith'
      @record.name__x.should == 'Herbert Smith'
      @record.name.should == 'Bob Smith'
    end 
    it "should save all types of indexes to the database" do
      @record[:name,9]='Name 9'
      @record[:name,'x']='Name x'
      @record[:name,'y']='Name y'
      @record.save('new_entry')
      nr = Record.locate(:first)
      nr[:name,9].should == 'Name 9'
      nr[:name,'x'].should == 'Name x'
      nr[:name,'y'].should =='Name y'
      nr.name.should == 'Bob Smith'
    end
    
  end
  describe "(setting_fields without initializing index)" do
    
    before(:each) do
    @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
    end
    
    it "should change a value when set via []" do
      @record.name.should == 'Bob Smith'
      @record[:name,nil].should == 'Bob Smith'  # the nil index is the default index
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
      @record.name.should == 'Bob Smith'
      @record[:name,1].should == nil
      @record[:name,1] = 'Sue Smith'
      @record.name.should == 'Bob Smith'
      @record[:name,1].should == 'Sue Smith'
      @record.save('new_entry')
      nr = Record.locate(:first)
      nr.name.should == 'Bob Smith'
      nr[:name,nil].should == 'Bob Smith'
      nr[:name,1].should == 'Sue Smith'
    end
    
    it "should change a value when set via attribute" do
      @record.name.should == 'Bob Smith'
      @record.name='Herbert Smith'
      @record.name.should == 'Herbert Smith'
      @record.save('new_entry') 
      nr = Record.locate(:first)
      nr.name.should == 'Herbert Smith'
      nr[:name].should == 'Herbert Smith'
      nr[:name,nil].should == 'Herbert Smith'
    end
    
    it "should change a value when set via attribute indexed" do
      @record.name.should == 'Bob Smith'
      @record.name__1='Herbert Smith'
      @record.name__1.should == 'Herbert Smith'
      @record.save('new_entry') 
      nr = Record.locate(:first)
      nr.name__1.should == 'Herbert Smith'
      nr[:name,1].should == 'Herbert Smith'
    end
    
    it "should change a value and retain it after a save" do
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'},:index=>1)
      @record.save('new_entry')
      @record = Record.find(:first)
      @record.name__1.should == 'Bob Smith'
      @record.name__1 = "Joe Smith"
      @record.save('new_entry')
      @record = Record.find(:first)
      @record.name__1.should == 'Joe Smith'
    end
  end
  
  describe "(multi-dimensional indexing)" do
    before(:each) do
      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
      @record = Record.make('SampleForm','new_entry',@initial_values)
    end
    
    it "should be able to set and retrieve a two dimensional index" do
      @record[:name,1] = 'Sue Smith'
      @record[:name,1,2] = 'Jane Smith'
      @record.name.should == 'Bob Smith'
      @record.name__1.should == 'Sue Smith'
      @record[:name,1].should == 'Sue Smith'
      @record[:name,1,2].should == 'Jane Smith'
      @record.save('new_entry')
      nr = Record.locate(:first)
      nr.name.should == 'Bob Smith'
      nr[:name,nil].should == 'Bob Smith'
      nr[:name,1].should == 'Sue Smith'
      nr[:name,1,2].should == 'Jane Smith'
    end
  end
  
  describe "(setting fields with initializing index)" do

    it "should correctly set fields when initializing with :index option" do
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'},:index => 1)
      @record.name.should == nil
      @record.name__1.should == 'Bob Smith'
    end

    it "should correctly set fields when initializing with :multi_index option" do
       @record = Record.make('SampleForm','new_entry', {
          2 => {:name =>'Bob Smith 2',:fruit => 'apple'},
          1 => {:name =>'Bob Smith 1',:fruit => 'banana'}
          },:multi_index => true)
        @record.name.should == nil
        @record.name__1.should == 'Bob Smith 1'
        @record.name__2.should == 'Bob Smith 2'
        @record.fruit.should == nil
        @record.fruit__1.should == 'banana'
        @record.fruit__2.should == 'apple'
    end
    
  end
  
  describe "(locating records)" do
    
    before(:each) do
      @records = []
      @records << Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records << Record.make('SampleForm','new_entry',{:name =>'Joe Smith',:fruit => 'banana'})
      @records << Record.make('SampleForm','new_entry',{:name =>'Frank Smith',:fruit => 'pear'})
    end
    
    it "should correctly set, save and locate indexed fields, each of nil index" do
      @records.each {|recs| recs.save('new_entry')}
      @nr = Record.locate(@records[0].id)
      @nr.name.should == @records[0].name
      Record.locate(:all,{:index => nil}).size.should == 3     
    end
    
    it "should correctly set, save and locate indexed fields, of non-nil indices" do
      @records[0][:name,1] = 'Bob Smith 1'
      @records[1][:name,99] = 'Joe Smith 99'
      @records[2][:name,1] = 'Frank Smith 1'
      @records.each { |recs| recs.save('new_entry') }
      Record.locate(:all,{:index => 1}).size.should == 2
      Record.locate(:all,{:index => 99}).size.should == 1
      Record.locate(:all,{:index => nil}).size.should == 3
    end
    
    it "should correctly set, save and locate fields with filters and, with work_flow_state_filters" do
      @records.last.workflow_state = 'fish'
      @records << Record.make('SampleForm','new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all)
      recs.size.should == 4
      Record.locate(:all,{:filters => ':fruit == "banana"'}).size.should == 3
      Record.locate(:all,{:filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.locate(:all,{:filters => ':name =~ /o/'}).size.should == 3
      Record.locate(:all,{:workflow_state_filter => 'fish'}).size.should == 1
    end

    it "should correctly set, save and locate indexed fields with complex filters" do
      @records[0].fruit__1 = 'carrot'
      @records[2].fruit__1 = 'carrot'
      @records[0].occupation = 'cat_catcher'
      @records[0].occupation__1 = 'snoozer'
      @records[1].occupation = 'unemployed'
      @records.each { |recs| recs.save('new_entry') }
      Record.locate(:all,{:index => :any,:filters => ':fruit.include?("carrot")'}).size.should == 2
      Record.locate(:all,{:index => :any,:filters => ':occupation.count >1'}).size.should == 1
    end
    
    it "should be able to retrieve the results as an answers hash" do
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all,{:return_answers_hash => true})
      recs.size.should == 3
      r = recs[0]
      r.instance_of?(Hash).should == true
      r['name'].instance_of?(Record::Answer).should == true
    end
    
    it "should handle mult-dimensional indexing" do
      @records[0].fruit__1 = 'peach'
      @records[0].fruit__2 = 'kiwi'
      @records[0][:fruit,2,1] = 'orange'
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all,{:index => :any,:return_answers_hash => true})
      r = recs[0]
      r['fruit']['1'].should == 'peach'
      r['fruit'][2].should == 'kiwi'
      r['fruit'][2,1].should == 'orange'
      r['fruit'].should == [['banana',nil],['peach',nil],['kiwi','orange']]
    end
    
  end 
  
  describe "(testing using fields with defaults set in form)"  do
    
    it "should correctly set values when the field has a default and when it doesn't" do
        @records = Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
        @records.occupation.should == nil
        @records.occupation__1.should == nil

        @records.field_with_default.should == 'fish'
        @records.field_with_default__1.should == 'fish'

        @records.indexed_field_no_default.should == nil
        @records.indexed_field_no_default__1.should == nil
        @records.indexed_field_no_default = 'dog'
        @records.indexed_field_no_default__2.should == 'dog'
        @records.indexed_field_no_default__1.should == nil  #should still be nil because it was already set

        @records.indexed_field_with_default.should == 'cow'
        @records.indexed_field_with_default__1.should == 'cow'
        @records.indexed_field_with_default = 'cat'
        @records.indexed_field_with_default__2.should == 'cat'
        @records.indexed_field_with_default__1.should == 'cow' #should still be 'cow' because it was already set
      end
    
  end
end