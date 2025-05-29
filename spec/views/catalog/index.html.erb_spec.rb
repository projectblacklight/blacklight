# frozen_string_literal: true

RSpec.describe "catalog/index.html.erb" do
  describe "with no search parameters" do
    before do
      allow(view).to receive_messages(has_search_parameters?: false, blacklight_config: CatalogController.blacklight_config)
      @response = instance_double(Blacklight::Solr::Response, empty?: true, total: 11, start: 1, limit_value: 10, aggregations: {})
    end

    let(:sidebar) { view.content_for(:sidebar) }

    it "renders the Search::SidebarComponent component" do
      render

      expect(sidebar).to match /Limit your search/
    end
  end

  describe "with search parameters" do
    before do
      stub_template "catalog/_results_pagination.html.erb" => ""
      allow(view).to receive_messages(has_search_parameters?: true, blacklight_config: Blacklight::Configuration.new)
      allow(search_builder).to receive_messages(start: 10, rows: 10)
      allow(controller).to receive_messages(blacklight_config: Blacklight::Configuration.new)

      @response = response
    end

    let(:search_builder) { Blacklight::SearchBuilder.new(view) }
    let(:response) { Blacklight::Solr::Response.new({ response: { numFound: 30 } }, search_builder) }

    it "renders the search_header partial" do
      render
      expect(rendered).to match /sortAndPerPage/
    end
  end
end
