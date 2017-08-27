# frozen_string_literal: true

RSpec.describe "catalog/show.html.erb" do
  let(:document) { SolrDocument.new :id => 'xyz', :format => 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before :each do
    allow(view).to receive(:action_name).and_return('show')
    allow(view).to receive_messages(:has_user_authentication_provider? => false)
    allow(view).to receive_messages(:render_document_sidebar_partial => "Sidebar")
    allow(view).to receive_messages(current_search_session: nil, search_session: {})
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "sets the @page_title" do
    allow(view).to receive(:document_show_html_title).and_return("Heading")
    render
    page_title = view.instance_variable_get(:@page_title)
    expect(page_title).to eq "Heading - Blacklight"
    expect(page_title).to be_html_safe
  end

  it "includes schema.org itemscope/type properties" do
    allow(view).to receive(:document_show_html_title).and_return("Heading")
    allow(document).to receive_messages(:itemtype => 'some-item-type-uri')
    render
    expect(rendered).to have_selector('div#document[@itemscope]')
    expect(rendered).to have_selector('div#document[@itemtype="some-item-type-uri"]')
  end

  it "renders the show_header and show partials by default" do
    allow(view).to receive(:render_grouped_response?).and_return(false)
    stub_template "catalog/_show_header_default.html.erb" => "document_header"
    stub_template "catalog/_show_default.html.erb" => "show_default"
    render
    expect(rendered).to match /document_header/
    expect(rendered).to match /show_default/
  end

  it "uses the show.partials parameter to determine the partials to render" do
    allow(view).to receive(:render_grouped_response?).and_return(false)
    blacklight_config.show.partials = ['a', 'b', 'c']
    stub_template "catalog/_a_default.html.erb" => "a_partial"
    stub_template "catalog/_b_default.html.erb" => "b_partial"
    stub_template "catalog/_c_default.html.erb" => "c_partial"
    render
    expect(rendered).to match /a_partial/
    expect(rendered).to match /b_partial/
    expect(rendered).to match /c_partial/
  end
end
