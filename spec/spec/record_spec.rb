require File.dirname(__FILE__) + '/../spec_helper'

describe Record do
  def setup_record(index = nil)
    @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
    @form = SampleForm.new
    @record = Record.make(@form,'new_entry',@initial_values,{:index => index})
    @form.set_record(@record)
  end
  describe "-- creating a new one" do
    before(:each) do
      setup_record
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
    
    it "should provide access to the form" do
      @record.form.should == @form
    end
  end

  describe "-- workflow" do
    before(:each) do
      setup_record
    end
    it "should provide access to the workflow state label" do
      @record.workflow_state = 'verifying'
      @record.workflow_state_label.should == 'Form in validation'
    end
  end    
    
  describe "-- indexed fields" do
    before(:each) do
      setup_record
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
      nr.name.should == 'Bob Smith'
      nr[:name,9].should == 'Name 9'
      nr[:name,'x'].should == 'Name x'
      nr[:name,'y'].should =='Name y'
    end
    
    it "should be able to return an answers hash" do
      @record[:name,1]='Herbert Smith'
      @record[:name,5]='Squid Smith'
      a = Record::Answer.new("Bob Smith",nil)
      a[1] = 'Herbert Smith'
      answers = @record.answers_hash(:name)
      answer = answers['name']
      answer.count == 3
      answer[0].should == 'Bob Smith'
      answer[1].should == 'Herbert Smith'
      answer[5].should == 'Squid Smith'
    end
    
    it "should be able to return all indexes" do
      @record[:name,1]='Herbert Smith'
      @record[:name,5]='Squid Smith'
      @record.save('new_entry')
      @record[:name,:any].should == ['Bob Smith','Herbert Smith','Squid Smith']
    end

    it "should be able to clear indexes on update" do
      @record[:name,1]='Herbert Smith'
      @record[:name,5]='Squid Smith'
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any})
      nr.update_attributes({:name => 'John Doe'},'new_entry',nil,:clear_indexes =>['name'])
      @record[:name,:any].should == ['John Doe']
    end

  end
  describe "-- setting_fields without initializing index" do
    
    before(:each) do
      setup_record
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
      setup_record(1)
      @record.save('new_entry')
      @record = Record.find(:first, :index => :any)
      @record.name__1.should == 'Bob Smith'
      @record.name__1 = "Joe Smith"
      @record.save('new_entry')
      @record = Record.find(:first, :index => :any)
      @record.name__1.should == 'Joe Smith'
    end
  end
  
  describe "-- multi-dimensional indexing" do
    before(:each) do
      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',@initial_values)
      @form.set_record(@record)
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
  
  describe "-- setting fields with initializing index" do

    it "should correctly set fields when initializing with :index option" do
      @record = Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'},:index => 1)
      @record.name.should == nil
      @record.name__1.should == 'Bob Smith'
    end

    it "should correctly set fields when initializing with :multi_index option" do
       @record = Record.make(SampleForm.new,'new_entry', {
          2 => {:name =>'Bob Smith 2',:fruit => 'apple'},
          1 => {:name =>'Bob Smith 1',:fruit => 'banana'},
          0 => {:name =>'Bob Smith 0'}
          },:multi_index => true)
        @record.name.should == 'Bob Smith 0'
        @record.name__1.should == 'Bob Smith 1'
        @record.name__2.should == 'Bob Smith 2'
        @record.fruit.should == nil
        @record.fruit__1.should == 'banana'
        @record.fruit__2.should == 'apple'
    end
    
  end
  
  describe "-- deleting record fields" do
    before(:each) do
      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',@initial_values)
      @form.set_record(@record)
      @record.save('new_entry')
      @record['occupation'] = 'bum'
    end
    it "should delete specified fields" do
      @record.delete_fields('name')
      @nr = @record
      @nr.name.should == nil
      @nr.fruit.should == 'banana'
      @nr.occupation.should == 'bum' #and not delete other things in the attributes cache
    end

    it "should delete all but the specified fields" do
      @record.delete_fields_except('name')
      @nr = @record
      @nr.name.should == 'Bob Smith'
      @nr.fruit.should == nil
      @nr.occupation.should == nil #and also delete other things in the attributes cache
    end
  end
  
  describe "-- loading data" do
    before(:each) do
      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',@initial_values)
      @record[:name,1] = 'Sue Smith'
      @form.set_record(@record)
      @record.save('new_entry')
    end
    it "should be possbile to reset the cached attribute data" do
      @record.reset_attributes
      @record.get_attributes.should == {nil=>{}}
    end
    it "should be possbile to load specific attributes" do
      @record.load_attributes(['name'])
      @record.get_attributes.should == {nil=>{}, "0"=>{"name"=>"Bob Smith"}}
    end
    it "should be possbile to load specific attributes by index" do
      @record.load_attributes(['name'],1)
      @record.get_attributes.should == {nil=>{}, "1"=>{"name"=>"Sue Smith"}}
    end
    it "should be possbile to load all indexes of the given attributes" do
      @record.load_attributes(['name'],:any)
      @record.get_attributes.should == {nil=>{"name"=>"Bob Smith"}, "1"=>{"name"=>"Sue Smith"}}
    end
  end
  
  describe "-- locating records" do
    
    before(:each) do
      @records = []
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'banana'})
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Frank Smith',:fruit => 'pear'})
    end
    
    it "should correctly set, save and locate indexed fields, each of nil index" do
      @records.each {|recs| recs.form.set_record(recs);recs.save('new_entry')}
      @nr = Record.locate(@records[0].id)
      @nr.name.should == @records[0].name
      Record.locate(:all,{:index => nil}).size.should == 3     
    end
    
    it "should correctly set, save and locate indexed fields, of non-nil indices" do
      @records[0][:name,1] = 'Bob Smith 1'
      @records[1][:name,99] = 'Joe Smith 99'
      @records[2][:name,1] = 'Frank Smith 1'
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      Record.locate(:all,{:index => 1}).size.should == 2
      Record.locate(:all,{:index => 99}).size.should == 1
      Record.locate(:all,{:index => nil}).size.should == 3
    end
    
    it "should correctly set, save and locate fields with filters and, with work_flow_state_filters" do
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      @records.last.workflow_state = 'logged'
      @records.last.save('update_entry')#      recs = Record.locate(:all)
#      recs.size.should == 4
      Record.locate(:all,{:filters => ':fruit == "banana"'}).size.should == 3
      Record.locate(:all,{:filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.locate(:all,{:filters => ':name =~ /o/'}).size.should == 3
      Record.locate(:all,{:workflow_state_filter => 'logged'}).size.should == 1
      Record.locate(:all,{:workflow_state_filter => 'verified'}).size.should == 0
      Record.locate(:all,{:workflow_state_filter => ['logged','verified']}).size.should == 1
      Record.locate(:all,{:workflow_state_filter => ['verified']}).size.should == 0
    end

    it "should correctly set, save and locate indexed fields with complex filters" do
      @records[0].fruit__1 = 'carrot'
      @records[2].fruit__1 = 'carrot'
      @records[0].occupation = 'cat_catcher'
      @records[0].occupation__1 = 'snoozer'
      @records[1].occupation = 'unemployed'
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      Record.locate(:all,{:index => :any,:filters => ':fruit.include?("carrot")'}).size.should == 2
      Record.locate(:all,{:index => :any,:filters => ':occupation.count >1'}).size.should == 1
    end
        
    it "should be able to retrieve the results as an answers hash" do
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      recs = Record.locate(:all,{:return_answers_hash => true})
      recs.size.should == 3
      r = recs[0]
      r.instance_of?(Hash).should == true
      r['name'].instance_of?(Record::Answer).should == true
    end
    
    it "should return indexed fields as arrays in the answers hash" do
      @records[0].fruit__1 = 'peach'
      @records[0].fruit__2 = 'kiwi'
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
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
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      recs = Record.locate(:all,{:index => :any,:return_answers_hash => true})
      r = recs[0]
      r['fruit'].value.should == [['banana'],['peach'],['kiwi','orange']]
      r['fruit'][1].should == ['peach']
      r['fruit'][2].should == ['kiwi','orange']
      r['fruit'][2,1].should == 'orange'
    end
    
    it "should return multi-dimentional indexes as arrays of arrays in the answers hash with second index > 1" do
      @record = Record.make(SampleForm.new,'new_entry')
      @record[:fruit,2,1] = 'orange'
      @record[:fruit,2,2] = 'kiwi'
      @record.form.set_record(@record);
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
      nr['fruit'].value.should == [[],[],[nil,'orange','kiwi']]
      nr['fruit'][2].should == [nil,'orange','kiwi']
      nr['fruit'][2,1].should == 'orange'
    end
    
    
    it "should get highest index array when the answer is multi-dimensional" do
      @record = Record.make(SampleForm.new,'new_entry')
      @record[:breastfeeding,2,1] = 'A'
      @record[:breastfeeding,2,2] = 'a'
      @record.form.set_record(@record);
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
      nr['breastfeeding'][2].should == [nil,'A','a']
      nr['breastfeeding'][2,1].should == 'A'
    end
    
  end 
  
  describe "-- defaults options"  do
    it "should correctly set values when the field has a default and when it doesn't" do
      @records = Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana'})
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
  
  describe "indexing utility methods" do
    before(:each) do
      @record = Record.make(SampleForm.new,'new_entry')
    end
    def after_init_save_and_get_from_locate
      yield if block_given?
      @record.save('new_entry')
      nr = Record.locate(:first, :index => :any)
    end

    describe "#last_answer" do
      it "should return nil when no matching records will be found within last_answer"  do
        nr = after_init_save_and_get_from_locate
        Record.locate(nr.id,:index => :any,:fields => ['breastfeeding'], :return_answers_hash => true).should == nil
        nr.last_answer("breastfeeding").should == nil
      end
      it "should get highest index value of field"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.last_answer("breastfeeding").should == 'D'
      end
      it "should get the highest index non-nil value of a field" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = nil  #Only one baby, fourth PP visit
        end
        nr.last_answer("breastfeeding").should == 'C'
      end    
      it "should get highest index array when the answer is multi-dimensional" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.last_answer("breastfeeding").should == [nil,'C','c','3']
      end
      it "should get highest index value when the answer is multi-dimensional and an index is passed in" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.last_answer("breastfeeding",2).should == 'c'
      end
      it "should get highest index non-nil value when the answer is multi-dimensional and an index is passed in" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          # @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.last_answer("breastfeeding",2).should == 'b'
      end
    end    
  
    describe "#answer_num" do
      it "should return nil when no matching records will be found within answer_num"  do
        nr = after_init_save_and_get_from_locate
        Record.locate(nr.id,:index => :any,:fields => ['breastfeeding'], :return_answers_hash => true).should == nil
        nr.answer_num("breastfeeding",'Z').should == nil
      end

      it "should return 0 when there are no matching answers for a given field"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.answer_num("breastfeeding",'Z').should == 0
      end

      it "should return 1 when that number of matches answers for a given field"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.answer_num("breastfeeding",'B').should == 1
      end

      it "should return 2 when that number of matches answers for a given field"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'B'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.answer_num("breastfeeding",'B').should == 2
      end

      it "should return 1 when that is the correct number of matching arrays and the answer is multi-dimensional" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 1
      end

      it "should return 2 when that is the correct number of matching arrays and the answer is multi-dimensional" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'A'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'a'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '1'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 2
      end

      it "should get return 1 when there is 1 matching answer for the given index and the answer is multi-dimensional and an index is passed in" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.answer_num("breastfeeding",'b',2).should == 1
      end

      it "should get return 2 when there are 2 matching answers for the given index and the answer is multi-dimensional and an index is passed in" do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
          @record[:breastfeeding,3,2] = 'b'    #Three babies, third PP visit, second baby
          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
        end
        nr.answer_num("breastfeeding",'b',2).should == 2
      end
    end
  end

  describe "-- calculated fields" do
    before(:each) do
      #TODO- think about this.  Record needs to have the form prepared for build... hmmmm...
      @initial_values = {:name =>'Bob Smith',:occupation => 'Boss'}
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',@initial_values)
      @form.set_record(@record)
#      @form = FormProxy.new('SampleForm'.gsub(/ /,'_'))
#      SampleForm.prepare_for_build(@record,@form,nil)
    end
    it "should do the calculation when accessed" do
      @form.with_record(@record) do
        @record.reverse_name_and_job.should == "ssoBhtimS boB"
      end
    end
    it "should raise and exception if you try to store a value it" do
      lambda {
       @record.reverse_name_and_job = "fred"
      }.should raise_error("you can't store a value to a calculated field")
    end
  end
  
  describe "-- explanations" do
    before(:each) do
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',{:name =>'Bob Smith'})
      @record.save('new_entry')
    end
    it "should return a nil explanation from a newly initialzed record" do
      @record.explanation(:name).should == nil
    end
    it "should return a the explanation after being set" do
      @record.set_explanation(:name, 'unknown')
      @record.explanation(:name).should == 'unknown'
    end
  end

  describe "-- timestamping" do
    before(:each) do
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',{:name =>'Bob Smith'})
      @record.save('new_entry')
    end
    it "should set the created date on creation" do
      @record.created_at.to_s.should == Time.now.to_s
    end
    it "should set the updated date on creation" do
      @record.updated_at.to_s.should == Time.now.to_s
    end
    it "should set the updated date on save" do
      now_seconds = Time.now.to_i
      Kernel::sleep 2
      @record.name = "Billy"
      @record.save('new_entry')
      nr = Record.locate(:first, :index => :any)
      nr.updated_at.to_i.should == now_seconds+2
    end
  end

  describe "-- timestamped updating" do
    before(:each) do
      setup_record
    end
    it "should allow saveing fields if timestamp is latest" do
      @record.save('new_entry')
      t = @record.updated_at.to_i
      @record.update_attributes({:name => 'Fred'},'new_entry',{:last_updated => t}).should == {"name"=>"Fred"}
    end
    it "should prevent overwriting of the same field when using timestamped updating but allow setting of fields that haven't been set and updating of older fields" do
      t = @record.updated_at.to_i  #get the timestamp from the first record
      Kernel::sleep 2
      @record.name = "Joe"
      @record.save('new_entry')
      lambda {@record.update_attributes({:name => 'Fred',:fruit=>'banana',:education => 'lots'},'new_entry',{:last_updated => t})}.should raise_error('Some field(s) were not saved: ["name"]')
      @record.education.should == 'lots'
      @record.fruit.should == 'banana'
    end
  end
  describe "-- validation" do
    before(:each) do
      setup_record
      @record.education = '99'
      @record.save('new_entry')      
      @id = @record.id
    end
    it "should set the field instance state to 'answered' for valid fields" do
      f = FieldInstance.find(:first,:conditions => ['form_instance_id = ? and field_id == "name"',@id])
      f.state.should == 'answered'
    end
    it "should set the field instance state to 'invalid' for invalid fields" do
      f = FieldInstance.find(:first,:conditions => ['form_instance_id = ? and field_id == "education"',@id])
      f.state.should == 'invalid'
    end
    it "should set the field instance state to 'explained' for fields with an explanation" do
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => 'has studied forever'}})
      f = FieldInstance.find(:first,:conditions => ['form_instance_id = ? and field_id == "education"',@id])
      f.state.should == 'explained'
      f.explanation.should == 'has studied forever'
    end
    describe "helper methods" do
      describe "_validate_attributes" do
        it "should calculate validation of current attributes" do
          @record.name = nil
          @record._validate_attributes.should == {"name"=>[["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
        end
        it "should alculate validation of current attributes selected from the given list" do
          @record.name = nil
          @record._validate_attributes(['name']).should == {"name"=>[["This information is required"]]}
        end
        it "should calculate validation of current attributes when they are at non-zero indexes" do
          @record['name',1] = nil
          @record._validate_attributes(['name']).should == {"name"=>[nil, ["This information is required"]]}
        end
      end
      describe "_merge_invalid_fields" do
        it "should merge validation data with nil index" do
          vd = {'_'=>{"education"=>[["Answer must be between 0 and 14"]]}}
          @record._merge_invalid_fields(vd,['name'],{"name"=>[["This information is required"],["This information is required"]]}).should ==
            {"name"=>[["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
        end
        it "should merge validation data with non-nil index" do
          vd = {'_'=>{"education"=>[["Answer must be between 0 and 14"]]}}
          @record._merge_invalid_fields(vd,['name'],{"name"=>[["This information is required"],["This information is required"]]},1).should ==
            {"name"=>[nil,["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
        end
        it "should merge validation data with :any index" do
          vd = {'_'=>{"education"=>[["Answer must be between 0 and 14"]]}}
          @record._merge_invalid_fields(vd,['name'],{"name"=>[["This information is required"],["This information is required"]]},:any).should ==
            {"name"=>[["This information is required"],["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
        end
        it "should pay attention to indexes for not clearing" do
          vd = {'_'=>{"name"=>[nil,["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}}
          @record._merge_invalid_fields(vd,['name'],{}).should ==
            {"name"=>[nil,["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
        end
        it "should clear validation data if not invalid" do
          vd = {'_'=>{"name"=>[nil,["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}}
          @record._merge_invalid_fields(vd,['name'],{},1)
          vd.should == {'_'=>{"education"=>[["Answer must be between 0 and 14"]]}}
        end
      end
      describe "_update_presentation_error_count" do
        before(:each) do
          @validation_data = {'_'=>{"name"=>[["This information is required"],["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}}
        end
        it "should add up the error count for a given presentation" do
          @form.setup_presentation('education_info',@record)
          @record._update_presentation_error_count(@validation_data,'education_info')["education_info"].should == [1]
        end
        it "should add up the error count for a given presentation and index" do
          @form.setup_presentation('new_entry',@record)
          @record._update_presentation_error_count(@validation_data,'new_entry',1)["new_entry"].should == [nil,1]
        end
        it "should add up the error count for a given presentation and all indexes (:any)" do
          @form.setup_presentation('new_entry',@record)
          @record._update_presentation_error_count(@validation_data,'new_entry',:any)["new_entry"].should == [2,1]
        end
      end
    end
    it "should list the current invalid fields" do
      @record.current_invalid_fields.should == {"education"=>[["Answer must be between 0 and 14"]]}
    end
    it "should set the validation data in the form_instance" do
      @record.form_instance.get_validation_data['_'].should == {"education"=>[["Answer must be between 0 and 14"]]}
      @record.form_instance.get_validation_data['new_entry'].should == 1
    end
    describe "validation counts for presentations" do
      it "should provide the count of errors in a presentation" do
        @record.get_invalid_field_count('new_entry').should == 1
        @record.update_attributes({:name => ''},'new_entry')
        @record.get_invalid_field_count('new_entry').should == 2
      end
      it "should provide the count of errors in a presentation at a given index" do
        @record.update_attributes({:name => ''},'simple',nil,:index => 1)
        @record.update_attributes({:name => 'bob'},'simple')
        @record.form_instance.get_validation_data.should == {"simple"=>[0, 1], "new_entry"=>[1], "_"=>{"education"=>[["Answer must be between 0 and 14"]]}}
        @record.get_invalid_field_count('simple',0).should == 0
        @record.get_invalid_field_count('simple',1).should == 1
      end
      it "should provide the count of errors in a presentation at for all indexes" do
        @record.update_attributes({:name => ''},'simple')
        @record.update_attributes({:name => ''},'simple',nil,:index => 2)
        @record.form_instance.get_validation_data.should == {"simple"=>[1,nil, 1], "new_entry"=>[1], "_"=>{"name"=>[["This information is required"],nil,["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}}
        @record.get_invalid_field_count('simple',:any).should == 2
      end
      it "should return nil for the count of errors in a presentation that hasn't been saved" do
        @record.get_invalid_field_count('education_info').should == nil
      end
    end #validation counts
    describe "recalculating validation" do 
      it "should be able to calculate the validation status of the whole form from scratch" do
        @form = SampleForm.new
        @record = Record.make(@form,'new_entry')
        @form.set_record(@record)
        @record.recalcualte_invalid_fields['_'].should == {"hobby"=>[["This information is required"]], "name"=>[["This information is required"]], "fruit"=>[["This information is required"]]}
      end
    end #recalculating validation
    it "should update the validity of related fields" do
      @record.update_attributes({:education => 3},'new_entry')
      @record.form_instance.get_validation_data['_'].should == {"degree"=>[["This information is required"]]}
    end
  end
  
  describe "force nil" do
    before(:each) do
      setup_record
    end
    describe "set_force_nil_attributes method" do
      before(:each) do
        @form.fields['name'].add_force_nil_case(@form.c('name=Joe'),['education'])
      end
      it "it should add nil forcing attributes to the record when condition matches" do
        @record.name = 'Joe'
        @record.set_force_nil_attributes
        @record.attributes.has_key?('education').should == true
        @record.attributes['education'].should == nil
      end
      it "it should not add nil forcing attributes to the record when condition doesn't matches" do
        @record.name = 'Bob'
        @record.set_force_nil_attributes
        @record.attributes.has_key?('education').should == false
      end
    end
    describe "set_force_nil_attributes method (negate)" do
      before(:each) do
        @form.fields['name'].add_force_nil_case(@form.c('name=Joe'),['education'],:unless)
      end
      it "it should add nil forcing attributes to the record when condition matches" do
        @record.name = 'Bob'
        @record.set_force_nil_attributes
        @record.attributes.has_key?('education').should == true
        @record.attributes['education'].should == nil
      end
      it "it should not add nil forcing attributes to the record when condition doesn't matches" do
        @record.name = 'Joe'
        @record.set_force_nil_attributes
        @record.attributes.has_key?('education').should == false
      end
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