# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Search::FacetSuggestInput, type: :component do
  let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet', suggest: true }
  let(:presenter) { instance_double(Blacklight::FacetFieldPresenter) }

  before do
    allow(presenter).to receive(:label).and_return 'Language'
  end

  it 'has an input with the facet-suggest class, which the javascript needs to find it' do
    rendered = render_inline(described_class.new(facet: facet, presenter: presenter))
    expect(rendered.css("input.facet-suggest").count).to eq 1
  end

  it 'has an input with the data-facet-field attribute, which the javascript needs to determine the correct query' do
    rendered = render_inline(described_class.new(facet: facet, presenter: presenter))
    expect(rendered.css('input[data-facet-field="language_facet"]').count).to eq 1
  end

  it 'has a visible label that is associated with the input' do
    rendered = render_inline(described_class.new(facet: facet, presenter: presenter))
    label = rendered.css('label').first
    expect(label.text.strip).to eq 'Filter Language'

    id_in_label_for = label.attribute('for').text
    expect(id_in_label_for).to eq('facet_suggest_language_facet')

    expect(rendered.css('input').first.attribute('id').text).to eq id_in_label_for
  end

  context 'when the facet is explicitly configured to suggest: false' do
    let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet', suggest: false }

    it 'does not display' do
      expect(render_inline(described_class.new(facet: facet, presenter: presenter)).to_s).to eq ''
    end
  end

  context 'when the facet is not explicitly configured with a suggest key' do
    let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet' }

    it 'does not display' do
      expect(render_inline(described_class.new(facet: facet, presenter: presenter)).to_s).to eq ''
    end
  end
end
