# frozen_string_literal: true

RSpec.describe "catalog/index.html.erb" do

  describe "with no search parameters" do
    before do
      allow(view).to receive(:has_search_parameters?).and_return(false)
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    end
    let(:sidebar) { view.content_for(:sidebar) }

    it "renders the search_sidebar partial" do
      stub_template "catalog/_search_sidebar.html.erb" => "sidebar_content"
      render
      expect(sidebar).to match /sidebar_content/
    end
  end

  describe "with search parameters" do
    let(:facet_list_presenter) { instance_double(Blacklight::FacetListPresenter, values?: false) }
    let(:results_page_presenter) do
      instance_double(Blacklight::ResultsPagePresenter,
                      facets: facet_list_presenter,
                      search_to_page_title: 'the title',
                      empty?: true)
    end

    before do
      allow(view).to receive(:has_search_parameters?).and_return(true)
      stub_template "catalog/_results_pagination.html.erb" => ""
      stub_template "catalog/_search_header.html.erb" => "header_content"
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
      allow(view).to receive(:render_opensearch_response_metadata).and_return("")
      assign(:list_presenter, results_page_presenter)
    end

    it "renders the search_header partial" do
      render
      expect(rendered).to match /header_content/
    end
  end
end
