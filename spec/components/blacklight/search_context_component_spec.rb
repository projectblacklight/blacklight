# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchContextComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:current_document_id) { 9 }
  let(:current_document) { SolrDocument.new(id: current_document_id) }
  let(:search_session) { { 'document_id' => current_document_id } }
  let(:current_search_session) { double(id: current_document_id) }
  let(:instance) { described_class.new(search_context: search_context, search_session: search_session, current_document: current_document) }

  before do
    allow(controller).to receive(:current_search_session).and_return(current_search_session)
    allow(controller).to receive(:view_context).and_return(controller.view_context)
    allow(controller.view_context).to receive(:current_search_session).and_return(current_search_session)
    allow(controller.view_context).to receive(:search_session).and_return(search_session)
  end

  context 'when there is no next or previous' do
    let(:search_context) { {} }

    it "does not render content" do
      expect(render.to_html).to be_blank
    end
  end

  context 'when there is next and previous' do
    let(:search_context) { { next: next_doc, prev: prev_doc } }
    let(:prev_doc) { SolrDocument.new(id: '777') }
    let(:next_doc) { SolrDocument.new(id: '888') }

    before do
      # allow(controller).to receive(:controller_tracking_method).and_return('track_catalog_path')
      allow(controller).to receive(:controller_name).and_return('catalog')

      allow(controller).to receive(:link_to_previous_document).and_return('')
      allow(controller).to receive(:link_to_next_document).and_return('')
    end

    it "renders content" do
      expect(render.css('.pagination-search-widgets').to_html).not_to be_blank
    end

    context "session and document are out of sync" do
      let(:current_document) { SolrDocument.new(id: current_document_id + 1) }

      it "does not render content" do
        expect(render.to_html).to be_blank
      end
    end
  end
end
