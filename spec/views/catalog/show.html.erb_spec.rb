require 'spec_helper'

describe "catalog/show.html.erb" do

  let :document do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  before :each do
    view.stub(:has_user_authentication_provider? => false)
    view.stub(:render_document_sidebar_partial => "Sidebar")
  end

  it "should include schema.org itemscope/type properties" do
    view.stub(:document_show_html_title).and_return("Heading")
    document.stub(:itemtype => 'some-item-type-uri')
    assign :document, document
    view.stub(:blacklight_config).and_return(blacklight_config)
    render

    expect(rendered).to have_selector('div#document[@itemscope]')
    expect(rendered).to have_selector('div#document[@itemtype="some-item-type-uri"]')
  end
end