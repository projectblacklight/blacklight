# frozen_string_literal: true

require 'elasticsearch'

RSpec.describe Blacklight::ElasticSearch::Repository, :api do
  subject(:repository) do
    described_class.new(blacklight_config).tap { |repo| repo.connection = connection }
  end

  let(:blacklight_config) do
    Blacklight::Configuration.new.tap do |config|
      config.response_model = Blacklight::ElasticSearch::Response
      config.document_model = SolrDocument
      config.connection_config = { adapter: 'elasticsearch', url: 'http://localhost:9200', index: 'blacklight-test' }
    end
  end

  let(:connection) { instance_double(Elasticsearch::Client) }

  let(:search_response) do
    {
      'hits' => {
        'total' => { 'value' => 1 },
        'hits' => [{ '_id' => '123', '_source' => { 'id' => '123' } }]
      }
    }
  end

  describe 'adapter class methods' do
    it 'declares the Elasticsearch companion classes' do
      expect(described_class.response_model).to eq Blacklight::ElasticSearch::Response
      expect(described_class.facet_paginator_class).to eq Blacklight::ElasticSearch::FacetPaginator
      expect(described_class.search_builder_behavior).to eq Blacklight::ElasticSearch::SearchBuilderBehavior
      expect(described_class.document_mixin).to eq Blacklight::ElasticSearch::Document
    end
  end

  describe '#index_name' do
    it 'reads the index from the connection config' do
      expect(repository.index_name).to eq 'blacklight-test'
    end
  end

  describe '#search' do
    before { allow(connection).to receive(:search).and_return(search_response) }

    it 'sends the request body to the configured index and wraps the response' do
      response = repository.search(params: { query: { match_all: {} } })

      expect(connection).to have_received(:search).with(index: 'blacklight-test', body: { query: { match_all: {} } })
      expect(response).to be_a Blacklight::ElasticSearch::Response
      expect(response.total).to eq 1
    end

    it 'warns when called with positional arguments' do
      allow(Blacklight.deprecation).to receive(:warn)
      repository.search({ query: { match_all: {} } })
      expect(Blacklight.deprecation).to have_received(:warn)
    end

    context 'when the cluster is unreachable' do
      before { allow(connection).to receive(:search).and_raise(Errno::ECONNREFUSED) }

      it 'raises a Blacklight exception' do
        expect { repository.search(params: {}) }.to raise_exception(Blacklight::Exceptions::ECONNREFUSED, /Unable to connect to Elasticsearch/)
      end
    end
  end

  describe '#find' do
    it 'queries by id' do
      allow(connection).to receive(:search).and_return(search_response)
      expect(repository.find('123')).to be_a Blacklight::ElasticSearch::Response
      expect(connection).to have_received(:search).with(index: 'blacklight-test', body: hash_including(query: { ids: { values: ['123'] } }))
    end

    it 'raises when nothing is found' do
      allow(connection).to receive(:search).and_return('hits' => { 'total' => { 'value' => 0 }, 'hits' => [] })
      expect { repository.find('missing') }.to raise_exception(Blacklight::Exceptions::RecordNotFound)
    end
  end

  describe '#ping?' do
    it 'delegates to the client' do
      allow(connection).to receive(:ping).and_return(true)
      expect(repository.ping?).to be true
    end
  end

  describe '#add' do
    it 'bulk indexes documents' do
      allow(connection).to receive(:bulk)
      repository.add([{ 'id' => '123' }])
      expect(connection).to have_received(:bulk).with(body: [
                                                        { index: { _index: 'blacklight-test', _id: '123' } },
                                                        { 'id' => '123' }
                                                      ])
    end
  end

  describe '#commit' do
    it 'refreshes the index' do
      indices = double('indices')
      allow(connection).to receive(:indices).and_return(indices)
      allow(indices).to receive(:refresh)
      repository.commit
      expect(indices).to have_received(:refresh).with(index: 'blacklight-test')
    end
  end

  describe '#create_index!' do
    let(:indices) { double('indices') }

    before { allow(connection).to receive(:indices).and_return(indices) }

    context 'when the index does not exist' do
      before do
        allow(indices).to receive(:exists?).and_return(false)
        allow(indices).to receive(:create)
      end

      it 'creates the index, mapping text fields as text and other strings as keyword' do
        repository.create_index!

        expect(indices).to have_received(:create) do |index:, body:|
          expect(index).to eq 'blacklight-test'
          templates = body.dig(:mappings, :dynamic_templates)
          text_rule = templates.find { |t| t.key?(:text_fields) }[:text_fields]
          string_rule = templates.find { |t| t.key?(:string_fields) }[:string_fields]
          text_matcher = Regexp.new(text_rule[:match])
          expect(text_matcher.match?('title_tsim')).to be true
          expect(text_matcher.match?('pub_date_si')).to be false
          expect(text_rule.dig(:mapping, :type)).to eq 'text'
          expect(string_rule.dig(:mapping, :type)).to eq 'keyword'
        end
      end

      context 'with a configured index mapping' do
        before { blacklight_config.elasticsearch_index_settings = { settings: { number_of_shards: 1 } } }

        it 'uses the configured mapping' do
          repository.create_index!
          expect(indices).to have_received(:create).with(index: 'blacklight-test', body: { settings: { number_of_shards: 1 } })
        end
      end
    end

    context 'when the index already exists' do
      before do
        allow(indices).to receive(:exists?).and_return(true)
        allow(indices).to receive(:create)
      end

      it 'does not recreate it' do
        repository.create_index!
        expect(indices).not_to have_received(:create)
      end
    end
  end
end
