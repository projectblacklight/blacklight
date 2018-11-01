# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::JsonPresenter, api: true do
  let(:response) do
    instance_double(Blacklight::Solr::Response,
                    documents: docs,
                    prev_page: nil,
                    next_page: 2,
                    total_pages: 3,
                    aggregations: aggregations)
  end
  let(:docs) do
    [
      SolrDocument.new(id: '123', title_tsim: 'Book1', author_tsim: 'Julie'),
      SolrDocument.new(id: '456', title_tsim: 'Book2', author_tsim: 'Rosie')
    ]
  end

  let(:aggregations) do
    { 'format_si' => Blacklight::Solr::Response::Facets::FacetField.new("format_si", [{ label: "Book", value: 'Book', hits: 20 }]) }
  end

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'format', field: 'format_si', label: 'Format'
      config.add_index_field 'title_tsim', label: 'Title:'
    end
  end

  let(:presenter) { described_class.new(response, config) }

  describe '#search_facets' do
    let(:search_facets) { presenter.search_facets }

    context 'with defined facets that are present in the response' do
      it 'returns them' do
        expect(search_facets.map(&:name)).to eq ['format_si']
      end
    end

    context 'when there are defined facets that are not in the response' do
      before do
        config.add_facet_field 'example_query_facet_field', label: 'Publish Date', query: {}
      end

      let(:aggregations) do
        {
          'format_si' => Blacklight::Solr::Response::Facets::FacetField.new("format_si", [{ label: "Book", value: 'Book', hits: 20 }]),
          'example_query_facet_field' => Blacklight::Solr::Response::Facets::FacetField.new("example_query_facet_field", [])
        }
      end

      it 'filters out the facets that are not defined' do
        expect(search_facets.map(&:name)).to eq ['format_si']
      end
    end
  end
end
