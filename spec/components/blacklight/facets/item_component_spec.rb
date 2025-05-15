# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Facets::ItemComponent, type: :component do
  before do
    render_inline(described_class.new(facet_item: facet_item))
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
    expect(page).to have_css 'li'
    expect(page).to have_link 'x', href: '/catalog?f=x' do |link|
      link['rel'] == 'nofollow'
    end
    expect(page).to have_css '.facet-count', text: '10'
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
      expect(page).to have_css 'li'
      expect(page).to have_css '.selected', text: 'x'
      expect(page).to have_link '[remove]', href: '/catalog' do |link|
        link['rel'] == 'nofollow'
      end
      expect(page).to have_css '.selected.facet-count', text: '10'
    end
  end
end
