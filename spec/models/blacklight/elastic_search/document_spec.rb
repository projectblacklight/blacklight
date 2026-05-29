# frozen_string_literal: true

RSpec.describe Blacklight::ElasticSearch::Document, :api do
  let(:document_class) do
    Class.new do
      include Blacklight::ElasticSearch::Document

      def self.name
        'ElasticDocument'
      end
    end
  end

  let(:document) { document_class.new(source) }

  let(:source) do
    { 'id' => 'abc', 'title_tsim' => ['A Title'], '_highlighting' => { 'title_tsim' => ['A <em>Title</em>'] } }
  end

  describe '#has_highlight_field?' do
    it 'is true when highlight data is present for the field' do
      expect(document.has_highlight_field?('title_tsim')).to be true
    end

    it 'is false when there is no highlight data for the field' do
      expect(document.has_highlight_field?('author_tsim')).to be false
    end

    context 'without any highlight data' do
      let(:source) { { 'id' => 'abc' } }

      it 'is false' do
        expect(document.has_highlight_field?('title_tsim')).to be false
      end
    end
  end

  describe '#highlight_field' do
    it 'returns html-safe highlight snippets' do
      snippets = document.highlight_field('title_tsim')
      expect(snippets).to eq ['A <em>Title</em>']
      expect(snippets).to all(be_html_safe)
    end
  end

  describe '#more_like_this' do
    it 'is empty (not supported by the Elasticsearch adapter)' do
      expect(document.more_like_this).to eq []
    end
  end
end
