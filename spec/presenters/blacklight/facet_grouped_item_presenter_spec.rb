# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::FacetGroupedItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(group, facet_item, facet_config, view_context, facet_field, search_state)
  end

  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'key') }
  let(:facet_field) { instance_double(Blacklight::Solr::Response::Facets::FacetField) }
  let(:view_context) { controller.view_context }

  let(:facet_item) { 'a' }
  let(:group) { %w[a b c] }
  let(:search_state) { Blacklight::SearchState.new(params, Blacklight::Configuration.new) }
  let(:params) { { f_inclusive: { key: group } } }

  describe '#selected' do
    it { is_expected.to be_selected }

    context 'when the item is not in the group' do
      let(:facet_item) { 'd' }

      it { is_expected.not_to be_selected }
    end

    describe '#href' do
      it 'removes the item from the "group" of filters' do
        expect(Rack::Utils.parse_query(URI(presenter.href).query)).to include 'f_inclusive[key][]' => %w[b c]
      end

      context 'when the item is not in the group' do
        let(:facet_item) { 'd' }

        it 'adds the item to the "group" of filters' do
          expect(Rack::Utils.parse_query(URI(presenter.href).query)).to include 'f_inclusive[key][]' => %w[a b c d]
        end
      end
    end
  end
end
