# frozen_string_literal: true

RSpec.describe CatalogHelper do
  include ERB::Util
  include CatalogHelper

  def mock_response args
    current_page = args[:current_page] || 1
    per_page = args[:rows] || args[:per_page] || 10
    total = args[:total]
    start = (current_page - 1) * per_page

    mock_docs = (1..total).to_a.map { ActiveSupport::HashWithIndifferentAccess.new }

    mock_response = Kaminari.paginate_array(mock_docs).page(current_page).per(per_page)

    allow(mock_response).to receive(:docs).and_return(mock_docs.slice(start, per_page))
    mock_response
  end

  def render_grouped_response?
    false
  end


  describe "page_entries_info" do
    it "with no results" do
      @response = mock_response :total => 0

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      expect(html).to eq "No entry_names found"
      expect(html).to be_html_safe
    end

    it "with no results (and no entry_name provided)" do
      @response = mock_response :total => 0

      html = page_entries_info(@response)
      expect(html).to eq "No entries found"
      expect(html).to be_html_safe
    end

    it "with an empty page of results" do
      @response = double(limit_value: -1)

      html = page_entries_info(@response)
      expect(html).to be_blank
    end

    describe "with a single result" do
      it "uses the provided entry name" do
        response = mock_response :total => 1

        html = page_entries_info(response, { :entry_name => 'entry_name' })
        expect(html).to eq "<strong>1</strong> entry_name found"
        expect(html).to be_html_safe
      end

      it "infers a name" do
        response = mock_response :total => 1

        html = page_entries_info(response)
        expect(html).to eq "<strong>1</strong> entry found"
        expect(html).to be_html_safe
      end

      it "uses the model_name from the response" do
        response = mock_response :total => 1
        allow(response).to receive(:model_name).and_return(double(:human => 'thingy'))

        html = page_entries_info(response)
        expect(html).to eq "<strong>1</strong> thingy found"
        expect(html).to be_html_safe
      end
    end

    it "with a single page of results" do
      response = mock_response :total => 7

      html = page_entries_info(response, { :entry_name => 'entry_name' })
      expect(html).to eq "<strong>1</strong> - <strong>7</strong> of <strong>7</strong>"
      expect(html).to be_html_safe
    end

    it "on the first page of multiple pages of results" do
      @response = mock_response :total => 15, :per_page => 10

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      expect(html).to eq "<strong>1</strong> - <strong>10</strong> of <strong>15</strong>"
      expect(html).to be_html_safe
    end

    it "on the second page of multiple pages of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 2

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      expect(html).to eq "<strong>11</strong> - <strong>20</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end

    it "on the last page of results" do
      @response = mock_response :total => 47, :per_page => 10, :current_page => 5

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      expect(html).to eq "<strong>41</strong> - <strong>47</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end
    it "works with rows the same as per_page" do
      @response = mock_response :total => 47, :rows => 20, :current_page => 2

      html = page_entries_info(@response, { :entry_name => 'entry_name' })
      expect(html).to eq "<strong>21</strong> - <strong>40</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end

    it "uses delimiters with large numbers" do
      @response = mock_response :total => 5000, :rows => 10, :current_page => 101
      html = page_entries_info(@response, { :entry_name => 'entry_name' })

      expect(html).to eq "<strong>1,001</strong> - <strong>1,010</strong> of <strong>5,000</strong>"
    end

    context "with an ActiveRecord collection" do
      let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345' }
      before { 50.times { Bookmark.create!(user: user) } }
      subject { helper.page_entries_info(Bookmark.page(1).per(25)) }

      it { is_expected.to eq "<strong>1</strong> - <strong>25</strong> of <strong>50</strong>" }
    end
  end

  describe "rss_feed_link_tag" do
    context "when an alternate scope is passed in" do
      subject(:tag) { helper.rss_feed_link_tag(route_set: my_engine) }

      let(:my_engine) { double("Engine") }
      let(:query_params) { { controller: 'catalog', action: 'index' } }
      let(:config) { Blacklight::Configuration.new }
      let(:search_state) { Blacklight::SearchState.new(query_params, config, controller) }

      before do
        allow(helper).to receive(:search_state).and_return search_state
      end

      it "calls url_for on the engine scope" do
        expect(my_engine).to receive(:url_for).and_return('/rss-path')
        expect(tag).to match /title="RSS for results"/
        expect(tag).to match /rel="alternate"/
        expect(tag).to match %r{type="application/rss\+xml"}
      end
    end
  end

  describe "atom_feed_link_tag" do
    context "when an alternate scope is passed in" do
      subject(:tag) { helper.atom_feed_link_tag(route_set: my_engine) }

      let(:my_engine) { double("Engine") }
      let(:query_params) { { controller: 'catalog', action: 'index' } }
      let(:config) { Blacklight::Configuration.new }
      let(:search_state) { Blacklight::SearchState.new(query_params, config, controller) }

      before do
        allow(helper).to receive(:search_state).and_return search_state
      end

      it "calls url_for on the engine scope" do
        expect(my_engine).to receive(:url_for).and_return('/atom-path')
        expect(tag).to match /title="Atom for results"/
        expect(tag).to match /rel="alternate"/
        expect(tag).to match %r{type="application/atom\+xml"}
      end
    end
  end

  describe "should_autofocus_on_search_box?" do
    before do
      expect(Deprecation).to receive(:warn)
    end
    it "is focused if we're on a catalog-like index page without query or facet parameters" do
      allow(helper).to receive_messages(controller: CatalogController.new, action_name: "index", has_search_parameters?: false)
      expect(helper.should_autofocus_on_search_box?).to be true
    end

    it "does not be focused if we're not on a catalog controller" do
      allow(helper).to receive_messages(controller: ApplicationController.new)
      expect(helper.should_autofocus_on_search_box?).to be false
    end

    it "does not be focused if we're not on a catalog controller index" do
      allow(helper).to receive_messages(controller: CatalogController.new, action_name: "show")
      expect(helper.should_autofocus_on_search_box?).to be false
    end

    it "does not be focused if a search parameters are provided" do
      allow(helper).to receive_messages(controller: CatalogController.new, action_name: "index", has_search_parameters?: true)
      expect(helper.should_autofocus_on_search_box?).to be false
    end
  end

  describe "has_thumbnail?" do
    before do
      expect(Deprecation).to receive(:warn)
    end

    let(:document) { SolrDocument.new(data) }
    let(:data) { {} }

    it "has a thumbnail if a thumbnail_method is configured" do
      allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(:thumbnail_method => :xyz, document_presenter_class: Blacklight::IndexPresenter) ))
      expect(helper.has_thumbnail? document).to be true
    end

    context "if a thumbnail_field is configured and it exists in the document" do
      let(:data) { { xyz: 'abc' } }
      it "has a thumbnail" do
        allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(:thumbnail_field => :xyz, document_presenter_class: Blacklight::IndexPresenter) ))
        expect(helper.has_thumbnail? document).to be true
      end
    end

    it "does not have a thumbnail if the thumbnail_field is missing from the document" do
      allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(:thumbnail_field => :xyz, document_presenter_class: Blacklight::IndexPresenter) ))
      allow(document).to receive_messages(has?: false)
      expect(helper.has_thumbnail? document).to be false
    end

    it "does not have a thumbnail if none of the fields are configured" do
      allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(document_presenter_class: Blacklight::IndexPresenter) ))
      expect(helper.has_thumbnail? document).to be_falsey
    end
  end

  describe "render_thumbnail_tag" do
    let(:index_presenter) do
      instance_double(Blacklight::IndexPresenter, thumbnail: thumbnail_presenter)
    end
    let(:thumbnail_presenter){ instance_double(Blacklight::ThumbnailPresenter) }

    before do
      expect(Deprecation).to receive(:warn)
      allow(helper).to receive(:index_presenter).with(document).and_return(index_presenter)
    end

    let(:document) { instance_double(SolrDocument) }

    it "calls thumbnail presenter with default values" do
      expect(thumbnail_presenter).to receive(:thumbnail_tag).with({}, {})
      helper.render_thumbnail_tag document
    end

    it "calls thumbnail presenter with provided values" do
      expect(thumbnail_presenter).to receive(:thumbnail_tag).with({}, suppress_link: true)
      result = helper.render_thumbnail_tag document, {}, suppress_link: true
    end
  end

  describe "thumbnail_url" do
    before do
      expect(Deprecation).to receive(:warn)
    end

    it "pulls the configured thumbnail field out of the document" do
      allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(:thumbnail_field => :xyz) ))
      document = instance_double(SolrDocument)
      allow(document).to receive(:has?).with(:xyz).and_return(true)
      allow(document).to receive(:first).with(:xyz).and_return("asdf")
      expect(helper.thumbnail_url document).to eq("asdf")
    end

    it "returns nil if the thumbnail field doesn't exist" do
      allow(helper).to receive_messages(:blacklight_config => Blacklight::Configuration.new(:index => Blacklight::OpenStructWithHashAccess.new(:thumbnail_field => :xyz) ))
      document = instance_double(SolrDocument)
      allow(document).to receive(:has?).with(:xyz).and_return(false)
      expect(helper.thumbnail_url document).to be_nil
    end
  end

  describe "document_counter_with_offset" do
    it "renders the document index with the appropriate offset" do
      assign(:response, instance_double(Blacklight::Solr::Response, start: 0, grouped?: false))
      expect(helper.document_counter_with_offset(0)).to be(1)
      expect(helper.document_counter_with_offset(1)).to be(2)
    end

    it "renders the document index with the appropriate offset" do
      assign(:response, instance_double(Blacklight::Solr::Response, start: 10, grouped?: false))
      expect(helper.document_counter_with_offset(0)).to be(11)
      expect(helper.document_counter_with_offset(1)).to be(12)
    end

    it "does not provide a counter for grouped responses" do
      assign(:response, instance_double(Blacklight::Solr::Response, start: 10, grouped?: true))
      expect(helper.document_counter_with_offset(0)).to be_nil
    end
  end

  describe "render_document_class" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    let :blacklight_config do
      Blacklight::Configuration.new
    end

    it "pulls data out of a document's field" do
      blacklight_config.index.display_type_field = :type
      doc = { :type => 'book' }
      expect(helper.render_document_class(doc)).to eq "blacklight-book"
    end

    it "supports multivalued fields" do
      blacklight_config.index.display_type_field = :type
      doc = { :type => ['book', 'mss'] }
      expect(helper.render_document_class(doc)).to eq "blacklight-book blacklight-mss"
    end

    it "supports empty fields" do
      blacklight_config.index.display_type_field = :type
      doc = { :type => [] }
      expect(helper.render_document_class(doc)).to be_blank
    end

    it "supports missing fields" do
      blacklight_config.index.display_type_field = :type
      doc = { }
      expect(helper.render_document_class(doc)).to be_blank
    end

    it "supports view-specific field configuration" do
      allow(helper).to receive(:document_index_view_type).and_return(:some_view_type)
      blacklight_config.view.some_view_type.display_type_field = :other_type
      doc = { other_type: "document"}
      expect(helper.render_document_class(doc)).to eq "blacklight-document"
    end
  end

  describe "#bookmarked?" do

    let(:bookmark) { Bookmark.new document: bookmarked_document }
    let(:bookmarked_document) { SolrDocument.new(id: 'a') }

    before do
      allow(helper).to receive(:current_bookmarks).and_return([bookmark])
    end

    it "is bookmarked if the document is in the bookmarks" do
      expect(helper.bookmarked?(bookmarked_document)).to eq true
    end

    it "does not be bookmarked if the document is not listed in the bookmarks" do
      expect(helper.bookmarked?(SolrDocument.new(id: 'b'))).to eq false
    end
  end

  describe "#render_search_to_page_title_filter" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
    end

    let :blacklight_config do
      Blacklight::Configuration.new
    end

    it "renders a facet with a single value" do
      expect(helper.render_search_to_page_title_filter('foo', ['bar'])).to eq "Foo: bar"
    end

    it "renders a facet with two values" do
      expect(helper.render_search_to_page_title_filter('foo', ['bar', 'baz'])).to eq "Foo: bar and baz"
    end

    it "renders a facet with more than two values" do
      expect(helper.render_search_to_page_title_filter('foo', ['bar', 'baz', 'foobar'])).to eq "Foo: 3 selected"
    end
  end

  describe "#render_search_to_page_title" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
      allow(helper).to receive(:default_search_field).and_return(Blacklight::Configuration::SearchField.new(:key => 'default_search_field', :display_label => 'Default'))
      allow(helper).to receive(:label_for_search_field).with(nil).and_return('')
    end

    let(:blacklight_config) { Blacklight::Configuration.new }

    context 'with search parameters' do
      let(:params) { ActionController::Parameters.new(q: 'foobar', f: { format: ["Book"] }) }
      subject { helper.render_search_to_page_title(params) }

      it { is_expected.to eq "foobar / Format: Book" }
    end

    context 'without search parameters' do
      let(:params) { ActionController::Parameters.new(q: '', f: {}) }
      subject { helper.render_search_to_page_title(params) }

      it { is_expected.to eq "" }
    end
  end

  describe "#render_search_title" do
    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
      allow(helper).to receive(:default_search_field).and_return(Blacklight::Configuration::SearchField.new(:key => 'default_search_field', :display_label => 'Default'))
      allow(helper).to receive(:label_for_search_field).with(nil).and_return('')
    end

    let(:blacklight_config) { Blacklight::Configuration.new }

    context 'with search parameters' do
      let(:params) { ActionController::Parameters.new(q: 'foobar', f: { format: ["Book"] }) }
      subject { helper.render_search_title(params) }

      it { is_expected.to eq "Results for \"foobar / Format: Book\" - Blacklight" }
    end

    context 'without search parameters' do
      let(:params) { ActionController::Parameters.new(q: '', f: {}) }
      subject { helper.render_search_title(params) }

      it { is_expected.to eq "All results - Blacklight" }
    end
  end
end
