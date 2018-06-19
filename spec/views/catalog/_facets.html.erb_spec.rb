require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "catalog/_facets" do
  before do
    @mock_config = Blacklight::Configuration.new
    allow(view).to receive_messages(:blacklight_config => @mock_config)
  end
  it "should not have a header if no facets are displayed" do
    allow(view).to receive_messages(:render_facet_partials => '')
    render
    expect(rendered).not_to have_selector('h4')
  end

  it "should have a header" do

      @mock_field_1 = double(:field => 'facet_field_1',
                       :label => 'label')
      @mock_display_facet_1 = double(:name => 'facet_field_1', :items => [Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
      allow(view).to receive_messages(:facet_field_names => [:facet_field_1],
                :facet_limit_for => 10 )

      @response = double()
      allow(@response).to receive(:facet_by_field_name).with(:facet_field_1) { @mock_display_facet_1 }

    allow(view).to receive_messages(:render_facet_partials => '')
    render
    expect(rendered).to have_selector('h4')
  end

  describe "facet display" do
    before do
      @mock_field_1 = double(:field => 'facet_field_1',
                       :label => 'label')
      @mock_display_facet_1 = double(:name => 'facet_field_1', :items => [Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
      allow(view).to receive_messages(:facet_field_names => [:facet_field_1],
                :facet_limit_for => 10 )

      @response = double()
      allow(@response).to receive(:facet_by_field_name).with(:facet_field_1) { @mock_display_facet_1 }

    end 

    it "should have a(n accessible) header" do
      render
      expect(rendered).to have_selector('h5')
      expect(rendered).to have_selector('h5 > a')
    end

    it "should list values" do
      render
      expect(rendered).to have_selector('a.facet_select')
      expect(rendered).to have_selector('.count')
    end

  end
end

