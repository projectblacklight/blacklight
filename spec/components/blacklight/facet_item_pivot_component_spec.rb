# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemPivotComponent, type: :component do
  before do
    render_inline(described_class.new(facet_item: facet_item))
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
      Blacklight::FacetItemPivotPresenter,
      facet_config: facet_config,
      facet_field: 'z',
      label: 'x',
      hits: 10,
      href: '/catalog?f[z]=x',
      selected?: false,
      search_state: search_state,
      facet_item_presenters: [OpenStruct.new(label: 'x:1', hits: 5, href: '/catalog?f[z][]=x:1', facet_config: facet_config)]
    )
  end

  let(:facet_config) { Blacklight::Configuration::NullField.new(key: 'z', item_component: Blacklight::Facets::ItemComponent, item_presenter: Blacklight::FacetItemPivotPresenter) }

  it 'links to the facet and shows the number of hits' do
    expect(page).to have_css 'li'
    expect(page).to have_link 'x', href: nokogiri_mediated_href(facet_item.href)
    expect(page).to have_css '.facet-count', text: '10'
  end

  it 'has the facet hierarchy' do
    expect(page).to have_css 'li ul.pivot-facet'
    expect(page).to have_link 'x:1', href: nokogiri_mediated_href(facet_item.facet_item_presenters.first.href)
  end

  context 'with a selected facet' do
    let(:facet_item) do
      instance_double(
        Blacklight::FacetItemPivotPresenter,
        facet_config: facet_config,
        facet_field: 'z',
        label: 'x',
        hits: 10,
        href: '/catalog',
        selected?: true,
        search_state: search_state,
        facet_item_presenters: []
      )
    end

    it 'links to the facet and shows the number of hits' do
      expect(page).to have_css 'li'
      expect(page).to have_css '.selected', text: 'x'
      expect(page).to have_link '[remove]', href: '/catalog'
      expect(page).to have_css '.selected.facet-count', text: '10'
    end
  end
end
