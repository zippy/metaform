require File.dirname(__FILE__) + '/../spec_helper'

describe RecordCache do
  before :each do
    @c = RecordCache.new
  end
  it "should return nil for attributes that don't exist in the cache" do
    @c.get_attribute('fish').should == nil
  end
  
  it "should save attributes at the default index" do
    @c.set_attribute('fish','cow')
    @c.get_attribute('fish').should == 'cow'
  end

  it "should save attributes at the specified indexs" do
    @c.set_attribute('fish','cow',1)
    @c.get_attribute('fish',1).should == 'cow'
    @c.get_attribute('fish').should == nil
  end
  
  it "should handle attributes as symbols or strings" do
    @c.set_attribute('fish','cow',1)
    @c.get_attribute(:fish,1).should == 'cow'
    @c.set_attribute(:bird,'dog')
    @c.get_attribute('bird').should == 'dog'
  end
  
  it "should be able to return an array of values with the :any index" do
    @c.set_attribute(:fish,'cow',1)
    @c.get_attribute(:fish,:any).should == [nil,'cow']
  end
    
  describe "enumeration" do
    before :each do
      @c.set_attribute(:fish,'trout',1)
      @c.set_attribute(:fish,'bass')
      @c.set_attribute(:bird,'dog')
      @c.set_attribute(:rodent,'mouse')
    end

    it "should be able to return a hash of all the attributes at a given index" do
      @c.attributes.should == {'fish'=>'bass','bird'=>'dog','rodent'=>'mouse'}
      @c.attributes(1).should == {'fish'=>'trout'}
      @c.attributes(2).should == nil
    end

    it "should allow enumeration across all items" do
      r = {}
      @c.each do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"fish1" => 'trout', "fish0"=> 'bass', 'bird0'=>'dog', 'rodent0'=>'mouse'}
    end
    
    it "should allow enumeration across a specified index" do
      r = {}
      @c.each(:index => 1) do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"fish1"=> 'trout'}
      r = {}
      @c.each(:index => 0) do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"fish0"=> 'bass', 'bird0'=>'dog', 'rodent0'=>'mouse'}
    end

    it "should allow enumeration across an attribute list" do
      r = {}
      @c.each(:attributes => :fish) do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"fish0"=> 'bass',"fish1"=> 'trout'}
      r = {}
      @c.each(:attributes => [:bird,'rodent']) do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"bird0"=> 'dog', 'rodent0'=>'mouse'}
    end
    
    it "should be clearable" do
      @c.clear
      r = {}
      @c.each do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {}
    end
    
    it "should allow clearing of particular attributes" do
      @c.clear(:attributes => :fish)
      r = {}
      @c.each do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {'bird0'=>'dog', 'rodent0'=>'mouse'}
    end

    it "should allow clearing of everything except particular attributes" do
      @c.clear(:attributes => :fish,:except => true)
      r = {}
      @c.each do |attribute,value,index|
        r["#{attribute}#{index}"] = value
      end
      r.should == {"fish1" => 'trout', "fish0"=> 'bass'}
    end
    
    it "should allow dectecting if an attribute exists" do
      @c.attribute_exists?(:fish).should == true
      @c.attribute_exists?('fish',1).should == true
      @c.attribute_exists?('fish',2).should == false
      @c.attribute_exists?(:meat).should == false
      @c.set_attribute(:meat,nil)
      @c.attribute_exists?(:meat).should == true 
      @c.set_attribute(:veggies,'carrot',1)
      @c.attribute_exists?(:veggies).should == false #nothing at the zeroth index      
      @c.attribute_exists?(:veggies,1).should == true
      @c.attribute_exists?(:veggies,:any).should == true
      @c.attribute_exists?('veggies',:any).should == true
    end
    
    it "should return a list attribute names in the cache" do
      @c.attribute_names.sort.should == ["bird", "fish", "rodent"]
    end
    
    it "should return a list of the indexes in the cache" do
      @c.set_attribute(:veggies,'carrot',4)
      @c.indexes.should == [0,1,4]
    end
    
  end
end