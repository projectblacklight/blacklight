# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /catalog/suggest' do
  it 'returns suggestions' do
    get '/catalog/suggest?q=new'
    expect(response.body).to eq <<-RESULT
  <li role="option"><span>new jersey</span></li>
  <li role="option"><span>new jersey bridgeton biography</span></li>
  <li role="option"><span>new jersey bridgeton history</span></li>
  <li role="option"><span>new york</span></li>
  <li role="option"><span>nuwākshūṭ</span></li>
    RESULT
  end
end
