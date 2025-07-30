# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ConstraintsComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  before { render_inline(component) }

  let(:params) do
    { search_state: search_state }
  end

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field :some_facet
    end
  end

  let(:search_state) { Blacklight::SearchState.new(query_params.with_indifferent_access, blacklight_config) }
  let(:query_params) { {} }

  context 'with no constraints' do
    describe '#render?' do
      it 'is false' do
        expect(component.render?).to be false
      end
    end
  end

  context 'with a query' do
    let(:query_params) { { q: 'some query' } }

    it 'renders a start-over link' do
      expect(page).to have_link 'Start Over', href: '/catalog'
    end

    it 'has a header' do
      expect(page).to have_css('h2', text: 'Your selections:')
    end

    it 'wraps the output in a div' do
      expect(page).to have_css('div#appliedParams')
    end

    it 'renders the query' do
      expect(page).to have_css('.applied-filter.constraint', text: 'some query')
    end
  end

  context 'with a facet' do
    let(:query_params) { { f: { some_facet: ['some value'] } } }

    it 'renders the query' do
      expect(page).to have_css('.constraint-value > .filter-name', text: 'Some Facet').and(have_css('.constraint-value > .filter-value', text: 'some value'))
    end

    context 'that is not configured' do
      let(:query_params) { { f: { some_facet: ['some value'], missing: ['another value'] } } }

      it 'renders only the configured constraints' do
        expect(page).to have_css('.constraint-value > .filter-name', text: 'Some Facet').and(have_css('.constraint-value > .filter-value', text: 'some value'))
        expect(page).to have_no_css('.constraint-value > .filter-name', text: 'Missing')
      end
    end
  end

  describe '.for_search_history' do
    subject(:component) { described_class.for_search_history(**params) }

    let(:query_params) { { q: 'some query', f: { some_facet: ['some value'] } } }

    it 'wraps the output in a span' do
      expect(page).to have_css('span .constraint')
    end

    it 'renders the search state as lightly-decorated text' do
      expect(page).to have_css('.constraint > .filter-values', text: 'some query').and(have_css('.constraint', text: 'Some Facet:some value'))
    end
  end
end
