# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom view type' do
  it 'uses the custom view config' do
    get '/catalog?q=new&view=gallery'
    expect(response.body).to include 'TEST"Strong Medicine speaks"'
  end
end
