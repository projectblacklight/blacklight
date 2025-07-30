# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::DocumentComponent, type: :component do
  subject(:component) { described_class.new(document: document, **attr) }

  let(:attr) { {} }
  let(:view_context) { vc_test_controller.view_context }

  let(:document) { view_context.document_presenter(presented_document) }

  let(:presented_document) do
    SolrDocument.new(
      id: 'x',
      thumbnail_path_ss: 'http://example.com/image.jpg',
      title_tsim: 'Title',
      isbn_ssim: ['Value']
    )
  end

  let(:blacklight_config) do
    CatalogController.blacklight_config.deep_copy.tap do |config|
      config.track_search_session.storage = false
      config.index.thumbnail_field = 'thumbnail_path_ss'
      config.index.document_actions[:bookmark].partial = '/catalog/bookmark_control'
    end
  end

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(vc_test_controller).to receive_messages(view_context: view_context, current_or_guest_user: User.new, blacklight_config: blacklight_config)
    allow(view_context).to receive_messages(search_session: {}, current_search_session: nil, current_bookmarks: [])
  end

  it 'has some defined content areas' do
    component.with_title { 'Title' }
    component.with_embed('Embed')
    component.with_metadata('Metadata')
    component.with_thumbnail('Thumbnail')
    component.with_actions { 'Actions' }
    render_inline component

    expect(page).to have_content 'Title'
    expect(page).to have_content 'Embed'
    expect(page).to have_content 'Metadata'
    expect(page).to have_content 'Thumbnail'
    expect(page).to have_content 'Actions'
  end

  it 'has schema.org properties' do
    component.with_body { '-' }
    render_inline component

    expect(page).to have_css 'article[@itemtype="http://schema.org/Thing"]'
    expect(page).to have_css 'article[@itemscope]'
  end

  context 'with a provided body' do
    it 'opts-out of normal component content' do
      component.with_body { 'Body content' }
      render_inline component

      expect(page).to have_content 'Body content'
      expect(page).to have_no_css 'header'
      expect(page).to have_no_css 'dl'
    end
  end

  context 'index view' do
    before do
      vc_test_controller.action_name = "index"
    end

    let(:attr) { { counter: 5 } }

    it 'has data properties' do
      component.with_body { '-' }
      render_inline component

      expect(page).to have_css 'article[@data-document-id="x"]'
      expect(page).to have_css 'article[@data-document-counter="5"]'
    end

    it 'renders a linked title' do
      render_inline component

      expect(page).to have_link 'Title', href: '/catalog/x'
    end

    it 'renders a counter with the title' do
      render_inline component

      expect(page).to have_css 'header', text: '5. Title'
    end

    context 'with a document rendered as part of a collection' do
      let(:document_counter) { 10 }
      let(:attr) { { document_counter: document_counter, counter_offset: 100 } }

      it 'renders a counter with the title' do
        render_inline component

        expect(page).to have_css 'header', text: '111. Title'
      end
    end

    it 'renders actions' do
      render_inline component

      expect(page).to have_css '.index-document-functions'
    end

    it 'renders a thumbnail' do
      render_inline component

      expect(page).to have_css 'a[href="/catalog/x"] img[src="http://example.com/image.jpg"]'
    end

    context 'with default metadata component' do
      it 'renders metadata' do
        render_inline component

        expect(page).to have_css 'dl.document-metadata'
        expect(page).to have_css 'dt', text: 'Title:'
        expect(page).to have_css 'dd', text: 'Title'
        expect(page).to have_no_css 'dt', text: 'ISBN:'
      end
    end
  end

  context 'show view' do
    let(:attr) { { title_component: :h1, show: true } }

    before do
      vc_test_controller.action_name = "show"
    end

    it 'renders with an id' do
      component.with_body { '-' }
      render_inline component

      expect(page).to have_css 'article#document'
    end

    it 'renders a title' do
      render_inline component

      expect(page).to have_css 'h1', text: 'Title'
    end

    it 'renders with show-specific metadata' do
      render_inline component

      expect(page).to have_css 'dl.document-metadata'
      expect(page).to have_css 'dt', text: 'ISBN:'
      expect(page).to have_css 'dd', text: 'Value'
    end

    context 'with an embed component' do
      before do
        vc_test_controller.action_name = "show"

        stub_const('StubComponent', Class.new(ViewComponent::Base) do
          def initialize(**); end

          def call
            'embed'.html_safe
          end
        end)

        blacklight_config.show.embed_component = StubComponent
        render_inline component
      end

      it 'renders an embed' do
        expect(page).to have_content 'embed'
      end
    end

    context 'show view with custom translation' do
      let!(:original_translations) { I18n.backend.send(:translations).deep_dup }

      before do
        vc_test_controller.action_name = "show"
        I18n.backend.store_translations(:en, blacklight: { search: { show: { label: "testing:%{label}" } } })
        render_inline component
      end

      after do
        I18n.backend.reload!
        I18n.backend.store_translations(:en, original_translations[:en])
      end

      it 'renders with show-specific metadata with correct translation' do
        expect(page).to have_css 'dl.document-metadata'
        expect(page).to have_css 'dt', text: 'testing:ISBN'
        expect(page).to have_css 'dd', text: 'Value'
      end
    end

    context 'with configured metadata component' do
      let(:custom_component_class) do
        Class.new(Blacklight::DocumentMetadataComponent) do
          # Override component rendering with our own value
          def call
            'blah'.html_safe
          end
        end
      end

      before do
        stub_const('MyMetadataComponent', custom_component_class)
        blacklight_config.show.metadata_component = MyMetadataComponent
        render_inline component
      end

      it 'renders custom component' do
        expect(page).to have_text 'blah'
      end
    end

    context 'with configured title component' do
      let(:custom_component_class) do
        Class.new(Blacklight::DocumentTitleComponent) do
          # Override component rendering with our own value
          def call
            'Titleriffic'.html_safe
          end
        end
      end

      before do
        stub_const('MyTitleComponent', custom_component_class)
        blacklight_config.show.title_component = MyTitleComponent
        render_inline component
      end

      it 'renders custom component' do
        expect(page).to have_text 'Titleriffic'
      end
    end
  end

  context 'with partials' do
    before do
      component.with_partial { 'Partials' }
      render_inline component
    end

    it 'renders partials' do
      expect(page).to have_content 'Partials'
    end
  end

  context 'with no partials (default behavior)' do
    before do
      render_inline component
    end

    it 'has no partials by default' do
      expect(component.partials?).to be false
    end
  end

  context 'with before_titles' do
    before do
      render_inline(component) do |inner_c|
        inner_c.with_title do |c|
          c.with_before_title { 'Prefix!' }
        end
      end
    end

    it 'shows the prefix' do
      expect(page).to have_content "Prefix!"
    end
  end
end
