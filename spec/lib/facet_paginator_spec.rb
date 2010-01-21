# Spec tests for Paginator class found in lib/blacklight/solr/facet_paginator.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Blacklight::Solr::Facets::Paginator' do
  before(:all) do
    require 'yaml'
    @seven_facet_values = YAML::load("--- \n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 792\n  value: Book\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 65\n  value: Musical Score\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 58\n  value: Serial\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 48\n  value: Musical Recording\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 37\n  value: Microform\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 27\n  value: Thesis\n- !ruby/object:RSolr::Ext::Response::Facets::FacetItem \n  hits: 0\n  value: \n")
    @six_facet_values = @seven_facet_values.slice(1,6)
    @limit = 6
  end

  it 'should have next when there are limit+1 results' do
    paginator = Blacklight::Solr::Facets::Paginator.new(@seven_facet_values, :offset => 0, :limit => @limit)
    
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
end
