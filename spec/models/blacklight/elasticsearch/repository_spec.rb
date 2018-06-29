# frozen_string_literal: true

RSpec.describe Blacklight::Elasticsearch::Repository, api: true do
  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  let(:repo) do
    described_class.new blacklight_config
  end

  describe '#find' do
    let(:mock_response) { double }

    it 'returns a response' do
      allow(repo.connection).to receive(:find).with('123').and_return(mock_response)
      expect(repo.find('123')).to be_a_kind_of Blacklight::Elasticsearch::Repository::SingleDocumentResponse
    end

    context 'when the document is not in the repo' do
      it 'raises an exception' do
        allow(repo.connection).to receive(:find).and_raise(Elasticsearch::Persistence::Repository::DocumentNotFound)
        expect { repo.find('123') }.to raise_error Blacklight::Exceptions::RecordNotFound
      end
    end
  end

  describe '#search' do
    let(:mock_response) { double }
    let(:params) { { q: 'foo' } }

    it 'returns a response' do
      allow(repo.connection).to receive(:search).with(params).and_return(mock_response)
      expect(repo.search(params)).to be_a_kind_of Blacklight::Elasticsearch::Repository::SearchResponse
    end
  end

  describe '#suggestions' do
    it 'returns a response' do
      expect(repo.suggestions({})).to be_a_kind_of Blacklight::Suggest::Response
    end
  end
end
