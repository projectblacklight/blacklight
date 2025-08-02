# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Facets::SuggestComponent, type: :component do
  let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet', suggest: true }
  let(:presenter) { Blacklight::FacetFieldPresenter.new(facet, nil, nil, nil) }
  let(:component) { described_class.new(presenter: presenter) }

  before do
    allow(presenter).to receive_messages(label: 'Language')
  end

  it 'has an input with the facet-suggest class, which the javascript needs to find it' do
    with_request_url "/catalog/facet/language_facet" do
      rendered = render_inline component
      expect(rendered.css("input.facet-suggest").count).to eq 1
    end
  end

  it 'has an input with the data-facet-field attribute, which the javascript needs to determine the correct query' do
    with_request_url "/catalog/facet/language_facet" do
      rendered = render_inline component
      expect(rendered.css('input[data-facet-field="language_facet"]').count).to eq 1
    end
  end

  it 'has an input with the data-facet-search-context attribute, which the javascript needs to determine the current search context' do
    with_request_url "/catalog/facet/language_facet?f%5Bformat%5D%5B%5D=Book&facet.prefix=R&facet.sort=index&q=tibet&search_field=all_fields" do
      rendered = render_inline component
      facet_path = ViewComponent::VERSION::MAJOR == 3 ? '/catalog/facet/language_facet.html' : '/catalog/facet/language_facet'
      expect(rendered.css("input[data-facet-search-context=\"#{facet_path}?f%5Bformat%5D%5B%5D=Book&facet.prefix=R&facet.sort=index&q=tibet&search_field=all_fields\"]").count).to eq 1
    end
  end

  it 'has a visible label that is associated with the input' do
    with_request_url "/catalog/facet/language_facet" do
      rendered = render_inline component
      label = rendered.css('label').first
      expect(label.text.strip).to eq 'Filter Language'

      id_in_label_for = label.attribute('for').text
      expect(id_in_label_for).to eq('facet_suggest_language_facet')

      expect(rendered.css('input').first.attribute('id').text).to eq id_in_label_for
    end
  end

  context 'when the facet is explicitly configured to suggest: false' do
    let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet', suggest: false }

    it 'does not display' do
      with_request_url "/catalog/facet/language_facet" do
        expect(render_inline(component).to_s).to eq ''
      end
    end
  end

  context 'when the facet is not explicitly configured with a suggest key' do
    let(:facet) { Blacklight::Configuration::FacetField.new key: 'language_facet' }

    it 'displays' do
      with_request_url "/catalog/facet/language_facet" do
        rendered = render_inline component
        expect(rendered.css("input.facet-suggest").count).to eq 1
      end
    end
  end
end
