require File.dirname(__FILE__) + '/../test_helper'


# TODO for now the plugin is drawing its form definitions from the forms dir at the top level
# getting it to preload them from a test directory doesn't work yet and should be fixed!
#    Form.forms_dir = File.join(File.dirname(__FILE__), '..', 'forms')

class MetaformTest < Test::Unit::TestCase
  self.fixture_path = File.join(File.dirname(__FILE__), '..', 'fixtures')

  def test_creating_a_record
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith'})
    
    assert r[:name] == 'Fred Smith' # we can access fields with []
    assert r.name == 'Fred Smith'   # or directly as attributes of the object
    assert r.due_date == nil        # un-initialized attributes should be accessible 
#    assert r.some_value == default_value        # TODO test default values when that gets implemented
    assert_raise(NoMethodError) {r.fish == nil} # other unknown methods should still raise method missing
  end
  
  def test_locating_records
    r = []
    r << Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    r << Record.make('SampleForm','new_entry',{:name =>'Joe Smith',:fruit => 'banana'})
    r << Record.make('SampleForm','new_entry',{:name =>'Frank Smith',:fruit => 'pear'})
    r.last.workflow_state = 'fish'
    r << Record.make('SampleForm','new_entry',{:name =>'Herbert Wilcox',:fruit => 'banana'})
    
    r.each { |recs| recs.save('new_entry') }

    r0 = Record.locate(r[0].id)
#    raise  "r[0]:" << r[0].name.inspect << "  r0:" << r0.name.inspect
#    raise r0.form_instance.field_instances.inspect
    assert r0.name == r[0].name
    
    recs = Record.locate(:all)
    assert recs.size == 4
#    assert Record.locate(:all,{:conditions => ['name like "%Smith"','fruit = "banana"']}).size == 2
#    assert Record.locate(:all,{:conditions => 'name like "%Smith"'}).size == 3
    assert Record.locate(:all,{:filters => ':fruit == "banana"'}).size == 3
    assert Record.locate(:all,{:filters => [':name =~ /Smith/',':fruit == "banana"']}).size == 2
    assert Record.locate(:all,{:filters => ':name =~ /^F/'}).size == 2
    assert Record.locate(:all,{:workflow_state_filter => 'fish'}).size == 1
  end

  def test_setting_fields
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    assert r.name == 'Fred Smith'  
    r.name='Herbert Smith'
    assert r.name == 'Herbert Smith'
    r.save('new_entry') 
    nr = Record.locate(:first)
    assert r.name == 'Herbert Smith'
    assert r[:name] == 'Herbert Smith'
  end
  
  def test_arrayable_fields_basics
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    assert r[:name,nil] == 'Fred Smith'   # the nil index is the default index
    assert r[:name,1] == nil
    r[:name,1] = 'Fred Smith Jones'
    assert r[:name,1] == 'Fred Smith Jones'
    r.save('new_entry')
    nr = Record.locate(:first)
    assert nr[:name,nil] == 'Fred Smith'   # the nil index is the default index
    assert nr[:name,1] == 'Fred Smith Jones'
  end

  def test_arrayable_fields_initializing
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'},:index => 1)
    assert r[:name,1] == 'Fred Smith'
    assert r[:name,nil] == nil
    r = Record.make('SampleForm','new_entry', {
      2 => {:name =>'Fred Smith 2',:fruit => 'apple'},
      1 => {:name =>'Fred Smith 1',:fruit => 'banana'}
    },:multi_index => true)
    assert r[:name,1] == 'Fred Smith 1'
    assert r[:name,2] == 'Fred Smith 2'
    assert r[:fruit,1] == 'banana'
    assert r[:fruit,2] == 'apple'
    assert r[:name,nil] == nil
  end

  def test_arrayable_fields_locate
    r = []
    r << Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    r << Record.make('SampleForm','new_entry',{:name =>'Joe Smith',:fruit => 'banana'})
    r << Record.make('SampleForm','new_entry',{:name =>'Frank Smith',:fruit => 'pear'})

    r[0][:name,1] = 'Fred Smith 1'
    r[1][:name,99] = 'Joe Smith 99'
    r[2][:name,1] = 'Frank Smith 1'
    r.each { |recs| recs.save('new_entry') }
    assert Record.locate(:all,{:index => 1}).size == 2
    assert Record.locate(:all,{:index => 99}).size == 1
    assert Record.locate(:all,{:index => nil}).size == 3
  end

  def test_arrayable_missing_methods
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    assert r.name__1 == nil
    r.name__1 = 'Fred Smith Jones'
    assert r.name__1 == 'Fred Smith Jones'
  end
    
  def test_arrayables_updating
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'},:index=>1)
    r.save('new_entry')
    r = Record.find(:first)
    r.name__1 = "Joe Smith"
    r.save('new_entry')
    r = Record.find(:first)
    assert r.name__1 == "Joe Smith"
  end
  
  def test_setting_defaults
    r = Record.make('SampleForm','new_entry',{:name =>'Fred Smith',:fruit => 'banana'})
    assert r.occupation == nil
    assert r.occupation__1 == nil
    
    assert r.field_with_default == 'fish'
    assert r.field_with_default__1 == 'fish'

    assert r.arrayable_field_no_default == nil
    assert r.arrayable_field_no_default__1 == nil
    r.arrayable_field_no_default = 'dog'
    assert r.arrayable_field_no_default__2 == 'dog'
    assert r.arrayable_field_no_default__1 == nil  #should still be nil because it was already set

    assert r.arrayable_field_with_default == 'cow'
    assert r.arrayable_field_with_default__1 == 'cow'
    r.arrayable_field_with_default = 'cat'
    assert r.arrayable_field_with_default__2 == 'cat'
    assert r.arrayable_field_with_default__1 == 'cow' #should still be 'cow' because it was already set
  end
  
end
