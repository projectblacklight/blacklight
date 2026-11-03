# frozen_string_literal: true

RSpec.describe Blacklight::OpenGraphPresenter, type: :presenter do
  subject(:open_graph) { described_class.new(document_presenter) }

  let(:view_context) { controller.view_context }
  let(:document) { SolrDocument.new(id: 'xyz') }
  let(:thumbnail_url) { 'http://example.com/image.jpg' }
  let(:thumbnail) { instance_double(Blacklight::ThumbnailPresenter, url: thumbnail_url) }
  let(:document_presenter) do
    instance_double(Blacklight::ShowPresenter, document: document, view_context: view_context, configuration: Blacklight::Configuration.new,
                                               html_title: 'A title', thumbnail: thumbnail)
  end

  describe '#properties' do
    it 'derives properties from the document presenter' do
      expect(open_graph.properties).to eq(
        'og:type' => 'website',
        'og:title' => 'A title',
        'og:image' => 'http://example.com/image.jpg'
      )
    end

    context 'when the document has no thumbnail url' do
      let(:thumbnail_url) { nil }

      it 'leaves out og:image' do
        expect(open_graph.properties).not_to have_key 'og:image'
      end
    end

    context 'with a subclass that provides a description' do
      subject(:open_graph) { custom_presenter_class.new(document_presenter) }

      let(:custom_presenter_class) do
        Class.new(described_class) do
          def description = 'A description'
        end
      end

      it 'includes og:description' do
        expect(open_graph.properties).to include 'og:description' => 'A description'
      end
    end
  end

  describe '#image' do
    context 'with a path' do
      let(:thumbnail_url) { '/images/thumbnail.jpg' }

      it 'returns an absolute url' do
        expect(open_graph.image).to eq 'http://test.host/images/thumbnail.jpg'
      end
    end
  end
end
