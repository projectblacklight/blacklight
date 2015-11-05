require 'spec_helper'

describe SuggestController do
  routes { Blacklight::Engine.routes }
  describe 'GET index' do
    it 'returns JSON' do
      get :index, format: 'json'
      expect(response.body).to eq [].to_json
    end
    it 'returns suggestions' do
      get :index, format: 'json', q: 'new'
      json = JSON.parse(response.body)
      expect(json.count).to eq 3
      expect(json.first['term']).to eq 'new jersey'
    end
  end
end
