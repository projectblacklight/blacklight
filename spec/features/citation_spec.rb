# frozen_string_literal: true

RSpec.describe 'Citation functionality' do
  before { visit solr_document_path('2007020969') }

  it 'displays the Cite modal with expected header' do
    click_on 'Cite'
    expect(find('div.modal-header')).to have_text 'Cite'
  end
end
