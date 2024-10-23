# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchContext::ServerItemPaginationComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:current_document_id) { 9 }
  let(:current_document) { SolrDocument.new(id: current_document_id) }
  let(:search_session) { { 'document_id' => current_document_id, 'counter' => 1, 'total' => '3' } }
  let(:instance) { described_class.new(search_context: search_context, search_session: search_session, current_document: current_document) }

  before do
    allow(controller).to receive(:current_search_session).and_return(double(id: current_document_id))
    controller.class.helper_method :current_search_session
  end

  context 'when there is no next or previous' do
    let(:search_context) { {} }

    it "does not render content" do
      expect(render.to_html).to be_blank
    end
  end

  context 'when there is exactly one search result with no next or previous document' do
    let(:search_context) { { prev: nil, next: nil } }
    let(:search_session) { { 'document_id' => current_document_id, 'counter' => 1, 'total' => '1' } }

    it "renders single page count" do
      expect(render.to_html).to include '<strong>1</strong> of <strong>1</strong>'
      expect(render.css('span.previous').to_html).to be_blank
      expect(render.css('span.next').to_html).to be_blank
    end
  end

  context 'when there is next and previous' do
    let(:search_context) { { next: next_doc, prev: prev_doc } }
    let(:prev_doc) { SolrDocument.new(id: '777') }
    let(:next_doc) { SolrDocument.new(id: '888') }

    before do
      # allow(controller).to receive(:controller_tracking_method).and_return('track_catalog_path')

      allow(controller).to receive_messages(controller_name: 'catalog', link_to_previous_document: '', link_to_next_document: '')
    end

    it "renders content" do
      expect(render.css('.search-context.page-links').to_html).not_to be_blank
    end

    context "session and document are out of sync" do
      let(:current_document) { SolrDocument.new(id: current_document_id + 1) }

      it "does not render content" do
        expect(render.to_html).to be_blank
      end
    end
  end
end
