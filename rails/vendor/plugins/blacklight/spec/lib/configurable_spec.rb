require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::Configurable do
  
  class TestConfig
    extend Blacklight::Configurable
  end
  
  before(:each) do
    TestConfig.reset_configs!
  end
  
  describe "the default state" do
    TestConfig.config.should == nil
    TestConfig.configs[:shared].class.should == Hash
  end
  
  describe "the #configure method behavior" do
    TestConfig.respond_to? :configure
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
      TestConfig.configure(:development) do |config|
        config[:app_id].should == 'Blacklight'
        config[:mode].should == :shared!
        config[:mode] = :dev
      end
      TestConfig.configure(:production) do |config|
        config[:app_id].should == 'Blacklight'
        config[:mode].should == :shared!
        config[:mode] = :prod
      end
    end
  end
  
  describe "The env_name should change the result of #config" do
    TestConfig.config.should == nil
    TestConfig.env_name = :shared
    TestConfig.config.class.should == Hash
    #
    TestConfig.configure do |config|
      config[:solr] = {}
    end
    TestConfig.configure(:production) do |config|
      config[:solr][:url] = 'http://solrserver.com'
    end
    TestConfig.configure(:development) do |config|
      config[:solr][:url] = 'http://localhost:8983/solr'
    end
    #
    TestConfig.config[:solr][:url].should == nil
    TestConfig.env_name = :production
    TestConfig.config[:solr][:url].should == 'http://solrserver.com'
    TestConfig.env_name = :development
    TestConfig.config[:solr][:url].should == 'http://localhost:8983/solr'
  end
  
end