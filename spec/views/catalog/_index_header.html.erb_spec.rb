# frozen_string_literal: true

RSpec.describe "catalog/_index_header" do
  let :document do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:actions) { nil }
  let(:presenter) { Blacklight::IndexPresenter.new(document, view) }

  before do
    allow(controller).to receive(:action_name).and_return('index')
    assign :response, instance_double(Blacklight::Solr::Response, start: 0)
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:render_index_doc_actions).and_return(actions)
    render "catalog/index_header", document: document, presenter: presenter, document_counter: 1
  end

  it "renders the document header using the whole space" do
    expect(rendered).to have_selector('.document-counter', text: "2")
    expect(rendered).to have_selector '.index_title.col-md-12'
  end

  context "when the actions are present" do
    let(:actions) { "DOCUMENT ACTIONS" }
    it "gives the document actions space" do
      expect(rendered).to have_selector '.index_title.col-sm-9'
      expect(rendered).to have_content "DOCUMENT ACTIONS"
    end
  end

end
