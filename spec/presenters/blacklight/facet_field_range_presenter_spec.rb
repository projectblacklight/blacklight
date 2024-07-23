# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldRangePresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_field, display_facet, view_context, search_state)
  end

  let(:facet_field) do
    Blacklight::Configuration::FacetField.new(
      key: 'field_key',
      field: 'some_field',
      filter_class: Blacklight::SearchState::RangeFilterField
    )
  end

  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, sort: :index, offset: 0, prefix: nil, response: response)
  end
  let(:response) { instance_double(Blacklight::Solr::Response, total: 12) }

  let(:view_context) { controller.view_context }
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config, view_context) }

  let(:blacklight_config) do
    Blacklight::Configuration.new.tap { |x| x.facet_fields['field_key'] = facet_field }
  end

  let(:params) { {} }
  let(:items) { [] }

  describe '#paginator' do
    subject(:paginator) { presenter.paginator }

    context 'when no range is selected' do
      let(:items) { [Blacklight::Solr::Response::Facets::FacetItem.new(missing: true, value: '[Missing]')] }

      it 'contains [Missing] facet' do
        expect(paginator.total_count).to be 1
        expect(paginator.items.first.value).to be '[Missing]'
      end
    end

    context 'with a user selected range' do
      let(:params) { { range: { field_key: { start: 100, end: 250 } } } }

      it 'contains selected facet' do
        expect(paginator.total_count).to be 1
        expect(paginator.items.first.value).to eql 100..250
      end
    end
  end

  describe '#missing_selected?' do
    context 'when missing facet is selected' do
      let(:params) { { range: { '-field_key' => ['[* TO *]'] } } }

      it 'returns true' do
        expect(presenter.missing_selected?).to be true
      end
    end

    it 'returns false if missing facet not selected' do
      expect(presenter.missing_selected?).to be false
    end
  end

  describe '#selected_range' do
    it 'returns nil if no range is selected' do
      expect(presenter.selected_range).to be_nil
    end

    context 'with a user-selected range' do
      let(:params) { { range: { field_key: { start: 100, end: 250 } } } }

      it 'returns the selected range' do
        expect(presenter.selected_range).to eq 100..250
      end
    end
  end
end
