# frozen_string_literal: true

# spec for sidebar partial in catalog show view

RSpec.describe "/catalog/_show_sidebar.html.erb" do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.index.title_field = 'title_tsim'
    end
  end
  let(:document_model) { respond_to?(:solr_document_path) ? SolrDocument : ElasticsearchDocument }
  let(:related_document) { document_model.new(id: '2', title_tsim: 'Title of MLT Document') }

  before(:each) do
    allow(controller).to receive(:action_name).and_return('show')
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:has_user_authentication_provider?).and_return(false)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:document_actions).and_return([])
    allow(related_document).to receive(:persisted?).and_return(true)
  end
  it "shows more-like-this titles in the sidebar" do
  	@document = document_model.new :id => 1, :title_s => 'abc', :format => 'default'
  	allow(@document).to receive(:more_like_this).and_return([related_document])
    render
    expect(rendered).to include("More Like This")
    expect(rendered).to include("Title of MLT Document")
  end
end
