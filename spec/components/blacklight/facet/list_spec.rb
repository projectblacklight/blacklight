# frozen_string_literal: true

RSpec.describe Blacklight::Facet::List do
  include ActionView::Component::TestHelpers

  subject(:rendered) do
    render_inline(described_class, blacklight_config: blacklight_config, response: response)
  end

  let(:blacklight_config) { Blacklight::Configuration.new }

  let(:facet_field) do
    Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label', group: nil).normalize!
  end

  let(:response) do
    instance_double(Blacklight::Solr::Response)
  end

  let(:instance) { described_class.new(blacklight_config: blacklight_config, response: response) }

  before do
    blacklight_config.facet_fields['facet_field_1'] = facet_field

    allow(described_class).to receive(:new).and_return(instance)
    allow(instance).to receive(:render)
  end

  it "calls facet_group for each name" do
    rendered
    expect(instance).to have_received(:render).with('catalog/facet_group', groupname: nil, response: response)
  end
end
