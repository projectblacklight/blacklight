require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::SearchFields do

  class MockConfig
    include Blacklight::SearchFields

    # add in a #config method that includes search field config
    # that will be used by SearchFields
    def config
      @config ||= {:search_fields => [ {:display_label => 'All Fields', :key => "all_fields"},
                           {:key => 'title', :qt => 'title_search'},
                           {:key => 'author', :qt => 'author_search'},
                           {:key => 'subject', :qt=> 'subject_search'},
                           ['Legacy Config', 'legacy_qt'],
                           {:key => "no_display", :qt=>"something", :include_in_simple_select => false}
                          ],
        :default_qt => "search"
      }
    end
    
  end

  before(:all) do
    @search_field_obj = MockConfig.new
  end

  it 'should convert legacy Array config to Hash properly' do
    hash = @search_field_obj.search_field_def_for_key('legacy_qt')

    hash.should be_kind_of(Hash)
    hash[:key].should == hash[:qt]
    hash[:display_label].should == 'Legacy Config'
  end
  
  it "should return search field list with calculated :display_label when needed" do
     @search_field_obj.search_field_list.each do |hash|        
        hash[:display_label].should_not be_blank
     end
  end

  it "should fill in default qt where needed" do
    @search_field_obj.search_field_def_for_key("all_fields")[:qt].should == Blacklight.config[:default_qt]
  end
  
  it "should return proper options_for_select arguments" do
    select_arguments = @search_field_obj.search_field_options_for_select

    select_arguments.each_index do |index|
       argument = select_arguments[index]
       config_hash = @search_field_obj.search_field_list[index]

       argument.length.should == 2
       argument[0].should == config_hash[:display_label]
       argument[1].should == config_hash[:key]
    end    
  end
  
  it "should include the current search option in select, even if not otherwise exposed" do
    select_options = @search_field_obj.search_field_options_for_select("no_display")
    select_options.should include(["No Display", "no_display"])
  end

  it "should not include fields in select if :display_in_simple_search=>false" do
    select_arguments = @search_field_obj.search_field_options_for_select

    select_arguments.should_not include(["No Display", "no_display"])
  end

  

  it "should lookup field definitions by key" do
    @search_field_obj.search_field_def_for_key("title")[:key].should == "title"
  end

  it "should find display_label by key" do
    @search_field_obj.label_for_search_field("title").should == "Title"
  end

  it "should supply default label for key not found" do
    @search_field_obj.label_for_search_field("non_existent_key").should == "Keyword"
  end

  describe "for unspecified :key" do
    before do
      @bad_config = MockConfig.new
      @bad_config.config[:search_fields] = [ 
        {:display_label => 'All Fields', :qt => "all_fields"},
        {:key => 'title', :qt => 'title_search'}
      ]
    end
    it "should raise exception on #search_field_list" do
      lambda {@bad_config.search_field_list}.should raise_error
    end
  end

  describe "for duplicate keys" do
    before do
      @bad_config = MockConfig.new
      @bad_config.config[:search_fields] = [ 
        {:display_label => 'All Fields', :key => "my_key"},
        {:key => 'title', :key => 'my_key'}
      ]
    end
    it "should raise on #search_field_list" do
      lambda {@bad_config.search_field_list}.should raise_error
    end
  end
  
end
