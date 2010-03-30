require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rubygems'

describe "Blacklight::Solr::Document" do
    class MockDocument
      include Blacklight::Solr::Document
    end

    module MockExtension
      def my_extension_method
        "my_extension_results"
      end
    end

    module MockSecondExtension
      def my_extension_method
        "override"
      end
    end
   

    context "Extendability" do
      before(:each) do
        #Clear extensions
        MockDocument.registered_extensions = []
      end
    
      it "should let you register an extension" do
        MockDocument.use_extension(MockExtension) { |doc| true }
  
        MockDocument.registered_extensions.find {|a| a[:module_obj] == MockExtension}.should_not be_nil
      end
      it "should let you register an extension with a nil condition proc" do
        MockDocument.use_extension(MockExtension) { |doc| true }
        MockDocument.registered_extensions.find {|a| a[:module_obj] == MockExtension}.should_not be_nil
      end
      it "should apply an extension whose condition is met" do
        MockDocument.use_extension(MockExtension) {|doc| true}
        doc = MockDocument.new()
  
        doc.methods.find {|name| name =="my_extension_method"}.should_not be_nil
        doc.my_extension_method.should == "my_extension_results"
      end
      it "should not apply an extension whose condition is not met" do
        MockDocument.use_extension(MockExtension) {|doc| false}
        doc = MockDocument.new()
  
        doc.methods.find {|name| name == "my_extension_method"}.should be_nil      
      end
      it "should treat a nil condition as always applyable" do
        MockDocument.use_extension(MockExtension)
  
        doc = MockDocument.new()
  
        doc.methods.find {|name | name=="my_extension_method"}.should_not be_nil
        doc.my_extension_method.should == "my_extension_results"
      end
      it "should let last extension applied override earlier extensions" do
        MockDocument.use_extension(MockExtension)
        MockDocument.use_extension(MockSecondExtension)

        MockDocument.new().my_extension_method.should == "override"        
      end

      
    end

end
