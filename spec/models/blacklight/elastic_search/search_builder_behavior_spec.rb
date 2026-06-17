# frozen_string_literal: true

RSpec.describe Blacklight::ElasticSearch::SearchBuilderBehavior, :api do
  subject(:body) { search_builder.with(user_params).to_hash }

  let(:search_builder_class) do
    Class.new(Blacklight::SearchBuilder) do
      include Blacklight::ElasticSearch::SearchBuilderBehavior
    end
  end
  let(:search_builder) { search_builder_class.new(context) }
  let(:context) { CatalogController.new }
  let(:user_params) { {} }

  let(:blacklight_config) do
    Blacklight::Configuration.new.tap do |config|
      config.add_facet_field 'format'
      config.add_facet_field 'language_ssim', limit: 5
      config.add_index_field 'title_tsim', highlight: true
      config.add_sort_field 'relevance', sort: 'score desc, title_si asc'
      config.add_facet_fields_to_solr_request!
    end
  end

  before { allow(context).to receive(:blacklight_config).and_return(blacklight_config) }

  describe 'the default processor chain' do
    it 'does not include Solr-only steps' do
      expect(search_builder.processor_chain).not_to include(:add_group_config_to_solr, :add_adv_search_clauses)
    end
  end

  describe '#add_query_to_request' do
    context 'with a query' do
      let(:user_params) { { q: 'history' } }

      it 'adds a simple_query_string clause targeting the all_text field' do
        expect(body.dig(:query, :bool, :must)).to include(
          simple_query_string: { query: 'history', fields: ['all_text'], default_operator: 'and' }
        )
      end
    end

    context 'with configured query fields' do
      let(:user_params) { { q: 'history' } }

      before { blacklight_config.elasticsearch_query_fields = %w[title_tsim author_tsim] }

      it 'uses a multi_match clause' do
        expect(body.dig(:query, :bool, :must)).to include(
          multi_match: { query: 'history', fields: %w[title_tsim author_tsim], type: 'best_fields', operator: 'and' }
        )
      end
    end

    context 'with a selected search field that scopes the query fields' do
      let(:user_params) { { q: 'history', search_field: 'title' } }

      before do
        blacklight_config.add_search_field('title') { |field| field.elastic_query_fields = %w[title_tsim title_addl_tsim] }
      end

      it 'scopes the multi_match to the search field fields' do
        expect(body.dig(:query, :bool, :must)).to include(
          multi_match: { query: 'history', fields: %w[title_tsim title_addl_tsim], type: 'best_fields', operator: 'and' }
        )
      end
    end

    context 'without a query' do
      it 'does not add a query clause' do
        expect(body[:query]).to be_nil
      end
    end
  end

  describe '#add_filters_to_request' do
    let(:user_params) { { f: { 'format' => ['Book'] } } }

    it 'adds a terms filter' do
      expect(body.dig(:query, :bool, :filter)).to include(terms: { 'format' => ['Book'] })
    end

    context 'when filtering on a missing value' do
      let(:user_params) { { f: { '-format' => [Blacklight::Engine.config.blacklight.facet_missing_param] } } }

      it 'adds a must_not exists clause' do
        expect(body.dig(:query, :bool, :must_not)).to include(exists: { field: 'format' })
      end
    end
  end

  describe '#add_facetting_to_request' do
    it 'adds a terms aggregation for each facet field, requesting limit + 1 values' do
      expect(body[:aggs]['format'][:terms]).to include(field: 'format')
      expect(body[:aggs]['language_ssim'][:terms]).to include(field: 'language_ssim', size: 6)
    end
  end

  describe '#add_paging_to_request' do
    let(:user_params) { { per_page: 20, page: 3 } }

    it 'maps page/per_page to size/from' do
      expect(body[:size]).to eq 20
      expect(body[:from]).to eq 40
    end
  end

  describe '#add_sorting_to_request' do
    let(:user_params) { { sort: 'relevance' } }

    it 'translates the Solr-style sort string into ES sort syntax' do
      expect(body[:sort]).to eq [{ '_score' => { order: 'desc' } }, { 'title_si' => { order: 'asc' } }]
    end
  end

  describe '#add_highlighting_to_request' do
    it 'requests highlighting for fields configured with highlight: true' do
      expect(body.dig(:highlight, :fields)).to have_key('title_tsim')
    end
  end
end
