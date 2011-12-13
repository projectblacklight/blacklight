#ste -*- encoding : utf-8 -*-
# -*- coding: UTF-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::Configuration" do
  
  before(:each) do
    @config = Blacklight::Configuration.new
  end

  it "should support arbitrary configuration values" do
    @config.a = 1

    @config.a.should == 1
    @config[:a].should == 1
  end

  describe "initialization" do
    it "should be an OpenStructWithHashAccess" do
      @config.should be_a_kind_of Blacklight::OpenStructWithHashAccess
    end

    it "should accept a block for configuration" do
      config = Blacklight::Configuration.new(:a => 1) { |c| c.a = 2 }

      config.a.should == 2

      config.configure { |c| c.a = 3 }

      config.a.should == 3
    end
  end

  describe "defaults" do
    it "should have a hash of default rsolr query parameters" do
      @config.default_solr_params.should be_a_kind_of Hash
    end
    it "should have openstruct values for show and index parameters" do
      @config.show.should be_a_kind_of OpenStruct
      @config.index.should be_a_kind_of OpenStruct
    end

    it "should have ordered hashes for field configuration" do
      @config.facet_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.index_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.show_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.search_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.show_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.search_fields.should be_a_kind_of ActiveSupport::OrderedHash
      @config.sort_fields.should be_a_kind_of ActiveSupport::OrderedHash
    end
  end

  describe "spell_max" do
    it "should default to 5" do
      Blacklight::Configuration.new.spell_max.should == 5
    end
    
    it "should accept config'd value" do
      Blacklight::Configuration.new(:spell_max => 10).spell_max.should == 10
    end
  end

  describe "inheritable_copy" do
    it "should provide a deep copy of the configuration" do
      config_copy = @config.inheritable_copy
      config_copy.a = 1

      @mock_facet = Blacklight::Configuration::FacetField.new
      config_copy.add_facet_field "dummy_field", @mock_facet

      @config.a.should be_nil
      @config.facet_fields.should_not include(@mock_facet)
    end
  end
  
  describe "add_facet_field" do
    it "should accept field name and hash form arg" do
      @config.add_facet_field('format',  :label => "Format", :limit => true)
      
      @config.facet_fields["format"].should_not be_nil
      @config.facet_fields["format"]["label"].should == "Format"
      @config.facet_fields["format"]["limit"].should == true
    end

    it "should accept FacetField obj arg" do
      @config.add_facet_field("format", Blacklight::Configuration::FacetField.new( :label => "Format"))
      
      @config.facet_fields["format"].should_not be_nil
      @config.facet_fields["format"]["label"].should == "Format"
    end
    
    it "should accept field name and block form" do
      @config.add_facet_field("format") do |facet|        
        facet.label = "Format"
        facet.limit = true
      end
      
      @config.facet_fields["format"].should_not be_nil
      @config.facet_fields["format"].limit.should == true
    end

    it "should accept block form" do
      @config.add_facet_field do |facet|
        facet.field = "format"
        facet.label = "Format"
      end

      @config.facet_fields['format'].should_not be_nil
    end

    it "should accept a configuration hash" do
      @config.add_facet_field :field => 'format', :label => 'Format'
      @config.facet_fields['format'].should_not be_nil
    end

    it "should accept array form" do
      @config.add_facet_field([{ :field => 'format', :label => 'Format'}, { :field => 'publication_date', :label => 'Publication Date' }])

      @config.facet_fields.length.should == 2
    end

    it "should create default label from titleized solr field" do
      @config.add_facet_field("publication_date")
        
      @config.facet_fields["publication_date"].label.should == "Publication Date"
    end
    
    it "should raise on nil solr field name" do
      lambda { @config.add_facet_field(nil) }.should raise_error ArgumentError
    end
    
  end
  
  describe "add_index_field" do
    it "takes hash form" do
      @config.add_index_field("title_display", :label => "Title")
      
      @config.index_fields["title_display"].should_not be_nil
      @config.index_fields["title_display"].label.should == "Title"
    end
    it "takes IndexField param" do
      @config.add_index_field("title_display", Blacklight::Configuration::IndexField.new(:field => "title_display", :label => "Title"))
      
      @config.index_fields["title_display"].should_not be_nil
      @config.index_fields["title_display"].label.should == "Title"
    end
    it "takes block form" do
      @config.add_index_field("title_display") do |field|        
        field.label = "Title"
      end
      @config.index_fields["title_display"].should_not be_nil
      @config.index_fields["title_display"].label.should == "Title"
    end
    
    it "creates default label from titleized field" do
      @config.add_index_field("title_display")
      
      @config.index_fields["title_display"].label.should == "Title Display"
    end
    
    it "should raise on nil solr field name" do
      lambda { @config.add_index_field(nil) }.should raise_error ArgumentError
    end

  end
  
  describe "add_show_field" do
    it "takes hash form" do
      @config.add_show_field("title_display", :label => "Title")
      
      @config.show_fields["title_display"].should_not be_nil
      @config.show_fields["title_display"].label.should == "Title"
    end
    it "takes ShowField argument" do
      @config.add_show_field("title_display", Blacklight::Configuration::ShowField.new(:field => "title_display", :label => "Title"))
      
      @config.show_fields["title_display"].should_not be_nil
      @config.show_fields["title_display"].label.should == "Title"
    end
    it "takes block form" do
      @config.add_show_field("title_display") do |f|        
        f.label = "Title"
      end
      
      @config.show_fields["title_display"].should_not be_nil
      @config.show_fields["title_display"].label.should == "Title"
    end
    
    it "creates default label humanized from field" do
      @config.add_show_field("my_custom_field")
      
      @config.show_fields["my_custom_field"].label.should == "My Custom Field"
    end
    
    it "should raise on nil solr field name" do
      lambda { @config.add_show_field(nil) }.should raise_error ArgumentError
    end
       
  end
    
  
  describe "add_search_field" do
    it "should accept hash form" do
      c = Blacklight::Configuration.new
      c.add_search_field(:key => "my_search_key")
      c.search_fields["my_search_key"].should_not be_nil
    end

    it "should accept two-arg hash form" do
      c = Blacklight::Configuration.new
      
      c.add_search_field("my_search_type",
          :key => "my_search_type",
          :solr_parameters => { :qf => "my_field_qf^10" }, 
          :solr_local_parameters => { :pf=>"$my_field_pf"})
      
      field = c.search_fields["my_search_type"]
      
      field.should_not be_nil
      
      
      field.solr_parameters.should_not be_nil
      field.solr_local_parameters.should_not be_nil  
      
      
    end
    
    it "should accept block form" do
      c = Blacklight::Configuration.new
      
      c.add_search_field("some_field") do |field|        
        field.solr_parameters = {:qf => "solr_field^10"}
        field.solr_local_parameters = {:pf => "$some_field_pf"}
      end
      
      f = c.search_fields["some_field"]
      
      f.should_not be_nil
      f.solr_parameters.should_not be_nil
      f.solr_local_parameters.should_not be_nil      
    end
    
    it "should accept SearchField object" do
      c = Blacklight::Configuration.new
      
      f = Blacklight::Configuration::SearchField.new( :foo => "bar")
      
      c.add_search_field("foo", f)
      
      c.search_fields["foo"].should_not be_nil
    end
    
    it "should raise on nil key" do
      lambda {@config.add_search_field(nil, :foo => "bar")}.should raise_error ArgumentError
    end
    
    it "creates default label from titleized field key" do
      @config.add_search_field("author_name")
      
      @config.search_fields["author_name"].label.should == "Author Name"
    end
                
        
  end
  
  describe "add_sort_field" do
    it "should take a hash" do
      c = Blacklight::Configuration.new
      c.add_sort_field(:key => "my_sort_key", :sort => "score desc")
      c.sort_fields["my_sort_key"].should_not be_nil
    end

    it "should take a two-arg form with a hash" do
      @config.add_sort_field("score desc, pub_date_sort desc, title_sort asc", :label => "relevance") 

      
      @config.sort_fields.values.find{|f| f.label == "relevance"}.should_not be_nil
    end
    
    it "should take a SortField object" do
      @config.add_sort_field(Blacklight::Configuration::SortField.new(:label => "relevance", :sort => "score desc, pub_date_sort desc, title_sort asc"
))     
      @config.sort_fields.values.find{|f| f.label == "relevance"}.should_not be_nil
    end
    
    it "should take block form" do
      @config.add_sort_field do |field|
        field.label = "relevance"
        field.sort = "score desc, pub_date_sort desc, title_sort asc"
      end
      
      @config.sort_fields.values.find{|f| f.label == "relevance"}.should_not be_nil

    end
  end
  
  describe "#default_search_field" do
    it "should use the field with a :default key" do
      @config.add_search_field('search_field_1')
      @config.add_search_field('search_field_2', :default => true)

      @config.default_search_field.key.should == 'search_field_2'
    end
  end
  
end
