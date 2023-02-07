# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldCheckboxesComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(facet_field: facet_field))
  end

  let(:facet_field) do
    instance_double(
      Blacklight::FacetFieldPresenter,
      facet_field: Blacklight::Configuration::NullField.new(key: 'field', item_component: Blacklight::FacetItemComponent, item_presenter: Blacklight::FacetItemPresenter),
      paginator: paginator,
      key: 'field',
      label: 'Field',
      active?: false,
      collapsed?: false,
      modal_path: nil,
      search_state: search_state
    )
  end

  let(:paginator) do
    instance_double(Blacklight::FacetPaginator, items: [
                      double(label: 'a', hits: 10, value: 'a'),
                      double(label: 'b', hits: 33, value: 'b'),
                      double(label: 'c', hits: 3, value: 'c')
                    ])
  end

  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, Blacklight::Configuration.new) }
  let(:params) { { f: { field: ['a'] } } }

  it 'renders a collapsible card' do
    expect(rendered).to have_selector 'details.card'
    expect(rendered).to have_selector 'summary', text: 'Field'
  end

  it 'renders the facet items' do
    expect(rendered).to have_selector 'ul.facet-values'
    expect(rendered).to have_selector 'li', count: 3

    expect(rendered).to have_field 'f_inclusive[field][]', with: 'a'
    expect(rendered).to have_field 'f_inclusive[field][]', with: 'b'
    expect(rendered).to have_field 'f_inclusive[field][]', with: 'c'
  end
end
