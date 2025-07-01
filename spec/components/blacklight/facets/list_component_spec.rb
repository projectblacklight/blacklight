# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Facets::ListComponent, type: :component do
  before do
    render_inline(described_class.new(facet_field: facet_field))
  end

  let(:facet_field) do
    instance_double(
      Blacklight::FacetFieldPresenter,
      paginator: paginator,
      facet_field: facet_config,
      key: 'field',
      label: 'Field',
      active?: false,
      collapsed?: false,
      modal_path: nil,
      values: []
    )
  end

  let(:facet_config) { Blacklight::Configuration::NullField.new(key: 'field', item_component: Blacklight::Facets::ItemComponent, item_presenter: Blacklight::FacetItemPresenter) }

  let(:paginator) do
    instance_double(Blacklight::FacetPaginator, items: [
                      double(label: 'x', hits: 10),
                      double(label: 'y', hits: 33)
                    ])
  end

  it 'renders an accordion item' do
    expect(page).to have_css '.accordion-item'
    expect(page).to have_button 'Field'
    expect(page).to have_css 'button[data-bs-target="#facet-field"]'
    expect(page).to have_css '#facet-field.collapse.show'
  end

  it 'renders the facet items' do
    expect(page).to have_css 'ul.facet-values'
    expect(page).to have_css 'li', count: 2
  end

  it 'does not add a role attribute by default' do
    expect(page).to have_css 'ul.facet-values'
    expect(page).to have_no_css 'ul.facet-values[role]'
  end

  context 'with an active facet' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        facet_field: facet_config,
        key: 'field',
        label: 'Field',
        active?: true,
        collapsed?: false,
        modal_path: nil,
        values: []
      )
    end

    it 'adds the facet-limit-active class' do
      expect(page).to have_css 'div.facet-limit-active'
    end
  end

  context 'with a collapsed facet' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        facet_field: facet_config,
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: true,
        modal_path: nil,
        values: []
      )
    end

    it 'renders a collapsed facet' do
      expect(page).to have_css '.facet-content.collapse'
      expect(page).to have_no_css '.facet-content.collapse.show'
    end

    it 'renders the toggle button in the collapsed state' do
      expect(page).to have_css '.btn.collapsed'
      expect(page).to have_css '.btn[aria-expanded="false"]'
    end
  end

  context 'with a modal_path' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        facet_field: facet_config,
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: false,
        modal_path: '/catalog/facet/modal',
        values: []
      )
    end

    it 'renders a link to the modal' do
      expect(page).to have_link 'more Field', href: '/catalog/facet/modal'
    end
  end

  context 'with inclusive facets' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        facet_field: facet_config,
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: false,
        modal_path: nil,
        values: [%w[a b c]],
        search_state: search_state
      )
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_facet_field :field
      end
    end
    let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, blacklight_config) }
    let(:params) { { f_inclusive: { field: %w[a b c] } } }

    it 'displays the constraint above the list' do
      expect(page).to have_content 'Any of:'
      expect(page).to have_css '.inclusive_or .facet-label', text: 'a'
      expect(page).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=b&f_inclusive%5Bfield%5D%5B%5D=c'
      expect(page).to have_css '.inclusive_or .facet-label', text: 'b'
      expect(page).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=a&f_inclusive%5Bfield%5D%5B%5D=c'
      expect(page).to have_css '.inclusive_or .facet-label', text: 'c'
      expect(page).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=a&f_inclusive%5Bfield%5D%5B%5D=b'
    end
  end
end
