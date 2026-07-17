# frozen_string_literal: true

RSpec.describe Blacklight::Rendering::LinkToFacet, type: :presenter do
  include Capybara::RSpecMatchers

  let(:field_config) { Blacklight::Configuration::FacetField.new(link_to_facet: true, key: 'field', label: 'Field') }
  let(:document) { instance_double(SolrDocument) }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:view_context) { controller.view_context }
  let(:value) { 'value' }
  let(:pipeline) { Blacklight::Rendering::Pipeline.new([value], field_config, document, view_context, [described_class], {}) }

  describe '#render' do
    subject { pipeline.render[0] }

    it 'renders the value' do
      expect(subject).to have_css('span', text: 'value')
    end

    it 'renders the accessible description as visually hidden' do
      expect(subject).to have_css('span.visually-hidden', text: 'Field search')
    end
  end
end
