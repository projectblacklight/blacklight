# frozen_string_literal: true

RSpec.describe "catalog/_facets" do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:facet_list_presenter) { instance_double(Blacklight::FacetListPresenter, values?: true) }

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config)
    allow(view).to receive(:search_action_path) do |*args|
      '/catalog'
    end
    assign(:presenter, instance_double(Blacklight::ResultsPagePresenter,
                                       facets: facet_list_presenter))
  end

  context "without any facet fields" do
    it "does not have a header if no facets are displayed" do
      allow(facet_list_presenter).to receive_messages(:render_partials => '')
      render
      expect(rendered).to_not have_selector('h4')
    end
  end

  context "with facet fields" do
    let(:facet_field) do
      Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label').normalize!
    end

    let(:facet_list_presenter) { Blacklight::FacetListPresenter.new(response, view) }

    let(:response) { instance_double(Blacklight::Solr::Response, aggregations: { "facet_field_1" => mock_display_facet_1 }) }
    let(:mock_display_facet_1) { double(name: 'facet_field_1', sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Value', hits: 1234)]) }

    before do
      blacklight_config.facet_fields['facet_field_1'] = facet_field
      allow(view).to receive_messages(:facet_field_names => [:facet_field_1], :facet_limit_for => 10)
    end

    it "has a header" do
      allow(facet_list_presenter).to receive_messages(:render_partials => '')
      render
      expect(rendered).to have_selector('.facets-heading')
    end

    describe "facet display" do
      it "has a(n accessible) header" do
        render
        expect(rendered).to have_selector('.facet-field-heading')
      end
      it "lists values" do
        render
        # The .facet-content class is used by blacklight_range_limit js, and
        # should be applied to the .panel-collapse div that contains the collapsible
        # facet content. Please make sure it remains if possible.
        expect(rendered).to have_selector('.facet-content a.facet-select')
        expect(rendered).to have_selector('.facet-content .facet-count')
      end
    end
  end
end
