# frozen_string_literal: true

RSpec.describe "catalog/_document_list" do
  let(:view_type) { 'some-view' }
  let(:view_config) { Blacklight::Configuration::ViewConfig.new(key: view_type, document_component: Blacklight::DocumentComponent, partials: []) }

  before do
    allow(view).to receive_messages(document_index_view_type: view_type, documents: [], blacklight_config: nil)
    assign(:response, instance_double(Blacklight::Solr::Response, start: 0))
  end

  it "includes a class for the current view" do
    render(partial: "catalog/document_list", locals: { view_config: view_config })
    expect(rendered).to have_css(".documents-some-view")
  end
end
