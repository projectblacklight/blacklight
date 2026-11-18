# frozen_string_literal: true

RSpec.describe Blacklight::Document::CacheKey, :api do
  subject(:document) { document_class.new(attributes) }

  let(:attributes) { {} }
  let(:document_class) { SolrDocument }

  # A SolrDocument subclass that keeps SolrDocument's model name, which is part of the cache key
  def solr_document_subclass(&)
    Class.new(SolrDocument) do
      def self.model_name
        SolrDocument.model_name
      end

      class_eval(&)
    end
  end

  it 'SolrDocument includes the module' do
    expect(document.class).to include(described_class)
  end

  describe 'new record' do
    let(:document_class) do
      solr_document_subclass do
        def new_record?
          true
        end
      end
    end

    it 'provides an acceptable cache key' do
      expect(document.cache_key).to eq 'solr_documents/new'
    end
  end

  describe 'with version' do
    let(:attributes) { { id: '12345', _version_: '1497353774427013120' } }

    it 'provides a cache key with the id and version' do
      expect(document.cache_key).to eq 'solr_documents/12345-1497353774427013120'
    end

    describe 'as array' do
      let(:attributes) { { id: '12345', _version_: %w[1234 4321] } }

      it 'provides a cache key with the id and joined version array' do
        expect(document.cache_key).to eq 'solr_documents/12345-12344321'
      end
    end
  end

  describe 'without version' do
    let(:attributes) { { id: '12345' } }

    it 'provides a cache key with just the id' do
      expect(document.cache_key).to eq 'solr_documents/12345'
    end
  end

  describe '#cache_version_key' do
    let(:attributes) { { id: '12345', another_version_field: '1497353774427013120' } }
    let(:document_class) do
      solr_document_subclass do
        def cache_version_key
          :another_version_field
        end
      end
    end

    it 'provides a cache key with the defined field' do
      expect(document.cache_key).to eq 'solr_documents/12345-1497353774427013120'
    end
  end
end
