# frozen_string_literal: true

RSpec.describe Blacklight::SuggestSearch, api: true do
  let(:params) { {q: 'test'} }
  let(:response) { instance_double(Blacklight::Suggest::Response)}
  let(:repository) { instance_double(Blacklight::Solr::Repository, suggestions: response) }
  let(:suggest_search) { described_class.new(params, repository)}

  describe '#suggestions' do
    it 'delegates to the repository' do
      expect(repository).to receive(:suggestions).with(q: 'test').and_return(response)
      expect(suggest_search.suggestions).to eq response
    end
  end
end
