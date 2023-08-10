# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemPivotComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(facet_item: facet_item))
  end

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field :z
    end
  end

  let(:search_state) do
    Blacklight::SearchState.new({}, blacklight_config)
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
    expect(rendered).to have_link 'x', href: nokogiri_mediated_href(facet_item.href)
    expect(rendered).to have_selector '.facet-count', text: '10'
  end

  it 'has the facet hierarchy' do
    pending
    expect(rendered).to have_selector 'li ul.pivot-facet'
    expect(rendered).to have_link 'x:1', href: nokogiri_mediated_href(facet_item.facet_item_presenters.first.href)
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
