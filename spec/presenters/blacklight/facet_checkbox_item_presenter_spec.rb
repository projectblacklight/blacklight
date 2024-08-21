# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetCheckboxItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
  end

  let(:facet_item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Book', hits: 30) }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'format') }
  let(:view_context) { controller.view_context }
  let(:filter_field) { Blacklight::SearchState::FilterField.new(facet_config, search_state) }
  let(:facet_field) { Blacklight::Solr::Response::Facets::FacetField.new('format', [facet_item]) }
  let(:params) { ActionController::Parameters.new(f_inclusive: { format: ["Book"] }) }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config) }

  before do
    blacklight_config.add_facet_field 'format'
  end

  describe '#selected?' do
    subject { presenter.selected? }

    context 'with a matching inclusive filter' do
      it { is_expected.to be true }
    end

    context 'with an inclusive filter that does not match' do
      let(:params) { ActionController::Parameters.new(f_inclusive: { format: ["Manuscript"] }) }

      it { is_expected.to be false }
    end

    context 'with a matching exclusive filter' do
      let(:params) { ActionController::Parameters.new(f: { format: ["Book"] }) }

      it { is_expected.to be false }
    end
  end
end
