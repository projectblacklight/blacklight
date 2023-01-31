# frozen_string_literal: true

RSpec.describe "catalog/_document" do
  let(:document) { SolrDocument.new id: 'xyz', format: 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(controller).to receive(:controller_name).and_return('test')
    allow(view).to receive(:render_grouped_response?).and_return(false)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view.main_app).to receive(:track_test_path).and_return('/track')
    assign(:response, instance_double(Blacklight::Solr::Response, start: 20))
  end

  it "uses the index.partials parameter to determine the partials to render" do
    blacklight_config.index.partials = %w[a b c]
    stub_template "catalog/_a_default.html.erb" => "a_partial"
    stub_template "catalog/_b_default.html.erb" => "b_partial"
    stub_template "catalog/_c_default.html.erb" => "c_partial"
    render partial: "catalog/document", locals: { document: document, document_counter: 1, view_config: blacklight_config.index }
    expect(rendered).to match /a_partial/
    expect(rendered).to match /b_partial/
    expect(rendered).to match /c_partial/
  end
end
