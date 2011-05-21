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
   
    context "Unique Key" do
      it "should use a configuration-defined document unique key" do
        MockDocument.should_receive(:unique_key).and_return(:my_unique_key)
        @document = MockDocument.new :id => 'asdf', :my_unique_key => '1234'
        @document.id.should == '1234'
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
      it "should apply an extension based on a Solr field" do
        MockDocument.use_extension(MockExtension) {|doc| doc.key?(:required_key)}

        with_extension = MockDocument.new(:required_key => "value")
        with_extension.my_extension_method.should == "my_extension_results"

        without_extension = MockDocument.new(:other_key => "value")
        without_extension.methods.find {|name| name == "my_extension_method"}.should be_nil
        
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

      describe "extension_parameters class-level hash" do
        it "should provide an extension_parameters hash at the class level" do
          MockDocument.extension_parameters[:key] = "value"
          MockDocument.extension_parameters[:key].should == "value"
        end
    
        it "extension_parameters should not be shared between classes" do
          class_one = Class.new do
            include Blacklight::Solr::Document
          end
          class_two = Class.new do
            include Blacklight::Solr::Document
          end

          class_one.extension_parameters[:key] = "class_one_value"
          class_two.extension_parameters[:key] = "class_two_value"

          class_one.extension_parameters[:key].should == "class_one_value"
        end
      end
      
    end

    context "Will export as" do
      class MockDocument
        include Blacklight::Solr::Document

        def export_as_marc
          "fake_marc"
        end
      end

      it "reports it's exportable formats properly" do
        doc = MockDocument.new
        doc.will_export_as(:marc, "application/marc" )
        doc.export_formats.should have_key(:marc)
        doc.export_formats[:marc][:content_type].should ==  "application/marc"
      end

      it "looks up content-type from Mime::Type if not given in arg" do
        doc = MockDocument.new
        doc.will_export_as(:html)
        doc.export_formats.should have_key(:html)        
      end

      context "format not registered with Mime::Type" do
        before(:all) do
          @doc = MockDocument.new
          @doc.will_export_as(:mock2, "application/mock2" )
          # Mime::Type doesn't give us a good way to clean up our new
          # registration in an after, sorry. 
        end
        it "registers format" do
          defined?("Mime::MOCK2").should be_true
        end
        it "registers as alias only" do
          Mime::Type.lookup("application/mock2").should_not equal(Mime::Type.lookup_by_extension("mock2"))
        end
      end

      it "export_as(:format) by calling export_as_format" do
        doc = MockDocument.new
        doc.will_export_as(:marc, "application/marc")
        doc.export_as(:marc).should == "fake_marc"
      end
    end

    context "to_semantic_fields" do
      class MockDocument
          include Blacklight::Solr::Document                        
      end
      before do
        MockDocument.field_semantics.merge!( :title => "title_field", :author => "author_field", :something => "something_field" )
        
        @doc1 = MockDocument.new( 
           "title_field" => "doc1 title",
           "something_field" => ["val1", "val2"],
           "not_in_list_field" => "weird stuff" 
         )
      end

      it "should return complete dictionary based on config'd fields" do        
        @doc1.to_semantic_values.should == {:title => ["doc1 title"], :something => ["val1", "val2"]}
      end      
      it "should return empty array for a key without a value" do
        @doc1.to_semantic_values[:author].should == []
        @doc1.to_semantic_values[:nonexistent_token].should == []
      end
      it "should return an array even for a single-value field" do
        @doc1.to_semantic_values[:title].should be_kind_of(Array)
      end
      it "should return complete array for a multi-value field" do
        @doc1.to_semantic_values[:something].should == ["val1", "val2"] 
      end
      
    end

    
end
