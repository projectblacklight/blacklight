require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

# spec for default partial to display solr document fields 
#   in catalog SHOW view

describe "/catalog/_show_partials/_default.html.erb" do
  
  include ApplicationHelper
  include CatalogHelper
  
  before(:each) do
    @fname_1 = Blacklight.config[:show_fields][:field_names].last
    @fname_2 = "solr_field_not_in_initializer"
    @fname_3 = Blacklight.config[:show_fields][:field_names][1]
    @fname_4 = Blacklight.config[:show_fields][:field_names][0]
    
    @flabel_1 = Blacklight.config[:show_fields][:labels][@fname_1]
    @flabel_3 = Blacklight.config[:show_fields][:labels][@fname_3]
    @flabel_4 = Blacklight.config[:show_fields][:labels][@fname_4]

    @document = {@fname_1 => "val_1", @fname_2 => "val_2", @fname_3 => nil, @fname_4 => "val_4"}
    assigns[:document] = @document
    render_document_partial @document, :show
  end

  it "should only display fields listed in the initializer" do
    response.should_not include_text("val_2")
    response.should_not include_text(@fname_2)
  end
  
  it "should skip over fields listed in initializer that are not in solr response" do
    response.should_not include_text(@fname_3)
  end

  it "should display field labels from initializer and raw solr field names in the class" do
    # labels
    response.should include_text(@flabel_1)
    response.should include_text(@flabel_4)
    # classes
    response.should include_text("blacklight-#{@fname_1}")
    response.should include_text("blacklight-#{@fname_4}")
  end
  
# this test probably belongs in a Cucumber feature
#  it "should display fields in the order listed in the initializer" do
#    pending
#  end

  it "should have values for displayed fields" do
    response.should include_text("val_1")
    response.should include_text("val_4")
    response.should_not include_text("val_2")
  end

end
