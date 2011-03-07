require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::Configurable do
  
  class TestConfig
    extend Blacklight::Configurable
  end
  
  before(:each) do
    TestConfig.reset_configs!
  end
  
  it "should respond to configure" do
    TestConfig.respond_to? :configure
  end
  
  describe "the default state" do
    describe "config" do
      it "should be a Hash" do
          TestConfig.config.should be_a Hash      
      end
    end
    describe "configs[:shared]" do
      it "should be a Hash" do
        TestConfig.configs[:shared].should be_a Hash
      end
    end
  end
  
  describe "configs[:shared]" do
    it "should not have the values of its members altered by other environments" do
      TestConfig.configure do |config|
        config[:key] = ":shared value"
      end
      TestConfig.configure(::Rails.env) do |config|
        config[:key] = ":test value"
      end
      TestConfig.config[:key].should == ":test value"
      TestConfig.configs[:shared][:key].should == ":shared value"
      TestConfig.configs[::Rails.env][:key].should == ":test value"
    end
  end
  
  describe "the #configure method behavior" do
    it "requires a block" do
      lambda{TestConfig.configure}.should raise_error(LocalJumpError)
    end
    it "yields a hash" do
      TestConfig.configure{|config| config.should be_a(Hash) }
    end
    it "should clear the configs if reset_configs! is called" do
      TestConfig.configure do |config|
        config[:asdf] = 'asdf'
      end
      TestConfig.configs[:shared][:asdf].should == 'asdf'
      TestConfig.reset_configs!
      TestConfig.configs[:shared][:asdf].should == nil
    end
    
    it "should merge settings from the :shared environment" do
      TestConfig.configure do |config|
        config[:app_id] = 'Blacklight'
        config[:mode] = :shared!
      end
      TestConfig.configure(::Rails.env) do |config|
        config[:mode] = ::Rails.env
      end
      TestConfig.config[:app_id].should == 'Blacklight'
      TestConfig.config[:mode].should_not == :shared!
      TestConfig.config[:mode].should == ::Rails.env
    end
  end
  
  describe "config" do
    it "should return an empty Hash if nothing was configured" do
      TestConfig.config.should == {}
    end
    
    it "should return only what is in configs[:shared] if no other environment was configured" do
      TestConfig.configure(:shared) do |config|
        config[:foo] = 'bar'
        config[:baz] = 'dang'
      end
      TestConfig.config.should == {:foo => 'bar', :baz => 'dang'}
      TestConfig.config.should == TestConfig.configs[:shared]
    end
    
    it "should return a merge of configs[:shared] and configs[RAILS_ENV]" do
      TestConfig.configure(:shared) do |config|
        config[:foo] = 'bar'
        config[:baz] = 'dang'
      end
    end
  end
  
  
end
