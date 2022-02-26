# frozen_string_literal: true

# spec for sidebar partial in catalog show view

RSpec.describe "catalog/_show_sidebar.html.erb" do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.index.title_field = 'title_tsim'
    end
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:has_user_authentication_provider?).and_return(false)
    allow(view).to receive(:document_actions).and_return([])
    allow(view).to receive(:session_tracking_params).and_return({})
  end

  it "shows more-like-this titles in the sidebar" do
    document = SolrDocument.new id: 1, title_s: 'abc', format: 'default'
    allow(document).to receive(:more_like_this).and_return([SolrDocument.new('id' => '2', 'title_tsim' => 'Title of MLT Document')])
    render 'catalog/show_sidebar', document: document
    expect(rendered).to include("More Like This")
    expect(rendered).to include("Title of MLT Document")
  end
end
