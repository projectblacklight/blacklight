# -*- encoding : utf-8 -*-
require 'spec_helper'

# spec for default partial to display solr document fields 
#  in catalog show view

describe "/catalog/_show_default.html.erb" do
  
  include BlacklightHelper
  include CatalogHelper


  before(:each) do
     @config = Blacklight::Configuration.new do |config|
      config.show.display_type = 'asdf'
      config.add_show_field 'one_field', :label => 'One:'
      config.add_show_field 'empty_field', :label => 'Three:'
      config.add_show_field 'four_field', :label => 'Four:'
    end

    @fname_1 = "one_field"
    @fname_2 = "solr_field_not_in_config"
    @fname_3 = "empty_field"
    @fname_4 = "four_field"
    
    @document = double("solr_doc")
    @document.stub(:get).with(@fname_1, hash_including(:sep => nil)).and_return("val_1")
    @document.stub(:get).with(@fname_2, hash_including(:sep => nil)).and_return("val_2")
    @document.stub(:get).with(@fname_3, hash_including(:sep => nil)).and_return(nil)
    @document.stub(:get).with(@fname_4, hash_including(:sep => nil)).and_return("val_4")
    
    @document.stub(:'has?').with(@fname_1).and_return(true)
    @document.stub(:'has?').with(@fname_2).and_return(true)
    @document.stub(:'has?').with(@fname_3).and_return(false)
    @document.stub(:'has?').with(@fname_4).and_return(true)
    
    # cover any remaining fields in initalizer
    @document.stub(:[])
    
    @flabel_1 = "One:"
    @flabel_3 = "Two:"
    @flabel_4 = "Four:"

    view.stub(:blacklight_config).and_return(@config)
    assigns[:document] = @document
    @rendered = view.render_document_partial @document, :show
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
