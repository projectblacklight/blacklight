require 'spec_helper'

# spec for default partial to display solr document fields 
#  in catalog INDEX view

describe "/catalog/_index_default.erb" do
  include BlacklightHelper
  include CatalogHelper

  before(:each) do
    @config = Blacklight::Configuration.new do |config|
      config.show.display_type_field = 'asdf'
      config.add_index_field 'one_field', :label => 'One:'
      config.add_index_field 'empty_field', :label => 'Three:'
      config.add_index_field 'four_field', :label => 'Four:'
    end

    @fname_1 = "one_field"
    @fname_2 = "solr_field_not_in_config"
    @fname_3 = "empty_field"
    @fname_4 = "four_field"
    
    
    @document = SolrDocument.new(id: 1, @fname_1 => "val_1", @fname_2 => "val2", @fname_4 => "val_4")

    @flabel_1 = "One:"
    @flabel_3 = "Three:"
    @flabel_4 = "Four:"

    allow(view).to receive(:blacklight_config).and_return(@config)
    assigns[:document] = @document
    @rendered = view.render_document_partial @document, :index
  end

  it "should only display fields listed in the initializer" do
    expect(@rendered).to_not include_text("val_2")
    expect(@rendered).to_not include_text(@fname_2)
  end
  
  it "should skip over fields listed in initializer that are not in solr response" do
    expect(@rendered).to_not include_text(@fname_3)
  end

  it "should display field labels from initializer and raw solr field names in the class" do
    # labels
    expect(@rendered).to include_text(@flabel_1)
    expect(@rendered).to include_text(@flabel_4)
    # classes    
    expect(@rendered).to include_text("blacklight-#{@fname_1}")
    expect(@rendered).to include_text("blacklight-#{@fname_4}")
  end
  
# this test probably belongs in a Cucumber feature
#  it "should display fields in the order listed in the initializer" do
#    pending
#  end

  it "should have values for displayed fields" do
    expect(@rendered).to include_text("val_1")
    expect(@rendered).to include_text("val_4")
    expect(@rendered).to_not include_text("val_2")
  end

end
