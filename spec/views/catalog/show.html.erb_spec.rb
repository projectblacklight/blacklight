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

  it "should render the show_header and show partials by default" do
    view.stub(:render_grouped_response?).and_return(false)
    view.stub(:blacklight_config).and_return(blacklight_config)
    stub_template "catalog/_show_header_default.html.erb" => "document_header"
    stub_template "catalog/_show_default.html.erb" => "show_default"
    
    assign :document, document
    render

    expect(rendered).to match /document_header/
    expect(rendered).to match /show_default/
  end


  it "should use the show.partials parameter to determine the partials to render" do
    view.stub(:render_grouped_response?).and_return(false)
    view.stub(:blacklight_config).and_return(blacklight_config)
    blacklight_config.show.partials = ['a', 'b', 'c']
    stub_template "catalog/_a_default.html.erb" => "a_partial"
    stub_template "catalog/_b_default.html.erb" => "b_partial"
    stub_template "catalog/_c_default.html.erb" => "c_partial"
    assign :document, document
    render
    expect(rendered).to match /a_partial/
    expect(rendered).to match /b_partial/
    expect(rendered).to match /c_partial/
  end
end