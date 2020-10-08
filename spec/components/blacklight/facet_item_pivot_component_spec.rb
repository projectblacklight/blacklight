# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemPivotComponent, type: :component do
  subject(:render) do
    render_inline(described_class.new(facet_item: facet_item))
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:search_state) do
    Blacklight::SearchState.new({}, Blacklight::Configuration.new)
  end

  let(:facet_item) do
    instance_double(
      Blacklight::FacetItemPresenter,
      facet_config: Blacklight::Configuration::FacetField.new(key: 'z'),
      facet_field: 'z',
      label: 'x',
      hits: 10,
      href: '/catalog?f[z]=x',
      selected?: false,
      search_state: search_state,
      items: [OpenStruct.new(value: 'x:1', hits: 5)]
    )
  end

  it 'links to the facet and shows the number of hits' do
    expect(rendered).to have_selector 'li'
    expect(rendered).to have_link 'x', href: '/catalog?f[z]=x'
    expect(rendered).to have_selector '.facet-count', text: '10'
  end

  it 'has the facet hierarchy' do
    expect(rendered).to have_selector 'li ul.pivot-facet'
    expect(rendered).to have_link 'x:1', href: /f%5Bz%5D%5B%5D=x%3A1/
  end

  context 'with a selected facet' do
    let(:facet_item) do
      instance_double(
        Blacklight::FacetItemPresenter,
        facet_config: Blacklight::Configuration::FacetField.new,
        facet_field: 'z',
        label: 'x',
        hits: 10,
        href: '/catalog',
        selected?: true,
        search_state: search_state,
        items: []
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
