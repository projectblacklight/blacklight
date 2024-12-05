# frozen_string_literal: true

RSpec.describe CatalogHelper do
  include ERB::Util
  include described_class

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

  describe "page_entries_info" do
    it "with no results" do
      @response = mock_response total: 0

      html = page_entries_info(@response, entry_name: 'entry_name')
      expect(html).to eq "No entry_names found"
      expect(html).to be_html_safe
    end

    it "with no results (and no entry_name provided)" do
      @response = mock_response total: 0

      html = page_entries_info(@response)
      expect(html).to eq "No entries found"
      expect(html).to be_html_safe
    end

    context "when response.entry_name is nil" do
      it "does not raise an error" do
        collection = mock_response total: 10
        allow(collection).to receive(:entry_name).and_return(nil)

        expect { page_entries_info(collection) }.not_to raise_error
      end
    end

    describe "with a single result" do
      it "uses the provided entry name" do
        response = mock_response total: 1

        html = page_entries_info(response, entry_name: 'entry_name')
        expect(html).to eq "<strong>1</strong> entry_name found"
        expect(html).to be_html_safe
      end

      it "infers a name" do
        response = mock_response total: 1

        html = page_entries_info(response)
        expect(html).to eq "<strong>1</strong> entry found"
        expect(html).to be_html_safe
      end
    end

    it "with a single page of results" do
      response = mock_response total: 7

      html = page_entries_info(response, entry_name: 'entry_name')
      expect(html).to eq "<strong>1</strong> - <strong>7</strong> of <strong>7</strong>"
      expect(html).to be_html_safe
    end

    it "on the first page of multiple pages of results" do
      @response = mock_response total: 15, per_page: 10

      html = page_entries_info(@response, entry_name: 'entry_name')
      expect(html).to eq "<strong>1</strong> - <strong>10</strong> of <strong>15</strong>"
      expect(html).to be_html_safe
    end

    it "on the second page of multiple pages of results" do
      @response = mock_response total: 47, per_page: 10, current_page: 2

      html = page_entries_info(@response, entry_name: 'entry_name')
      expect(html).to eq "<strong>11</strong> - <strong>20</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end

    it "on the last page of results" do
      @response = mock_response total: 47, per_page: 10, current_page: 5

      html = page_entries_info(@response, entry_name: 'entry_name')
      expect(html).to eq "<strong>41</strong> - <strong>47</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end

    it "works with rows the same as per_page" do
      @response = mock_response total: 47, rows: 20, current_page: 2

      html = page_entries_info(@response, entry_name: 'entry_name')
      expect(html).to eq "<strong>21</strong> - <strong>40</strong> of <strong>47</strong>"
      expect(html).to be_html_safe
    end

    it "uses delimiters with large numbers" do
      @response = mock_response total: 5000, rows: 10, current_page: 101
      html = page_entries_info(@response, entry_name: 'entry_name')

      expect(html).to eq "<strong>1,001</strong> - <strong>1,010</strong> of <strong>5,000</strong>"
    end

    context "with an ActiveRecord collection" do
      subject { helper.page_entries_info(Bookmark.page(1).per(25)) }

      let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345' }

      before { 50.times { Bookmark.create!(user: user) } }

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
      doc = { type: 'book' }.with_indifferent_access
      expect(helper.render_document_class(doc)).to eq "blacklight-book"
    end

    it "supports multivalued fields" do
      blacklight_config.index.display_type_field = :type
      doc = { type: %w[book mss] }.with_indifferent_access
      expect(helper.render_document_class(doc)).to eq "blacklight-book blacklight-mss"
    end

    it "supports empty fields" do
      blacklight_config.index.display_type_field = :type
      doc = { type: [] }.with_indifferent_access
      expect(helper.render_document_class(doc)).to be_blank
    end

    it "supports missing fields" do
      blacklight_config.index.display_type_field = :type
      doc = {}.with_indifferent_access
      expect(helper.render_document_class(doc)).to be_blank
    end

    it "supports view-specific field configuration" do
      allow(helper).to receive(:document_index_view_type).and_return(:some_view_type)
      blacklight_config.view.some_view_type(display_type_field: :other_type)
      doc = { other_type: "document" }.with_indifferent_access
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
      expect(helper.bookmarked?(bookmarked_document)).to be true
    end

    it "does not be bookmarked if the document is not listed in the bookmarks" do
      expect(helper.bookmarked?(SolrDocument.new(id: 'b'))).to be false
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
      expect(helper.render_search_to_page_title_filter('foo', %w[bar baz])).to eq "Foo: bar and baz"
    end

    it "renders a facet with more than two values" do
      expect(helper.render_search_to_page_title_filter('foo', %w[bar baz foobar])).to eq "Foo: 3 selected"
    end

    it "strips tags from html_safe values" do
      expect(helper.render_search_to_page_title_filter('Year', ['<span class="from" data-blrl-begin="1990">1990</span> to <span class="to" data-blrl-end="1999">1999</span>'.html_safe])).to eq "Year: 1990 to 1999"
    end

    it "does not strip tags from non-html_safe values" do
      expect(helper.render_search_to_page_title_filter('Folder', ['Some > Nested > <span>Hierarchy</span>'])).to eq "Folder: Some > Nested > <span>Hierarchy</span>"
    end
  end

  describe "#render_search_to_page_title" do
    subject { helper.render_search_to_page_title(Blacklight::SearchState.new(params, blacklight_config)) }

    before do
      allow(helper).to receive_messages(blacklight_config: blacklight_config, default_search_field: Blacklight::Configuration::SearchField.new(key: 'default_search_field', display_label: 'Default'))
      allow(helper).to receive(:label_for_search_field).with(nil).and_return('')
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new.tap do |config|
        config.add_facet_field 'format'
      end
    end

    context 'when the f param is an array' do
      let(:params) { ActionController::Parameters.new(q: 'foobar', f: { format: ["Book"] }) }

      it { is_expected.to eq "foobar / Format: Book" }
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

  describe "#document_index_view_type" do
    it "defaults to the default view" do
      allow(helper).to receive_messages(document_index_views: { a: 1, b: 2 }, default_document_index_view_type: :xyz)
      expect(helper.document_index_view_type).to eq :xyz
    end

    it "uses the query parameter" do
      allow(helper).to receive(:document_index_views).and_return(a: 1, b: 2)
      expect(helper.document_index_view_type(view: :a)).to eq :a
    end

    it "uses the default view if the requested view is not available" do
      allow(helper).to receive_messages(default_document_index_view_type: :xyz, document_index_views: { a: 1, b: 2 })
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
end
