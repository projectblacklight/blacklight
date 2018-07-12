# frozen_string_literal: true

RSpec.describe Blacklight::Document::CacheKey, api: true do
  let(:attributes) { {} }
  let(:subject) { SolrDocument.new(attributes) }
  it 'SolrDocument includes the module' do
    expect(subject.class).to include(Blacklight::Document::CacheKey)
  end

  describe 'new record' do
    before do
      allow(subject).to receive_messages(new_record?: true)
    end
    it 'provides an acceptable cache key' do
      expect(subject.cache_key).to eq 'solr_documents/new'
    end
  end

  describe 'with version' do
    let(:attributes) { { id: '12345', _version_: '1497353774427013120' } }
    it 'provides a cache key with the id and version' do
      expect(subject.cache_key).to eq 'solr_documents/12345-1497353774427013120'
    end
    describe 'as array' do
      let(:attributes) { { id: '12345', _version_: ['1234', '4321'] } }
      it 'provides a cache key with the id and joined version array' do
        expect(subject.cache_key).to eq 'solr_documents/12345-12344321'
      end
    end
  end

  describe 'without version' do
    let(:attributes) { { id: '12345' } }
    it 'provides a cache key with just the id' do
      expect(subject.cache_key).to eq 'solr_documents/12345'
    end
  end

  describe '#cache_version_key' do
    let(:attributes) { { id: '12345', another_version_field: '1497353774427013120' } }
    before do
      allow(subject).to receive_messages(cache_version_key: :another_version_field)
    end
    it 'provides a cache key with the defined field' do
      expect(subject.cache_key).to eq 'solr_documents/12345-1497353774427013120'
    end
  end
end
