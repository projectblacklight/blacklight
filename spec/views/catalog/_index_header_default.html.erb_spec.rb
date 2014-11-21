require 'spec_helper'

describe "catalog/_index_header_default" do
  let :document do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  it "should render the document header" do
    assign :response, double(:params => {})
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:render_bookmarks_control?).and_return false
    render :partial => "catalog/index_header_default", :locals => {:document => document, :document_counter => 1}
    expect(rendered).to have_selector('.document-counter', text: "2")
  end

end
