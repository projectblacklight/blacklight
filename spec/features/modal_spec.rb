# frozen_string_literal: true

RSpec.describe 'Modal' do
  it 'can open and dismiss the email modal', :js do
    visit solr_document_path('2007020969')
    expect(page).to have_no_selector 'dialog#blacklight-modal'
    click_on 'Email'
    expect(page).to have_css 'dialog#blacklight-modal'
    find('button[aria-label=Close]').click
    expect(page).to have_no_selector 'dialog#blacklight-modal'
  end
end
