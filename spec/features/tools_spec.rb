# frozen_string_literal: true

RSpec.describe 'Tools' do
  before { visit solr_document_path('2007020969') }
  it 'displays Email modal properly' do
    click_link 'Email'
    expect(find('div.modal-header')).to have_text 'Email This'
    expect(page).to have_selector('form#email_form')
  end

  it 'displays SMS modal properly' do
    click_link 'SMS'
    expect(find('div.modal-header')).to have_text 'SMS This'
    expect(page).to have_selector('form#sms_form')
  end
end
