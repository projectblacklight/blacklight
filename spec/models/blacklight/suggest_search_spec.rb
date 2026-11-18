# frozen_string_literal: true

RSpec.describe Blacklight::SuggestSearch, :api do
  let(:params) { { q: 'test' } }
  let(:response) { instance_double(Blacklight::Suggest::Response) }
  let(:repository) { instance_double(Blacklight::Solr::Repository, suggestions: response) }
  let(:suggest_search) { described_class.new(params, repository) }

  describe '#suggestions' do
    it 'delegates to the repository' do
      expect(suggest_search.suggestions).to eq response
      expect(repository).to have_received(:suggestions).with({ q: 'test' })
    end
  end
end
