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
      nr = Record.locate(:first, :index => :any)
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
      nr = Record.locate(:first, :index => :any)
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
      nr = Record.locate(:first, :index => :any)
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
      nr = Record.locate(:first, :index => :any)
      nr.name__1.should == 'Herbert Smith'
      nr[:name,1].should == 'Herbert Smith'
    end
    
    it "should change a value and retain it after a save" do
      @record = Record.make('SampleForm','new_entry',{:name =>'Bob Smith',:fruit => 'banana'},:index=>1)
      @record.save('new_entry')
      @record = Record.find(:first, :index => :any)
      @record.name__1.should == 'Bob Smith'
      @record.name__1 = "Joe Smith"
      @record.save('new_entry')
      @record = Record.find(:first, :index => :any)
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
      @record[:name,1,nil].should == 'Sue Smith'
      @record[:name,1,2].should == 'Jane Smith'
      @record[:name,1,3] = 'Scott Smith'
      @record.save('new_entry')
      nr = Record.locate(:first, :index => :any)      
      nr.name.should == 'Bob Smith'
      nr[:name,nil].should == 'Bob Smith'
      nr[:name,1].should == 'Sue Smith'
      nr[:name,1,2].should == 'Jane Smith'
      nr[:name,1,3].should == 'Scott Smith'
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
#      recs = Record.locate(:all)
#      recs.size.should == 4
      Record.locate(:all,{:filters => ':fruit == "banana"'}).size.should == 3
      Record.locate(:all,{:filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.locate(:all,{:filters => ':name =~ /o/'}).size.should == 3
      Record.locate(:all,{:workflow_state_filter => 'fish'}).size.should == 1
      Record.locate(:all,{:workflow_state_filter => 'cow'}).size.should == 0
      Record.locate(:all,{:workflow_state_filter => ['fish','cow']}).size.should == 1
      Record.locate(:all,{:workflow_state_filter => ['cow']}).size.should == 0
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
    
    it "should return indexed fields as arrays in the answers hash" do
      @records[0].fruit__1 = 'peach'
      @records[0].fruit__2 = 'kiwi'
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all,{:index => :any,:return_answers_hash => true})
      r = recs[0]
      r['fruit'][0].should == 'banana'
      r['fruit'][1].should == 'peach'
      r['fruit'][2].should == 'kiwi'
      r['fruit'].value.should == ['banana','peach','kiwi']
    end
    
    it "should return multi-dimentional indexes as arrays of arrays in the answers hash" do
      @records[0].fruit__1 = 'peach'
      @records[0].fruit__2 = 'kiwi'
      @records[0][:fruit,2,1] = 'orange'
      @records.each { |recs| recs.save('new_entry') }
      recs = Record.locate(:all,{:index => :any,:return_answers_hash => true})
      r = recs[0]
      r['fruit'].value.should == [['banana'],['peach'],['kiwi','orange']]
      r['fruit'][1].should == ['peach']
      r['fruit'][2].should == ['kiwi','orange']
      r['fruit'][2,1].should == 'orange'
    end
    
    it "should return multi-dimentional indexes as arrays of arrays in the answers hash with second index > 1" do
      @record = Record.make('SampleForm','new_entry')
      @record[:fruit,2,1] = 'orange'
      @record[:fruit,2,2] = 'kiwi'
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
      nr['fruit'].value.should == [[],[],[nil,'orange','kiwi']]
      nr['fruit'][2].should == [nil,'orange','kiwi']
      nr['fruit'][2,1].should == 'orange'
    end
    
    
    it "should get highest index array when the answer is multi-dimensional" do
      @record = Record.make('SampleForm','new_entry')
      @record[:breastfeeding,2,1] = 'A'
      @record[:breastfeeding,2,2] = 'a'
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
      nr['breastfeeding'][2].should == [nil,'A','a']
      nr['breastfeeding'][2,1].should == 'A'
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
  
  describe "(testing last_answer)" do
    it "should get highest index value of field"  do
       @record = Record.make('SampleForm','new_entry')
       @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
       @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
       @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
       @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
       @record.save('new_entry')
       nr = Record.locate(:first, :index => :any)
       nr.last_answer("breastfeeding").should == 'D'
    end
    
    
    it "should get the highest index non-nil value of a field" do
      @record = Record.make('SampleForm','new_entry')
      @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
      @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
      @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
      @record[:breastfeeding,3] = nil  #Only one baby, fourth PP visit
      @record.save('new_entry')
      nr = Record.locate(:first, :index => :any)
      nr.last_answer("breastfeeding").should == 'C'
    end    
  
    it "should get highest index array when the answer is multi-dimensional" do
       @record = Record.make('SampleForm','new_entry')
       @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
       @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
       @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
       @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
       @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
       @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
       @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
       @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
       @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
       @record.save('new_entry')
       nr = Record.locate(:first, :index => :any)    
       nr.last_answer("breastfeeding").should == [nil,'C','c','3']
     end
   
     it "should get highest index value when the answer is multi-dimensional and an index is passed in" do
        @record = Record.make('SampleForm','new_entry')
        @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
        @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
        @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
        @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
        @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
        @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
        @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
        @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
        @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        @record.save('new_entry')
        nr = Record.locate(:first, :index => :any)    
        nr.last_answer("breastfeeding",2).should == 'c'
      end
    
      it "should get highest index non-nil value when the answer is multi-dimensional and an index is passed in" do
         @record = Record.make('SampleForm','new_entry')
         @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
         @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
         @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
         @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
         @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
         @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
         @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
         # @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
         @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
         @record.save('new_entry')
         nr = Record.locate(:first, :index => :any)    
         nr.last_answer("breastfeeding",2).should == 'b'
       end
     end    
  
  describe "(testing answer_num)" do
    it "should return 1 when that number of matches answers for a given field"  do
       @record = Record.make('SampleForm','new_entry')
       @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
       @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
       @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
       @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
       @record.save('new_entry')
       nr = Record.locate(:first, :index => :any)
       nr.answer_num("breastfeeding",'B').should == 1
    end
    
    it "should return 2 when that number of matches answers for a given field"  do
       @record = Record.make('SampleForm','new_entry')
       @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
       @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
       @record[:breastfeeding,2] = 'B'  #Only one baby, third PP visit
       @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
       @record.save('new_entry')
       nr = Record.locate(:first, :index => :any)
       nr.answer_num("breastfeeding",'B').should == 2
    end
    
    it "should return 1 when that is the correct number of matching arrays and the answer is multi-dimensional" do
       @record = Record.make('SampleForm','new_entry')
       @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
       @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
       @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
       @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
       @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
       @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
       @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
       @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
       @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
       @record.save('new_entry')
       nr = Record.locate(:first, :index => :any)    
       nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 1
     end
     
     it "should return 2 when that is the correct number of matching arrays and the answer is multi-dimensional" do
        @record = Record.make('SampleForm','new_entry')
        @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
        @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
        @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
        @record[:breastfeeding,2,1] = 'A'    #Three babies, second PP visit, first baby
        @record[:breastfeeding,2,2] = 'a'    #Three babies, second PP visit, second baby
        @record[:breastfeeding,2,3] = '1'    #Three babies, second PP visit, third baby
        @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
        @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
        @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        @record.save('new_entry')
        nr = Record.locate(:first, :index => :any)    
        nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 2
      end
   
     it "should get return 1 when there is 1 matching answer for the given index and the answer is multi-dimensional and an index is passed in" do
          @record = Record.make('SampleForm','new_entry')
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
          @record.save('new_entry')
          nr = Record.locate(:first, :index => :any)    
          nr.answer_num("breastfeeding",'b',2).should == 1
        end
        
        it "should get return 2 when there are 2 matching answers for the given index and the answer is multi-dimensional and an index is passed in" do
             @record = Record.make('SampleForm','new_entry')
             @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
             @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
             @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
             @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
             @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
             @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
             @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
             @record[:breastfeeding,3,2] = 'b'    #Three babies, third PP visit, second baby
             @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
             @record.save('new_entry')
             nr = Record.locate(:first, :index => :any)    
             nr.answer_num("breastfeeding",'b',2).should == 2
        end
   end
  

end

describe Record::Answer do
  it "should create with value initializer" do
    a = Record::Answer.new('some_value')
    a.value.should == 'some_value'
    a.is_indexed?.should == false
  end

  it "should create with value and index initializer" do
    a = Record::Answer.new('some_value',2)
    a.value.should == [nil,nil,'some_value']
    a.is_indexed?.should == true
    a[0].should == nil
    a[1].should == nil
    a[2].should == 'some_value'
  end

  it "should set value" do
    a = Record::Answer.new('some_value')
    a.value.should == 'some_value'
    a.value = 'other_value'
    a.value.should == 'other_value'
  end

  it "should set indexed values" do
    a = Record::Answer.new('some_value')
    a.value.should == 'some_value'
    a[2] = 'other_value'
    a.value.should == ['some_value',nil,'other_value']
    a[0].should == 'some_value'
    a[1].should == nil
    a[2].should == 'other_value'
  end

  it "should handle multi-dimensional indexs" do
    a = Record::Answer.new('some_value')
    a.value.should == 'some_value'
    a[2,1] = 'other_value'
    a.value.should == [['some_value'],[],[nil,'other_value']]
    a[0].should == ['some_value']
    a[1].should == []
    a[2].should == [nil,'other_value']
    a[2,1].should == 'other_value'
    a[0,1].should == nil
    a[0,0].should == 'some_value'
  end

end