# frozen_string_literal: true

RSpec.describe Blacklight::ElasticSearch::Request do
  subject(:request) { described_class.new }

  describe '#append_query' do
    it 'adds a clause to the bool must list' do
      request.append_query(simple_query_string: { query: 'foo' })
      expect(request.dig(:query, :bool, :must)).to eq [{ simple_query_string: { query: 'foo' } }]
    end

    it 'ignores blank queries' do
      request.append_query(nil)
      expect(request[:query]).to be_nil
    end
  end

  describe '#append_filter_query' do
    it 'adds a clause to the bool filter list' do
      request.append_filter_query(terms: { 'format' => ['Book'] })
      expect(request.dig(:query, :bool, :filter)).to eq [{ terms: { 'format' => ['Book'] } }]
    end
  end

  describe '#append_must_not' do
    it 'adds a clause to the bool must_not list' do
      request.append_must_not(exists: { field: 'format' })
      expect(request.dig(:query, :bool, :must_not)).to eq [{ exists: { field: 'format' } }]
    end
  end

  describe '#append_aggregation' do
    it 'adds the aggregation under the aggs key' do
      request.append_aggregation('format', terms: { field: 'format', size: 11 })
      expect(request[:aggs]).to eq('format' => { terms: { field: 'format', size: 11 } })
    end
  end

  describe '#append_highlight_field' do
    it 'registers the field for highlighting' do
      request.append_highlight_field('title')
      expect(request.dig(:highlight, :fields)).to eq('title' => {})
    end
  end
end
