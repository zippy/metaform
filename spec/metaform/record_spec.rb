require File.dirname(__FILE__) + '/../spec_helper'
include UtilityFunctions

describe Record do
  before(:each) do
    Form.config[:hide_required_extra_errors] = true
  end
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
      @record[:name,1].should == 'Herbert Smith'
      @record.name__1.should == 'Herbert Smith'
      @record.name.should == 'Bob Smith'
    end 
#    it "should work to use string indexes" do
#      @record[:name,'x']='Herbert Smith'
#      @record[:name,'y']='Frankfurt Smith'
#      @record[:name,'x'].should == 'Herbert Smith'
#      @record[:name,'y'].should =='Frankfurt Smith'
#      @record.name__x.should == 'Herbert Smith'
#      @record.name.should == 'Bob Smith'
#    end 
    it "should save all types of indexes to the database" do
      @record[:name,9]='Name 9'
#      @record[:name,'x']='Name x'
#      @record[:name,'y']='Name y'
      @record.save('new_entry')
      nr = Record.locate(:first, :index => :any)
      nr.name.should == 'Bob Smith'
      nr[:name,9].should == 'Name 9'
#      nr[:name,'x'].should == 'Name x'
#      nr[:name,'y'].should =='Name y'
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
      @record[:name,:any].should == ['Bob Smith','Herbert Smith',nil,nil,nil,'Squid Smith']
    end

    it "should be able to clear indexes on update" do
      @record[:name,1]='Herbert Smith'
      @record[:name,5]='Squid Smith'
      @record.save('new_entry')
      nr = Record.locate(:first,{:index => :any})
      nr.update_attributes({:name => 'John Doe'},'new_entry',nil,:clear_indexes =>['name'])
      nr[:name,:any].should == ['John Doe']
    end

    it "should not clear values on update" do
       @record = Record.make(SampleForm.new,'condition_test')
       @record.yale_class = 'music'
       @record['indexed_field_no_default',2] = 'dog'
       @record['indexed_field_no_default',1].should == nil
       @record['indexed_field_no_default',2].should == 'dog'
       @record.save('condition_test')
       nr = Record.locate(:first,{:index => :any})
#       nr.yale_class.should == 'music'
       nr['indexed_field_no_default',1].should == nil
       nr['indexed_field_no_default',2].should == 'dog'
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
#      puts "<br>CACHE:"+@record.cache.dump.inspect
      @record.save('new_entry')
      @record = Record.find(:first, :index => :any)
      @record.name__1.should == 'Joe Smith'
    end
  end
  
#  describe "-- multi-dimensional indexing" do
#    before(:each) do
#      @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
#      @form = SampleForm.new
#      @record = Record.make(@form,'new_entry',@initial_values)
#      @form.set_record(@record)
#    end
#    
#    it "should be able to set and retrieve a two dimensional index" do
#      @record[:name,1] = 'Sue Smith'
#      @record[:name,1,2] = 'Jane Smith'
#      @record.name.should == 'Bob Smith'
#      @record.name__1.should == 'Sue Smith'
#      @record[:name,1].should == 'Sue Smith'
#      @record[:name,1,nil].should == 'Sue Smith'
#      @record[:name,1,2].should == 'Jane Smith'
#      @record[:name,1,3] = 'Scott Smith'
#      @record.save('new_entry')
#      nr = Record.locate(:first, :index => :any)      
#      nr.name.should == 'Bob Smith'
#      nr[:name,nil].should == 'Bob Smith'
#      nr[:name,1].should == 'Sue Smith'
#      nr[:name,1,2].should == 'Jane Smith'
#      nr[:name,1,3].should == 'Scott Smith'
#    end
#  end
  
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
      @record.delete_fields(:all,'name')
      @nr = @record
      @nr.name.should == nil
      @nr.fruit.should == 'banana'
      @nr.occupation.should == 'bum' #and not delete other things in the attributes cache
    end

    it "should delete all but the specified fields" do
      f = FieldInstance.find(:all,:conditions => ['form_instance_id = ?',@record.id])
      f.collect {|f| f.field_id}.sort.should == ["fruit", "name", "reverse_name_and_job", "sue_is_a_plumber", "total_bobs"]
      @record.delete_fields_except('name')
      f = FieldInstance.find(:all,:conditions => ['form_instance_id = ?',@record.id])
      f.collect {|f| f.field_id}.sort.should == ["name"]
      @nr = @record
      @nr.name.should == 'Bob Smith'
      @nr.fruit.should == nil
      @nr.occupation.should == nil #and also delete other things in the attributes cache
    end
    
    it "should delete field instance if answer=nil and state='answered' and no explanation" do
      @record.save('new_entry')
      f = FieldInstance.find(:all,:conditions => ['field_id = ?','occupation'])
      f.size.should == 1
      @record.occupation = nil
      @record.save('new_entry')
      f = FieldInstance.find(:all,:conditions => ['field_id = ?','occupation'])
      f.size.should == 0
    end
  end
  
  describe "-- deleting record fields and wiping their validation data" do
    before(:each) do
      @initial_values = {:education => 15, :name => 'Joe', :fruit => nil, :occupation => 'Bum'}
      @form = SampleForm.new
      @record = Record.make(@form,'new_entry',@initial_values)
      @form.set_record(@record)
      @record.save('new_entry')
    end
    it "should delete specified fields" do
      @record.form_instance.get_validation_data['_'].should == {"degree"=>[["This information is required"]], "fruit"=>[["This information is required"]], "education"=>[["Answer must be between 0 and 14"]]}
      @record.delete_fields_and_validation_data('education','degree')
      @nr = @record
      @nr.name.should == 'Joe'
      @nr.occupation.should == 'Bum'
      @nr.education.should == nil
      @nr.degree .should == nil
      @record.form_instance.get_validation_data['_'].should == {"fruit"=>[["This information is required"]]}
    end
  end
  
#  describe "-- lower level attribute functions" do
#    describe "-- load_attributes" do
#      before(:each) do
#        @initial_values = {:name =>'Bob Smith',:fruit => 'banana'}
#        @form = SampleForm.new
#        @record = Record.make(@form,'new_entry',@initial_values)
#        @record[:name,1] = 'Sue Smith'
#        @form.set_record(@record)
#        @record.save('new_entry')
#      end
#      it "should be possbile to reset the cached attribute data" do
#        @record.reset_attributes
#        @record.get_attributes.should == {nil=>{}}
#      end
#      it "should be possbile to load specific attributes" do
#        @record.load_attributes(['name'])
#        @record.get_attributes.should == {nil=>{}, "0"=>{"name"=>"Bob Smith"}}
#      end
#      it "should be possbile to load specific attributes by index" do
#        @record.load_attributes(['name'],1)
#        @record.get_attributes.should == {nil=>{}, "1"=>{"name"=>"Sue Smith"}}
#      end
#      it "should be possbile to load all indexes of the given attributes" do
#        @record.load_attributes(['name'],:any)
#        @record.get_attributes.should == {nil=>{"name"=>"Bob Smith"}, "1"=>{"name"=>"Sue Smith"}}
#      end
#    end
#  end
    
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
      Record.locate(:all,{:index => 0}).size.should == 3     
    end
    
    it "should correctly set, save and locate indexed fields, of non-nil indices" do
      @records[0][:name,1] = 'Bob Smith 1'
      @records[1][:name,99] = 'Joe Smith 99'
      @records[2][:name,1] = 'Frank Smith 1'
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      Record.locate(:all,{:index => 1}).size.should == 2
      Record.locate(:all,{:index => 99}).size.should == 1
      Record.locate(:all).size.should == 3
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
      r.instance_of?(Record::AnswersHash).should == true
      r['name'].instance_of?(Record::Answer).should == true
      r.name.instance_of?(String).should == true
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
    
    it "should correctly locate fields with filters with a preset array of records" do
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      Record.gather({:records => FormInstance.find(:all), :filters => ':fruit == "banana"'}).size.should == 3
      Record.gather({:records => FormInstance.find(:all), :filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.gather({:records => FormInstance.find(:all), :filters => ':name =~ /o/'}).size.should == 3
     end

    it "should correctly locate fields with filters with a proc to determine the array of records" do
      @records << Record.make(SampleForm.new,'new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      Record.gather({:records => Proc.new{FormInstance.find(:all)}, :filters => ':fruit == "banana"'}).size.should == 3
      Record.gather({:records => Proc.new{FormInstance.find(:all)}, :filters => [':name =~ /Smith/',':fruit == "banana"']}).size.should == 2
      Record.gather({:records => Proc.new{FormInstance.find(:all)}, :filters => ':name =~ /o/'}).size.should == 3
    end

    it "should be able to prefilter by sql" do
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      recs = Record.locate(:all,:sql_prefilters => ":fruit = 'banana'")
      recs.size.should == 2
    end

    it "should be able to prefilter by sql where no records match" do
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      recs = Record.locate(:all,:sql_prefilters => ":fruit = 'zingo_fruit'")
      recs.size.should == 0
    end

    it "should be able to prefilter by sql as a proc" do
      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
      recs = Record.locate(:all,:sql_prefilters => Proc.new{":fruit = 'banana'"})
      recs.size.should == 2
    end

#    it "should return multi-dimentional indexes as arrays of arrays in the answers hash" do
#      @records[0].fruit__1 = 'peach'
#      @records[0].fruit__2 = 'kiwi'
#      @records[0][:fruit,2,1] = 'orange'
#      @records.each { |recs| recs.form.set_record(recs);recs.save('new_entry') }
#      recs = Record.locate(:all,{:index => :any,:return_answers_hash => true})
#      r = recs[0]
#      r['fruit'].value.should == [['banana'],['peach'],['kiwi','orange']]
#      r['fruit'][1].should == ['peach']
#      r['fruit'][2].should == ['kiwi','orange']
#      r['fruit'][2,1].should == 'orange'
#    end
#    
#    it "should return multi-dimentional indexes as arrays of arrays in the answers hash with second index > 1" do
#      @record = Record.make(SampleForm.new,'new_entry')
#      @record[:fruit,2,1] = 'orange'
#      @record[:fruit,2,2] = 'kiwi'
#      @record.form.set_record(@record);
#      @record.save('new_entry')
#      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
#      nr['fruit'].value.should == [[],[],[nil,'orange','kiwi']]
#      nr['fruit'][2].should == [nil,'orange','kiwi']
#      nr['fruit'][2,1].should == 'orange'
#    end
#    
#    
#    it "should get highest index array when the answer is multi-dimensional" do
#      @record = Record.make(SampleForm.new,'new_entry')
#      @record[:breastfeeding,2,1] = 'A'
#      @record[:breastfeeding,2,2] = 'a'
#      @record.form.set_record(@record);
#      @record.save('new_entry')
#      nr = Record.locate(:first,{:index => :any,:return_answers_hash => true})
#      nr['breastfeeding'][2].should == [nil,'A','a']
#      nr['breastfeeding'][2,1].should == 'A'
#    end
    describe "-- limiting fields" do
      before(:each) do
        Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
        Record.make(SampleForm.new,'new_entry',{:name =>'Joe Smith',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
        Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:occupation => ''}).save('new_entry')
        Record.make(SampleForm.new,'new_entry',{:name =>'Oliver Smith'}).save('new_entry')
      end
      it "should find records and limit fields instances returned" do
        r = Record.locate(:all,:fields=>["name"])
        r.size.should == 4
        r[0].form_instance.field_instances.size.should == 1
      end
      it "should not find records if fields are nill or empty string" do
        r = Record.locate(:all,:fields=>["occupation"])
        r.size.should == 2
      end
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
    
    describe "#slice" do
      it "should return an empty hash when no matching records are found"  do
        nr = after_init_save_and_get_from_locate
        Record.locate(nr.id,:index => :any,:fields => ['breastfeeding'], :return_answers_hash => true).should == nil
        nr.slice("breastfeeding").should == {}
      end
      it "should return a hash of one value set at the zeroth index"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
        end
        nr.slice("breastfeeding").should == {0=>"A"}
      end
      it "should return a hash of multiple values set at various indexes"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.slice("breastfeeding").should == {0=>"A", 1 => 'B', 3 => 'D'}
      end
      it "should return a hash of hashes, one for each field id, of multiple values set at various indexes"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
          @record[:fruit] = 'apple'    #Only one baby, first PP visit
          @record[:fruit,2] = 'orange'  #Only one baby, second PP visit
          @record[:fruit,3] = 'kiwi'  #Only one baby, fourth PP visit
          
        end
        nr.slice("breastfeeding","fruit").should == {"breastfeeding"=>{0=>"A", 1=>"B", 3=>"D"}, "fruit"=>{0=>"apple", 2=>"orange", 3=>"kiwi"}}
      end
      
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
      it "should get the highest index value of a field, even when that value is nil" do
         nr = after_init_save_and_get_from_locate do
           @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
           @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
           @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
           @record[:breastfeeding,3] = nil  #Only one baby, fourth PP visit
         end
         nr.last_answer("breastfeeding").should == nil
       end    
#      it "should get highest index array when the answer is multi-dimensional" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.last_answer("breastfeeding").should == [nil,'C','c','3']
#      end
#      it "should get highest index value when the answer is multi-dimensional and an index is passed in" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.last_answer("breastfeeding",2).should == 'c'
#      end
#      it "should get highest index non-nil value when the answer is multi-dimensional and an index is passed in" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          # @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.last_answer("breastfeeding",2).should == 'b'
#      end
    end    
    
    describe "#max_index" do
      it "should return nil when no matching field_instances are found for this record"  do
        nr = after_init_save_and_get_from_locate
        Record.locate(nr.id,:index => :any,:fields => ['breastfeeding'], :return_answers_hash => true).should == nil
        nr.max_index("breastfeeding").should == nil
      end
      it "should get highest index of field"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.max_index("breastfeeding").should == 3
      end
      it "should get highest index of field even when the answer at the highest index is nil"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = 'B'  #Only one baby, second PP visit
          @record[:breastfeeding,2] = 'C'  #Only one baby, third PP visit
          @record[:breastfeeding,3] = nil  #Only one baby, fourth PP visit
        end
        nr.max_index("breastfeeding").should == 3
      end
      
    end
  
    describe "#answer_num" do
      it "should return 0 when no matching records will be found within answer_num"  do
        nr = after_init_save_and_get_from_locate
        Record.locate(nr.id,:index => :any,:fields => ['breastfeeding'], :return_answers_hash => true).should == nil
        nr.answer_num("breastfeeding",'Z').should == 0
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
      
      it "should return 2 when that number of matches answers for a given field, even when the desired answer is ''"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = ''  #Only one baby, second PP visit
          @record[:breastfeeding,2] = ''  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.answer_num("breastfeeding",'').should == 2
      end
      it "should return 2 when that number of matches answers for a given field, even when the desired answer is nil"  do
        nr = after_init_save_and_get_from_locate do
          @record[:breastfeeding] = 'A'    #Only one baby, first PP visit
          @record[:breastfeeding,1] = nil  #Only one baby, second PP visit
          @record[:breastfeeding,2] = nil  #Only one baby, third PP visit
          @record[:breastfeeding,3] = 'D'  #Only one baby, fourth PP visit
        end
        nr.answer_num("breastfeeding",nil).should == 2
      end
      

#      it "should return 1 when that is the correct number of matching arrays and the answer is multi-dimensional" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 1
#      end
#
#      it "should return 2 when that is the correct number of matching arrays and the answer is multi-dimensional" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'A'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'a'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '1'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.answer_num("breastfeeding",[nil,'A','a','1']).should == 2
#      end
#
#      it "should get return 1 when there is 1 matching answer for the given index and the answer is multi-dimensional and an index is passed in" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'c'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.answer_num("breastfeeding",'b',2).should == 1
#      end
#
#      it "should get return 2 when there are 2 matching answers for the given index and the answer is multi-dimensional and an index is passed in" do
#        nr = after_init_save_and_get_from_locate do
#          @record[:breastfeeding,1,1] = 'A'    #Three babies, first PP visit, first baby
#          @record[:breastfeeding,1,2] = 'a'    #Three babies, first PP visit, second baby
#          @record[:breastfeeding,1,3] = '1'    #Three babies, first PP visit, third baby
#          @record[:breastfeeding,2,1] = 'B'    #Three babies, second PP visit, first baby
#          @record[:breastfeeding,2,2] = 'b'    #Three babies, second PP visit, second baby
#          @record[:breastfeeding,2,3] = '2'    #Three babies, second PP visit, third baby
#          @record[:breastfeeding,3,1] = 'C'    #Three babies, third PP visit, first baby
#          @record[:breastfeeding,3,2] = 'b'    #Three babies, third PP visit, second baby
#          @record[:breastfeeding,3,3] = '3'    #Three babies, third PP visit, third baby
#        end
#        nr.answer_num("breastfeeding",'b',2).should == 2
#      end
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
#    it "should raise and exception if you try to store a value it" do
#      lambda {
#       @record.reverse_name_and_job = "fred"
#      }.should raise_error("you can't store a value to a calculated field (reverse_name_and_job)")
#    end
    it "should save a cached version to the database on attribute save" do
      @record.save('new_entry')
      r = Record.locate(@record.id,:fields => ['reverse_name_and_job'],:return_answers_hash =>true)
      r['reverse_name_and_job'].value.should == "ssoBhtimS boB"
    end
    it "summary_calculation fields should be cached to the 0th index" do
      @record['name',1] = 'Joe'
      @record['name',2] = 'Jane'
      @record['name',3] = 'Bob'
      @record.total_bobs.should == 2
      @record['total_bobs',0].should == 2
      @record['total_bobs',4].should == 2
      @record.save('new_entry')
      r = Record.locate(@record.id,:fields => ['total_bobs'],:return_answers_hash =>true)
      r['total_bobs'].value.should == "2"
    end
    it "should update a cached value when on attribute update" do
      @record.save('new_entry')
      r = Record.locate(@record.id,:fields => ['reverse_name_and_job'],:return_answers_hash =>true)
      r['reverse_name_and_job'].value.should == "ssoBhtimS boB"
      @record.update_attributes({:name => 'Herbert'},'new_entry')
      r = Record.locate(@record.id,:fields => ['reverse_name_and_job'],:return_answers_hash =>true)
      r['reverse_name_and_job'].value.should == "ssoBtrebreH"
    end
    it "summary_calculation fields should be written to the database at the 0th index" do
      @record['name',1] = 'Joe'
      @record['name',2] = 'Jane'
      @record['name',3] = 'Bob'
      @record.save('new_entry')
      f = FieldInstance.find(:all,:conditions => ['form_instance_id = ? and field_id = "total_bobs"',@record.id])
      f.size.should == 1
      f[0].answer.should == "2" 
    end
    it "summary_calculation fields should be written to the database at the 0th index, even when there is a value saved there already" do
      @record.save('new_entry')
      record = Record.find(:first, :index => :any)
      record['name',0].should == 'Bob Smith'
      record['name',1] = 'Joe'
      record['name',2] = 'Jane'
      record['name',3] = 'Bob'
      record.save('new_entry')
      f = FieldInstance.find(:all,:conditions => ['form_instance_id = ? and field_id = "total_bobs"',@record.id])
      f.size.should == 1
      f[0].answer.should == "2" 
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
      @record.update_attributes({:name => 'Fred',:occupation=>'1'},'new_entry',{:last_updated => t})["name"].should == "Fred"
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
    it "should not be faked into preventing overwriting of field when using timestamped updating when the value comes in as a different type" do
      t = @record.updated_at.to_i  #get the timestamp from the first record
      Kernel::sleep 2
      @record.occupation = "3"
      @record.save('new_entry')
      @record.update_attributes({:occupation => 3},'new_entry',{:last_updated => t}).has_key?('occupation').should == false
    end
  end
  describe "-- validation" do
    before(:each) do
      setup_record
      @record.education = '99'
      @record.save('new_entry')      
    end
    it "should set the field instance state to 'answered' for valid fields" do
      f = @record.form_instance.field_instances.find_by_field_id('name')
      f.state.should == 'answered'
    end
    it "should set the field instance state to 'invalid' for invalid fields" do
      f = @record.form_instance.field_instances.find_by_field_id('education')
      f.state.should == 'invalid'
    end
    it "should set the field instance state to 'explained' for fields with an explanation" do
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => {"0" => 'has studied forever'}}})
      f = @record.form_instance.field_instances.find_by_field_id('education')
      f.state.should == 'explained'
      f.explanation.should == 'has studied forever'
    end
    it "should set the field instance state to 'explained' for fields with an explanation at an index" do
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => {"1" => 'has studied forever'}}},:index => "1")
      f = @record.form_instance.field_instances.find_by_field_id_and_idx('education',"1")
      f.state.should == 'explained'
      f.explanation.should == 'has studied forever'
    end
    it "setting explanations at a particular index shouldn't have an effect on the explanation at a different index" do
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => {"0" => 'has studied forever'}}})
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => {"1" => 'has also studied forever'}}},:index => "1")
      f = @record.form_instance.field_instances.find_by_field_id('education')
      f.state.should == 'explained'
      f.explanation.should == 'has studied forever'
      f = @record.form_instance.field_instances.find_by_field_id_and_idx('education',"1")
      f.state.should == 'explained'
      f.explanation.should == 'has also studied forever'
    end
    it "should set the field instance state to 'explained' for multi_index fields with explanations" do
      @record.update_attributes(
        { 0 => {:education => '99'},1 => {:education => '97'}},'new_entry',
        {:explanations => {'education' => {"0" => 'has studied forever',"1" => 'has flunked forever'}}},:multi_index => true)
      f = @record.form_instance.field_instances.find_by_field_id('education')
      f.state.should == 'explained'
      f.explanation.should == 'has studied forever'
      f = @record.form_instance.field_instances.find_by_field_id_and_idx('education',"1")
      f.state.should == 'explained'
      f.explanation.should == 'has flunked forever'
    end
    it "should set the field instance state to 'approved' for fields with an approval" do
      @record.update_attributes({:education => '99'},'new_entry',{:approvals => {'education' => {"0" => 'Y'}}})
      f = @record.form_instance.field_instances.find_by_field_id('education')
      f.state.should == 'approved'
    end
    describe "helper methods" do
      describe "_validate_attributes" do
        it "should calculate validation of current attributes" do
          @record.name = nil
          @record._validate_attributes.should == {"name"=>[["This information is required"]], "degree"=>[["This information is required"]],  "education"=>[["Answer must be between 0 and 14"]]}
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
          @record._update_presentation_error_count(@validation_data,'education_info',nil)["education_info"].should == [1]
        end
        it "should not count fields as invalid that are in the specified state" do
          @form.setup_presentation('education_info',@record)
          @record._update_presentation_error_count(@validation_data,'education_info',nil,{'education'=>['explained']},'explained')["education_info"].should == [0]
        end
        it "should add up the error count for a given presentation and index" do
          @form.setup_presentation('new_entry',@record)
          @record._update_presentation_error_count(@validation_data,'new_entry',1)["new_entry"].should == [nil,1]
        end
        it "should add up the error count for a given presentation and all indexes (:any)" do
          @form.setup_presentation('new_entry',@record)
          @record._update_presentation_error_count(@validation_data,'new_entry',:any)["new_entry"].should == [2,1]
        end
        it "should add up the error count for a given presentation and all indexes (:any) excluding ones in the specified state" do
          states = {"name"=>['answered','explained'],'education'=>['answered']}
          @form.setup_presentation('new_entry',@record)
          @record._update_presentation_error_count(@validation_data,'new_entry',:any,states,'explained')["new_entry"].should == [2,0]
          @record._update_presentation_error_count(@validation_data,'new_entry',:any,states,'answered')["new_entry"].should == [0,1]
        end
      end
      describe "get_attribute_states" do
        it "should return a hash of all the attributes state" do
          @record.get_attribute_states.should == {"name"=>["answered"], "sue_is_a_plumber"=>["calculated"], "reverse_name_and_job"=>["calculated"], "total_bobs"=>["calculated"], "fruit"=>["answered"], "education"=>["invalid"]}
        end
      end
    end
    it "should list the current invalid fields" do
      @record.current_invalid_fields.should == {"education"=>[["Answer must be between 0 and 14"]]}
    end
    it "should set the validation data in the form_instance" do
      @record.form_instance.get_validation_data['_'].should == {"education"=>[["Answer must be between 0 and 14"]],"degree"=>[["This information is required"]]}
      @record.form_instance.get_validation_data['new_entry'].should == [1]
    end
    describe "validation counts for presentations" do
      it "should provide the count of errors in a presentation" do
        @record.get_invalid_field_count('new_entry').should == 1
        @record.update_attributes({:name => ''},'new_entry')
        @record.get_invalid_field_count('new_entry').should == 2
      end
      it "should provide the count of errors in a presentation subtracting out ones from fields with excluded states" do
        @record.update_attributes({:name => ''},'new_entry',{:explanations => {'name' => {"0" =>'unknown'}}})
        @record.get_invalid_field_count('new_entry').should == 1
      end
      it "should provide the count of errors in a presentation at a given index" do
        @record.update_attributes({:name => ''},'simple',nil,:index => 1)
        @record.update_attributes({:name => 'bob'},'simple')
        @record.form_instance.get_validation_data.should == {"simple"=>[0, 1], "new_entry"=>[1], "_"=>{"name"=>[nil, ["This information is required"]], "degree"=>[["This information is required"]],  "education"=>[["Answer must be between 0 and 14"]]}}
        @record.get_invalid_field_count('simple',0).should == 0
        @record.get_invalid_field_count('simple',1).should == 1
      end
      it "should provide error count for a presentation at for all indexes" do
        @record.update_attributes({:name => ''},'simple')
        @record.update_attributes({:name => ''},'simple',nil,:index => 2)
        @record.form_instance.get_validation_data.should == {"simple"=>[1,nil, 1], "new_entry"=>[1], "_"=>{"name"=>[["This information is required"],nil,["This information is required"]], "degree"=>[["This information is required"]],  "education"=>[["Answer must be between 0 and 14"]]}}
        @record.get_invalid_field_count('simple',:any).should == 2
      end
      it "should provide error count of zero in a presentation at for all indexes if there are no errors" do
        @record.update_attributes({:name => 'joe'},'simple')
        @record.update_attributes({:name => 'jane'},'simple',nil,:index => 2)
        @record.form_instance.get_validation_data.should == {"simple"=>[0,nil, 0], "new_entry"=>[1], "_"=>{"education"=>[["Answer must be between 0 and 14"]], "degree"=>[["This information is required"]] }}
        @record.get_invalid_field_count('simple',:any).should == 0
      end
      it "should update the error count correctly for multi-index update" do
        @record.update_attributes(
          {
            0 => {:name =>''},
            1 => {:name =>''},
            2 => {:name =>'Jane'}
          }, 'simple',nil,:multi_index => true)
        @record.form_instance.get_validation_data.should == {"simple"=>[1,1], "new_entry"=>[1], "_"=>{"name"=>[["This information is required"], ["This information is required"]], "degree"=>[["This information is required"]],  "education"=>[["Answer must be between 0 and 14"]]}}
        @record.get_invalid_field_count('simple',:any).should == 2
      end
      it "should update the error count correctly when no errors for multi-index update" do
        @record.update_attributes(
          {
            1 => {:name =>'Jane'}
          }, 'simple',nil,:multi_index => true)
        @record.form_instance.get_validation_data.should == {"simple"=>[0], "new_entry"=>[1], "_"=>{"education"=>[["Answer must be between 0 and 14"]], "degree"=>[["This information is required"]]}}
        @record.get_invalid_field_count('simple',:any).should == 0
      end
      it "should return nil for the count of errors in a presentation that hasn't been saved" do
        @record.get_invalid_field_count('education_info').should == nil
      end
    end #validation counts
#    describe "recalculating validation" do 
#      it "should be able to calculate the validation status of the whole form from scratch" do
#        @form = SampleForm.new
#        @record = Record.make(@form,'new_entry')
#        @form.set_record(@record)
#        @record.recalcualte_invalid_fields['_'].should == {"hobby"=>[["This information is required"]], "name"=>[["This information is required"]], "fruit"=>[["This information is required"]]}
#      end
#    end #recalculating validation
    it "should update the validity of related fields" do
      @record.update_attributes({:education => 3},'new_entry')
      @record.form_instance.get_validation_data['_'].should == {"degree"=>[["This information is required"]]}
      @record.update_attributes({:education => 0},'new_entry')
      @record.form_instance.get_validation_data['_'].should == {}
    end
    it "should set validation through the workflow validation command" do
      @record.form_instance.get_validation_data.has_key?(:test).should == false
      @record.save('new_entry',{:workflow_action=>'create'})
      @record.form_instance.get_validation_data[:test].should == 1
    end
  end #--validation
  
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
        @record.set_force_nil_attributes.include?('education').should == true
        @record.cache.attribute_exists?('education').should == true
        @record.education.should == nil
      end
      it "it should not add nil forcing attributes to the record when condition doesn't matches" do
        @record.name = 'Bob'
        @record.set_force_nil_attributes.include?('education').should == false
        @record.cache.attribute_exists?('education').should == false
      end
    end
    describe "set_force_nil_attributes method (negate)" do
      before(:each) do
        @form.fields['name'].add_force_nil_case(@form.c('name=Joe'),['education'],:unless)
      end
      it "it should add nil forcing attributes to the record when condition matches" do
        @record.name = 'Bob'
        @record.set_force_nil_attributes.include?('education').should == true
        @record.cache.attribute_exists?('education').should == true
        @record.education.should == nil
      end
      it "it should not add nil forcing attributes to the record when condition doesn't matches" do
        @record.name = 'Joe'
        @record.set_force_nil_attributes.include?('education').should == false
        @record.cache.attribute_exists?('education').should == false
      end
    end
  end
  describe "forcing nil should also clear any explanations" do
    before(:each) do
      setup_record
      @record.save('new_entry')      
      @form.fields['name'].add_force_nil_case(@form.c('name=Joe'),['education'])
    end
    it "should clear the explanation field after a update_attributes in which a field was forced to nil" do
      @record.update_attributes({:education => '99'},'new_entry',{:explanations => {'education' => {"0" => 'has studied forever'}}})
      @record.education.should == '99'
      @record.explanation('education').should == 'has studied forever'
      @record.any_explanations?.should == true
      @record.update_attributes({:name => 'Joe'},'new_entry')
      @record.education.should == nil
      @record.explanation('education').should == nil
      @record.any_explanations?.should == false
    end
  end
  describe "force nil procs based on conditions" do
    before(:each) do
      setup_record
      @record.save('new_entry')      
    end
    it "should take an array of lambda procs in the :zapping_proc attributes" do
      @record.update_attributes({:breastfeeding => 'yum', :name => 'Sue', :occupation => 'plumber'},'new_entry')
      @record.sue_is_a_plumber.should == 'true'
      @record.breastfeeding.should == 'yum'
      @record.update_attributes({:occupation => 'teacher'},'new_entry')
      @record.education.should == nil
    end
    it "should allow you to only hit the database with the force_nil call if the condition-related value has changed" do
      @record.update_attributes({:education => 'college', :name => 'Sue', :occupation => 'plumber'},'new_entry')
      @record.sue_is_a_plumber.should == 'true'
      @record.education.should == 'college'
      @record.update_attributes({:fruit => 'plum'},'new_entry')
      @record.education.should == 'college'
    end
    it "should apply proc in complex situation with different conditions and indexes" do
      @record.update_attributes({0 => {:education =>'grad_school', :name => 'Sue', :occupation => 'plumber', :fruit => 'orange', :people_num => "2", :breastfeeding => 'yum'}, 1 => {:education => 'college', :fruit => 'banana'}}, 'new_entry',nil,:multi_index => true)
      @record[:education,0].should == 'grad_school'  
      @record[:education,1].should == 'college'  
      @record[:fruit,0].should == 'orange'  
      @record[:fruit,1].should == 'banana'  
      @record[:breastfeeding].should == 'yum'
      @record[:people_num].should == "2"
      @record.update_attributes({:people_num => "1", :occupation => 'teacher'},'new_entry')
      @record[:education,0].should == 'grad_school'  
      @record[:education,1].should == nil 
      @record[:fruit,0].should == 'orange'  
      @record[:fruit,1].should == nil 
      @record[:breastfeeding].should == nil
      @record[:people_num].should == "1"                      
    end
  end
  describe "exporting records" do
    before(:each) do
      setup_record
    end
    it "should be able to export a record to a CSV line" do
      @record.export(
        :fields => ['name', 'fruit']
      ).should == ['SampleForm,,0,,,,Bob Smith,banana']
    end
    it "should be able to export a record and specify date format" do
      i = Time.now
      @record[:due_date] = "1/1/2000"
      @record[:some_time] = "Fri Jan 09 01:10:12 -0500 2009"
      @record.save('new_entry')
      @record.export(
        :fields => ['due_date','some_time'],
        :date_time_format => "%m/%d/%Y %H:%M",
        :date_format => "%m/%d/%Y"
      ).should == ["SampleForm,1,0,#{i.strftime('%m/%d/%Y %H:%M')},#{i.strftime('%m/%d/%Y %H:%M')},,01/01/2000,01/09/2009 01:10"]
    end
    it "should be able to export an indexed record" do
      @record[:fruit,2] = 'apple'
      @record.export(
        :fields => ['name', 'fruit'],
        :meta => true
      ).should == ['SampleForm,,0,,,,Bob Smith,banana','SampleForm,,2,,,,,apple']
    end
  end
  describe "Record.search" do
    def make_record(vals,index=0)
      form = SampleForm.new
      record = Record.make(form,'new_entry',[],{:index => index})
      vals.each {|k,v| record[k] = v}      
      form.set_record(record)
      record.save('new_entry')
    end
    before(:each) do
      make_record({:name =>'Bob Smith',:fruit => 'banana'})
      make_record({:name =>'Fred Smith',:fruit => 'apple'})
      make_record({:name =>'Bob Feldspar',:fruit => 'orange'})
      make_record({:name =>'Jane Feldspar',:fruit => 'orange',:due_date => "1/1/2000"})
    end
    it "should be able to search for fields" do
      records = Record.search(:fields => [:name])
      results = {}
      records.each{|r| results[r.id] = r.attributes}
      results.should == {4=>{"name"=>"Jane Feldspar", "id"=>4}, 1=>{"name"=>"Bob Smith", "id"=>1}, 2=>{"name"=>"Fred Smith", "id"=>2}, 3=>{"name"=>"Bob Feldspar", "id"=>3}}
    end
    it "should be able to search for fields and limit results" do
      records = Record.search(:fields => [:name],:limit => 2,:order => [:name])
      results = {}
      records.each{|r| results[r.id] = r.attributes}
      results.should == {1 => {"name"=>"Bob Smith", "id"=>1}, 3=>{"name"=>"Bob Feldspar", "id"=>3}}
    end
    it "should be able to order fields on search" do
      records = Record.search(:fields => [:name],:order => [:name])
      records.collect{|r| r.attributes}.collect {|h| h["name"]}.should == ["Bob Feldspar", "Bob Smith", "Fred Smith", "Jane Feldspar"] 
    end
    it "should be able to order fields on search selecting the table name too" do
      records = Record.search(:fields => [:name],:order => 'form_instances.id')
      records.collect{|r| r.id}.should == [1,2,3,4]      
    end
    it "should be able to search conditionally on fields" do
      records = Record.search(:conditions => ":name  like 'Bob%'")
      records.collect{|r| r.attributes}.should == [{"id"=>1}, {"id"=>3}]
    end
    it "should be able to search conditionally on fields using rails like array substitution syntax" do
      records = Record.search(:conditions => [":name  like ?","Bob%"])
      records.collect{|r| r.attributes}.should == [{"id"=>1}, {"id"=>3}]
    end
    it "should be able to search conditionally on fields using rails like array substitution syntax and handle nil" do
      records = Record.search(:conditions => [":name  like ?",nil])
      records.collect{|r| r.attributes}.should == []
    end
    it "should be able to search conditionally on fields using rails like array substitution syntax and escape quotes" do
      make_record({:name =>"Bob 'the fat guy' Herman",:fruit => 'orange'})
      records = Record.search(:conditions => [":name  like ?","%'%"])
      records.collect{|r| r.attributes}.should == [{"id"=>5}]
    end
    it "should be able to search conditionally on fields with multiple fields in the condition" do
      records = Record.search(:conditions => ":name  like 'Bob%' or :fruit = 'orange'")
      records.collect{|r| r.attributes}.should == [{"id"=>1}, {"id"=>3}, {"id"=>4}]
    end
    it "should be able to search conditionally on fields with condition as a proc" do
      records = Record.search(:conditions => Proc.new{":name  like 'Bob%'"})
      records.collect{|r| r.attributes}.should == [{"id"=>1}, {"id"=>3}]
    end
    it "should be able to add other fields when searching conditionally" do
      records = Record.search(:fields => [:name,:fruit],:conditions => ":name like 'Bob%'")
      results = {}
      records.each{|r| results[r.id] = r.attributes}
      results.should == { 1=>{"name"=>"Bob Smith", "id"=>1, "fruit"=>'banana'}, 3=> {"name"=>"Bob Feldspar", "id"=>3, "fruit"=>'orange'}}
    end
    it "should be able to add meta_fields to results" do
      records = Record.search(:meta_fields => [:workflow_state])
      results = {}
      records.each{|r| results[r.id] = r.attributes}
      results.should == { 1=> {"id"=>1,"workflow_state"=>nil}, 2=>{"id"=>2,"workflow_state"=>nil},3=>{"id"=>3,"workflow_state"=>nil},4=>{"id"=>4,"workflow_state"=>nil}}
    end
    it "should be able to add raw_fields to results" do
      records = Record.search(:fields => [:name,:fruit],:raw_fields => %Q|CASE
        WHEN workflow_state = 'x' THEN "name".answer
        WHEN workflow_state = 'y' THEN "fruit".answer
        END as conditional|
      )
      results = {}
      records.each{|r| results[r.id] = r.attributes}
      results.should == {1=>{"name"=>"Bob Smith", "id"=>1, "conditional"=>nil, "fruit"=>"banana"}, 2=>{"name"=>"Fred Smith", "id"=>2, "conditional"=>nil, "fruit"=>"apple"},3=> {"name"=>"Bob Feldspar", "id"=>3, "conditional"=>nil, "fruit"=>"orange"}, 4=>{"name"=>"Jane Feldspar", "id"=>4, "conditional"=>nil, "fruit"=>"orange"}}
    end
    it "should be able to search on a meta condition" do
      records = Record.search(:meta_condition => "id > 2")
      records.collect{|r| r.attributes}.should == [{"id"=>3}, {"id"=>4}]
    end
    describe "load_after" do
      it "should be able to specify some fields as :load_after for speed enhancement" do
        records = Record.search(:fields => [:name])
        lambda {records[0].name}.should_not raise_error
        lambda {records[0].fruit}.should raise_error(NoMethodError)
        records = Record.search(:fields => [:name],:load_after =>[:fruit])
        lambda {records[0].fruit}.should_not raise_error(NoMethodError)
      end
      it "should be able to handle fields with special characters in them when using load_after" do
        fruit =  "blood|ora'nge \"fruit\""
        make_record({:name =>'Wilma Feldspar',:fruit =>fruit})
        records = Record.search(:fields => [:name],:load_after =>[:fruit],:conditions => ":name = 'Wilma Feldspar'")
        records[0].fruit.should == fruit
      end
      it "should be able to handle fields with nil values when using load_after" do
        records = Record.search(:fields => [:name],:load_after =>[:hobby])
        records[0].hobby.should == nil
      end
      it "should be able to handle fields with values that return non-string using load_after" do
        records = Record.search(:fields => [:name],:load_after =>[:total_bobs])
        records[0].total_bobs.should == 1
      end
    end
    
  end
  
  #The following two specs were written when we were trying to implement the use of force_nil on fields in indexed presentations.
  #Currently, fields with a force_nil bin will wipe the fields listed only on the index at which the triggering field was located.
  #We tried to talk through how to add in a parameter for force_nil which told it to wipe all indexes of a given field, and
  #kept running into assumptions which made it not work easily.  Instead, we make use of a before_save_record call to wipe the
  #fields and any related validation_data manually.  
  # describe "Indexed Presentations" do
  #   before(:each) do
  #     @form = SampleForm.new
  #     @record = Record.make(@form,'indexed_presentation_by_flag')
  #     @form.set_record(@record)
  #     @record.save('indexed_presentation_by_flag',{:workflow_action=>'create'})
  #     @record.update_attributes({ 
  #         0 => {:prev_preg_flag => 'Y',:prev_preg_REF => 1, :prev_preg_outcome => 'Jane'},
  #         1 => {:prev_preg_REF => 1, :prev_preg_outcome => nil}, 
  #         2 => {:prev_preg_REF => 1, :prev_preg_outcome => 'David'}},'indexed_presentation_by_flag',nil,:multi_index => true)
  #   end
  # 
  #   it "should wipe values for fields in indexed presentation when a force nil is set to do so" do
  #     @record.prev_preg_flag = 'N'
  #     @record.save('indexed_presentation_by_flag')
  #     @record['prev_preg_outcome',0].should == nil
  #     @record['prev_preg_outcome',1].should == nil
  #     @record['prev_preg_outcome',2].should == nil
  #   end
  #   
  #   it "should wipe validation data for fields in indexed presentation when a force nil is set to do so" do
  #     @record.form_instance.get_validation_data['_'].should == {"prev_preg_outcome"=>[nil, ["This information is required"]]}
  #     @record.prev_preg_flag = 'N'
  #     @record.save('indexed_presentation_by_flag')
  #     @record.form_instance.get_validation_data['_'].should == {"name"=>[["This information is required"]], "prev_preg_outcome"=>[nil, nil]}
  #   end
  # end
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

#  it "should handle multi-dimensional indexs" do
#    a = Record::Answer.new('some_value')
#    a.value.should == 'some_value'
#    a[2,1] = 'other_value'
#    a.value.should == [['some_value'],[],[nil,'other_value']]
#    a[0].should == ['some_value']
#    a[1].should == []
#    a[2].should == [nil,'other_value']
#    a[2,1].should == 'other_value'
#    a[0,1].should == nil
#    a[0,0].should == 'some_value'
#  end

end
