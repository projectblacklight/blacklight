# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

# spec for default partial to display solr document fields 
#  in catalog INDEX view

describe "/catalog/_index_default.erb" do
  include BlacklightHelper
  include CatalogHelper

  before(:each) do
    @config = Blacklight::Configuration.from_legacy_configuration({
      :show => {
        :display_type => 'asdf'
      },
      :index_fields => {
        :field_names => [
          'one_field',
          'empty_field',
          'four_field'
        ],
        :labels => {
          'one_field' => 'One:',
          'empty_field' => 'Three:',
          'four_field' => 'Four:'
        }
      }
    })

    @fname_1 = "one_field"
    @fname_2 = "solr_field_not_in_config"
    @fname_3 = "empty_field"
    @fname_4 = "four_field"
    
    @document = mock("solr_doc")
    @document.should_receive(:get).with(@fname_1, hash_including(:sep => nil)).any_number_of_times.and_return("val_1")
    @document.should_receive(:get).with(@fname_2, hash_including(:sep => nil)).any_number_of_times.and_return("val_2")
    @document.should_receive(:get).with(@fname_3, hash_including(:sep => nil)).any_number_of_times.and_return(nil)
    @document.should_receive(:get).with(@fname_4, hash_including(:sep => nil)).any_number_of_times.and_return("val_4")
    
    @document.should_receive(:'has?').with(@fname_1).any_number_of_times.and_return(true)
    @document.should_receive(:'has?').with(@fname_2).any_number_of_times.and_return(true)
    @document.should_receive(:'has?').with(@fname_3).any_number_of_times.and_return(false)
    @document.should_receive(:'has?').with(@fname_4).any_number_of_times.and_return(true)
    @document.should_receive(:'has?').with(anything()).any_number_of_times.and_return(true)
    
    # cover any remaining fields in initalizer
    @document.should_receive(:get).with(anything(), hash_including(:sep => nil)).any_number_of_times.and_return("bleah")
    @document.should_receive(:[]).any_number_of_times
    
    @flabel_1 = "One:"
    @flabel_3 = "Three:"
    @flabel_4 = "Four:"

    view.stub!(:blacklight_config).and_return(@config)
    assigns[:document] = @document
    @rendered = view.render_document_partial @document, :index
  end

  it "should only display fields listed in the initializer" do
    @rendered.should_not include_text("val_2")
    @rendered.should_not include_text(@fname_2)
  end
  
  it "should skip over fields listed in initializer that are not in solr response" do
    @rendered.should_not include_text(@fname_3)
  end

  it "should display field labels from initializer and raw solr field names in the class" do
    # labels
    @rendered.should include_text(@flabel_1)
    @rendered.should include_text(@flabel_4)
    # classes    
    @rendered.should include_text("blacklight-#{@fname_1}")
    @rendered.should include_text("blacklight-#{@fname_4}")
  end
  
# this test probably belongs in a Cucumber feature
#  it "should display fields in the order listed in the initializer" do
#    pending
#  end

  it "should have values for displayed fields" do
    @rendered.should include_text("val_1")
    @rendered.should include_text("val_4")
    @rendered.should_not include_text("val_2")
  end

end
