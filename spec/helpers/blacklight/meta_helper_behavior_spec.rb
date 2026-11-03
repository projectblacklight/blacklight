# frozen_string_literal: true

RSpec.describe Blacklight::MetaHelperBehavior do
  include Capybara::RSpecMatchers

  before do
    allow(helper).to receive_messages(application_name: 'Blacklight', render_page_title: 'Some Page - Blacklight')
  end

  describe '#add_open_graph_properties' do
    it 'normalizes to string keys' do
      helper.add_open_graph_properties(prop: 'value')

      expect(helper.open_graph_properties).to eq('prop' => 'value')
    end

    it 'overwrites properties that were already set' do
      helper.add_open_graph_properties('og:title' => 'A title')
      helper.add_open_graph_properties('og:title' => 'Another title')

      expect(helper.open_graph_properties).to eq('og:title' => 'Another title')
    end

    it 'removes properties that are set to nil' do
      helper.add_open_graph_properties('og:title' => 'A title')
      helper.add_open_graph_properties('og:title' => nil)

      expect(helper.open_graph_properties).to eq('og:title' => nil)
    end
  end

  describe '#add_default_open_graph_properties' do
    it 'only adds properties that are not set yet' do
      helper.add_open_graph_properties('og:title' => 'A title')
      helper.add_default_open_graph_properties('og:title' => 'Fallback title', 'og:image' => 'http://example.com/image.jpg')

      expect(helper.open_graph_properties).to eq('og:title' => 'A title', 'og:image' => 'http://example.com/image.jpg')
    end

    it 'ignores nil values' do
      helper.add_default_open_graph_properties('og:site_name' => nil)

      expect(helper.open_graph_properties).to eq({})
    end
  end

  describe '#default_open_graph_properties' do
    it 'derives properties from the application and the current page' do
      expect(helper.default_open_graph_properties).to eq(
        'og:type' => 'website',
        'og:site_name' => 'Blacklight',
        'og:title' => 'Some Page - Blacklight',
        'og:url' => 'http://test.host'
      )
    end
  end

  describe '#render_open_graph_tags' do
    subject(:rendered) { Capybara.string(helper.render_open_graph_tags) }

    it 'renders the default properties as <meta> tags' do
      expect(rendered).to have_css 'meta[property="og:type"][content="website"]', visible: :all
      expect(rendered).to have_css 'meta[property="og:site_name"][content="Blacklight"]', visible: :all
      expect(rendered).to have_css 'meta[property="og:title"][content="Some Page - Blacklight"]', visible: :all
      expect(rendered).to have_css 'meta[property="og:url"][content="http://test.host"]', visible: :all
    end

    it 'prefers properties added by the page over fallbacks and defaults' do
      helper.add_open_graph_properties('og:title' => 'Page title')
      helper.add_default_open_graph_properties('og:title' => 'Fallback title', 'og:site_name' => 'Fallback site')

      expect(rendered).to have_css 'meta[property="og:title"][content="Page title"]', visible: :all
      expect(rendered).to have_css 'meta[property="og:site_name"][content="Fallback site"]', visible: :all
    end

    it 'leaves out a default the page set to nil' do
      helper.add_open_graph_properties('og:url' => nil)

      expect(rendered).to have_no_css 'meta[property="og:url"]', visible: :all
    end

    it 'escapes content' do
      helper.add_open_graph_properties('og:title' => '"Quoted" & <tagged>')

      expect(helper.render_open_graph_tags).to include 'content="&quot;Quoted&quot; &amp; &lt;tagged&gt;"'
    end
  end
end
