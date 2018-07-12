# frozen_string_literal: true

RSpec.describe "Blacklight::Solr::Document", api: true do
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

        expect(doc.has?(:cat, /^elec/)).to eq true
        expect(doc.has?(:cat, 'elec')).not_to eq true
        expect(doc.has?(:cat, 'electronics')).to eq true

        expect(doc.fetch(:cat)).to eq ['electronics', 'hard drive']
        expect(doc.fetch(:xyz, nil)).to be_nil
        expect(doc.fetch(:xyz, 'def')).to eq 'def'
        expect(doc.fetch(:xyz) { |el| 'def' }).to eq 'def'
        expect { doc.fetch(:xyz) }.to raise_exception(KeyError)
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
        expect(@document.id).to eq '1234'
      end

    end

    describe "Primary key" do
      before(:each) do
        MockDocument.unique_key = 'my_unique_key'
      end
      after(:each) do
        MockDocument.unique_key = 'id'
      end
      it "should be the same as the unique key" do
        expect(MockDocument.primary_key).to eq MockDocument.unique_key
      end
    end

    describe "#to_param" do
      it "should be a string" do
        @document = MockDocument.new :id => 1234
        expect(@document.to_param).to eq '1234'
      end
    end

    context "Extendability" do
      before(:each) do
        #Clear extensions
        MockDocument.registered_extensions = []
      end

      it "should let you register an extension" do
        MockDocument.use_extension(MockExtension) { |doc| true }

        expect(MockDocument.registered_extensions.find {|a| a[:module_obj] == MockExtension}).not_to be_nil
      end
      it "should let you register an extension with a nil condition proc" do
        MockDocument.use_extension(MockExtension) { |doc| true }
        expect(MockDocument.registered_extensions.find {|a| a[:module_obj] == MockExtension}).not_to be_nil
      end
      it "should apply an extension whose condition is met" do
        MockDocument.use_extension(MockExtension) {|doc| true}
        doc = MockDocument.new()

        expect(doc.methods.find {|name| name.to_s == "my_extension_method"}).not_to be_nil
        expect(doc.my_extension_method.to_s).to eq "my_extension_results"
      end
      it "should apply an extension based on a Solr field" do
        MockDocument.use_extension(MockExtension) {|doc| doc.key?(:required_key)}

        with_extension = MockDocument.new(:required_key => "value")
        expect(with_extension.my_extension_method.to_s).to eq "my_extension_results"

        without_extension = MockDocument.new(:other_key => "value")
        expect(without_extension.methods.find {|name| name.to_s == "my_extension_method"}).to be_nil

      end
      it "should not apply an extension whose condition is not met" do
        MockDocument.use_extension(MockExtension) {|doc| false}
        doc = MockDocument.new()

        expect(doc.methods.find {|name| name.to_s == "my_extension_method"}).to be_nil
      end
      it "should treat a nil condition as always applyable" do
        MockDocument.use_extension(MockExtension)

        doc = MockDocument.new()

        expect(doc.methods.find {|name | name.to_s =="my_extension_method"}).not_to be_nil
        expect(doc.my_extension_method).to eq "my_extension_results"
      end
      it "should let last extension applied override earlier extensions" do
        MockDocument.use_extension(MockExtension)
        MockDocument.use_extension(MockSecondExtension)

        expect(MockDocument.new().my_extension_method.to_s).to eq "override"
      end

      describe "extension_parameters class-level hash" do
        it "should provide an extension_parameters hash at the class level" do
          MockDocument.extension_parameters[:key] = "value"
          expect(MockDocument.extension_parameters[:key]).to eq "value"
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

          expect(class_one.extension_parameters[:key]).to eq "class_one_value"
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
        expect(doc.export_formats).to have_key(:marc)
        expect(doc.export_formats[:marc][:content_type]).to eq "application/marc"
      end

      it "looks up content-type from Mime::Type if not given in arg" do
        doc = MockDocument.new
        doc.will_export_as(:html)
        expect(doc.export_formats).to have_key(:html)
      end

      context "format not registered with Mime::Type" do
        before(:all) do
          @doc = MockDocument.new
          @doc.will_export_as(:mock2, "application/mock2" )
          # Mime::Type doesn't give us a good way to clean up our new
          # registration in an after, sorry.
        end
        it "registers format" do
          expect(defined?("Mime::MOCK2")).to be_truthy
        end
        it "registers as alias only" do
          expect(Mime::Type.lookup("application/mock2")).not_to equal Mime::Type.lookup_by_extension("mock2")
        end
      end

      it "export_as(:format) by calling export_as_format" do
        doc = MockDocument.new
        doc.will_export_as(:marc, "application/marc")
        expect(doc.export_as(:marc)).to eq "fake_marc"
      end

      it "should know if a document is exportable" do
        doc = MockDocument.new
        doc.will_export_as(:marc, "application/marc")
        expect(doc.exports_as?(:marc)).to be true
      end
    end

    context "to_semantic_fields" do
      class MockDocument
          include Blacklight::Solr::Document
      end
      before do
        MockDocument.field_semantics.merge!(
          title: ["title_field", "other_title"],
          author: "author_field",
          something: "something_field"
        )

        @doc1 = MockDocument.new(
           "title_field" => "doc1 title",
           "other_title" => "doc1 title other",
           "something_field" => ["val1", "val2"],
           "not_in_list_field" => "weird stuff"
         )
      end

      it "should return complete dictionary based on config'd fields" do
        expect(@doc1.to_semantic_values)
          .to eq title: ["doc1 title", "doc1 title other"], something: ["val1", "val2"]
      end
      it "should return empty array for a key without a value" do
        expect(@doc1.to_semantic_values[:author]).to be_empty
        expect(@doc1.to_semantic_values[:nonexistent_token]).to be_empty
      end
      it "should return an array even for a single-value field" do
        expect(@doc1.to_semantic_values[:title]).to be_kind_of(Array)
      end
      it "should return complete array for a multi-value field" do
        expect(@doc1.to_semantic_values[:something]).to eq ["val1", "val2"]
      end

    end

    context "highlighting" do

      before(:all) do
        @document = MockDocument.new({'id' => 'doc1', 'title_field' => 'doc1 title'}, {'highlighting' => { 'doc1' => { 'title_tsimext' => ['doc <em>1</em>']}, 'doc2' => { 'title_tsimext' => ['doc 2']}}})

      end

      describe "#has_highlight_field?" do
        it "should be true if the highlight field is in the solr response" do
          expect(@document).to have_highlight_field 'title_tsimext'
          expect(@document).to have_highlight_field :title_tsimext
        end

        it "should be false if the highlight field isn't in the solr response" do
           expect(@document).to_not have_highlight_field 'nonexisting_field'
        end
      end

      describe "#highlight_field" do
        it "should return a value" do
          expect(@document.highlight_field('title_tsimext')).to include('doc <em>1</em>')
        end


        it "should return a value that is html safe" do
          expect(@document.highlight_field('title_tsimext').first).to be_html_safe
        end

        it "should return nil when the field doesn't exist" do
          expect(@document.highlight_field('nonexisting_field')).to be_nil
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
  describe '#more_like_this' do
    let(:response) { instance_double(Blacklight::Solr::Response, :more_like => [{'id' => 'abc'}]) }
    let(:document) { MockDocument.new({:id => '123'}, response) }
    subject(:result) { document.more_like_this }

    it "should pluck the MoreLikeThis results from the Solr Response" do
      expect(result).to have(1).item
      expect(result.first).to be_a_kind_of(MockDocument)
      expect(result.first.id).to eq 'abc'
      expect(result.first.solr_response).to eq response
    end
  end
end
