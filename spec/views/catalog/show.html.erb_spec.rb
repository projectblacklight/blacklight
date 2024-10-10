# frozen_string_literal: true

RSpec.describe "catalog/show.html.erb" do
  let(:document) { SolrDocument.new id: 'xyz', format: 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:presenter) { Blacklight::ShowPresenter.new(document, view, blacklight_config) }

  before do
    allow(presenter).to receive(:html_title).and_return('Heading')
    allow(document).to receive(:more_like_this).and_return([])
    allow(view).to receive_messages(has_user_authentication_provider?: false)
    allow(view).to receive_messages(render_document_sidebar_partial: "Sidebar")
    allow(view).to receive_messages(current_search_session: nil, search_session: {})
    assign :document, document
    allow(view).to receive_messages(document_presenter: presenter, action_name: 'show', blacklight_config: blacklight_config)
  end

  it "sets the @page_title" do
    render
    page_title = view.instance_variable_get(:@page_title)
    expect(page_title).to eq "Heading - Blacklight"
    expect(page_title).to be_html_safe
  end

  it "includes schema.org itemscope/type properties" do
    allow(document).to receive_messages(itemtype: 'some-item-type-uri')
    render
    expect(rendered).to have_css('div#document[@itemscope]')
    expect(rendered).to have_css('div#document[@itemtype="some-item-type-uri"]')
  end

  it "uses the show.partials parameter to determine the partials to render" do
    allow(view).to receive(:render_grouped_response?).and_return(false)
    blacklight_config.show.partials = %w[a b c]
    stub_template "catalog/_a_default.html.erb" => "a_partial"
    stub_template "catalog/_b_default.html.erb" => "b_partial"
    stub_template "catalog/_c_default.html.erb" => "c_partial"
    render
    expect(rendered).to match /a_partial/
    expect(rendered).to match /b_partial/
    expect(rendered).to match /c_partial/
  end
end
