# frozen_string_literal: true

RSpec.describe Blacklight::Suggest::Response, api: true do
  let(:empty_response) { described_class.new({}, { q: 'hello' }, 'suggest') }
  let(:full_response) do
    described_class.new(
      {
        'responseHeader' => {
          'status' => 200
        },
        'suggest' => {
          'mySuggester' => {
            'new' => {
              'numFound' => 3,
              'suggestions' => [
                {
                  'term' => 'new jersey',
                  'weight' => 3,
                  'payload' => ''
                },
                {
                  'term' => 'new jersey bridgeton biography',
                  'weight' => 3,
                  'payload' => ''
                },
                {
                  'term' => 'new jersey bridgeton history',
                  'weight' => 3,
                  'payload' => ''
                }
              ]
            }
          }
        }
      },
      {
        q: 'new'
      },
      'suggest'
    )
  end

  describe '#initialize' do
    it 'creates a Blacklight::Suggest::Response' do
      expect(empty_response).to be_an Blacklight::Suggest::Response
    end
  end
  describe '#suggestions' do
    it 'returns an array of suggestions' do
      expect(full_response.suggestions).to be_an Array
      expect(full_response.suggestions.count).to eq 3
      expect(full_response.suggestions.first['term']).to eq 'new jersey'
    end
  end
end
