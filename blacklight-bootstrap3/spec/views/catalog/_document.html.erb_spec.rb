require 'spec_helper'

describe "catalog/_document" do
  let :document do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  it "should render the header, thumbnail and index" do
    view.stub(:blacklight_config).and_return(blacklight_config)
    stub_template "catalog/_document_header.html.erb" => "document_header"
    stub_template "catalog/_thumbnail_default.html.erb" => "thumbnail_default"
    stub_template "catalog/_index_default.html.erb" => "index_default"
    render :partial => "catalog/document", :locals => {:document => document, :document_counter => 1}
    expect(rendered).to match /document_header/
    expect(rendered).to match /thumbnail_default/
    expect(rendered).to match /index_default/
  end
end