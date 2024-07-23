# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemRangePresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
  end

  let(:facet_item) { instance_double(Blacklight::Solr::Response::Facets::FacetItem) }
  let(:filter_field) { instance_double(Blacklight::SearchState::FilterField, include?: true) }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'key') }
  let(:facet_field) { instance_double(Blacklight::Solr::Response::Facets::FacetField) }
  let(:view_context) { controller.view_context }
  let(:search_state) { instance_double(Blacklight::SearchState, filter: filter_field) }

  describe '#label' do
    context 'with a single value' do
      let(:facet_item) { 'blah' }

      it 'uses the normal logic for item values' do
        expect(presenter.label).to eq 'blah'
      end
    end

    context 'with a range' do
      let(:facet_item) { 1234..2345 }

      it 'translates the range into some nice, human-readable html' do
        expect(Capybara.string(presenter.label)).to have_text('1234 to 2345')
      end
    end

    context 'with a range that has the same start + end values' do
      let(:facet_item) { 2021..2021 }

      it 'translates the range into some nice, human-readable html' do
        expect(Capybara.string(presenter.label)).to have_text('2021')
      end
    end
  end
end
