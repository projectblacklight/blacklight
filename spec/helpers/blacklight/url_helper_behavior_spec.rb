# frozen_string_literal: true

RSpec.describe Blacklight::UrlHelperBehavior do
  around { |test| Deprecation.silence(described_class) { test.call } }

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_tsim'
      config.index.display_type_field = 'format'
    end
  end

  let(:parameter_class) { ActionController::Parameters }

  before do
    allow(controller).to receive(:controller_name).and_return('test')
    allow(helper).to receive(:search_action_path) do |*args|
      search_catalog_url *args
    end

    allow(helper).to receive_messages(blacklight_config: blacklight_config)
    allow(helper).to receive_messages(current_search_session: nil)
    allow(helper).to receive(:search_session).and_return({})
  end

  describe "url_for_document" do
    let(:controller_class) { ::CatalogController.new }
    let(:doc) { SolrDocument.new }

    before do
      allow(helper).to receive_messages(controller: controller_class)
      allow(helper).to receive_messages(controller_name: controller_class.controller_name)
      allow(helper).to receive_messages(params: parameter_class.new)
    end

    it "is a polymorphic routing-ready object" do
      expect(helper.url_for_document(doc)).to eq doc
    end

    it "allows for custom show routes" do
      helper.blacklight_config.show.route = { controller: 'catalog' }
      expect(helper.url_for_document(doc)).to eq(controller: 'catalog', action: :show, id: doc)
    end

    context "within bookmarks" do
      let(:controller_class) { ::BookmarksController.new }

      it "uses polymorphic routing" do
        expect(helper.url_for_document(doc)).to eq doc
      end
    end

    context "within an alternative catalog controller" do
      let(:controller_class) { ::AlternateController.new }

      before do
        helper.blacklight_config.show.route = { controller: :current }
        allow(helper).to receive(:params).and_return(parameter_class.new(controller: 'alternate'))
      end

      it "supports the :current controller configuration" do
        expect(helper.url_for_document(doc)).to eq(controller: 'alternate', action: :show, id: doc)
      end
    end

    it "is a polymorphic route if the solr document responds to #to_model with a non-SolrDocument" do
      some_model = double
      doc = SolrDocument.new
      allow(doc).to receive_messages(to_model: some_model)
      expect(helper.url_for_document(doc)).to eq doc
    end
  end

  describe "link_back_to_catalog" do
    let(:query_params) { { q: "query", f: "facets", controller: 'catalog' } }
    let(:bookmarks_query_params) { { controller: 'bookmarks' } }

    it "builds a link tag to catalog using session[:search] for query params" do
      allow(helper).to receive(:current_search_session).and_return double(query_params: query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /q=query/
      expect(tag).to match /f=facets/
      expect(tag).not_to match /page=/
      expect(tag).not_to match /per_page=/
    end

    it "builds a link tag to bookmarks using session[:search] for query params" do
      allow(helper).to receive(:current_search_session).and_return double(query_params: bookmarks_query_params)
      tag = helper.link_back_to_catalog
      expect(tag).to match /Back to Bookmarks/
      expect(tag).to match %r{/bookmarks}
    end

    context "with a search context" do
      it "uses the current search session counter and per page information to construct the appropriate pagination context" do
        allow(helper).to receive_messages(current_search_session: double(query_params: query_params))
        allow(helper).to receive_messages(search_session: { 'per_page' => 15, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=3/
        expect(tag).to match /per_page=15/
      end

      it "omits per_page if the value is the same as the default" do
        allow(helper).to receive_messages(current_search_session: double(query_params: query_params))
        allow(helper).to receive_messages(search_session: { 'per_page' => 10, 'counter' => 31 })
        tag = helper.link_back_to_catalog
        expect(tag).to match /page=4/
        expect(tag).not_to match /per_page=/
      end
    end

    context "without current search context" do
      subject { helper.link_back_to_catalog }

      before do
        controller.request.assign_parameters(Rails.application.routes, 'catalog', 'show', { id: '123' }, '/catalog/123', [:controller, :action, :id])
        allow(helper).to receive_messages(current_search_session: nil)
      end

      it "links to the catalog" do
        expect(subject).to eq '<a href="/catalog">Back to Search</a>'
      end
    end

    context "when an alternate scope is passed in" do
      subject(:tag) { helper.link_back_to_catalog(route_set: my_engine) }

      let(:my_engine) { double("Engine") }

      before do
        allow(helper).to receive(:current_search_session).and_return double(query_params: query_params)
      end

      it "calls url_for on the engine scope" do
        expect(my_engine).to receive(:url_for)
          .with(q: "query", f: "facets", controller: "catalog")
          .and_return('link-url')
        expect(tag).to match /Back to Search/
        expect(tag).to match /link-url/
      end
    end
  end

  describe "link_to_previous_document" do
    context "when the argument is nil" do
      subject { helper.link_to_previous_document(nil) }

      it { is_expected.to eq '<span class="previous">&laquo; Previous</span>' }
    end
  end

  describe "link_to_query" do
    it "builds a link tag to catalog using query string (no other params)" do
      query = "brilliant"
      allow(helper).to receive_messages(params: parameter_class.new)
      tag = helper.link_to_query(query)
      expect(tag).to match /q=#{query}/
      expect(tag).to match %r{>#{query}</a>}
    end

    it "builds a link tag to catalog using query string and other existing params" do
      query = "wonderful"
      allow(helper).to receive_messages(params: parameter_class.new(qt: "title_search", per_page: "50"))
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=title_search/
      expect(tag).to match /per_page=50/
    end

    it "ignores existing :page param" do
      query = "yes"
      allow(helper).to receive_messages(params: parameter_class.new(page: "2", qt: "author_search"))
      tag = helper.link_to_query(query)
      expect(tag).to match /qt=author_search/
      expect(tag).not_to match /page/
    end

    it "is html_safe" do
      query = "brilliant"
      allow(helper).to receive_messages(params: parameter_class.new(page: "2", qt: "author_search"))
      tag = helper.link_to_query(query)
      expect(tag).to be_html_safe
    end
  end

  describe "start_over_path" do
    it 'is the catalog path with the current view type' do
      allow(blacklight_config).to receive(:view).and_return(list: nil, abc: nil)
      allow(helper).to receive_messages(blacklight_config: blacklight_config)
      expect(helper.start_over_path(view: 'abc')).to eq search_catalog_url(view: 'abc')
    end

    it 'does not include the current view type if it is the default' do
      allow(blacklight_config).to receive(:view).and_return(list: nil, asdf: nil)
      allow(helper).to receive_messages(blacklight_config: blacklight_config)
      expect(helper.start_over_path(view: 'list')).to eq search_catalog_url
    end
  end

  describe "link_to_document" do
    let(:title_tsim) { '654321' }
    let(:id) { '123456' }
    let(:data) { { 'id' => id, 'title_tsim' => [title_tsim] } }
    let(:document) { SolrDocument.new(data) }

    before do
      allow(controller).to receive(:action_name).and_return('index')
      allow(helper.main_app).to receive(:track_test_path).and_return('tracking url')
      allow(helper.main_app).to receive(:respond_to?).with('track_test_path').and_return(true)
    end

    it "consists of the document title wrapped in a <a>" do
      allow(Deprecation).to receive(:warn)
      expect(helper.link_to_document(document, :title_tsim)).to have_selector("a", text: '654321', count: 1)
    end

    it "accepts and returns a string label" do
      expect(helper.link_to_document(document, 'This is the title')).to have_selector("a", text: 'This is the title', count: 1)
    end

    it "accepts and returns a Proc" do
      allow(Deprecation).to receive(:warn)
      expect(helper.link_to_document(document, proc { |doc, _opts| doc[:id] + ": " + doc.first(:title_tsim) })).to have_selector("a", text: '123456: 654321', count: 1)
    end

    context 'when label is missing' do
      let(:data) { { 'id' => id } }

      it "returns id" do
        allow(Deprecation).to receive(:warn)
        expect(helper.link_to_document(document, :title_tsim)).to have_selector("a", text: '123456', count: 1)
      end

      it "is html safe" do
        allow(Deprecation).to receive(:warn)
        expect(helper.link_to_document(document, :title_tsim)).to be_html_safe
      end

      it "passes on the title attribute to the link_to_with_data method" do
        expect(helper.link_to_document(document, "Some crazy long label...", title: "Some crazy longer label")).to match(/title="Some crazy longer label"/)
      end

      it "doesn't add an erroneous title attribute if one isn't provided" do
        expect(helper.link_to_document(document, "Some crazy long label...")).not_to match(/title=/)
      end

      context "with an integer id" do
        let(:id) { 123_456 }

        it "works" do
          expect(helper.link_to_document(document)).to have_selector("a")
        end
      end
    end

    it "converts the counter parameter into a data- attribute" do
      allow(Deprecation).to receive(:warn)
      expect(helper.link_to_document(document, :title_tsim, counter: 5)).to include 'data-context-href="tracking url"'
      expect(helper.main_app).to have_received(:track_test_path).with(hash_including(id: have_attributes(id: '123456'), counter: 5))
    end

    it "includes the data- attributes from the options" do
      link = helper.link_to_document document, data: { x: 1 }
      expect(link).to have_selector '[data-x]'
    end

    it 'adds a controller-specific tracking attribute' do
      expect(helper.main_app).to receive(:track_test_path).and_return('/asdf')
      link = helper.link_to_document document, data: { x: 1 }

      expect(link).to have_selector '[data-context-href="/asdf"]'
    end
  end

  describe "link_to_previous_search" do
    let(:params) { {} }

    it "links to the given search parameters" do
      allow(helper).to receive(:render_search_to_s).with(params).and_return "link text"
      expect(helper.link_to_previous_search({})).to eq helper.link_to("link text", helper.search_action_path)
    end
  end

  describe "#bookmarks_export_url" do
    it "is the bookmark url with an encrypted user token" do
      allow(helper).to receive_messages(encrypt_user_id: 'xyz', current_or_guest_user: double(id: 123))
      url = helper.bookmarks_export_url(:html)
      expect(url).to eq helper.bookmarks_url(format: :html, encrypted_user_id: 'xyz')
    end
  end

  describe "#session_tracking_path" do
    let(:document) { SolrDocument.new(id: 1) }

    it "determines the correct route for the document class" do
      allow(helper.main_app).to receive(:track_test_path).with(id: have_attributes(id: 1)).and_return('x')
      expect(helper.session_tracking_path(document)).to eq 'x'
    end

    it "passes through tracking parameters" do
      allow(helper.main_app).to receive(:track_test_path).with(id: have_attributes(id: 1), x: 1).and_return('x')
      expect(helper.session_tracking_path(document, x: 1)).to eq 'x'
    end

    it "uses the track_search_session configuration to determine whether to track the search session" do
      blacklight_config.track_search_session = false
      expect(helper.session_tracking_path(document, x: 1)).to eq nil
    end
  end
end
