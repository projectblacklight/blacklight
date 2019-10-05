# frozen_string_literal: true

RSpec.describe 'catalog/facet.html.erb' do
  let(:display_facet) { double }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    blacklight_config.add_facet_field 'xyz', label: "Facet title"
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    stub_template 'catalog/_facet_pagination.html.erb' => 'pagination'
    assign :facet, blacklight_config.facet_fields['xyz']
    assign :display_facet, display_facet
    allow(view).to receive(:render).and_call_original
    @response = instance_double(Blacklight::Solr::Response)
  end

  it "has the facet title" do
    allow(view).to receive(:render).with(Blacklight::Facet::FacetLimit, display_facet: display_facet,
                                                                        blacklight_config: blacklight_config,
                                                                        response: @response,
                                                                        layout: false).and_return('')
    render
    expect(rendered).to have_selector 'h1', text: "Facet title"
  end

  it "renders facet pagination" do
    allow(view).to receive(:render).with(Blacklight::Facet::FacetLimit, display_facet: display_facet,
                                                                        blacklight_config: blacklight_config,
                                                                        response: @response,
                                                                        layout: false).and_return('')
    render
    expect(rendered).to have_content 'pagination'
  end
end
