# frozen_string_literal: true

RSpec.describe Blacklight::ElasticSearch::Response, :api do
  subject(:response) do
    described_class.new(raw_response, request_params, blacklight_config: blacklight_config, document_model: SolrDocument)
  end

  let(:blacklight_config) do
    Blacklight::Configuration.new.tap do |config|
      config.add_facet_field 'format'
    end
  end

  let(:request_params) { { from: 10, size: 10 } }

  let(:raw_response) do
    {
      'took' => 5,
      'hits' => {
        'total' => { 'value' => 42 },
        'hits' => [
          { '_id' => 'abc', '_score' => 1.2, '_source' => { 'title_tsim' => ['A Title'] }, 'highlight' => { 'title_tsim' => ['A <em>Title</em>'] } },
          { '_id' => 'def', '_score' => 0.9, '_source' => { 'id' => 'def', 'title_tsim' => ['Another'] } }
        ]
      },
      'aggregations' => {
        'format' => {
          'buckets' => [
            { 'key' => 'Book', 'doc_count' => 30 },
            { 'key' => 'Journal', 'doc_count' => 12 }
          ]
        }
      }
    }
  end

  describe '#total' do
    it 'reads the hit total' do
      expect(response.total).to eq 42
    end

    context 'when the total is a plain integer (older ES / OpenSearch)' do
      let(:raw_response) { { 'hits' => { 'total' => 7, 'hits' => [] } } }

      it 'still works' do
        expect(response.total).to eq 7
      end
    end
  end

  describe '#documents' do
    it 'builds documents from the hits, deriving the id from _id when absent' do
      expect(response.documents.size).to eq 2
      expect(response.documents.first.id).to eq 'abc'
      expect(response.documents.first['title_tsim']).to eq ['A Title']
    end

    it 'attaches highlight data to the document source' do
      expect(response.documents.first['_highlighting']).to eq('title_tsim' => ['A <em>Title</em>'])
    end
  end

  describe '#aggregations' do
    it 'converts ES aggregations into Blacklight facet fields' do
      facet = response.aggregations['format']
      expect(facet.items.map(&:value)).to eq %w[Book Journal]
      expect(facet.items.map(&:hits)).to eq [30, 12]
    end

    it 'returns a null facet field for unknown facets' do
      expect(response.aggregations['unknown']).to be_a Blacklight::Solr::Response::Facets::NullFacetField
    end
  end

  describe 'pagination' do
    it 'reports start and rows from the request' do
      expect(response.start).to eq 10
      expect(response.rows).to eq 10
    end
  end

  describe 'disabled Solr features' do
    it 'is never grouped' do
      expect(response.grouped?).to be false
    end

    it 'returns empty spelling suggestions' do
      expect(response.spelling.words).to eq []
      expect(response.spelling.collation).to be_nil
    end

    it 'returns no more-like-this documents' do
      expect(response.more_like(response.documents.first)).to eq []
    end
  end
end
