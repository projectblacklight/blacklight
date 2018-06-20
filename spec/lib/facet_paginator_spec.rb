# -*- encoding : utf-8 -*-
# Spec tests for Paginator class found in lib/blacklight/solr/facet_paginator.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Blacklight::Solr::FacetPaginator' do
  before(:all) do
    require 'yaml'
    @seven_facet_values = YAML::load("--- \n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 792\n  value: Book\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 65\n  value: Musical Score\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 58\n  value: Serial\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 48\n  value: Musical Recording\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 37\n  value: Microform\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 27\n  value: Thesis\n- !ruby/object:Blacklight::SolrResponse::Facets::FacetItem \n  hits: 0\n  value: \n")
    @six_facet_values = @seven_facet_values.slice(1,6)
    @limit = 6

    @sort_key = Blacklight::Solr::FacetPaginator.request_keys[:sort]
    @page_key = Blacklight::Solr::FacetPaginator.request_keys[:page]
  end
  context 'when there are limit+1 results' do
    before(:each) do
      @paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :limit => 6)
    end
    it 'should have next' do
      expect(@paginator).to be_has_next
    end

  end
  it 'should not have next when there are fewer results' do
    paginator = Blacklight::Solr::FacetPaginator.new(@six_facet_values, :offset => 0, :limit => @limit)

    expect(paginator).not_to be_has_next
  end
  context 'when offset is greater than 0' do
    before(:each) do
      @offset = 100
      @paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :offset => @offset, :limit => @limit)
    end
  
    it 'should have previous' do    
      expect(@paginator).to be_has_previous
    end

  end
  it 'should not have previous when offset is 0' do
    paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :offset => 0, :limit => @limit)

    expect(paginator).not_to be_has_previous
  end
  it 'should know a manually set sort, and produce proper sort url' do
      paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :offset => 100, :limit => @limit, :sort => 'index')

      expect(paginator.sort).to eq('index')
      
      click_params = paginator.params_for_resort_url('count', {})

      expect(click_params[ @sort_key ]).to eq('count')
      expect(click_params[ @page_key ]).to be_nil
  end
  it 'should limit items to limit, if limit is smaller than items.length' do
    paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :offset => 100, :limit => 6, :sort => 'index')
    expect(paginator.items.length).to eq(6)
  end
  it 'should return all items when limit is greater than items.length' do
    paginator = Blacklight::Solr::FacetPaginator.new(@six_facet_values, :offset => 100, :limit => 6, :sort => 'index')
    expect(paginator.items.length).to eq(6)
  end
  describe "for a nil :limit" do
    before(:all) do
      @paginator = Blacklight::Solr::FacetPaginator.new(@seven_facet_values, :offset => 100, :limit => nil, :sort => 'index')
    end
    it 'should return all items' do
      expect(@paginator.items).to eq(@seven_facet_values)      
    end
    it 'should not has_next?' do
      expect(@paginator).not_to be_has_next
    end
    it 'should not has_previous?' do
      expect(@paginator).not_to be_has_previous
    end
  end
  
end
