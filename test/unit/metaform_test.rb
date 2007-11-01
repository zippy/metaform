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
end
