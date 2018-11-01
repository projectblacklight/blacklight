# frozen_string_literal: true

RSpec.describe 'Autocomplete suggestions' do
  it 'search form has suggest path' do
    visit root_path
    expect(page).to have_css 'input[data-autocomplete-path="/catalog/suggest"]'
  end
end
