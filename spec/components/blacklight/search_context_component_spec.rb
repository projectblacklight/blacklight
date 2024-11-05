# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Blacklight::SearchContextComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:current_document_id) { 9 }
  let(:search_session) { { 'document_id' => current_document_id, 'counter' => 1, 'total' => '3' } }
  let(:instance) { described_class.new(search_context: search_context, search_session: search_session) }

  before do
    allow(controller).to receive(:search_session).and_return(search_session)
    allow(controller).to receive(:current_search_session).and_return(double(id: current_document_id))
    controller.class.helper_method :search_session
    controller.class.helper_method :current_search_session
  end

  context 'when there is next and previous' do
    let(:search_context) { { next: next_doc, prev: prev_doc } }
    let(:prev_doc) { SolrDocument.new(id: '777') }
    let(:next_doc) { SolrDocument.new(id: '888') }

    before do
      allow(controller).to receive_messages(controller_name: 'catalog', link_to_previous_document: '', link_to_next_document: '')
    end

    it "renders content" do
      expect(render.css('.page-links').to_html).not_to be_blank
    end
  end
end
