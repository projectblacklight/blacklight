# frozen_string_literal: true

RSpec.describe 'Modal' do
  it 'can open and dismiss the email modal', js: true do
    visit solr_document_path('2007020969')
    expect(page).to have_no_selector 'dialog#blacklight-modal'
    click_link 'Email'
    expect(page).to have_selector 'dialog#blacklight-modal'
    click_button '×'
    expect(page).to have_no_selector 'dialog#blacklight-modal'
  end
end
