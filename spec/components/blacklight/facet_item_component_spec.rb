# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(facet_item: facet_item))
  end

  let(:facet_item) do
    instance_double(
      Blacklight::FacetItemPresenter,
      facet_config: Blacklight::Configuration::FacetField.new,
      label: 'x',
      hits: 10,
      href: '/catalog?f=x',
      selected?: false
    )
  end

  it 'links to the facet and shows the number of hits' do
    expect(rendered).to have_selector 'li'
    expect(rendered).to have_link 'x', href: '/catalog?f=x'
    expect(rendered).to have_selector '.facet-count', text: '10'
  end

  context 'with a selected facet' do
    let(:facet_item) do
      instance_double(
        Blacklight::FacetItemPresenter,
        facet_config: Blacklight::Configuration::FacetField.new,
        label: 'x',
        hits: 10,
        href: '/catalog',
        selected?: true
      )
    end

    it 'links to the facet and shows the number of hits' do
      expect(rendered).to have_selector 'li'
      expect(rendered).to have_selector '.selected', text: 'x'
      expect(rendered).to have_link '[remove]', href: '/catalog'
      expect(rendered).to have_selector '.selected.facet-count', text: '10'
    end
  end
end
