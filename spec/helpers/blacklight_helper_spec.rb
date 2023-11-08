# frozen_string_literal: true

RSpec.describe BlacklightHelper do
  before do
    allow(helper).to receive(:current_or_guest_user).and_return(User.new)
    allow(helper).to receive(:search_action_path) do |*args|
      search_catalog_url *args
    end
  end

  describe "#application_name" do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::NullStore.new)
    end

    it "defaults to 'Blacklight'" do
      expect(application_name).to eq "Blacklight"
    end

    context "when the language is not english" do
      around do |example|
        I18n.locale = :de
        example.run
        I18n.locale = :en
      end

      context "and no translation exists for that language" do
        it "defaults to 'Blacklight'" do
          expect(application_name).to eq "Blacklight"
        end
      end

      context "and a translation exists for that language" do
        around do |example|
          I18n.backend.store_translations(:de, 'blacklight' => { 'application_name' => 'Schwarzlicht' })
          example.run
          I18n.backend.reload!
        end

        it "uses the provided value" do
          expect(application_name).to eq "Schwarzlicht"
        end
      end
    end
  end

  describe "#render_page_title" do
    it "looks in content_for(:page_title)" do
      helper.content_for(:page_title) { "xyz" }
      expect(helper.render_page_title).to eq "xyz"
    end

    it "looks in the @page_title ivar" do
      assign(:page_title, "xyz")
      expect(helper.render_page_title).to eq "xyz"
    end

    it "defaults to the application name" do
      expect(helper.render_page_title).to eq helper.application_name
    end
  end

  describe "render_link_rel_alternates" do
    let(:document) { instance_double(SolrDocument) }
    let(:result) { double }
    let(:view_context) { double(blacklight_config: blacklight_config, document_index_view_type: 'index') }
    let(:presenter) { Blacklight::IndexPresenter.new(document, view_context) }
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_tsim'
        config.index.display_type_field = 'format'
      end
    end

    before do
      allow(helper).to receive(:document_presenter).and_return(presenter)
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    it "generates <link rel=alternate> tags" do
      expect(presenter).to receive(:link_rel_alternates).and_return(result)
      expect(helper.render_link_rel_alternates(document)).to eq result
    end

    it "sends parameters" do
      expect(presenter).to receive(:link_rel_alternates).with({ unique: true }).and_return(result)
      expect(helper.render_link_rel_alternates(document, unique: true)).to eq result
    end
  end

  describe "with a config" do
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_tsim'
        config.index.display_type_field = 'format'
      end
    end
    let(:document) { SolrDocument.new('title_tsim' => "A Fake Document", 'id' => '8') }

    before do
      config.add_show_tools_partial(:bookmark, partial: 'catalog/bookmark_control')
      config.add_results_document_tool(:bookmark, partial: 'catalog/bookmark_control', if: :render_bookmarks_control?)
      config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark')
      allow(helper).to receive(:blacklight_config).and_return(config)
      allow(helper).to receive_messages(current_bookmarks: [])
    end

    describe "render_nav_actions" do
      it "renders partials" do
        buff = String.new
        helper.render_nav_actions { |_config, item| buff << "<foo>#{item}</foo>" }
        expect(buff).to have_selector "foo a#bookmarks_nav[href=\"/bookmarks\"]"
        expect(buff).to have_selector "foo a span[data-role='bookmark-counter']", text: '0'
      end
    end

    describe "render_index_doc_actions" do
      it "renders partials" do
        allow(controller).to receive(:render_bookmarks_control?).and_return(true)
        response = helper.render_index_doc_actions(document)
        expect(response).to have_selector(".bookmark-toggle")
      end

      it "is nil if no partials are renderable" do
        allow(controller).to receive(:render_bookmarks_control?).and_return(false)
        expect(helper.render_index_doc_actions(document)).to be_blank
      end

      it "renders view type specific actions" do
        allow(helper).to receive(:document_index_view_type).and_return(:custom)
        config.view.custom(document_actions: [])
        expect(helper.render_index_doc_actions(document)).to be_blank
      end
    end
  end

  describe "#opensearch_description_tag" do
    subject { helper.opensearch_description_tag 'title', 'href' }

    it "has a search rel" do
      expect(subject).to have_selector "link[rel='search']", visible: false
    end

    it "has the correct mime type" do
      expect(subject).to have_selector "link[type='application/opensearchdescription+xml']", visible: false
    end

    it "has a title attribute" do
      expect(subject).to have_selector "link[title='title']", visible: false
    end

    it "has an href attribute" do
      expect(subject).to have_selector "link[href='href']", visible: false
    end
  end

  describe "#render_document_index" do
    it "renders the document index with the current view type" do
      allow(helper).to receive_messages(document_index_view_type: :current_view)
      allow(helper).to receive(:render_document_index_with_view).with(:current_view, [], { a: 1, b: 2 })
      helper.render_document_index [], a: 1, b: 2
    end
  end

  describe "#render_document_index_with_view" do
    let(:obj1) { SolrDocument.new }
    let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }

    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
      assign(:response, instance_double(Blacklight::Solr::Response, grouped?: false, start: 0))
      allow(helper).to receive(:link_to_document).and_return('<a/>')
      allow(helper).to receive(:render_index_doc_actions).and_return('<div/>')
    end

    it "ignores missing templates" do
      blacklight_config.view.view_type(partials: %w[index_header a b])

      response = helper.render_document_index_with_view :view_type, [obj1, obj1]
      expect(response).to have_selector "div#documents"
    end

    context 'with a template partial provided by the view config' do
      before do
        blacklight_config.view.gallery(template: '/my/partial')
      end

      it 'renders that template' do
        # Not sure why we need to re-implement rspec's stub_template, but
        # we already were, and need a Rails 7.1+ safe alternate too
        # https://github.com/rspec/rspec-rails/commit/4d65bea0619955acb15023b9c3f57a3a53183da8
        # https://github.com/rspec/rspec-rails/issues/2696
        replace_hash = { 'my/_partial.html.erb' => 'some content' }
        if ::Rails.version.to_f >= 7.1
          controller.prepend_view_path(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
        else
          view.view_paths.unshift(ActionView::FixtureResolver.new(replace_hash))
        end

        response = helper.render_document_index_with_view :gallery, [obj1, obj1]

        expect(response).to eq 'some content'
      end
    end
  end
end
