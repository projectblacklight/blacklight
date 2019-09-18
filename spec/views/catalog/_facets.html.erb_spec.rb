# frozen_string_literal: true

RSpec.describe "catalog/_facets" do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config)
    allow(view).to receive(:search_action_path).and_return('/catalog')
  end

  context "without any facet fields" do
    it "does not have a header if no facets are displayed" do
      allow(view).to receive_messages(render_facet_partials: '')
      render
      expect(rendered).not_to have_selector('h4')
    end
  end

  context "with facet groups" do
    let :facet_field do
      Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label', group: nil).normalize!
    end

    before do
      blacklight_config.facet_fields['facet_field_1'] = facet_field
      @mock_display_facet_1 = double(name: 'facet_field_1', sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Value', hits: 1234)])
      allow(view).to receive_messages(facet_group_names: [nil], facet_field_names: [:facet_field_1], facet_limit_for: 10)
      @response = double
      allow(@response).to receive(:aggregations).and_return("facet_field_1" => @mock_display_facet_1)
    end

    context "with the default facet group" do
      it "has a header" do
        allow(view).to receive_messages(render_facet_partials: '')
        render
        expect(rendered).to have_selector('.facets-heading')
      end
    end

    context "with a named facet group" do
      let :facet_field do
        Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label', group: 'group_1').normalize!
      end

      before do
        blacklight_config.facet_fields['facet_field_1'] = facet_field
        @mock_display_facet_1 = double(name: 'facet_field_1', sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Value', hits: 1234)])
        allow(view).to receive_messages(facet_group_names: [nil, 'group_1'], facet_field_names: [:facet_field_1], facet_limit_for: 10)
        @response = double
        allow(@response).to receive(:aggregations).and_return("facet_field_1" => @mock_display_facet_1)
      end

      it "has a header" do
        allow(view).to receive_messages(render_facet_partials: '')
        render
        expect(rendered).to have_selector('.facets-heading')
        expect(rendered).to have_selector('#facets-group_1')
      end
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
