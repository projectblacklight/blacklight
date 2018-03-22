# frozen_string_literal: true
describe BlacklightHelper do
  before(:each) do
    allow(helper).to receive(:current_or_guest_user).and_return(User.new)
    allow(helper).to receive(:search_action_path) do |*args|
      search_catalog_url *args
    end
  end

  describe "#application_name", :test => true do
    it "defaults to 'Blacklight'" do
      expect(application_name).to eq "Blacklight"
    end
    it "uses the Rails application config application_name if available" do
      allow(Rails.application).to receive(:config).and_return(double(application_name: "asdf"))
      expect(application_name).to eq "asdf"
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
    let(:presenter) { Blacklight::DocumentPresenter.new(document, self) }
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_display'
        config.index.display_type_field = 'format'
      end
    end

    before do
      allow(helper).to receive(:presenter).and_return(presenter)
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    it "generates <link rel=alternate> tags" do
      expect(presenter).to receive(:link_rel_alternates).and_return(result)
      expect(helper.render_link_rel_alternates(document)).to eq result
    end

    it "sends parameters" do
      expect(presenter).to receive(:link_rel_alternates).with(unique: true).and_return(result)
      expect(helper.render_link_rel_alternates(document, unique: true)).to eq result
    end
  end

  describe "with a config" do
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.index.title_field = 'title_display'
        config.index.display_type_field = 'format'
      end
    end
    let(:document) { SolrDocument.new('title_display' => "A Fake Document", 'id'=>'8') }

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
        helper.render_nav_actions { |config, item| buff << "<foo>#{item}</foo>" }
        expect(buff).to have_selector "foo a#bookmarks_nav[href=\"/bookmarks\"]"
        expect(buff).to have_selector "foo a span[data-role='bookmark-counter']", text: '0'
      end
    end

    describe "render_index_doc_actions" do
      it "renders partials" do
        allow(controller).to receive(:render_bookmarks_control?).and_return(true)
        response = helper.render_index_doc_actions(document)
        expect(response).to have_selector(".bookmark_toggle")
      end

      it "is nil if no partials are renderable" do
        allow(controller).to receive(:render_bookmarks_control?).and_return(false)
        expect(helper.render_index_doc_actions(document)).to be_blank
      end

      it "renders view type specific actions" do
        allow(helper).to receive(:document_index_view_type).and_return(:custom)
        config.view.custom.document_actions = []
        expect(helper.render_index_doc_actions(document)).to be_blank
      end
    end

    describe "render_show_doc_actions" do
      it "renders partials" do
        response = helper.render_show_doc_actions(document)
        expect(response).to have_selector(".bookmark_toggle")
      end
    end
  end

  describe "#should_render_index_field?" do
    before do
      allow(helper).to receive_messages(should_render_field?: true, document_has_value?: true)
    end

    it "is true" do
      expect(helper.should_render_index_field?(double, double)).to be true
    end

    it "is false if the document doesn't have a value for the field" do
      allow(helper).to receive_messages(document_has_value?: false)
      expect(helper.should_render_index_field?(double, double)).to be false
    end

    it "is false if the configuration has the field disabled" do
      allow(helper).to receive_messages(should_render_field?: false)
      expect(helper.should_render_index_field?(double, double)).to be false
    end
  end

  describe "#should_render_show_field?" do
    before do
      allow(helper).to receive_messages(should_render_field?: true, document_has_value?: true)
    end

    it "is true" do
      expect(helper.should_render_show_field?(double, double)).to be true
    end

    it "is false if the document doesn't have a value for the field" do
      allow(helper).to receive_messages(document_has_value?: false)
      expect(helper.should_render_show_field?(double, double)).to be false
    end

    it "is false if the configuration has the field disabled" do
      allow(helper).to receive_messages(should_render_field?: false)
      expect(helper.should_render_show_field?(double, double)).to be false
    end
  end

  context "render methods" do
    let(:field) { "some_field" }
    let(:doc) { instance_double(SolrDocument) }
    let(:presenter) { instance_double(Blacklight::ShowPresenter) }
    before do
      allow(Deprecation).to receive(:warn) # TODO: purge Deprecations
      allow(helper).to receive(:presenter).with(doc).and_return(presenter)
    end

    describe "#render_index_field_value" do
      it "passes the document and field through to the presenter" do
        expect(presenter).to receive(:field_value).with(field, {})
        helper.render_index_field_value(doc, field)
      end

      it "allows the document and field to be passed as hash arguments" do
        expect(presenter).to receive(:field_value).with(field, {})
        helper.render_index_field_value(document: doc, field: field)
      end

      it "allows additional options to be passed to the presenter" do
        expect(presenter).to receive(:field_value).with(field, x: 1)
        helper.render_index_field_value(document: doc, field: field, x: 1)
      end
    end

    describe "#render_document_show_field_value" do
      it "passes the document and field through to the presenter" do
        expect(presenter).to receive(:field_value).with(field, {})
        helper.render_document_show_field_value(doc, field)
      end

      it "allows the document and field to be passed as hash arguments" do
        expect(presenter).to receive(:field_value).with(field, {})
        helper.render_document_show_field_value(document: doc, field: field)
      end

      it "allows additional options to be passed to the presenter" do
        expect(presenter).to receive(:field_value).with(field, x: 1)
        helper.render_document_show_field_value(document: doc, field: field, x: 1)
      end
    end
  end

  describe "#document_has_value?" do
    let(:doc) { double(SolrDocument) }
    it "ifs the document has the field value" do
      allow(doc).to receive(:has?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf')
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end
    it "ifs the document has a highlight field value" do
      allow(doc).to receive(:has?).with('asdf').and_return(false)
      allow(doc).to receive(:has_highlight_field?).with('asdf').and_return(true)
      field_config = double(:field => 'asdf', :highlight => true)
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end
    it "ifs the field has a model accessor" do
      allow(doc).to receive(:has?).with('asdf').and_return(false)
      allow(doc).to receive(:has_highlight_field?).with('asdf').and_return(false)
      field_config = double(:field => 'asdf', :highlight => true, :accessor => true)
      expect(helper.document_has_value?(doc, field_config)).to eq true
    end
  end

  describe "render_grouped_response?" do
    it "checks if the response ivar contains grouped data" do
      assign(:response, instance_double(Blacklight::Solr::Response, grouped?: true))
      expect(helper.render_grouped_response?).to be true
    end

    it "checks if the response param contains grouped data" do
      response = instance_double(Blacklight::Solr::Response, grouped?: true)
      expect(helper.render_grouped_response?(response)).to be true
    end
  end

  describe "render_grouped_document_index" do
    pending 'not implemented'
  end

  describe "should_show_spellcheck_suggestions?" do
    before do
      allow(helper).to receive_messages spell_check_max: 5
    end
    it "does not show suggestions if there are enough results" do
      response = double(total: 10)
      expect(helper.should_show_spellcheck_suggestions? response).to be false
    end
    it "only shows suggestions if there are very few results" do
      response = double(total: 4, spelling: double(words: [1]))
      expect(helper.should_show_spellcheck_suggestions? response).to be true
    end
    it "shows suggestions only if there are spelling suggestions available" do
      response = double(total: 4, spelling: double(words: []))
      expect(helper.should_show_spellcheck_suggestions? response).to be false
    end
    it "does not show suggestions if spelling is not available" do
      response = double(total: 4, spelling: nil)
      expect(helper.should_show_spellcheck_suggestions? response).to be false
    end
  end

  describe "#render_document_partials" do
    let(:doc) { double }
    before do
      allow(helper).to receive_messages(document_partial_path_templates: [])
      allow(helper).to receive_messages(document_index_view_type: 'index_header')
    end

    it "gets the document format from document_partial_name" do
      allow(helper).to receive(:document_partial_name).with(doc, :xyz)
      helper.render_document_partial(doc, :xyz)
    end
  end

  describe "#document_partial_name" do
    let(:blacklight_config) { Blacklight::Configuration.new }
    before do
      allow(helper).to receive_messages(blacklight_config: blacklight_config)
    end

    context "with a solr document with empty fields" do
      let(:document) { SolrDocument.new }
      it "is the default value" do
        expect(helper.document_partial_name(document)).to eq 'default'
      end
    end

    context "with a solr document with the display type field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz'}
      before do
        blacklight_config.show.display_type_field = 'my_field'
      end

      it "uses the value in the configured display type field" do
        expect(helper.document_partial_name(document)).to eq 'xyz'
      end
      it "uses the value in the configured display type field if the action-specific field is empty" do
        expect(helper.document_partial_name(document, :some_action)).to eq 'xyz'
      end
    end

    context "with a solr doucment with an action-specific field set" do
      let(:document) { SolrDocument.new 'my_field' => 'xyz', 'other_field' => 'abc' }
      before do
        blacklight_config.show.media_display_type_field = 'my_field'
        blacklight_config.show.metadata_display_type_field = 'other_field'
      end
      it "uses the value in the action-specific fields" do
        expect(helper.document_partial_name(document, :media)).to eq 'xyz'
        expect(helper.document_partial_name(document, :metadata)).to eq 'abc'
      end
    end
  end

  describe "#type_field_to_partial_name" do
    let(:document) { double }
    context "with default value" do
      subject { helper.type_field_to_partial_name(document, 'default') }
      it { should eq 'default' }
    end
    context "with spaces" do
      subject { helper.type_field_to_partial_name(document, 'one two three') }
      it { should eq 'one_two_three' }
    end
    context "with hyphens" do
      subject { helper.type_field_to_partial_name(document, 'one-two-three') }
      it { should eq 'one_two_three' }
    end
    context "an array" do
      subject { helper.type_field_to_partial_name(document, ['one', 'two', 'three']) }
      it { should eq 'one_two_three' }
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
      allow(helper).to receive(:render_document_index_with_view).with(:current_view, [], a: 1, b: 2)
      helper.render_document_index [], a: 1, b: 2
    end
  end

  describe "#render_document_index_with_view" do
    let(:obj1) { SolrDocument.new }
    before do
      allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      assign(:response, instance_double(Blacklight::Solr::Response, grouped?: false, start: 0))
      allow(helper).to receive(:link_to_document).and_return('<a/>')
      allow(helper).to receive(:render_index_doc_actions).and_return('<div/>')
    end

    it "ignores missing templates" do
      response = helper.render_document_index_with_view :view_type, [obj1, obj1]
      expect(response).to have_selector "div#documents"
    end
  end

  describe "#document_index_view_type" do
    it "defaults to the default view" do
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      allow(helper).to receive(:default_document_index_view_type).and_return(:xyz)
      expect(helper.document_index_view_type).to eq :xyz
    end

    it "uses the query parameter" do
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      expect(helper.document_index_view_type(view: :a)).to eq :a
    end

    it "uses the default view if the requested view is not available" do
      allow(helper).to receive(:default_document_index_view_type).and_return(:xyz)
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      expect(helper.document_index_view_type(view: :c)).to eq :xyz
    end

    context "when they have a preferred view" do
      before do
        session[:preferred_view] = :b
      end

      context "and no view is specified" do
        it "uses the saved preference" do
          allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2, c: 3)
          expect(helper.document_index_view_type).to eq :b
        end

        it "uses the default view if the preference is not available" do
          allow(helper).to receive(:document_index_views).and_return(a: 1)
          expect(helper.document_index_view_type).to eq :a
        end
      end

      context "and a view is specified" do
        it "uses the query parameter" do
          allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2, c: 3)
          expect(helper.document_index_view_type(view: :c)).to eq :c
        end
      end
    end
  end

  context "related classes" do
    let(:presenter_class) { double }
    let(:blacklight_config) { Blacklight::Configuration.new }
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    describe "#presenter_class" do
      it "uses the value defined in the blacklight configuration" do
        expect(Deprecation).to receive(:warn).exactly(2).times
        blacklight_config.document_presenter_class = presenter_class
        expect(helper.presenter_class).to eq presenter_class
      end

      it "defaults to Blacklight::DocumentPresenter" do
        expect(Deprecation).to receive(:warn)
        expect(helper.presenter_class).to eq Blacklight::DocumentPresenter
      end
    end

    describe "#index_presenter_class" do
      it "uses the value defined in the blacklight configuration" do
        blacklight_config.index.document_presenter_class = presenter_class
        expect(helper.index_presenter_class(nil)).to eq presenter_class
      end

      it "defaults to Blacklight::IndexPresenter" do
        expect(helper.index_presenter_class(nil)).to eq Blacklight::IndexPresenter
      end
    end

    describe "#show_presenter_class" do
      it "uses the value defined in the blacklight configuration" do
        blacklight_config.show.document_presenter_class = presenter_class
        expect(helper.show_presenter_class(nil)).to eq presenter_class
      end

      it "defaults to Blacklight::DocumentPresenter" do
        expect(helper.show_presenter_class(nil)).to eq Blacklight::ShowPresenter
      end
    end
  end

  describe "#render_document_heading" do
    let(:document) { double }
    before do
      allow(helper).to receive(:presenter).and_return(double(heading: "Heading"))
    end

    it "accepts no arguments and render the document heading" do
      expect(helper.render_document_heading).to have_selector "h4", text: "Heading"
    end

    it "accepts the tag name as an option" do
      expect(helper.render_document_heading tag: "h1").to have_selector "h1", text: "Heading"
    end

    it "accepts an explicit document argument" do
      allow(helper).to receive(:presenter).with(document).and_return(double(heading: "Document Heading"))
      expect(helper.render_document_heading(document)).to have_selector "h4", text: "Document Heading"
    end

    it "accepts the document with a tag option" do
      allow(helper).to receive(:presenter).with(document).and_return(double(heading: "Document Heading"))
      expect(helper.render_document_heading(document, tag: "h3")).to have_selector "h3", text: "Document Heading"
    end
  end
end
