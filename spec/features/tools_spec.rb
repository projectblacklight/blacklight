# frozen_string_literal: true

RSpec.describe 'Tools' do
  before { visit solr_document_path('2007020969') }
  it 'displays Email modal properly' do
    click_link 'Email'
    expect(find('div.modal-header')).to have_text I18n.t('blacklight.email.form.title')
    expect(find('div.modal-body')).to have_text I18n.t('blacklight.email.form.to')
  end

  it 'displays SMS modal properly' do
    click_link 'SMS'
    expect(find('div.modal-header')).to have_text I18n.t('blacklight.sms.form.title')
    expect(find('div.modal-body')).to have_text I18n.t('blacklight.sms.form.to')
  end
end
