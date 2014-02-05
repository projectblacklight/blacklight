require 'spec_helper'

describe "catalog/_facets" do
  before do
    @mock_config = Blacklight::Configuration.new
    view.stub(:blacklight_config => @mock_config)
  end

  describe "facet groups" do
    describe "default facet group" do
      it "should not have a header if no facets are displayed" do
        view.stub(:render_facet_partials => '')
        render
        expect(rendered).to_not have_selector('h4')
      end

      it "should have a header" do

        @mock_field_1 = double(:field => 'facet_field_1',
                       :label => 'label', :group => nil)
        @mock_display_facet_1 = double(:name => 'facet_field_1', :items => [Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
        view.stub(:facet_group_names => [nil], :facet_field_names => [:facet_field_1],
                :facet_limit_for => 10 )

        @response = double()
        @response.stub(:facet_by_field_name).with(:facet_field_1) { @mock_display_facet_1 }

        view.stub(:render_facet_partials => '')
        render
        expect(rendered).to have_selector('h4')
      end
    end

    describe "named facet group" do
      it "should not have a header if no facets are displayed" do
        view.stub(:render_facet_partials => '')
        render
        expect(rendered).to_not have_selector('h4')
        expect(rendered).to_not have_selector('#facets-group_1')
      end

      it "should have a header" do

        @mock_field_1 = double(:field => 'facet_field_1',
                       :label => 'label', :group => 'group_1')
        @mock_display_facet_1 = double(:name => 'facet_field_1', :items => [Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
        view.stub(:facet_group_names => [nil, 'group_1'], 
                :facet_limit_for => 10 )
        view.stub(:facet_field_names).with('group_1').and_return([:facet_field_1])

        @response = double()
        @response.stub(:facet_by_field_name).with(:facet_field_1) { @mock_display_facet_1 }

        view.stub(:render_facet_partials => '')
        render
        expect(rendered).to have_selector('h4')
        expect(rendered).to have_selector('#facets-group_1')
      end

    end
  end

  describe "facet display" do
    before do
      @mock_field_1 = double(:field => 'facet_field_1',
                       :label => 'label', :group => nil)
      @mock_display_facet_1 = double(:name => 'facet_field_1', :items => [Blacklight::SolrResponse::Facets::FacetItem.new(:value => 'Value', :hits => 1234)])
      view.stub(:facet_group_names => [nil], :facet_field_names => [:facet_field_1],
                :facet_limit_for => 10 )

      @response = double()
      @response.stub(:facet_by_field_name).with(:facet_field_1) { @mock_display_facet_1 }

    end 

    it "should have a(n accessible) header" do
      render
      expect(rendered).to have_selector('h5')
    end

    it "should list values" do
      render
      expect(rendered).to have_selector('a.facet_select')
      expect(rendered).to have_selector('.facet-count')
    end

  end
end

