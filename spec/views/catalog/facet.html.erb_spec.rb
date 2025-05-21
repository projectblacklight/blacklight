# frozen_string_literal: true

RSpec.describe 'catalog/facet.html.erb' do
  let(:display_facet) { double }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:component) { instance_double(Blacklight::FacetComponent) }
  let(:facet_suggest_input) { instance_double(Blacklight::Facets::SuggestComponent) }
  let(:pagination) { instance_double(Blacklight::FacetFieldPaginationComponent) }

  before do
    allow(Blacklight::FacetComponent).to receive(:new).and_return(component)
    allow(Blacklight::Facets::SuggestComponent).to receive(:new).and_return(facet_suggest_input)
    allow(Blacklight::FacetFieldPaginationComponent).to receive(:new).and_return(pagination)

    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(component)
    allow(view).to receive(:render).with(facet_suggest_input)
    allow(view).to receive(:render).with(pagination)

    blacklight_config.add_facet_field 'xyz', label: "Facet title"
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    assign :facet, blacklight_config.facet_fields['xyz']
    assign :display_facet, display_facet
  end

  it "has the facet title" do
    render
    expect(rendered).to have_css 'h1', text: "Facet title"
  end

  it "renders the subcomponents" do
    render
    expect(view).to have_received(:render).with(facet_suggest_input)
    expect(view).to have_received(:render).with(pagination).twice
  end

  it "renders the facet limit" do
    render
    expect(view).to have_received(:render).with(component)
  end
end
