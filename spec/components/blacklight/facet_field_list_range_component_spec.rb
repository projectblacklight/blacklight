# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldListRangeComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(facet_field: facet_field))
  end

  let(:facet_field) do
    instance_double(
      Blacklight::FacetFieldRangePresenter,
      paginator: paginator,
      facet_field: facet_config,
      key: 'field',
      label: 'My facet field',
      active?: false,
      collapsed?: false,
      modal_path: nil,
      selected_range: nil,
      selected_item: nil,
      missing_selected?: false,
      search_state: Blacklight::SearchState.new({}, nil)
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::NullField.new(
      key: 'field',
      item_component: Blacklight::FacetItemComponent,
      item_presenter: Blacklight::FacetItemRangePresenter
    )
  end

  let(:paginator) { instance_double(Blacklight::FacetPaginator, items: items) }
  let(:items) { [] }

  it 'renders into the default facet layout' do
    expect(rendered).to have_selector('h3', text: 'My facet field')
    expect(rendered).to have_selector '.facet-content.collapse'
  end

  it 'renders a form for the range' do
    expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
    expect(rendered).to have_field('range[field][start]')
    expect(rendered).to have_field('range[field][end]')
  end

  it 'does not render the missing link if there are no matching documents' do
    expect(rendered).not_to have_link '[Missing]'
  end

  context 'with missing documents' do
    let(:items) do
      [
        Blacklight::Solr::Response::Facets::FacetItem.new(
          value: Blacklight::SearchState::FilterField::MISSING,
          hits: 50
        )
      ]
    end

    it 'renders a facet value for the documents that are missing the field data' do
      expected_facet_query_param = Regexp.new(Regexp.escape({ f: { '-field': ['[* TO *]'] } }.to_param))
      expect(rendered).to have_link '[Missing]', href: expected_facet_query_param
    end
  end
end
