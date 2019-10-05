# frozen_string_literal: true

RSpec.describe Blacklight::Facet::Group do
  include ActionView::Component::TestHelpers

  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:instance) { described_class.new(groupname: nil, blacklight_config: blacklight_config, response: response) }

  before do
    allow(described_class).to receive(:new).and_return(instance)
    allow(instance).to receive(:render)
  end

  context "without any facet fields" do
    subject(:rendered) do
      render_inline(described_class, groupname: nil, blacklight_config: blacklight_config, response: response)
    end

    let(:response) do
      instance_double(Blacklight::Solr::Response)
    end

    it "does not have a header if no facets are displayed" do
      expect(rendered.css('h4')).not_to be_present
    end
  end

  context "with facet groups" do
    let :facet_field do
      Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label', group: nil).normalize!
    end

    let(:mock_display_facet1) do
      double(name: 'facet_field_1', sort: nil, offset: nil, prefix: nil, items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: 'Value', hits: 1234)])
    end

    let(:response) do
      instance_double(Blacklight::Solr::Response, aggregations: { "facet_field_1" => mock_display_facet1 })
    end

    before do
      blacklight_config.facet_fields['facet_field_1'] = facet_field
    end

    context "with the default facet group" do
      subject(:rendered) do
        render_inline(described_class, groupname: nil, blacklight_config: blacklight_config, response: response)
      end

      it "has a header" do
        expect(rendered.css('.facets-heading')).to be_present
      end
    end

    context "with a named facet group" do
      subject(:rendered) do
        render_inline(described_class, groupname: 'group_1', blacklight_config: blacklight_config, response: response)
      end

      let :facet_field do
        Blacklight::Configuration::FacetField.new(field: 'facet_field_1', label: 'label', group: 'group_1').normalize!
      end

      let(:instance) { described_class.new(groupname: 'group_1', blacklight_config: blacklight_config, response: response) }

      before do
        blacklight_config.facet_fields['facet_field_1'] = facet_field
      end

      it "has a header" do
        expect(rendered.css('.facets-heading')).to be_present
        expect(rendered.css('#facets-group_1')).to be_present
      end
    end
  end
end
