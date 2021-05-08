# frozen_string_literal: true

RSpec.describe Blacklight::SearchState do
  subject(:search_state) { described_class.new(params, blacklight_config, controller) }

  around { |test| Deprecation.silence(described_class) { test.call } }

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.index.title_field = 'title_tsim'
      config.index.display_type_field = 'format'
    end
  end

  let(:parameter_class) { ActionController::Parameters }
  let(:controller) { double }
  let(:params) { parameter_class.new }

  describe '#to_h' do
    let(:data) { { a: '1' } }
    let(:params) { parameter_class.new data }

    it 'returns a copy of the original parameters' do
      expect(search_state.to_h).to eq data.with_indifferent_access
      expect(search_state.to_h.object_id).not_to eq params.object_id
    end

    context 'with AC::Parameters' do
      let(:parameter_class) { ActionController::Parameters }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end

    context 'with HashWithIndifferentAccess' do
      let(:parameter_class) { HashWithIndifferentAccess }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end

    context 'with Hash' do
      let(:params) { data }

      it 'returns the hash data' do
        expect(search_state.to_h).to eq data.with_indifferent_access
      end
    end

    context 'with facebooks badly mangled query parameters' do
      let(:params) { { f: { field: { '0': 'first', '1': 'second' } } } }

      it 'normalizes the facets to the expected format' do
        expect(search_state.to_h).to include f: { field: %w[first second] }
      end
    end

    context 'deleting item from to_h' do
      let(:params) { { q: 'foo', q_1: 'bar' } }

      it 'does not mutate search_state to mutate search_state.to_h' do
        params = search_state.to_h
        params.delete(:q_1)

        expect(search_state.to_h).to eq('q' => 'foo', 'q_1' => 'bar')
        expect(params).to eq('q' => 'foo')
      end
    end

    context 'deleting deep item from to_h' do
      let(:params) { { foo: { bar: [] } } }

      it 'does not mutate search_state to deep mutate search_state.to_h' do
        params = search_state.to_h
        params[:foo][:bar] << 'buzz'

        expect(search_state.to_h).to eq('foo' => { 'bar' => [] })
        expect(params).to eq('foo' => { 'bar' => ['buzz'] })
      end
    end
  end

  describe '#query_param' do
    let(:params) { parameter_class.new q: 'xyz' }

    it 'returns the query param' do
      expect(search_state.query_param).to eq 'xyz'
    end
  end

  describe '#has_constraints?' do
    it 'is false' do
      expect(search_state.has_constraints?).to eq false
    end

    context 'with a query param' do
      let(:params) { parameter_class.new q: 'xyz' }

      it 'is true' do
        expect(search_state.has_constraints?).to eq true
      end
    end

    context 'with a facet param' do
      let(:params) { parameter_class.new f: { format: ['xyz'] } }

      before do
        blacklight_config.add_facet_field 'format', label: 'Format'
      end

      it 'is true' do
        expect(search_state.has_constraints?).to eq true
      end
    end
  end

  describe "params_for_search" do
    let(:params) { parameter_class.new 'default' => 'params' }

    it "takes original params" do
      result = search_state.params_for_search
      expect(result).to eq('default' => 'params')
      expect(params.object_id).not_to eq result.object_id
    end

    it "accepts params to merge into the controller's params" do
      result = search_state.params_for_search(q: 'query')
      expect(result).to eq('q' => 'query', 'default' => 'params')
    end

    context "when params have blacklisted keys" do
      let(:params) { parameter_class.new action: 'action', controller: 'controller', id: "id", commit: 'commit' }

      it "removes them" do
        result = search_state.params_for_search
        expect(result.keys).not_to include(:action, :controller, :commit, :id)
      end
    end

    context "when params has page" do
      context "and per_page changed" do
        let(:params) { parameter_class.new per_page: 20, page: 5 }

        it "adjusts the current page" do
          result = search_state.params_for_search(per_page: 100)
          expect(result[:page]).to eq 1
        end
      end

      context "and per_page didn't change" do
        let(:params) { parameter_class.new per_page: 20, page: 5 }

        it "doesn't change the current page" do
          result = search_state.params_for_search(per_page: 20)
          expect(result[:page]).to eq 5
        end
      end

      context "and the sort changes" do
        let(:params) { parameter_class.new sort: 'field_a', page: 5 }

        it "adjusts the current page" do
          result = search_state.params_for_search(sort: 'field_b')
          expect(result[:page]).to eq 1
        end
      end

      context "and the sort didn't change" do
        let(:params) { parameter_class.new sort: 'field_a', page: 5 }

        it "doesn't change the current page" do
          result = search_state.params_for_search(sort: 'field_a')
          expect(result[:page]).to eq 5
        end
      end
    end

    context "with a block" do
      let(:params) { parameter_class.new a: 1, b: 2 }

      it "evalutes the block and allow it to add or remove keys" do
        result = search_state.params_for_search(c: 3) do |params|
          params.extract! :a, :b
          params[:d] = 'd'
        end

        expect(result.keys).not_to include(:a, :b)
        expect(result[:c]).to eq 3
        expect(result[:d]).to eq 'd'
      end
    end
  end

  describe "add_facet_params_and_redirect" do
    let(:params) do
      parameter_class.new(
        q: "query",
        search_field: "search_field",
        per_page: "50",
        page: "5",
        f: { "facet_field_1" => ["value1"], "facet_field_2" => %w[value2 value2a] },
        Blacklight::Solr::FacetPaginator.request_keys[:page] => "100",
        Blacklight::Solr::FacetPaginator.request_keys[:sort] => "index",
        id: 'facet_field_name'
      )
    end

    it "does not include request parameters used by the facet paginator" do
      params = search_state.add_facet_params_and_redirect("facet_field_2", "facet_value")

      bad_keys = Blacklight::Solr::FacetPaginator.request_keys.values + [:id]
      bad_keys.each do |paginator_key|
        expect(params.keys).not_to include(paginator_key)
      end
    end

    it 'removes :page request key' do
      params = search_state.add_facet_params_and_redirect("facet_field_2", "facet_value")
      expect(params).not_to have_key(:page)
    end
  end

  describe '#reset' do
    it 'returns a search state with the given parameters' do
      new_state = search_state.reset('a' => 1)

      expect(new_state.to_hash).to eq('a' => 1)
    end
  end

  describe '#page' do
    context 'with a page' do
      let(:params) { { 'page' => '3' } }

      it 'is mapped from page' do
        expect(search_state.page).to eq 3
      end
    end

    context 'without a page' do
      let(:params) { {} }

      it 'is defaults to page 1' do
        expect(search_state.page).to eq 1
      end

      context 'with negative numbers or other bad data' do
        let(:params) { { 'page' => '-3' } }

        it 'is defaults to page 1' do
          expect(search_state.page).to eq 1
        end
      end
    end
  end

  describe '#per_page' do
    context 'with rows' do
      let(:params) { { rows: '30' } }

      it 'maps from rows' do
        expect(search_state.per_page).to eq 30
      end
    end

    context 'with per_page' do
      let(:params) { { per_page: '14' } }

      it 'maps from rows' do
        expect(search_state.per_page).to eq 14
      end
    end

    context 'it defaults to the configured value' do
      let(:params) { {} }

      it 'maps from rows' do
        expect(search_state.per_page).to eq 10
      end
    end
  end

  describe '#sort_field' do
    let(:params) { { 'sort' => 'author' } }

    before do
      blacklight_config.add_sort_field 'relevancy', label: 'relevance'
      blacklight_config.add_sort_field 'author', label: 'asd'
    end

    it 'returns the current search field' do
      expect(search_state.sort_field).to have_attributes(key: 'author')
    end

    context 'without a search field' do
      let(:params) { {} }

      it 'returns the current search field' do
        expect(search_state.sort_field).to have_attributes(key: 'relevancy')
      end
    end
  end

  describe '#search_field' do
    let(:params) { { 'search_field' => 'author' } }

    before do
      blacklight_config.add_search_field 'author', label: 'asd'
    end

    it 'returns the current search field' do
      expect(search_state.search_field).to have_attributes(key: 'author')
    end
  end

  describe '#facet_page' do
    context 'with a page' do
      let(:params) { { 'facet.page' => '3' } }

      it 'is mapped from facet.page' do
        expect(search_state.facet_page).to eq 3
      end
    end

    context 'without a page' do
      let(:params) { {} }

      it 'is defaults to page 1' do
        expect(search_state.facet_page).to eq 1
      end
    end

    context 'with negative numbers or other bad data' do
      let(:params) { { 'facet.page' => '-3' } }

      it 'is defaults to page 1' do
        expect(search_state.facet_page).to eq 1
      end
    end
  end

  describe '#facet_sort' do
    let(:params) { { 'facet.sort' => 'index' } }

    it 'is mapped from facet.sort' do
      expect(search_state.facet_sort).to eq 'index'
    end
  end

  describe '#facet_prefix' do
    let(:params) { { 'facet.prefix' => 'A' } }

    it 'is mapped from facet.prefix' do
      expect(search_state.facet_prefix).to eq 'A'
    end
  end

  describe "#url_for_document" do
    let(:controller_class) { ::CatalogController.new }
    let(:doc) { SolrDocument.new }

    before do
      allow(search_state).to receive_messages(controller: controller_class)
      allow(search_state).to receive_messages(controller_name: controller_class.controller_name)
      allow(search_state).to receive_messages(params: parameter_class.new)
    end

    it "is a polymorphic routing-ready object" do
      expect(search_state.url_for_document(doc)).to eq doc
    end

    it "allows for custom show routes" do
      search_state.blacklight_config.show.route = { controller: 'catalog' }
      expect(search_state.url_for_document(doc)).to eq(controller: 'catalog', action: :show, id: doc)
    end

    context "within bookmarks" do
      let(:controller_class) { ::BookmarksController.new }

      it "uses polymorphic routing" do
        expect(search_state.url_for_document(doc)).to eq doc
      end
    end

    context "within an alternative catalog controller" do
      let(:controller_class) { ::AlternateController.new }

      before do
        search_state.blacklight_config.show.route = { controller: :current }
        allow(search_state).to receive(:params).and_return(parameter_class.new(controller: 'alternate'))
      end

      it "supports the :current controller configuration" do
        expect(search_state.url_for_document(doc)).to eq(controller: 'alternate', action: :show, id: doc)
      end
    end

    it "is a polymorphic route if the solr document responds to #to_model with a non-SolrDocument" do
      some_model = double
      doc = SolrDocument.new
      allow(doc).to receive_messages(to_model: some_model)
      expect(search_state.url_for_document(doc)).to eq doc
    end
  end
end
