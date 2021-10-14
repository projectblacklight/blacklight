# frozen_string_literal: true

RSpec.describe "catalog/_document" do
  let(:document) { SolrDocument.new id: 'xyz', format: 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(controller).to receive(:controller_name).and_return('test')
    allow(view).to receive(:render_grouped_response?).and_return(false)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    assign(:response, instance_double(Blacklight::Solr::Response, start: 20))
  end

  it "renders the header, thumbnail and index by default" do
    stub_template "catalog/_index_header.html.erb" => "document_header"
    stub_template "catalog/_thumbnail.html.erb" => "thumbnail_default"
    stub_template "catalog/_index_default.html.erb" => "index_default"
    render partial: "catalog/document", locals: { document: document, document_counter: 1 }
    expect(rendered).to have_selector 'article.document[@data-document-counter="22"]'
    expect(rendered).to match /document_header/
    expect(rendered).to match /thumbnail_default/
    expect(rendered).to match /index_default/
  end

  it "uses the index.partials parameter to determine the partials to render" do
    blacklight_config.index.partials = %w[a b c]
    stub_template "catalog/_a_default.html.erb" => "a_partial"
    stub_template "catalog/_b_default.html.erb" => "b_partial"
    stub_template "catalog/_c_default.html.erb" => "c_partial"
    render partial: "catalog/document", locals: { document: document, document_counter: 1 }
    expect(rendered).to match /a_partial/
    expect(rendered).to match /b_partial/
    expect(rendered).to match /c_partial/
  end

  it 'provides the rendered partials to an explicitly configured component but does not render them by default' do
    blacklight_config.index.partials = %w[a]
    stub_template "catalog/_a_default.html.erb" => "partial"
    blacklight_config.index.document_component = Blacklight::DocumentComponent
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view.main_app).to receive(:track_test_path).and_return('/track')

    render partial: "catalog/document", locals: { document: document, document_counter: 1 }

    expect(rendered).to have_selector 'article.document header', text: '22. xyz'
    expect(rendered).not_to match(/partial/)
  end

  it 'renders the partial using a provided view config' do
    view_config = Blacklight::Configuration::ViewConfig.new partials: %w[a]
    stub_template "catalog/_a_default.html.erb" => "partial"

    render partial: "catalog/document", locals: { document: document, document_counter: 1, view_config: view_config }

    expect(rendered).to match(/partial/)
  end
end
