require 'spec_helper'

describe "catalog/_thumbnail_default" do

  let :document_without_thumbnail_field do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :document_with_thumbnail_field do
    SolrDocument.new :id => 'xyz', :format => 'a', :thumbnail_url => 'http://localhost/logo.png'
  end

  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.index.thumbnail_field = :thumbnail_url
    end
  end

  before do
    assign :response, double(:params => {})
    view.stub(:render_grouped_response?).and_return false
    view.stub(:blacklight_config).and_return(blacklight_config)
    view.stub(:current_search_session).and_return nil
    view.stub(:search_session).and_return({})
  end

  it "should render the thumbnail if the document has one" do
    render :partial => "catalog/thumbnail_default", :locals => {:document => document_with_thumbnail_field, :document_counter => 1}
    expect(rendered).to match /document-thumbnail/
    expect(rendered).to match /src="http:\/\/localhost\/logo.png"/
  end

  it "should not render a thumbnail if the document does not have one" do
    render :partial => "catalog/thumbnail_default", :locals => {:document => document_without_thumbnail_field, :document_counter => 1}
    expect(rendered).to eq ""
  end
end
