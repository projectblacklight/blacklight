# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetComponent, type: :component do
  subject(:rendered) do
    render_inline_to_capybara_node(component)
  end

  let(:component) { described_class.new(**component_kwargs) }
  let(:component_kwargs) { { field_config: facet_config, display_facet: display_facet } }
  let(:items) { [{ label: "Book", value: 'Book', hits: 20 }] }

  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, name: 'field', items: items, limit: nil, sort: :index, offset: 0, prefix: nil)
  end

  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'field').normalize! }

  it 'delegates to the configured component to render something' do
    expect(rendered).to have_css 'ul.facet-values'
  end

  context 'with a provided component' do
    let(:component_kwargs) { { field_config: facet_config, display_facet: display_facet, component: component_class } }
    let(:component_class) do
      Class.new(Blacklight::FacetFieldListComponent) do
        def self.name
          'CustomFacetComponent'
        end

        def call
          'Custom facet rendering'.html_safe
        end
      end
    end

    it 'renders the provided component' do
      expect(rendered).to have_content 'Custom facet rendering'
    end
  end

  context 'with a facet configured to use a partial' do
    let(:facet_config) do
      Blacklight::Configuration::FacetField.new(key: 'field', partial: 'catalog/facet_partial').normalize!
    end

    # Not sure why we need to re-implement rspec's stub_template, but
    # we already were, and need a Rails 7.1+ safe alternate too
    # https://github.com/rspec/rspec-rails/commit/4d65bea0619955acb15023b9c3f57a3a53183da8
    # https://github.com/rspec/rspec-rails/issues/2696
    before do
      replace_hash = { 'catalog/_facet_partial.html.erb' => 'facet partial' }

      if Rails.version.to_f >= 7.1
        controller.prepend_view_path(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
      else
        controller.view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
      end
    end

    it 'renders the partial' do
      expect(rendered).to have_content 'facet partial'
    end
  end

  context 'with a field and response' do
    let(:component_kwargs) do
      { display_facet_or_field_config: facet_config, response: response }
    end

    let(:response) { instance_double(Blacklight::Solr::Response, aggregations: { 'field' => display_facet }) }

    it 'extracts the facet data from the response to pass on to the rendering component' do
      allow(facet_config.component).to receive(:new).and_call_original

      rendered

      expect(facet_config.component).to have_received(:new).with(facet_field: have_attributes(facet_field: facet_config, display_facet: display_facet))
    end

    context 'when the field is not in the response' do
      let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'some_other_field').normalize! }

      it 'uses a null field to pass through the response information anyway' do
        allow(facet_config.component).to receive(:new).and_call_original

        rendered

        expect(facet_config.component).to have_received(:new).with(facet_field: have_attributes(facet_field: facet_config, display_facet: have_attributes(items: [], response: response)))
      end
    end
  end

  context 'with a display facet and configuration' do
    let(:component_kwargs) do
      { display_facet_or_field_config: display_facet, blacklight_config: blacklight_config }
    end

    let(:blacklight_config) { Blacklight::Configuration.new.tap { |config| config.facet_fields['field'] = facet_config } }

    it 'pulls the facet config from the blacklight config' do
      allow(facet_config.component).to receive(:new).and_call_original

      rendered

      expect(facet_config.component).to have_received(:new).with(facet_field: have_attributes(facet_field: facet_config, display_facet: display_facet))
    end
  end

  context 'with a presenter' do
    let(:component_kwargs) do
      { display_facet_or_field_config: presenter }
    end

    let(:presenter) { Blacklight::FacetFieldPresenter.new(facet_config, display_facet, controller.view_context) }

    it 'renders the component with the provided presenter' do
      allow(facet_config.component).to receive(:new).and_call_original

      rendered

      expect(facet_config.component).to have_received(:new).with(facet_field: presenter)
    end
  end
end
