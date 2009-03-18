require File.dirname(__FILE__) + '/../spec_helper'

describe Listings do
  before(:each) do
    Record.make(SampleForm.new,'new_entry',{:name =>'Bob Smith',:fruit => 'banana',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Joe Doe',:fruit => 'apple',:occupation => 'unemployed'}).save('new_entry')
    Record.make(SampleForm.new,'new_entry',{:name =>'Will Smith',:fruit => 'apple_mutsu',:occupation => 'unemployed'}).save('new_entry')
    r = Record.make(SampleForm.new,'new_entry',{:name =>'Jane Jones',:fruit => 'banana',:occupation => 'unemployed'})
    r[:occupation,1] = 'farmer'
    r.occupation__2 = 'painter'
    r.save('new_entry')
  end
  it "should return 4 items" do 
    @list = Log.get_list('samples')
    @list.size.should == 4
  end
  # it "should return all items when listing has no search rules defined" do
  #   @list = Log.get_listing('snapshot')
  #   @list.size.should == 4
  # end
  # it "should return correct number of items when restricted by a search rule" do
  #   @search_params = {"on_main"=>"n","for_main"=>"Smith"}
  #   @list = Log.get_listing('restricted_snapshot')
  #   @list.size.should == 4
  # end
  
  #order
  #search (pass in search params)
end