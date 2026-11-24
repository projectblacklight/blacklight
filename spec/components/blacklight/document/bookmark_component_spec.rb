# frozen_string_literal: true

RSpec.describe Blacklight::Document::BookmarkComponent, type: :component do
  subject(:component) { described_class.new(document: document, **attr) }

  let(:attr) { {} }
  let(:document) { SolrDocument.new(id: 'a') }
  let(:view_context) { vc_test_controller.view_context }
  let(:bookmarks) { [Bookmark.new(document: SolrDocument.new(id: 'a'))] }

  before do
    allow(vc_test_controller).to receive_messages(view_context: view_context, blacklight_config: CatalogController.blacklight_config)
    allow(view_context).to receive_messages(current_bookmarks: bookmarks, bookmark_path: '/bookmarks/a')
  end

  context 'when the document is bookmarked' do
    it 'renders a checked bookmark control' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"][checked]'
      expect(page).to have_button 'Remove bookmark'
    end
  end

  context 'when the document is not bookmarked' do
    let(:document) { SolrDocument.new(id: 'b') }

    it 'renders an unchecked bookmark control' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"]:not([checked])'
      expect(page).to have_button 'Bookmark'
    end
  end

  context 'when a bookmark has a different document type' do
    let(:bookmarks) { [Bookmark.new(document_id: 'a', document_type: 'OtherDocument')] }

    before do
      stub_const('OtherDocument', Class.new(SolrDocument))
    end

    it 'is not bookmarked' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"]:not([checked])'
    end
  end

  context 'with an explicit checked value' do
    let(:attr) { { checked: false } }

    it 'uses it without looking up the bookmarks' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"]:not([checked])'
      expect(view_context).not_to have_received(:current_bookmarks)
    end
  end

  context 'with bookmarks passed in' do
    let(:attr) { { bookmarks: [Bookmark.new(document: SolrDocument.new(id: 'z'))] } }
    let(:document) { SolrDocument.new(id: 'z') }

    it 'uses them without looking up the bookmarks' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"][checked]'
      expect(view_context).not_to have_received(:current_bookmarks)
    end

    context 'when the application overrides the bookmarked? helper' do
      before do
        allow(view_context).to receive(:bookmarked?).and_return(false)
      end

      it 'prefers the bookmarks that were passed in' do
        render_inline component

        expect(page).to have_css 'input[type="checkbox"][checked]'
        expect(view_context).not_to have_received(:bookmarked?)
      end
    end
  end

  context 'when the application overrides the bookmarked? helper' do
    let(:document) { SolrDocument.new(id: 'b') }

    before do
      allow(view_context).to receive(:bookmarked?).and_return(true)
    end

    it 'uses the helper' do
      render_inline component

      expect(page).to have_css 'input[type="checkbox"][checked]'
      expect(view_context).to have_received(:bookmarked?).with(document)
    end
  end
end
