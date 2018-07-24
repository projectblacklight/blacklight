# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::JsonPresenter, api: true do
  let(:response) { instance_double(Blacklight::Solr::Response, documents: docs, prev_page: nil, next_page: 2, total_pages: 3) }
  let(:docs) do
     [
       SolrDocument.new(id: '123', title_tsim: 'Book1', author_tsim: 'Julie'),
       SolrDocument.new(id: '456', title_tsim: 'Book2', author_tsim: 'Rosie')
     ]
  end

  let(:facets) do
    [
      Blacklight::Solr::Response::Facets::FacetField.new("format_si", [{ label: "Book", value: 'Book', hits: 20 }])
    ]
  end

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'format', field: 'format_si', label: 'Format'
      config.add_index_field 'title_tsim', label: 'Title:'
    end
  end

  let(:presenter) { described_class.new(response, facets, config) }


  describe '#search_facets_as_json' do
    subject { presenter.search_facets_as_json }

    context 'for defined facets that are present in the response' do
      it 'has a label' do
        expect(subject.first["label"]).to eq 'Format'
      end
    end


    context 'when there are defined facets that are not in the response' do
      before do
        config.add_facet_field 'example_query_facet_field', label: 'Publish Date', query: {}
      end

      let(:facets) do
        [
          Blacklight::Solr::Response::Facets::FacetField.new("format_si", [{ label: "Book", value: 'Book', hits: 20 }]),
          Blacklight::Solr::Response::Facets::FacetField.new("example_query_facet_field", [])
        ]
      end

      it 'shows only facets that are defined' do
        expect(subject.map { |f| f['name'] }).to eq ['format_si']
      end
    end
  end
end
