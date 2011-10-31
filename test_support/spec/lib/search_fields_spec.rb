# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::SearchFields do

  class MockConfig
    include Blacklight::SearchFields
  end

  before(:all) do
    @config = Blacklight::Configuration.from_legacy_configuration({:search_fields => [ {:label => 'All Fields', :key => "all_fields"},
                           {:key => 'title', :qt => 'title_search'},
                           {:key => 'author', :qt => 'author_search'},
                           {:key => 'subject', :qt=> 'subject_search'},
                           ['Legacy Config', 'legacy_qt'],
                           {:key => "no_display", :qt=>"something", :include_in_simple_select => false}
                          ],
                           :default_solr_params => { :qt => "search" }
    })
  end

  before(:each) do  
    @search_field_obj = MockConfig.new
    @search_field_obj.stub!(:blacklight_config).and_return(@config)
  end

  it 'should convert legacy Array config to Hash properly' do
    hash = @search_field_obj.search_field_def_for_key('legacy_qt')

    hash.should be_kind_of(Blacklight::Configuration::SearchField)
    hash.key.should == hash.qt
    hash.label.should == 'Legacy Config'
  end
  
  it "should return search field list with calculated :label when needed" do
     @search_field_obj.search_field_list.each do |hash|        
        hash.label.should_not be_blank
     end
  end

  it "should fill in default qt where needed" do
    @search_field_obj.search_field_def_for_key("all_fields").qt == @config.default_solr_params[:qt]
  end
  
  it "should return proper options_for_select arguments" do

    select_arguments = @search_field_obj.search_field_options_for_select

    select_arguments.each_index do |index|
       argument = select_arguments[index]
       config_hash = @search_field_obj.search_field_list[index]

       argument.length.should == 2
       argument[0].should == config_hash.label
       argument[1].should == config_hash.key
    end    
  end

  it "should not include fields in select if :display_in_simple_search=>false" do
    select_arguments = @search_field_obj.search_field_options_for_select

    select_arguments.should_not include(["No Display", "no_display"])
  end

  

  it "should lookup field definitions by key" do
    @search_field_obj.search_field_def_for_key("title").key.should == "title"
  end

  it "should find label by key" do
    @search_field_obj.label_for_search_field("title").should == "Title"
  end

  it "should supply default label for key not found" do
    @search_field_obj.label_for_search_field("non_existent_key").should == "Keyword"
  end

  describe "for unspecified :key" do
    before do
      @bad_config = MockConfig.new
    end
    it "should raise exception on #search_field_list" do
      lambda { @bad_config.stub(:blacklight_config).and_return(Blacklight::Configuration.from_legacy_configuration({:search_fields => [ 
        {:label => 'All Fields', :qt => "all_fields"},
        {:key => 'title', :qt => 'title_search'}
      ]}))   }.should raise_error
    end
  end

  describe "for duplicate keys" do
    before do
      @bad_config = MockConfig.new
    end
    it "should raise on #search_field_list" do
      lambda { @bad_config.stub(:blacklight_config).and_return(Blacklight::Configuration.from_legacy_configuration({:search_fields => [ 
        {:label => 'All Fields', :qt => "my_key"},
        {:key => 'title', :qt => 'my_key'}
      ]})) }.should raise_error
    end
  end
  
end
