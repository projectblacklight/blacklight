# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Facets::PivotListComponent, type: :component do
  before do
    render_inline(described_class.new(facet_field: facet_field))
  end

  let(:facet_field) do
    instance_double(
      Blacklight::FacetFieldPresenter,
      paginator: paginator,
      facet_field: facet_config,
      key: 'pivot_field',
      label: 'Pivot Field',
      active?: false,
      collapsed?: false,
      modal_path: nil,
      values: []
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::NullField.new(
      key: 'pivot_field',
      item_component: Blacklight::FacetItemPivotComponent,
      item_presenter: Blacklight::FacetItemPivotPresenter,
      pivot: %w[field_a field_b]
    )
  end

  let(:paginator) do
    instance_double(Blacklight::FacetPaginator, items: [
                      double(value: 'x', hits: 10),
                      double(value: 'y', hits: 33)
                    ])
  end

  it 'renders the facet items top ul with "pivot-facet" class' do
    expect(page).to have_css 'ul.pivot-facet'
  end

  it 'renders the facet items with role="tree"' do
    expect(page).to have_css 'ul.facet-values[role="tree"]'
  end
end
