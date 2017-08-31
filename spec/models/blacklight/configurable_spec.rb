# frozen_string_literal: true

RSpec.describe "Blacklight::Configurable" do

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
    it "inherits the configuration when subclassed" do
      expect(TestCaseInheritence::Child.blacklight_config.list).to include(1,2,3)
    end

    it "inherited version should be a deep copy, not original" do
      expect(TestCaseInheritence::Child.blacklight_config).to_not  be(TestCaseInheritence::Parent.blacklight_config)

      TestCaseInheritence::Child.blacklight_config.list << "child_only"


      expect(TestCaseInheritence::Child.blacklight_config.list).to include("child_only")
      expect(TestCaseInheritence::Parent.blacklight_config.list).to_not include("child_only")
    end
  end

  describe "default configuration" do
    before(:each) do
      Blacklight::Configurable.default_configuration = nil
    end

    after do
      Blacklight::Configurable.default_configuration = nil
    end

    it "loads an empty configuration" do
      a = Class.new
      a.send(:include, Blacklight::Configurable)

      expect(a.blacklight_config.default_solr_params).to be_empty
    end

    it "allows the user to provide a default configuration" do
      a = Class.new

      Blacklight::Configurable.default_configuration = Blacklight::Configuration.new :a => 1

      a.send(:include, Blacklight::Configurable)
      expect(a.blacklight_config.a).to eq 1
    end

    it "has configure_blacklight convenience method" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)

      klass.configure_blacklight do |config|
        config.my_key = 'value'
      end

      expect(klass.blacklight_config.my_key).to eq 'value'
    end

    it "allows the instance to set a radically different config from the class" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      klass.blacklight_config.foo = "bar"

      instance = klass.new
      instance.blacklight_config = Blacklight::Configuration.new

      expect(instance.blacklight_config).to_not eq klass.blacklight_config
      expect(instance.blacklight_config.foo).to be_nil
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
      expect(instance.blacklight_config).to_not eq klass.blacklight_config
      expect(klass.blacklight_config.foo).to eq "bar"
      expect(instance.blacklight_config.foo).to eq  "bar"
      expect(klass.blacklight_config.bar).to_not include("123")
      expect(instance.blacklight_config.bar).to include("asd", "123")
    end

    it "configurable classes should not mutate the default configuration object" do
      klass = Class.new
      klass.send(:include, Blacklight::Configurable)
      klass.blacklight_config.foo = "bar"

      klass2 = Class.new
      klass2.send(:include, Blacklight::Configurable)
      klass2.blacklight_config.foo = "asdf"

      expect(klass.blacklight_config.foo).to eq "bar"
      expect(klass2.blacklight_config.foo).to eq "asdf"
    end

  end
end
