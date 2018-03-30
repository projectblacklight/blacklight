# frozen_string_literal: true

RSpec.describe 'catalog/facet.html.erb' do
  let(:display_facet) { double }
  let(:blacklight_config) { Blacklight::Configuration.new }
  before :each do
    blacklight_config.add_facet_field 'xyz', label: "Facet title"
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    stub_template 'catalog/_facet_pagination.html.erb' => 'pagination'
    assign :facet, blacklight_config.facet_fields['xyz']
    assign :display_facet, display_facet
  end

  it "has the facet title" do
    allow(view).to receive(:render_facet_limit)
    render
    expect(rendered).to have_selector 'h1', text: "Facet title"
  end

  it "renders facet pagination" do
    allow(view).to receive(:render_facet_limit)
    render
    expect(rendered).to have_content 'pagination'
  end

  it "renders the facet limit" do
    allow(view).to receive(:render_facet_limit).with(display_facet, layout: false)
    render
  end
end
