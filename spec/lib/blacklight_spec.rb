# frozen_string_literal: true

RSpec.describe Blacklight do
  context 'root' do
    let(:blroot) { File.expand_path(File.join(__FILE__, '..', '..', '..')) }

    it 'returns the full path to the BL plugin' do
      expect(described_class.root).to eq blroot
    end
  end

  describe '.default_index' do
    context 'for a solr index' do
      before do
        allow(described_class).to receive(:connection_config).and_return(adapter: 'solr')
      end

      it 'is an instance of Blacklight::Solr::Repository' do
        expect(described_class.default_index).to be_a Blacklight::Solr::Repository
      end
    end
  end

  describe '.repository_class' do
    context 'when the adapter key is missing' do
      before do
        allow(described_class).to receive(:connection_config).and_return({})
      end

      it 'raises an error' do
        expect { described_class.repository_class }.to raise_error RuntimeError, 'The value for :adapter was not found in the blacklight.yml config'
      end
    end

    context 'for a solr index' do
      before do
        allow(described_class).to receive(:connection_config).and_return(adapter: 'solr')
      end

      it 'resolves to the SolrRepository implementation' do
        expect(described_class.repository_class).to eq Blacklight::Solr::Repository
      end
    end

    context 'for an elastic_search index' do
      before do
        stub_const("Blacklight::ElasticSearch::Repository", double)
        allow(described_class).to receive(:connection_config).and_return(adapter: 'elastic_search')
      end

      it 'resolves to the SolrRepository implementation' do
        expect(described_class.repository_class).to eq Blacklight::ElasticSearch::Repository
      end
    end

    context 'for an explicitly provided class' do
      before do
        stub_const("CustomSearch::Repository", double)
        allow(described_class).to receive(:connection_config).and_return(adapter: 'CustomSearch::Repository')
      end

      it 'resolves to the custom implementation' do
        expect(described_class.repository_class).to eq CustomSearch::Repository
      end
    end
  end

  describe '.default_configuration' do
    it 'is a Blacklight configuration' do
      expect(described_class.default_configuration).to be_a Blacklight::Configuration
    end
  end
end
