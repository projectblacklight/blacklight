# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(described_class.new(field_config: facet_config, display_facet: display_facet ))
  end
  let(:items) { [{ label: "Book", value: 'Book', hits: 20 }] }

  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, limit: nil, sort: :index, offset: 0, prefix: nil)
  end

  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'field').normalize! }


  it 'delegates to the configured component to render something' do
    expect(rendered).to have_selector 'ul.facet-values'
  end

  context 'with a facet configured to use a partial' do
    let(:facet_config) do
      Blacklight::Configuration::FacetField.new(key: 'field', partial: 'catalog/facet_partial').normalize!
    end

    before do
      controller.view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for('catalog/_facet_partial.html.erb' => 'facet partial'))
    end

    it 'renders the partial' do
      expect(rendered).to have_content 'facet partial'
    end
  end
end
