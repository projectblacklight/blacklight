# frozen_string_literal: true

describe Blacklight::SearchFields do

  class MockConfig
    include Blacklight::SearchFields
  end

  before(:all) do
    @config = Blacklight::Configuration.new do |config|
      config.default_solr_params = { :qt => 'search' }
      
      config.add_search_field 'all_fields', :label => 'All Fields'
      config.add_search_field 'title', :qt => 'title_search'
      config.add_search_field 'author', :qt => 'author_search'
      config.add_search_field 'subject', :qt => 'subject_search'
      config.add_search_field 'no_display', :qt => 'something', :include_in_simple_select => false
    end
  end

  before(:each) do  
    @search_field_obj = MockConfig.new
    allow(@search_field_obj).to receive(:blacklight_config).and_return(@config)
  end

  it "returns search field list with calculated :label when needed" do
     @search_field_obj.search_field_list.each do |hash|        
        expect(hash.label).not_to be_blank
     end
  end

  it "fills in default qt where needed" do
    expect(@search_field_obj.search_field_def_for_key("all_fields").qt).to eq @config.default_solr_params[:qt]
  end

  it "lookups field definitions by key" do
    expect(@search_field_obj.search_field_def_for_key("title").key).to eq "title"
  end

  it "finds label by key" do
    expect(@search_field_obj.label_for_search_field("title")).to eq "Title"
  end

  it "supplies default label for key not found" do
    expect(@search_field_obj.label_for_search_field("non_existent_key")).to eq "Keyword"
  end

  describe "for unspecified :key" do
    before do
      @bad_config = MockConfig.new
    end
    it "raises exception on #search_field_list" do
      expect { allow(@bad_config).to receive(:blacklight_config).and_return(Blacklight::Configuration.new { |config|
           config.add_search_field :label => 'All Fields', :qt => 'all_fields'
           config.add_search_field 'title', :qt => 'title_search'
      })   }.to raise_error ArgumentError
    end
  end

  describe "for duplicate keys" do
    before do
      @bad_config = MockConfig.new
    end
    it "raises on #search_field_list" do
      expect { allow(@bad_config).to receive(:blacklight_config).and_return(Blacklight::Configuration.new { |config|
        config.add_search_field 'my_key', :label => 'All Fields'
        config.add_search_field 'my_key', :label => 'title'

      }) }.to raise_error RuntimeError
    end
  end
  
end
