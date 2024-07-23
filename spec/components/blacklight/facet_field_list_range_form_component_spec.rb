# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetFieldListRangeFormComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(facet_field: facet_field))
  end

  let(:selected_range) { nil }
  let(:search_params) { { another_field: 'another_value' } }

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
      selected_range: selected_range,
      selected_item: nil,
      missing_selected?: false,
      search_state: Blacklight::SearchState.new(search_params, nil)
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

  it 'renders a form with no selected range' do
    expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
    expect(rendered).to have_field('range[field][start]', type: 'number') { |e| e['value'].blank? }
    expect(rendered).to have_field('range[field][end]', type: 'number') { |e| e['value'].blank? }
    expect(rendered).to have_field('another_field', type: 'hidden', with: 'another_value', visible: :hidden)
  end

  it 'renders submit controls without a name to suppress from formData' do
    anon_submit = rendered.find('input', visible: true) { |ele| ele[:type] == 'submit' && !ele[:'aria-hidden'] && !ele[:name] }
    expect(anon_submit).to be_present
    expect { rendered.find('input') { |ele| ele[:type] == 'submit' && ele[:name] } }.to raise_error(Capybara::ElementNotFound)
  end

  context 'with range data' do
    let(:selected_range) { (100..300) }
    let(:search_params) do
      {
        another_field: 'another_value',
        range: {
          another_range: { start: 128, end: 1024 },
          field: { start: selected_range.first, end: selected_range.last }
        }
      }
    end

    it 'renders a form for the selected range' do
      expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
      expect(rendered).to have_field('range[field][start]', type: 'number', with: selected_range.first)
      expect(rendered).to have_field('range[field][end]', type: 'number', with: selected_range.last)
      expect(rendered).to have_field('another_field', type: 'hidden', with: 'another_value', visible: :hidden)
      expect(rendered).to have_field('range[another_range][start]', type: 'hidden', with: 128, visible: :hidden)
      expect(rendered).to have_field('range[another_range][end]', type: 'hidden', with: 1024, visible: :hidden)
    end
  end

  context 'with configuration options for inputs' do
    let(:facet_config) do
      Blacklight::Configuration::NullField.new(
        key: 'field',
        range: { input: { placeholder: 'Year', max: 9999 } },
        item_component: Blacklight::FacetItemComponent,
        item_presenter: Blacklight::FacetItemRangePresenter
      )
    end

    it 'renders inputs with the options provided' do
      expect(rendered).to have_field('range[field][start]', type: :number) do |e|
        e['placeholder'] == 'Year' && e['max'] == '9999'
      end
      expect(rendered).to have_field('range[field][end]', type: 'number') do |e|
        e['placeholder'] == 'Year' && e['max'] == '9999'
      end
    end
  end
end
