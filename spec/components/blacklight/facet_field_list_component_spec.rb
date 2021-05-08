# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldListComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(facet_field: facet_field))
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:facet_field) do
    instance_double(
      Blacklight::FacetFieldPresenter,
      paginator: paginator,
      key: 'field',
      label: 'Field',
      active?: false,
      collapsed?: false,
      modal_path: nil,
      values: []
    )
  end

  let(:paginator) do
    instance_double(Blacklight::FacetPaginator, items: [
                      double(label: 'x', hits: 10),
                      double(label: 'y', hits: 33)
                    ])
  end

  it 'renders a collapsible card' do
    expect(rendered).to have_selector '.card'
    expect(rendered).to have_button 'Field'
    expect(rendered).to have_selector 'button[data-target="#facet-field"]'
    expect(rendered).to have_selector '#facet-field.collapse.show'
  end

  it 'renders the facet items' do
    expect(rendered).to have_selector 'ul.facet-values'
    expect(rendered).to have_selector 'li', count: 2
  end

  context 'with an active facet' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        key: 'field',
        label: 'Field',
        active?: true,
        collapsed?: false,
        modal_path: nil,
        values: []
      )
    end

    it 'adds the facet-limit-active class' do
      expect(rendered).to have_selector 'div.facet-limit-active'
    end
  end

  context 'with a collapsed facet' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: true,
        modal_path: nil,
        values: []
      )
    end

    it 'renders a collapsed facet' do
      expect(rendered).to have_selector '.facet-content.collapse'
      expect(rendered).not_to have_selector '.facet-content.collapse.show'
    end

    it 'renders the toggle button in the collapsed state' do
      expect(rendered).to have_selector '.btn.collapsed'
      expect(rendered).to have_selector '.btn[aria-expanded="false"]'
    end
  end

  context 'with a modal_path' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: false,
        modal_path: '/catalog/facet/modal',
        values: []
      )
    end

    it 'renders a link to the modal' do
      expect(rendered).to have_link 'more Field', href: '/catalog/facet/modal'
    end
  end

  context 'with inclusive facets' do
    let(:facet_field) do
      instance_double(
        Blacklight::FacetFieldPresenter,
        paginator: paginator,
        facet_field: Blacklight::Configuration::NullField.new(key: 'field'),
        key: 'field',
        label: 'Field',
        active?: false,
        collapsed?: false,
        modal_path: nil,
        html_id: 'facet-field',
        values: [%w[a b c]],
        search_state: search_state
      )
    end

    let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, Blacklight::Configuration.new) }
    let(:params) { { f_inclusive: { field: %w[a b c] } } }

    it 'displays the constraint above the list' do
      expect(rendered).to have_content 'Any of:'
      expect(rendered).to have_selector '.inclusive_or .facet-label', text: 'a'
      expect(rendered).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=b&f_inclusive%5Bfield%5D%5B%5D=c'
      expect(rendered).to have_selector '.inclusive_or .facet-label', text: 'b'
      expect(rendered).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=a&f_inclusive%5Bfield%5D%5B%5D=c'
      expect(rendered).to have_selector '.inclusive_or .facet-label', text: 'c'
      expect(rendered).to have_link '[remove]', href: 'http://test.host/catalog?f_inclusive%5Bfield%5D%5B%5D=a&f_inclusive%5Bfield%5D%5B%5D=b'
    end
  end
end
