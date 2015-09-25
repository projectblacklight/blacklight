require 'spec_helper'

describe Blacklight do
  
  context 'root' do

    let(:blroot) { File.expand_path(File.join(__FILE__, '..', '..', '..' )) }

    it 'should return the full path to the BL plugin' do
      expect(Blacklight.root).to eq blroot
    end

  end

  describe '.default_index' do
    context 'for a solr index' do
      before do
        allow(Blacklight).to receive(:connection_config).and_return(adapter: 'solr')
      end

      it 'is an instance of Blacklight::SolrRepository' do
        expect(Blacklight.default_index).to be_a Blacklight::SolrRepository
      end
    end
  end

  describe '.repository_class' do
    context 'for a solr index' do
      before do
        allow(Blacklight).to receive(:connection_config).and_return(adapter: 'solr')
      end

      it 'resolves to the SolrRepository implementation' do
        expect(Blacklight.repository_class).to eq Blacklight::SolrRepository
      end
    end

    context 'for an elastic_search index' do
      before do
        stub_const("Blacklight::ElasticSearch::Repository", double)
        allow(Blacklight).to receive(:connection_config).and_return(adapter: 'elastic_search')
      end

      it 'resolves to the SolrRepository implementation' do
        expect(Blacklight.repository_class).to eq Blacklight::ElasticSearch::Repository
      end
    end

    context 'for an explicitly provided class' do
      before do
        stub_const("CustomSearch::Repository", double)
        allow(Blacklight).to receive(:connection_config).and_return(adapter: 'CustomSearch::Repository')
      end

      it 'resolves to the custom implementation' do
        expect(Blacklight.repository_class).to eq CustomSearch::Repository
      end
    end
  end

  describe '.default_configuration' do
    it 'is a Blacklight configuration' do
      expect(Blacklight.default_configuration).to be_a Blacklight::Configuration
    end
  end
  
end
