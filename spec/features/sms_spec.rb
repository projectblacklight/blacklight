# frozen_string_literal: true

RSpec.describe 'SMS functionality' do
  before { visit solr_document_path('2007020969') }

  it 'displays SMS modal with form' do
    click_link 'SMS'
    expect(find('div.modal-header')).to have_text 'SMS This'
    fill_in 'Phone Number:', with: '555-555-5555'
    select 'Verizon', from: 'Carrier'
  end
end
