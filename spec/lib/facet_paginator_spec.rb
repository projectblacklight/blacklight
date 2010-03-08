# Spec tests for Paginator class found in lib/blacklight/solr/facet_paginator.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Blacklight::Solr::Facets::Paginator' do
  before(:all) do
    require 'yaml'
    @seven_facet_values = YAML::load("--- \n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 792\n  value: Book\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 65\n  value: Musical Score\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 58\n  value: Serial\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 48\n  value: Musical Recording\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 37\n  value: Microform\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 27\n  value: Thesis\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 0\n  value: \n")
    @six_facet_values = @seven_facet_values.slice(1,6)
    @limit = 6

    @sort_key = Blacklight::Solr::Facets::Paginator.request_keys[:sort]
    @offset_key = Blacklight::Solr::Facets::Paginator.request_keys[:offset]
    @limit_key = Blacklight::Solr::Facets::Paginator.request_keys[:limit]
  end

  it 'should have next when there are limit+1 results' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, @offset_key => 0, :limit => @limit)
    
    paginator.should be_has_next
  end
  it 'should not have next when there are fewer results' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@six_facet_values, :offset => 0, :limit => @limit)

    paginator.should_not be_has_next
  end
  it 'should have previous when offset is greater than 0' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, :offset => 10, :limit => @limit)

    paginator.should be_has_previous
  end
  it 'should not have previous when offset is 0' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, :offset => 0, :limit => @limit)

    paginator.should_not be_has_previous
  end
  it 'should know a manually set sort, and produce proper sort url' do
      paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, :offset => 100, :limit => @limit, :sort => 'index')

      paginator.sort.should == 'index'
      
      click_params = paginator.params_for_resort_url('count', {})

      click_params[ @sort_key ].should == 'count'
      click_params[ @offset_key ].to_s.should == "0"
  end
  it 'should limit items to limit, if limit is smaller than items.length' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, :offset => 100, :limit => 6, :sort => 'index')
    paginator.items.length.should == 6
  end
  it 'should return all items when limit is greater than items.length' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@six_facet_values, :offset => 100, :limit => 6, :sort => 'index')
    paginator.items.length.should == 6
  end
  
end
