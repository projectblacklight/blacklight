# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::AdvancedSearchFormComponent, type: :component do
  subject(:render) do
    component.render_in(view_context)
  end

  let(:component) { described_class.new(url: '/whatever', response: response, params: params) }
  let(:response) { Blacklight::Solr::Response.new({ facet_counts: { facet_fields: { format: { 'Book' => 10, 'CD' => 5 } } } }.with_indifferent_access, {}) }
  let(:params) { {} }

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:view_context) { controller.view_context }

  before do
    allow(view_context).to receive(:facet_limit_for).and_return(nil)
  end

  context 'with additional parameters' do
    let(:params) { { some: :parameter, an_array: [1, 2] } }

    it 'adds additional parameters as hidden fields' do
      expect(rendered).to have_field 'some', with: 'parameter', type: :hidden
      expect(rendered).to have_field 'an_array[]', with: '1', type: :hidden
      expect(rendered).to have_field 'an_array[]', with: '2', type: :hidden
    end
  end

  it 'has text fields for each search field' do
    expect(rendered).to have_selector '.advanced-search-field', count: 4
    expect(rendered).to have_field 'clause_0_field', with: 'all_fields', type: :hidden
    expect(rendered).to have_field 'clause_1_field', with: 'title', type: :hidden
    expect(rendered).to have_field 'clause_2_field', with: 'author', type: :hidden
    expect(rendered).to have_field 'clause_3_field', with: 'subject', type: :hidden
  end

  it 'has filters' do
    expect(rendered).to have_selector '.blacklight-format'
    expect(rendered).to have_field 'f_inclusive[format][]', with: 'Book'
    expect(rendered).to have_field 'f_inclusive[format][]', with: 'CD'
  end

  it 'has a sort field' do
    expect(rendered).to have_select 'sort', options: %w[relevance year author title]
  end
end
