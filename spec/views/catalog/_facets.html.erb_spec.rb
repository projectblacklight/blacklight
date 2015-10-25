require 'spec_helper'

describe "catalog/_facets" do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config)
    allow(view).to receive(:search_action_path) do |*args|
      catalog_index_url *args
    end
  end

  context "without any facet fields" do
    it "should not have a header if no facets are displayed" do
      allow(view).to receive_messages(:render_facet_partials => '')
      render
      expect(rendered).to_not have_selector('h4')
    end
  end
  context "with facet fields" do

    let :facet_field do
      Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label').normalize!
    end

    before do
      blacklight_config.facet_fields['facet_field_1'] = facet_field

        @mock_display_facet_1 = double(:name => 'facet_field_1', sort: nil, offset: nil, :items => [Blacklight::Solr::Response::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
        allow(view).to receive_messages(:facet_field_names => [:facet_field_1],
                  :facet_limit_for => 10 )

        @response = double()
        allow(@response).to receive(:aggregations).and_return("facet_field_1" => @mock_display_facet_1)
    end

    it "should have a header" do
      allow(view).to receive_messages(:render_facet_partials => '')
      render
      expect(rendered).to have_selector('.facets-heading')
    end


    describe "facet display" do
      it "should have a(n accessible) header" do
        render
        expect(rendered).to have_selector('.facet-field-heading')
      end

      it "should list values" do
        render

        # The .facet-content class is used by blacklight_range_limit js, and
        # should be applied to the .panel-collapse div that contains the collapsible
        # facet content. Please make sure it remains if possible. 
        expect(rendered).to have_selector('.facet-content a.facet_select')
        expect(rendered).to have_selector('.facet-content .facet-count')    
      end
    end
  end
end

