# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::FacetFieldPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_field, display_facet, view_context, search_state)
  end

  let(:facet_field) { Blacklight::Configuration::FacetField.new(key: 'key') }
  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, sort: :index, offset: 0, prefix: nil)
  end
  let(:items) { [] }
  let(:view_context) { controller.view_context }
  let(:search_state) { view_context.search_state }

  before do
    allow(view_context).to receive(:facet_limit_for).and_return(20)
  end

  describe '#collapsed?' do
    it "is collapsed by default" do
      facet_field.collapse = true
      expect(presenter.collapsed?).to be true
    end

    it "does not be collapse if the configuration says so" do
      facet_field.collapse = false
      expect(presenter).not_to be_collapsed
    end

    it "does not be collapsed if it is in the params" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.collapsed?).to be false
    end
  end

  describe '#active?' do
    it "checks if any value is selected for a given facet" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.active?).to eq true
    end

    it "is false if no value for facet is selected" do
      expect(presenter.active?).to eq false
    end
  end

  describe '#in_modal?' do
    context 'for a modal-like action' do
      before do
        controller.params[:action] = 'facet'
      end

      it 'is true' do
        expect(presenter.in_modal?).to eq true
      end
    end

    it 'is false' do
      expect(presenter.in_modal?).to eq false
    end
  end

  describe '#modal_path' do
    let(:paginator) { Blacklight::FacetPaginator.new([{}, {}], limit: 1) }

    before do
      allow(view_context).to receive(:facet_paginator).and_return(paginator)
    end

    context 'with no additional data' do
      let(:paginator) { Blacklight::FacetPaginator.new([{}, {}], limit: 10) }

      it 'is nil' do
        expect(presenter.modal_path).to be_nil
      end
    end

    it 'returns the path to the facet view' do
      allow(view_context).to receive(:search_facet_path).with(id: 'key').and_return('/catalog/facet/key')

      expect(presenter.modal_path).to eq '/catalog/facet/key'
    end
  end

  describe '#label' do
    it 'gets the label from the helper' do
      allow(view_context).to receive(:facet_field_label).with('key').and_return('Label')
      expect(presenter.label).to eq 'Label'
    end
  end

  describe '#paginator' do
    subject(:paginator) { presenter.paginator }

    it 'return a paginator for the facet data' do
      expect(paginator.current_page).to eq 1
      expect(paginator.total_count).to eq 0
    end
  end
end
