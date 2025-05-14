# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Facets::FiltersComponent, type: :component do
  let(:facet_field) { Blacklight::Configuration::FacetField.new key: 'language_facet', suggest: true }
  let(:presenter) do
    instance_double(Blacklight::FacetFieldPresenter, facet_field: facet_field, label: 'Lang',
                                                     view_context: view_context, suggest: true, key: 'lang')
  end
  let(:view_context) { vc_test_controller.view_context }

  before do
    allow(view_context).to receive(:search_facet_path).and_return('/catalog/facet/language_facet')

    with_request_url '/catalog?q=foo' do
      render_inline(component)
    end
  end

  context 'with default classes' do
    let(:component) { described_class.new(presenter: presenter) }

    it 'draws default classes' do
      expect(page).to have_css(".facet-filters.card.card-body.bg-light.p-3.mb-3.border-0")
    end
  end

  context 'with custom classes' do
    let(:component) { described_class.new(presenter: presenter, classes: 'foo') }

    it 'draws default classes' do
      expect(page).to have_css(".foo")
    end
  end
end
