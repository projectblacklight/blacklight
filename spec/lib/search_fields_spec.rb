require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::SearchFields do

  class MockConfig
    include Blacklight::SearchFields

    # add in a #config method that includes search field config
    # that will be used by SearchFields
    def config
      {:search_fields => [ {:display_label => 'All Fields'},
                           {:display_label => 'Title', :qt => 'title_search'},
                           {:display_label =>'Author', :qt => 'author_search'},
                           {:display_label => 'Subject', :qt=> 'subject_search'}     ]  
      }
    end
    
  end

  before(:all) do
    @search_field_obj = MockConfig.new
  end
  
  it "should return search field list with supplied default :key" do
     @search_field_obj.search_field_list.each do |hash|        
        hash[:key].should_not be_blank
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

  it "should lookup field definitions by key" do
    @search_field_obj.search_field_def_for_key("title")[:key].should == "title"
  end

  it "should find display_label by key" do
    @search_field_obj.label_for_search_field("title").should == "Title"
  end

  it "should supply default label for key not found" do
    @search_field_obj.label_for_search_field("non_existent_key").should == "Keyword"
  end
  
end
