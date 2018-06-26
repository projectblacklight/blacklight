# frozen_string_literal: true

RSpec.describe "catalog/_index_header" do
  let(:document) { blacklight_config.document_model.new(id: 'xyz', format: 'a') }
  let(:document_model) { respond_to?(:solr_document_path) ? SolrDocument : ElasticsearchDocument }
  let(:blacklight_config) { Blacklight::Configuration.new(document_model: document_model) }

  before do
    # routes only are generated correctly for persisted models
    allow(document).to receive(:persisted?).and_return(true)
    allow(controller).to receive(:action_name).and_return('index')
    assign :response, instance_double(Blacklight::Solr::Response, start: 0)
    allow(view).to receive(:render_grouped_response?).and_return false
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
  end

  it "renders the document header" do
    allow(view).to receive(:render_index_doc_actions)
    render partial: "catalog/index_header", locals: {document: document, document_counter: 1}
    expect(rendered).to have_selector('.document-counter', text: "2")
  end

  it "allows the title to take the whole space if no document tools are rendered" do
    allow(view).to receive(:render_index_doc_actions)
    render partial: "catalog/index_header", locals: {document: document, document_counter: 1}
    expect(rendered).to have_selector '.index_title.col-md-12'
  end

  it "gives the document actions space if present" do
    allow(view).to receive(:render_index_doc_actions).and_return("DOCUMENT ACTIONS")
    render partial: "catalog/index_header", locals: {document: document, document_counter: 1}
    expect(rendered).to have_selector '.index_title.col-sm-9'
    expect(rendered).to have_content "DOCUMENT ACTIONS"
  end

end
