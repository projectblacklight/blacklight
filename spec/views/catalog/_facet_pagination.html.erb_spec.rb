# -*- encoding : utf-8 -*-
# Spec tests for _facet_pagination.html.erb view found in app/view/catalog/_facet_pagination.html.erb

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'catalog/_facet_pagination' do
  before do
    require 'yaml'
    @seven_facet_values = YAML::load("--- \n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 792\n  value: Book\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 65\n  value: Musical Score\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 58\n  value: Serial\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 48\n  value: Musical Recording\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 37\n  value: Microform\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 27\n  value: Thesis\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 0\n  value: \n")

    @mock_config = Blacklight::Configuration.new
    view.stub(:blacklight_config => @mock_config)

  end
  
 
    it "should not have form filter" do
      @pagination = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :limit => 5)
      render
      rendered.should_not have_selector('#filter_facet')
    end

    it "should have form filter" do
      @pagination = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :limit => 5, :can_filter => true)
      params[:id] = 'facet_field_1'
      render
      rendered.should have_selector('#filter_facet')
    end

  
 end
