require 'spec_helper'

describe "Blacklight::Configuration" do
  
  before(:each) do
    @config = Blacklight::Configuration.new
  end

  it "should support arbitrary configuration values" do
    @config.a = 1

    expect(@config.a).to eq 1
    expect(@config[:a]).to eq 1
  end

  describe "initialization" do
    it "should be an OpenStructWithHashAccess" do
      expect(@config).to be_a_kind_of Blacklight::OpenStructWithHashAccess
    end

    it "should accept a block for configuration" do
      config = Blacklight::Configuration.new(:a => 1) { |c| c.a = 2 }

      expect(config.a).to eq 2

      config.configure { |c| c.a = 3 }

      expect(config.a).to eq 3
    end
  end

  describe "defaults" do
    it "should have a hash of default rsolr query parameters" do
      expect(@config.default_solr_params).to be_a_kind_of Hash
    end

    it "should have openstruct values for show and index parameters" do
      expect(@config.show).to be_a_kind_of OpenStruct
      expect(@config.index).to be_a_kind_of OpenStruct
    end

    it "should have ordered hashes for field configuration" do
      expect(@config.facet_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.index_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.show_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.search_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.show_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.search_fields).to be_a_kind_of ActiveSupport::OrderedHash
      expect(@config.sort_fields).to be_a_kind_of ActiveSupport::OrderedHash
    end
  end

  describe "config.index.respond_to" do
    it "should have a list of additional formats for index requests to respond to" do
      @config.index.respond_to.xml = true

      @config.index.respond_to.csv = { :layout => false }

      @config.index.respond_to.yaml = lambda { render text: "" }

      expect(@config.index.respond_to.keys).to eq [:xml, :csv, :yaml]
    end
  end

  describe "spell_max" do
    it "should default to 5" do
      expect(Blacklight::Configuration.new.spell_max).to eq 5
    end
    
    it "should accept config'd value" do
      expect(Blacklight::Configuration.new(:spell_max => 10).spell_max).to eq 10
    end
  end

  describe "inheritable_copy" do
    it "should provide a deep copy of the configuration" do
      config_copy = @config.inheritable_copy
      config_copy.a = 1

      @mock_facet = Blacklight::Configuration::FacetField.new
      config_copy.add_facet_field "dummy_field", @mock_facet

      expect(@config.a).to be_nil
      expect(@config.facet_fields).to_not include(@mock_facet)
    end

    it "should not dup solr_response_model or solr_document_model" do
      @config.solr_response_model = Blacklight::SolrResponse
      @config.solr_document_model = SolrDocument

      config_copy = @config.inheritable_copy

      expect(config_copy.solr_response_model).to eq Blacklight::SolrResponse
      expect(config_copy.solr_document_model).to eq SolrDocument
    end

    it "should provide cloned copies of mutable data structures" do
      @config.a = { value: 1 }
      @config.b = [1,2,3]

      config_copy = @config.inheritable_copy

      config_copy.a[:value] = 2
      config_copy.b << 5

      expect(@config.a[:value]).to eq 1
      expect(config_copy.a[:value]).to eq 2
      expect(@config.b).to match_array [1,2,3]
      expect(config_copy.b).to match_array [1,2,3,5]
    end
  end

  describe "add alternative solr fields" do
    it "should let you define any arbitrary solr field" do
      Blacklight::Configuration.define_field_access :my_custom_field

      config = Blacklight::Configuration.new do |config|
        config.add_my_custom_field 'qwerty', :label => "asdf"
      end

      

      expect(config.my_custom_fields.keys).to include('qwerty')
    end

    it "should let you define a field accessor that uses an existing field-type" do

      Blacklight::Configuration.define_field_access :my_custom_facet_field, :class => Blacklight::Configuration::FacetField

      config = Blacklight::Configuration.new do |config|
        config.add_my_custom_facet_field 'qwerty', :label => "asdf"
      end

      

      expect(config.my_custom_facet_fields['qwerty']).to be_a_kind_of(Blacklight::Configuration::FacetField)
    end

  end
  
  describe "add_facet_field" do
    it "should accept field name and hash form arg" do
      @config.add_facet_field('format',  :label => "Format", :limit => true)
      
      expect(@config.facet_fields["format"]).to_not be_nil
      expect(@config.facet_fields["format"]["label"]).to eq "Format"
      expect(@config.facet_fields["format"]["limit"]).to be true
    end

    it "should accept FacetField obj arg" do
      @config.add_facet_field("format", Blacklight::Configuration::FacetField.new( :label => "Format"))
      
      expect(@config.facet_fields["format"]).to_not be_nil
      expect(@config.facet_fields["format"]["label"]).to eq "Format"
    end
    
    it "should accept field name and block form" do
      @config.add_facet_field("format") do |facet|        
        facet.label = "Format"
        facet.limit = true
      end
      
      expect(@config.facet_fields["format"]).to_not be_nil
      expect(@config.facet_fields["format"].limit).to be true
    end

    it "should accept block form" do
      @config.add_facet_field do |facet|
        facet.field = "format"
        facet.label = "Format"
      end

      expect(@config.facet_fields['format']).to_not be_nil
    end

    it "should accept a configuration hash" do
      @config.add_facet_field :field => 'format', :label => 'Format'
      expect(@config.facet_fields['format']).to_not be_nil
    end

    it "should accept array form" do
      @config.add_facet_field([{ :field => 'format', :label => 'Format'}, { :field => 'publication_date', :label => 'Publication Date' }])

      expect(@config.facet_fields).to have(2).fields
    end

    it "should accept array form with a block" do
      expect do |b|
        @config.add_facet_field([{ :field => 'format', :label => 'Format'}, { :field => 'publication_date', :label => 'Publication Date' }], &b)
      end.to yield_control.twice
    end


    it "should create default label from titleized solr field" do
      @config.add_facet_field("publication_date")
        
      expect(@config.facet_fields["publication_date"].label).to eq "Publication Date"
    end

    it "should allow you to not show the facet in the facet bar" do
      @config.add_facet_field("publication_date", :show=>false)
        
      expect(@config.facet_fields["publication_date"]['show']).to be false
    end
    
    it "should raise on nil solr field name" do
      expect { @config.add_facet_field(nil) }.to raise_error ArgumentError
    end

    it "should take wild-carded field names and dereference them to solr fields" do
      allow(@config).to receive_messages(luke_fields: { 
        "some_field_facet" => {}, 
        "another_field_facet" => {},
        "a_facet_field" => {},
        })
      expect { |b| @config.add_facet_field "*_facet", &b }.to yield_control.twice
      expect(@config.facet_fields.keys).to eq ["some_field_facet", "another_field_facet"]
    end

    describe "if/unless conditions with legacy show parameter" do
      it "should be hidden if the if condition is false" do
        expect(@config.add_facet_field("hidden", if: false).if).to eq false
        expect(@config.add_facet_field("hidden_with_legacy", if: false, show: true).if).to eq false
      end

      it "should be true if the if condition is true" do
        expect(@config.add_facet_field("hidden", if: true).if).to eq true
        expect(@config.add_facet_field("hidden_with_legacy", if: true, show: false).if).to eq true
      end

      it "should be true if the if condition is missing" do
        expect(@config.add_facet_field("hidden", show: true).if).to eq true
      end
    end
  end
  
  describe "add_index_field" do
    it "takes hash form" do
      @config.add_index_field("title_display", :label => "Title")
      
      expect(@config.index_fields["title_display"]).to_not be_nil
      expect(@config.index_fields["title_display"].label).to eq "Title"
    end
    it "takes IndexField param" do
      @config.add_index_field("title_display", Blacklight::Configuration::IndexField.new(:field => "title_display", :label => "Title"))
      
      expect(@config.index_fields["title_display"]).to_not be_nil
      expect(@config.index_fields["title_display"].label).to eq "Title"
    end
    it "takes block form" do
      @config.add_index_field("title_display") do |field|        
        field.label = "Title"
      end
      expect(@config.index_fields["title_display"]).to_not be_nil
      expect(@config.index_fields["title_display"].label).to eq "Title"
    end
    
    it "creates default label from titleized field" do
      @config.add_index_field("title_display")
      
      expect(@config.index_fields["title_display"].label).to eq "Title Display"
    end
    
    it "should raise on nil solr field name" do
      expect { @config.add_index_field(nil) }.to raise_error ArgumentError
    end

    it "should take wild-carded field names and dereference them to solr fields" do
      allow(@config).to receive_messages(luke_fields: { 
        "some_field_display" => {}, 
        "another_field_display" => {},
        "a_facet_field" => {},
        })
      @config.add_index_field "*_display"

      expect(@config.index_fields.keys).to eq ["some_field_display", "another_field_display"]
    end
  end
  
  describe "add_show_field" do
    it "takes hash form" do
      @config.add_show_field("title_display", :label => "Title")
      
      expect(@config.show_fields["title_display"]).to_not be_nil
      expect(@config.show_fields["title_display"].label).to eq "Title"
    end
    it "takes ShowField argument" do
      @config.add_show_field("title_display", Blacklight::Configuration::ShowField.new(:field => "title_display", :label => "Title"))
      
      expect(@config.show_fields["title_display"]).to_not be_nil
      expect(@config.show_fields["title_display"].label).to eq  "Title"
    end
    it "takes block form" do
      @config.add_show_field("title_display") do |f|        
        f.label = "Title"
      end
      
      expect(@config.show_fields["title_display"]).to_not be_nil
      expect(@config.show_fields["title_display"].label).to eq  "Title"
    end
    
    it "creates default label humanized from field" do
      @config.add_show_field("my_custom_field")
      
      expect(@config.show_fields["my_custom_field"].label).to eq  "My Custom Field"
    end
    
    it "should raise on nil solr field name" do
      expect { @config.add_show_field(nil) }.to raise_error ArgumentError
    end
       
    it "should take wild-carded field names and dereference them to solr fields" do
      allow(@config).to receive_messages(luke_fields: { 
        "some_field_display" => {}, 
        "another_field_display" => {},
        "a_facet_field" => {},
        })
      @config.add_show_field "*_display"

      expect(@config.show_fields.keys).to eq ["some_field_display", "another_field_display"]
    end

  end
    
  
  describe "add_search_field" do
    it "should accept hash form" do
      c = Blacklight::Configuration.new
      c.add_search_field(:key => "my_search_key")
      expect(c.search_fields["my_search_key"]).to_not be_nil
    end

    it "should accept two-arg hash form" do
      c = Blacklight::Configuration.new
      
      c.add_search_field("my_search_type",
          :key => "my_search_type",
          :solr_parameters => { :qf => "my_field_qf^10" }, 
          :solr_local_parameters => { :pf=>"$my_field_pf"})
      
      field = c.search_fields["my_search_type"]
      
      expect(field).to_not be_nil
      
      
      expect(field.solr_parameters).to_not be_nil
      expect(field.solr_local_parameters).to_not be_nil  
      
      
    end
    
    it "should accept block form" do
      c = Blacklight::Configuration.new
      
      c.add_search_field("some_field") do |field|        
        field.solr_parameters = {:qf => "solr_field^10"}
        field.solr_local_parameters = {:pf => "$some_field_pf"}
      end
      
      f = c.search_fields["some_field"]
      
      expect(f).to_not be_nil
      expect(f.solr_parameters).to_not be_nil
      expect(f.solr_local_parameters).to_not be_nil      
    end
    
    it "should accept SearchField object" do
      c = Blacklight::Configuration.new
      
      f = Blacklight::Configuration::SearchField.new( :foo => "bar")
      
      c.add_search_field("foo", f)
      
      expect(c.search_fields["foo"]).to_not be_nil
    end
    
    it "should raise on nil key" do
      expect {@config.add_search_field(nil, :foo => "bar")}.to raise_error ArgumentError
    end
    
    it "creates default label from titleized field key" do
      @config.add_search_field("author_name")
      
      expect(@config.search_fields["author_name"].label).to eq "Author Name"
    end

    describe "if/unless conditions with legacy include_in_simple_search" do
      it "should be hidden if the if condition is false" do
        expect(@config.add_search_field("hidden", if: false).if).to eq false
        expect(@config.add_search_field("hidden_with_legacy", if: false, include_in_simple_search: true).if).to eq false
      end

      it "should be true if the if condition is true" do
        expect(@config.add_search_field("hidden", if: true).if).to eq true
        expect(@config.add_search_field("hidden_with_legacy", if: true, include_in_simple_search: false).if).to eq true
      end

      it "should be true if the if condition is missing" do
        expect(@config.add_search_field("hidden", include_in_simple_search: true).if).to eq true
      end
    end
  end
  
  describe "add_sort_field" do
    it "should take a hash" do
      c = Blacklight::Configuration.new
      c.add_sort_field(:key => "my_sort_key", :sort => "score desc")
      expect(c.sort_fields["my_sort_key"]).to_not be_nil
    end

    it "should take a two-arg form with a hash" do
      @config.add_sort_field("score desc, pub_date_sort desc, title_sort asc", :label => "relevance") 

      
      expect(@config.sort_fields.values.find{|f| f.label == "relevance"}).to_not be_nil
    end
    
    it "should take a SortField object" do
      @config.add_sort_field(Blacklight::Configuration::SortField.new(:label => "relevance", :sort => "score desc, pub_date_sort desc, title_sort asc"
))     
      expect(@config.sort_fields.values.find{|f| f.label == "relevance"}).to_not be_nil
    end
    
    it "should take block form" do
      @config.add_sort_field do |field|
        field.label = "relevance"
        field.sort = "score desc, pub_date_sort desc, title_sort asc"
      end
      
      expect(@config.sort_fields.values.find{|f| f.label == "relevance"}).to_not be_nil

    end
  end
  
  describe "#default_search_field" do
    it "should use the field with a :default key" do
      @config.add_search_field('search_field_1')
      @config.add_search_field('search_field_2', :default => true)

      expect(@config.default_search_field.key).to eq 'search_field_2'
    end
  end
  
end
