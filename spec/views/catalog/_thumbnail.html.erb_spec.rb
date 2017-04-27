# frozen_string_literal: true

RSpec.describe "catalog/_thumbnail" do

  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.index.thumbnail_field = :thumbnail_url
    end
  end

  let(:presenter) { Blacklight::ResultsPagePresenter.new(document, view) }

  before do
    allow(controller).to receive(:action_name).and_return('index')
    assign :response, instance_double(Blacklight::Solr::Response, start: 0)
    assign :list_presenter, presenter
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    render "catalog/thumbnail", document: document, document_counter: 1
  end

  context "when the document has a thumbnail field" do
    let(:document) do
      SolrDocument.new :id => 'xyz', :format => 'a', :thumbnail_url => 'http://localhost/logo.png'
    end

    it "renders the thumbnail if the document has one" do
      expect(rendered).to match /document-thumbnail/
      expect(rendered).to match /src="http:\/\/localhost\/logo.png"/
    end
  end

  context "when the document does not have a thumbnail field" do
    let(:document) do
      SolrDocument.new :id => 'xyz', :format => 'a'
    end

    it "does not render a thumbnail if the document does not have one" do
      expect(rendered).to eq ""
    end
  end
end
