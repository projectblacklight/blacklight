# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ConstraintsComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:rendered) { render_inline_to_capybara_node(component) }

  let(:params) do
    { search_state: search_state }
  end

  let(:blacklight_config) do
    Blacklight::Configuration.new.tap do |config|
      config.add_facet_field 'facet'
    end
  end

  let(:search_state) { Blacklight::SearchState.new(query_params.with_indifferent_access, blacklight_config) }
  let(:query_params) { {} }

  context 'with no constraints' do
    describe '#render?' do
      it 'is false' do
        expect(component.render?).to eq false
      end
    end
  end

  context 'with a query' do
    let(:query_params) { { q: 'some query' } }

    it 'renders a start-over link' do
      expect(rendered).to have_link 'Start Over', href: '/catalog'
    end

    it 'has a header' do
      expect(rendered).to have_selector('h2', text: 'Search Constraints')
    end

    it 'wraps the output in a div' do
      expect(rendered).to have_selector('div#appliedParams')
    end

    it 'renders the query' do
      expect(rendered).to have_selector('.applied-filter.constraint', text: 'some query')
    end
  end

  context 'with a facet' do
    let(:query_params) { { f: { facet: ['some value'] } } }

    it 'renders the query' do
      expect(rendered).to have_selector('.constraint-value > .filter-name', text: 'Facet').and(have_selector('.constraint-value > .filter-value', text: 'some value'))
    end

    context 'that is not configured' do
      let(:query_params) { { f: { facet: ['some value'], missing: ['another value'] } } }

      it 'renders only the configured constraints' do
        expect(rendered).to have_selector('.constraint-value > .filter-name', text: 'Facet').and(have_selector('.constraint-value > .filter-value', text: 'some value'))
        expect(rendered).not_to have_selector('.constraint-value > .filter-name', text: 'Missing')
      end
    end
  end

  describe '.for_search_history' do
    subject(:component) { described_class.for_search_history(**params) }

    let(:query_params) { { q: 'some query', f: { facet: ['some value'] } } }

    it 'wraps the output in a span' do
      expect(rendered).to have_selector('span .constraint')
    end

    it 'renders the search state as lightly-decorated text' do
      expect(rendered).to have_selector('.constraint > .filter-values', text: 'some query').and(have_selector('.constraint', text: 'Facet:some value'))
    end

    it 'omits the headers' do
      expect(rendered).not_to have_selector('h2', text: 'Search Constraints')
    end
  end
end
