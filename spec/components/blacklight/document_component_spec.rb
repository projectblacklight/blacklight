# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::DocumentComponent, type: :component do
  subject(:component) { described_class.new(document: document, **attr) }

  let(:attr) { {} }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:document) do
    SolrDocument.new(
      id: 'x',
      thumbnail_path_ss: 'http://example.com/image.jpg',
      title_tsim: 'Title',
      isbn_ssim: ['Value']
    )
  end

  let(:blacklight_config) do
    CatalogController.blacklight_config.deep_copy.tap do |config|
      config.track_search_session = false
      config.index.thumbnail_field = 'thumbnail_path_ss'
      config.index.document_actions[:bookmark].partial = '/catalog/bookmark_control.html.erb'
    end
  end

  before do
    allow(controller).to receive(:current_or_guest_user).and_return(User.new)
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view_context).to receive(:search_session).and_return({})
    allow(view_context).to receive(:current_search_session).and_return(nil)
    allow(view_context).to receive(:current_bookmarks).and_return([])
  end

  it 'has some defined content areas' do
    component.with(:title, 'Title')
    component.with(:embed, 'Embed')
    component.with(:metadata, 'Metadata')
    component.with(:thumbnail, 'Thumbnail')
    component.with(:actions, 'Actions')

    expect(rendered).to have_content 'Title'
    expect(rendered).to have_content 'Embed'
    expect(rendered).to have_content 'Metadata'
    expect(rendered).to have_content 'Thumbnail'
    expect(rendered).to have_content 'Actions'
  end

  it 'has schema.org properties' do
    component.with(:body, '-')

    expect(rendered).to have_selector 'article[@itemtype="http://schema.org/Thing"]'
    expect(rendered).to have_selector 'article[@itemscope]'
  end

  context 'with a provided body' do
    it 'opts-out of normal component content' do
      component.with(:body, 'Body content')

      expect(rendered).to have_content 'Body content'
      expect(rendered).not_to have_selector 'header'
      expect(rendered).not_to have_selector 'dl'
    end
  end

  context 'index view' do
    let(:attr) { { counter: 5 } }

    it 'has data properties' do
      component.with(:body, '-')

      expect(rendered).to have_selector 'article[@data-document-id="x"]'
      expect(rendered).to have_selector 'article[@data-document-counter="5"]'
    end

    it 'renders a linked title' do
      expect(rendered).to have_link 'Title', href: '/catalog/x'
    end

    it 'renders a counter with the title' do
      expect(rendered).to have_selector 'header', text: '5. Title'
    end

    context 'with a document rendered as part of a collection' do
      let(:attr) { { document_counter: 10, counter_offset: 100 } }

      it 'renders a counter with the title' do
        expect(rendered).to have_selector 'header', text: '111. Title'
      end
    end

    it 'renders actions' do
      expect(rendered).to have_selector '.index-document-functions'
    end

    it 'renders a thumbnail' do
      expect(rendered).to have_selector 'a[href="/catalog/x"] img[src="http://example.com/image.jpg"]'
    end
  end

  context 'show view' do
    let(:attr) { { title_component: :h1, show: true } }

    before do
      allow(view_context).to receive(:action_name).and_return('show')
    end

    it 'renders with an id' do
      component.with(:body, '-')

      expect(rendered).to have_selector 'article#document'
    end

    it 'renders a title' do
      expect(rendered).to have_selector 'h1', text: 'Title'
    end

    it 'renders with show-specific metadata' do
      expect(rendered).to have_selector 'dl.document-metadata'
      expect(rendered).to have_selector 'dt', text: 'ISBN:'
      expect(rendered).to have_selector 'dd', text: 'Value'
    end

    it 'renders an embed' do
      stub_const('StubComponent', Class.new(ViewComponent::Base) do
        def initialize(**); end

        def call
          'embed'
        end
      end)

      blacklight_config.show.embed_component = StubComponent
      expect(rendered).to have_content 'embed'
    end
  end

  it 'renders metadata' do
    expect(rendered).to have_selector 'dl.document-metadata'
    expect(rendered).to have_selector 'dt', text: 'Title:'
    expect(rendered).to have_selector 'dd', text: 'Title'
    expect(rendered).not_to have_selector 'dt', text: 'ISBN:'
  end
end
