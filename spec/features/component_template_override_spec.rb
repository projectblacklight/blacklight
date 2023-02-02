# frozen_string_literal: true

RSpec.describe 'Generated test application template at default path' do
  it 'unobtrusively overrides default top navbar component template' do
    visit root_path
    expect(page).to have_css 'nav[data-template-override="top_navbar_component"]'
  end
end
