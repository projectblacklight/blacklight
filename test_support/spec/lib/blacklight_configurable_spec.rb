#ste -*- encoding : utf-8 -*-
# -*- coding: UTF-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::Configurable" do

  describe "inheritence" do
    before(:all) do
      module TestCaseInheritence
        class Parent
          include Blacklight::Configurable

          blacklight_config.configure do |config|
            config.list = [1,2,3]
          end
        end

        class Child < Parent
        end
      end
    end
    it "should inherit the configuration when subclassed" do            
      TestCaseInheritence::Child.blacklight_config.list.should include(1,2,3)
    end
    
    it "inherited version should be a deep copy, not original" do      
      TestCaseInheritence::Child.blacklight_config.should_not  be(TestCaseInheritence::Parent.blacklight_config)
    
      TestCaseInheritence::Child.blacklight_config.list << "child_only"


      TestCaseInheritence::Child.blacklight_config.list.should include("child_only")      
      TestCaseInheritence::Parent.blacklight_config.list.should_not include("child_only")
    end    
  end

  describe "default configuration" do
    before(:each) do
      Blacklight::Configurable.default_configuration = nil
    end

    after do
      Blacklight::Configurable.default_configuration = nil
    end

    it "should load an empty configuration" do
      a = Class.new
      a.send(:include, Blacklight::Configurable)

      a.blacklight_config.default_solr_params.should be_empty
    end

    it "should allow the user to provide a default configuration" do
      a = Class.new

      Blacklight::Configurable.default_configuration = Blacklight::Configuration.new :a => 1

      a.send(:include, Blacklight::Configurable)
      a.blacklight_config.a.should == 1
    end
    
    it "has configure_blacklight convenience method" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      
      klass.configure_blacklight do |config|
        config.my_key = 'value'
      end 
      
      klass.blacklight_config.my_key.should == 'value'
    end

    it "allows the instance to set a radically different config from the class" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      klass.blacklight_config.foo = "bar"

      instance = klass.new
      instance.blacklight_config.should_not == klass.blacklight_config
      instance.blacklight_config.foo.should be_nil
    end
    
    it "allows instance to set it's own config seperate from class" do
      # this is built into class_attribute; we spec it both to document it,
      # and to ensure we preserve this feature if we change implementation
      # to not use class_attribute
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      klass.blacklight_config.foo = "bar"
      klass.blacklight_config.bar = []
      klass.blacklight_config.bar << "asd"
      
      instance = klass.new
      instance.blacklight_config.bar << "123"
      instance.blacklight_config.should_not == klass.blacklight_config
      klass.blacklight_config.foo.should == "bar"
      instance.blacklight_config.foo.should == "bar"
      klass.blacklight_config.bar.should_not include("123")
      instance.blacklight_config.bar.should include("asd", "123")
    end

    it "configurable classes should not mutate the default configuration object" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      klass.blacklight_config.foo = "bar"

      klass2 = Class.new
      klass2.send(:include, Blacklight::Configurable)
      klass2.blacklight_config.foo = "asdf"

      klass.blacklight_config.foo.should == "bar"
      klass2.blacklight_config.foo.should == "asdf"
    end
    
  end
end
  
