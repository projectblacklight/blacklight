# -*- encoding : utf-8 -*-
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

    context "Hashy methods" do
      it 'should create a doc with hashy methods' do
        doc = SolrDocument.new({'id'=>'SP2514N','inStock'=>true,'manu'=>'Samsung Electronics Co. Ltd.','name'=>'Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133','popularity'=>6,'price'=>92.0,'sku'=>'SP2514N','timestamp'=>'2009-03-20T14:42:49.795Z','cat'=>['electronics','hard drive'],'spell'=>['Samsung SpinPoint P120 SP2514N - hard drive - 250 GB - ATA-133'],'features'=>['7200RPM, 8MB cache, IDE Ultra ATA-133','NoiseGuard, SilentSeek technology, Fluid Dynamic Bearing (FDB) motor']})

        doc.has?(:cat, /^elec/).should == true
        doc.has?(:cat, 'elec').should_not == true
        doc.has?(:cat, 'electronics').should == true

        doc.get(:cat).should == 'electronics, hard drive'
        doc.get(:xyz).should == nil
        doc.get(:xyz, :default=>'def').should == 'def'
      end
    end

   
    context "Unique Key" do
      before(:each) do
        MockDocument.unique_key = 'my_unique_key'
      end

      after(:each) do
        MockDocument.unique_key = 'id'
      end
      it "should use a configuration-defined document unique key" do
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

        doc.methods.find {|name| name.to_s == "my_extension_method"}.should_not be_nil
        doc.my_extension_method.to_s.should == "my_extension_results"
      end
      it "should apply an extension based on a Solr field" do
        MockDocument.use_extension(MockExtension) {|doc| doc.key?(:required_key)}

        with_extension = MockDocument.new(:required_key => "value")
        with_extension.my_extension_method.to_s.should == "my_extension_results"

        without_extension = MockDocument.new(:other_key => "value")
        without_extension.methods.find {|name| name.to_s == "my_extension_method"}.should be_nil
        
      end
      it "should not apply an extension whose condition is not met" do
        MockDocument.use_extension(MockExtension) {|doc| false}
        doc = MockDocument.new()
  
        doc.methods.find {|name| name.to_s == "my_extension_method"}.should be_nil      
      end
      it "should treat a nil condition as always applyable" do
        MockDocument.use_extension(MockExtension)
  
        doc = MockDocument.new()
  
        doc.methods.find {|name | name.to_s =="my_extension_method"}.should_not be_nil
        doc.my_extension_method.should == "my_extension_results"
      end
      it "should let last extension applied override earlier extensions" do
        MockDocument.use_extension(MockExtension)
        MockDocument.use_extension(MockSecondExtension)

        MockDocument.new().my_extension_method.to_s.should == "override"        
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

    context "highlighting" do

      before(:all) do
        @document = MockDocument.new({'id' => 'doc1', 'title_field' => 'doc1 title'}, {'highlighting' => { 'doc1' => { 'title_text' => ['doc <em>1</em>']}, 'doc2' => { 'title_text' => ['doc 2']}}})

      end

      describe "#has_highlight_field?" do
        it "should be true if the highlight field is in the solr response" do
          @document.should have_highlight_field 'title_text'
          @document.should have_highlight_field :title_text
        end

        it "should be false if the highlight field isn't in the solr response" do
           @document.should_not have_highlight_field 'nonexisting_field'
        end
      end

      describe "#highlight_field" do
        it "should return a value" do
          @document.highlight_field('title_text').should include('doc <em>1</em>')
        end


        it "should return a value that is html safe" do
          @document.highlight_field('title_text').first.should be_html_safe
        end

        it "should return nil when the field doesn't exist" do
          @document.highlight_field('nonexisting_field').should be_nil
        end
      end
    end

  describe "#first" do
    it "should get the first value from a multi-valued field" do
      doc = SolrDocument.new :multi => ['a', 'b']
      expect(doc.first :multi).to eq("a")
    end

    it "should get the value from a single-valued field" do
      doc = SolrDocument.new :single => 'a'
      expect(doc.first :single).to eq("a")

    end
  end
    
end
