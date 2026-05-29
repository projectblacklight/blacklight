# frozen_string_literal: true

require 'spec_helper'

# Autocomplete suggestions are backed by the Solr suggester component.
RSpec.describe 'GET /catalog/suggest', :solr_only do
  it 'returns suggestions' do
    get '/catalog/suggest?q=new'
    expect(response.body).to eq <<-RESULT
  <li role="option" class="dropdown-item"><span>new jersey</span></li>
  <li role="option" class="dropdown-item"><span>new jersey bridgeton biography</span></li>
  <li role="option" class="dropdown-item"><span>new jersey bridgeton history</span></li>
  <li role="option" class="dropdown-item"><span>new york</span></li>
  <li role="option" class="dropdown-item"><span>nuwākshūṭ</span></li>
    RESULT
  end
end
